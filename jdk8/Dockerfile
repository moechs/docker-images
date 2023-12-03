FROM centos:7

ENV LANG=en_US.UTF-8 \
    TZ=Asia/Shanghai \
    PS1='\u@\h:\w$ ' \
    JAVA_HOME=/usr/java/default \
    APP_DIR=/data/app \
    LOG_DIR=/data/logs \
    FAKETIME_DONT_FAKE_MONOTONIC=1 \
    FAKETIME_TIMESTAMP_FILE=/etc/faketime/faketimerc

ENV PATH=/usr/java/default/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN rpm -ivh https://repo.plus \
    && yum install epel-release -y \
    && yum update -y \
    && yum install -y bash ca-certificates tzdata tzdata-java nc iproute net-tools tcpdump gzip curl wget tar less arthas libfaketime binutils freetype fontconfig jdk dejavu-sans-fonts chinese-fonts \
    && chmod +s /usr/sbin/tcpdump /usr/sbin/ss /usr/bin/netstat \
    && ln -sf /etc/pki/ca-trust/extracted/java/cacerts /usr/java/default/jre/lib/security/cacerts \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && update-ca-trust \
    && java -version \
    && mkdir -p /data /app/logs /etc/faketime \
    && touch /etc/faketime/faketimerc \
    && chown -R nobody.nobody /data /app /etc/faketime \
    && usermod -d /app nobody \
    && date \
    && LD_PRELOAD=/usr/lib64/faketime/libfaketime.so.1 FAKETIME="+1d" date \
    && echo "+1d">/etc/faketime/faketimerc \
    && LD_PRELOAD=/usr/lib64/faketime/libfaketime.so.1 date \
    && rm -rf /var/cache/yum/* /var/log/yum.log /tmp/*

USER nobody

WORKDIR /app

EXPOSE 8080

ENTRYPOINT ["java"]

CMD []
