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
}

module "ecr" {
  source = "./modules/ecr"

  ecr_name     = var.ecr_repository_name
  scan_on_push = var.ecr_scan_on_push
}
