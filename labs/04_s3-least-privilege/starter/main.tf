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
    s3  = var.ministack_endpoint
    sts = var.ministack_endpoint
  }
}

resource "aws_s3_bucket" "workshop" {
  bucket_prefix = "ministack-iam-lab-"
}

resource "aws_s3_object" "seed" {
  bucket  = aws_s3_bucket.workshop.id
  key     = "welcome.txt"
  content = "hello from the MiniStack IAM lab"
}

resource "aws_s3_object" "restricted" {
  bucket  = aws_s3_bucket.workshop.id
  key     = "restricted.txt"
  content = "this object is outside the learner's grant"
}

resource "aws_iam_user" "learner" {
  name = aws_s3_bucket.workshop.id
}

output "bucket" {
  value = aws_s3_bucket.workshop.id
}

output "object_key" {
  value = aws_s3_object.seed.key
}

output "learner" {
  value = aws_iam_user.learner.name
}
