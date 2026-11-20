ARG IMAGE_NAME=moechs/openvpn
ARG IMAGE_VERSION=2.7.7-r0

FROM alpine:3.24.4

ARG VERSION="2"

RUN apk add --no-cache bash grep gawk openvpn=~${VERSION}

COPY entrypoint.sh /entrypoint.sh

WORKDIR /etc/openvpn

CMD ["/entrypoint.sh"]
