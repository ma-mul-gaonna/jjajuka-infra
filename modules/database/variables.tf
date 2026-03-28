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

# -- vpc
variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(any)
}