ARG IMAGE_NAME=moechs/dnsmasq
ARG IMAGE_VERSION=2.92_p2-r0

FROM alpine:3.24.4

ARG VERSION="2"

RUN apk add --no-cache dnsmasq-dnssec=~${VERSION}

CMD ["/usr/sbin/dnsmasq", "-k", "--log-facility=-"]
