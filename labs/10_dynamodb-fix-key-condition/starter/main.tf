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
  name         = "ministack-ddb-fix-query"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "customer_id"
  range_key    = "order_id"

  attribute {
    name = "customer_id"
    type = "S"
  }

  attribute {
    name = "order_id"
    type = "S"
  }
}

# Pre-populate both customer partitions
resource "aws_dynamodb_table_item" "alice_1" {
  table_name = aws_dynamodb_table.orders.name
  hash_key   = aws_dynamodb_table.orders.hash_key
  range_key  = aws_dynamodb_table.orders.range_key

  item = jsonencode({
    customer_id = { S = "alice" }
    order_id    = { S = "ord-100" }
    status      = { S = "pending" }
    amount      = { N = "42" }
  })
}

resource "aws_dynamodb_table_item" "alice_2" {
  table_name = aws_dynamodb_table.orders.name
  hash_key   = aws_dynamodb_table.orders.hash_key
  range_key  = aws_dynamodb_table.orders.range_key

  item = jsonencode({
    customer_id = { S = "alice" }
    order_id    = { S = "ord-200" }
    status      = { S = "shipped" }
    amount      = { N = "99" }
  })
}

resource "aws_dynamodb_table_item" "bob_1" {
  table_name = aws_dynamodb_table.orders.name
  hash_key   = aws_dynamodb_table.orders.hash_key
  range_key  = aws_dynamodb_table.orders.range_key

  item = jsonencode({
    customer_id = { S = "bob" }
    order_id    = { S = "ord-101" }
    status      = { S = "delivered" }
    amount      = { N = "15" }
  })
}

output "table" {
  value = aws_dynamodb_table.orders.name
}

output "hint" {
  value = "broken-query.sh uses 'status' as the key condition. Inspect the table's KeySchema."
}
