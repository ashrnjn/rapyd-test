output "gateway_private_subnets" {
  value = module.vpc_gateway.private_subnet_ids
}

output "backend_private_subnets" {
  value = module.vpc_backend.private_subnet_ids
}

output "vpc_peering_id" {
  value = module.peering.peering_id
}
