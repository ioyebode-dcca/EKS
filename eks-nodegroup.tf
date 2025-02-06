module "eks_node_group" {
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "19.0.0"

  cluster_name = module.eks.cluster_name  # Ensure it references the correct cluster
  subnet_ids   = var.subnet_ids           # Ensure subnets match EKS

  eks_managed_node_groups = {
    default = {
      desired_size   = 1
      min_size       = 1
      max_size       = 2
      instance_types = ["t3.small"]
    }
  }

  depends_on = [module.eks]  # Ensure the cluster is created before nodes
}
