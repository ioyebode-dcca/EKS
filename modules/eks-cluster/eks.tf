# ── EKS CONTROL PLANE ────────────────────────────────────────────────────────
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.0.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.34"
  vpc_id          = var.vpc_id
  subnet_ids      = var.private_subnet_ids

  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access_cidrs = var.allowed_cidr_blocks

  enable_irsa = true

  cluster_addons          = local.cluster_addons
  eks_managed_node_groups = local.node_groups
  node_security_group_additional_rules = local.node_sg_rules

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "underwater"
  }
}
