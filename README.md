# Project Documentation - Local and Cloud Deployment

## Repository Overview

This repository provides infrastructure as code (IaC) for local Kubernetes development insdie neo and AWS cloud deployments that provide access to the neo environment. The project is organized into two main components:

1. **Local Setup**: A development environment using Kind (Kubernetes in Docker), ArgoCD, and nginx-ingress for local testing and development.
2. **Cloud Setup**: An AWS-based proxy deployment with Lambda, API Gateway, CloudFront, and VPC configuration.

## Repository Structure

```
.
├── .env.example                 # Environment variables template
├── Makefile                     # Root-level make commands
├── cloud-setup/                 # AWS infrastructure resources
│   ├── app/                     # Lambda function resources
│   ├── api-gateway/             # API Gateway configuration
│   ├── cloudfront/              # CloudFront distribution
│   ├── lambda-function/         # Lambda function code
│   ├── vpc/                     # VPC networking configuration
│   └── ...
└── local-setup/                 # Local Kubernetes setup
    ├── kind/                    # Kind cluster configuration
    ├── argocd/                  # ArgoCD deployment and configuration
    └── ...
```

## Local Setup (Kubernetes with Kind)

### Overview

The local setup provisions a Kubernetes environment using Kind (Kubernetes in Docker) with the following components:

- **Kind cluster**: A lightweight Kubernetes cluster running inside Docker
- **Ingress NGINX Controller**: For handling ingress traffic to the cluster
- **ArgoCD**: GitOps continuous delivery tool for Kubernetes

### Prerequisites

- Docker or Podman installed
- kubectl installed
- OpenTofu (or Terraform) installed
- make utility installed

### Configuration

Configuration is managed through environment variables in the `.env` file:

```
# Copy from .env.example and customize as needed
TF_VAR_cluster_name=neo-test              # Name of the Kind cluster
TF_VAR_http_ingress_port=8889             # Port for HTTP ingress
TF_VAR_https_ingress_port=4449            # Port for HTTPS ingress
KIND_EXPERIMENTAL_PROVIDER=podman         # Container runtime (podman or docker)
TF_VAR_argocd_applications=[...]          # ArgoCD application configurations
```

### Deployment Steps

1. **Setup Environment Variables**:
   ```bash
   cp .env.example .env
   # Edit .env to configure your environment
   ```

2. **Deploy the Local Environment**:
   ```bash
   make local-deploy
   ```

3. **Check Deployment Status**:
   ```bash
   kubectl get pods --all-namespaces
   ```

4. **Access ArgoCD UI**:
   The ArgoCD UI is available at: http://localhost:8889/argocd
   
   Retrieve the admin password:
   ```bash
   cat local-setup/argocd/argocd-login.txt
   ```
   
   Username: `admin`

### Key Components

#### Kind Cluster Configuration

The Kind cluster is defined in `local-setup/kind/config.yaml.tmpl`:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 80
    hostPort: ${http_ingress_port}
    protocol: TCP
  - containerPort: 443
    hostPort: ${https_ingress_port}
    protocol: TCP
