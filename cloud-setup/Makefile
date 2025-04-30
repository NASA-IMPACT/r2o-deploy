# cloud-setup/Makefile
# Define shell for consistent behavior
SHELL := /bin/bash

# Variables
BACKEND_CONF ?= lambda-backend.conf
TFVARS_FILE ?= lambda.tfvars

# Main targets
.PHONY: init plan apply destroy clean validate list update-lockfile

init:
	tofu init -backend-config=$(BACKEND_CONF)

# Safely update the lock file when needed
update-lockfile:
	tofu init -backend-config=$(BACKEND_CONF) -upgrade

plan:
	tofu plan -var-file=$(TFVARS_FILE)

apply:
	tofu apply -var-file=$(TFVARS_FILE)

destroy:
	tofu destroy -var-file=$(TFVARS_FILE)

clean:
	rm -rf .terraform
	rm -f terraform.tfstate*
	rm -f lambda-function/proxy-lambda.zip

validate:
	tofu validate

list:
	@grep '^[^#[:space:]].*:' Makefile