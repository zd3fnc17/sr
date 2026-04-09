#!/bin/bash
# DESC: Smart VPS proxy checker (cache + dual output mode)

CACHE_FILE="/home/ubuntu/cache/lxd-proxy-index.tsv"
CACHE_DIR="$(dirname "$CACHE_FILE")"
HOST_IP=$(hostname -I | awk '{print $1}')
NOW="$(date '+%Y-%m-%d %H:%M:%S')"

########################################
# HELP
########################################
show_help() {
  cat <<EOF
Cek VPS Proxy (berbasis cache)

Usage:
  ./cekvps.sh -all
  ./cekvps.sh -p
  ./cekvps.sh <nama-vps>
  ./cekvps.sh -h
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
# GET VPS LIST
########################################
mapfile -t VPS_ARRAY < <(lxc list --format csv -c n | sort)
LIVE_VPS_LIST=$(printf "%s," "${VPS_ARRAY[@]}" | sed 's/,$//')

########################################
# READ CACHE
########################################
CACHE_VPS_LIST=""
if [ -f "$CACHE_FILE" ]; then
  CACHE_VPS_LIST=$(grep '^# VPS_LIST=' "$CACHE_FILE" | cut -d= -f2)
fi

########################################
# DECIDE REBUILD
########################################
NEED_BUILD=0

if [ ! -f "$CACHE_FILE" ]; then
  NEED_BUILD=1
elif [ "$LIVE_VPS_LIST" != "$CACHE_VPS_LIST" ]; then
  NEED_BUILD=1
fi

########################################
# BUILD CACHE
########################################
if [ "$NEED_BUILD" -eq 1 ]; then
  echo "=== BUILD PROXY CACHE ==="
  echo "Waktu : $NOW"
  echo

  mkdir -p "$CACHE_DIR"

  {
    echo "# UPDATED_AT=$NOW"
    echo "# VPS_LIST=$LIVE_VPS_LIST"
    echo -e "LISTEN_IP\tLISTEN_PORT\tCONNECT_IP\tCONNECT_PORT\tVPS_NAME\tPROXY_NAME"
  } > "$CACHE_FILE"

  TOTAL=${#VPS_ARRAY[@]}
  IDX=1

  for VPS in "${VPS_ARRAY[@]}"; do
    echo "→ ($IDX/$TOTAL) Build cache: $VPS"
    IDX=$((IDX+1))

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

  echo
  echo "Selesai build cache"
  echo
else
  echo "Cache valid (daftar VPS tidak berubah)"
  echo "Rebuild dilewati"
  echo
fi

########################################
# OUTPUT
########################################
case "$MODE" in

########################################
# MODE -all
########################################
-all)

  RESULT=$(
    awk -F'\t' '$2~/^[0-9]+$/{print $5 "|" $2 "|" $6}' "$CACHE_FILE" | \
    xargs -P 20 -n 1 bash -c '
      IFS="|" read VPS PORT PROXY <<< "$0"

      if timeout 1 bash -c "</dev/tcp/127.0.0.1/$PORT" >/dev/null 2>&1; then
        STATUS="OPEN"
      else
        STATUS="CLOSED"
      fi

      printf "%s|%s|%s|%s\n" \
        "$VPS" "'"$HOST_IP"':$PORT" "$STATUS" "$PROXY"
    '
  )

  echo "=== ACTIVE AND STOP ==="
  printf "%-15s %-22s %-10s %s\n" "VPS_NAME" "IP:PORT" "STATUS" "PROXY"
  echo "---------------------------------------------------------------"

  echo "$RESULT" | while IFS="|" read VPS IP STATUS PROXY; do
    printf "%-15s %-22s %-10s %s\n" "$VPS" "$IP" "$STATUS" "$PROXY"
  done

  echo

  echo "=== ACTIVE ONLY ==="
  printf "%-15s %-22s %-10s %s\n" "VPS_NAME" "IP:PORT" "STATUS" "PROXY"
  echo "---------------------------------------------------------------"

  echo "$RESULT" | while IFS="|" read VPS IP STATUS PROXY; do
    [ "$STATUS" != "OPEN" ] && continue
    printf "%-15s %-22s %-10s %s\n" "$VPS" "$IP" "$STATUS" "$PROXY"
  done
  ;;

########################################
# MODE -p
########################################
-p)

  RESULT=$(
    awk -F'\t' '$2~/^[0-9]+$/{print $5 "|" $2}' "$CACHE_FILE" | \
    xargs -P 20 -n 1 bash -c '
      IFS="|" read VPS PORT <<< "$0"

      if timeout 1 bash -c "</dev/tcp/127.0.0.1/$PORT" >/dev/null 2>&1; then
        STATUS="OPEN"
      else
        STATUS="CLOSED"
      fi

      printf "%s|%s|%s\n" \
        "$VPS" "'"$HOST_IP"':$PORT" "$STATUS"
    '
  )

  echo "=== ACTIVE AND STOP ==="
  echo "$RESULT" | while IFS="|" read VPS IP STATUS; do
    echo "$VPS=$IP"
  done

  echo

  echo "=== ACTIVE ONLY ==="
  echo "$RESULT" | while IFS="|" read VPS IP STATUS; do
    [ "$STATUS" != "OPEN" ] && continue
    echo "$VPS=$IP"
  done
  ;;

########################################
# MODE specific VPS
########################################
*)
  awk -F'\t' -v vps="$MODE" '$5==vps && $2~/^[0-9]+${
    print vps "\t" "'"$HOST_IP"':" $2
  }' "$CACHE_FILE"
  ;;
esac
