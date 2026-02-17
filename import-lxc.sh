#!/bin/bash

TARGET_DIR="$HOME/pindah"

# Ambil IPv4 utama server (bukan 127.0.0.1)
SERVER_IP=$(hostname -I | awk '{print $1}')

if [ -z "$SERVER_IP" ]; then
    echo "Gagal mendeteksi IPv4 server."
    exit 1
fi

# Cek parameter
if [ $# -eq 0 ]; then
    echo "Usage: $0 vps1.tar.gz vps2.tar.gz ..."
    exit 1
fi

for FILE_INPUT in "$@"
do
    FILE_PATH="$TARGET_DIR/$FILE_INPUT"

    if [ ! -f "$FILE_PATH" ]; then
        echo "FILE TIDAK DITEMUKAN: $FILE_INPUT"
        echo ""
        continue
    fi

    echo "===================================="
    echo "Importing: $FILE_INPUT"
    echo "------------------------------------"

    # Import container
    lxc import "$FILE_PATH"

    if [ $? -ne 0 ]; then
        echo "FAILED: Import $FILE_INPUT gagal"
        echo ""
        continue
    fi

    VPS_NAME="${FILE_INPUT%.tar.gz}"

    sleep 2

    # Ambil port forwarding bernama "vnc"
    VNC_PORT=$(lxc config device show "$VPS_NAME" | awk '
        /vnc:/ {flag=1}
        flag && /listen:/ {
            split($2,a,":");
            print a[length(a)];
            flag=0
        }
    ')


    echo ""
    echo "VPS telah berhasil di import:"
    echo "$VPS_NAME dengan ip ${SERVER_IP}:${VNC_PORT}"
    echo "===================================="
    echo ""
done

echo "Semua proses import selesai."
