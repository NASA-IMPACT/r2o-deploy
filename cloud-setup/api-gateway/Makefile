# cloud-setup/api-gateway/Makefile
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
	tofu plan -var-file=$(TFVARS_FILE) -out=api-gateway.plan

apply:
	tofu apply api-gateway.plan

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
	@echo "API Gateway ID: $$(tofu output -raw api_id)"
	@echo "Invoke URL: $$(tofu output -raw invoke_url)"