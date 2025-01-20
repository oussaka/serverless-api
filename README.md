# serverless-api: AWS Lambda function using GoLang

First, we start by creating our sample api using Golang

``` 
    go mod init serverless-api
    go get github.com/aws/aws-lambda-go/events
    go get github.com/aws/aws-lambda-go/lambda
```

Deploying the api:

```
    cd /iac/api/
    terraform plan
    terraform apply --auto-approve
```

`/iac/api/outputs.tf` file contains properties that will be printed out after terraform apply finishes running. If all goes well, I should see an output similar to this:

```
    invoke_url = "https://url.execute-api.eu-central-1.amazonaws.com/v1"
```

Now with that url in place, I can use curl to test if everything’s working as expected:

```
# create document
curl -X POST https://url.execute-api.eu-central-1.amazonaws.com/v1/users \
 -H 'Content-Type: application/json' \
 -d '{"username": "foo"}'

# get document
curl -X GET https://url.execute-api.eu-central-1.amazonaws.com/v1/users/foo

# update document
curl -X PUT https://url.execute-api.eu-central-1.amazonaws.com/v1/users/foo \
 -H 'Content-Type: application/json' \
 -d '{"fname": "bar", "lname": "baz", "age": 100}'

# delete document
curl -X DELETE https://url.execute-api.eu-central-1.amazonaws.com/v1/users/foo
```