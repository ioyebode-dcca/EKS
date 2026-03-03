module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.0.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.34"

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access_cidrs = var.allowed_cidr_blocks

  enable_irsa = true

  # ── MANAGED ADDONS ──────────────────────────────────────────────────────────
  cluster_addons = {
    vpc-cni = {
      most_recent              = true
      before_compute           = true
      service_account_role_arn = var.vpc_cni_irsa_role_arn
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
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = var.ebs_csi_irsa_role_arn
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
  }

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

  # ── SECURITY GROUP RULES ─────────────────────────────────────────────────────
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description = "Node all egress"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "underwater"
  }
}
