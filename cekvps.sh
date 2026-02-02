#!/bin/bash
# DESC: Smart VPS proxy checker (incremental cache, first-build safe)

CACHE_FILE="/home/ubuntu/cache/lxd-proxy-index.tsv"
CACHE_DIR="$(dirname "$CACHE_FILE")"
HOST_IP=$(hostname -I | awk '{print $1}')
NOW="$(date '+%Y-%m-%d %H:%M:%S')"

########################################
# HELP
########################################
show_help() {
  cat <<EOF
Cek VPS Proxy (incremental cache)

Usage:
  ./cekvps.sh -all
      Tampilkan semua VPS + IP:PORT + STATUS + PROXY

  ./cekvps.sh -p
      Output ringkas: namavps=ip:port

  ./cekvps.sh <nama-vps>
      Tampilkan IP:PORT untuk VPS tertentu

  ./cekvps.sh -h
      Tampilkan bantuan
EOF
  exit 0
}

########################################
# ARGUMENT
########################################
MODE="$1"
[ -z "$MODE" ] && show_help
[ "$MODE" = "-h" ] && show_help

########################################
# LIVE VPS LIST
########################################
mapfile -t VPS_ARRAY < <(lxc list --format csv -c n | sort)
LIVE_VPS_LIST=$(printf "%s," "${VPS_ARRAY[@]}" | sed 's/,$//')

########################################
# CACHE INIT
########################################
mkdir -p "$CACHE_DIR"

FIRST_BUILD=0
if [ ! -f "$CACHE_FILE" ]; then
  FIRST_BUILD=1
  echo "Cache belum ada → build awal"
  : > "$CACHE_FILE"
fi

########################################
# READ CACHE VPS LIST
########################################
CACHE_VPS_ARRAY=()

if [ "$FIRST_BUILD" -eq 0 ]; then
  CACHE_VPS_LIST=$(grep '^# VPS_LIST=' "$CACHE_FILE" | cut -d= -f2)
  IFS=',' read -ra CACHE_VPS_ARRAY <<< "$CACHE_VPS_LIST"
fi

########################################
# DIFF VPS
########################################
VPS_ADDED=()
VPS_REMOVED=()

for v in "${VPS_ARRAY[@]}"; do
  [[ ! " ${CACHE_VPS_ARRAY[*]} " =~ " $v " ]] && VPS_ADDED+=("$v")
done

for v in "${CACHE_VPS_ARRAY[@]}"; do
  [[ ! " ${VPS_ARRAY[*]} " =~ " $v " ]] && VPS_REMOVED+=("$v")
done

########################################
# REMOVE DELETED VPS FROM CACHE
########################################
for v in "${VPS_REMOVED[@]}"; do
  echo "✖ VPS dihapus → $v (hapus cache)"
  awk -F'\t' 'NR<=3 || $5!="'$v'"' \
    "$CACHE_FILE" > "$CACHE_FILE.tmp" && mv "$CACHE_FILE.tmp" "$CACHE_FILE"
done

########################################
# ADD NEW VPS TO CACHE
########################################
for VPS in "${VPS_ADDED[@]}"; do
  echo "➕ Build cache VPS: $VPS"

  lxc config device list "$VPS" | while read dev; do
    type=$(lxc config device get "$VPS" "$dev" type 2>/dev/null)
    [ "$type" != "proxy" ] && continue

    listen=$(lxc config device get "$VPS" "$dev" listen)
    connect=$(lxc config device get "$VPS" "$dev" connect)
    [ -z "$listen" ] || [ -z "$connect" ] && continue

    L_PORT="${listen##*:}"
    C_PORT="${connect##*:}"

    echo -e "0.0.0.0\t$L_PORT\t127.0.0.1\t$C_PORT\t$VPS\t$dev" >> "$CACHE_FILE"
  done
done

########################################
# REWRITE HEADER (FIXED)
########################################
TMP="$CACHE_FILE.tmp"

{
  echo "# UPDATED_AT=$NOW"
  echo "# VPS_LIST=$LIVE_VPS_LIST"
  echo -e "LISTEN_IP\tLISTEN_PORT\tCONNECT_IP\tCONNECT_PORT\tVPS_NAME\tPROXY_NAME"
  awk 'NR>3' "$CACHE_FILE"
} > "$TMP"

mv "$TMP" "$CACHE_FILE"

########################################
# OUTPUT MODE
########################################
case "$MODE" in
  -all)
    printf "%-15s %-22s %-10s %s\n" "VPS_NAME" "IP:PORT" "STATUS" "PROXY"
    echo "---------------------------------------------------------------"

    awk -F'\t' '$2~/^[0-9]+$/{print $5 "|" $2 "|" $6}' "$CACHE_FILE" | \
    xargs -P 20 -n 1 bash -c '
      IFS="|" read VPS PORT PROXY <<< "$0"
      if timeout 1 bash -c "</dev/tcp/127.0.0.1/$PORT" &>/dev/null; then
        STATUS="OPEN"
      else
        STATUS="CLOSED"
      fi
      printf "%-15s %-22s %-10s %s\n" \
        "$VPS" "'"$HOST_IP"':$PORT" "$STATUS" "$PROXY"
    '
    ;;

  -p)
    awk -F'\t' '$2~/^[0-9]+$/{print $5 "=" "'"$HOST_IP"':" $2}' "$CACHE_FILE"
    ;;

  *)
    awk -F'\t' -v vps="$MODE" '$5==vps && $2~/^[0-9]+${
      print vps "\t" "'"$HOST_IP"':" $2
    }' "$CACHE_FILE"
    ;;
esac
