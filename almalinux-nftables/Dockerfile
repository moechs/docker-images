FROM almalinux:9.6-minimal

RUN microdnf install --nodocs -y nftables \
    && microdnf clean all && rm -rf /var/log/* \
    && >/etc/sysconfig/nftables.conf

CMD ["/usr/sbin/nft", "-f", "/etc/sysconfig/nftables.conf"]
