ARG IMAGE_NAME=moechs/almalinux-ansible
ARG IMAGE_VERSION=7.7.0

FROM almalinux/9-init:9.9-20261116

ARG IMAGE_VERSION

ENV LANG=en_US.UTF-8 \
    TZ=Asia/Shanghai \
    container=docker \
    PS1='\u@\h:\w# '

RUN dnf -y install epel-release \
    && /usr/bin/crb enable \
    && dnf config-manager --disable epel-cisco-openh264 \
    && dnf upgrade -y \
    && dnf clean all \
    && rm -rf /var/cache/dnf /var/log/* /tmp/* /var/tmp/* ~/.cache/*

RUN dnf install --allowerasing -y bash curl wget ca-certificates tzdata \
    dumb-init openssh openssh-clients sshpass rsync ansible-${IMAGE_VERSION} python3-passlib \
    glibc-langpack-en \
    && echo $TZ > /etc/timezone \
    && echo "LANG=en_US.UTF-8" >/etc/locale.conf \
    && dnf clean all \
    && rm -rf /var/cache/dnf /var/log/* /tmp/* /var/tmp/* ~/.cache/*

ADD rootfs/ /
