# ----------------------------------------------------
# configure aws provider
# ----------------------------------------------------
provider "aws" {
    region = var.AWS_REGION
    access_key = var.AWS_ACCESS_KEY
    secret_key = var.AWS_SECRET_KEY
}

# ----------------------------------------------------
# create dynamo db for deployments locking 
# ----------------------------------------------------
resource "aws_dynamodb_table" "terraform_statelock" {
  name           = local.ddb_name
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# ----------------------------------------------------
# create S3 bucket that will be used for the backend
# ----------------------------------------------------
resource "aws_s3_bucket" "remote_state" {
  bucket        = local.state_bucket_name
  force_destroy = local.destroy_bucket

  tags = {
    Name    = "My tutorial bucket"
    Env     = local.env
  }
}

resource "aws_s3_bucket_versioning" "versioning_remote_state" {
  bucket = aws_s3_bucket.remote_state.id
  versioning_configuration {
    status = "Enabled"
  }
}
