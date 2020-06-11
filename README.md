# ForgeOps Smoke Test Service

This is deployed a Cloud Run service, and will perform 
a basic smoke test on a deployed ForgeOps platform.

The test requires the use of `amadmin` credentials. DO NOT RUN THIS TEST ON 
A PRODUCTION SYSTEM. The test uses a POST, so most intermediate systems will not
log the credential - but leakage is very possible. You have been warned.

## Running the test

You can manually run the test via the index page:

https://smoketest-7escakmhgq-uk.a.run.app/ 

Or using curl:
```
curl 'https://smoketest-7escakmhgq-uk.a.run.app/test' \
    --data 'fqdn=nightly.iam.forgeops.com&amadminPassword=secretpassword'
```

The POST form arguments are:
* fqdn - the fully qualified domain name (do not include the https)
* amadminPassword - the password for the `amadin` user

A 200 response means the test has passed. See the json that is returned for the test results.

Anything other than a 200 is a test failure. Note the test stops immediately on the first error. 

## Adding new tests

Refer to [smoke_test.dart](lib/smoke_test.dart).  

The strategy for the test is to "fail fast". Failed tests should throw an Exception. 

## Manually running tests

You can run [bin/main.dart](bin/main.dart) to manually run tests, or if you want to run
the http server run [bin/server.dart](bin/server.dart).

## Deploying to cloud run

Run `gclouds builds submit`

Dart's tree shaking and native compilation using `dart2native` results in a very small docker image (less than 6mb).


## Test Side effects

Running the test will:
 
* Create users `user.0` through to `user.5`. If they already exist they will not be re-created.
* Self-register a user `tuserxxxxx` where xxxxx is a random integer.


## TODO


