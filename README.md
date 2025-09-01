Terraform EKS Deploy + Multi-Cluster App Deploy
Overview

This repository provides a fully automated GitHub Actions workflow to deploy a multi-cluster Amazon EKS environment using Terraform. It provisions:

Networking infrastructure: VPCs for backend and gateway clusters, including peering.

EKS clusters: Separate backend and gateway clusters for isolation and scalability.

ALB Controllers: For load balancing Kubernetes services.

Applications: Backend and Gateway apps deployed on respective clusters.

This setup ensures repeatable, reliable, and idempotent deployments across AWS accounts and regions, enabling multi-cluster architectures suitable for production workloads.

Architecture Diagram
┌───────────────────────────────┐
│        VPC Gateway            │
│ ┌───────────────────────────┐ │
│ │ EKS Cluster Gateway        │ │
│ │ ┌───────────────────────┐ │ │
│ │ │ ALB Controller         │ │ │
│ │ └─────────┬─────────────┘ │ │
│ │           │                │ │
│ │     ┌─────▼─────┐          │ │
│ │     │ Gateway App│          │ │
│ │     └───────────┘          │ │
│ └───────────────────────────┘ │
│               │ Peering        │
│               ▼                │
│ ┌───────────────────────────┐ │
│ │ VPC Backend               │ │
│ │ ┌───────────────────────┐ │ │
│ │ │ EKS Cluster Backend    │ │ │
│ │ │ ┌───────────────────┐ │ │ │
│ │ │ │ ALB Controller     │ │ │ │
│ │ │ └─────────┬─────────┘ │ │ │
│ │ │           │           │ │ │
│ │ │     ┌─────▼─────┐     │ │ │
│ │ │     │ Backend App│     │ │ │
│ │ │     └───────────┘     │ │ │
│ │ └───────────────────────┘ │ │
└───────────────────────────────┘

Traffic Flow Explanation

Gateway App receives external requests.

ALB Controller (Gateway Cluster) dynamically provisions Application Load Balancers to route traffic to the Gateway App.

Gateway App communicates securely with the Backend App across VPC peering.

ALB Controller (Backend Cluster) manages load balancing for the Backend App, enabling high availability and scaling.

Benefits

Separation of concerns: Backend and gateway workloads run in different clusters for security and scalability.

Dynamic Load Balancing: ALB Controllers automate traffic routing and ensure high availability.

Secure Multi-Cluster Communication: VPC peering allows secure, private connectivity between clusters.

Modular Deployments: Each component (VPC, EKS, ALB, App) is deployed via Terraform modules, allowing independent updates and repeatable deployments.

Prerequisites

AWS Account with sufficient permissions to create:

IAM roles/policies

VPCs, subnets, route tables, security groups

EKS clusters and Node Groups

ALB and target groups

GitHub Secrets:

AWS_ACCESS_KEY_ID

AWS_SECRET_ACCESS_KEY

Terraform CLI v1.x (optional if running fully in GitHub Actions)

kubectl (optional for verifying deployments)

Repository Structure
├── .github/workflows/
│   └── deploy.yml          # GitHub Actions workflow
├── modules/
│   ├── vpc_backend/        # Backend VPC resources
│   ├── vpc_gateway/        # Gateway VPC resources
│   ├── eks_backend/        # Backend EKS cluster
│   ├── eks_gateway/        # Gateway EKS cluster
│   ├── alb_controller_backend/  # ALB Controller for backend cluster
│   ├── alb_controller_gateway/  # ALB Controller for gateway cluster
│   ├── backend_app/        # Backend app deployment
│   └── gateway_app/        # Gateway app deployment
├── envs/
│   └── dev/
│       └── terraform.tfvars # Environment-specific variables
├── iam-policy.json          # IAM policy for ALB Controller
└── README.md

Workflow Steps & Benefits
1. Checkout Repository
- name: Checkout repo
  uses: actions/checkout@v4


Action: Clones the repository to the GitHub runner.

Benefit: Ensures the latest Terraform configuration, modules, and environment files are available for deployment.

2. Configure AWS Credentials
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: eu-west-2


Action: Sets AWS credentials in the runner.

Benefit: Allows Terraform and AWS CLI commands to authenticate securely without hardcoding credentials.

3. Create IAM Policy for ALB Controller
- name: Create LoadBalancerControllerPolicy
  run: |
    set +e
    aws iam create-policy \
      --policy-name LoadBalancerControllerPolicy \
      --policy-document file://iam-policy.json || echo "Policy may already exist"
    set -e


Action: Creates the IAM policy required by the AWS Load Balancer Controller.

Benefit: Ensures the ALB Controller has proper permissions to manage ALBs automatically, enabling Kubernetes services to expose traffic securely.

4. Terraform Setup
- name: Setup Terraform
  uses: hashicorp/setup-terraform@v3


Action: Installs Terraform on the GitHub runner.

Benefit: Guarantees the workflow uses a consistent Terraform version, ensuring reproducible infrastructure deployments.

5. Terraform Init
- name: Terraform Init
  run: terraform init


Action: Initializes Terraform modules, downloads providers, and sets up the backend.

Benefit: Prepares Terraform for a reliable plan/apply cycle and ensures all modules are available before deployment.

6. Networking Infrastructure Deployment
- name: Terraform Plan (Networking)
- name: Terraform Apply (Networking)


Action: Creates backend and gateway VPCs along with VPC peering.

Benefit: Provides isolated networking for backend and gateway clusters with controlled connectivity. Enables multi-cluster communication without overlapping IP ranges.

7. EKS Cluster Deployment
- name: Terraform Plan (EKS)
- name: Terraform Apply (EKS)


Action: Deploys backend and gateway EKS clusters.

Benefit: Provides fully managed Kubernetes clusters for backend and gateway workloads, enabling scalability and separation of concerns between clusters.

8. ALB Controllers Deployment
- name: Terraform Plan (ALB Controllers)
- name: Terraform Apply (ALB Controllers)


Action: Deploys ALB controllers to both clusters.

Benefit: Automatically manages Application Load Balancers for services. Ensures seamless traffic routing, dynamic load balancing, and integration with Kubernetes Ingress resources.

Note: The workflow waits 120 seconds to allow ALB pods to start properly.

9. Backend Application Deployment
- name: Terraform Plan (Backend App)
- name: Terraform Apply (Backend App)


Action: Deploys backend application to the backend EKS cluster.

Benefit: Ensures backend services are running in an isolated cluster with proper load balancing, security, and networking.

10. Gateway Application Deployment
- name: Terraform Plan (Gateway App)
- name: Terraform Apply (Gateway App)


Action: Deploys the gateway application to the gateway EKS cluster.

Benefit: Provides a front-facing entry point for services, enabling routing, authentication, and access control for backend services while isolating traffic flows.

Summary of Benefits

Isolation & Security: Separate VPCs and clusters for backend and gateway workloads.

Scalability: EKS clusters and ALBs allow dynamic scaling of applications.

Automation: GitHub Actions + Terraform ensures repeatable deployments.

High Availability: ALB Controllers automatically balance traffic and maintain uptime.

Modular Architecture: Independent Terraform modules for networking, clusters, ALBs, and applications enable incremental updates and easier management.