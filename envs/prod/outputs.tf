output "instance_ids" {
  value = module.backend.instance_ids
}

output "alb_dns_name" {
  value = module.backend.alb_dns_name
}

output "rds_host" {
  value = module.database.host
}
