# Define shell for consistent behavior
SHELL := /bin/bash

-include .env

# ifneq (,$(wildcard ./.env))
#     include .env
#     export $(shell sed 's/=.*//' .env)
# endif

.PHONY:
	clean
	all
	test
	list

.env:
	@echo "ERROR: .env file is required. Copy .env.example to .env and modify as needed."
	@exit 1

local-setup-list: .env
	$(MAKE) -C local-setup list

local-deploy: .env
	$(MAKE) -C local-setup init
	$(MAKE) -C local-setup deploy

local-cleanup: .env
	$(MAKE) -C local-setup clean
