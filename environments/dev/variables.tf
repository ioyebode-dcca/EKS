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