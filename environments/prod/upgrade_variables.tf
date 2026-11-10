# Declared so the infra pipeline can pass these to prod without an error.
# They take effect once environments/prod/eks.tf passes them to the eks module
# the same way environments/dev/eks.tf does.
variable "cluster_version" {
  type        = string
  description = "Kubernetes version for the EKS cluster"
  default     = "1.34"
}

variable "addon_versions" {
  type        = map(string)
  description = "Optional add-on version pins keyed by add-on name"
  default     = {}
}
