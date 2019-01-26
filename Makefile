# Docker image Makefile

IMAGE_NAME = server-base
IMAGE_TAGS ?= 0.2
IMAGE_PREFIX ?= niflostancu/
FULL_IMAGE_NAME=$(IMAGE_PREFIX)$(IMAGE_NAME)

-include local.mk

build:
	docker build $(BUILD_ARGS) -t $(FULL_IMAGE_NAME) -f Dockerfile .
	$(foreach TAG,$(IMAGE_TAGS),docker tag $(FULL_IMAGE_NAME) $(FULL_IMAGE_NAME):$(TAG);)

build_force: BUILD_ARGS+= --pull --no-cache
build_force: build

push:
	docker push $(FULL_IMAGE_NAME):latest
	$(foreach TAG,$(IMAGE_TAGS),docker push $(FULL_IMAGE_NAME):$(TAG);)

run:
	docker run -it --rm --name $(IMAGE_NAME)-testinst --hostname=$(IMAGE_NAME) \
		-e "PUID=$$(id -u)" -e PGID=$$(id -g) \
		$(FULL_IMAGE_NAME):latest shell

test:
	@echo "Testing $(FULL_IMAGE_NAME):latest"
	@TEST_IMAGE="$(FULL_IMAGE_NAME):latest" ./test/run_tests.sh

.PHONY: build build_force push test

