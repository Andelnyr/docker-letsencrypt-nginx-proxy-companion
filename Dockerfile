FROM golang:1.13-alpine AS go-builder

ENV DOCKER_GEN_VERSION=0.7.4

# Build docker-gen
RUN apk add --no-cache --virtual .build-deps \
        curl \
        gcc \
        git \
        make \
        musl-dev \
    && go get github.com/jwilder/docker-gen \
    && cd /go/src/github.com/jwilder/docker-gen \
    && git checkout $DOCKER_GEN_VERSION \
    && make get-deps \
    && make all \
    && go clean -cache \
    && mv docker-gen /usr/local/bin/ \
    && rm -rf /go/src \
    && apk del .build-deps

FROM alpine:3.10

LABEL maintainer="Yves Blusseau <90z7oey02@sneakemail.com> (@blusseau)"

ENV DEBUG=false \
    DOCKER_HOST=unix:///var/run/docker.sock

# Install packages required by the image
RUN apk add --no-cache --virtual .bin-deps \
        bash \
        ca-certificates \
        coreutils \
        curl \
        jq \
        openssl

# Install docker-gen from build stage
COPY --from=go-builder /usr/local/bin/docker-gen /usr/local/bin/

# Install simp_le
COPY /install_simp_le.sh /app/install_simp_le.sh
RUN chmod +rx /app/install_simp_le.sh \
    && sync \
    && /app/install_simp_le.sh \
    && rm -f /app/install_simp_le.sh

COPY /app/ /app/

WORKDIR /app

ENTRYPOINT [ "/bin/bash", "/app/entrypoint.sh" ]
CMD [ "/bin/bash", "/app/start.sh" ]
