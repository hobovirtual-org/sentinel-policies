SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help

# Use the pinned CLI from `make tools` when present, otherwise the one on PATH.
SENTINEL := $(or $(abspath $(wildcard .tools/bin/sentinel)),sentinel)

# A policy set is any folder under terraform/ that has a sentinel.hcl.
SETS := $(patsubst %/sentinel.hcl,%,$(wildcard terraform/*/sentinel.hcl))

.PHONY: help tools fmt test gen ci new-policy

help: ## Show available targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-11s %s\n", $$1, $$2}'

tools: ## Install the pinned Sentinel CLI (checksum + GPG verified)
	@scripts/install-sentinel.sh

fmt: ## Check formatting of every .sentinel file in every policy set
	@for set in $(SETS); do \
		for f in "$$set"/*.sentinel; do $(SENTINEL) fmt -check "$$f"; done; \
	done

gen: ## Regenerate mocks and test cases from scripts/gen-test-data.py
	@python3 scripts/gen-test-data.py

test: ## Run sentinel test in every policy set
	@for set in $(SETS); do \
		echo "== $$set"; \
		(cd "$$set" && $(SENTINEL) test); \
	done

ci: fmt test ## Everything CI runs, in order

new-policy: ## Scaffold a policy set: make new-policy NAME=my-policy
	@scripts/new-policy.sh "$(NAME)"
