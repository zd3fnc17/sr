#!/bin/bash
# DESC: untuk memperbarui cache proxy. nanti digunakan untuk banyak keperluan

CACHE_FILE="/home/ubuntu/cache/lxd-proxy-index.tsv"
CACHE_DIR="$(dirname "$CACHE_FILE")"

NOW="$(date '+%Y-%m-%d %H:%M:%S')"
COUNT=0

show_help() {
  cat <<EOF
LXD Proxy Cache Builder

Usage:
  $0 [options]

Options:
  -h, --help     Tampilkan bantuan
  --rebuild      Rebuild cache proxy (default behavior)

Deskripsi:
  Script ini membangun cache proxy LXD berisi:
    - LISTEN_IP
    - LISTEN_PORT
    - CONNECT_IP
    - CONNECT_PORT
    - VPS_NAME
    - PROXY_NAME

Metadata:
  - Lokasi cache
  - Waktu terakhir diperbarui

Output:
  $CACHE_FILE
EOF
  exit 0
}

case "$1" in
  -h|--help)
    show_help
    ;;
esac

mkdir -p "$CACHE_DIR"

echo "Memulai proses build proxy cache..."
echo "Target cache : $CACHE_FILE"
echo "Waktu mulai  : $NOW"
echo

{
  echo "# PROXY_CACHE_FILE=$CACHE_FILE"
  echo "# UPDATED_AT=$NOW"
  echo "# FORMAT=LISTEN_IP LISTEN_PORT CONNECT_IP CONNECT_PORT VPS_NAME PROXY_NAME"
  echo -e "LISTEN_IP\tLISTEN_PORT\tCONNECT_IP\tCONNECT_PORT\tVPS_NAME\tPROXY_NAME"
} > "$CACHE_FILE"

VPS_LIST=$(lxc list --format csv -c n)

for VPS in $VPS_LIST; do
  echo "→ Memproses VPS: $VPS"
  DEV_LIST=$(lxc config device list "$VPS")
  for dev in $DEV_LIST; do
    TYPE=$(lxc config device get "$VPS" "$dev" type 2>/dev/null)
    [ "$TYPE" != "proxy" ] && continue

    LISTEN=$(lxc config device get "$VPS" "$dev" listen)
    CONNECT=$(lxc config device get "$VPS" "$dev" connect)

    [ -z "$LISTEN" ] && continue
    [ -z "$CONNECT" ] && continue

    L_RAW="${LISTEN##*://}"
    L_IP="${L_RAW%%:*}"
    L_PORT="${L_RAW##*:}"
    [ -z "$L_IP" ] && L_IP="tcp"

    C_RAW="${CONNECT##*://}"
    C_IP="${C_RAW%%:*}"
    C_PORT="${C_RAW##*:}"

    echo -e "$L_IP\t$L_PORT\t$C_IP\t$C_PORT\t$VPS\t$dev" >> "$CACHE_FILE"
    COUNT=$((COUNT+1))
  done
done

echo
echo "Proxy cache berhasil diperbarui"
echo "  Lokasi      : $CACHE_FILE"
echo "  Waktu       : $NOW"
echo "  Total entry : $COUNT"
