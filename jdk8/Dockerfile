FROM almalinux:9.6-20250803

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=Asia/Shanghai \
    PS1='\u@\h:\w$ ' \
    JAVA_HOME=/usr/java/default \
    APP_DIR=/app \
    LOG_DIR=/app/logs \
    DATA_DIR=/data \
    FAKETIME_DONT_FAKE_MONOTONIC=1 \
    FAKETIME_TIMESTAMP_FILE=/etc/faketime/faketimerc

ENV PATH=/usr/java/default/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin


COPY entrypoint.sh /entrypoint.sh

RUN dnf update -y && \
    dnf install -y epel-release glibc-langpack-en glibc-all-langpacks \
    && rpm -ivh https://repo.plus \
    && dnf install -y vim ca-certificates tzdata tzdata-java \
       iproute net-tools tcpdump bind-utils gzip wget tar less \
       libfaketime binutils freetype fontconfig wkhtmltox bc dumb-init \
       dejavu-sans-fonts chinese-fonts procps-ng jdk arthas \
    && chmod +s /usr/sbin/tcpdump /usr/sbin/ss /usr/bin/netstat \
    && sed -e "s/#crypto.policy=unlimited/crypto.policy=unlimited/" -i /usr/java/default/jre/lib/security/java.security \
    && ln -sf /etc/pki/ca-trust/extracted/java/cacerts /usr/java/default/jre/lib/security/cacerts \
    && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo $TZ > /etc/timezone \
    && update-ca-trust \
    && mkdir -p /data /app/logs /opt/spring /etc/faketime \
    && ln -sf /app/logs /data/logs \
    && groupadd -r appuser \
    && useradd -r -g appuser -d /app -s /bin/bash appuser \
    && touch /etc/faketime/faketimerc \
    && chown -R appuser:appuser /data /app /opt/spring /etc/faketime \
    && chmod +x /entrypoint.sh \
    && chown appuser:appuser /entrypoint.sh \
    && date \
    && LD_PRELOAD=/usr/lib64/libfaketime.so.1 FAKETIME="-1d" date \
    && echo "+1d">/etc/faketime/faketimerc \
    && LD_PRELOAD=/usr/lib64/libfaketime.so.1 date \
    && >/etc/faketime/faketimerc \
    && date \
    && rm -rf /var/cache/dnf /var/log/dnf.* /tmp/* /var/tmp/*

USER appuser

WORKDIR /app

EXPOSE 8080

ENTRYPOINT ["/usr/bin/dumb-init", "--", "/entrypoint.sh"]

CMD ["-version"]
