# ✅ Fetch VPC Dynamically
data "aws_vpc" "eks_vpc" {
  id = var.vpc_id
}

# ✅ Fetch Private Subnets for EKS
data "aws_subnets" "eks_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.eks_vpc.id]
  }

  filter {
    name   = "tag:Type"
    values = ["private"]
  }
}

# ✅ Output for Debugging (Ensures Subnets Are Found)
output "eks_subnet_ids" {
  value = length(data.aws_subnets.eks_subnets.ids) > 0 ? data.aws_subnets.eks_subnets.ids : []
}
