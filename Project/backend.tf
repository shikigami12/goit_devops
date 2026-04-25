# Remote state backend (S3 + DynamoDB locking).
#
# IMPORTANT: comment this block out for the very first `terraform apply`
# (the s3_backend module must create the bucket/table first).
# After that apply, uncomment and run:
#
#   terraform init -migrate-state
#
# terraform {
#   backend "s3" {
#     bucket         = "eugenkhudoliiv-tfstate-project"
#     key            = "project/terraform.tfstate"
#     region         = "us-west-2"
#     dynamodb_table = "terraform-locks-project"
#     encrypt        = true
#   }
# }
