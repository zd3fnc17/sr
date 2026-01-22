#!/bin/bash

set -e

# ===== VALIDASI INPUT =====
if [ -z "$1" ]; then
  echo "Usage: $0 <nama-vps> [storage]"
  exit 1
fi

VPS=$1
POOL=${2:-default}

# ===== LOG PROGRESS =====
echo "▶️ Sedang memperjuangkan VPS \"$VPS\"... mohon bersabar"

# ===== KONFIGURASI DEFAULT =====
TEMPLATE=digios-5
CPU=1
RAM=2001MB
DISK=30GB
CONNECT_PORT=6112

# ===== AMBIL 3 DIGIT TERAKHIR UNTUK PORT =====
SUFFIX=$(echo "$VPS" | grep -o '[0-9]*$' | tail -c 4)

if [ -z "$SUFFIX" ]; then
  echo "❌ Nama VPS wajib diakhiri angka"
  exit 1
fi

PORT=6$SUFFIX

# ===== PROVISIONING =====
lxc copy "$TEMPLATE" "$VPS" --storage "$POOL"

lxc config set "$VPS" limits.cpu "$CPU"
lxc config set "$VPS" limits.memory "$RAM"
lxc config device set "$VPS" root size="$DISK"

IP=$(ip route get 1.1.1.1 | awk '{print $7; exit}')

lxc config device add "$VPS" vnc proxy \
listen=tcp:0.0.0.0:$PORT \
connect=tcp:127.0.0.1:$CONNECT_PORT

lxc start "$VPS"

# ===== OUTPUT AKHIR =====
echo "================================="
echo "🎉 VPS BERHASIL DIBUAT!"
echo "VPS      : $VPS"
echo "TEMPLATE : $TEMPLATE"
echo "STORAGE  : $POOL"
echo "CPU      : $CPU core"
echo "RAM      : $RAM"
echo "DISK     : $DISK"
echo "VNC      : $IP:$PORT"
echo "================================="
