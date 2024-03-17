provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc_postech_fiap"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform = "true"
  }
}

resource "aws_security_group" "lb_security_group" {
  name        = "lb_security_group_postech_fiap"
  description = "LoadBalancer Security Group Postech Fiap"
  vpc_id      = module.vpc.vpc_id
  ingress {
    description = "Allow from anyone on port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow from anyone on port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
}

resource "aws_lb" "alb_eks" {
  name               = "alb-eks-postech-fiap"
  load_balancer_type = "application"
  internal           = true
  subnets            = module.vpc.private_subnets
  security_groups    = [aws_security_group.lb_security_group.id]
}

resource "aws_lb_target_group" "alb_eks_tg" {
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_lb_listener" "eks_alb_listener" {
  load_balancer_arn = aws_lb.alb_eks.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_eks_tg.arn
  }
}

resource "aws_apigatewayv2_vpc_link" "vpclink_apigw_to_alb" {
  name               = "vpclink_apigw_to_alb_postech_fiap"
  security_group_ids = []
  subnet_ids         = module.vpc.private_subnets
}

resource "aws_apigatewayv2_api" "apigw_http_endpoint" {
  name          = "lanchonete-pvt-endpoint"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "apigw_integration" {
  api_id           = aws_apigatewayv2_api.apigw_http_endpoint.id
  integration_type = "HTTP_PROXY"
  integration_uri  = aws_lb_listener.eks_alb_listener.arn

  integration_method     = "ANY"
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.vpclink_apigw_to_alb.id
  payload_format_version = "1.0"
  depends_on = [aws_apigatewayv2_vpc_link.vpclink_apigw_to_alb,
    aws_apigatewayv2_api.apigw_http_endpoint,
  aws_lb_listener.eks_alb_listener]
}

resource "aws_apigatewayv2_route" "apigw_route" {
  api_id     = aws_apigatewayv2_api.apigw_http_endpoint.id
  route_key  = "ANY /lanchonete/{proxy+}"
  target     = "integrations/${aws_apigatewayv2_integration.apigw_integration.id}"
  depends_on = [aws_apigatewayv2_integration.apigw_integration]
}

resource "aws_apigatewayv2_stage" "apigw_stage" {
  api_id      = aws_apigatewayv2_api.apigw_http_endpoint.id
  name        = "$default"
  auto_deploy = true
  depends_on  = [aws_apigatewayv2_api.apigw_http_endpoint]
}

output "apigw_endpoint" {
  value       = aws_apigatewayv2_api.apigw_http_endpoint.api_endpoint
  description = "API Gateway Endpoint"
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = "lanchonete-cluster"
  version  = "1.29"
  role_arn = "arn:aws:iam::767398144542:role/LabRole"
  vpc_config {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [aws_security_group.lb_security_group.id]
  }
}

resource "aws_eks_node_group" "eks_node_group_t3_medium" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "eks_node_group_t3_medium"
  node_role_arn   = "arn:aws:iam::767398144542:role/LabRole"
  subnet_ids      = module.vpc.private_subnets
  instance_types  = ["t3.medium"]
  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
}