ARG ALPINE_VERSION
FROM alpine:${ALPINE_VERSION}

# package versions and arch
ARG S6L_VERSION="v3.???"
ARG TARGETPLATFORM

# environment variables
ENV PS1="$(whoami)@$(hostname):$(pwd)$ " \
	HOME="/root" TERM="xterm" SHELL="/usr/local/bin/run-shell" \
	S6_CMD_WAIT_FOR_SERVICES_MAXTIME=30000 \
	S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
	PATH="/command:/usr/local/bin:$PATH" \
	CONT_USER="container" CONT_UID="911" CONT_GID=

ADD --chmod=755 install_s6_overlay.sh /tmp/

RUN \
	echo "**** installing packages ****" && \
	apk --update upgrade && \
	apk add --no-cache \
		bash coreutils iproute2 shadow tzdata curl ca-certificates tar xz && \
	echo "**** adding s6 overlay ****" && \
	/tmp/install_s6_overlay.sh "${S6L_VERSION}" && \
	echo "**** cleanup ****" && \
	rm -rf /tmp/*

# add local files
COPY etc /etc
COPY bin /usr/local/bin

ENTRYPOINT ["/usr/local/bin/ext-entry"]

