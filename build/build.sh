#!/bin/bash
# wipi-build.sh - wipi bootstraping
set -eu

log() { echo "[wipi-build] $*"; }
die() { echo "[error] $*" >&2; exit 1; }

out_dir="/wipi/.build"
cache_dir="${CACHE_DIR:-/tmp/wipi-cache}"
alpi_ver="${ALPINE_VER:-3.23.3}"
alpi_arch="${ALPINE_ARCH:-armhf}"
alpi_minor=$(echo "$alpi_ver" | cut -d. -f1-2)
alpi_tar="alpine-rpi-${alpi_ver}-${alpi_arch}.tar.gz"
alpi_url="https://dl-cdn.alpinelinux.org/alpine/v${alpi_minor}/releases/${alpi_arch}/${alpi_tar}"

mkdir -p "$out_dir" "$cache_dir"

# stage 1: fetch alpine
log "fetch alpine ${alpi_ver} ${alpi_arch}"
if [ ! -f "$cache_dir/$alpi_tar" ]; then
    curl -fL --progress-bar -o "$cache_dir/$alpi_tar" "$alpi_url"
    curl -fsSL -o "$cache_dir/$alpi_tar.sha256" "${alpi_url}.sha256"
    (cd "$cache_dir" && sha256sum -c "$alpi_tar.sha256") || die "sha256 check failed"
    log "downloaded: $alpi_tar"
else
    log "cache hit: $alpi_tar"
fi

# stage 2: seed
log "seed alpine rootfs"
alpi_dir="$cache_dir/${alpi_tar%.tar.gz}-rootfs"
rm -rf "$alpi_dir"
mkdir -p "$alpi_dir"

tar -xzf "$cache_dir/$alpi_tar" -C "$alpi_dir"

# inject scripts
log "inject wipi scripts"
mkdir -p "$alpi_dir/etc/wipi"
cp /wipi/scripts/*.sh "$alpi_dir/etc/wipi/"
chmod +x "$alpi_dir/etc/wipi/"*.sh

# inject wipi.env
envsubst < /wipi/templates/wipi.env.template > "$alpi_dir/etc/wipi/wipi.env"
chmod 600 "$alpi_dir/etc/wipi/wipi.env"

# inject pihole compose
envsubst '${TZ} ${PIHOLE_PASSWD}' < /wipi/templates/pihole.yaml.template > "$alpi_dir/etc/wipi/pihole.yaml"

# inject alpine answers (alpi-seed)
log "inject seed config"
mkdir -p "$alpi_dir/boot/seed"
envsubst '${HOSTNAME} ${TZ}' < /wipi/templates/alpi-seed.conf > "$alpi_dir/boot/seed/answers"

# inject wifi config if set
if [ -n "${WIFI_SSID:-}" ]; then
    log "inject wifi config"
    wpa_dir="$alpi_dir/etc/wpa_supplicant"
    mkdir -p "$wpa_dir"
    envsubst < /wipi/templates/wifi.conf >> "$wpa_dir/wpa_supplicant.conf"
    chmod 600 "$wpa_dir/wpa_supplicant.conf"
fi

# stage 3: pack artifact
log "pack artifact"
tar -czf "$out_dir/alpine-wipi.tar.gz" -C "$alpi_dir" .

# generate test artifacts
envsubst < /wipi/templates/wipi.env.template > "$out_dir/wipi.env"
chmod 600 "$out_dir/wipi.env"
envsubst '${TZ} ${PIHOLE_PASSWD}' < /wipi/templates/pihole.yaml.template > "$out_dir/pihole.yaml"

log "built: $out_dir/alpine-wipi.tar.gz"
log "done"
