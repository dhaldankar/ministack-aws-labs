terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "ministack_endpoint" {
  description = "HTTP endpoint of the MiniStack instance for this lab."
  type        = string
  default     = "http://localhost:4567"
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
    sqs = var.ministack_endpoint
  }
}

resource "aws_sqs_queue" "dlq" {
  name = "ministack-sqs-redrive-dlq"
}

resource "aws_sqs_queue" "work" {
  name = "ministack-sqs-redrive-work"

  # TODO: set a short visibility timeout (e.g. 10 seconds)
  visibility_timeout_seconds = 30

  # TODO: set redrive_policy using dlq.arn and maxReceiveCount of 2
  # redrive_policy = jsonencode({
  #   deadLetterTargetArn = aws_sqs_queue.dlq.arn
  #   maxReceiveCount     = 2
  # })
}

output "queue_url" {
  value = aws_sqs_queue.work.url
}

output "dlq_url" {
  value = aws_sqs_queue.dlq.url
}

output "dlq_arn" {
  value = aws_sqs_queue.dlq.arn
}
