# ── CLUSTER ADDONS ───────────────────────────────────────────────────────────
# Core components that run inside EKS
# vpc-cni      → handles pod networking
# coredns      → handles DNS inside cluster
# kube-proxy   → handles network rules on nodes
# ebs-csi      → allows pods to use EBS volumes (managed in the environment)
# Note: IRSA role ARNs added after cluster creation to avoid cycle
locals {
  managed_addon_names = ["vpc-cni", "coredns", "kube-proxy", "eks-pod-identity-agent"]

  # Version settings per add-on.
  # If var.addon_versions names the add-on, that exact version is used.
  # Otherwise the newest version compatible with var.cluster_version is used,
  # so add-ons follow the cluster through a Kubernetes upgrade.
  addon_version_args = {
    for name in local.managed_addon_names : name => merge(
      { most_recent = lookup(var.addon_versions, name, "") == "" },
      { for k, v in { addon_version = lookup(var.addon_versions, name, "") } : k => v if v != "" }
    )
  }

  cluster_addons = {
    vpc-cni = merge(local.addon_version_args["vpc-cni"], {
      before_compute = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    })
    coredns = merge(local.addon_version_args["coredns"], {
      configuration_values = jsonencode({
        replicaCount = var.environment == "dev" ? 1 : 2
      })
    })
    kube-proxy             = local.addon_version_args["kube-proxy"]
    eks-pod-identity-agent = local.addon_version_args["eks-pod-identity-agent"]
  }
}
