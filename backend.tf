terraform {
  backend "s3" {
    bucket         = "project-backend" # Change this
    key            = "eks/${terraform.workspace}/terraform.tfstate"
    region         = "ap-south-1" # Change this to your region
    dynamodb_table = "users-table"
  }
}
