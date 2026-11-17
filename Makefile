SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help

# Use the pinned CLI from `make tools` when present, otherwise the one on PATH.
SENTINEL := $(or $(wildcard .tools/bin/sentinel),sentinel)

.PHONY: help tools fmt test gen ci

help: ## Show available targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-8s %s\n", $$1, $$2}'

tools: ## Install the pinned Sentinel CLI (checksum + GPG verified)
	@scripts/install-sentinel.sh

fmt: ## Check formatting of every .sentinel file
	@for f in *.sentinel; do $(SENTINEL) fmt -check "$$f"; done

gen: ## Regenerate mocks and test cases from scripts/gen-test-data.py
	@python3 scripts/gen-test-data.py

test: ## sentinel test
	@$(SENTINEL) test

ci: fmt test ## Everything CI runs, in order
