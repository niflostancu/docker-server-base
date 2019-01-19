# Go apps builder
set -e

# Retrieve the latest version matching the prefix
GOMPLATE_REPO=hairyhenderson/gomplate
GOMPLATE_RELEASES=https://api.github.com/repos/$GOMPLATE_REPO/releases
GOMPLATE_RELEASE=$( \
	curl --silent "$GOMPLATE_RELEASES" | \
	jq -r '[.[].tag_name | select(tostring|startswith("'$GOMPLATE_VERSION'"))]|.[0]')

echo "Gomplate Release: $GOMPLATE_RELEASE" >> /tmp/VERSIONS

# Get the release
REL_NAME="gomplate_linux-${ARCH}-slim"
curl -o /tmp/gomplate.bin -L \
	"https://github.com/$GOMPLATE_REPO/releases/download/$GOMPLATE_RELEASE/$REL_NAME"

# Move to local/bin
mv /tmp/gomplate.bin /usr/local/bin/gomplate
chmod +x /usr/local/bin/gomplate

