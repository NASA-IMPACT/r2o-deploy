# Kubernetes and ArgoCD Local Development Environment

This repository contains infrastructure-as-code (IaC) setup for deploying a local Kubernetes environment with ArgoCD for continuous delivery. It uses OpenTofu (a Terraform fork) to provision and configure all components.

## Repository Structure

```
.
├── .env.example                     # Example environment variables
├── .gitignore                       # Git ignore patterns
├── Makefile                         # Main project Makefile
├── cloud-setup/                     # Future cloud deployment (empty)
└── local-setup/                     # Local Kubernetes setup
    ├── Makefile                     # Local setup Makefile
    ├── argocd/                      # ArgoCD configuration
    │   ├── argocd-conf/             # ArgoCD manifests and configuration
    │   ├── main.tf                  # Terraform configuration for ArgoCD
    │   └── variables.tf             # ArgoCD variables definition
    ├── kind/                        # Kind cluster configuration
    │   ├── config.yaml.tmpl         # Kind cluster config template
    │   ├── ingress-nginx.yaml       # NGINX ingress controller manifest
    │   ├── main.tf                  # Terraform config for Kind
    │   └── variables.tf             # Kind variables definition
    ├── main.tf                      # Main Terraform config for local setup
    ├── outputs.tf                   # Terraform outputs
    ├── provider.tf                  # Provider configuration
    └── variables.tf                 # Variables for local setup
```

## Prerequisites

- Linux/Unix environment
- Podman
- kubectl
- OpenTofu (or Terraform)
- Kind (Kubernetes in Docker)
- Git

## Setup Instructions

### 1. Environment Configuration

1. Create a `.env` file based on `.env.example`:
   ```bash
   cp .env.example .env
   ```

2. Customize the variables in `.env`:
   ```
   # Configuration variables
   TF_VAR_cluster_name=neo-test           # Name of your Kind cluster
   TF_VAR_http_ingress_port=8889          # HTTP port for ingress
   TF_VAR_https_ingress_port=4449         # HTTPS port for ingress
   KIND_EXPERIMENTAL_PROVIDER=podman      # Container provider (podman or docker)
   
   # Optional: Configure multiple ArgoCD applications
   TF_VAR_argocd_applications=[{"app_name":"app-name","project_name":"project-name","repo_url":"https://github.com/user/repo","target_path":"path/to/app","target_branch":"main"}]
   
   # Optional: GitHub App credentials for private repo access
   TF_VAR_github_app_id=12345
   TF_VAR_github_app_installation_id=6789410
   TF_VAR_github_app_private_key_path=path/to/key.pem
   ```

### 2. Local Deployment

1. Install OpenTofu (if not installed):
   ```bash
   make -C local-setup tofu-install
   ```

2. Deploy the local environment:
   ```bash
   make local-deploy
   ```

   This command:
   - Creates a Kind cluster
   - Sets up ingress-nginx
   - Installs ArgoCD
   - Configures ArgoCD with specified applications

3. Access the setup:
   - ArgoCD UI: http://localhost:{http_ingress_port}/argocd
   - Get the ArgoCD admin password:
     ```bash
     cat local-setup/argocd/argocd-login.txt
     ```

### 3. Cleaning Up

To destroy the environment:
```bash
make local-cleanup
```

## Architecture Details

### Kind Cluster

The setup creates a single-node Kubernetes cluster running locally using Kind (Kubernetes in Docker). The cluster is configured to:
- Use podman/docker for container runtime
- Forward ports for HTTP and HTTPS ingress
- Support LoadBalancer services via metallb (implicit)

### NGINX Ingress Controller

NGINX Ingress Controller is deployed to provide ingress capabilities to the cluster, with:
- LoadBalancer service type for external access
- HTTP and HTTPS ports exposed via port forwarding
- Configured webhooks for validating ingress resources

### ArgoCD

ArgoCD is deployed via Helm chart and configured with:
- Web UI accessible at /argocd path
- Insecure mode enabled for simplicity
- Automated sync policy for Git-based deployments
- Support for multiple application deployments
- Optional GitHub App integration for private repositories

## GitOps Configuration

1. Multiple applications via `TF_VAR_argocd_applications`:
   ```
   TF_VAR_argocd_applications='[
     {
       "app_name": "app1",
       "project_name": "default",
       "repo_url": "https://github.com/user/repo1",
       "target_path": "path/to/app1",
       "target_branch": "main"
     },
     {
       "app_name": "app2",
       "project_name": "default",
       "repo_url": "https://github.com/user/repo2",
       "target_path": "path/to/app2",
       "target_branch": "develop"
     }
   ]'
   ```

## GitHub App Integration (Optional)

For private repositories, you can configure GitHub App credentials:

1. Create a GitHub App with repository permissions
2. Generate a private key
3. Install the app on your repositories
4. Configure the app credentials in `.env`:
   ```
   TF_VAR_github_app_id=your_app_id
   TF_VAR_github_app_installation_id=your_installation_id
   TF_VAR_github_app_private_key_path=path/to/private-key.pem
   ```

## Troubleshooting

### Kind Cluster Creation Fails
- Check if Kind is installed: `kind --version`
- Verify podman/docker is running: `podman ps- a`
- Ensure ports are not already in use: `ss -tulpn | grep <port>`

### ArgoCD Deployment Fails
- Check Kubernetes context is correctly set: `kubectl config current-context`
- Verify Helm is installed: `helm version`
- Check for error messages in the Terraform output

### Applications Not Syncing
- Check repository URL and path 
- Verify credentials for private repositories
- Check ArgoCD logs: `kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller`

### Ingress Not Working
- Verify ingress controller is running: `kubectl get pods -n ingress-nginx`
- Check service is properly exposing ports: `kubectl get svc -n ingress-nginx`
- Verify ingress resource: `kubectl get ingress -n argocd`