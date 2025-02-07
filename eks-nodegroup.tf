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

  # Remove the launch template configuration temporarily for testing
  # launch_template {
  #   id      = aws_launch_template.eks_node_group.id
  #   version = aws_launch_template.eks_node_group.latest_version
  # }

  depends_on = [
    module.eks,
    null_resource.create_aws_auth,
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy_Workers,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly
  ]
}