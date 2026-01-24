#!/bin/bash

#############################################
# BAGIAN YANG BOLEH DIUBAH
#############################################

OS_VERSION="digios6"
CHECK_VPS="digios6-data1"

ARCHIVE_URL="https://srv.sgp1.cdn.digitaloceanspaces.com/masterlxd/${OS_VERSION}.tar.gz"
STORAGE_POOLS=("data1" "data2" "data3" "data4")

#############################################
# JANGAN DIUBAH
#############################################

WORKDIR="$HOME/masteros"
ARCHIVE_FILE="${OS_VERSION}.tar.gz"

# === CEK MASTER OS ===
if lxc list | awk '{print $1}' | grep -qx "$CHECK_VPS"; then
    echo "ℹ️  Master OS sudah ada ($CHECK_VPS)."
    echo "   Proses tidak dilanjutkan."
    exit 0
fi

read -p "Master OS $OS_VERSION belum ada. Tambahkan sekarang? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "⏹️  Proses dibatalkan."
    exit 0
fi

echo "▶️  Menambahkan Master OS $OS_VERSION..."

mkdir -p "$WORKDIR"
cd "$WORKDIR" || exit 1

wget "$ARCHIVE_URL" || exit 1

for POOL in "${STORAGE_POOLS[@]}"; do
    NAME="${OS_VERSION}-${POOL}"

    if ! lxc storage list | awk '{print $1}' | grep -qx "$POOL"; then
        echo "⚠️  Storage $POOL tidak ada, dilewati."
        continue
    fi

    echo "▶️  Import ke $POOL..."
    lxc import "$ARCHIVE_FILE" "$NAME" --storage "$POOL" || exit 1
done

cd ~
rm -rf "$WORKDIR"

echo "✅ Proses penambahan Master OS selesai."
