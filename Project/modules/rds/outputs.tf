output "endpoint" {
  description = "Primary database endpoint"
  value       = var.use_aurora ? aws_rds_cluster.main[0].endpoint : aws_db_instance.main[0].address
}

output "port" {
  description = "Database port"
  value       = var.use_aurora ? aws_rds_cluster.main[0].port : aws_db_instance.main[0].port
}

output "db_name" {
  description = "Name of the initial database"
  value       = var.db_name
}

output "security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}
