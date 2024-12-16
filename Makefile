# Docker image Makefile

# include base makefile script
BASE_DIR ?= .
include $(BASE_DIR)/lib/build.mk

# image variables
ALPINE_VERSION=3.20
S6L_VER_PREFIX = v3
S6L_URL=https://github.com/just-containers/s6-overlay/\#prefix=$(S6L_VER_PREFIX).
S6L_VERSION ?= $(get-s6l-version)

DOCKER_IMAGE_PREFIX ?= niflostancu/

# we have but one image, aliased "image"
build-docker-images = image

image = server-base
image-tags = alpine$(ALPINE_VERSION)-s6l$(S6L_VERSION) alpine-s6l$(S6L_VER_PREFIX) s6l$(S6L_VER_PREFIX) latest
image-build-args = --build-arg="ALPINE_VERSION=$(ALPINE_VERSION)" --build-arg="S6L_VERSION=$(S6L_VERSION)"

# fetch & cache the latest S6 version
get-s6l-version = $(strip $(if $(_s6l-ver-cached),,$(eval _s6l-ver-cached := 1)\
	$(eval _s6l-version := $(shell "$(BASE_DIR)/lib/fetch.sh" --print-version "$(S6L_URL)" | head -1)))$(_s6l-version))

$(eval_all_rules)
# now some extra global rules:

run:
	docker run -it --rm --name $(image)-testinst --hostname=$(image) \
		-e "PUID=$$(id -u)" -e PGID=$$(id -g) \
		$(image-full-name):latest run-shell

test:
	@echo "Testing $(image-full-name)"
	@BASE_IMAGE="$(image-full-name):latest" ./test/run_tests.sh

.PHONY: run test

