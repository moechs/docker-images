ARG IMAGE_NAME=moechs/bird
ARG IMAGE_VERSION=3.2.4

FROM alpine:3.24.4

ARG IMAGE_VERSION

RUN apk add --no-cache bird=~${IMAGE_VERSION} \
    && mkdir -p /var/run/bird /etc/bird \
    && mv /etc/bird.conf /etc/bird/

CMD [ "/usr/sbin/bird", "-d", "-c", "/etc/bird/bird.conf" ]
