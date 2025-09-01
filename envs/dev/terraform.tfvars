aws_profile = "default"
aws_region  = "eu-west-2"
name_prefix = "sentinel"

gateway_vpc_cidr        = "10.10.0.0/16"
backend_vpc_cidr        = "10.20.0.0/16"

gateway_private_subnets = ["10.10.1.0/24", "10.10.2.0/24"]
gateway_public_subnets  = ["10.10.101.0/24", "10.10.102.0/24"]

backend_private_subnets = ["10.20.1.0/24", "10.20.2.0/24"]
backend_public_subnets  = ["10.20.101.0/24", "10.20.102.0/24"]

cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"] # tighten to your IP/CIDR

tags = {
  Project = "Sentinel"
  Owner   = "Platform"
}
