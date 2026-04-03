output "instance_ids" {
  value = module.backend.instance_ids
}

output "rds_host" {
  value = module.database.host
}