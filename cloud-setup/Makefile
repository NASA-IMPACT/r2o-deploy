# cloud-setup/Makefile
# Define shell for consistent behavior
SHELL := /bin/bash

# Main targets
.PHONY: vpc-init vpc-plan vpc-apply vpc-destroy app-init app-plan app-apply app-destroy deploy-all destroy-all clean

# VPC targets
vpc-init:
	cd vpc && $(MAKE) init

vpc-plan:
	cd vpc && $(MAKE) plan

vpc-apply:
	cd vpc && $(MAKE) apply

vpc-destroy:
	cd vpc && $(MAKE) destroy

# App targets
app-init:
	cd app && $(MAKE) init

app-plan:
	cd app && $(MAKE) plan

app-apply:
	cd app && $(MAKE) apply

app-destroy:
	cd app && $(MAKE) destroy

# Combined targets
deploy-all: vpc-apply app-apply

destroy-all: app-destroy vpc-destroy

# General targets
clean:
	cd vpc && $(MAKE) clean
	cd app && $(MAKE) clean

list:
	@echo "VPC Commands:"
	@cd vpc && $(MAKE) -s | sed 's/^/  vpc-/'
	@echo "App Commands:"
	@cd app && $(MAKE) -s | sed 's/^/  app-/'
	@echo "Combined Commands:"
	@grep '^deploy\|^destroy\|^clean\|^list:' Makefile | grep -v grep

# Add to cloud-setup/Makefile
check-state-lock:
	@echo "⚠️ WARNING: No state locking is configured. Make sure nobody else is running Terraform commands."
	@echo "Continue? (y/n)"
	@read -r REPLY; \
	if [ "$$REPLY" != "y" ]; then \
		echo "Operation cancelled."; \
		exit 1; \
	fi

vpc-apply: check-state-lock
	cd vpc && $(MAKE) apply

app-apply: check-state-lock
	cd app && $(MAKE) apply