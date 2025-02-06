module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0"

  cluster_name    = "DevOps-cluster"
  cluster_version = "1.31"
  subnet_ids      = var.subnet_ids
  vpc_id          = var.vpc_id

  enable_irsa = true
  
  # Ensure both public and private access are enabled
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # Disable built-in auth management
  manage_aws_auth_configmap = false
  create_aws_auth_configmap = false

  # Add cluster security group rules for worker nodes
  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description                = "Node groups to cluster API"
      protocol                  = "tcp"
      from_port                 = 1025
      to_port                   = 65535
      type                      = "ingress"
      source_node_security_group = true
    }
  }
}