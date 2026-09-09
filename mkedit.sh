#!/bin/bash

# ==============================
# mkedit.sh - LXD Resource Editor
# ==============================

show_help() {
  echo ""
  echo "LXD Resource Editor (mkedit.sh)"
  echo ""
  echo "Usage:"
  echo "  ~/sr/mkedit.sh <paket> CONTAINER1 [CONTAINER2 ...]"
  echo ""
  echo "Contoh:"
  echo "  ~/sr/mkedit.sh royal web1 web2"
  echo ""
  echo "Paket tersedia:"
  echo "  standard  - 1 CPU, 1024MB RAM, 30GB Disk"
  echo "  prime     - 1 CPU, 2048MB RAM, 40GB Disk"
  echo "  elite     - 2 CPU, 3072MB RAM, 50GB Disk"
  echo "  supreme   - 2 CPU, 4096MB RAM, 60GB Disk"
  echo "  royal     - 3 CPU, 5120MB RAM, 70GB Disk"
  echo ""
  exit 0
}

# ==============================
# Handle help flag
# ==============================

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  show_help
fi

# Minimal argumen
if [ $# -lt 2 ]; then
  show_help
fi

PLAN=$1
shift

# ==============================
# Daftar Paket
# ==============================

case "$PLAN" in

  standard)
    CPU=1
    RAM=1024MB
    DISK=30GB
    ;;

  prime)
    CPU=1
    RAM=2048MB
    DISK=40GB
    ;;

  elite)
    CPU=2
    RAM=3072MB
    DISK=50GB
    ;;

  supreme)
    CPU=2
    RAM=4096MB
    DISK=60GB
    ;;

  royal)
    CPU=3
    RAM=5120MB
    DISK=70GB
    ;;

  *)
    echo ""
    echo "Paket '$PLAN' tidak ditemukan."
    echo "Gunakan -h untuk melihat daftar paket."
    echo ""
    exit 1
    ;;
esac

# ==============================
# Eksekusi ke semua container
# ==============================

for CT in "$@"; do
  echo "====================================="
  echo "Mengubah container $CT ke paket: $PLAN"
  echo "CPU  : $CPU core"
  echo "RAM  : $RAM"
  echo "DISK : $DISK"
  echo "====================================="

  lxc config set "$CT" limits.cpu "$CPU"
  lxc config set "$CT" limits.memory "$RAM"
  lxc config device set "$CT" root size "$DISK"

  echo "Selesai untuk $CT"
  echo ""
done

echo "Semua container selesai diproses."
