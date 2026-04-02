# -- common
variable "app" {
  type = string
}

variable "env" {
  type = string
}

# -- ec2
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

variable "ai_port" {
  type    = number
  default = 8000
}

# -- vpc
variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "certificate_arn" {
  type        = string
  description = "HTTPS 리스너에 사용할 ACM 인증서 ARN"
}

variable "user_data" {
  type = string
}

