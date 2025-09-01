variable "aws_profile" {
  description = "AWS CLI profile to use for credentials"
  type        = string
  default     = "default"
}

variable "aws_region" {
  description = "region in which resources will be deployed"
  type        = string
  default     = ""
}

variable "name_prefix" {
  description = "A short name prefix for tagging and resource names"
  type        = string
  default     = "sentinel"
}

variable "gateway_vpc_cidr" {
  description = "CIDR block for the gateway VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "backend_vpc_cidr" {
  description = "CIDR block for the backend VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "gateway_private_subnets" {
  description = "List of private subnet CIDRs for gateway VPC"
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.2.0/24"]
}

variable "gateway_public_subnets" {
  description = "List of public subnet CIDRs for gateway VPC"
  type        = list(string)
  default     = ["10.10.101.0/24", "10.10.102.0/24"]
}

variable "backend_private_subnets" {
  description = "List of private subnet CIDRs for backend VPC"
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "backend_public_subnets" {
  description = "List of public subnet CIDRs for backend VPC (for NAT)"
  type        = list(string)
  default     = ["10.20.101.0/24", "10.20.102.0/24"]
}

variable "eks_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.30"
}

variable "enable_private_endpoints" {
  description = "Create VPC endpoints for private access to AWS services"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Whether EKS endpoint is publicly accessible (restricted by CIDRs)"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "Allowed CIDRs for public access to EKS endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Tagging"
  type        = map(string)
  default     = {}
}

