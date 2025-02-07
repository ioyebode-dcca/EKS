module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.31"
  subnet_ids      = data.aws_subnets.eks_subnets.ids # ✅ Dynamically fetched subnets
  vpc_id          = data.aws_vpc.eks_vpc.id          # ✅ Dynamically fetched VPC ID

  enable_irsa = true

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  manage_aws_auth_configmap = false
  create_aws_auth_configmap = false

  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  # ✅ Use the security group from `vpc.tf`
  cluster_security_group_id = aws_security_group.eks_sg.id

  # ✅ Worker Node Group Configuration
  eks_managed_node_groups = {
    default = {
      desired_size = 2
      min_size     = 1
      max_size     = 3
      instance_types = ["t3.small"]
      security_group_ids = [aws_security_group.eks_sg.id]
    }
  }
}
