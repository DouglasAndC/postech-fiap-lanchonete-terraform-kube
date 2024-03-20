resource "aws_security_group" "vpc_link" {
  name   = "vpc-link"
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_apigatewayv2_vpc_link" "eks" {
  name               = "eks"
  security_group_ids = [aws_security_group.vpc_link.id]
  subnet_ids = [
    aws_subnet.private-us-east-1a.id,
    aws_subnet.private-us-east-1b.id
  ]
}

resource "aws_apigatewayv2_integration" "eks_lanchonete" {
  api_id = aws_apigatewayv2_api.apigw_http_endpoint.id

  integration_uri    = "arn:aws:elasticloadbalancing:us-east-1:344419620370:listener/net/a8fd1469ce837426bafa9cb2693cdcaa/ada1a617a6dd1afc/a99a5d0cec961163"
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.eks.id
}

resource "aws_apigatewayv2_route" "any_lanchonete" {
  api_id = aws_apigatewayv2_api.apigw_http_endpoint.id

  route_key = "ANY /lanchonete/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.eks_lanchonete.id}"
}