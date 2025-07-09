# Getting Started with Containerized NVIDIA Environment

## Prerequisites

This document assumes that you have either:

*   **OpenTofu** installed on your system.
*   **Kind** (Kubernetes In-Docker-Environment) installed and configured on your system.
*   **Docker** and **Podman** installed on your system, along with NVIDIA drivers to run GPU-enabled containers.
*   **Ubuntu/Linux system** with NVIDIA GPU hardware
*   **NVIDIA drivers** properly installed and configured

### Install Requirements

To follow the guidelines outlined in this document, ensure that you have:

#### Installing Kind
*   Follow the official installation instructions for [OpenTofu](https://opentofu.org/).
*   Follow the official installation instructions for [Kind](https://kind.sigs.k8s.io/docs/user-guide/install/).
*   Follow the official installation instructions for [nvKind](https://github.com/NVIDIA/nvkind).
*   This will provide a way to containerize and deploy Kubernetes environments without having to set up a physical cluster.

#### Helpful installation link
*   Install kind with gpus [kind-with-gpus](https://www.substratus.ai/blog/kind-with-gpus).

#### Installing Docker and Podman

*   Install Docker using the package manager of your operating system (e.g. `apt` for Ubuntu-based systems, `brew` for macOS, etc.).
*   OR, install Podman, which allows you to run containers in isolated environments without needing root privileges.
*   For NVIDIA drivers, ensure that they are properly installed and configured on your system.

### Supported Environments

This setup supports the following environments:

#### NVIDIA-Kind Environment

*   Uses Kind as the container runtime environment for running Kubernetes clusters.
*   Mounts NVIDIA drivers to the containers requiring a GPU.
*   Provides an efficient way to develop, test, and deploy applications that rely on GPUs.

#### Docker Podman NVIDIA Environment

*   Uses Docker or Podman as the container runtime environment for running containers with NVIDIA drivers.
*   Supports running containers that require GPU acceleration without relying on Kind's cluster setup.

## Usage
To use this setup, follow these steps:
1. clone this repository to your local machine.
2. define the necessary variables in an `AWS Secret Manager` file (e.g., `cluster_name`, `http_ingress_port`...
3. run the following command to install Kind and create a Kubernetes cluster:
```bash
make local-deploy
```
This will deploy the Kind cluster with the specified configuration, and ArgoCD will be installed on the cluster with the preconfigured github applications.
4. Access the ArgoCD web interface
*   Navigate to `http://<your-cluster-ip>:<http_ingress_port>/argocd` in your browser.
5. Log in using the default credentials.

# GPU-Enabled Kubernetes Setup Guide

## Step 1: Install Go Programming Language

First, install Go 1.24.4:

```bash
# Download Go
wget https://go.dev/dl/go1.24.4.linux-amd64.tar.gz

# Install Go to local directory (avoiding system-wide installation)
mkdir -p ~/.local
tar -C ~/.local -xzf go1.24.4.linux-amd64.tar.gz

# Add Go to PATH
export PATH=$PATH:$HOME/.local/go/bin

# Verify installation
go version
```

## Step 2: Install Homebrew on Linux

Since some tools are easier to install via Homebrew, set up Homebrew for Linux:

```bash
# Create Homebrew directory
mkdir -p $HOME/.homebrew

# Clone Homebrew
git clone https://github.com/Homebrew/brew $HOME/.homebrew

# Clone homebrew-core tap
mkdir -p ~/.homebrew/Homebrew/Library/Taps/homebrew
git clone https://github.com/Homebrew/homebrew-core ~/.homebrew/Homebrew/Library/Taps/homebrew/homebrew-core

# Set up Homebrew environment variables
export HOMEBREW_PREFIX="$HOME/.homebrew"
export HOMEBREW_REPOSITORY="$HOME/.homebrew"
export HOMEBREW_CELLAR="$HOME/.homebrew/Cellar"
export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:$PATH"

# Verify installation
brew --version
```

## Step 3: Install Kubernetes Tools

Install essential Kubernetes tools:

```bash
# Install kind (Kubernetes in Docker)
brew install kind

# Install kubectl and helm
brew install kubectl helm

# Create kubectl alias for convenience
alias k=kubectl
```

## Step 4: Configure NVIDIA Container Runtime

Set up Docker to work with NVIDIA GPUs:

```bash
# Test GPU availability
nvidia-smi -L

# Test Docker with NVIDIA runtime
docker run --runtime=nvidia -e NVIDIA_VISIBLE_DEVICES=all ubuntu:20.04 nvidia-smi -L

# Configure NVIDIA container toolkit
sudo nvidia-ctk runtime configure --runtime=docker --set-as-default --cdi.enabled
sudo nvidia-ctk config --set accept-nvidia-visible-devices-as-volume-mounts=true --in-place

# Restart Docker services
sudo systemctl restart docker
sudo systemctl restart containerd

# Verify services are running
sudo systemctl status docker
sudo systemctl status containerd
```

## Step 5: Install and Use nvkind

Install NVIDIA's nvkind tool for GPU-enabled Kubernetes clusters:

```bash
# Install nvkind
go install github.com/NVIDIA/nvkind/cmd/nvkind@latest

# Add Go bin directory to PATH
export PATH=$PATH:$HOME/go/bin

# Create GPU-enabled Kubernetes cluster
nvkind cluster create
```

## Step 6: Install NVIDIA GPU Operator

Deploy the NVIDIA GPU Operator to manage GPU resources in Kubernetes:

```bash
# Add NVIDIA Helm repository
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia || true
helm repo update

# Install GPU Operator (with host drivers disabled since we're using nvkind)
helm install --wait --generate-name \
  -n gpu-operator --create-namespace \
  nvidia/gpu-operator --set driver.enabled=false

# Verify GPU operator pods
k get pods -n gpu-operator
```

## Step 7: Test GPU Access in Kubernetes

Test that GPU resources are available in the cluster:

```bash
# Run interactive GPU test container
k run -it --rm gpu-test --image=nvidia/cuda:12.0.1-runtime-ubuntu22.04 -- /bin/bash

# Inside the container, you can run:
# nvidia-smi -L
```

## Step 8: Deploy NASA R2O Project

Clone and deploy the NASA R2O project:

```bash
# Clone the repository
git clone https://github.com/NASA-IMPACT/r2o-deploy.git
cd r2o-deploy

# Switch to GPU support branch
git checkout feature/support-cluster-with-gpu

# Set up environment configuration
cp .env.example .env
nano .env  # Edit configuration as needed

# Generate SSH key if needed
ssh-keygen -t rsa

# Source environment variables
set -a; source .env; set +a

# Navigate to local setup directory
cd local-setup

# Generate SSL certificates
openssl req -x509 -newkey rsa:2048 -nodes -keyout key.pem -out cert.pem -days 365

# Install OpenTofu (Terraform alternative)
brew install opentofu

# Initialize and deploy infrastructure
make init
make plan
make apply
make deploy
```

## Step 9: Verification

Verify the deployment:

```bash
# Check all pods
k get pods

# Check GPU operator pods specifically
k get pods -n gpu-operator

# Test GPU access again
k run -it --rm gpu-test --image=nvidia/cuda:12.0.1-runtime-ubuntu22.04 -- /bin/bash
```

## Cleanup

To clean up the environment:

```bash
# List clusters
kind get clusters

# Delete the cluster (replace with actual cluster name)
kind delete cluster --name nvkind-rqbcv
```

## Key Points

1. **nvkind** is NVIDIA's tool for creating GPU-enabled Kubernetes clusters using kind
2. The **GPU Operator** manages GPU resources and drivers within Kubernetes
3. The **driver.enabled=false** setting is important when using nvkind since it manages drivers differently
4. The **NASA R2O project** appears to be a research-to-operations deployment system with GPU support
5. **OpenTofu** is used as a Terraform alternative for infrastructure management

## Troubleshooting

- Ensure NVIDIA drivers are properly installed on the host
- Verify Docker can access GPUs before creating the cluster
- Check that all services (Docker, containerd) are running after configuration changes
- Make sure environment variables are properly sourced when working with the R2O project
