resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "default"
  node_role_arn   = aws_iam_role.worker_nodes_role.arn
  subnet_ids      = data.aws_subnets.eks_subnets.ids

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }

  instance_types = ["t3.small"]
  capacity_type  = "ON_DEMAND"

  # ✅ Attach the correct security group
  network_config {
    security_groups = [aws_security_group.eks_sg.id]
  }

  depends_on = [
    module.eks,
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy_Workers,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly
  ]
}
