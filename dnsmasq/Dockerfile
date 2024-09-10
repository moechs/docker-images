FROM alpine:3

ARG DNSMASQ_VERSION="2"

RUN apk add --no-cache dnsmasq-dnssec=~${DNSMASQ_VERSION}

CMD ["/usr/sbin/dnsmasq", "-k", "--log-facility=-"]
