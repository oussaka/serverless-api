package main

import (
	"net/http"
	"os"
	"serverless-api/api/internal/responsewritter"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/sirupsen/logrus"
)

func main() {
	lambda.Start(Run)
}

func Run(req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	logrus.SetFormatter(&logrus.JSONFormatter{})
	logger := logrus.WithFields(logrus.Fields{
		"resource": "users/:username",
		"method":   "DELETE",
	})

	username := req.PathParameters["username"]
	if len(username) == 0 {
		logger.Print("missing 'username' in path")
		return responsewritter.Default(http.StatusBadRequest, "missing 'username' in path"), nil
	}

	tableName, ok := os.LookupEnv("DDB_TABLE_NAME")
	if !ok {
		logger.Print("missing mandatory env vars")
		return responsewritter.Default(http.StatusInternalServerError, "try again later"), nil
	}

	sess := session.Must(session.NewSessionWithOptions(session.Options{
		SharedConfigState: session.SharedConfigEnable,
	}))

	svc := dynamodb.New(sess)
	input := &dynamodb.DeleteItemInput{
		Key: map[string]*dynamodb.AttributeValue{
			"username": {
				S: aws.String(username),
			},
		},
		TableName: aws.String(tableName),
	}

	if _, err := svc.DeleteItem(input); err != nil {
		logger.WithFields(logrus.Fields{
			"username": username,
			"err":      err.Error(),
		}).Error("failed deleting user")

		return responsewritter.Default(http.StatusBadRequest, "failed deleting user"), nil
	}

	return responsewritter.Default(http.StatusOK, "OK"), nil
}
