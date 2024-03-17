provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "postech_fiap_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc_postech_fiap"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.postech_fiap_vpc.id

  tags = {
    Name = "postech_fiap_vpc_internet_gw"
  }
}

resource "aws_subnet" "postech_fiap_private_subnet1" {
  vpc_id                  = aws_vpc.postech_fiap_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "postech_fiap_private_subnet1"
  }
}

resource "aws_subnet" "postech_fiap_private_subnet2" {
  vpc_id                  = aws_vpc.postech_fiap_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "postech_fiap_private_subnet2"
  }
}

resource "aws_subnet" "postech_fiap_public_subnet1" {
  vpc_id                  = aws_vpc.postech_fiap_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"

  tags = {
    Name = "postech_fiap_public_subnet1"
  }
}

resource "aws_subnet" "postech_fiap_public_subnet2" {
  vpc_id                  = aws_vpc.postech_fiap_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"

  tags = {
    Name = "postech_fiap_public_subnet2"
  }
}

resource "aws_api_gateway_vpc_link" "postech_fiap_gateway" {
  name        = "postech-fiap-alb"
  description = "postech-fiap-alb"
  target_arns = [aws_lb.postech_fiap_alb.arn]
}

resource "aws_lb" "postech_fiap_alb" {
  name               = "postech-fiap-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.postech_fiap_alb_sg.id]
  subnets            = [aws_subnet.postech_fiap_private_subnet1.id, aws_subnet.postech_fiap_private_subnet2.id]
}

resource "aws_security_group" "postech_fiap_alb_sg" {
  name        = "alb-sg"
  description = "Security Group for ALB"
  vpc_id      = aws_vpc.postech_fiap_vpc.id

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

resource "aws_eks_cluster" "eks_cluster" {
  name     = "lanchonete-cluster"
  version  = "1.29"
  role_arn = "arn:aws:iam::992382762661:role/LabRole"
  vpc_config {
    subnet_ids         = [aws_subnet.postech_fiap_private_subnet1.id, aws_subnet.postech_fiap_private_subnet2.id]
    security_group_ids = [aws_security_group.postech_fiap_eks_sg.id]
  }
}

resource "aws_security_group" "postech_fiap_eks_sg" {
  name        = "eks-sg"
  description = "Security Group for EKS"
  vpc_id      = aws_vpc.postech_fiap_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
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