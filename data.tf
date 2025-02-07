# ✅ Fetch Only EKS-Tagged Subnets Dynamically
data "aws_subnets" "eks_subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  
  # ✅ Filter only subnets meant for EKS (Modify this tag as needed)
  filter {
    name   = "tag:kubernetes.io/cluster/DevOps-cluster"
    values = ["shared"]
  }
}

# ✅ Fetch VPC ID Dynamically (If Not Hardcoded)
data "aws_vpc" "eks_vpc" {
  filter {
    name   = "tag:Name"
    values = ["eks-vpc"] # Make sure this matches the VPC name in `vpc.tf`
  }
}

# ✅ Output the Subnet IDs for Use (Sorted to Ensure Stability)
output "eks_subnet_ids" {
  value = sort(data.aws_subnets.eks_subnets.ids)  # ✅ Ensures stable order
}

output "eks_vpc_id" {
  value = data.aws_vpc.eks_vpc.id
}
