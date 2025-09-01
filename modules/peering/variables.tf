variable "name" { type = string }

variable "vpc_id_requester"   { type = string }
variable "vpc_cidr_requester" { type = string }
variable "requester_private_rt_ids" { type = list(string) }

variable "vpc_id_accepter"    { type = string }
variable "vpc_cidr_accepter"  { type = string }
variable "accepter_private_rt_ids" { type = list(string) }

variable "tags" {
  description = "Tagging"
  type        = map(string)
  default     = {}
}
