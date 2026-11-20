ARG IMAGE_NAME=moechs/almalinux-ndppd
ARG IMAGE_VERSION=0.2.5

FROM almalinux:9.9-minimal-20261116

ARG IMAGE_VERSION

RUN microdnf install --nodocs -y --setopt=install_weak_deps=0 epel-release \
    && microdnf install --nodocs -y ndppd-${IMAGE_VERSION} \
    && microdnf remove -y epel-release \
    && microdnf clean all && rm -rf /var/log/*

CMD ["/usr/sbin/ndppd", "-c", "/etc/ndppd.conf"]
