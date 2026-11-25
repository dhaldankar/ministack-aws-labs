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
    sqs = var.ministack_endpoint
  }
}

resource "random_id" "lab" {
  byte_length = 4
}

locals {
  name = "lab-13-${random_id.lab.hex}"
}

resource "aws_sqs_queue" "dlq" {
  name = "${local.name}-dlq"
}

resource "aws_sqs_queue" "source" {
  name                       = "${local.name}-source"
  visibility_timeout_seconds = 4

  # Add a redrive policy targeting the DLQ with maxReceiveCount 2.
}
output "source_url" {
  value = aws_sqs_queue.source.url
}
output "dlq_url" {
  value = aws_sqs_queue.dlq.url
}
output "dlq_arn" {
  value = aws_sqs_queue.dlq.arn
}
