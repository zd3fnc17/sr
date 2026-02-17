#!/bin/bash

# ==============================
# mkedit.sh - LXC Resource Editor
# ==============================

# Minimal argumen: paket + minimal 1 CTID
if [ $# -lt 2 ]; then
  echo ""
  echo "Usage:"
  echo "  $0 <paket> CTID1 [CTID2 ...]"
  echo ""
  echo "Contoh:"
  echo "  $0 royal 101 102"
  echo ""
  exit 1
fi

PLAN=$1
shift

# ==============================
# Daftar Paket
# ==============================

case "$PLAN" in

  # ---------- STANDARD ----------
  standard)
    CPU=1
    CPU_ALLOW=1
    RAM=2001
    DISK=30G
    ;;

  # ---------- PRIME ----------
  prime)
    CPU=1
    CPU_ALLOW=1
    RAM=4002
    DISK=50G
    ;;

  # ---------- ELITE ----------
  elite)
    CPU=2
    CPU_ALLOW=2
    RAM=6003
    DISK=60G
    ;;

  # ---------- SUPREME ----------
  supreme)
    CPU=2
    CPU_ALLOW=2
    RAM=8004
    DISK=70G
    ;;

  # ---------- ROYAL ----------
  royal)
    CPU=3
    CPU_ALLOW=3
    RAM=10005
    DISK=80G
    ;;

  # ---------- TAMBAHKAN PAKET BARU DI SINI ----------


  *)
    echo ""
    echo "Paket '$PLAN' tidak ditemukan."
    echo "Silakan cek kembali nama paket."
    echo ""
    exit 1
    ;;

esac


# ==============================
# Eksekusi ke semua CT
# ==============================

for CTID in "$@"; do
  echo "====================================="
  echo "Mengubah CT $CTID ke paket: $PLAN"
  echo "CPU     : $CPU core"
  echo "CPU LIM : $CPU_ALLOW"
  echo "RAM     : ${RAM}MB"
  echo "DISK    : $DISK"
  echo "====================================="

  pct set $CTID -cores $CPU -cpulimit $CPU_ALLOW -memory $RAM
  pct resize $CTID rootfs $DISK

  echo "Selesai untuk CT $CTID"
  echo ""
done

echo "Semua container selesai diproses."
