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

module "acm" {
  source = "../../modules/acm"

  app                       = var.app
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
}
