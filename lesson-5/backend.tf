# Remote state backend (S3 + DynamoDB locking).
#
# IMPORTANT: the bucket and DynamoDB table referenced below are *created* by
# the s3_backend module in this same configuration, so this file MUST stay
# commented out for the very first `terraform apply`. After that initial
# apply succeeds, uncomment the block and run:
#
#   terraform init -migrate-state
#
# to migrate the local state file into S3. See README.md for the full
# bootstrap procedure.
#
# terraform {
#   backend "s3" {
#     bucket         = "eugenkhudoliiv-tfstate-lesson-5"
#     key            = "lesson-5/terraform.tfstate"
#     region         = "us-west-2"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }
