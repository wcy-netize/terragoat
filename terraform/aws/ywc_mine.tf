# 1. AWS Provider Configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 2. Virtual Private Cloud (VPC)
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# 3. Public Subnets
resource "aws_subnet" "public" {
  for_each          = toset(["us-east-1a", "us-east-1b"])
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.key == "us-east-1a" ? "10.0.1.0/24" : "10.0.2.0/24"
  availability_zone = each.key
}

# 4. Security Group
resource "aws_security_group" "external" {
  name        = "external-alb-sg"
  description = "Security group for load balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 5. Application Load Balancer
resource "aws_alb" "main" {
  name            = "demo-load-balancer"
  subnets         = [for subnet in aws_subnet.public : "${subnet.id}"]
  security_groups = [aws_security_group.external.id]
}
