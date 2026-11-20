ARG IMAGE_NAME=moechs/node
ARG IMAGE_VERSION=26.13.1

FROM node:26.13.1

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        curl \
        dumb-init \
        ca-certificates \
    && npm install --global \
        npm@latest \
        corepack@latest \
    && corepack enable \
    && corepack install --global \
        pnpm@latest \
        yarn@stable \
    && install -d -o node -g node \
        /data \
        /app/logs \
    && ln -s /app/logs /data/logs \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

USER node
