FROM alpine/git:v2.52.0

RUN apk add --no-cache bash curl wget sed gawk jq yq tar unzip dumb-init \
    && addgroup -g 1000 git \
    && adduser -s /bin/bash -G git -D -u 1000 git \
    && mkdir -p /data /app/logs \
    && ln -sf /app/logs /data/logs \
    && chown -R git:git /data /app 

WORKDIR /app

USER git
