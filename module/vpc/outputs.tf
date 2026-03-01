output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnets
  description = "Private subnet IDs"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnets
  description = "Public subnet IDs"
}

output "vpc_cidr_block" {
  value       = module.vpc.vpc_cidr_block
  description = "VPC CIDR block"
}
