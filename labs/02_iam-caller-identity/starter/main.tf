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

resource "aws_iam_role" "lab" {
  name = "ministack-iam-caller-identity-lab"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "*" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lab_inline" {
  name = "lab-inline-policy"
  role = aws_iam_role.lab.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = ["arn:aws:s3:::ministack-iam-caller-identity-lab/*"]
    }]
  })
}

output "role_arn" {
  value = aws_iam_role.lab.arn
}

output "role_name" {
  value = aws_iam_role.lab.name
}
