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
    dynamodb = var.ministack_endpoint
  }
}

resource "aws_dynamodb_table" "orders" {
  name         = "ministack-ddb-query-orders"
  billing_mode = "PAY_PER_REQUEST"

  # TODO: set hash_key to customer_id and range_key to order_id
  hash_key  = ""
  range_key = ""

  # TODO: add attribute blocks for customer_id (S) and order_id (S)
}

output "table" {
  value = aws_dynamodb_table.orders.name
}
