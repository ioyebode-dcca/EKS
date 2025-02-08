module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.31"

  # ✅ Ensure Subnet IDs Are Not Empty
  subnet_ids = length(var.subnet_ids) > 0 ? var.subnet_ids : data.aws_subnets.eks_subnets.ids

  vpc_id = data.aws_vpc.eks_vpc.id

  enable_irsa = true

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  manage_aws_auth_configmap = false
  create_aws_auth_configmap = false

  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  # ✅ Ensure EKS Security Group Is Used
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
