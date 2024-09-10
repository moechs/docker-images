FROM alpine:3

ARG BIRD_VERSION="2.15.1"

RUN apk add --no-cache bird=~${BIRD_VERSION} \
    && mkdir -p /var/run/bird /etc/bird \
    && mv /etc/bird.conf /etc/bird/

CMD [ "/usr/sbin/bird", "-d", "-c", "/etc/bird/bird.conf" ]
