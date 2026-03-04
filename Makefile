# Makefile for FastAPI (Nix build + distroless runtime)

APP_NAME ?= fastapi-nix
IMAGE ?= $(APP_NAME)
PORT ?= 8000
HOST ?= 127.0.0.1
CONTAINER ?= $(APP_NAME)
DOCKERFILE ?= Dockerfile

# Compose autodetect
COMPOSE_FILE :=
ifneq (,$(wildcard compose.yml))
  COMPOSE_FILE := compose.yml
endif
ifneq (,$(wildcard docker-compose.yml))
  COMPOSE_FILE := docker-compose.yml
endif

ifeq ($(strip $(COMPOSE_FILE)),)
  USE_COMPOSE := 0
else
  USE_COMPOSE := 1
endif

.PHONY: help build start stop restart down logs shell status health

help: ## Show available commands
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  %-10s %s\n", $$1, $$2}'
	@echo ""
	@echo "Vars (override like: make start PORT=9000 HOST=0.0.0.0):"
	@echo "  IMAGE=$(IMAGE)"
	@echo "  CONTAINER=$(CONTAINER)"
	@echo "  PORT=$(PORT)"
	@echo "  HOST=$(HOST)"
	@if [ "$(USE_COMPOSE)" = "1" ]; then \
		echo "  COMPOSE_FILE=$(COMPOSE_FILE)"; \
	else \
		echo "  COMPOSE_FILE= (not found; using docker run)"; \
	fi

build: ## Build the Docker image
	docker build -t $(IMAGE) -f $(DOCKERFILE) .

start: build ## Start the service (compose up or docker run)
	@if [ "$(USE_COMPOSE)" = "1" ]; then \
		docker compose -f $(COMPOSE_FILE) up -d --build; \
	else \
		docker rm -f $(CONTAINER) >/dev/null 2>&1 || true; \
		docker run -d --name $(CONTAINER) -p $(HOST):$(PORT):8000 $(IMAGE); \
	fi
	@echo "Running on http://$(HOST):$(PORT)/ (docs: /docs, health: /health)"

stop: ## Stop the service (compose stop or docker stop)
	@if [ "$(USE_COMPOSE)" = "1" ]; then \
		docker compose -f $(COMPOSE_FILE) stop; \
	else \
		docker stop $(CONTAINER) >/dev/null 2>&1 || true; \
	fi

restart: ## Restart the service
	@if [ "$(USE_COMPOSE)" = "1" ]; then \
		docker compose -f $(COMPOSE_FILE) restart; \
	else \
		docker restart $(CONTAINER) >/dev/null 2>&1 || true; \
	fi

down: ## Stop and remove containers (compose down or docker rm)
	@if [ "$(USE_COMPOSE)" = "1" ]; then \
		docker compose -f $(COMPOSE_FILE) down; \
	else \
		docker rm -f $(CONTAINER) >/dev/null 2>&1 || true; \
	fi

status: ## Show container/service status
	@if [ "$(USE_COMPOSE)" = "1" ]; then \
		docker compose -f $(COMPOSE_FILE) ps; \
	else \
		docker ps --filter "name=$(CONTAINER)"; \
	fi

logs: ## Follow logs (compose logs -f or docker logs -f)
	@if [ "$(USE_COMPOSE)" = "1" ]; then \
		docker compose -f $(COMPOSE_FILE) logs -f; \
	else \
		docker logs -f $(CONTAINER); \
	fi

health: ## Call the /health endpoint (requires curl)
	@command -v curl >/dev/null 2>&1 || { echo "curl not found"; exit 1; }
	@curl -fsS "http://$(HOST):$(PORT)/health" || (echo && echo "Health check failed" && exit 1)
	@echo

shell: ## Open a debug shell in a nixos/nix container with your repo mounted (distroless has no shell)
	@echo "Opening debug shell (nixos/nix) with repo mounted at /app..."
	docker run --rm -it -v "$(PWD):/app" -w /app nixos/nix:2.22.1 sh