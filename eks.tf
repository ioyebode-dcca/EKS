module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.5.0"

  cluster_name    = "DevOps-cluster"
  cluster_version = "1.31"
  subnets         = aws_subnet.eks_subnet.*.id
  vpc_id          = aws_vpc.eks_vpc.id

  cluster_role_arn = aws_iam_role.eks-iam-role.arn  # Fix: Pass IAM role to EKS

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
