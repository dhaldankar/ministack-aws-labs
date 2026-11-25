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
    s3 = var.ministack_endpoint
  }
}

resource "aws_s3_bucket" "lab" {
  bucket_prefix = "ministack-s3-delete-marker-"
}

resource "aws_s3_bucket_versioning" "lab" {
  bucket = aws_s3_bucket.lab.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Seed the original report object
resource "aws_s3_object" "report" {
  bucket  = aws_s3_bucket.lab.id
  key     = "report.txt"
  content = "quarterly report: all systems operational"
  depends_on = [aws_s3_bucket_versioning.lab]
}

output "bucket" {
  value = aws_s3_bucket.lab.id
}

output "object_key" {
  value = aws_s3_object.report.key
}

output "original_content" {
  value = aws_s3_object.report.content
}
