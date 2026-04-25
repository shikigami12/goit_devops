provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "devops-coursework"
      Lesson    = "lesson-5"
      ManagedBy = "Terraform"
    }
  }
}
