variable "aws_region" {
  description = "The AWS region where the EKS cluster will be created."
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "The name of the EKS cluster."
  default     = "my-eks-cluster"
}

variable "vpc_id" {
  description = "The ID of the VPC where the EKS cluster will be created."
}

variable "subnet_ids" {
  description = "A list of subnet IDs where the EKS cluster will be created."
  type        = list(string)
}

variable "aws_iam_role_name" {
  description = "The name of the IAM role that will be used by the EKS cluster."
  default     = "my-eks-role"
}

variable "tags" {
  description = "A map of tags to add to the resources created by the Terraform code."
  type        = map(string)
  default     = {
    Environment = "dev"
  }
}
