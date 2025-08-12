terraform {
  backend "s3" {
    bucket         = "project-backend"
    key            = "ec2/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "users-table"
  }
}
