output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "jenkins_irsa_role_arn" {
  description = "IAM role ARN for Jenkins pods"
  value       = module.irsa.jenkins_irsa_role_arn
}

output "flux_irsa_role_arn" {
  description = "IAM role ARN for Flux controllers"
  value       = module.irsa.flux_irsa_role_arn
}
