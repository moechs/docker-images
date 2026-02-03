FROM almalinux:9.7-minimal-20260129

RUN microdnf install --nodocs -y nftables \
    && microdnf clean all && rm -rf /var/log/* \
    && >/etc/sysconfig/nftables.conf

CMD ["/usr/sbin/nft", "-f", "/etc/sysconfig/nftables.conf"]
