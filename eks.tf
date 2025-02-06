module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0"

  cluster_name    = "DevOps-cluster"
  cluster_version = "1.31"
  subnet_ids      = var.subnet_ids
  vpc_id          = var.vpc_id

  enable_irsa = true
  
  # These are important for accessing the cluster
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # Important for auth management
  manage_aws_auth_configmap = true
}