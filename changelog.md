# Changelog

## TCL iRule
* Cache creds in a table entry with a timeout, retrieve creds by calling new method (if table entry doesn't exist)
* Cleaned up error messages -- no need to check the data group if we're already in the ``if`` block after the ``class match``
* Updated Content length collection method to standard pattern
* added ``noserver`` options to [HTTP::Respond] to prevent BIG-IP server header
* There is no handling of GET requests


## ILX rule
* Seperate method for retrieving credentials (so that call doesn't happen with every processed request)
* Use``request-promise`` instead of ``http``. This package is already provided/required by ``aws-sdk``.


## Issues
* so we're a assuming that all content that comes back is JSON? Aren't we proxying lamda as well as other things in the API?
* How much information do we want to give in the error message? Do we maybe want to return an ASM error message?
* Any HTTP verb without a payload is not going to work.
* <64KB RPC channel is crippling here
