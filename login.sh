#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <nama-container>"
  exit 1
fi

CONTAINER="$1"
USER="admin"

lxc exec "$CONTAINER" -- su - "$USER"
