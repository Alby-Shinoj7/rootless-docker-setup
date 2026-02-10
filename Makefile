SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin

.PHONY: help install uninstall check lint smoke-test

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*## "; printf "Usage: make <target>\n\nTargets:\n"} /^[a-zA-Z0-9_.-]+:.*## / {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install wrapper scripts to user prefix
	PREFIX="$(PREFIX)" BINDIR="$(BINDIR)" ./scripts/install.sh

uninstall: ## Uninstall wrapper scripts from user prefix
	PREFIX="$(PREFIX)" BINDIR="$(BINDIR)" ./scripts/uninstall.sh

check: ## Syntax check core scripts
	bash -n dockerd-rootless-setuptool.sh
	bash -n dockerd-rootless.sh
	bash -n scripts/install.sh
	bash -n scripts/uninstall.sh
	bash -n test/smoke-check.sh

lint: ## Run shellcheck (local if available, container fallback)
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck dockerd-rootless-setuptool.sh dockerd-rootless.sh scripts/*.sh test/*.sh; \
	elif command -v docker >/dev/null 2>&1; then \
		docker run --rm -v "$$(pwd):/mnt" -w /mnt koalaman/shellcheck:stable \
			dockerd-rootless-setuptool.sh dockerd-rootless.sh scripts/*.sh test/*.sh; \
	else \
		echo "shellcheck not found and docker unavailable; skipping lint"; \
		exit 0; \
	fi

smoke-test: ## Run non-root smoke test for check command behavior
	./test/smoke-check.sh
