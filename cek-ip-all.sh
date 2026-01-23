#!/bin/bash

HOST_IP=$(hostname -I | awk '{print $1}')

lxc list --format csv -c n | while read c; do
  lxc config device list "$c" | while read dev; do
    TYPE=$(lxc config device get "$c" "$dev" type 2>/dev/null)
    [ "$TYPE" != "proxy" ] && continue

    LISTEN=$(lxc config device get "$c" "$dev" listen)
    [ -z "$LISTEN" ] && continue

    PORT=${LISTEN##*:}

    printf "%s %s:%s %s\n" "$c" "$HOST_IP" "$PORT" "$dev"
  done
done
