output "certificate_arn" {
  description = "ACM 인증서 ARN"
  value       = aws_acm_certificate.this.arn
}

output "domain_validation_options" {
  description = "DNS 검증용 CNAME 레코드 목록 (가비아에 직접 등록)"
  value       = aws_acm_certificate.this.domain_validation_options
}
