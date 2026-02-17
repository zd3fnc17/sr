#!/bin/bash

PORT=18001
FOLDER="$HOME/pindah"

# Ambil IPv4 public saja (paksa -4)
PUBLIC_IP=$(curl -4 -s https://ifconfig.me 2>/dev/null)

# Fallback ke IPv4 lokal kalau tidak ada internet
if [ -z "$PUBLIC_IP" ]; then
    PUBLIC_IP=$(hostname -I | tr ' ' '\n' | grep -E '^[0-9]+\.' | head -n1)
fi

echo "--------------------------------------------"
echo "Folder $FOLDER telah di expose ke public."
echo "Silakan akses di browser:"
echo "http://$PUBLIC_IP:$PORT"
echo ""
echo "Tekan CTRL + C untuk menghentikan proses ini"
echo "--------------------------------------------"
echo ""

cd "$FOLDER" || {
    echo "Folder tidak ditemukan!"
    exit 1
}

python3 -m http.server $PORT --bind 0.0.0.0
