#!/bin/bash

HOST_IP=$(hostname -I | awk '{print $1}')

show_help() {
  cat <<EOF
Usage:
  $0 <nama-vps>    Cek port proxy untuk 1 VPS
  $0 --all         Cek port proxy untuk semua VPS
  $0 -h | --help   Tampilkan bantuan

Contoh:
  $0 vps-01
  $0 --all

Output:
  VPS  IP:PORT  STATUS  PROXY
EOF
  exit 0
}

# arg check
[ -z "$1" ] && show_help

check_vps() {
  VPS="$1"

  if ! lxc info "$VPS" >/dev/null 2>&1; then
    echo "VPS '$VPS' tidak ditemukan"
    return
  fi

  lxc config device list "$VPS" | while read dev; do
    TYPE=$(lxc config device get "$VPS" "$dev" type 2>/dev/null)
    [ "$TYPE" != "proxy" ] && continue

    LISTEN=$(lxc config device get "$VPS" "$dev" listen)
    [ -z "$LISTEN" ] && continue

    PORT=${LISTEN##*:}

    timeout 2 bash -c "</dev/tcp/127.0.0.1/$PORT" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
      STATUS="OPEN"
    else
      STATUS="CLOSED"
    fi

    printf "%-15s %-22s %-10s %s\n" \
      "$VPS" "$HOST_IP:$PORT" "$STATUS" "$dev"
  done
}

case "$1" in
  -h|--help)
    show_help
    ;;
  --all)
    printf "%-15s %-22s %-10s %s\n" "VPS" "IP:PORT" "STATUS" "PROXY"
    lxc list --format csv -c n | while read c; do
      check_vps "$c"
    done
    ;;
  *)
    printf "%-15s %-22s %-10s %s\n" "VPS" "IP:PORT" "STATUS" "PROXY"
    check_vps "$1"
    ;;
esac
