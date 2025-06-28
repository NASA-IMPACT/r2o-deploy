# Getting Started with Containerized NVIDIA Environment

## Prerequisites

This document assumes that you have either:

*   **OpenTofu** installed on your system.
*   **Kind** (Kubernetes In-Docker-Environment) installed and configured on your system.
*   **Docker** and **Podman** installed on your system, along with NVIDIA drivers to run GPU-enabled containers.

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


