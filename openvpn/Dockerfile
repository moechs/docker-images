FROM alpine:3

ARG VERSION="2"

RUN apk add --no-cache openvpn=~${VERSION}

WORKDIR /etc/openvpn

CMD ["/usr/sbin/openvpn", "--suppress-timestamps", "--nobind", "--config", "client.conf"]
