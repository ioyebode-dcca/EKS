module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0"

  cluster_name    = "DevOps-cluster"
  cluster_version = "1.31"
  subnet_ids      = var.subnet_ids
  vpc_id          = var.vpc_id

  enable_irsa = true

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  manage_aws_auth_configmap = false
  create_aws_auth_configmap = false

  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  # ✅ Ensure EKS cluster uses the correct security group
  cluster_security_group_id = aws_security_group.eks_sg.id

  # ✅ Attach security groups to worker nodes
  node_security_group_additional_rules = {
    all_traffic = {
      description = "Allow all traffic within the VPC"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      cidr_blocks = [aws_vpc.eks_vpc.cidr_block]
    }
  }
}

# ✅ Security Group for EKS Cluster
resource "aws_security_group" "eks_sg" {
  name_prefix = "eks-"
  vpc_id      = aws_vpc.eks_vpc.id

  # Allow inbound traffic for EKS API
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Can be restricted if needed
  }

  # ✅ Allow all traffic within the VPC CIDR (Worker Nodes <--> Control Plane)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.eks_vpc.cidr_block]
  }

  # ✅ Allow all outbound traffic to any destination (Fixes API connectivity)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-security-group"
  }
}

# ✅ Security Group Rule for EKS Cluster Outbound Traffic
resource "aws_security_group_rule" "eks_cluster_egress_rule" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.eks.cluster_security_group_id
}
