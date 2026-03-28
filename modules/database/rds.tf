# -- rds subnet group
resource "aws_db_subnet_group" "this" {
  name       = "${var.app}-${var.env}-rds-subnet-group"
  subnet_ids = module.vpc.private_subnet_ids

  tags = {
    Name = "${var.app}-${var.env}-rds-subnet-group"
  }
}

# -- rds instance
resource "aws_db_instance" "this" {
  identifier        = local.prefix
  engine            = "mysql"
  instance_class    = var.instance_type
  allocated_storage = 20
  storage_type      = "gp2"
  multi_az          = var.multi_az

  db_name  = var.app
  username = var.MYSQL_USER
  password = var.MYSQL_PASSWORD

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]

  skip_final_snapshot = true
  publicly_accessible = false

  tags = merge(
    local.tags, {
      Name = "${local.prefix}-${local.tags["tier"]}"
    }
  )
}

# -- rds security group
resource "aws_security_group" "db" {
  vpc_id = var.vpc_id

  name = "${local.prefix}-db-sg"

  ingress {
    from_port   = var.database_port
    to_port     = var.database_port
    protocol    = local.tcp_protocol
    cidr_blocks = local.all_ips
  }

  tags = merge(
    local.tags, {
      Name = "${local.prefix}-db-sg"
    }
  )
}