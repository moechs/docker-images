FROM almalinux:9.7-20260407

ENV LANG=en_US.UTF-8 \
    TZ=Asia/Shanghai \
    PS1='\u@\h:\w$ '

RUN dnf install --allowerasing -y ansible \
    && echo $TZ > /etc/timezone \
    && echo "LANG=en_US.UTF-8" >/etc/locale.conf \
    && dnf clean all \
    && rm -rf /var/cache/dnf /var/log/* /tmp/* /var/tmp/* ~/.cache/*

ADD rootfs/ /
