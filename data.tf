# ✅ Fetch Subnets Dynamically
data "aws_subnets" "eks_subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

# ✅ Fetch VPC ID Dynamically (If Not Hardcoded)
data "aws_vpc" "eks_vpc" {
  filter {
    name   = "tag:Name"
    values = ["eks-vpc"] # Make sure this matches the VPC name in `vpc.tf`
  }
}

# ✅ Output the Subnet IDs for Use
output "eks_subnet_ids" {
  value = data.aws_subnets.eks_subnets.ids
}

output "eks_vpc_id" {
  value = data.aws_vpc.eks_vpc.id
}
