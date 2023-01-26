# ==============================================================================
# VARIABLES
DOCKER_UID           = $(shell id -u)
DOCKER_GID           = $(shell id -g)
DOCKER_USER          = $(DOCKER_UID):$(DOCKER_GID)
COMPOSE              = DOCKER_USER=$(DOCKER_USER) docker compose -f docker-compose.yml -f docker-compose-superset.yml
COMPOSE_RUN          = $(COMPOSE) run --rm

# -- Node
COMPOSE_RUN_NODE     = $(COMPOSE_RUN) node
YARN                 = $(COMPOSE_RUN_NODE) yarn

# -- Utils
WAIT_DB              = $(COMPOSE_RUN) dockerize -wait tcp://postgresql:5432 -timeout 60s
WAIT_GRAFANA         = $(COMPOSE_RUN) dockerize -wait http://grafana:3000 -timeout 60s
WAIT_ES              = $(COMPOSE_RUN) dockerize -wait http://elasticsearch:9200 -timeout 60s
WAIT_MYSQL           = $(COMPOSE_RUN) dockerize -wait tcp://edx_mysql:3306 -timeout 60s

# -- Targets
sources := $(shell find src -type f -name '*.jsonnet')
libraries := $(shell find src -type f -name '*.libsonnet')
plugins := $(shell find src/plugins/packages -maxdepth 1 -mindepth 1 -type d)
targets := $(patsubst src/%.jsonnet,var/lib/grafana/%.json,$(sources))
plugins-dist := $(patsubst src/plugins/packages/%,var/lib/grafana/plugins/%,$(plugins))

default: help

# ==============================================================================
# FILES
var/lib/grafana:
	mkdir -p var/lib/grafana

var/lib/grafana/%.json: src/%.jsonnet
	mkdir -p $(shell dirname $@)
	bin/jsonnet -o /$@ $<

var/lib/grafana/plugins/%: src/plugins/packages/%
	mkdir -p $@
	cp -R $</dist/* $@

tree: \
	var/lib/grafana
.PHONY: tree

# RULES
bootstrap: \
	tree \
	dependencies \
	plugins \
	build \
	compile \
	fixtures \
	hooks \
	init-superset
bootstrap: ## bootstrap the application
.PHONY: bootstrap

build: ## build potsie development image
	@$(COMPOSE) build app
.PHONY: build

clean: \
	down
clean: ## remove project files and containers (warning: it removes the database container)
	rm -rf ./var src/plugins/node_modules src/plugins/packages/*/node_modules src/plugins/packages/*/dist
.PHONY: clean

compile: \
	tree \
	$(targets)
compile: ## compile jsonnet sources to json
.PHONY: compile

dependencies: ## install project dependencies (plugins)
	@$(YARN) install
.PHONY: dependencies

down: ## remove stack (warning: it removes the database container)
	@$(COMPOSE) down || echo WARNING: unable to remove the stack. Try to stop linked containers or networks first.
.PHONY: down

fixtures: \
    run
fixtures: ## Load test data (for development)
	@echo "Wait for databases to be up..."
	@$(WAIT_ES)
	@$(WAIT_MYSQL)
	zcat ./fixtures/elasticsearch/lrs.json.gz | \
	  $(COMPOSE_RUN) patch_statements_date | \
	  $(COMPOSE_RUN) -T ralph push -b es && \
	  $(COMPOSE_RUN) users-permissions sh /scripts/users-permissions.sh
.PHONY: fixtures

format: ## format Jsonnet sources and libraries
	bin/jsonnetfmt -i $(sources) $(libraries)
.PHONY: format

hooks: ## run post-deployment hooks
	@$(COMPOSE_RUN) hooks ./post-deploy
.PHONY: hooks

init-superset: ## initialize superset
	@$(COMPOSE) run superset-init
.PHONY: init-superset

lint: ## lint Jsonnet sources and libraries
	bin/jsonnet-lint $(sources) $(libraries)
.PHONY: lint

logs: ## display grafana logs (follow mode)
	@$(COMPOSE) logs -f grafana
.PHONY: logs

logs-superset: ## display superset logs (follow mode)
	@$(COMPOSE) logs -f superset
.PHONY: logs-superset

plugins: ## download, build and install plugins
	@$(YARN) build
.PHONY: plugins

plugins-dist: \
	tree \
  $(plugins-dist)
plugins-dist: ## copy compiled plugins in the distribution tree
.PHONY: plugins-dist

restart: ## restart grafana
	@$(COMPOSE) restart grafana
.PHONY: restart

run: \
	tree
run: ## start the development server
	@$(COMPOSE) up -d postgresql
	@echo "Wait for database to be up..."
	@$(WAIT_DB)
	@$(COMPOSE) up -d grafana
	@echo "Wait for grafana to be up..."
	@$(WAIT_GRAFANA)
.PHONY: run

run-superset: \
	run
run-superset: ## start superset server
	@$(COMPOSE) up -d superset superset-worker superset-worker-beat
.PHONY: run-superset

status: ## an alias for "docker-compose ps"
	@$(COMPOSE) ps
.PHONY: status

stop: ## stop the development server
	@$(COMPOSE) stop
.PHONY: stop

update: ## update jsonnet bundles
	@$(COMPOSE_RUN) jb update
	$(MAKE) build
.PHONY: update

# This rule requires to install the inotify-tools dependency (Linux Only)
# https://github.com/inotify-tools/inotify-tools/wiki
watch: ## automatically compiles sources when changed
	bin/watch src "$(MAKE) -B compile"
.PHONY: watch

# ==============================================================================
help:
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
.PHONY: help
