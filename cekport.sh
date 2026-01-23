#!/bin/bash

# usage check
if [ -z "$1" ]; then
  echo "Usage: $0 <nama-vps>"
  exit 1
fi

VPS="$1"
HOST_IP=$(hostname -I | awk '{print $1}')

# cek apakah VPS ada
if ! lxc info "$VPS" >/dev/null 2>&1; then
  echo "VPS '$VPS' tidak ditemukan"
  exit 1
fi

lxc config device list "$VPS" | while read dev; do
  TYPE=$(lxc config device get "$VPS" "$dev" type 2>/dev/null)
  [ "$TYPE" != "proxy" ] && continue

  LISTEN=$(lxc config device get "$VPS" "$dev" listen)
  [ -z "$LISTEN" ] && continue

  PORT=${LISTEN##*:}

  # cek port (timeout 2 detik)
  timeout 2 bash -c "</dev/tcp/127.0.0.1/$PORT" >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    STATUS="OPEN"
  else
    STATUS="CLOSED"
  fi

  printf "%s %s:%s %s %s\n" "$VPS" "$HOST_IP" "$PORT" "$dev" "$STATUS"
done
