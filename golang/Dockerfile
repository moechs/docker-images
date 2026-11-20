ARG IMAGE_NAME=moechs/golang
ARG IMAGE_VERSION=1.27.4

FROM golang:1.27.4-trixie

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        curl \
        dumb-init \
        ca-certificates \
    && groupadd --gid 1000 go \
    && useradd --uid 1000 --gid go --shell /bin/bash --create-home go \
    && mkdir -p /data /app/logs \
    && ln -sf /app/logs /data/logs \
    && chown -R go:go /go /data /app \
    && rm -rf /var/lib/apt/lists/*

USER go
