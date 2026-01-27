#!/bin/bash

if [ "$#" -eq 0 ]; then
  echo "❌ Tidak ada container yang diberikan"
  echo "👉 Contoh: ~/sr/terminate.sh vps1 vps2"
  exit 1
fi

echo "⚠️  PERINGATAN"
echo "Tindakan ini akan MENGHAPUS container berikut:"
echo "👉 $*"
echo

read -p "Lanjutkan? (y/n): " confirm
case "$confirm" in
  y|Y)
    echo
    echo "🚀 Proses dimulai..."
    echo "============================="
    ;;
  *)
    echo "❌ Dibatalkan oleh user"
    exit 0
    ;;
esac

for v in "$@"; do
  if ! lxc info "$v" >/dev/null 2>&1; then
    echo "❌ $v : container tidak ditemukan"
    echo "-----------------------------"
    continue
  fi

  echo "➡️  $v : proses stop..."
  lxc stop "$v" 2>/dev/null || echo "ℹ️  $v : sudah dalam kondisi stop"

  echo "🗑️  $v : proses hapus..."
  if lxc delete "$v"; then
    echo "✅  $v : berhasil dihapus"
  else
    echo "❌  $v : gagal dihapus"
  fi

  echo "-----------------------------"
done
