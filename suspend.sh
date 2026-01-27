#!/bin/bash

if [ "$#" -eq 0 ]; then
  echo "❌ Tidak ada vps yang diberikan"
  echo "👉 Contoh: ~/sr/suspend.sh vps1 vps2"
  exit 1
fi

echo "⚠️  PERINGATAN"
echo "Tindakan ini akan melakukan SUSPEND vps berikut:"
echo "👉 $*"
echo

read -p "Lanjutkan? (y/n): " confirm
case "$confirm" in
  y|Y)
    echo
    echo "🚀 Proses suspend dimulai..."
    echo "============================="
    ;;
  *)
    echo "❌ Dibatalkan oleh user"
    exit 0
    ;;
esac

for v in "$@"; do
  if ! lxc info "$v" >/dev/null 2>&1; then
    echo "❌ $v : vps tidak ditemukan"
    echo "-----------------------------"
    continue
  fi

  echo "➡️  $v : proses stop..."
  lxc stop "$v" 2>/dev/null || echo "ℹ️  $v : sudah dalam kondisi stop"

  echo "⚙️  $v : set boot.autostart = false..."
  lxc config set "$v" boot.autostart false

  echo "✅  $v : suspend selesai"
  echo "-----------------------------"
done
