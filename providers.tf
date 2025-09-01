provider "aws" {
  region  = var.aws_region
  #profile = var.aws_profile
}

# Kubernetes + Helm providers are configured only after cluster creation using data sources/outputs in modules.


# Backend EKS cluster
provider "kubernetes" {
  alias                  = "backend"
  host                   = module.eks_backend.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_backend.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.backend.token
}

data "aws_eks_cluster_auth" "backend" {
  name = module.eks_backend.cluster_name
}

# Gateway EKS cluster
provider "kubernetes" {
  alias                  = "gateway"
  host                   = module.eks_gateway.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_gateway.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.gateway.token
}

data "aws_eks_cluster_auth" "gateway" {
  name = module.eks_gateway.cluster_name
}


provider "helm" {
  alias                  = "backend"
  kubernetes = {
    host                   = module.eks_backend.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_backend.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.backend.token
  }
}

provider "helm" {
  alias                  = "gateway"
  kubernetes = {
    host                   = module.eks_gateway.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_gateway.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.gateway.token
  }
}

