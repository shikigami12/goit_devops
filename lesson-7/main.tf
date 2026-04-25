terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "devops-coursework"
      Lesson    = "lesson-7"
      ManagedBy = "Terraform"
    }
  }
}

variable "aws_region" {
  description = "AWS region used for all resources in lesson-7"
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
  default     = "eugenkhudoliiv-tfstate-lesson-7"
}

variable "lock_table_name" {
  description = "DynamoDB table name used for Terraform state locking"
  type        = string
  default     = "terraform-locks-lesson-7"
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
  default     = "lesson-7-vpc"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "lesson-7-django"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "lesson-7-eks"
}

module "s3_backend" {
  source = "./modules/s3-backend"

  bucket_name = var.state_bucket_name
  table_name  = var.lock_table_name
}

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr_block     = var.vpc_cidr_block
  public_subnets     = var.public_subnet_cidrs
  private_subnets    = var.private_subnet_cidrs
  availability_zones = var.availability_zones
  vpc_name           = var.vpc_name
  cluster_name       = var.cluster_name
}

module "ecr" {
  source = "./modules/ecr"

  ecr_name = var.ecr_repository_name
}

module "eks" {
  source = "./modules/eks"

  cluster_name = var.cluster_name
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids
}
