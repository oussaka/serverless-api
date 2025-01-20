package main

import (
	"encoding/json"
	"net/http"
	"os"
	"serverless-api/api/internal/models"
	"serverless-api/api/internal/responsewritter"
	"strconv"
	"time"

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
		"resource": "users",
		"method":   "PUT",
	})

	username := req.PathParameters["username"]
	if len(username) == 0 {
		logger.Print("missing 'username' in path")
		return responsewritter.Default(http.StatusBadRequest, "missing 'username' in path"), nil
	}

	user := models.UserUpdate{}
	if err := json.Unmarshal([]byte(req.Body), &user); err != nil {
		logger.Error("unmarshal request body", err)
		return responsewritter.Default(http.StatusBadRequest, "try again later"), nil
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

	input := &dynamodb.UpdateItemInput{
		Key: map[string]*dynamodb.AttributeValue{
			"username": {
				S: aws.String(username),
			},
		},
		ExpressionAttributeValues: map[string]*dynamodb.AttributeValue{
			":fn": {
				S: aws.String(user.Fname),
			},
			":ln": {
				S: aws.String(user.Lname),
			},
			":a": {
				N: aws.String(strconv.Itoa(user.Age)),
			},
			":u": {
				S: aws.String(time.Now().UTC().Format(time.RFC3339)),
			},
		},
		TableName:        aws.String(tableName),
		ReturnValues:     aws.String("UPDATED_NEW"),
		UpdateExpression: aws.String("set fname = :fn, lname = :ln, age = :a, updated = :u"),
	}

	if _, err := svc.UpdateItem(input); err != nil {
		logger.Error("got error calling UpdateItem", err)
		return responsewritter.Default(http.StatusInternalServerError, "failed updating record, try again later"), nil
	}

	return responsewritter.Default(http.StatusOK, "OK"), nil
}
