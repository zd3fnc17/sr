#!/bin/bash

CACHE_DIR="$HOME/cache"
CACHE_FILE="$CACHE_DIR/lxd-proxy-index.tsv"

show_help() {
  cat <<EOF
LXD Proxy Cache Builder

Usage:
  $0 [options]

Options:
  -h, --help     Tampilkan bantuan
  --rebuild      Paksa rebuild cache (hapus cache lama dulu)

Deskripsi:
  Script ini membangun index proxy LXD yang berisi:
    - LISTEN_IP      : IP di host (proxy.listen)
    - LISTEN_PORT    : Port di host
    - CONNECT_IP     : IP tujuan di VPS (proxy.connect)
    - CONNECT_PORT   : Port tujuan di VPS
    - VPS_NAME       : Nama VPS / container
    - PROXY_NAME     : Nama device proxy (alias port)

Output:
  $CACHE_FILE

Contoh:
  $0
  $0 --rebuild

Catatan:
  - 0.0.0.0 / [::] berarti listen di semua IP host
  - Script ini TIDAK melakukan suspend / stop VPS
EOF
  exit 0
}

# arg parsing
case "$1" in
  -h|--help)
    show_help
    ;;
  --rebuild)
    rm -f "$CACHE_FILE"
    ;;
esac

mkdir -p "$CACHE_DIR"

echo -e "LISTEN_IP\tLISTEN_PORT\tCONNECT_IP\tCONNECT_PORT\tVPS_NAME\tPROXY_NAME" > "$CACHE_FILE"

VPS_LIST=$(lxc list --format csv -c n)

for VPS in $VPS_LIST; do
  DEV_LIST=$(lxc config device list "$VPS")
  for dev in $DEV_LIST; do
    TYPE=$(lxc config device get "$VPS" "$dev" type 2>/dev/null)
    [ "$TYPE" != "proxy" ] && continue

    LISTEN=$(lxc config device get "$VPS" "$dev" listen)
    CONNECT=$(lxc config device get "$VPS" "$dev" connect)

    [ -z "$LISTEN" ] && continue
    [ -z "$CONNECT" ] && continue

    # LISTEN
    L_RAW="${LISTEN##*://}"
    L_IP="${L_RAW%%:*}"
    L_PORT="${L_RAW##*:}"
    [ -z "$L_IP" ] && L_IP="0.0.0.0"

    # CONNECT
    C_RAW="${CONNECT##*://}"
    C_IP="${C_RAW%%:*}"
    C_PORT="${C_RAW##*:}"

    echo -e "$L_IP\t$L_PORT\t$C_IP\t$C_PORT\t$VPS\t$dev" >> "$CACHE_FILE"
  done
done

echo "Cache proxy LXD berhasil dibuat:"
echo "  $CACHE_FILE"
