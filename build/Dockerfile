FROM alpine:3.23.3

RUN echo "https://dl-cdn.alpinelinux.org/alpine/v3.23/community" \
        >> /etc/apk/repositories \
    && apk add --no-cache \
        bash \
        curl \
        coreutils \
        gettext \
        shellcheck \
        yamllint \
        tar \
        gzip

WORKDIR /wipi
CMD ["/bin/bash", "./build/build.sh"]
