# Docker image Makefile

VERSION=3.18
PUSH?=
ALL?=$(PUSH)
LOAD?=$(if $(ALL),,1)

IMAGE_NAME = server-base
IMAGE_TAGS ?= alpine3 alpine-$(VERSION)
IMAGE_PREFIX ?= niflostancu/
FULL_IMAGE_NAME=$(IMAGE_PREFIX)$(IMAGE_NAME)

PLATFORMS=linux/amd64,linux/arm64,linux/arm/v7
BUILDX_ARGS?=
BUILDX_ARGS+=$(if $(ALL),--platform $(PLATFORMS))

-include local.mk

_full_tag_args = $(foreach tag,latest $(IMAGE_TAGS),-t "$(FULL_IMAGE_NAME):$(tag)")

build:
	docker buildx build $(BUILDX_ARGS) $(_full_tag_args) -f Dockerfile \
		$(if $(PUSH),--push,$(if $(LOAD),--load)) .

build_force: BUILDX_ARGS+= --pull --no-cache
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

