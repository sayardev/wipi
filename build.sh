#!/bin/bash
# wipi build; build unattended alpine-setup

set -eu

log()  { printf '[wipi] %s\n' "$*"; }
die()  { printf '[error] %s\n' "$*" >&2; exit 1; }

[ -f .env ] && . ./.env || true

HOSTNAME="${HOSTNAME:-wipi-02}"
TIMEZONE="${TIMEZONE:-UTC}"
ALPINE_VER="${ALPINE_VER:-3.23.3}"
ALPINE_ARCH="${ALPINE_ARCH:-armhf}"
USERNAME="${USERNAME:-pi02}"
USER_PASSWD="${USER_PASSWD:-alpine}"
WIFI_SSID="${WIFI_SSID:-}"
WIFI_PASSWD="${WIFI_PASSWD:-}"
SSH_PUBKEY="${SSH_PUBKEY:-}"

cache_dir="${CACHE_DIR:-./.cache}"
build_dir="${BUILD_DIR:-./.build}"
alpine_minor=$(echo "$ALPINE_VER" | cut -d. -f1-2)
alpi_tar="alpine-rpi-${ALPINE_VER}-${ALPINE_ARCH}.tar.gz"
alpi_url="https://dl-cdn.alpinelinux.org/alpine/v${alpine_minor}/releases/${ALPINE_ARCH}/${alpi_tar}"

mkdir -p "$build_dir" "$cache_dir"
log "download alpine ${ALPINE_VER} ${ALPINE_ARCH}"
if [ ! -f "$cache_dir/$alpi_tar" ]; then
    curl -fL --progress-bar -o "$cache_dir/$alpi_tar" "$alpi_url"
    curl -fsSL -o "$cache_dir/$alpi_tar.sha256" "${alpi_url}.sha256"
    (cd "$cache_dir" && sha256sum -c "$alpi_tar.sha256") || die "sha256 verification failed"
    log "downloaded"
fi

log "extract and seed"
alpi_dir="$cache_dir/${alpi_tar%.tar.gz}-rootfs"
rm -rf "$alpi_dir"
mkdir -p "$alpi_dir"
tar -xzf "$cache_dir/$alpi_tar" -C "$alpi_dir"
log "extracted"

log "copy scripts to /opt/scripts"
mkdir -p "$alpi_dir/opt/scripts"
cp scripts/* "$alpi_dir/opt/scripts/" 2>/dev/null || true
chmod +x "$alpi_dir/opt/scripts"/*.sh 2>/dev/null || true
log "scripts copied"

log "prepare ssh pubkey"
if [ -z "$SSH_PUBKEY" ]; then
    log "warning: SSH_PUBKEY not set, no pubkey will be seeded"
    export SSH_PUBKEY_CONTENT=""
else
    export SSH_PUBKEY_CONTENT="$SSH_PUBKEY"
    log "pubkey prepared"
fi

log "seed alpine installer"
mkdir -p "$alpi_dir/boot/seed"
envsubst < alpi-seed.conf > "$alpi_dir/boot/seed/answers"
log "seeded"

log "inject ssh pubkey to authorized_keys"
if [ -n "$SSH_PUBKEY_CONTENT" ]; then
    mkdir -p "$alpi_dir/home/${USERNAME}/.ssh"
    echo "$SSH_PUBKEY_CONTENT" > "$alpi_dir/home/${USERNAME}/.ssh/authorized_keys"
    chmod 700 "$alpi_dir/home/${USERNAME}/.ssh"
    chmod 600 "$alpi_dir/home/${USERNAME}/.ssh/authorized_keys"
    log "pubkey injected"
else
    log "warning: SSH_PUBKEY not set"
fi

log "create init script for password"
if [ -n "$USER_PASSWD" ]; then
    mkdir -p "$alpi_dir/usr/local/bin"
    cat > "$alpi_dir/usr/local/bin/wipi-init.sh" << SCRIPT
#!/bin/sh
echo "${USERNAME}:${USER_PASSWD}" | chpasswd
SCRIPT
    chmod +x "$alpi_dir/usr/local/bin/wipi-init.sh"
    log "init script created"
fi

log "package"
tar -czf "$build_dir/alpine-wipi.tar.gz" -C "$alpi_dir" .
log "output: $build_dir/alpine-wipi.tar.gz"

#### wip;
mkdir -p $build_dir/ovl
mkdir -p $build_dir/ovl/etc
touch $build_dir/ovl/etc/.default_boot_services

cat $build_dir/ovl/etc/apk/repositories <<EOF
/media/cdrom/apks
https://dl-cdn.alpinelinux.org/alpine/v3.18/main
https://dl-cdn.alpinelinux.org/alpine/v3.18/community
EOF

cp kickstart.sh $build_dir/ovl/etc/local.d/auto-setup-alpine.start
chmod 755 $build_dir/ovl/etc/local.d/auto-setup-alpine.start
# example: alpine-setup -c answers
cp alpi-seed.conf $build_dir/ovl/etc/auto-setup-alpine/answers
tar --owner=0 --group=0 -czf $build_dir/localhost.apkovl.tar.gz -C $build_dir/ovl .

# TODO
xorriso \
  -indev alpine-virt-3.18.4-x86_64.iso \
  -outdev my-alpine.iso \
  -map $build_dir/localhost.apkovl.tar.gz /localhost.apkovl.tar.gz \
  -boot_image any replay