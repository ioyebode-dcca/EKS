variable "region" {
  type    = string
  default = "us-east-1"
}

variable "worker_instance_type" {
  type    = string
  default = "t3.small"
}

variable "num_workers" {
  type    = number
  default = 3
}

variable "cluster_name" {
  type    = string
  default = "DevOps-cluster"
}

variable "vpc_id" {
  type    = string
  default = "vpc-01c3435ed182b7ac3"
}

variable "ssh_key_name" {
  type    = string
  default = "izzy"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for EKS cluster"
  default     = ["subnet-05f419a0c06eacbe7", "subnet-039132a7ecbffea63"]  # ✅ Replace with your actual subnets
}

variable "control_plane_subnet_ids" {
  type        = list(string)
  description = "List of control plane subnets"
  default     = []  # ✅ Default to empty, but EKS needs at least two subnets
}



