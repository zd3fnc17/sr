#!/bin/bash
# DESC: Proxy cache checker (VPS-name based, fast, with progress)

CACHE_FILE="/home/ubuntu/cache/lxd-proxy-index.tsv"
CACHE_DIR="$(dirname "$CACHE_FILE")"
HOST_IP=$(hostname -I | awk '{print $1}')
NOW="$(date '+%Y-%m-%d %H:%M:%S')"

########################################
# GET LIVE VPS LIST (LIGHT)
########################################
mapfile -t VPS_ARRAY < <(lxc list --format csv -c n | sort)
LIVE_VPS_LIST=$(printf "%s," "${VPS_ARRAY[@]}" | sed 's/,$//')

########################################
# READ CACHE VPS LIST
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
# BUILD CACHE (IF NEEDED)
########################################
if [ "$NEED_BUILD" -eq 1 ]; then
  echo "=== BUILD PROXY CACHE ==="
  echo "Waktu : $NOW"
  echo

  mkdir -p "$CACHE_DIR"

  {
    echo "# PROXY_CACHE_FILE=$CACHE_FILE"
    echo "# UPDATED_AT=$NOW"
    echo "# VPS_LIST=$LIVE_VPS_LIST"
    echo "# FORMAT=LISTEN_IP LISTEN_PORT CONNECT_IP CONNECT_PORT VPS_NAME PROXY_NAME"
    echo -e "LISTEN_IP\tLISTEN_PORT\tCONNECT_IP\tCONNECT_PORT\tVPS_NAME\tPROXY_NAME"
  } > "$CACHE_FILE"

  COUNT=0
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

      L_RAW="${listen##*://}"
      L_IP="${L_RAW%%:*}"
      L_PORT="${L_RAW##*:}"

      C_RAW="${connect##*://}"
      C_IP="${C_RAW%%:*}"
      C_PORT="${C_RAW##*:}"

      echo -e "$L_IP\t$L_PORT\t$C_IP\t$C_PORT\t$VPS\t$dev" >> "$CACHE_FILE"
      COUNT=$((COUNT+1))
    done
  done

  echo
  echo "Selesai build cache"
  echo "Total proxy: $COUNT"
  echo
else
  echo "Cache valid (daftar VPS tidak berubah)"
  echo "Rebuild dilewati"
  echo
fi

########################################
# DISPLAY PORT STATUS (PARALLEL)
########################################
printf "%-15s %-22s %-10s %s\n" "VPS_NAME" "IP:PORT" "STATUS" "PROXY"
echo "---------------------------------------------------------------"

awk -F'\t' '
  $0 !~ /^#/ && $2 ~ /^[0-9]+$/ {
    print $5 "|" $2 "|" $6
  }
' "$CACHE_FILE" | \
xargs -P 20 -n 1 bash -c '
  IFS="|" read VPS PORT PROXY <<< "$0"
  if timeout 1 bash -c "</dev/tcp/127.0.0.1/$PORT" >/dev/null 2>&1; then
    STATUS="OPEN"
  else
    STATUS="CLOSED"
  fi
  printf "%-15s %-22s %-10s %s\n" \
    "$VPS" "'"$HOST_IP"':$PORT" "$STATUS" "$PROXY"
'
