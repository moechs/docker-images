FROM almalinux:9.4

RUN dnf --allowerasing -y install nftables \
    && dnf clean all && rm -rf /var/log/* \
    && >/etc/sysconfig/nftables.conf

CMD ["/usr/sbin/nft", "-f", "/etc/sysconfig/nftables.conf"]
