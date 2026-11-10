variable "region" {
  type        = string
  description = "AWS region"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDRs"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDRs"
}

variable "alert_phone_number" {
  type        = string
  description = "Phone number for SMS alerts"
  sensitive   = true
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "dev"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version for the EKS cluster. The infra pipeline overrides this with K8S_VERSION, or with the running version when K8S_VERSION is blank."
  default     = "1.34"
}

variable "addon_versions" {
  type        = map(string)
  description = "Optional add-on version pins keyed by add-on name. Blank means newest compatible version."
  default     = {}
}
