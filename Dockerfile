FROM alpine:3.23.3

RUN apk add --no-cache \
    bash \
    curl \
    coreutils \
    gettext \
    tar \
    gzip

WORKDIR /wipi
ENTRYPOINT ["/bin/bash", "./build.sh"]
