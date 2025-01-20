#-----------------------------------------------------------------------------------
# configure aws provider
#-----------------------------------------------------------------------------------
provider "aws" {
  region = var.region
}

#-----------------------------------------------------------------------------------
# backend setup for state tracking, check prerequisites
#-----------------------------------------------------------------------------------
terraform {
  backend "s3" {
    region         = "us-east-2"
    bucket         = "project-123-remote-state"
    key            = "project-123-remote-state.tfstate"
    dynamodb_table = "project-123-tf-statelock"
  }
}

#-----------------------------------------------------------------------------------
# create a role that will allow lambda to be executed and access other resources
#-----------------------------------------------------------------------------------
data "template_file" "lambda_policy" {
  template = file("templates/lambda_policy.json")
}

data "template_file" "lambda_role" {
  template = file("templates/lambda_role.json")
}

resource "aws_iam_policy" "policy" {
  name        = "${local.env}-${var.prefix}-policy"
  description = "policy to allow lambda use specified resources"
  policy      = data.template_file.lambda_policy.rendered
}

resource "aws_iam_role" "role" {
  name               = "${local.env}-${var.prefix}-role"
  assume_role_policy = data.template_file.lambda_role.rendered
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

#-----------------------------------------------------------------------------------
# Create Dynamodb table for users resource
#-----------------------------------------------------------------------------------
module "dynamodb_table" {
  source = "terraform-aws-modules/dynamodb-table/aws"

  name     = local.ddb_users_table
  hash_key = "username"

  attributes = [
    {
      name = "username"
      type = "S"
    }
  ]

  tags = {
    Env = local.env
  }
}

#-----------------------------------------------------------------------------------
# create user lambda
#-----------------------------------------------------------------------------------
module "create_user_lambda" {
  source        = "../modules/aws/lambda"
  function_name = "create_user"
  lambda_path   = var.lambda_path
  description   = "create user lambda, part of /users resource CRUD to handle user creation"
  role_arn      = aws_iam_role.role.arn

  environment = {
    ENV            = local.env
    REGION         = var.region
    DDB_TABLE_NAME = local.ddb_users_table
  }

  tags = {
    Env = local.env
  }
}

#-----------------------------------------------------------------------------------
# update user lambda
#-----------------------------------------------------------------------------------
module "update_user_lambda" {
  source        = "../modules/aws/lambda"
  function_name = "update_user"
  lambda_path   = var.lambda_path
  description   = "update user lambda, part of /users resource CRUD to handle user update"
  role_arn      = aws_iam_role.role.arn

  environment = {
    ENV            = local.env
    REGION         = var.region
    DDB_TABLE_NAME = local.ddb_users_table
  }

  tags = {
    Env = local.env
  }
}

#-----------------------------------------------------------------------------------
# get user lambda
#-----------------------------------------------------------------------------------
module "get_user_lambda" {
  source        = "../modules/aws/lambda"
  function_name = "get_user"
  lambda_path   = var.lambda_path
  description   = "get user lambda, part of /users resource CRUD to handle user reads"
  role_arn      = aws_iam_role.role.arn

  environment = {
    ENV            = local.env
    REGION         = var.region
    DDB_TABLE_NAME = local.ddb_users_table
  }

  tags = {
    Env = local.env
  }
}

#-----------------------------------------------------------------------------------
# delete user lambda
#-----------------------------------------------------------------------------------
module "delete_user_lambda" {
  source        = "../modules/aws/lambda"
  function_name = "delete_user"
  lambda_path   = var.lambda_path
  description   = "delete user lambda, part of /users resource CRUD to handle user deletes"
  role_arn      = aws_iam_role.role.arn

  environment = {
    ENV            = local.env
    REGION         = var.region
    DDB_TABLE_NAME = local.ddb_users_table
  }

  tags = {
    Env = local.env
  }
}

#-----------------------------------------------------------------------------------
# create API Gateway
#-----------------------------------------------------------------------------------
data "template_file" "apigw_policy" {
  template = file("${path.module}/templates/apigw_policy.json")
}

data "template_file" "api_spec" {
  template = file("templates/api.yaml")
  vars = {
    role_arn               = aws_iam_role.role.arn
    region                 = var.region
    create_user_lambda_arn = module.create_user_lambda.function_arn
    update_user_lambda_arn = module.update_user_lambda.function_arn
    get_user_lambda_arn    = module.get_user_lambda.function_arn
    delete_user_lambda_arn = module.delete_user_lambda.function_arn
  }
}

resource "aws_api_gateway_rest_api" "rest_api" {
  name        = "serverless-api"
  description = "serverless-api"
  body        = data.template_file.api_spec.rendered
  policy      = data.template_file.apigw_policy.rendered
}

resource "aws_api_gateway_deployment" "client-example-api" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  depends_on  = [aws_api_gateway_rest_api.rest_api]

  variables = {
    api_version = md5(file("${path.module}/templates/api.yaml"))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  stage_name    = var.api_version
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  deployment_id = aws_api_gateway_deployment.client-example-api.id
}
