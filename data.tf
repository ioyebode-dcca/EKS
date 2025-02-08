# ✅ Fetch VPC Dynamically
data "aws_vpc" "eks_vpc" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]  # Ensure the correct VPC ID is used
  }
}

# ✅ Fetch Subnets Dynamically
data "aws_subnets" "eks_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.eks_vpc.id]
  }

  filter {
    name   = "tag:kubernetes.io/cluster/DevOps-cluster"
    values = ["shared"]
  }
}

output "eks_subnet_ids" {
  value = data.aws_subnets.eks_subnets.ids
}
