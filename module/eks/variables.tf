variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "environment" {
  type        = string
  description = "Environment name (dev or prod)"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the EKS cluster"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for EKS nodes"
}

variable "vpc_cni_irsa_role_arn" {
  type        = string
  description = "IAM role ARN for VPC CNI IRSA"
}

variable "ebs_csi_irsa_role_arn" {
  type        = string
  description = "IAM role ARN for EBS CSI IRSA"
}

variable "node_instance_types" {
  type        = list(string)
  description = "EC2 instance types for node group"
}

variable "node_min_size" {
  type        = number
  description = "Minimum number of nodes"
}

variable "node_max_size" {
  type        = number
  description = "Maximum number of nodes"
}

variable "node_desired_size" {
  type        = number
  description = "Desired number of nodes"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to access the cluster API"
  default     = ["0.0.0.0/0"]
}
