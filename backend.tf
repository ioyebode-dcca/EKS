terraform {
  backend "s3" {
    bucket  = "izzy-terraform"
    key     = "eks/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

