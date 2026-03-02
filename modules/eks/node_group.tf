  # ── NODE GROUPS ──────────────────────────────────────────────────────────────
  eks_managed_node_groups = {
    main = {
      name           = "${var.environment}-node-group"
      instance_types = var.node_instance_types
      capacity_type  = var.environment == "dev" ? "SPOT" : "ON_DEMAND"

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.environment == "dev" ? 20 : 50
            volume_type           = "gp3"
            delete_on_termination = true
            encrypted             = true
          }
        }
      }

      labels = {
        Environment = var.environment
        NodeGroup   = "main"
      }

      tags = {
        Environment                                      = var.environment
        "k8s.io/cluster-autoscaler/enabled"              = "true"
        "k8s.io/cluster-autoscaler/${var.cluster_name}"  = "owned"
      }
    }
  }