# -- Frontend Security Group
resource "aws_security_group" "frontend" {
  vpc_id = var.vpc_id
  name   = "${local.prefix}-frontend-sg"

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = local.all_protocol
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = local.all_protocol
    cidr_blocks = local.all_ips
  }

  tags = merge(local.tags, { Name = "${local.prefix}-frontend-sg" })
}

# -- ALB Security Group
resource "aws_security_group" "alb" {
  vpc_id = var.vpc_id
  name   = "${local.prefix}-alb-sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = local.tcp_protocol
    cidr_blocks = local.all_ips
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = local.tcp_protocol
    cidr_blocks = local.all_ips
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = local.all_protocol
    cidr_blocks = local.all_ips
  }

  tags = merge(local.tags, { Name = "${local.prefix}-alb-sg" })
}

# -- Backend Security Group
resource "aws_security_group" "app" {
  vpc_id = var.vpc_id
  name   = "${local.prefix}-app-sg"

  ingress {
    from_port       = var.backend_port
    to_port         = var.backend_port
    protocol        = local.tcp_protocol
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = local.all_protocol
    cidr_blocks = local.all_ips
  }

  tags = merge(local.tags, { Name = "${local.prefix}-app-sg" })
}

# -- AI Security Group
resource "aws_security_group" "ai" {
  vpc_id = var.vpc_id
  name   = "${local.prefix}-ai-sg"

  ingress {
    from_port       = var.ai_port
    to_port         = var.ai_port
    protocol        = local.tcp_protocol
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = local.all_protocol
    cidr_blocks = local.all_ips
  }

  tags = merge(local.tags, { Name = "${local.prefix}-ai-sg" })
}

# -- Frontend Instance
resource "aws_instance" "frontend" {
  ami                  = var.ami
  instance_type        = var.frontend_instance_type
  subnet_id            = var.public_subnet_ids[0]
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm.name

  vpc_security_group_ids = [aws_security_group.frontend.id]
  tags = merge(local.tags, { Name = "${local.prefix}-frontend" })
}

# -- Backend Instance
resource "aws_instance" "app" {
  ami                  = var.ami
  instance_type        = var.backend_instance_type
  subnet_id            = var.public_subnet_ids[0]
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm.name

  vpc_security_group_ids = [aws_security_group.app.id]
  tags = merge(local.tags, { Name = "${local.prefix}-app" })
}

# -- AI Instance
resource "aws_instance" "ai" {
  ami                  = var.ami
  instance_type        = var.ai_instance_type
  subnet_id            = var.public_subnet_ids[0]
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm.name

  vpc_security_group_ids = [aws_security_group.ai.id]
  tags = merge(local.tags, { Name = "${local.prefix}-ai" })
}
