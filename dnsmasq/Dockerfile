FROM alpine:3.22

ARG VERSION="2"

RUN apk add --no-cache dnsmasq-dnssec=~${VERSION}

CMD ["/usr/sbin/dnsmasq", "-k", "--log-facility=-"]
