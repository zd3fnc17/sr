#!/bin/bash

HOST_IP=$(hostname -I | awk '{print $1}')

show_help() {
  cat <<EOF
Usage:
  $0 IP:PORT [IP:PORT ...]
  $0 -f file.txt

Contoh:
  $0 103.1.1.1:8080 103.1.1.2:8443
  $0 -f ports.txt
EOF
  exit 0
}

[ -z "$1" ] && show_help

# ambil target
TARGETS=()

if [ "$1" = "-f" ]; then
  [ -z "$2" ] && echo "File tidak ada" && exit 1
  while read line; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    TARGETS+=("$line")
  done < "$2"
else
  TARGETS=("$@")
fi

declare -A MATCHED

# scan semua VPS sekali
lxc list --format csv -c n | while read VPS; do
  lxc config device list "$VPS" | while read dev; do
    TYPE=$(lxc config device get "$VPS" "$dev" type 2>/dev/null)
    [ "$TYPE" != "proxy" ] && continue

    LISTEN=$(lxc config device get "$VPS" "$dev" listen)
    [ -z "$LISTEN" ] && continue

    IP="${LISTEN##*://}"
    IP="${IP%%:*}"
    PORT="${LISTEN##*:}"

    [ -z "$IP" ] && IP="$HOST_IP"

    for t in "${TARGETS[@]}"; do
      if [ "$t" = "$IP:$PORT" ]; then
        MATCHED["$VPS"]=1
      fi
    done
  done
done

# output bash loop
if [ "${#MATCHED[@]}" -eq 0 ]; then
  echo "# Tidak ada VPS yang cocok"
  exit 0
fi

echo "for v in ${!MATCHED[@]}; do"
echo "  lxc stop \$v"
echo "  lxc config set \$v boot.autostart false"
echo "done"
