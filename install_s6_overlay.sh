#!/bin/bash
# Builds the S6 Overlay inside the container
set -e

S6L_REPO=just-containers/s6-overlay
S6L_VERSION=${1}
S6L_V2=1; [[ "$S6L_VERSION" =~ ^v2\. ]] || S6L_V2=

# normalize binary arch name
declare -A ARCH_TABLE=(["amd64"]="x86_64" ["arm64"]="aarch64"
	["arm/v7"]="arm" ["arm/v6"]="armhf" ["386"]="i686")
if [[ -n "$S6L_V2" ]]; then
	# yep, they changed conventions
	ARCH_TABLE=(["amd64"]="amd64" ["arm64"]="aarch64"
		["arm/v7"]="arm" ["arm/v6"]="armhf" ["386"]="x86")
fi
ARCH=${TARGETPLATFORM#linux/}
if [[ -v ARCH_TABLE["$ARCH"] ]]; then
	ARCH="${ARCH_TABLE["$ARCH"]}"
fi

AR_EXT=tar.gz
[[ -n "$S6L_V2" ]] || AR_EXT=tar.xz

function download_s6_release() {
	local URL="https://github.com/$S6L_REPO/releases/download/$S6L_VERSION/$1"
	echo "Fetching $URL"
	curl --fail --show-error --silent -o "/tmp/$1" -L "$URL"
	tar -C / -xpf "/tmp/$1"
}

echo "Installing S6L version: $S6L_VERSION (ARCH=$ARCH)"
[[ -n "$S6L_V2" ]] || download_s6_release "s6-overlay-noarch.$AR_EXT"
download_s6_release "s6-overlay-${ARCH}.$AR_EXT"

# migration: ensure v3-compatible paths for common s6 shebang executables
if [[ -n "$S6L_V2" ]]; then
	mkdir -p /command
	for exe in execlineb with-contenv; do
		ln -sf "/usr/bin/$exe" "/command/$exe"
	done
fi

