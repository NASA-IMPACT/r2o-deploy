# Define shell for consistent behavior
SHELL := /bin/bash

-include .env
export

.PHONY:
	clean
	all
	test
	list
	generate_terraform_variables
	check_create_remote_state

.env:
	@echo "ERROR: .env file is required. Copy .env.example to .env and modify as needed."
	@exit 1

local-setup-list: .env
	$(MAKE) -C local-setup list

create-state: .env
	@source ./deploy.sh && \
	cd local-setup && \
	generate_terraform_variables && \
	check_create_remote_state ${AWS_REGION} ${LOCAL_DEPLOY_STATE_BUCKET_NAME} ${LOCAL_DEPLOY_STATE_DYNAMO_TABLE}

local-deploy: .env create-state
	$(MAKE) -C local-setup init
	$(MAKE) -C local-setup deploy

local-cleanup: .env create-state
	$(MAKE) -C local-setup clean

test-env: .env
	$(MAKE) -C local-setup test-env

