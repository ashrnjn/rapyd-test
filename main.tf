############################
# VPCs
############################

module "vpc_gateway" {
  source                   = "./modules/vpc"
  name                     = "${var.name_prefix}-gateway"
  region                   = "${var.aws_region}"
  vpc_cidr                 = var.gateway_vpc_cidr
  private_subnets          = var.gateway_private_subnets
  public_subnets           = var.gateway_public_subnets
  az_count                 = 2
  enable_private_endpoints = var.enable_private_endpoints
  # Minimal endpoint set for gateway cluster + ECR/S3
  interface_endpoints = [
    "com.amazonaws.${var.aws_region}.ssm",
    "com.amazonaws.${var.aws_region}.ssmmessages",
    "com.amazonaws.${var.aws_region}.ec2messages",
    "com.amazonaws.${var.aws_region}.kms",
    "com.amazonaws.${var.aws_region}.secretsmanager",
    "com.amazonaws.${var.aws_region}.ecr.api",
    "com.amazonaws.${var.aws_region}.ecr.dkr",
    "com.amazonaws.${var.aws_region}.logs",
    "com.amazonaws.${var.aws_region}.ec2"
  ]
  gateway_endpoints = ["s3"]
  is_gateway   = true
  cluster_name = "aashish-eks-gateway"
  tags              = var.tags
}

module "vpc_backend" {
  source                   = "./modules/vpc"
  name                     = "${var.name_prefix}-backend"
  region                   = "${var.aws_region}"
  vpc_cidr                 = var.backend_vpc_cidr
  private_subnets          = var.backend_private_subnets
  public_subnets           = var.backend_public_subnets
  az_count                 = 2
  enable_private_endpoints = var.enable_private_endpoints
  # Backend needs same set (and often DynamoDB for controllers).
  interface_endpoints = [
    "com.amazonaws.${var.aws_region}.ssm",
    "com.amazonaws.${var.aws_region}.ssmmessages",
    "com.amazonaws.${var.aws_region}.ec2messages",
    "com.amazonaws.${var.aws_region}.kms",
    "com.amazonaws.${var.aws_region}.secretsmanager",
    "com.amazonaws.${var.aws_region}.ecr.api",
    "com.amazonaws.${var.aws_region}.ecr.dkr",
    "com.amazonaws.${var.aws_region}.logs",
    "com.amazonaws.${var.aws_region}.ec2"
  ]
  gateway_endpoints = ["s3", "dynamodb"]
  is_gateway   = false
  cluster_name = "aashish-eks-backend"
  tags              = var.tags
}

############################
# VPC Peering and routes
############################

module "peering" {
  source                   = "./modules/peering"
  name                     = "${var.name_prefix}-gw-backend"
  vpc_id_requester         = module.vpc_gateway.vpc_id
  vpc_cidr_requester       = module.vpc_gateway.vpc_cidr
  requester_private_rt_ids = module.vpc_gateway.private_route_table_ids

  vpc_id_accepter         = module.vpc_backend.vpc_id
  vpc_cidr_accepter       = module.vpc_backend.vpc_cidr
  accepter_private_rt_ids = module.vpc_backend.private_route_table_ids

  tags = var.tags
}

############################
# EKS Clusters
############################

module "eks_gateway" {
  source                       = "./modules/eks"
  name                         = "${var.name_prefix}-gateway"
  cluster_version              = var.eks_version
  subnet_ids                   = module.vpc_gateway.private_subnet_ids
  vpc_id                       = module.vpc_gateway.vpc_id
  endpoint_public_access       = var.cluster_endpoint_public_access
  endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  endpoint_private_access      = true
  node_desired_size            = 2
  node_min_size                = 2
  node_max_size                = 4
  node_instance_types          = ["t3.large"]
  tags                         = var.tags
}

module "eks_backend" {
  source                       = "./modules/eks"
  name                         = "${var.name_prefix}-backend"
  cluster_version              = var.eks_version
  subnet_ids                   = module.vpc_backend.private_subnet_ids
  vpc_id                       = module.vpc_backend.vpc_id
  endpoint_public_access       = var.cluster_endpoint_public_access
  endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  endpoint_private_access      = true
  node_desired_size            = 2
  node_min_size                = 2
  node_max_size                = 4
  node_instance_types          = ["t3.large"]
  tags                         = var.tags
}

############################
# ALB Controller
############################

module "alb_controller_backend" {
  source             = "./modules/alb_controller"
  providers = {
    kubernetes = kubernetes.backend
    helm       = helm.backend
  }
  cluster_name       = module.eks_backend.cluster_name
  oidc_provider_arn  = module.eks_backend.oidc_provider_arn
  oidc_provider_url  = module.eks_backend.oidc_provider_url
  region             = var.aws_region
  vpc_id             = module.vpc_backend.vpc_id
}

module "alb_controller_gateway" {
  source             = "./modules/alb_controller"
  providers = {
    kubernetes = kubernetes.gateway
    helm       = helm.gateway
  }
  cluster_name       = module.eks_gateway.cluster_name
  oidc_provider_arn  = module.eks_gateway.oidc_provider_arn
  oidc_provider_url  = module.eks_gateway.oidc_provider_url
  region             = var.aws_region
  vpc_id             = module.vpc_gateway.vpc_id
}

############################
# Backend App
############################


module "backend_app" {
  source     = "./modules/backend_app"
  depends_on = [module.eks_backend]
  providers = {
    kubernetes = kubernetes.backend
    helm       = helm.backend
  }
  namespace  = "aashish-eks-backend"
  #alb_sg_id  = aws_security_group.backend_alb.id
  app_image  = "hashicorp/http-echo:1.0"
  app_text   = "Hello from backend"
}

############################
# DNS
############################
/*
module "dns" {
  source          = "./modules/dns"
  zone_name       = "aashish-eks.local"
  vpc_ids         = [module.vpc_backend.vpc_id, module.vpc_gateway.vpc_id]
  backend_alb_dns = module.backend_app.ingress_hostname
  record_name     = "backend"
}
*/

############################
# Gateway App
############################

module "gateway_app" {
  source     = "./modules/gateway_app"
  depends_on = [module.eks_gateway]
  providers = {
    kubernetes = kubernetes.gateway
    helm       = helm.gateway
  }
  namespace  = "aashish-eks-gateway"
  backend_dns = module.backend_app.ingress_hostname
}

output "gateway_vpc_id" { value = module.vpc_gateway.vpc_id }
output "backend_vpc_id" { value = module.vpc_backend.vpc_id }
output "eks_gateway_cluster_name" { value = module.eks_gateway.cluster_name }
output "eks_backend_cluster_name" { value = module.eks_backend.cluster_name }
output "backend_alb_dns" {  value = module.backend_app.ingress_hostname }
#output "backend_private_dns" {  value = module.dns.backend_fqdn }
output "gateway_lb_dns" {  value = module.gateway_app.gateway_lb_dns }


