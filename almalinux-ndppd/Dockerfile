FROM almalinux:9.9-minimal-20261116

RUN microdnf install --nodocs -y --setopt=install_weak_deps=0 epel-release \
    && microdnf install --nodocs -y ndppd \
    && microdnf remove -y epel-release \
    && microdnf clean all && rm -rf /var/log/*

CMD ["/usr/sbin/ndppd", "-c", "/etc/ndppd.conf"]
