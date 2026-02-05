FROM almalinux:9.7-20260129

ENV LANG=en_US.UTF-8 \
    TZ=Asia/Shanghai \
    PS1='\u@\h:\w$ ' \
    APP_DIR=/app

RUN microdnf install -y epel-release \
    && rpm -e curl-minimal libcurl-minimal --nodeps \
    && microdnf install --nodocs -y bash curl libcurl vim ca-certificates tzdata \
    iproute net-tools tcpdump bind-utils gzip unzip wget tar less \
    strace lsof tree binutils bc procps-ng wireshark-cli \
    && chmod +s /usr/sbin/tcpdump /usr/sbin/ss /usr/bin/netstat \
    && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo $TZ > /etc/timezone \
    && echo "LANG=en_US.UTF-8" >/etc/locale.conf \
    && mkdir -p /data /app/ \
    && groupadd -r -g 1000 app \
    && useradd -r -u 1000 -g 1000 -d /app -s /bin/bash app \
    && chown -R app:app /data /app \
    && microdnf clean all && rm -rf /var/log/* \
    && >/etc/sysconfig/nftables.conf

USER app

WORKDIR /app
