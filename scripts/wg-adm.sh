#!/bin/sh
# wg-adm - wireguard client management

WG_CONF="${WG_CONF:-/etc/wireguard/wg0.conf}"
CLIENTS_DIR="${CLIENTS_DIR:-/etc/wireguard/clients}"
WG_SUBNET="10.0.100"
WG_SERVER_IP="10.0.100.1"
WG_PORT="51820"

die()  { printf 'error: %s\n' "$*" >&2; exit 1; }
usage(){ printf 'usage: wg-adm add <name> | list | revoke <name>\n' >&2; exit 1; }

cmd_add() {
    name="${1:-}"
    [ -n "$name" ] || die "name required"
    mkdir -p "$CLIENTS_DIR"

    count=$(find "$CLIENTS_DIR" -name '*.conf' 2>/dev/null | wc -l)
    client_ip="${WG_SUBNET}.$((count + 2))"

    priv=$(wg genkey)
    pub=$(echo "$priv" | wg pubkey)
    psk=$(wg genpsk)

    [ -f /etc/wireguard/server.pub ] || die "server.pub not found, run wg-setup.sh first"
    server_pub=$(cat /etc/wireguard/server.pub)
    endpoint="${WG_ENDPOINT:-$(cat /etc/hostname)}:${WG_PORT}"

    cat >> "$WG_CONF" <<EOF

[Peer]
# ${name}
PublicKey = ${pub}
PresharedKey = ${psk}
AllowedIPs = ${client_ip}/32
EOF

    # apply live without restart
    tmp=$(mktemp)
    cat > "$tmp" <<EOF
[Peer]
PublicKey = ${pub}
PresharedKey = ${psk}
AllowedIPs = ${client_ip}/32
EOF
    wg addconf wg0 "$tmp" 2>/dev/null || true
    rm -f "$tmp"

    # write client config
    client_conf="$CLIENTS_DIR/${name}.conf"
    envsubst < client-dual.conf > "$client_conf"

    chmod 600 "$client_conf"

    printf 'added: %s (%s)\n\n' "$name" "$client_ip"
    cat "$client_conf"
    echo ""
    command -v qrencode >/dev/null 2>&1 \
        && qrencode -t ansiutf8 < "$client_conf" || true
}

cmd_list() {
    find "$CLIENTS_DIR" -name '*.conf' 2>/dev/null | xargs -I{} basename {} .conf | sort || echo "no clients"
}

cmd_revoke() {
    name="${1:-}"
    [ -n "$name" ] || die "name required"
    client_conf="$CLIENTS_DIR/${name}.conf"
    [ -f "$client_conf" ] || die "client not found: $name"

    # extract peer public key from client config's [Peer] block (server pubkey is there,
    # but we need the client pub - parse from server wg0.conf comment block)
    # match the # name comment in wg0.conf and remove that [Peer] block
    python3 /opt/wg-revoke.py "$WG_CONF" "$name"

    rm -f "$client_conf"
    wg syncconf wg0 <(wg-quick strip wg0) 2>/dev/null || warn "reload wg manually: wg-quick down wg0 && wg-quick up wg0"
}

warn() { printf 'warn: %s\n' "$*" >&2; }

case "${1:-}" in
    add)    shift; cmd_add "$@" ;;
    list)   cmd_list ;;
    revoke) shift; cmd_revoke "$@" ;;
    *)      usage ;;
esac
