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
    eventbridge = var.ministack_endpoint
    sqs = var.ministack_endpoint
  }
}

resource "random_id" "lab" {
  byte_length = 4
}

locals {
  name = "lab-18-${random_id.lab.hex}"
}

resource "aws_sqs_queue" "orders" {
  name = "${local.name}-orders"
}

resource "aws_cloudwatch_event_bus" "orders" {
  name = local.name
}

resource "aws_cloudwatch_event_rule" "orders" {
  name           = "order-events"
  event_bus_name = aws_cloudwatch_event_bus.orders.name
  event_pattern  = jsonencode({
    source = ["lab.orders"]
    # Add a detail-type match here.
  })
}

resource "aws_sqs_queue_policy" "orders" {
  queue_url = aws_sqs_queue.orders.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.orders.arn
      Condition = { ArnEquals = { "aws:SourceArn" = aws_cloudwatch_event_rule.orders.arn } }
    }]
  })
}

resource "aws_cloudwatch_event_target" "orders" {
  rule           = aws_cloudwatch_event_rule.orders.name
  event_bus_name = aws_cloudwatch_event_bus.orders.name
  target_id      = "orders-queue"
  arn            = aws_sqs_queue.orders.arn
  depends_on     = [aws_sqs_queue_policy.orders]
}
output "bus" {
  value = aws_cloudwatch_event_bus.orders.name
}
output "queue_url" {
  value = aws_sqs_queue.orders.url
}
output "rule_arn" {
  value = aws_cloudwatch_event_rule.orders.arn
}
