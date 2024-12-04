FROM alpine:3.20

ARG VERSION="2"

RUN apk add --no-cache openvpn=~${VERSION}

COPY entrypoint.sh /entrypoint.sh

WORKDIR /etc/openvpn

CMD ["/entrypoint.sh"]
