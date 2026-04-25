output "state_bucket_name" {
  description = "S3 bucket holding Terraform state"
  value       = module.s3_backend.bucket_name
}

output "lock_table_name" {
  description = "DynamoDB table for state locking"
  value       = module.s3_backend.dynamodb_table_name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "ecr_repository_url" {
  description = "ECR repository URL (docker push target)"
  value       = module.ecr.repository_url
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}

output "jenkins_url_command" {
  description = "Command to get Jenkins LoadBalancer hostname"
  value       = module.jenkins.jenkins_url_command
}

output "argocd_server_command" {
  description = "Command to get Argo CD server hostname"
  value       = module.argo_cd.argocd_server_command
}

output "argocd_initial_password_command" {
  description = "Command to get initial Argo CD admin password"
  value       = module.argo_cd.argocd_initial_password_command
}

output "db_endpoint" {
  description = "Database connection endpoint"
  value       = module.rds.endpoint
}

output "db_port" {
  description = "Database port"
  value       = module.rds.port
}

output "grafana_portforward_command" {
  description = "Command to access Grafana on localhost:3000"
  value       = module.monitoring.grafana_portforward_command
}

output "prometheus_portforward_command" {
  description = "Command to access Prometheus on localhost:9090"
  value       = module.monitoring.prometheus_portforward_command
}
