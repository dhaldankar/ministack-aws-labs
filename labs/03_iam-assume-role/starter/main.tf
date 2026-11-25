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
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  skip_region_validation      = true

  endpoints {
    iam = var.ministack_endpoint
    sts = var.ministack_endpoint
    s3  = var.ministack_endpoint
  }
}

resource "aws_s3_bucket" "lab" {
  bucket_prefix = "ministack-assume-role-lab-"
}

resource "aws_s3_object" "target" {
  bucket  = aws_s3_bucket.lab.id
  key     = "allowed/data.txt"
  content = "this is the allowed object for the assume-role lab"
}

resource "aws_s3_object" "control" {
  bucket  = aws_s3_bucket.lab.id
  key     = "restricted/data.txt"
  content = "this object is outside the role grant"
}

resource "aws_iam_role" "lab" {
  name = "ministack-assume-role-lab-${aws_s3_bucket.lab.id}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "*" }
      Action    = "sts:AssumeRole"
    }]
  })
}

output "bucket" {
  value = aws_s3_bucket.lab.id
}

output "target_key" {
  value = aws_s3_object.target.key
}

output "control_key" {
  value = aws_s3_object.control.key
}

output "role_arn" {
  value = aws_iam_role.lab.arn
}

output "role_name" {
  value = aws_iam_role.lab.name
}

output "policy_object_arn" {
  value = aws_s3_object.target.arn
}
