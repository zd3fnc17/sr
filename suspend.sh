#!/bin/bash

if [ "$#" -eq 0 ]; then
  echo "❌ Tidak ada container yang diberikan"
  echo "👉 Contoh: ./suspend.sh vps1 vps2"
  exit 1
fi

for v in "$@"; do
  if ! lxc info "$v" >/dev/null 2>&1; then
    echo "❌ $v : container tidak ditemukan"
    echo "-----------------------------"
    continue
  fi

  echo "➡️  $v : proses stop..."
  lxc stop "$v" 2>/dev/null || echo "ℹ️  $v : sudah dalam kondisi stop"

  echo "⚙️  $v : set boot.autostart = false..."
  lxc config set "$v" boot.autostart false

  echo "✅  $v : selesai"
  echo "-----------------------------"
done
