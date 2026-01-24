#!/bin/bash

OS_VERSION="digios7"
CHECK_VPS="digios7-data1"

ARCHIVE_URL="https://srv.sgp1.cdn.digitaloceanspaces.com/masterlxd/${OS_VERSION}.tar.gz"
STORAGE_POOLS=("data1" "data2" "data3" "data4")

# ===== LIST MASTER OS LAMA YANG MAU DIBERSIHKAN =====
CLEANUP_INSTANCES=(
    "digios5-data1"
    "digios5-data2"
    "digios6-data1"
    "digios6-data2"
)

WORKDIR="$HOME/masteros"
ARCHIVE_FILE="${OS_VERSION}.tar.gz"

# ===== CEK MASTER OS BARU (HARD STOP) =====
if lxc info "$CHECK_VPS" >/dev/null 2>&1; then
    echo "ℹ️  Master OS $OS_VERSION sudah ada ($CHECK_VPS)."
    echo "⛔ Tidak ada proses yang dijalankan."
    exit 0
fi

# ===== MASTER OS BELUM ADA =====
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

# ===== BERSIH-BERSIH SETELAH MASTER BARU ADA =====
echo
echo "🧹 Mulai proses bersih-bersih Master OS lama..."

for INSTANCE in "${CLEANUP_INSTANCES[@]}"; do
    if lxc info "$INSTANCE" >/dev/null 2>&1; then
        echo "▶️  Menghapus instance $INSTANCE ..."
        if lxc delete "$INSTANCE" --force; then
            echo "✅ $INSTANCE berhasil dihapus"
        else
            echo "⚠️  Gagal menghapus $INSTANCE"
        fi
    else
        echo "ℹ️  $INSTANCE tidak ada (sudah bersih)"
    fi
done

echo "🧹 Bersih-bersih selesai."
echo

echo "🏁 Proses selesai."
