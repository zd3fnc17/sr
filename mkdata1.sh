#!/bin/bash
set -e

# ===== GLOBAL DEFAULT CONFIG =====
TEMPLATE="digios6-data1"
POOL="data1"
CONNECT_PORT=6112

# ===== HELP =====
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  cat <<'EOF'

panduan langsung belum tersedia
bisa langsung tanya pada discord

EOF
  exit 0
fi

# ===== VALIDASI INPUT =====
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "❌ GAGAL: Parameter kurang"
  echo "Gunakan -h untuk bantuan"
  exit 1
fi

PAKET="$1"
VPS="$2"

# ===== LOG PROGRESS =====
echo "▶️ Membuat \"$VPS\" | Paket: $PAKET | Storage: $POOL"

# ===== KONFIGURASI PAKET =====
case "$PAKET" in
  standard)
    CPU=2          # dulu 1 core
    CPU_ALLOW=50%
    RAM=2001MB
    DISK=30GB
    ;;
  prime)
    CPU=2          # dulu 1 core
    CPU_ALLOW=50%
    RAM=4002MB
    DISK=50GB
    ;;
  elite)
    CPU=4          # dulu 2 core
    CPU_ALLOW=50%
    RAM=6003MB
    DISK=60GB
    ;;
  supreme)
    CPU=4          # dulu 2 core
    CPU_ALLOW=50%
    RAM=8004MB
    DISK=70GB
    ;;
  royal)
    CPU=6          # dulu 3 core
    CPU_ALLOW=50%
    RAM=10005MB
    DISK=80GB
    ;;
  *)
    echo "❌ GAGAL: Paket \"$PAKET\" tidak dikenal"
    exit 1
    ;;
esac

# ===== VALIDASI NAMA VPS (PORT DARI 4 DIGIT TERAKHIR) =====
NUMBERS=$(echo "$VPS" | grep -o '[0-9]*$')

if [ -z "$NUMBERS" ]; then
  echo "❌ GAGAL: Nama VPS harus diakhiri angka"
  exit 1
fi

if [ ${#NUMBERS} -lt 4 ]; then
  echo "❌ GAGAL: Angka di akhir nama VPS kurang dari 4 digit ($NUMBERS)"
  exit 1
fi

PORT=${NUMBERS: -4}

# ===== JIKA PORT DIAWALI 0 =====
if [[ "$PORT" == 0* ]]; then
  PORT="1${PORT:1}"
fi

# ===== CEK PORT =====
if ss -lnt | awk '{print $4}' | grep -q ":$PORT$"; then
  echo "❌ GAGAL: Port $PORT sudah digunakan"
  exit 1
fi

# ===== PROVISIONING =====
lxc copy "$TEMPLATE" "$VPS" --storage "$POOL"

lxc config set "$VPS" limits.cpu "$CPU"
lxc config set "$VPS" limits.cpu.allowance "$CPU_ALLOW"
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
echo "VPS       : $VPS"
echo "PAKET     : $PAKET"
echo "TEMPLATE  : $TEMPLATE"
# echo "CPU       : $CPU core (50%)"
echo "RAM       : $RAM"
echo "DISK      : $DISK"
echo "STORAGE   : $POOL"
echo "VNC       : $IP:$PORT"
echo "================================="
