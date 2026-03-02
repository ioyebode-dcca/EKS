variable "environment" {
  type        = string
  description = "Environment name (dev or prod)"
}

variable "oidc_provider_arn" {
  type        = string
  description = "OIDC provider ARN from EKS cluster"
}

variable "tf_state_bucket" {
  type        = string
  description = "S3 bucket name for Terraform state"
}

variable "tf_lock_table" {
  type        = string
  description = "DynamoDB table name for Terraform state locking"
}
