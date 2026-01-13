FROM almalinux:9.7-20260104

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=Asia/Shanghai \
    PS1='\u@\h:\w$ ' \
    JAVA_HOME=/usr/lib/jvm/java \
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
       iproute net-tools tcpdump bind-utils gzip unzip wget tar less \
       libfaketime binutils freetype fontconfig wkhtmltox bc dumb-init \
       libpng libjpeg libX11 libXext libXrender xorg-x11-fonts-75dpi xorg-x11-fonts-Type1 \
       java-1.8.0-openjdk java-1.8.0-openjdk-devel java-1.8.0-openjdk-headless \
       dejavu-sans-fonts chinese-fonts procps-ng arthas \
    && chmod +s /usr/sbin/tcpdump /usr/sbin/ss /usr/bin/netstat \
    && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo $TZ > /etc/timezone \
    && update-ca-trust \
    && mkdir -p /data /app/logs /opt/spring /etc/faketime \
    && ln -sf /app/logs /data/logs \
    && groupadd -r -g 1000 app \
    && useradd -r -u 1000 -g 1000 -d /app -s /bin/bash app \
    && touch /etc/faketime/faketimerc \
    && chown -R app:app /data /app /opt/spring /etc/faketime \
    && chmod +x /entrypoint.sh \
    && chown app:app /entrypoint.sh \
    && date \
    && LD_PRELOAD=/usr/lib64/libfaketime.so.1 FAKETIME="-1d" date \
    && echo "+1d">/etc/faketime/faketimerc \
    && LD_PRELOAD=/usr/lib64/libfaketime.so.1 date \
    && >/etc/faketime/faketimerc \
    && date \
    && rm -rf /var/cache/dnf /var/log/dnf.* /tmp/* /var/tmp/*

USER app

WORKDIR /app

ENTRYPOINT ["/usr/bin/dumb-init", "--", "/entrypoint.sh"]

CMD ["-version"]
