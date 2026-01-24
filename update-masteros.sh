#!/bin/bash

OS_VERSION="digios6"
CHECK_VPS="digios6-data1"

ARCHIVE_URL="https://srv.sgp1.cdn.digitaloceanspaces.com/masterlxd/${OS_VERSION}.tar.gz"
STORAGE_POOLS=("data1" "data2" "data3" "data4")

WORKDIR="$HOME/masteros"
ARCHIVE_FILE="${OS_VERSION}.tar.gz"

# Cek Master OS (flag)
if lxc info "$CHECK_VPS" >/dev/null 2>&1; then
    echo "ℹ️  Master OS sudah ada ($CHECK_VPS)."
    exit 0
fi

read -p "Master OS $OS_VERSION belum ada. Tambahkan sekarang? (y/n): " confirm
[[ "$confirm" != "y" && "$confirm" != "Y" ]] && exit 0

echo "▶️  Menambahkan Master OS $OS_VERSION..."

mkdir -p "$WORKDIR"
cd "$WORKDIR" || exit 1

wget "$ARCHIVE_URL" || exit 1

for POOL in "${STORAGE_POOLS[@]}"; do
    NAME="${OS_VERSION}-${POOL}"
    echo "▶️  Import ke storage $POOL..."

    if lxc import "$ARCHIVE_FILE" "$NAME" --storage "$POOL"; then
        echo "✅ Berhasil di $POOL"
    else
        echo "⚠️  Gagal di $POOL (kemungkinan storage tidak ada)"
    fi
done

cd ~
rm -rf "$WORKDIR"

echo "🏁 Proses selesai."
