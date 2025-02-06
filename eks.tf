module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.0.0"

  cluster_name    = "DevOps-cluster"
  cluster_version = "1.31"
  subnet_ids      = var.subnet_ids
  vpc_id          = var.vpc_id

  # IAM role should be passed as an input variable (not cluster_role_arn)
  enable_irsa = true

