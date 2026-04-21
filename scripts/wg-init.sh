#!/bin/bash
# wg-setup.sh - setup wg on wipi as edge vpn server
# utlizeses wg-quick for setting up wg interface from config file

# umask 077
wg genkey | tee privatekey | wg pubkey > publickey
ip link add dev wg0 type wireguard
ip addr add dev wg0 $WG_IP/24
wg set wg0 private-key ./privatekey
ip addr
wg set wg0 peer $(cat ./publickey) allowed-ips $WG_NET endpoint $WG_DOMAIN:$WG_PORT persistent-keepalive 25
wg setconf wg0 myconfig.conf
wg set wg0 listen-port 51820 private-key /path/to/private-key peer ABCDEF... allowed-ips 192.168.88.0/24 endpoint 209.202.254.14:8172
ip link set up dev wg0

#
# SPDX-License-Identifier: GPL-2.0
#
# Copyright (C) 2015-2020 Jason A. Donenfeld <Jason@zx2c4.com>. All Rights Reserved.
# https://git.zx2c4.com/wireguard-tools/plain/contrib/ncat-client-server/client.sh
#
set -e
[[ $UID == 0 ]] || { echo "You must be root to run this."; exit 1; }
exec 3<>/dev/tcp/demo.wireguard.com/42912
privatekey="$(wg genkey)"
wg pubkey <<<"$privatekey" >&3
IFS=: read -r status server_pubkey server_port internal_ip <&3
[[ $status == OK ]]
ip link del dev wg0 2>/dev/null || true
ip link add dev wg0 type wireguard
wg set wg0 private-key <(echo "$privatekey") peer "$server_pubkey" allowed-ips 0.0.0.0/0 endpoint "demo.wireguard.com:$server_port" persistent-keepalive 25
ip address add "$internal_ip"/24 dev wg0
ip link set up dev wg0
if [ "$1" == "default-route" ]; then
	host="$(wg show wg0 endpoints | sed -n 's/.*\t\(.*\):.*/\1/p')"
	ip route add $(ip route get $host | sed '/ via [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/{s/^\(.* via [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\).*/\1/}' | head -n 1) 2>/dev/null || true
	ip route add 0/1 dev wg0
	ip route add 128/1 dev wg0
fi

# debug & test
# modprobe wireguard && echo module wireguard +p > /sys/kernel/debug/dynamic_debug/control
