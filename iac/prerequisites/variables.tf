variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_KEY" {}

variable "AWS_AMIS" {
    type = map
    default = {
        # "us-east-1" = "ami-085925f297f89fce1"
        "us-east-2" = "ami-07c1207a9d40bc3bd"
    }
}

variable "AWS_REGION" {
    type = string
    default = "us-east-2"
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
