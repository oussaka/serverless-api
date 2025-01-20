package responsewritter

import (
	"encoding/json"

	"github.com/aws/aws-lambda-go/events"
)

func Do(statusCode int, payload []byte) events.APIGatewayProxyResponse {
	return events.APIGatewayProxyResponse{
		StatusCode: statusCode,
		Headers: map[string]string{
			"Content-Type":                "application/json",
			"Access-Control-Allow-Origin": "*",
		},
		Body: string(payload),
	}
}

func Default(statusCode int, msg string) events.APIGatewayProxyResponse {
	res := struct {
		Code    int    `json:"code"`
		Message string `json:"message"`
	}{
		Code:    statusCode,
		Message: msg,
	}

	b, _ := json.Marshal(res)

	return Do(statusCode, b)
}
