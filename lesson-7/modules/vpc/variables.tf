variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "CIDR blocks for the public subnets (one per availability zone, in order)"
  type        = list(string)
}

variable "private_subnets" {
  description = "CIDR blocks for the private subnets (one per availability zone, in order)"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones used to place subnets, in the same order as the subnet lists"
  type        = list(string)
}

variable "vpc_name" {
  description = "Name tag for the VPC and prefix for child resources"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name used for subnet tagging (kubernetes.io/cluster/<name>)"
  type        = string
}
