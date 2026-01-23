#!/bin/bash
# DESC: untuk login ke server

#!/bin/bash
# DESC: login ke server LXC


CONTAINER="$1"
USER="admin"

lxc exec -t "$CONTAINER" -- su - "$USER"




if [ -z "$1" ]; then
  echo "Usage: $0 <nama-container>"
  exit 1
fi

CONTAINER="$1"
USER="admin"

lxc exec -t "$CONTAINER" -- su - "$USER"
