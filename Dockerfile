FROM alpine:3.8
MAINTAINER Florin Stancu <niflostancu@gmail.com>

# package versions (prefixes) and arch
ARG S6L_VERSION="v1."
ARG CONFD_VERSION="v0.16."
ARG ARCH="amd64"

# environment variables
ENV PS1="$(whoami)@$(hostname):$(pwd)$ " \
	HOME="/root" TERM="xterm"

ADD build_s6overlay.sh build_confd.sh /tmp/

RUN \
	echo "**** installing packages ****" && \
	apk --update upgrade && \
	apk add --no-cache \
		bash coreutils shadow tzdata curl ca-certificates tar && \
	apk add --no-cache --virtual .build-dependencies \
		go git gcc make musl-dev jq && \
	echo "**** adding s6 overlay ****" && \
	/tmp/build_s6overlay.sh "${S6L_VERSION}" && \
	echo "**** building confd ****" && \
	/tmp/build_confd.sh "${CONFD_VERSION}" && \
	echo "**** creating user & folder structure ****" && \
	groupmod -g 1000 users && \
	useradd -u 911 -U -d /config -s /bin/false container && \
	usermod -G users container && \
	mkdir -p /app /config /defaults && \
	echo "**** cleanup ****" && \
	apk del .build-dependencies && \
	cat /tmp/VERSIONS 1>&2 && \
	rm -rf /tmp/*

# add local files
COPY etc /etc

ENTRYPOINT [ "/init" ]

