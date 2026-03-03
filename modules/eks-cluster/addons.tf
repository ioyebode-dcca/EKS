# ── CLUSTER ADDONS ───────────────────────────────────────────────────────────
# Core components that run inside EKS
# vpc-cni      → handles pod networking
# coredns      → handles DNS inside cluster
# kube-proxy   → handles network rules on nodes
# ebs-csi      → allows pods to use EBS volumes
# Note: IRSA role ARNs added after cluster creation to avoid cycle
locals {
  cluster_addons = {
    vpc-cni = {
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
    coredns = {
      most_recent = true
      configuration_values = jsonencode({
        replicaCount = var.environment == "dev" ? 1 : 2
      })
    }
    kube-proxy = {
      most_recent = true
    }
    # aws-ebs-csi-driver = {
    #   most_recent = true
    # }
    eks-pod-identity-agent = {
      most_recent = true
    }
  }
}
