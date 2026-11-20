ARG IMAGE_NAME=moechs/almalinux-nftables
ARG IMAGE_VERSION=1.0.9

FROM almalinux:9.9-minimal-20261116

ARG IMAGE_VERSION

RUN microdnf install --nodocs -y nftables-${IMAGE_VERSION} \
    && microdnf clean all && rm -rf /var/log/* \
    && >/etc/sysconfig/nftables.conf

CMD ["/usr/sbin/nft", "-f", "/etc/sysconfig/nftables.conf"]
