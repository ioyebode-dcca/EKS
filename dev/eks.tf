module "eks" {
  source = "../modules/eks"

  environment           = local.environment
  cluster_name          = local.cluster_name
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  vpc_cni_irsa_role_arn = module.irsa.vpc_cni_irsa_role_arn
  ebs_csi_irsa_role_arn = module.irsa.ebs_csi_irsa_role_arn

  # Dev uses SPOT instances to save ~70% cost
  node_instance_types = ["t3.medium"]
  node_min_size       = 1
  node_max_size       = 3
  node_desired_size   = 2
}
