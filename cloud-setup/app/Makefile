# cloud-setup/app/Makefile
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
	tofu plan -var-file=$(TFVARS_FILE) -out=app.plan

apply:
	tofu apply app.plan

apply-auto:
	tofu apply -var-file=$(TFVARS_FILE) -auto-approve

destroy:
	tofu destroy -var-file=$(TFVARS_FILE)

clean:
	rm -rf .terraform
	rm -f terraform.tfstate*
	rm -f *.plan
	rm -f ../lambda-function/proxy-lambda.zip

validate:
	tofu validate

output:
	@echo "Lambda Function Name: $$(tofu output -raw lambda_function_name)"
	@echo "Lambda Function ARN: $$(tofu output -raw lambda_function_arn)"