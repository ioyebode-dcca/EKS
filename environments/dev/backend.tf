terraform {
  backend "s3" {
    bucket         = "devops-bucket-495905914919"
    key            = "environments/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
