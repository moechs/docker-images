ARG IMAGE_NAME=moechs/dnsmasq
ARG IMAGE_VERSION=2.92_p2-r0

FROM alpine:3.24.4

ARG IMAGE_VERSION

RUN apk add --no-cache dnsmasq-dnssec=~${IMAGE_VERSION}

CMD ["/usr/sbin/dnsmasq", "-k", "--log-facility=-"]
