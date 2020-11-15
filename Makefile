
.IMAGE=ghcr.io/openfaas/faas-swarm

.GIT_COMMIT=$(shell git rev-parse HEAD)
.GIT_VERSION=$(shell git describe --tags 2>/dev/null || echo "$(.GIT_COMMIT)")
.GIT_UNTRACKEDCHANGES := $(shell git status --porcelain --untracked-files=no)
ifneq ($(.GIT_UNTRACKEDCHANGES),)
	.GIT_COMMIT := $(.GIT_COMMIT)-dirty
endif

TAG?=latest-dev


.PHONY: all
all: build

.PHONY: start-dev
start-dev:
	cd contrib && ./dev.sh

.PHONY: stop-dev
stop-dev:
	docker stack rm func


.PHONY: build
build:
	docker build \
	--build-arg http_proxy="${http_proxy}" \
	--build-arg https_proxy="${https_proxy}" \
	--build-arg GIT_COMMIT="${.GIT_COMMIT}" \
	--build-arg VERSION="${.GIT_VERSION}"  \
	-t ${.IMAGE}:$(TAG) .

.PHONY: build-buildx
build-buildx:
	@docker buildx create --use --name=multiarch --node=multiarch && \
	docker buildx build \
		--output "type=docker,push=false" \
		--platform linux/amd64 \
		--build-arg GIT_COMMIT="${.GIT_COMMIT}" \
		--build-arg VERSION="${.GIT_VERSION}"  \
		--tag ${.IMAGE}:$(TAG) \
		.

.PHONY: build-buildx-all
build-buildx-all:
	@docker buildx create --use --name=multiarch --node=multiarch && \
	docker buildx build \
		--platform linux/amd64,linux/arm/v7,linux/arm64 \
		--output "type=image,push=false" \
		--build-arg GIT_COMMIT="${.GIT_COMMIT}" \
		--build-arg VERSION="${.GIT_VERSION}"  \
		--tag ${.IMAGE}:$(TAG) \
		.

.PHONY: test-unit
test-unit:
	go test -v $(go list ./... | grep -v /vendor/) -cover


.PHONY: push
push:
	docker push ${.IMAGE}:$(TAG)

