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

variable "lab_aws_account_id" {
  description = "Account ID of the disposable AWS sandbox"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.lab_aws_account_id)) && var.lab_aws_account_id != "000000000000"
    error_message = "Supply the 12-digit AWS sandbox account ID."
  }
}

provider "aws" {
  region              = "us-east-1"
  allowed_account_ids = [var.lab_aws_account_id]
}

resource "random_id" "lab" {
  byte_length = 4
}

locals {
  name = "lab-23-${random_id.lab.hex}"
}

resource "aws_s3_bucket" "lab" {
  bucket        = "cloudtrail-${local.name}-${var.lab_aws_account_id}"
  force_destroy = true
}
output "bucket" {
  value = aws_s3_bucket.lab.bucket
}
