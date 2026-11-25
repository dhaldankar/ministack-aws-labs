terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source = "hashicorp/random"
    }
    archive = {
      source = "hashicorp/archive"
    }
  }
}

variable "ministack_endpoint" {
  type    = string
  default = "http://localhost:4567"
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  skip_region_validation      = true

  endpoints {
    apigatewayv2 = var.ministack_endpoint
    lambda = var.ministack_endpoint
    iam = var.ministack_endpoint
    cloudwatchlogs = var.ministack_endpoint
  }
}

resource "random_id" "lab" {
  byte_length = 4
}

locals {
  name = "lab-31-${random_id.lab.hex}"
}

resource "aws_cloudwatch_log_group" "function" {
  name              = "/aws/lambda/${local.name}"
  retention_in_days = 1
}

resource "aws_iam_role" "function" {
  name = local.name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "function" {
  name = "function-access"
  role = aws_iam_role.function.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "${aws_cloudwatch_log_group.function.arn}:*"
    }], [

    ])
  })
}

data "archive_file" "function" {
  type        = "zip"
  source_file = "${path.module}/handler.py"
  output_path = "${path.module}/handler.zip"
}

resource "aws_lambda_function" "function" {
  function_name    = local.name
  filename         = data.archive_file.function.output_path
  source_code_hash = data.archive_file.function.output_base64sha256
  role             = aws_iam_role.function.arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  timeout          = 10

  depends_on = [aws_iam_role_policy.function]
}
output "function" {
  value = aws_lambda_function.function.function_name
}
output "log_group" {
  value = aws_cloudwatch_log_group.function.name
}

resource "aws_apigatewayv2_api" "lab" {
  name          = local.name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "function" {
  api_id                 = aws_apigatewayv2_api.lab.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.function.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "lab" {
  for_each = toset(["POST /orders/{id}"])
  api_id   = aws_apigatewayv2_api.lab.id
  route_key = each.value
  target    = "integrations/${aws_apigatewayv2_integration.function.id}"
}

resource "aws_apigatewayv2_stage" "lab" {
  api_id      = aws_apigatewayv2_api.lab.id
  name        = "v1"
  auto_deploy = true
}

resource "aws_lambda_permission" "api" {
  statement_id  = "AllowLabApi"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lab.execution_arn}/*/*/*"
}
output "api_id" {
  value = aws_apigatewayv2_api.lab.id
}
output "stage" {
  value = aws_apigatewayv2_stage.lab.name
}
