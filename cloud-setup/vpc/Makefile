# cloud-setup/vpc/Makefile
# Define shell for consistent behavior
SHELL := /bin/bash



# Main targets
.PHONY: init plan apply destroy clean validate output

init:
	tofu init

plan:
	tofu plan -out=vpc.plan



deploy:
	tofu apply --auto-approve

destroy:
	tofu destroy

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
