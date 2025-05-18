# Define shell for consistent behavior
SHELL := /bin/bash

# Main targets
.PHONY: tofu-install deploy init plan list

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


list:
	@grep '^[^#[:space:]].*:' Makefile

clean: init
	tofu destroy --auto-approve
	#kind delete cluster --name ${TF_VAR_cluster_name}
	@rm -rf .terraform
	@rm -rf .terraform.lock.hcl
	@rm terraform.tfstate*

test-env:
	echo ${PROJECT}
