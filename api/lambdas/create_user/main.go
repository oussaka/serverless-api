package main

import (
	"encoding/json"
	"net/http"
	"os"
	"serverless-api/api/internal/models"
	"serverless-api/api/internal/responsewritter"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
	"github.com/sirupsen/logrus"
)

func main() {
	lambda.Start(Run)
}

func Run(req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	logrus.SetFormatter(&logrus.JSONFormatter{})
	logger := logrus.WithFields(logrus.Fields{
		"resource": "users",
		"method":   "POST",
	})

	tableName, ok := os.LookupEnv("DDB_TABLE_NAME")
	if !ok {
		logger.Print("missing mandatory env vars")
		return responsewritter.Default(http.StatusInternalServerError, "try again later"), nil
	}

	user := models.User{}
	now := time.Now().UTC()
	user.Created = now
	user.Updated = now

	if err := json.Unmarshal([]byte(req.Body), &user); err != nil {
		logger.Error("unmarshal request body", err)
		return responsewritter.Default(http.StatusBadRequest, "failed to unmarshal request payload"), nil
	}

	if err := user.Valid(); err != nil {
		logger.Error("user model validation failed", err)
		return responsewritter.Default(http.StatusBadRequest, err.Error()), nil
	}

	sess := session.Must(session.NewSessionWithOptions(session.Options{
		SharedConfigState: session.SharedConfigEnable,
	}))
	svc := dynamodb.New(sess)

	item, err := dynamodbattribute.MarshalMap(user)
	if err != nil {
		logger.Error("dynamodb attribute marshal", err)
		return responsewritter.Default(http.StatusInternalServerError, "please try again later"), nil
	}

	input := &dynamodb.PutItemInput{
		Item:                   item,
		ReturnConsumedCapacity: aws.String("TOTAL"),
		TableName:              aws.String(tableName),
		ExpressionAttributeNames: map[string]*string{
			"#un": aws.String("username"),
		},
		ConditionExpression: aws.String("attribute_not_exists(#un)"),
	}

	if _, err := svc.PutItem(input); err != nil {
		logger.Error("creating user record", err)
		return responsewritter.Default(http.StatusInternalServerError, "failed creating user record"), nil
	}

	return responsewritter.Default(http.StatusOK, "OK"), nil
}
