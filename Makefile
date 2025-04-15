# Define shell for consistent behavior
SHELL := /bin/bash

.PHONY:
	clean
	all
	test
	list

local-setup-list:
	$(MAKE) -C local-setup list

local-deploy:
	$(MAKE) -C local-setup init
	$(MAKE) -C local-setup deploy

local-cleanup:
	$(MAKE) -C local-setup clean