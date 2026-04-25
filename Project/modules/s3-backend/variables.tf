variable "bucket_name" {
  description = "Globally unique S3 bucket name for Terraform remote state"
  type        = string
}

variable "table_name" {
  description = "DynamoDB table name used for Terraform state locking"
  type        = string
}
