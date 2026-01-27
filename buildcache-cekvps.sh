#!/bin/bash
# DESC: Build cache proxy LXD lalu cek status semua port proxy

CACHE_FILE="/home/ubuntu/cache/lxd-proxy-index.tsv"
CACHE_DIR="$(dirname "$CACHE_FILE")"
HOST_IP=$(hostname -I | awk '{print $1}')
NOW="$(date '+%Y-%m-%d %H:%M:%S')"
COUNT=0

########################################
# STEP 1 — BUILD CACHE
########################################
mkdir -p "$CACHE_DIR"

echo "=== BUILD PROXY CACHE ==="
echo "Target : $CACHE_FILE"
echo "Waktu  : $NOW"
echo

{
  echo "# PROXY_CACHE_FILE=$CACHE_FILE"
  echo "# UPDATED_AT=$NOW"
  echo "# FORMAT=LISTEN_IP LISTEN_PORT CONNECT_IP CONNECT_PORT VPS_NAME PROXY_NAME"
  echo -e "LISTEN_IP\tLISTEN_PORT\tCONNECT_IP\tCONNECT_PORT\tVPS_NAME\tPROXY_NAME"
} > "$CACHE_FILE"

VPS_LIST=$(lxc list --format csv -c n)

for VPS in $VPS_LIST; do
  DEV_LIST=$(lxc config device list "$VPS")
  for dev in $DEV_LIST; do
    TYPE=$(lxc config device get "$VPS" "$dev" type 2>/dev/null)
    [ "$TYPE" != "proxy" ] && continue

    LISTEN=$(lxc config device get "$VPS" "$dev" listen)
    CONNECT=$(lxc config device get "$VPS" "$dev" connect)

    [ -z "$LISTEN" ] && continue
    [ -z "$CONNECT" ] && continue

    L_RAW="${LISTEN##*://}"
    L_IP="${L_RAW%%:*}"
    L_PORT="${L_RAW##*:}"
    [ -z "$L_IP" ] && L_IP="tcp"

    C_RAW="${CONNECT##*://}"
    C_IP="${C_RAW%%:*}"
    C_PORT="${C_RAW##*:}"

    echo -e "$L_IP\t$L_PORT\t$C_IP\t$C_PORT\t$VPS\t$dev" >> "$CACHE_FILE"
    COUNT=$((COUNT+1))
  done
done

echo "Cache selesai dibangun"
echo "Total entry: $COUNT"
echo

########################################
# STEP 2 — CHECK ALL PORTS
########################################
printf "%-15s %-22s %-10s %s\n" "VPS_NAME" "IP:PORT" "STATUS" "PROXY"
echo "---------------------------------------------------------------"

awk -F'\t' '
  $0 !~ /^#/ &&
  $2 ~ /^[0-9]+$/ {
    print $5 "\t" $2 "\t" $6
  }
' "$CACHE_FILE" | while IFS=$'\t' read -r VPS PORT PROXY; do

  if timeout 2 bash -c "</dev/tcp/127.0.0.1/$PORT" >/dev/null 2>&1; then
    STATUS="OPEN"
  else
    STATUS="CLOSED"
  fi

  printf "%-15s %-22s %-10s %s\n" \
    "$VPS" "$HOST_IP:$PORT" "$STATUS" "$PROXY"
done
