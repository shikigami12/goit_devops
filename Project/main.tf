terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "devops-coursework"
      Lesson    = "Project"
      ManagedBy = "Terraform"
    }
  }
}

data "aws_eks_cluster" "main" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "main" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-west-2"
}

variable "availability_zones" {
  description = "Availability zones for VPC subnets"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform remote state"
  type        = string
  default     = "eugenkhudoliiv-tfstate-project"
}

variable "lock_table_name" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = "terraform-locks-project"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "vpc_name" {
  description = "Name tag for the VPC"
  type        = string
  default     = "project-vpc"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "project-django"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "project-eks"
}

variable "jenkins_admin_password" {
  description = "Jenkins admin password"
  type        = string
  sensitive   = true
  default     = "changeme"
}

variable "git_repo_url" {
  description = "Git repository URL that Argo CD watches"
  type        = string
  default     = "https://github.com/REPLACE_ME/devops.git"
}

variable "git_repo_path" {
  description = "Path within the git repo to the django-app Helm chart"
  type        = string
  default     = "Project/charts/django-app"
}

variable "target_revision" {
  description = "Git branch Argo CD tracks"
  type        = string
  default     = "main"
}

variable "use_aurora" {
  description = "Use Aurora cluster (true) or plain RDS instance (false)"
  type        = bool
  default     = false
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "devops"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "devops"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
  default     = "changeme_db"
}

module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = var.state_bucket_name
  table_name  = var.lock_table_name
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = var.vpc_cidr_block
  public_subnets     = var.public_subnet_cidrs
  private_subnets    = var.private_subnet_cidrs
  availability_zones = var.availability_zones
  vpc_name           = var.vpc_name
  cluster_name       = var.cluster_name
}

module "ecr" {
  source   = "./modules/ecr"
  ecr_name = var.ecr_repository_name
}

module "eks" {
  source       = "./modules/eks"
  cluster_name = var.cluster_name
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids
}

module "jenkins" {
  source         = "./modules/jenkins"
  admin_password = var.jenkins_admin_password
  depends_on     = [module.eks]
}

module "argo_cd" {
  source          = "./modules/argo_cd"
  git_repo_url    = var.git_repo_url
  git_repo_path   = var.git_repo_path
  target_revision = var.target_revision
  depends_on      = [module.eks]
}

module "rds" {
  source = "./modules/rds"

  identifier     = "project-db"
  use_aurora     = var.use_aurora
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnet_ids
  vpc_cidr_block = var.vpc_cidr_block
  db_name        = var.db_name
  db_username    = var.db_username
  db_password    = var.db_password

  depends_on = [module.vpc]
}
