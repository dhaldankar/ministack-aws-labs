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
  name = "lab-38-${random_id.lab.hex}"
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
  count             = 2
  vpc_id            = aws_vpc.lab.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.lab.cidr_block, 8, count.index)
  tags = { Name = "${local.name}-public-${count.index}" }
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

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_iam_role" "app" {
  name = "${local.name}-app"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "app_ssm" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "app" {
  name = "${local.name}-app"
  role = aws_iam_role.app.name
}

resource "aws_security_group" "app" {
  name        = "${local.name}-app"
  description = "app security group"
  vpc_id      = aws_vpc.lab.id
}

resource "aws_vpc_security_group_egress_rule" "app_https" {
  security_group_id = aws_security_group.app.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}
output "app_sg" {
  value = aws_security_group.app.id
}

resource "aws_security_group" "alb" {
  name        = "${local.name}-alb"
  description = "alb security group"
  vpc_id      = aws_vpc.lab.id
}
output "alb_sg" {
  value = aws_security_group.alb.id
}

resource "aws_vpc_security_group_ingress_rule" "alb_app" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}

resource "aws_vpc_security_group_egress_rule" "app_alb" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}

resource "aws_vpc_security_group_egress_rule" "alb_to_target" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
}

resource "aws_vpc_security_group_ingress_rule" "app_alb" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
}

resource "aws_instance" "app" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.app.name
  user_data                   = file("${path.module}/app-user-data.sh")
  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted             = true
    delete_on_termination = true
  }

  tags = { Name = "${local.name}-app" }
  depends_on = [aws_route.internet, aws_iam_role_policy_attachment.app_ssm]
}
output "app_id" {
  value = aws_instance.app.id
}

resource "aws_lb_target_group" "app" {
  name        = "${local.name}-app"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.lab.id
  target_type = "instance"
  deregistration_delay = 10

  health_check {
    path                = "/health"
    matcher             = "200"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app.id
  port             = 8080
}
output "app_target_group" {
  value = aws_lb_target_group.app.arn
}

resource "aws_lb" "lab" {
  name               = local.name
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.lab.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
output "alb_dns" {
  value = aws_lb.lab.dns_name
}
output "alb_arn" {
  value = aws_lb.lab.arn
}
output "listener_arn" {
  value = aws_lb_listener.http.arn
}
