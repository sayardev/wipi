#!/bin/bash
# wipi bootstrap script
# target: alpine linux on pi-zero-2w
# task: setup wireguard, pi-hole

# todo:
# install dependencies
# git, curl, jq, etc
apk add curl jq git
# install wireguard
apk add wireguard-tools wireguard-virt
rc-update add wireguard
rc-service wireguard start

# generate key-pair and write to config
openssl genpkey -algorithm ed25519 -out privatekey.pem
WG_PRIVATE_KEY=$(cat privatekey.pem)
WG_PUBLIC_KEY=$(openssl pkey -in privatekey.pem -pubout -outform PEM | tail -n +2 | head -n -1 | tr -d '\n')

apk add docker docker-cli docker-openrc
rc-update add docker
rc-service docker start

# firewall pi-hole dns
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT
PostUp = iptables -A FORWARD -o wg0 -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT
PostDown = iptables -D FORWARD -o wg0 -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# install pi-hole
docker run -d --name pihole -p 53:53/tcp -p 53:53/udp -p 80:80 \
    -e TZ="Europe/Berlin" \
    -e WEBPASSWORD="yourpassword" \
    -v /etc/pihole:/etc/pihole \
    -v /etc/dnsmasq.d:/etc/dnsmasq.d \
    --restart=unless-stopped \
    pihole/pihole:latest

# initial configure pi-hole (over api ?)

# install & configure talescale|cf-tunnel if no much load on system

# setup ddns+cron job
# claudine ddns script:
# chmod +x /usr/local/bin/cf-ddns.sh
# crontab -a */5 * * * * /usr/local/bin/cf-ddns.sh >/dev/null 2>&1
# 
#...client config
# envsubst < client-dns-failover.conf > wg0.conf
# envsubst < client-dual-endpoint.conf > wg0.conf
