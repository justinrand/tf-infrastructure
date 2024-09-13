terraform {
    backend "s3" {
    bucket = "jrand-terraform-backend"
    key = "backend/terraform.tfstate"
    region = "us-east-2"
  }
}