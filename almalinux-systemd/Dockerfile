FROM almalinux:9.4

RUN dnf -y install epel-release && /usr/bin/crb enable \
    && dnf --allowerasing -y install atop bash-completion bind-utils binutils \
      ca-certificates cronie curl dstat dmidecode e2fsprogs ethtool file \
      glibc-langpack-en gnupg2 hostname initscripts iproute iptables-nft \
      iputils lsof mtr nmap-ncat net-tools nftables nmap openssh-clients \
      openssh-server openssl passwd procps rsyslog strace sudo \
      systemd-sysv systemd-udev tcpdump telnet traceroute tzdata \
      util-linux vim-enhanced wget libxcrypt-compat which git tig \
    && dnf upgrade -y && dnf clean all && rm -rf /var/log/* \
    && (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
      systemd-tmpfiles-setup.service ] || rm -f $i; done); \
      rm -f /lib/systemd/system/multi-user.target.wants/*; \
      rm -f /etc/systemd/system/*.wants/*; \
      rm -f /lib/systemd/system/local-fs.target.wants/*; \
      rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
      rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
      rm -f /lib/systemd/system/basic.target.wants/*; \
      rm -f /lib/systemd/system/anaconda.target.wants/*; \
      echo -e "[Install]\nWantedBy=multi-user.target" \
        >> /lib/systemd/system/systemd-sysctl.service; \
      echo -e "[Install]\nWantedBy=multi-user.target" \
        >> /lib/systemd/system/systemd-logind.service; \
      echo -e "[Install]\nWantedBy=multi-user.target" \
        >> /lib/systemd/system/systemd-user-sessions.service; \
      systemctl set-default multi-user.target; \
      systemctl mask dev-hugepages.mount sys-fs-fuse-connections.mount \
        network.service systemd-journal-flush.service \
        systemd-hostnamed.service systemd-timedated; \
      systemctl unmask systemd-logind; \
      systemctl enable crond.service rsyslog.service sshd.service \
        systemd-sysctl.service systemd-user-sessions.service \
        systemd-logind.service logrotate.timer; \
      chmod +x /etc/rc.d/rc.local; \
      mkdir -p /root/.ssh && chmod 700 /root/.ssh && \
      echo c3NoLXJzYSBBQUFBQjNOemFDMXljMkVBQUFBREFRQUJBQUFCQVFETGZSM2l1aXk3MVVCdXZSeU5Ha2hzTzZxRnNFd0lYS3lkak1oeTBRV2lvV01UQTZhRUltZlBZMFNxTmJCNUtSTm5PZ01PSVNXVm5XSzYyV1BXbHc3K2Y2YjBFZ3Z1ZVg5RTZyTmFXWk1qaU1MSXE0SjBhc3JNY2VEaWlrMHVoeWY0ZEVaNTdPd3dkN2QwNE5vVC9jZCtpWlRKYWpGTEJyb2N3QzY0T0tnUGZRK256c0h3K21UOEFhN1U5bEtQQWZpWFFvNHN0clJJM3N6bTkvQ2FLWUZzcHppVUNoWFN2dXdxS1dYZFBOMU1RSVBJWHRVaVBvQnMyYm1XNitzVS9ZdU9hVEc0WTU0SWtuQTZpc2NwVUdhTURDNm1SSlROMXZhdGNWbTM4bTQyeHF5RXBGTnVDK0JJYm9kYjlOZUJsSkJKQTFXYVlHUk9KSzl2QWlLa000Mm4Kc3NoLXJzYSBBQUFBQjNOemFDMXljMkVBQUFBREFRQUJBQUFDQVFEc2tXUytmbk1UQVRmT3kyTUVqWmlHYktuMVdTQlpjdi9mbGh3L0ZxQkdsMmd3RXgvMlZMUkQ0ZlZ6eXZUMHZmeWZzTmFUOW9MM0U1NzNHQ2REM2Y4MWFFcWdWTnFNQTRCRzUwYUJQN0trZk9kR3MzQVBDa2phWThGd0MvdXBhVGpuMjhXUGFvbHBhZnh6NEVYTEJQa044QXJRL2hDOUUwdXhsZnBSOUgzVFl6TDRrZjRMSEZIRi9zb0xEcTFOdlpXeExDNjVmM2p2MDRhNDltdXRPZk15OC8vc0xyUlNwTnZiVTdIYUpZVDBFNmxPbWRrMHE1QmZCb21ZME1iWU93ZW85bjdGVzVmV2NHOUdNa3B4SFViRVl5QnpQdFIzbVpjWFNoRVZTV1JiU3pzd2VGbGIxU285THp2Sy9jaDhxYkxYemJiUXU1ZmZVQ2kyWDNlOUNTSU5iZXRJajZEeWZDMnpZTldTczdFZzJvUUhoZVN5a2VheU4rNXRnRmlEZG5LVDY3U1M0U0hGYW16cC8wTEdLaGc2cC84REVQTzR1cVZsekdFYVlNZW55emhySkt4UXNXYm55ZkU4b3lXM0Ywd0VDSXlTckpQekJTWmJmTDJDSG5sdVBKZEVXT1BBb3JTSTdYUHA2M1dVRWo5b2pLaWZ5U25remZFMzFpR09qVHpVLzF0dHlkbWl0b0szTUI3Sm54L1c3ZUYydnlhWlFYdVJJYURYVStzeVE0ZnRhZTdjeFc3eUJoWmZYc3lWdXh3ZU8vUndhNVdsdmhyaFllcEMxZU0zK080WXpqWGRkN0hXZmkreDA5cmgwK0RXekVpMlY1ZXQ1aW9teXJBTkdBL3gvUlZwYmd4RW15bUdJV1U1M3V1YjBrbGg4R2JKL3RPb2Q1bnYwdFJ3Z3c9PQo=|base64 -d>/root/.ssh/authorized_keys

ADD rootfs/ /

VOLUME [ "/sys/fs/cgroup" ]

CMD ["/usr/sbin/init"]
