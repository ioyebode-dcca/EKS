output "vpc_cni_irsa_role_arn" {
  value       = module.vpc_cni_irsa.iam_role_arn
  description = "IAM role ARN for VPC CNI"
}

output "ebs_csi_irsa_role_arn" {
  value       = module.ebs_csi_irsa.iam_role_arn
  description = "IAM role ARN for EBS CSI driver"
}

output "jenkins_irsa_role_arn" {
  value       = module.jenkins_irsa.iam_role_arn
  description = "IAM role ARN for Jenkins pods"
}

output "flux_irsa_role_arn" {
  value       = module.flux_irsa.iam_role_arn
  description = "IAM role ARN for Flux controllers"
}
