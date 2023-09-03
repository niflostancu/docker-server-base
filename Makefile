# Docker image Makefile

ALPINE_VERSION=3.18
S6L_VER_PREFIX = v3
S6L_VERSION ?= $(get-s6l-version)

V ?=
PUSH ?=
ALL ?= $(PUSH)
LOAD ?= $(if $(ALL),,1)

IMAGE_NAME = server-base
IMAGE_TAGS ?= alpine$(ALPINE_VERSION)-s6l$(S6L_VERSION) alpine-s6l$(S6L_VER_PREFIX) s6l$(S6L_VER_PREFIX) latest
IMAGE_PREFIX ?= niflostancu/

BUILDX_PLATFORMS = linux/amd64,linux/arm64,linux/arm/v7
BUILDX_ARGS ?=
BUILDX_ARGS += --build-arg="ALPINE_VERSION=$(ALPINE_VERSION)" --build-arg="S6L_VERSION=$(S6L_VERSION)"
BUILDX_ARGS += $(if $(ALL),--platform $(BUILDX_PLATFORMS))
BUILDX_ARGS += $(if $(V),--progress=plain)

-include local.mk

# fetches & caches the latest S6 version
get-s6l-version = $(strip $(if $(_s6l-ver-cached),,$(eval _s6l-ver-cached := 1)\
	$(eval _s6l-version := $(shell ./fetch_s6l_version.sh $(S6L_VER_PREFIX). | head -1)))$(_s6l-version))
# tags + image name
_full_image_name = $(IMAGE_PREFIX)$(IMAGE_NAME)
_full_tag_args = $(foreach tag,$(IMAGE_TAGS),-t "$(_full_image_name):$(tag)")

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
		$(_full_image_name):latest run-shell

test:
	@echo "Testing $(_full_image_name)"
	@TEST_IMAGE="$(_full_image_name):$(firstword $(IMAGE_TAGS))" ./test/run_tests.sh

.PHONY: build build_force push test

