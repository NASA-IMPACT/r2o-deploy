# Configuration variables
CLUSTER_NAME := neo-dev-cluster
CLUSTER_CONFIG := kind-config.yaml
ARGOCD_NAMESPACE := argocd
ARGOCD_PASSWORD_FILE := .argocd-password
TOFU_VERSION := 1.6.0
TOFU_DIR := $(HOME)/.local/bin
NODE_PORT_HTTP := 30080
NODE_PORT_HTTPS := 30443
KIND_EXPERIMENTAL_PROVIDER := podman

# Define shell for consistent behavior
SHELL := /bin/bash

# Helper functions
define info_message
	@echo -e "\033[0;32m$(1)\033[0m"
endef

define warning_message
	@echo -e "\033[0;33m$(1)\033[0m"
endef

define error_message
	@echo -e "\033[0;31m$(1)\033[0m"
endef

define countdown
	@echo "Waiting for resources to be ready..."; \
	secs=$(1); \
	while [ $$secs -gt 0 ]; do \
		printf "%d\033[0K\r" "$$secs"; \
		sleep 1; \
		secs=$$((secs - 1)); \
	done; \
	echo ""
endef

# Main targets
.PHONY: all clean help cluster ingress argocd argocd-password argocd-configure tofu-install apply-tofu destroy-tofu status

all: cluster ingress argocd


help:
	@echo "Available targets:"
	@echo "  all              - Set up the complete environment (cluster, ingress, and ArgoCD)"
	@echo "  cluster          - Create a Kind Kubernetes cluster"
	@echo "  ingress          - Install NGINX ingress controller"
	@echo "  argocd           - Install ArgoCD"
	@echo "  argocd-password  - Retrieve the ArgoCD admin password"
	@echo "  tofu-install     - Install OpenTofu"
	@echo "  apply-tofu       - Apply OpenTofu configuration"
	@echo "  destroy-tofu     - Destroy OpenTofu-managed resources"
	@echo "  status           - Check cluster and deployments status"
	@echo "  clean            - Delete the cluster and clean up resources"

cluster:
	systemd-run --scope --user -p "Delegate=yes" kind create cluster --name $(CLUSTER_NAME) --config=$(CLUSTER_CONFIG)

tofu-install:
	curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
	chmod +x install-opentofu.sh
	./install-opentofu.sh --install-method rpm
	rm -f install-opentofu.sh

deploy:
	tofu apply --auto-approve

init:
	tofu init

plan:
	tofu plan
# # Create Kubernetes cluster
# cluster: $(CLUSTER_CONFIG)
# 	$(call info_message,"Creating Kubernetes cluster '$(CLUSTER_NAME)'...")
# 	@if kind get clusters | grep -q "$(CLUSTER_NAME)"; then \
# 		$(call warning_message,"Cluster '$(CLUSTER_NAME)' already exists."); \
# 	else \
# 		systemd-run --scope --user -p "Delegate=yes" kind create cluster --name $(CLUSTER_NAME) --config=$(CLUSTER_CONFIG); \
# 		$(call info_message,"Cluster '$(CLUSTER_NAME)' created successfully!"); \
# 	fi
# 	@kubectl cluster-info --context kind-$(CLUSTER_NAME)

# # Install NGINX ingress controller
# ingress:
# 	$(call info_message,"Installing NGINX Ingress Controller...")
# 	@kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml
# 	$(call countdown,20)
# 	@kubectl wait --namespace ingress-nginx \
# 		--for=condition=ready pod \
# 		--selector=app.kubernetes.io/component=controller \
# 		--timeout=90s
# 	$(call info_message,"NGINX Ingress Controller deployed successfully!")

# # Install ArgoCD
# argocd: argocd-namespace argocd-install argocd-configure argocd-password

# argocd-namespace:
# 	$(call info_message,"Creating ArgoCD namespace...")
# 	@if ! kubectl get namespace $(ARGOCD_NAMESPACE) >/dev/null 2>&1; then \
# 		kubectl create namespace $(ARGOCD_NAMESPACE); \
# 		$(call info_message,"Namespace '$(ARGOCD_NAMESPACE)' created."); \
# 	else \
# 		$(call warning_message,"Namespace '$(ARGOCD_NAMESPACE)' already exists."); \
# 	fi

