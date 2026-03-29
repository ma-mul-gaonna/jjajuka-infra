output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "app_security_group_id" {
  value = aws_security_group.app.id
}

output "instance_ids" {
  value = {
    frontend = aws_instance.frontend.id
    app      = aws_instance.app.id
    ai       = aws_instance.ai.id
  }
}
