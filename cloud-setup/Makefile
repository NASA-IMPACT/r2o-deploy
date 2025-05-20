# Define shell for consistent behavior
SHELL := /bin/bash


# Main targets
.PHONY: init plan apply destroy clean validate output app-only vpc-only list

# Initialize infrastructure
init:
	tofu init

# Plan changes
plan:
	tofu plan -out=cloud-setup.plan


deploy:
	tofu apply --auto-approve

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



# List available commands
list:
	@grep '^[a-zA-Z_-]*:' Makefile | sed 's/:.*//g' | sort
