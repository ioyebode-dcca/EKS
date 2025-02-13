resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "default"
  node_role_arn   = aws_iam_role.worker_nodes_role.arn

  # ✅ Ensure valid subnets are used
  subnet_ids = length(data.aws_subnets.eks_subnets.ids) > 0 ? data.aws_subnets.eks_subnets.ids : var.subnet_ids

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }

  instance_types = ["t3.nano"]
  capacity_type  = "ON_DEMAND"

  remote_access {
    ec2_ssh_key = var.ssh_key_name
    source_security_group_ids = [aws_security_group.eks_sg.id]
  }

  depends_on = [
    module.eks,
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy_Workers,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly
  ]
}
