ARG IMAGE_NAME=moechs/openvpn
ARG IMAGE_VERSION=2.7.7-r0

FROM alpine:3.24.4

ARG IMAGE_VERSION

RUN apk add --no-cache bash grep gawk openvpn=~${IMAGE_VERSION}

COPY entrypoint.sh /entrypoint.sh

WORKDIR /etc/openvpn

CMD ["/entrypoint.sh"]
