# Builds the S6 Overlay inside the container
set -e

# Retrieve the latest version matching the prefix
S6L_REPO=just-containers/s6-overlay
S6L_VERSION=${1}
S6L_RELEASES=https://api.github.com/repos/$S6L_REPO/releases
S6L_RELEASE=$( \
	curl --silent "$S6L_RELEASES" | \
	jq -r '[.[].name | select(tostring|startswith("'$S6L_VERSION'"))]|.[0]')

echo "S6_Overlay Release: $S6L_RELEASE" >> /tmp/VERSIONS

# Get the release
ARCH=${TARGETPLATFORM#linux/}
if [[ "$ARCH" == *"arm/v7"* || "$ARCH" == *"arm32"* ]]; then
	ARCH=armhf
elif [[ "$ARCH" == *"arm64"* ]]; then
	ARCH=aarch64
fi

REL_NAME="s6-overlay-${ARCH}.tar.gz"
URL="https://github.com/$S6L_REPO/releases/download/$S6L_RELEASE/$REL_NAME"
echo "Fetching $URL"
curl --fail --show-error --silent -o /tmp/s6-overlay.tar.gz -L "$URL"
	

# Untar it to the rootfs
tar xfz /tmp/s6-overlay.tar.gz -C /

