terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# IAM Role for EKS Control Plane
resource "aws_iam_role" "eks_iam_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach required policies to the EKS IAM role
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_iam_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_iam_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_iam_role.name
}

# EKS Cluster Resource (Corrected)
resource "aws_eks_cluster" "eks_cluster" {
  name     = "DevOps-cluster"
  role_arn = aws_iam_role.eks_iam_role.arn

  vpc_config {
    subnet_ids = [var.subnet_id_1, var.subnet_id_2]
  }

  depends_on = [
    aws_iam_role.eks_iam_role,
  ]
}

# IAM Role for Worker Nodes
resource "aws_iam_role" "worker_nodes_role" {
  name = "eks-worker-nodes-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach IAM policies to the Worker Node IAM Role
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.worker_nodes_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy_Workers" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.worker_nodes_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.worker_nodes_role.name
}

# EKS Node Group (Worker Nodes)
resource "aws_eks_node_group" "worker_node_group" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  node_group_name = "eks-worker-nodes"
  node_role_arn  = aws_iam_role.worker_nodes_role.arn

  subnet_ids = [var.subnet_id_1, var.subnet_id_2]

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  instance_types = ["t2.micro"]

  depends_on = [
    aws_eks_cluster.eks_cluster,
    aws_iam_role.worker_nodes_role
  ]
}
