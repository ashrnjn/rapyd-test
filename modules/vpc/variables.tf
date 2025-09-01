variable "name"                { type = string }
variable "vpc_cidr"            { type = string }
variable "private_subnets"     { type = list(string) }
variable "public_subnets"      { type = list(string) }
variable "az_count"            { type = number }
variable "enable_private_endpoints" { type = bool }
variable "interface_endpoints" { type = list(string) }
variable "gateway_endpoints"   { type = list(string) }
variable "is_gateway" { type = bool }
variable "cluster_name" { type = string }
variable "tags" {
  description = "Tagging"
  type        = map(string)
  default     = {}
}
