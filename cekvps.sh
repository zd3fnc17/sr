#!/bin/bash
# DESC: Smart proxy cache checker (VPS FP + Proxy FP)

CACHE_FILE="/home/ubuntu/cache/lxd-proxy-index.tsv"
CACHE_DIR="$(dirname "$CACHE_FILE")"
HOST_IP=$(hostname -I | awk '{print $1}')
NOW="$(date '+%Y-%m-%d %H:%M:%S')"

########################################
# FINGERPRINT FUNCTIONS
########################################

calc_vps_fp() {
  lxc list --format csv -c n | sort | sha1sum | awk '{print $1}'
}

calc_proxy_fp() {
  lxc list --format csv -c n | sort | while read VPS; do
    lxc config device list "$VPS" | sort | while read dev; do
      type=$(lxc config device get "$VPS" "$dev" type 2>/dev/null)
      [ "$type" != "proxy" ] && continue
      listen=$(lxc config device get "$VPS" "$dev" listen)
      connect=$(lxc config device get "$VPS" "$dev" connect)
      echo "$VPS|$dev|$listen|$connect"
    done
  done | sha1sum | awk '{print $1}'
}

########################################
# READ CACHE METADATA
########################################

CACHE_VPS_FP=""
CACHE_PROXY_FP=""

if [ -f "$CACHE_FILE" ]; then
  CACHE_VPS_FP=$(grep '^# VPS_FINGERPRINT=' "$CACHE_FILE" | cut -d= -f2)
  CACHE_PROXY_FP=$(grep '^# PROXY_FINGERPRINT=' "$CACHE_FILE" | cut -d= -f2)
fi

########################################
# DECISION LOGIC
########################################

LIVE_VPS_FP=$(calc_vps_fp)

NEED_BUILD=0

if [ ! -f "$CACHE_FILE" ]; then
  NEED_BUILD=1
elif [ "$LIVE_VPS_FP" != "$CACHE_VPS_FP" ]; then
  NEED_BUILD=1
else
  LIVE_PROXY_FP=$(calc_proxy_fp)
  [ "$LIVE_PROXY_FP" != "$CACHE_PROXY_FP" ] && NEED_BUILD=1
fi

########################################
# BUILD CACHE (IF NEEDED)
########################################

if [ "$NEED_BUILD" -eq 1 ]; then
  echo "=== BUILD PROXY CACHE ==="
  mkdir -p "$CACHE_DIR"

  LIVE_PROXY_FP=$(calc_proxy_fp)

  {
    echo "# PROXY_CACHE_FILE=$CACHE_FILE"
    echo "# UPDATED_AT=$NOW"
    echo "# VPS_FINGERPRINT=$LIVE_VPS_FP"
    echo "# PROXY_FINGERPRINT=$LIVE_PROXY_FP"
    echo "# FORMAT=LISTEN_IP LISTEN_PORT CONNECT_IP CONNECT_PORT VPS_NAME PROXY_NAME"
    echo -e "LISTEN_IP\tLISTEN_PORT\tCONNECT_IP\tCONNECT_PORT\tVPS_NAME\tPROXY_NAME"
  } > "$CACHE_FILE"

  COUNT=0
  lxc list --format csv -c n | while read VPS; do
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

  echo "Cache rebuilt ($COUNT entries)"
  echo
else
  echo "Cache masih valid — rebuild dilewati"
  echo
fi

########################################
# DISPLAY PORT STATUS
########################################

printf "%-15s %-22s %-10s %s\n" "VPS_NAME" "IP:PORT" "STATUS" "PROXY"
echo "---------------------------------------------------------------"

awk -F'\t' '
  $0 !~ /^#/ && $2 ~ /^[0-9]+$/ {
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
