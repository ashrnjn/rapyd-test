variable "name"                       { type = string }
variable "cluster_version"            { type = string }
variable "subnet_ids"                 { type = list(string) }
variable "vpc_id"                     { type = string }

variable "endpoint_public_access"     { type = bool }
variable "endpoint_public_access_cidrs" { type = list(string) }
variable "endpoint_private_access"    { type = bool }

variable "node_desired_size"          { type = number }
variable "node_min_size"              { type = number }
variable "node_max_size"              { type = number }
variable "node_instance_types"        { type = list(string) }

variable "tags" {
  description = "Tagging"
  type        = map(string)
  default     = {}
}
