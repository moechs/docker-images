FROM almalinux/9-init:9.7-20260104

ADD rootfs/ /

RUN dnf -y install epel-release \
    && /usr/bin/crb enable \
    && dnf config-manager --disable epel-cisco-openh264 \
    && dnf upgrade -y \
    && dnf clean all \
    && rm -rf /var/cache/dnf /var/log/* /tmp/* /var/tmp/* ~/.cache/*

RUN dnf --allowerasing -y install \
      cronie rsyslog openssh-server logrotate \
      initscripts passwd sudo \
      bind-utils iproute iputils net-tools nmap-ncat mtr traceroute \
      iptables-nft nftables tcpdump telnet curl wget \
      atop dstat procps lsof strace ethtool dmidecode \
      e2fsprogs util-linux file rsync coreutils-common inotify-tools \
      vim-enhanced git tig which python3.13-pip \
      bash-completion glibc-langpack-en gnupg2 hostname \
      ca-certificates openssl tzdata s-nail jq ipcalc \
      nmap openssh-clients binutils libxcrypt-compat \
    && pip3.13 install --no-cache-dir pip --upgrade \
    && pip3.13 install --no-cache-dir json2yaml \ 
    && systemctl mask \
      systemd-networkd.service \
      systemd-networkd.socket \
      systemd-networkd-wait-online.service \
      systemd-timedated.service \
      systemd-sysctl.service \
      systemd-hostnamed.service \
      systemd-resolved.service \
      systemd-journal-flush.service \
      systemd-network-generator.service \
      systemd-update-utmp.service \
      systemd-initctl.socket \
      ldconfig.service \
      dnf-makecache.timer \
      systemd-tmpfiles-clean.timer \
      sys-kernel-config.mount \
      sys-kernel-debug.mount \
      sys-kernel-tracing.mount \
    && systemctl unmask systemd-logind.service \
    && chmod +x /etc/rc.d/rc.local \
    && mkdir -p /root/.ssh && touch /root/.ssh/authorized_keys && chmod 700 /root/.ssh && chmod 600 /root/.ssh/authorized_keys \
    && echo c3NoLXJzYSBBQUFBQjNOemFDMXljMkVBQUFBREFRQUJBQUFCQVFETGZSM2l1aXk3MVVCdXZSeU5Ha2hzTzZxRnNFd0lYS3lkak1oeTBRV2lvV01UQTZhRUltZlBZMFNxTmJCNUtSTm5PZ01PSVNXVm5XSzYyV1BXbHc3K2Y2YjBFZ3Z1ZVg5RTZyTmFXWk1qaU1MSXE0SjBhc3JNY2VEaWlrMHVoeWY0ZEVaNTdPd3dkN2QwNE5vVC9jZCtpWlRKYWpGTEJyb2N3QzY0T0tnUGZRK256c0h3K21UOEFhN1U5bEtQQWZpWFFvNHN0clJJM3N6bTkvQ2FLWUZzcHppVUNoWFN2dXdxS1dYZFBOMU1RSVBJWHRVaVBvQnMyYm1XNitzVS9ZdU9hVEc0WTU0SWtuQTZpc2NwVUdhTURDNm1SSlROMXZhdGNWbTM4bTQyeHF5RXBGTnVDK0JJYm9kYjlOZUJsSkJKQTFXYVlHUk9KSzl2QWlLa000Mm4Kc3NoLXJzYSBBQUFBQjNOemFDMXljMkVBQUFBREFRQUJBQUFDQVFEc2tXUytmbk1UQVRmT3kyTUVqWmlHYktuMVdTQlpjdi9mbGh3L0ZxQkdsMmd3RXgvMlZMUkQ0ZlZ6eXZUMHZmeWZzTmFUOW9MM0U1NzNHQ2REM2Y4MWFFcWdWTnFNQTRCRzUwYUJQN0trZk9kR3MzQVBDa2phWThGd0MvdXBhVGpuMjhXUGFvbHBhZnh6NEVYTEJQa044QXJRL2hDOUUwdXhsZnBSOUgzVFl6TDRrZjRMSEZIRi9zb0xEcTFOdlpXeExDNjVmM2p2MDRhNDltdXRPZk15OC8vc0xyUlNwTnZiVTdIYUpZVDBFNmxPbWRrMHE1QmZCb21ZME1iWU93ZW85bjdGVzVmV2NHOUdNa3B4SFViRVl5QnpQdFIzbVpjWFNoRVZTV1JiU3pzd2VGbGIxU285THp2Sy9jaDhxYkxYemJiUXU1ZmZVQ2kyWDNlOUNTSU5iZXRJajZEeWZDMnpZTldTczdFZzJvUUhoZVN5a2VheU4rNXRnRmlEZG5LVDY3U1M0U0hGYW16cC8wTEdLaGc2cC84REVQTzR1cVZsekdFYVlNZW55emhySkt4UXNXYm55ZkU4b3lXM0Ywd0VDSXlTckpQekJTWmJmTDJDSG5sdVBKZEVXT1BBb3JTSTdYUHA2M1dVRWo5b2pLaWZ5U25remZFMzFpR09qVHpVLzF0dHlkbWl0b0szTUI3Sm54L1c3ZUYydnlhWlFYdVJJYURYVStzeVE0ZnRhZTdjeFc3eUJoWmZYc3lWdXh3ZU8vUndhNVdsdmhyaFllcEMxZU0zK080WXpqWGRkN0hXZmkreDA5cmgwK0RXekVpMlY1ZXQ1aW9teXJBTkdBL3gvUlZwYmd4RW15bUdJV1U1M3V1YjBrbGg4R2JKL3RPb2Q1bnYwdFJ3Z3c9PQo=|base64 -d>/root/.ssh/authorized_keys \
    && systemctl enable \
      crond.service \
      rsyslog.service \
      sshd.service \
      systemd-logind.service \
      systemd-user-sessions.service \
      logrotate.timer \
    && dnf clean all \
    && rm -rf /var/cache/dnf /var/log/* /tmp/* /var/tmp/* ~/.cache/*

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    container=docker
