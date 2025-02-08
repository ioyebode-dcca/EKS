# ✅ Fetch VPC Dynamically by ID Instead of Name
data "aws_vpc" "eks_vpc" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]  # Ensure correct VPC ID is used
  }
}

# ✅ Fetch Subnets Dynamically
data "aws_subnets" "eks_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.eks_vpc.id]
  }

  # ✅ Ensure only subnets tagged for EKS are fetched
  filter {
    name   = "tag:kubernetes.io/cluster/DevOps-cluster"
    values = ["shared"]
  }
}

# ✅ Output VPC and Subnet IDs for Debugging
output "eks_vpc_id" {
  value = data.aws_vpc.eks_vpc.id
}

output "eks_subnet_ids" {
  value = data.aws_subnets.eks_subnets.ids
}
