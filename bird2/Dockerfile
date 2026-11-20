ARG IMAGE_NAME=moechs/bird
ARG IMAGE_VERSION=2.19.3

FROM alpine:3.24.4

ARG IMAGE_VERSION

RUN apk add --no-cache bird2=~${IMAGE_VERSION} \
    && mkdir -p /var/run/bird /etc/bird \
    && mv /etc/bird.conf /etc/bird/

CMD [ "/usr/sbin/bird", "-d", "-c", "/etc/bird/bird.conf" ]
