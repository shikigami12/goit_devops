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
#     bucket         = "eugenkhudoliiv-tfstate-lesson-8"
#     key            = "lesson-8/terraform.tfstate"
#     region         = "us-west-2"
#     dynamodb_table = "terraform-locks-lesson-8"
#     encrypt        = true
#   }
# }
