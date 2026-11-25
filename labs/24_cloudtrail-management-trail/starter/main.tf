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
  name = "lab-24-${random_id.lab.hex}"
}

resource "aws_s3_bucket" "lab" {
  bucket        = "cloudtrail-${local.name}-${var.lab_aws_account_id}"
  force_destroy = true
}
output "bucket" {
  value = aws_s3_bucket.lab.bucket
}

locals {
  trail_arn = "arn:aws:cloudtrail:us-east-1:${var.lab_aws_account_id}:trail/${local.name}"
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.lab.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.lab.arn
        Condition = { StringEquals = { "aws:SourceArn" = local.trail_arn } }
      },
      {
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.lab.arn}/AWSLogs/${var.lab_aws_account_id}/*"
        Condition = { StringEquals = {
          "aws:SourceArn" = local.trail_arn
          "s3:x-amz-acl"  = "bucket-owner-full-control"
        } }
      }
    ]
  })
}

resource "aws_cloudtrail" "lab" {
  name                          = local.name
  s3_bucket_name                = aws_s3_bucket.lab.bucket
  include_global_service_events = false
  is_multi_region_trail         = false
  enable_logging                = false # Enable this and configure the event selector.
  depends_on                    = [aws_s3_bucket_policy.cloudtrail]
}
output "trail" {
  value = aws_cloudtrail.lab.name
}
