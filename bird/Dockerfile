FROM alpine:3.20

ARG VERSION="2"

RUN apk add --no-cache bird=~${VERSION} \
    && mkdir -p /var/run/bird /etc/bird \
    && mv /etc/bird.conf /etc/bird/

CMD [ "/usr/sbin/bird", "-d", "-c", "/etc/bird/bird.conf" ]
