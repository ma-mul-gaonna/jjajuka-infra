terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

module "ecr" {
  source = "../../modules/ecr"

  app = var.app
  env = var.env
}

module "vpc" {
  source = "../../modules/vpc"

  app                  = var.app
  env                  = var.env
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs
}

data "aws_acm_certificate" "jjajuka" {
  domain   = "jjajuka.site"
  statuses = ["ISSUED"]
}

module "backend" {
  source = "../../modules/backend"

  app = var.app
  env = var.env

  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids

  backend_port           = var.backend_port
  ami                    = var.ami
  frontend_instance_type = var.frontend_instance_type
  backend_instance_type  = var.backend_instance_type
  ai_instance_type       = var.ai_instance_type

  certificate_arn = data.aws_acm_certificate.jjajuka.arn
  user_data       = var.user_data
}

module "database" {
  source = "../../modules/database"

  app    = var.app
  env    = var.env
  domain = var.domain

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  instance_type         = var.instance_type
  database_port         = var.database_port
  MYSQL_USER            = var.MYSQL_USER
  MYSQL_PASSWORD        = var.MYSQL_PASSWORD
  multi_az              = var.multi_az
  app_security_group_id = module.backend.app_security_group_id
}

module "monitoring" {
  source = "../../modules/monitoring"

  app         = var.app
  env         = var.env
  alert_email = var.alert_email

  instance_ids   = module.backend.instance_ids
  rds_identifier = module.database.identifier
}