provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "postech_fiap_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc_postech_fiap"
  }
}

resource "aws_internet_gateway" "postech_fiap_igw" {
  vpc_id = aws_vpc.postech_fiap_vpc.id
}

resource "aws_subnet" "postech_fiap_eks_subnet1" {
  vpc_id            = aws_vpc.postech_fiap_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "eks_subnet_postech_fiap_1"
  }
}

resource "aws_subnet" "postech_fiap_eks_subnet2" {
  vpc_id            = aws_vpc.postech_fiap_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "eks_subnet_postech_fiap_2"
  }
}

resource "aws_eks_cluster" "eks_cluster" {
  name        = "lanchonete-cluster"
  version     = "1.29"
  role_arn    = "arn:aws:iam::992382762661:role/LabRole"
  vpc_config {
    subnet_ids         = [aws_subnet.postech_fiap_eks_subnet1.id, aws_subnet.postech_fiap_eks_subnet2.id]
    security_group_ids = [aws_security_group.postech_fiap_eks_sg.id]
  }
}

resource "aws_security_group" "postech_fiap_elb_sg" {
  name        = "elb-sg"
  description = "Security Group for ELB"
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

resource "aws_elb" "postech_fiap_elb" {
  name            = "postech-fiap-elb"
  subnets         = [aws_subnet.postech_fiap_eks_subnet1.id, aws_subnet.postech_fiap_eks_subnet2.id]
  security_groups = [aws_security_group.postech_fiap_elb_sg.id]

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }
}

resource "aws_api_gateway_vpc_link" "postech_fiap_vpc_link" {
  name        = "vpc_link_postech_fiap"
  description = "VPC Link Postech Fiap"
  target_arns = [aws_elb.postech_fiap_elb.arn]
}