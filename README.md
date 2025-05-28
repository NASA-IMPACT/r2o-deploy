# R2O Deployment Documentation

## Overview

This repository contains infrastructure code for deploying applications in local environments and connecting them to cloud production environments. The setup uses Infrastructure as Code (IaC) principles with OpenTofu (Terraform) and provides two main deployment paths:

1. **Local Deployment**: Uses Kind (Kubernetes in Docker) with ArgoCD for GitOps
2. **Cloud Deployment**: Uses AWS services including Lambda, API Gateway, and CloudFront

## Table of Contents

- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Local Deployment](#local-deployment)
- [Cloud Deployment](#cloud-deployment)
- [Architecture Overview](#architecture-overview)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools

1. **OpenTofu** (Infrastructure as Code tool)
   - Alternative to Terraform
   - Used for managing infrastructure state

2. **Kind** (Kubernetes in Docker)
   - For local Kubernetes cluster
   - Requires Docker or Podman

3. **kubectl** 
   - Kubernetes command-line tool
   - For interacting with clusters

4. **Helm**
   - Kubernetes package manager
   - Used for ArgoCD installation

5. **AWS CLI** (for cloud deployment)
   - For AWS resource management
   - Requires proper IAM permissions

### AWS Requirements

- AWS Account with appropriate IAM permissions
- GitHub App for private repository access (if using private repos)
- SSL certificates for HTTPS (stored locally for Kind setup)

## Environment Setup

### 1. Create Environment Configuration

Copy the example environment file and customize it:

```bash
cp .env.example .env
```

Edit `.env` with your specific values:

```bash
# AWS Configuration
AWS_REGION=us-west-2
AWS_PROFILE=your-aws-profile

# Terraform State Management
LOCAL_DEPLOY_STATE_BUCKET_NAME=your-terraform-state-bucket
LOCAL_DEPLOY_STATE_DYNAMO_TABLE=your-terraform-lock-table
PREFIX=your-unique-prefix

# Local Deployment Configuration
TF_VAR_cluster_name=neo-cluster
TF_VAR_http_ingress_port=8888
TF_VAR_https_ingress_port=4444
TF_VAR_kind_experimental_provider=podman

# GitHub App Configuration (for private repos)
TF_VAR_github_app_id=your-github-app-id
TF_VAR_github_app_installation_id=your-installation-id
TF_VAR_path_to_github_app_private_key=/path/to/private-key.pem
```

### 2. Install OpenTofu

```bash
# Install OpenTofu (if not already installed)
make tofu-install
```

## Local Deployment

### What Gets Deployed Locally

The local deployment creates:

1. **Kind Cluster**: A local Kubernetes cluster running in Docker/Podman
2. **Ingress Controller**: NGINX Ingress for routing traffic
3. **ArgoCD**: GitOps tool for continuous deployment
4. **SSL Configuration**: HTTPS support with custom certificates
5. **Application Deployments**: Your applications via ArgoCD

### Architecture Components

#### Kind Cluster Configuration
- **Control Plane**: Single node cluster
- **Port Mapping**: 
  - HTTP: 8888 → 80 (configurable)
  - HTTPS: 4444 → 443 (configurable)
- **Network**: Pod subnet `10.244.0.0/16`

#### ArgoCD Setup
- **Namespace**: `argocd`
- **Access**: Via ingress at `https://kind.neo.nsstc.uah.edu:4444/argocd`
- **Authentication**: Initial admin password stored in `argocd-login.txt`

### Deployment Steps

#### 1. Prepare Prerequisites

Ensure SSL certificates are available at the expected paths:
```bash
# Default paths (modify in variables if different)
/home/opkind/ssl_certs/neo.nsstc.uah.edu.unencrypted.key
/home/opkind/ssl_certs/bundle-cert-intermediates-root.cer
```

#### 2. Deploy Local Infrastructure

```bash
# Deploy everything
make local-deploy
```

This command will:
1. Create/verify Terraform state bucket and DynamoDB table
2. Initialize Terraform in the local-setup directory
3. Apply the infrastructure configuration

#### 3. Verify Deployment

```bash
# Check cluster status
kubectl cluster-info --context kind-neo-cluster

# Check ArgoCD pods
kubectl get pods -n argocd

# Get ArgoCD admin password
cat local-setup/argocd/argocd-login.txt
```

#### 4. Access Services

- **ArgoCD UI**: `https://kind.neo.nsstc.uah.edu:4444/argocd`
- **Applications**: Through ingress rules defined in your application manifests

### Local Deployment Configuration

#### Application Configuration

Applications are defined in `local-setup/argocd-github-repos.tf`:

```hcl
variable "argocd_applications" {
  type = list(object({
    app_name      = string
    project_name  = optional(string)
    repo_url      = string
    target_path   = string
    target_branch = string
    private       = optional(bool)
  }))
  default = [
    {
      app_name      = "fastapi-app"
      repo_url      = "https://github.com/NASA-IMPACT/r2o-fastapi-k8s"
      target_path   = "fastapi-manifest"
      target_branch = "use-ssl"
      private       = true
    }
  ]
}
```

#### GitHub App Configuration

For private repositories, configure GitHub App authentication:

1. Create a GitHub App in your organization
2. Install the app on repositories you want to access
3. Download the private key
4. Set the environment variables with app ID, installation ID, and key path

### Local Commands

```bash
# Initialize only
make -C local-setup init

# Plan changes
make -C local-setup plan

# Deploy
make -C local-setup deploy

# Clean up
make local-cleanup
```

## Cloud Deployment

### What Gets Deployed in Cloud

The cloud deployment creates:

1. **VPC**: Custom Virtual Private Cloud with public/private subnets
2. **Lambda Function**: Proxy service for routing requests
3. **API Gateway**: REST API endpoint for Lambda
4. **CloudFront**: CDN distribution for global access
5. **Security Groups**: Network security rules
6. **IAM Roles**: Permissions for Lambda execution

#### Components Explanation

1. **CloudFront Distribution**
   - Global CDN for low-latency access
   - SSL termination
   - Caching policies (disabled for API calls)

2. **API Gateway**
   - REST API with proxy integration
   - Handles all HTTP methods (GET, POST, PUT, DELETE, etc.)
   - Stage: `api`

3. **Lambda Proxy Function**
   - Node.js runtime
   - Forwards requests to target server
   - Custom path mapping logic
   - VPC-enabled for security

4. **VPC Configuration**
   - Private subnets for Lambda
   - NAT Gateway for outbound internet access
   - VPC endpoints for AWS services

### Cloud Deployment Steps

#### 1. Deploy VPC (Optional - if using custom VPC)

```bash
# Deploy VPC infrastructure
make vpc-deploy
```

#### 2. Deploy Application Infrastructure

```bash
# Deploy all cloud components
make cloud-deploy
```

#### 3. Verify Deployment

```bash
# Check outputs
make -C cloud-setup output

# Test API Gateway endpoint
curl https://your-api-gateway-id.execute-api.us-west-2.amazonaws.com/api/v1/api/health

# Test CloudFront distribution
curl https://your-cloudfront-domain.cloudfront.net/v1/api/health
```

### Lambda Proxy Function

The Lambda function (`cloud-setup/lambda-function/index.js`) provides intelligent request routing:

#### Key Features

1. **Path Mapping**: Handles different URL structures
2. **Query Parameter Forwarding**: Preserves query strings
3. **Header Management**: Proper host header handling
4. **Error Handling**: Custom 404 responses with debugging info
5. **SSL Support**: Ignores certificate validation for development

#### Path Handling Examples

```javascript
// Health check
/v1/api/health → /v1/api/health

// Root path redirect
/ → /v1/api/health

// Proxy paths
/api/users → /api/users

// With query parameters
/api/data?limit=10 → /api/data?limit=10
```

### Cloud Configuration

#### Environment Variables

The Lambda function accepts these environment variables:

- `TARGET_SERVER`: Default target server URL
- Additional variables can be added in `cloud-setup/variables.tf`

#### VPC Configuration

Default VPC settings (modify in `cloud-setup/variables.tf`):

```hcl
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  default = ["us-west-2a", "us-west-2b"]
}
```

### Cloud Commands

```bash
# VPC only
make vpc-deploy

# Application only
make cloud-deploy
```

## State Management

### Remote State Configuration

Both local and cloud deployments use S3 backend for state management:

- **State Bucket**: Stores Terraform state files
- **DynamoDB Table**: Provides state locking
- **Encryption**: State files are encrypted at rest

### State Structure

```
s3://your-bucket/
├── your-prefix/local-deployment/terraform.tfstate
├── your-prefix/cloud-deployment/terraform.tfstate
└── your-prefix/cloud-deployment/vpc/terraform.tfstate
```

## CI/CD Pipeline

### GitHub Actions Workflow

The repository includes a CI/CD pipeline (`.github/workflows/cicd.yml`):

#### Features

1. **OIDC Authentication**: Secure AWS access without long-lived credentials
2. **Secrets Management**: AWS Secrets Manager integration
3. **Self-Hosted Runner**: Runs on your infrastructure
4. **Automated Deployment**: Triggers on code changes

#### Workflow Steps

1. **Build**: Install dependencies and run tests
2. **Deploy**: 
   - Configure AWS credentials via OIDC
   - Retrieve secrets from AWS Secrets Manager
   - Execute deployment

### OIDC Configuration

The workflow uses AWS IAM OIDC provider for secure authentication:

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::244822573120:role/r2o-oidc
    aws-region: us-west-2
```

## Troubleshooting

### Common Issues

#### Local Deployment

1. **Kind Cluster Creation Fails**
   ```bash
   # Check Docker/Podman status
   docker ps
   # or
   podman ps
   
   # Delete existing cluster
   kind delete cluster --name neo-cluster
   ```

2. **SSL Certificate Issues**
   ```bash
   # Verify certificate paths
   ls -la /home/opkind/ssl_certs/
   
   # Check certificate validity
   openssl x509 -in /path/to/cert.cer -text -noout
   ```

3. **ArgoCD Access Issues**
   ```bash
   # Check ingress status
   kubectl get ingress -n argocd
   
   # Port forward as alternative
   kubectl port-forward svc/argocd-helm-server -n argocd 8080:443
   ```

#### Cloud Deployment

1. **Lambda Function Errors**
   ```bash
   # Check CloudWatch logs
   aws logs describe-log-groups --log-group-name-prefix "/aws/lambda"
   
   # View recent logs
   aws logs tail /aws/lambda/your-function-name --follow
   ```

2. **API Gateway Issues**
   ```bash
   # Test API Gateway directly
   curl -v https://your-api-id.execute-api.region.amazonaws.com/api/
   ```

3. **VPC Connectivity Issues**
   ```bash
   # Check NAT Gateway
   aws ec2 describe-nat-gateways
   
   # Verify route tables
   aws ec2 describe-route-tables
   ```

### Debug Commands

```bash
# Local debugging
kubectl logs -n argocd deployment/argocd-helm-application-controller
kubectl describe pod -n argocd

# Cloud debugging
aws lambda invoke --function-name your-function response.json
aws apigateway test-invoke-method --rest-api-id your-api --resource-id your-resource --http-method GET
```

### Getting Help

1. **Check Logs**: Always start with application and infrastructure logs
2. **Verify Configuration**: Ensure environment variables are set correctly
3. **Test Incrementally**: Test each component separately
4. **Use Debug Mode**: Enable verbose logging where available

## Best Practices

### Security

1. **Environment Variables**: Never commit sensitive data to git
2. **IAM Permissions**: Use least privilege principle
3. **SSL/TLS**: Always use HTTPS in production
4. **State Files**: Encrypt Terraform state files
