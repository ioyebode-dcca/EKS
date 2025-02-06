module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0"  # Updated version

  cluster_name    = "DevOps-cluster"
  cluster_version = "1.31"
  subnet_ids      = var.subnet_ids
  vpc_id          = var.vpc_id

  enable_irsa = true
  
  # Add these for proper endpoint access
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # Add proper cluster security group rules
  vpc_security_group_ids = []
}