# Docker image Makefile library

# prerequisites
include $(BASE_DIR)/lib/utils.mk
# load default configuration file
include config.default.mk

# clean build
MAKEFLAGS += --no-builtin-rules
.SUFFIXES:

## Global environment vars

DOCKER ?= docker
# Set to 1 to push the image to the container repository
PUSH ?=
# Set to 1 to build for all platforms
ALL ?= $(PUSH)
# Set to 1 to load the image back into Docker for local usage
LOAD ?= $(if $(ALL),,1)
# Whether to force build (always pull & no cache)
FORCE ?= 
# Verbose (enables all debugging flags)
V ?=

# Per-image variables and their defaults
-docker-image-prefix = $(call _def_value,$(_image)-prefix,$(DOCKER_IMAGE_PREFIX))
-docker-image-name = $(call _def_value,$(_image),$(_image))
-docker-image-name-full = $(-docker-image-prefix)$(-docker-image-name)
-docker-image-deps = $($(_image)-deps)
-docker-src-dir = $(call _def_value,$(_image)-src,.)
-docker-src-file = $(call _def_value,$(_image)-dockerfile,$(-docker-src-dir)/Dockerfile)
-docker-build-platforms = $(call _def_value,$(_image)-build-platforms,$(DOCKER_BUILD_PLATFORMS))
-docker-build-tags = $(call _def_value,$(_image)-tags,latest)
-docker-build-tag-full = $(foreach tag,$(-docker-build-tags),-t "$(-docker-image-name-full):$(tag)")
-docker-build-extra-args = $($(_image)-build-args)
-docker-build-args = $$(DOCKER_BUILD_ARGS) \
			$(if $(ALL),--platform $(-docker-build-platforms)) \
			$(if $(V),--progress=plain) \
			$(if $(PUSH),--push,$(if $(LOAD),--load)) \
			$(-docker-build-tag-full) $(-docker-build-extra-args) \
			-f $(-docker-src-file) "$(-docker-src-dir)"

-docker-extra-rules = $($(_image)-extra-rules)

# Docker buildx command macro
define docker_buildx_cmd
cd "$(-docker-src-dir)" && $(DOCKER) buildx build $(-docker-build-args)
endef

# Main per-image rules macro
define docker_image_gen_rules
# Docker build rules for $(_image)
$(_image)-full-name := $(-docker-image-name-full)
.PHONY: $(_image) $(_image)_force $(_image)_push $(_image)_clean
$(_image): $(-docker-image-deps)
	$(docker_buildx_cmd)
$(_image)_force:
	$(let FORCE,1,$(docker_buildx_cmd))
$(_image)_push:
	$(let ALL,1,$(let PUSH,1,$(docker_buildx_cmd)))
#@ $(_image) clean (rm) rule
$(_image)_clean:
	CONTAINERS=$$$$(docker container ls -q --filter "ancestor=$(-docker-image-name-full):*"); \
	IMAGES=$$$$(docker image ls -q --filter "reference=$(-docker-image-name-full):*" | uniq); \
	[ -z "$$$$CONTAINERS" ] || docker container rm -f $$$$CONTAINERS; \
	[ -z "$$$$IMAGES" ] || docker image rm -f $$$$IMAGES;

endef

# Default (top-level) rules
DEFAULT_GOAL ?= $(build-docker-images)
define gen_default_rules
.PHONY: _ build push clean
_: $(DEFAULT_GOAL)
push: $(foreach _image,$(build-docker-images),$(_image)_push)
clean: $(foreach _image,$(build-docker-images),$(_image)_clean)

endef

# Makefile debugging helper rules
define gen_debug_rules
# debug helpers
.PHONY: @debug @debug-make @debug-rules
@debug: @debug-rules
@debug-rules:
	$$(info $$(gen_docker_rules))
	@echo
@debug-make: @debug-rules
	@$(MAKE) -r -p
@print-% : ; @echo $$* = $$($$*)

endef

# Rule evaluation macros
gen_docker_rules = $(foreach _image,$(build-docker-images),$(nl)$(docker_image_gen_rules))
eval_docker_rules = $(foreach _image,$(build-docker-images),$(eval $(nl)$(docker_image_gen_rules)))

eval_all_rules = $(eval $(gen_default_rules)) $(eval_docker_rules) $(eval $(gen_debug_rules))

