# ✅ Fetch VPC Dynamically with Error Handling
data "aws_vpc" "eks_vpc" {
  filter {
    name   = "tag:Name"
    values = ["eks-vpc"] # Ensure this matches your VPC name in AWS
  }
}

# ✅ Fetch Only EKS-Tagged Subnets
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

# ✅ Output Subnet IDs and VPC ID for Debugging
output "eks_subnet_ids" {
  value = data.aws_subnets.eks_subnets.ids
}

output "eks_vpc_id" {
  value = data.aws_vpc.eks_vpc.id
}
