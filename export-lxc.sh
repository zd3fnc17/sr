#!/bin/bash

TARGET_DIR="$HOME/pindah"

# Cek parameter
if [ $# -eq 0 ]; then
    echo "Usage: $0 vps1 vps2 vps3 ..."
    exit 1
fi

echo "===================================="
echo "Menyiapkan folder export..."
echo "===================================="

# Hapus folder lama jika ada
rm -rf "$TARGET_DIR"

# Buat folder baru
mkdir -p "$TARGET_DIR"

echo "Folder siap: $TARGET_DIR"
echo ""

# Proses export
for CT in "$@"
do
    FILE="$TARGET_DIR/${CT}.tar.gz"

    echo "===================================="
    echo "Exporting container: $CT"
    echo "Output file        : $FILE"
    echo "------------------------------------"

    lxc export "$CT" "$FILE"

    if [ $? -eq 0 ]; then
        echo "SUCCESS: $CT berhasil di-export menjadi ${CT}.tar.gz"
    else
        echo "FAILED: Export $CT gagal!"
    fi

    echo ""
done

echo "===================================="
echo "Semua proses selesai."
echo "===================================="
echo ""

# Tampilkan tabel hasil
printf "%-25s %-12s %-20s\n" "NAMA FILE" "SIZE" "TANGGAL"
printf "%-25s %-12s %-20s\n" "-------------------------" "--------" "-------------------"

TOTAL_SIZE=0

for FILE in "$TARGET_DIR"/*.tar.gz; do
    [ -e "$FILE" ] || continue
    NAME=$(basename "$FILE")
    SIZE=$(du -h "$FILE" | cut -f1)
    DATE=$(stat -c "%y" "$FILE" | cut -d'.' -f1)
    BYTES=$(stat -c "%s" "$FILE")
    TOTAL_SIZE=$((TOTAL_SIZE + BYTES))

    printf "%-25s %-12s %-20s\n" "$NAME" "$SIZE" "$DATE"
done

# Total size
TOTAL_HUMAN=$(numfmt --to=iec $TOTAL_SIZE 2>/dev/null)

echo ""
echo "Total Size: $TOTAL_HUMAN"
