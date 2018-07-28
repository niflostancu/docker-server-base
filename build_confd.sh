# Custom confd version build script
set -e

# Retrieve the latest version matching the prefix
CONFD_REPO=kelseyhightower/confd
CONFD_VERSION=${1}
CONFD_RELEASES=https://api.github.com/repos/$CONFD_REPO/releases
CONFD_RELEASE=$( \
	curl --silent "$CONFD_RELEASES" | \
	jq -r '[.[].name | select(tostring|startswith("'$CONFD_VERSION'"))]|.[0]')

echo "Confd Release: $CONFD_RELEASE" >> /tmp/VERSIONS

# Fetch it into a appropriate GOPATH structure
mkdir -p /tmp/confd/src/github.com/kelseyhightower
git clone https://github.com/$CONFD_REPO.git \
	/tmp/confd/src/github.com/$CONFD_REPO
cd /tmp/confd/src/github.com/$CONFD_REPO
git checkout -q --detach "$CONFD_RELEASE"

# Build & install it
GOPATH=/tmp/confd/ CGO_ENABLED=0 go build --ldflags '-s -w -X main.GitSHA=${GIT_SHA}'
install -c confd /usr/bin/confd

rm -rf $HOME/.cache

