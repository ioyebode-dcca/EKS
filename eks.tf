module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.0.0"  # Upgrade to a newer version

  cluster_name    = "DevOps-cluster"
  cluster_version = "1.31"
  subnet_ids      = var.subnet_ids
  vpc_id          = var.vpc_id

  cluster_role_arn = aws_iam_role.eks_iam_role.arn

  worker_groups_launch_template = [
    {
      name                 = "eks-worker-group"
      instance_type        = "t2.small"
      asg_desired_capacity = 2
      additional_security_group_ids = [aws_security_group.eks_sg.id]
      subnets             = aws_subnet.eks_subnet.*.id
    }
  ]
}
