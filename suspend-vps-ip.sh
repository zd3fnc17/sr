#!/bin/bash

CACHE_FILE="/home/ubuntu/cache/lxd-proxy-index.tsv"

show_help() {
  cat <<EOF
Cari VPS berdasarkan IP:PORT menggunakan cache proxy LXD

Usage:
  $0 IP:PORT [IP:PORT ...]
  $0 -f file.txt
  $0 -h | --help

Contoh:
  $0 51.79.228.218:1033 51.79.228.218:1037
  $0 -f ports.txt

Catatan:
  - Data diambil dari cache:
    $CACHE_FILE
  - IP diabaikan, pencocokan berdasarkan PORT
  - Output berupa bash for-loop siap dieksekusi
EOF
  exit 0
}

[ ! -f "$CACHE_FILE" ] && {
  echo "# Cache tidak ditemukan:"
  echo "# $CACHE_FILE"
  echo "# Jalankan ./cache-proxy.sh terlebih dahulu"
  exit 1
}

[ -z "$1" ] && show_help

# ambil target port
TARGET_PORTS=()

if [ "$1" = "-f" ]; then
  [ -z "$2" ] && echo "File tidak ada" && exit 1
  while read line; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    TARGET_PORTS+=("${line##*:}")
  done < "$2"
else
  for arg in "$@"; do
    TARGET_PORTS+=("${arg##*:}")
  done
fi

declare -A VPS_MATCH

# lookup ke cache
for p in "${TARGET_PORTS[@]}"; do
  awk -v port="$p" '
    NR>1 && $2==port {print $5}
  ' "$CACHE_FILE" | while read vps; do
    VPS_MATCH["$vps"]=1
  done
done

# output
if [ "${#VPS_MATCH[@]}" -eq 0 ]; then
  echo "# Tidak ada VPS yang cocok"
  exit 0
fi

echo "for v in ${!VPS_MATCH[@]}; do"
echo "  lxc stop \$v"
echo "  lxc config set \$v boot.autostart false"
echo "done"
