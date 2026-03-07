module "vpc" {
  source = "../../modules/eks-vpc"

  environment          = local.environment
  cluster_name         = local.cluster_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
}
