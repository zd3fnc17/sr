#!/bin/bash

if [ "$#" -eq 0 ]; then
  echo "❌ Tidak ada vps yang diberikan"
  echo "👉 Contoh: ~/sr/unsuspend.sh vps1 vps2"
  exit 1
fi

echo "🚀 Proses UNSUSPEND VPS:"
echo "👉 $*"
echo "============================="

for v in "$@"; do
  if ! lxc info "$v" >/dev/null 2>&1; then
    echo "❌ $v : vps tidak ditemukan"
    echo "-----------------------------"
    continue
  fi

  echo "⚙️  $v : set boot.autostart = true..."
  lxc config set "$v" boot.autostart true

  echo "➡️  $v : proses start..."
  lxc start "$v" 2>/dev/null || echo "ℹ️  $v : sudah dalam kondisi running"

  echo "✅  $v : unsuspend selesai"
  echo "-----------------------------"
done
