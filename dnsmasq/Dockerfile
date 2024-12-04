FROM alpine:3.20

ARG VERSION="2"

RUN apk add --no-cache dnsmasq-dnssec=~${VERSION}

CMD ["/usr/sbin/dnsmasq", "-k", "--log-facility=-"]
