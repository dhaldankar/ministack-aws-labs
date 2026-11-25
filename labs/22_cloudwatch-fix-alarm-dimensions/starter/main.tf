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
    cloudwatch = var.ministack_endpoint
  }
}

resource "random_id" "lab" {
  byte_length = 4
}

locals {
  name = "lab-22-${random_id.lab.hex}"
}

resource "aws_cloudwatch_metric_alarm" "backlog" {
  alarm_name          = local.name
  namespace           = "Lab/${local.name}"
  metric_name         = "Backlog"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 60
  statistic           = "Maximum"
  threshold           = 10 # The desired threshold is 10.
  treat_missing_data  = "missing"
  actions_enabled     = false

  dimensions = {
    Queue = "order" # The publisher uses Queue=orders.
  }
}
output "alarm" {
  value = aws_cloudwatch_metric_alarm.backlog.alarm_name
}
output "namespace" {
  value = aws_cloudwatch_metric_alarm.backlog.namespace
}
