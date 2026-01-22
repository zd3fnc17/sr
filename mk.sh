#!/bin/bash

set -e

# ===== HELP (DUMMY) =====
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  cat <<'EOF'
CARA MENGGUNAKAN:
--------------
./mk <namavps> <namapaket> <data>
--------------
apabila ingin menggunakan data1, maka boleh tidak ditulis "data1" 
EOF
  exit 0
fi

# ===== VALIDASI INPUT =====
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "❌ GAGAL: Parameter kurang"
  echo "Gunakan -h untuk bantuan"
  exit 1
fi

VPS=$1
PAKET=$2
POOL=${3:-default}

# ===== LOG PROGRESS =====
echo "▶️ Sedang memperjuangkan VPS \"$VPS\" (paket: $PAKET)... mohon bersabar"

# ===== TEMPLATE & KONFIGURASI UMUM =====
TEMPLATE=digios-5
CONNECT_PORT=6112

# ===== KONFIGURASI PAKET =====
case "$PAKET" in

  standard)
    CPU=1
    RAM=2001MB
    DISK=30GB
    ;;

  prime)
    CPU=1
    RAM=4002MB
    DISK=50GB
    ;;

  elite)
    CPU=2
    RAM=6003MB
    DISK=60GB
    ;;

  supreme)
    CPU=2
    RAM=8004MB
    DISK=70GB
    ;;

  royal)
    CPU=3
    RAM=10005MB
    DISK=80GB
    ;;

  *)
    echo "❌ GAGAL: Paket \"$PAKET\" tidak dikenal"
    exit 1
    ;;

esac

# ===== AMBIL ANGKA TERAKHIR DARI NAMA VPS =====
NUMBERS=$(echo "$VPS" | grep -o '[0-9]*$')

if [ -z "$NUMBERS" ]; then
  echo "❌ GAGAL: Nama VPS tidak mengandung angka di bagian akhir"
  exit 1
fi

if [ ${#NUMBERS} -lt 4 ]; then
  echo "❌ GAGAL: Angka di akhir nama VPS kurang dari 4 digit ($NUMBERS)"
  exit 1
fi

PORT=${NUMBERS: -4}

# ===== CEK PORT =====
if ss -lnt | awk '{print $4}' | grep -q ":$PORT$"; then
  echo "❌ GAGAL: Port $PORT sudah digunakan"
  exit 1
fi

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
echo "PAKET    : $PAKET"
echo "CPU      : $CPU core"
echo "RAM      : $RAM"
echo "DISK     : $DISK"
echo "STORAGE  : $POOL"
echo "VNC      : $IP:$PORT"
echo "================================="
