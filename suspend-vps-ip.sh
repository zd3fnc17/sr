#!/bin/bash

show_help() {
  cat <<EOF
Usage:
  $0 IP:PORT [IP:PORT ...]
  $0 -f file.txt
EOF
  exit 0
}

[ -z "$1" ] && show_help

TARGET_PORTS=()

# ambil port dari input
if [ "$1" = "-f" ]; then
  [ -z "$2" ] && echo "File tidak ada" && exit 1
  while read line; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    TARGET_PORTS+=("${line##*:}")
  done < "$2"
else
  for arg in "$@"; do
    TARGET_PORTS+=("${arg##*:}")
  done
fi

declare -A VPS_MATCH

# ambil daftar VPS TANPA pipe
VPS_LIST=$(lxc list --format csv -c n)

for VPS in $VPS_LIST; do
  DEV_LIST=$(lxc config device list "$VPS")
  for dev in $DEV_LIST; do
    TYPE=$(lxc config device get "$VPS" "$dev" type 2>/dev/null)
    [ "$TYPE" != "proxy" ] && continue

    LISTEN=$(lxc config device get "$VPS" "$dev" listen)
    [ -z "$LISTEN" ] && continue

    PORT="${LISTEN##*:}"

    for tp in "${TARGET_PORTS[@]}"; do
      if [ "$PORT" = "$tp" ]; then
        VPS_MATCH["$VPS"]=1
      fi
    done
  done
done

# output
if [ "${#VPS_MATCH[@]}" -eq 0 ]; then
  echo "# Tidak ada VPS yang cocok"
  exit 0
fi

echo "for v in ${!VPS_MATCH[@]}; do"
echo "  lxc stop \$v"
echo "  lxc config set \$v boot.autostart false"
echo "done"
