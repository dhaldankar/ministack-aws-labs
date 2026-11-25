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
  name = "lab-32-${random_id.lab.hex}"
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "lab" {
  cidr_block           = "10.42.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = local.name }
}

resource "aws_subnet" "public" {
  count             = 1
  vpc_id            = aws_vpc.lab.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.lab.cidr_block, 8, count.index)
  tags = { Name = "${local.name}-public-${count.index}" }
}

resource "aws_subnet" "private" {
  count             = 1
  vpc_id            = aws_vpc.lab.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.lab.cidr_block, 8, count.index + 10)
  tags = { Name = "${local.name}-private-${count.index}" }
}

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id
  tags = { Name = local.name }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab.id
  tags = { Name = "${local.name}-public" }
}

resource "aws_route" "internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.lab.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.lab.id
  tags = { Name = "${local.name}-private" }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
output "vpc" {
  value = aws_vpc.lab.id
}
output "public_subnets" {
  value = aws_subnet.public[*].id
}
output "public_route_table" {
  value = aws_route_table.public.id
}
output "gateway" {
  value = aws_internet_gateway.lab.id
}
output "private_subnets" {
  value = aws_subnet.private[*].id
}
output "private_route_table" {
  value = aws_route_table.private.id
}