```

This configuration creates a single-node cluster with port mappings for HTTP and HTTPS ingress.

#### ArgoCD Configuration

ArgoCD is configured to deploy applications from Git repositories. Applications are defined in the `.env` file:

```
TF_VAR_argocd_applications=[{"app_name":"app-name","project_name":"project-name","repo_url":"https://github.com/org/repo","target_path":"path/to/app","target_branch":"main"}]
```

ArgoCD is accessible through the ingress at `/argocd` path.

### Cleanup

To clean up the local environment:

```bash
make local-cleanup
```

## Cloud Setup (AWS)

### Overview

The cloud setup deploys a serverless proxy infrastructure on AWS with the following components:

- **VPC**: Custom network with public and private subnets
- **Lambda Function**: Node.js proxy function running in a VPC
- **API Gateway**: REST API interface for the Lambda function
- **CloudFront**: Content delivery network for the API Gateway

### Prerequisites

- AWS CLI configured with appropriate permissions
- OpenTofu (or Terraform) installed
- S3 bucket for Terraform state (referenced as `r2o-tf-state-bucket`)

### Deployment Architecture

![AWS Architecture Diagram]

1. **VPC**: Isolated network with public and private subnets across two AZs
2. **Lambda**: Proxy function running in private subnets with VPC endpoints
3. **API Gateway**: REST API with proxy integration to Lambda
4. **CloudFront**: Distribution with API Gateway as origin

### Deployment Steps

The AWS infrastructure is organized into modules that can be deployed separately:

1. **Deploy VPC Infrastructure**:
   ```bash
   cd cloud-setup/vpc
   make init
   make apply
   ```

2. **Deploy everything else**:
   ```bash
   cd cloud-setup
   make init
   make apply
   ```

### Key Components

#### Lambda Proxy Function

The Lambda function (`cloud-setup/lambda-function/index.js`) is designed to proxy HTTP requests to a target server, which can be configured via environment variables:

```javascript
// Target server configuration
const targetServer = event.targetServer || process.env.TARGET_SERVER || 'https://kind.neo.nsstc.uah.edu:4449';
```

By default, it points to the HTTPS port of the local Kind cluster.

#### API Gateway Configuration

The API Gateway is configured with a catch-all proxy resource (`{proxy+}`) that forwards all requests to the Lambda function:

```
ANY /{proxy+} -> Lambda
ANY / -> Lambda
```

#### State Management

State is stored in an S3 bucket with a seperate configuration for the VPC.

- VPC: `vpc/terraform.tfstate`
- Complete application: `application/terraform.tfstate`

### Cleanup

To destroy the cloud resources:

```bash
cd cloud-setup
make destroy
```

**Note**: This will not destroy the VPC by default. To destroy the VPC:

```bash
cd cloud-setup/vpc
make destroy
```

## Integration Between Local and Cloud Environments

The local Kubernetes cluster and AWS cloud infrastructure are designed to work together:

1. The Lambda proxy function in AWS can forward requests to the local Kind cluster (when accessible)
2. This allows testing cloud-to-local integrations without exposing services directly

To configure the Lambda function to point to your local cluster:

1. Ensure your local cluster is accessible via a public IP or domain
2. Update the `TARGET_SERVER` environment variable in Lambda to point to your cluster's address

## Common Operations

### Managing ArgoCD Applications

To add a new application to ArgoCD:

1. Update the `TF_VAR_argocd_applications` value in `.env`
2. Run `make local-deploy` to apply changes

### Accessing Local Cluster

```bash
# Set kubectl context
kubectl cluster-info --context kind-neo-test

# Port-forward to a service (if needed)
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

### Viewing AWS Resources

```bash
# Get Lambda details
aws lambda get-function --function-name proxy-lambda

# Get API Gateway URL
cd cloud-setup
tofu output api_gateway_invoke_url

# Get CloudFront domain
tofu output cloudfront_domain_name
```

## Troubleshooting

### Local Setup Issues

1. **Kind cluster fails to start**:
   - Check Docker/Podman is running
   - Ensure ports 8889 and 4449 are available
   - Check logs: `kind export logs --name neo-test`

2. **ArgoCD not accessible**:
   - Verify ingress controller is running: `kubectl get pods -n ingress-nginx`
   - Check ingress is created: `kubectl get ingress -n argocd`

### Cloud Setup Issues

1. **Lambda deployment failure**:
   - Check Lambda execution role permissions
   - Verify VPC endpoints for Lambda and CloudWatch

2. **API Gateway connectivity issues**:
   - Check Lambda permissions for API Gateway
   - Verify Lambda VPC configuration

## References

- [Kind Documentation](https://kind.sigs.k8s.io/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)