variable "aws_region" {
  description = "AWS region used for all resources in lesson-5"
  type        = string
  default     = "us-west-2"
}

variable "availability_zones" {
  description = "Availability zones used for the VPC subnets (must match aws_region)"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform remote state"
  type        = string
  default     = "eugenkhudoliiv-tfstate-lesson-5"
}

variable "lock_table_name" {
  description = "DynamoDB table name used for Terraform state locking"
  type        = string
  default     = "terraform-locks"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets (one per availability zone)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets (one per availability zone)"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "vpc_name" {
  description = "Name tag applied to the VPC and used as prefix for child resources"
  type        = string
  default     = "lesson-5-vpc"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "lesson-5-ecr"
}

variable "ecr_scan_on_push" {
  description = "Whether to enable automatic image scanning on push"
  type        = bool
  default     = true
}
