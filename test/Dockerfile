ARG SERVER_BASE
FROM ${SERVER_BASE}

ENV CONT_USER=testuser CONT_UID=1970

RUN useradd -m -u $CONT_UID $CONT_USER

ADD test-files/s6-rc.d/ /etc/s6-overlay/s6-rc.d/
ADD test-files/legacy/ /etc/services.d/legacy/

