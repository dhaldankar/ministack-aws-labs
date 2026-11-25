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
    sns = var.ministack_endpoint
    sqs = var.ministack_endpoint
  }
}

resource "random_id" "lab" {
  byte_length = 4
}

locals {
  name = "lab-15-${random_id.lab.hex}"
}

resource "aws_sns_topic" "orders" {
  name = local.name
}

resource "aws_sqs_queue" "audit" {
  name = "${local.name}-audit"
}

resource "aws_sqs_queue_policy" "audit" {
  queue_url = aws_sqs_queue.audit.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.audit.arn
      Condition = { ArnEquals = { "aws:SourceArn" = aws_sns_topic.orders.arn } }
    }]
  })
}

resource "aws_sns_topic_subscription" "audit" {
  topic_arn = aws_sns_topic.orders.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.audit.arn
  depends_on = [aws_sqs_queue_policy.audit]
}
output "audit_url" {
  value = aws_sqs_queue.audit.url
}

resource "aws_sqs_queue" "billing" {
  name = "${local.name}-billing"
}

resource "aws_sqs_queue_policy" "billing" {
  queue_url = aws_sqs_queue.billing.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.billing.arn
      Condition = { ArnEquals = { "aws:SourceArn" = aws_sns_topic.orders.arn } }
    }]
  })
}

resource "aws_sns_topic_subscription" "billing" {
  topic_arn = aws_sns_topic.orders.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.billing.arn
  filter_policy_scope = "MessageAttributes"
  filter_policy = jsonencode({ status = ["paid", "cancelled"] }) # Edit this filter.
  depends_on = [aws_sqs_queue_policy.billing]
}
output "billing_url" {
  value = aws_sqs_queue.billing.url
}
output "topic_arn" {
  value = aws_sns_topic.orders.arn
}
output "billing_subscription" {
  value = aws_sns_topic_subscription.billing.arn
}
