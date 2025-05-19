# cloud-setup/vpc/Makefile
# Define shell for consistent behavior
SHELL := /bin/bash

# Variables
BACKEND_CONF ?= backend.conf
TFVARS_FILE ?= terraform.tfvars

# Main targets
.PHONY: init plan apply destroy clean validate output

init:
	tofu init -backend-config=$(BACKEND_CONF)

plan:
	tofu plan -var-file=$(TFVARS_FILE) -out=vpc.plan

apply:
	tofu apply vpc.plan

apply-auto:
	tofu apply -var-file=$(TFVARS_FILE) -auto-approve

destroy:
	tofu destroy -var-file=$(TFVARS_FILE)

clean:
	rm -rf .terraform
	rm -f terraform.tfstate*
	rm -f *.plan

validate:
	tofu validate

output:
	@echo "VPC ID: $$(tofu output -raw vpc_id)"
	@echo "Private subnet IDs: $$(tofu output -json private_subnet_ids)"
	@echo "Public subnet IDs: $$(tofu output -json public_subnet_ids)"