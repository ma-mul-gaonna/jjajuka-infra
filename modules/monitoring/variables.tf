variable "app" {
  type = string
}

variable "env" {
  type = string
}

variable "alert_email" {
  type        = string
  description = "SNS 알림 수신 이메일"
}

variable "instance_ids" {
  type = object({
    frontend = string
    app      = string
    ai       = string
  })
  description = "EC2 인스턴스 ID 맵"
}

variable "rds_identifier" {
  type        = string
  description = "RDS 인스턴스 식별자"
}

variable "cpu_threshold" {
  type        = number
  default     = 80
  description = "CPU 사용률 알림 임계값 (%)"
}

variable "rds_free_storage_threshold" {
  type        = number
  default     = 2147483648 # 2GB
  description = "RDS 남은 스토리지 알림 임계값 (bytes)"
}

variable "rds_connections_threshold" {
  type        = number
  default     = 100
  description = "RDS DB 연결 수 알림 임계값"
}
