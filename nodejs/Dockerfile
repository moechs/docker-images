FROM node:24.14.1

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        curl \
        dumb-init \
        ca-certificates \
    && corepack enable \
    && corepack prepare npm@latest --activate \
    && corepack prepare pnpm@latest --activate \
    && corepack prepare yarn@stable --activate \
    && mkdir -p /data /app/logs \
    && ln -sf /app/logs /data/logs \
    && chown -R node:node /data /app

WORKDIR /app

USER node
