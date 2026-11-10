variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}
variable "cluster_version" {
  type        = string
  description = "Kubernetes version for the control plane and node group, for example 1.34"
  default     = "1.34"
}
variable "addon_versions" {
  type        = map(string)
  description = "Optional add-on version pins keyed by add-on name. Add-ons not listed use the newest version compatible with cluster_version."
  default     = {}
}
variable "environment" {
  type        = string
  description = "Environment name (dev or prod)"
}
variable "vpc_id" {
  type        = string
  description = "VPC ID for the EKS cluster"
}
variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for EKS nodes"
}
variable "vpc_cni_irsa_role_arn" {
  type        = string
  description = "IAM role ARN for VPC CNI IRSA"
  default     = ""
}
variable "ebs_csi_irsa_role_arn" {
  type        = string
  description = "IAM role ARN for EBS CSI IRSA"
  default     = ""
}
variable "node_instance_types" {
  type        = list(string)
  description = "EC2 instance types for node group"
}
variable "node_min_size" {
  type        = number
  description = "Minimum number of nodes"
}
variable "node_max_size" {
  type        = number
  description = "Maximum number of nodes"
}
variable "node_desired_size" {
  type        = number
  description = "Desired number of nodes"
}
variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to access the cluster API"
  default     = ["0.0.0.0/0"]
}
