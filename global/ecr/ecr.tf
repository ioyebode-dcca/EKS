terraform {
  backend "s3" {
    bucket         = "izzy-terraform"
    key            = "global/ecr/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ECR repos are shared between dev and prod
# Dev pushes dev-{buildnumber} tags, prod pushes release-{buildnumber} tags
resource "aws_ecr_repository" "services" {
  for_each             = toset(["underwater", "auth-service", "api-service"])
  name                 = each.value
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project = "underwater"
  }
}

# Lifecycle policy — keep dev images short, prod images longer
resource "aws_ecr_lifecycle_policy" "services" {
  for_each   = aws_ecr_repository.services
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 dev images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["dev-"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep last 20 release images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["release-"]
          countType     = "imageCountMoreThan"
          countNumber   = 20
        }
        action = { type = "expire" }
      }
    ]
  })
}

output "ecr_repository_urls" {
  value = { for k, v in aws_ecr_repository.services : k => v.repository_url }
}
