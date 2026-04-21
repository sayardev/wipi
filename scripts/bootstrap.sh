#!/bin/sh
# wipi bootstrap; post-boot to bootstrap wipi for wipine

set -eu

log()  { printf '[wipi] %s\n' "$*"; }
die()  { printf '[error] %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "must run as root"

log "al+pine bootstrap"
log "update system"
apk update
apk upgrade -y

# log "enable ip forwarding"
# echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
# sysctl -p /etc/sysctl.conf > /dev/null

log "install packages"
apk add --no-cache curl git ca-certificates openssl

log "setup docker"
rc-update add docker default
rc-service docker start

log "setup ssh"
rc-update add sshd default
rc-service sshd start

log "deploy wipine"
git clone https://github.com/sayardev/wipine.git && 
    cd wipine &&
    docker-compose up -d

log "wipi ready"
