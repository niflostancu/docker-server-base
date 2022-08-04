FROM alpine:3.16

# package versions (prefixes) and arch
ARG S6L_VERSION="v2."
ARG ARCH="amd64"

# environment variables
ENV PS1="$(whoami)@$(hostname):$(pwd)$ " \
	HOME="/root" TERM="xterm" SHELL="/bin/shell" \
	S6_BEHAVIOUR_IF_STAGE2_FAILS=2

ADD install_s6overlay.sh /tmp/

RUN \
	echo "**** installing packages ****" && \
	apk --update upgrade && \
	apk add --no-cache \
		bash coreutils iproute2 shadow tzdata curl ca-certificates tar && \
	apk add --no-cache --virtual .build-dependencies \
		jq && \
	echo "**** adding s6 overlay ****" && \
	/tmp/install_s6overlay.sh "${S6L_VERSION}" && \
	echo "**** cleanup ****" && \
	apk del .build-dependencies && \
	cat /tmp/VERSIONS 1>&2 && \
	rm -rf /tmp/*

# add local files
COPY etc /etc
COPY bin /bin

ENTRYPOINT [ "/bin/entrypoint-cmd" ]