# argocd-install:
# 	$(call info_message,"Installing ArgoCD...")
# 	@kubectl apply -n $(ARGOCD_NAMESPACE) -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# 	$(call info_message,"Waiting for ArgoCD pods to be ready (this may take a few minutes)...")
# 	@kubectl wait --for=condition=Ready pods --all -n $(ARGOCD_NAMESPACE) --timeout=300s
# 	$(call info_message,"ArgoCD installed successfully!")

# argocd-configure:
# 	$(call info_message,"Configuring ArgoCD server for NodePort access...")
# 	@kubectl patch svc argocd-server -n $(ARGOCD_NAMESPACE) -p '{"spec": {"type": "NodePort", "ports": [{"name": "http", "port": 80, "targetPort": 8080, "nodePort": $(NODE_PORT_HTTP)}, {"name": "https", "port": 443, "targetPort": 8080, "nodePort": $(NODE_PORT_HTTPS)}]}}'
# 	$(call info_message,"ArgoCD server configured with NodePorts $(NODE_PORT_HTTP) (HTTP) and $(NODE_PORT_HTTPS) (HTTPS)")

# argocd-password:
# 	$(call info_message,"Retrieving ArgoCD admin password...")
# 	@kubectl -n $(ARGOCD_NAMESPACE) get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > $(ARGOCD_PASSWORD_FILE)
# 	@chmod 600 $(ARGOCD_PASSWORD_FILE)
# 	$(call info_message,"ArgoCD admin password saved to $(ARGOCD_PASSWORD_FILE)")
# 	@echo "Username: admin"
# 	@echo "Password: $$(cat $(ARGOCD_PASSWORD_FILE))"
# 	$(call info_message,"Access ArgoCD UI at https://localhost:4443 or through NodePort $(NODE_PORT_HTTPS)")

# # OpenTofu installation and management
# tofu-install:
# 	$(call info_message,"Installing OpenTofu v$(TOFU_VERSION)...")
# 	@mkdir -p $(TOFU_DIR)
# 	@curl -Lo $(TOFU_DIR)/tofu.zip https://github.com/opentofu/opentofu/releases/download/v$(TOFU_VERSION)/tofu_$(TOFU_VERSION)_linux_amd64.zip
# 	@unzip -o $(TOFU_DIR)/tofu.zip -d $(TOFU_DIR)
# 	@rm $(TOFU_DIR)/tofu.zip
# 	@chmod +x $(TOFU_DIR)/tofu
# 	@echo 'export PATH=$$PATH:$(TOFU_DIR)' >> ~/.bashrc
# 	$(call info_message,"OpenTofu v$(TOFU_VERSION) installed at $(TOFU_DIR)/tofu")
# 	$(call info_message,"Please run 'source ~/.bashrc' or start a new terminal to use tofu")

# apply-tofu:
# 	$(call info_message,"Initializing and applying OpenTofu configuration...")
# 	@cd terraform && \
# 	tofu init && \
# 	tofu apply

# destroy-tofu:
# 	$(call info_message,"Destroying OpenTofu-managed resources...")
# 	@cd terraform && \
# 	tofu destroy

# # Status check
# status:
# 	$(call info_message,"Checking cluster status...")
# 	@kubectl cluster-info --context kind-$(CLUSTER_NAME)
# 	@echo ""
# 	$(call info_message,"Checking pods across all namespaces...")
# 	@kubectl get pods --all-namespaces
# 	@echo ""
# 	$(call info_message,"Checking ArgoCD deployment...")
# 	@kubectl get all -n $(ARGOCD_NAMESPACE)
# 	@echo ""
# 	$(call info_message,"Checking ingress controller...")
# 	@kubectl get all -n ingress-nginx

# # Clean up
# clean:
# 	$(call warning_message,"Deleting cluster '$(CLUSTER_NAME)'...")
# 	@kind delete cluster --name $(CLUSTER_NAME)
# 	@rm -f $(CLUSTER_CONFIG) $(ARGOCD_PASSWORD_FILE)
# 	$(call info_message,"Cluster and resources deleted successfully!")
