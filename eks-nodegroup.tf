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

  # Add launch template configuration
  launch_template {
    name    = "eks-node-group-launch-template"
    version = "$Latest"
  }

  # Add proper node group tags
  tags = {
    "kubernetes.io/cluster/${module.eks.cluster_name}" = "owned"
    "k8s.io/cluster-autoscaler/enabled"               = "true"
    "k8s.io/cluster-autoscaler/${module.eks.cluster_name}" = "owned"
  }

  # Make sure all IAM roles are created before the node group
  depends_on = [
    module.eks,
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy_Workers,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly
  ]
}