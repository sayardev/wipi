#!/bin/bash
# this script can be saved as /usr/local/bin/wgphys and used for commands like wgphys up, wgphys down, and wgphys exec:
# https://www.wireguard.com/netns/#the-new-namespace-solution

set -ex

[[ $UID != 0 ]] && exec sudo -E "$(readlink -f "$0")" "$@"

up() {
    killall wpa_supplicant dhcpcd || true
    ip netns add physical
    ip -n physical link add wgvpn0 type wireguard
    ip -n physical link set wgvpn0 netns 1
    wg setconf wgvpn0 /etc/wireguard/wgvpn0.conf
    ip addr add 192.168.4.33/32 dev wgvpn0
    ip link set eth0 down
    ip link set wlan0 down
    ip link set eth0 netns physical
    iw phy phy0 set netns name physical
    ip netns exec physical dhcpcd -b eth0
    ip netns exec physical dhcpcd -b wlan0
    ip netns exec physical wpa_supplicant -B -c/etc/wpa_supplicant/wpa_supplicant-wlan0.conf -iwlan0
    ip link set wgvpn0 up
    ip route add default dev wgvpn0
}

down() {
    killall wpa_supplicant dhcpcd || true
    ip -n physical link set eth0 down
    ip -n physical link set wlan0 down
    ip -n physical link set eth0 netns 1
    ip netns exec physical iw phy phy0 set netns 1
    ip link del wgvpn0
    ip netns del physical
    dhcpcd -b eth0
    dhcpcd -b wlan0
    wpa_supplicant -B -c/etc/wpa_supplicant/wpa_supplicant-wlan0.conf -iwlan0
}

execi() {
    exec ip netns exec physical sudo -E -u \#${SUDO_UID:-$(id -u)} -g \#${SUDO_GID:-$(id -g)} -- "$@"
}

command="$1"
shift

case "$command" in
    up) up "$@" ;;
    down) down "$@" ;;
    exec) execi "$@" ;;
    *) echo "Usage: $0 up|down|exec" >&2; exit 1 ;;
esac