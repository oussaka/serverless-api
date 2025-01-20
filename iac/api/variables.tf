variable "region" {
  default     = "us-east-2"
  description = "region where all the resources will be deployed"
}

variable "prefix" {
  default     = "project-123"
  description = "organization or service name, has to be unique"
}

variable "ddb_statelock_table" {
  default     = "tf-statelock"
  description = "name of dynamo db table for terraform state locking"
}

variable "api_version" {
  description = "api version, v1, v2, v... etc"
  default     = "v1"
}

variable "lambda_path" {
  description = "relative path to lambdas"
  default     = "../../api/lambdas"
}
