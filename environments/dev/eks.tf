module "eks" {
  source = "../../modules/eks-cluster"

  environment        = local.environment
  cluster_name       = local.cluster_name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  # Dev uses SPOT instances to save ~70% cost
  node_instance_types = ["t3.medium"]
  node_min_size       = 1
  node_max_size       = 3
  node_desired_size   = 2
}

# ── CLUSTER ACCESS ENTRY ─────────────────────────────────────────────────────
# Grants devops-admin user kubectl accessr
resource "aws_eks_access_entry" "devops_admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::495905914919:user/devops-admin"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "devops_admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::495905914919:user/devops-admin"
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.devops_admin]
}

# ── EBS CSI DRIVER ───────────────────────────────────────────────────────────
resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.38.1-eksbuild.1"
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [
    module.eks
  ]
}

# ── DEFAULT STORAGE CLASS ────────────────────────────────────────────────────
# Patches gp2 to be the default storage class for PVC provisioning
resource "null_resource" "set_default_storage_class" {
  provisioner "local-exec" {
    command = <<-EOT
      aws eks update-kubeconfig \
        --region ${var.region} \
        --name ${module.eks.cluster_name}

      kubectl patch storageclass gp2 \
        -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
    EOT
  }

  depends_on = [
    aws_eks_addon.ebs_csi
  ]
}
