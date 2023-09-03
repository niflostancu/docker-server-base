#!/bin/bash
set -e

S6L_VER_PREFIX="$1"

# Retrieve the latest version matching the prefix
S6L_REPO=just-containers/s6-overlay
S6L_RELEASES=https://api.github.com/repos/$S6L_REPO/releases
S6L_RELEASE=$( \
	curl --silent "$S6L_RELEASES" | \
	jq -r '[.[].name | select(tostring|startswith("'$S6L_VER_PREFIX'"))]|.[0]')

echo "$S6L_RELEASE"

