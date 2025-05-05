# Define shell for consistent behavior
SHELL := /bin/bash

# Variables
BACKEND_CONF = backend.conf

# Main targets
.PHONY: init plan apply destroy clean validate output app-only vpc-only list

# Initialize infrastructure
init:
	tofu init -backend-config=$(BACKEND_CONF)

# Plan changes
plan:
	tofu plan -out=cloud-setup.plan

# Apply changes
apply:
	tofu apply cloud-setup.plan

# Apply without plan file
apply-auto:
	tofu apply -auto-approve

# Destroy application resources (won't affect VPC)
destroy:
	@echo "Destroying application resources (VPC will NOT be affected)..."
	tofu destroy

# Clean up files
clean:
	rm -rf .terraform
	rm -f terraform.tfstate*
	rm -f *.plan
	rm -f lambda-function/proxy-lambda.zip

# Validate configuration
validate:
	tofu validate

# Output resource details
output:
	tofu output

# VPC-only operations (for reference, these run in the vpc subdirectory)
vpc-init:
	cd vpc && $(MAKE) init

vpc-plan:
	cd vpc && $(MAKE) plan

vpc-apply:
	cd vpc && $(MAKE) apply

# List available commands
list:
	@grep '^[a-zA-Z_-]*:' Makefile | sed 's/:.*//g' | sort