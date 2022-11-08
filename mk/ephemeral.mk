
# .PHONY: ephemeral-setup
# ephemeral-setup: ## Configure bonfire to run locally
# 	bonfire config write-default > $(PROJECT_DIR)/config/bonfire-config.yaml

APP ?= $(APP_NAME)
NAMESPACE ?= $(shell oc project -q 2>/dev/null)
# POOL could be:
#   default
#   minimal
#   managed-kafka
#   real-managed-kafka
POOL ?= default
export NAMESPACE
export APP
export POOL


# https://consoledot.pages.redhat.com/docs/dev/getting-started/ephemeral/onboarding.html
.PHONY: ephemeral-login
ephemeral-login: .old-ephemeral-login ## Help in login to the ephemeral cluster
	@#if [ "$(GH_SESSION_COOKIE)" != "" ]; then python3 $(GO_OUTPUT)/get-token.py; else $(MAKE) .old-ephemeral-login; fi

.PHONY: .old-ephemeral-login
.old-ephemeral-login:
	xdg-open "https://oauth-openshift.apps.c-rh-c-eph.8p0c.p1.openshiftapps.com/oauth/token/request"
	@echo "- Login with github"
	@echo "- Do click on 'Display Token'"
	@echo "- Copy 'Log in with this token' command"
	@echo "- Paste the command in your terminal"
	@echo ""
	@echo "Now you should have access to the cluster, remember to use bonfire to manage namespace lifecycle:"
	@echo '# make ephemeral-namespace-reserve'
	@echo ""
	@echo "Check the namespaces reserved to you by:"
	@echo '# make ephemeral-namespace-list'
	@echo ""
	@echo "If you need to extend 1hour the time for the namespace reservation"
	@echo '# make ephemeral-namespace-extend-1h'
	@echo ""
	@echo "Finally if you don't need the reserved namespace or just you want to cleanup and restart with a fresh namespace you run:"
	@echo '# make ephemeral-namespace-release-all'

# Download https://gitlab.cee.redhat.com/klape/get-token/-/blob/main/get-token.py
$(GO_OUTPUT/get-token.py):
	curl -Ls -o "$(GO_OUTPUT/get-token.py)" "https://gitlab.cee.redhat.com/klape/get-token/-/raw/main/get-token.py"

# Changes to config/bonfire-local.yaml could impact to this rule
.PHONY: ephemeral-deploy
ephemeral-deploy: EPHEMERAL_OPTS ?= --no-single-replicas
ephemeral-deploy:  ## Deploy application using 'config/bonfire-local.yaml' file
	# Building container images
	[ "$(EPHEMERAL_NO_BUILD)" == "y" ] || $(MAKE) docker-build docker-push APP_COMPONENT="appservice" DOCKER_DOCKERFILE=Containerfile DOCKER_CONTEXT_DIR="$(PROJECT_DIR)/external/console.dot/appservice"
	[ "$(EPHEMERAL_NO_BUILD)" == "y" ] || $(MAKE) docker-build docker-push APP_COMPONENT="bridge" DOCKER_DOCKERFILE=Containerfile DOCKER_CONTEXT_DIR="$(PROJECT_DIR)/external/console.dot/server"
	# Deploying resources in $(NAMESPACE)
	source .venv/bin/activate && \
	bonfire deploy \
	    --source local \
		--local-config-path configs/bonfire-local.yaml \
		--secrets-dir "$(PROJECT_DIR)/secrets" \
		--import-secrets \
		--namespace "$(NAMESPACE)" \
		--set-parameter "$(APP_COMPONENT)/IMAGE=$(DOCKER_IMAGE_BASE)" \
		--set-parameter "$(APP_COMPONENT)/IMAGE_TAG=$(DOCKER_IMAGE_TAG)" \
		$(EPHEMERAL_OPTS) \
		$(APP)

.PHONY: ephemeral-undeploy
ephemeral-undeploy: EPHEMERAL_OPTS ?= --no-single-replicas
ephemeral-undeploy: ## Undeploy application from the current namespace
	source .venv/bin/activate && \
	bonfire process \
	    --source local \
		--local-config-path configs/bonfire-local.yaml \
		--namespace "$(NAMESPACE)" \
		--set-parameter "$(APP_COMPONENT)/IMAGE=$(DOCKER_IMAGE_BASE)" \
		--set-parameter "$(APP_COMPONENT)/IMAGE_TAG=$(DOCKER_IMAGE_TAG)" \
		$(EPHEMERAL_OPTS) \
		$(APP) 2>/dev/null | json2yaml | oc delete -f -
	! oc get secrets/content-sources-certs &>/dev/null || oc delete secrets/content-sources-certs

.PHONY: ephemeral-process
ephemeral-process: EPHEMERAL_OPTS ?= --no-single-replicas
ephemeral-process: ## Process application from the current namespace
	source .venv/bin/activate && \
	bonfire process \
	    --source local \
		--local-config-path configs/bonfire-local.yaml \
		--namespace "$(NAMESPACE)" \
		--set-parameter "$(APP_COMPONENT)/IMAGE=$(DOCKER_IMAGE_BASE)" \
		--set-parameter "$(APP_COMPONENT)/IMAGE_TAG=$(DOCKER_IMAGE_TAG)" \
		$(EPHEMERAL_OPTS) \
		$(APP) 2>/dev/null | json2yaml

# TODO Add command to specify to bonfire the clowdenv template to be used
.PHONY: ephemeral-namespace-reserve
ephemeral-namespace-reserve:  ## Reserve a namespace (requires ephemeral environment)
	@command -v bonfire 1>/dev/null 2>/dev/null || { echo "error:bonfire is not available in this environment"; exit 1; }
	oc project "$(shell bonfire namespace reserve --pool "$(POOL)" 2>/dev/null)"

.PHONY: ephemeral-namespace-release-all
ephemeral-namespace-release-all: ## Release all namespace reserved by us (requires ephemeral environment)
	source .venv/bin/activate && \
	for item in $$( bonfire namespace list --mine --output json | jq -r '. | to_entries | map(select(.key | match("ephemeral-*";"i"))) | map(.key) | .[]' ); do \
	  bonfire namespace release --force $$item ; \
	done

.PHONY: ephemeral-namespace-list
ephemeral-namespace-list: ## List all the namespaces reserved to the current user (requires ephemeral environment)
	source .venv/bin/activate && \
	bonfire namespace list --mine

.PHONY: ephemeral-namespace-extend-1h
ephemeral-namespace-extend-1h: ## Extend for 1 hour the usage of the current ephemeral environment
	source .venv/bin/activate && \
	bonfire namespace extend --duration 1h "$(NAMESPACE)"

.PHONY: ephemeral-namespace-describe
ephemeral-namespace-describe:  ## Describe the namespace
	@source .venv/bin/activate && \
	bonfire namespace describe "$(NAMESPACE)"

# DOCKER_IMAGE_BASE should be a public image
# Tested by 'make ephemeral-build-deploy DOCKER_IMAGE_BASE=quay.io/avisied0/content-sources-backend'
.PHONY: ephemeral-run-build-deploy
ephemeral-run-build-deploy:  ## Run script 'build_deploy.sh'; It requires to pass DOCKER_IMAGE_BASE and DOCKER_IMAGE_TAG
	IMAGE="$(DOCKER_IMAGE_BASE)" IMAGE_TAG="$(DOCKER_IMAGE_TAG)" ./build_deploy.sh

.PHONY: ephemeral-run-pr-check
ephemeral-run-pr-check:  ## Run script pr_check.sh
	IMAGE="$(DOCKER_IMAGE_BASE)" bash ./pr_check.sh
