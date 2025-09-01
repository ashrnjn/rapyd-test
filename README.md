# Sentinel Split Architecture (Terraform)

This repository provisions two isolated VPCs with private subnets, NAT, VPC endpoints, a VPC peering connection, and two EKS clusters (`gateway` and `backend`).

> **Note:** No public EC2 instances are created. Public subnets exist only to host NAT Gateways and the gateway cluster's public Load Balancer when you deploy an ingress/proxy.

## What gets created
- `vpc-gateway` and `vpc-backend` (CIDRs configurable)
- Private subnets (2 AZs), Public subnets (for NAT/LB)
- NAT Gateways (1 per AZ), route tables
- VPC Endpoints for SSM, KMS, Secrets Manager, ECR, Logs, EC2, and S3/DynamoDB
- VPC Peering and private routing both ways
- Two EKS clusters with managed node groups in private subnets, private endpoint enabled, public endpoint CIDR-restricted

## How to use
```bash
cd envs/dev
# optionally edit terraform.tfvars
cd .. && terraform init
terraform apply
```

After clusters are created, configure `aws-auth` ConfigMap to allow node role access. You can use the output IAM roles from the EKS modules and apply via `kubectl`.
