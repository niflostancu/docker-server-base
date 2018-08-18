# Go apps builder
set -e

# Retrieve the latest version matching the prefix
ORBIT_REPO=gulien/orbit
ORBIT_VERSION=${1}
ORBIT_RELEASES=https://api.github.com/repos/$ORBIT_REPO/releases
ORBIT_RELEASE=$( \
	curl --silent "$ORBIT_RELEASES" | \
	jq -r '[.[].name | select(tostring|startswith("'$ORBIT_VERSION'"))]|.[0]')

echo "Orbit Release: $ORBIT_RELEASE" >> /tmp/VERSIONS

# Fetch it into a appropriate GOPATH structure
mkdir -p /tmp/go/src/github.com/kelseyhightower
git clone https://github.com/$ORBIT_REPO.git \
	/tmp/go/src/github.com/$ORBIT_REPO
cd /tmp/go/src/github.com/$ORBIT_REPO
git checkout -q --detach "$ORBIT_RELEASE"

# Build & install it
GOPATH=/tmp/go/ CGO_ENABLED=0 go build --ldflags '-X main.version='$ORBIT_RELEASE'-alpine -s -w'
install -c orbit /usr/bin/orbit

rm -rf $HOME/.cache

