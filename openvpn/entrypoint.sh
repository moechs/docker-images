#!/bin/sh

set -e

mkdir -p /dev/net
if [ ! -c /dev/net/tun ]; then
    mknod /dev/net/tun c 10 200
fi

cd /etc/openvpn && \
exec openvpn ${OVPN_ARGS:---suppress-timestamps --nobind} --config ${OVPN_CONFIG:-client.conf}
