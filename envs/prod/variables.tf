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

# -- EC2
variable "ami" {
  type = string
}

variable "frontend_instance_type" {
  type = string
}

variable "backend_instance_type" {
  type = string
}

variable "ai_instance_type" {
  type = string
}

variable "backend_port" {
  type = number
}

variable "user_data" {
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

# -- monitoring
variable "alert_email" {
  type        = string
  description = "CloudWatch 알림 수신 이메일"
}

# -- ssm
variable "discord_webhook_url" {
  type      = string
  sensitive = true
}

variable "google_api_key" {
  type      = string
  sensitive = true
}

variable "ai_base_url" {
  type = string
}