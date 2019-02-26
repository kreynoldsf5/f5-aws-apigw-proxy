//index.js
var f5 = require('f5-nodejs');
var rp = require('request-promise');
var AWS = require('aws-sdk');
var apigClientFactory = require('aws-api-gateway-client').default;
var ilx = new f5.ILXServer();

ilx.addMethod('apigw_creds', function(req, res){
    const http_opts = {
        host: '169.254.169.254',
        path: '/latest/meta-data/iam/security-credentials/f5ApiProxyRole',
        method: 'GET'
    };
    rp(http_opts)
    .then(function(credBody) {
        jsonCreds = JSON.parse(credBody);
        var creds;
        creds.accessKeyId = jsonCreds.AccessKeyId;
        creds.secretAccessKey = jsonCreds.SecretAccessKey;
        creds.sessionToken = jsonCreds.Token;
        //TBD -- what else is in the response? Maybe just pass the whole thing and parse later?
        res.reply(JSON.stringify(creds));
    }).catch(function(err) {
        console.log(err);
        res.reply("failed")
    });
});

ilx.addMethod('apigw_proxy_call', function(req, res){
    //Parse the req passed in
    var creds = req.params(0);
    var apiUri = req.params()[1];  //'glc-hello-sns'; //
    var body = JSON.parse(req.params()[2]);  //'{"here": "I am"}';//
    var mthd = req.params()[3];  //'POST'; //
    //
    const localRegion = {
        host: '169.254.169.254',
        path: '/latest/dynamic/instance-identity/document',
        method: 'GET'
    };
    //
    rp(localRegion)
    .then(function(body){
        var thisRegion = body.region;

    })
    .then(function(body) {
        
    })
    .catch(function(err) {
        console.log(err);
        res.reply("failed")
    })
    //Don't have the region yet
    AWS.config = new AWS.Config({ accessKeyId: accessKeyId, secretAccessKey: secretAccessKey, sessionToken: sessionToken, region: defRegion });
});

ilx.listen();
