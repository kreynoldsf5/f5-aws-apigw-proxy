when HTTP_REQUEST {
    ## Capture path
    set orig_path [string trimleft [HTTP::path] "/"]
    log local0.info "Starting the process..with path of:  $orig_path"
    ## Collect for methods that will contain payload
    ## TBD: Insert logic to account for 64KB RPC channel (this includes creds, URI, payload, and body AND overhead)
    ## Lambda payload sizes are now 256KB max (used to be 128KB)
    ## Add cleaner/debug logging
    switch [HTTP::method] {
        "POST" -
        "PUT" - 
        "PATCH" {
            if {[HTTP::header "Content-Length"] ne "" && [HTTP::header "Content-Length"] <= 1048576}{
                set content_length [HTTP::header "Content-Length"]
            } else {
                set content_length 64512
            }
            if { $content_length > 0} {
                HTTP::collect $content_length
            }
        }
    }
}

when HTTP_REQUEST_DATA {
    ### check if URI presented is in DG. If so pass path to proxy
    if { [class match [string tolower $orig_path] contains aws-apis]}{
        set apiUrl [class match -value [string tolower $orig_path] contains aws-apis]
        set RPC_HANDLE [ILX::init f5_aws_apigw_proxy aws_apigw_proxy]
        ## Retrieve credentials from table entry or fetch credentials if not already cached in table
        if { [table lookup aws_apigw_creds] = "" } {
            if {[catch {ILX::call $RPC_HANDLE "apigw_creds_call"} apigw_creds]} {
                log local0.error  "Credential retrieval error, ILX failure: $apigw_creds"
                HTTP::respond 500 noserver content "Unable to proxy call, verify if appropriate IAM role 'f5ApiProxyRole' has been attached to the BIGIP instance."
                return
            }
            table set aws_apigw_creds $apigw_creds indef 3600
        } else {
            set apigw_creds [table lookup aws_apigw_proxy]
        }

        ## Initialize plugin and call proxy
        log local0.info "Sending to nodejs:  $apiUrl"

        if {[catch {ILX::call $RPC_HANDLE "apigw_proxy_call" $apigw_creds $apiUrl [HTTP::payload] [HTTP::method]} result]} {
           log local0.error  "Client - [IP::client_addr], ILX failure: $result"
           HTTP::respond 500 noserver content "Unable to proxy call, verify AWS API endpoint in registered in the aws-apis datagroup and verify if appropriate IAM role 'f5ApiProxyRole' has been attached to the BIGIP instance - https://aws.amazon.com/blogs/security/easily-replace-or-attach-an-iam-role-to-an-existing-ec2-instance-by-using-the-ec2-console/"
           return
        }
        ## return proxy result
        if { $result eq "failed" }{
            HTTP::respond 400 noserver content '{"error":"Failed to call API or function"}'  "Content-Type" "application/json"
        } else {
            HTTP::respond 200 noserver content $result  "Content-Type" "application/json"
        }

    } else {
        ## Not a legitimate URI
        #log local0.info "Failure: No matching API found"
        HTTP::respond 404 noserver content "Requested API not found at this location"
    }
}
