module "irsa" {
  source = "../modules/irsa"

  environment       = local.environment
  oidc_provider_arn = module.eks.oidc_provider_arn
  tf_state_bucket   = "devops-bucket-495905914919"
  tf_lock_table     = "terraform-state-lock"

  depends_on = [module.eks]
}
