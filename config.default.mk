# Default configuration vars

# To override, check create this file:
# (just in case you want to the config file's location, do it from your Makefiles)
USER_CONFIG_DIR ?= .
-include $(USER_CONFIG_DIR)/config.local.mk

# Docker binary
DOCKER ?= docker

# Default docker image repo prefix
DOCKER_IMAGE_PREFIX ?= niflostancu/

# Default build platforms
DOCKER_BUILD_PLATFORMS ?= linux/amd64,linux/arm64,linux/arm/v7

