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

module "vpc" {
  source = "../../modules/vpc"

  app                  = var.app
  env                  = var.env
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs
}

module "database" {
  source = "../../modules/database"

  app    = var.app
  env    = var.env
  domain = var.domain

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  instance_type  = var.instance_type
  database_port  = var.database_port
  MYSQL_USER     = var.MYSQL_USER
  MYSQL_PASSWORD = var.MYSQL_PASSWORD
  multi_az       = var.multi_az
}