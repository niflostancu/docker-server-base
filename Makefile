# Docker image Makefile

IMAGE_NAME = server-base
IMAGE_TAGS ?= alpine3 alpine-3.16
IMAGE_PREFIX ?= niflostancu/
FULL_IMAGE_NAME=$(IMAGE_PREFIX)$(IMAGE_NAME)
BUILD_ARGS=--platform linux/amd64,linux/arm64,linux/arm/v7
PUSH?=

-include local.mk

_full_tag_args = $(foreach tag,latest $(IMAGE_TAGS),-t "$(FULL_IMAGE_NAME):$(tag)")

build:
	docker buildx build $(BUILD_ARGS) $(_full_tag_args) -f Dockerfile \
		$(if $(PUSH),--push,) .

build_force: BUILD_ARGS+= --pull --no-cache
build_force: build

push: PUSH=1
push: build

run:
	docker run -it --rm --name $(IMAGE_NAME)-testinst --hostname=$(IMAGE_NAME) \
		-e "PUID=$$(id -u)" -e PGID=$$(id -g) \
		$(FULL_IMAGE_NAME):latest shell

test:
	@echo "Testing $(FULL_IMAGE_NAME):latest"
	@TEST_IMAGE="$(FULL_IMAGE_NAME):latest" ./test/run_tests.sh

.PHONY: build build_force push test

