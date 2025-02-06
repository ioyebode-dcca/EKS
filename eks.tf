module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.0.0"

  cluster_name    = "DevOps-cluster"
  cluster_version = "1.31"
  subnet_ids      = var.subnet_ids
  vpc_id          = var.vpc_id

  # IAM role should be passed as an input variable (not cluster_role_arn)
  enable_irsa = true

  eks_managed_node_groups = {
    default = {
      desired_size = 2
      min_size     = 1
      max_size     = 3

      instance_types = ["t2.small"]
      security_group_ids = [aws_security_group.eks_sg.id]
      subnet_ids         = var.subnet_ids
    }
  }
}
