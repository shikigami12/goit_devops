output "state_bucket_name" {
  description = "Name of the S3 bucket holding Terraform state"
  value       = module.s3_backend.bucket_name
}

output "lock_table_name" {
  description = "DynamoDB table used for Terraform state locking"
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
  description = "URL of the ECR repository (docker push target)"
  value       = module.ecr.repository_url
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint URL of the EKS API server"
  value       = module.eks.cluster_endpoint
}

output "kubeconfig_command" {
  description = "Command to update local kubeconfig with cluster credentials"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}
