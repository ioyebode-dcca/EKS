# ✅ AWS Region
variable "region" {
  type    = string
  default = "us-east-1"
}

# ✅ Instance Type for Worker Nodes (Improved from `t2.micro` to `t3.small`)
variable "worker_instance_type" {
  type    = string
  default = "t3.small"
}

# ✅ Number of Worker Nodes
variable "num_workers" {
  type    = number
  default = 3
}

# ✅ Cluster Name (Consistent with `eks.tf`)
variable "cluster_name" {
  type    = string
  default = "DevOps-cluster"
}

# ✅ VPC ID
variable "vpc_id" {
  type    = string
  default = "vpc-01c3435ed182b7ac3"
}

# ✅ Dynamically Retrieve Subnet IDs in the VPC
data "aws_subnets" "eks_subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

variable "subnet_ids" {
  type    = list(string)
  default = data.aws_subnets.eks_subnets.ids
}

# ✅ SSH Key Name for Worker Nodes (Replace with your AWS Key Name)
variable "ssh_key_name" {
  type    = string
  default = "izzy"
}
