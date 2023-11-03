SHELL := /bin/bash

APP_NAME=ls_bug_demo
AWS_REGION=us-west-2
ENV=ls_local
STACK=$(APP_NAME).$(ENV)
PULUMI_CONFIG_PASSPHRASE=test
PULUMI_BACKEND_URL=file://
ENDPOINT=http://localhost:4566
AWS_ACCESS_KEY=test
AWS_SECRET_ACCESS_KEY=test
# LOCALSTACK_HOSTNAME=localhost.localstack.cloud

.PHONY: all cleanup get-logs-aws run-test


# ==========
# Usage
# ==============================

# build everything && install dependencies
all: up install-iac-deps build-pulumi run-ui
# tears down everything
cleanup: down reset-iac
# get the localstack logs
get-logs-aws:
	docker logs localstack -f

# run the test -> will come back as pass since we dont check for return but print from within lambda should show up in logs
#run-test:
#	source ./venv/bin/activate; \
#	cd tests; \
#	pytest -s;

# =======
# localstack aws profile
# ============================
# profile localstack config looks like this
#[profile localstack]
#region = us-west-2
#output = json
# ============================
# profile localstack credentials looks like this
#[localstack]
#aws_access_key_id = test
#aws_secret_access_key = test
# ============================

# ========================================================================================================================
# Raw recipes
# ==============================
up:
	docker-compose up -d;
# 	export LOCALSTACK_HOSTNAME=$(LOCALSTACK_HOSTNAME); \

install-iac-deps:
	cd ./iac/ && yarn install;

build-pulumi:
	cd ./iac/; \
	export PULUMI_BACKEND_URL=$(PULUMI_BACKEND_URL); export PULUMI_CONFIG_PASSPHRASE=$(PULUMI_CONFIG_PASSPHRASE); export P_STACK=$(STACK); \
	pulumi stack init $(STACK) || pulumi stack select $(STACK); \
	pulumi config set aws_region $(AWS_REGION); \
	pulumi up -y -s $(STACK); \
	pulumi stack output -s $(STACK) -j > ./../pulumi_output.json;

down:
	docker-compose down -v; \
	docker system prune -f;

reset-iac:
	rm pulumi_output.json || true; \
	rm -rf ls_volume || true; \
	cd ./iac/ && rm -rf .pulumi Pulumi.*.ls_local.yaml node_modules || true;

run-ui:
	cp pulumi_output.json ui/
	cd ui && npm run run-ui