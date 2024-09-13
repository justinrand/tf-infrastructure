terraform {
  backend "s3" {
    bucket = "jrand-terraform-backend"
    key    = "root.tfstate"
    region = "us-east-2"
  }
}