# -- common
variable "app" {
  type = string
}

variable "env" {
  type = string
}

variable "domain" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

# -- vpc
variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "azs" {
  type = list(string)
}

# -- RDS
variable "database_port" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "MYSQL_USER" {
  type = string
}

variable "MYSQL_PASSWORD" {
  type = string
}

variable "multi_az" {
  type    = bool
  default = false
}