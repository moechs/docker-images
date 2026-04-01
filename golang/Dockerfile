FROM golang:1.25.7-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        curl \
        dumb-init \
        ca-certificates \
    && groupadd --gid 1000 go \
    && useradd --uid 1000 --gid go --shell /bin/bash --home-dir /go --no-create-home go \
    && mkdir -p /data /app/logs \
    && ln -sf /app/logs /data/logs \
    && chown -R go:go /go /data /app

USER go
