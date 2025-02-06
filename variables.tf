# AWS Region
variable "region" {
  type    = string
  default = "us-east-1"
}

# Instance Type for Worker Nodes
variable "worker_instance_type" {
  type    = string
  default = "t2.micro"
}

# Number of Worker Nodes
variable "num_workers" {
  type    = number
  default = 3
}

# Cluster Name (Ensure Consistency Across All Files)
variable "cluster_name" {
  type    = string
  default = "eks-cluster" # Ensure this matches what is used in eks.tf
}

# Subnet IDs (Use a List Instead of Individual Variables)
variable "subnet_ids" {
  type    = list(string)
  default = ["subnet-0bc5ce8bf3a2857a3", "subnet-039132a7ecbffea63", "subnet-05f419a0c06eacbe7"]
}

# VPC ID (If Needed for References)
variable "vpc_id" {
  type    = string
  default = "vpc-01c3435ed182b7ac3"
}
