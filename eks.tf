module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0"

  cluster_name    = "DevOps-cluster"
  cluster_version = "1.31"
  subnet_ids      = var.subnet_ids
  vpc_id          = var.vpc_id

  enable_irsa = true
  
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # Change this to false to avoid the auth ConfigMap error
  manage_aws_auth_configmap = false

  # Add this to handle auth outside the module
  create_aws_auth_configmap = false
}