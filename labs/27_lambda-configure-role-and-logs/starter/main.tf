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
    lambda = var.ministack_endpoint
    iam = var.ministack_endpoint
    cloudwatchlogs = var.ministack_endpoint
    dynamodb = var.ministack_endpoint
  }
}

resource "random_id" "lab" {
  byte_length = 4
}

locals {
  name = "lab-27-${random_id.lab.hex}"
}

resource "aws_dynamodb_table" "orders" {
  name         = local.name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "order_id"

  attribute {
    name = "order_id"
    type = "S"
  }
}
output "table" {
  value = aws_dynamodb_table.orders.name
}

resource "aws_dynamodb_table_item" "fixture" {
  table_name = aws_dynamodb_table.orders.name
  hash_key   = aws_dynamodb_table.orders.hash_key
  item       = file("${path.module}/order.json")
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
      # Add the table-scoped DynamoDB statement here.
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
  # Add TABLE_NAME to the function environment.
  depends_on = [aws_iam_role_policy.function]
}
output "function" {
  value = aws_lambda_function.function.function_name
}
output "log_group" {
  value = aws_cloudwatch_log_group.function.name
}
