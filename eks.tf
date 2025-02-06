module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.0.0"

  cluster_name    = "DevOps-cluster"
  cluster_version = "1.31"
  subnet_ids      = var.subnet_ids
  vpc_id          = var.vpc_id

  enable_irsa = true
}

# Output the cluster name to be used in eks-nodegroup.tf
output "eks_cluster_name" {
  value = module.eks.cluster_name
}
