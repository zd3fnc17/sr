#!/bin/bash

CACHE_FILE="/home/ubuntu/cache/lxd-proxy-index.tsv"

show_help() {
  cat <<EOF
Generate perintah suspend / terminate VPS berdasarkan IP:PORT
(menggunakan cache proxy)

Usage:
  $0 IP:PORT [IP:PORT ...]
  $0 -f file.txt
  $0 -h | --help

Catatan:
  - IP diabaikan, pencocokan berdasarkan PORT
  - Data diambil dari cache proxy
  - Output hanya berupa perintah (tidak dieksekusi)

Cache:
  $CACHE_FILE
EOF
  exit 0
}

# validasi cache
[ ! -f "$CACHE_FILE" ] && {
  echo "# Cache proxy tidak ditemukan:"
  echo "# $CACHE_FILE"
  echo "# Jalankan ./cache-proxy.sh terlebih dahulu"
  exit 1
}

# tampilkan info cache
CACHE_UPDATED_AT=$(awk -F= '/^# UPDATED_AT=/ {print $2}' "$CACHE_FILE")

echo "menggunakan proxy cache \"$CACHE_FILE\""
echo "proxy diperbarui pada \"$CACHE_UPDATED_AT\""
echo

[ -z "$1" ] && show_help

# ambil port dari input
TARGET_PORTS=()

if [ "$1" = "-f" ]; then
  [ -z "$2" ] && { echo "File tidak ditemukan"; exit 1; }
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

# lookup VPS dari cache (tanpa subshell)
for p in "${TARGET_PORTS[@]}"; do
  while read vps; do
    VPS_MATCH["$vps"]=1
  done < <(
    awk -v port="$p" 'NR>1 && $2==port {print $5}' "$CACHE_FILE"
  )
done

# validasi hasil
if [ "${#VPS_MATCH[@]}" -eq 0 ]; then
  echo "# Tidak ada VPS yang cocok berdasarkan cache"
  exit 0
fi

VPS_LIST="${!VPS_MATCH[@]}"

# ================= OUTPUT =================

echo "# ===== SUSPEND VPS ====="
echo "for v in $VPS_LIST; do"
echo "  lxc stop \$v"
echo "  lxc config set \$v boot.autostart false"
echo "done"
echo

echo "# ===== TERMINATE VPS ====="
echo "for v in $VPS_LIST; do"
echo "  lxc stop \$v"
echo "  lxc delete \$v"
echo "done"
