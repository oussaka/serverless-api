resource "null_resource" "lambda_build" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "CGO_ENABLED=0 GOOS=linux go build -o ${var.lambda_path}/${var.function_name}/bootstrap ${var.lambda_path}/${var.function_name}/main.go"
  }
}

data "archive_file" "this" {
  depends_on  = [null_resource.lambda_build]
  source_file = "${var.lambda_path}/${var.function_name}/bootstrap"
  output_path = "${var.lambda_path}/${var.function_name}/bootstrap.zip"
  type        = "zip"
}

resource "aws_lambda_function" "this" {
  function_name                  = format("%s", var.function_name)
  filename                       = data.archive_file.this.output_path
  source_code_hash               = data.archive_file.this.output_base64sha256
  description                    = var.description
  role                           = var.role_arn
  handler                        = var.handler
  runtime                        = var.runtime
  publish                        = var.publish
  memory_size                    = var.memory_size
  reserved_concurrent_executions = var.concurrency
  timeout                        = var.lambda_timeout
  tags                           = var.tags
  layers                         = var.layers

  dynamic "vpc_config" {
    for_each = var.vpc_config == null ? [] : [var.vpc_config]
    content {
      security_group_ids = vpc_config.value.security_group_ids
      subnet_ids         = vpc_config.value.subnet_ids
    }
  }

  dynamic "tracing_config" {
    for_each = var.tracing_config == null ? [] : [var.tracing_config]
    content {
      mode = tracing_config.value.mode
    }
  }

  dynamic "environment" {
    for_each = var.environment == null ? [] : [var.environment]
    content {
      variables = var.environment
    }
  }

  lifecycle {
    ignore_changes = [
      filename,
    ]
  }

  depends_on = [aws_cloudwatch_log_group.this]
}

resource "aws_lambda_function_event_invoke_config" "this" {
  function_name                = aws_lambda_function.this.function_name
  qualifier                    = aws_lambda_function.this.version
  maximum_event_age_in_seconds = var.event_age_in_seconds
  maximum_retry_attempts       = var.retry_attempts
}

resource "aws_lambda_function_event_invoke_config" "latest" {
  function_name                = aws_lambda_function.this.function_name
  qualifier                    = "$LATEST"
  maximum_event_age_in_seconds = var.event_age_in_seconds
  maximum_retry_attempts       = var.retry_attempts
}

# Cloud watch
resource "aws_cloudwatch_log_group" "this" {
  name              = format("/aws/lambda/%s", var.function_name)
  retention_in_days = var.log_retention

  tags = merge(var.tags,
    { Function = format("%s", var.function_name) }
  )
}