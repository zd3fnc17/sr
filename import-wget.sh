#!/bin/bash

TARGET_DIR="$HOME/pindah"

# 1. Cek apakah folder ada, kalau tidak buat
if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
fi

# 2. Cek apakah ada argumen link
if [ "$#" -eq 0 ]; then
    echo "Gunakan: $0 link1 link2 link3 ..."
    exit 1
fi

# 3. Download semua link ke folder pindah
for url in "$@"; do
    echo "Downloading: $url"
    wget -P "$TARGET_DIR" "$url"
done

echo ""
echo "=== Daftar File di $TARGET_DIR ==="

# 4. Tampilkan tabel urut berdasarkan tanggal (terbaru dulu)
printf "%-30s %-20s\n" "NAMA FILE" "TANGGAL"
echo "-------------------------------------------------------------"

ls -lt --time-style=long-iso "$TARGET_DIR" | awk 'NR>1 {
    printf "%-30s %-20s\n", $8, $6" "$7
}'
