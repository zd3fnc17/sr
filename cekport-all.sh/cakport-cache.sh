#!/bin/bash

CACHE_FILE="/home/ubuntu/cache/lxd-proxy-index.tsv"
HOST_IP=$(hostname -I | awk '{print $1}')

show_help() {
  cat <<EOF
Cek status port proxy VPS (berdasarkan cache proxy)

Usage:
  $0 <nama-vps>    Cek port proxy untuk 1 VPS
  $0 --all         Cek port proxy untuk semua VPS
  $0 -h | --help   Tampilkan bantuan

Output:
  VPS  IP:PORT  STATUS  PROXY

Catatan:
  - Data proxy diambil dari cache:
    $CACHE_FILE
  - Tidak melakukan query LXD
EOF
  exit 0
}

# validasi cache
[ ! -f "$CACHE_FILE" ] && {
  echo "Cache proxy tidak ditemukan:"
  echo "  $CACHE_FILE"
  echo "Jalankan ./build-cache-proxy.sh terlebih dahulu"
  exit 1
}

[ -z "$1" ] && show_help

printf "%-15s %-22s %-10s %s\n" "VPS" "IP:PORT" "STATUS" "PROXY"

check_vps() {
  local VPS="$1"

  awk -v vps="$VPS" '
    NR>1 && $5==vps {print $2 "\t" $6}
  ' "$CACHE_FILE" | while read PORT PROXY; do

    timeout 2 bash -c "</dev/tcp/127.0.0.1/$PORT" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
      STATUS="OPEN"
    else
      STATUS="CLOSED"
    fi

    printf "%-15s %-22s %-10s %s\n" \
      "$VPS" "$HOST_IP:$PORT" "$STATUS" "$PROXY"
  done
}

case "$1" in
  -h|--help)
    show_help
    ;;
  --all)
    awk 'NR>1 {print $5}' "$CACHE_FILE" | sort -u | while read VPS; do
      check_vps "$VPS"
    done
    ;;
  *)
    check_vps "$1"
    ;;
esac
