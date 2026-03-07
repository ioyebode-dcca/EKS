module "eks" {
  source = "../../modules/eks-cluster"

  environment           = local.environment
  cluster_name          = local.cluster_name
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  vpc_cni_irsa_role_arn = module.irsa.vpc_cni_irsa_role_arn
  ebs_csi_irsa_role_arn = module.irsa.ebs_csi_irsa_role_arn

  # Prod uses ON_DEMAND for reliability
  node_instance_types = ["t3.large"]
  node_min_size       = 2
  node_max_size       = 6
  node_desired_size   = 3
}
