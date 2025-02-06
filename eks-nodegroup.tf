resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "default"
  node_role_arn   = aws_iam_role.worker_nodes_role.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }

  instance_types = ["t3.small"]
  capacity_type  = "SPOT"

  depends_on = [module.eks]
}
