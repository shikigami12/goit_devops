variable "identifier" {
  description = "Base name for all RDS resources"
  type        = string
  default     = "project-db"
}

variable "use_aurora" {
  description = "Create an Aurora cluster (true) or plain RDS instance (false)"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "vpc_cidr_block" {
  description = "VPC CIDR — used for the security group ingress rule"
  type        = string
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Name of the initial database"
  type        = string
  default     = "devops"
}

variable "db_username" {
  description = "Master database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master database password"
  type        = string
  sensitive   = true
}

variable "engine" {
  description = "Engine for plain RDS instance"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Engine version for plain RDS instance"
  type        = string
  default     = "15.4"
}

variable "aurora_engine" {
  description = "Engine for Aurora cluster"
  type        = string
  default     = "aurora-postgresql"
}

variable "aurora_engine_version" {
  description = "Engine version for Aurora cluster"
  type        = string
  default     = "15.4"
}

variable "instance_class" {
  description = "DB instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GiB (plain RDS only)"
  type        = number
  default     = 20
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment (plain RDS only; Aurora is inherently multi-AZ)"
  type        = bool
  default     = false
}

variable "db_parameter_group_family" {
  description = "Parameter group family for plain RDS (e.g. postgres15)"
  type        = string
  default     = "postgres15"
}

variable "aurora_parameter_group_family" {
  description = "Parameter group family for Aurora (e.g. aurora-postgresql15)"
  type        = string
  default     = "aurora-postgresql15"
}

variable "max_connections" {
  description = "max_connections parameter value (plain RDS only)"
  type        = string
  default     = "100"
}

variable "log_statement" {
  description = "log_statement parameter value (none|ddl|mod|all)"
  type        = string
  default     = "none"
}

variable "work_mem" {
  description = "work_mem parameter value in kB"
  type        = string
  default     = "4096"
}
