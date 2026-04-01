output "certificate_arn" {
  description = "dev/prod ALB에서 공유하는 ACM 인증서 ARN"
  value       = module.acm.certificate_arn
}

output "domain_validation_options" {
  description = "가비아에 등록할 CNAME 레코드"
  value       = module.acm.domain_validation_options
}
