#!/bin/bash
# DESC: untuk login ke server

### HELP START ###
show_help() {
  cat << 'EOF'
Cara pakai
 ~/login.sh namavps

Description:
  Login ke container LXC sebagai user admin.

Options:
  -h, --help    Tampilkan help ini
EOF
}
### HELP END ###


if [ -z "$1" ]; then
  echo "Usage: $0 <nama-container>"
  exit 1
fi

CONTAINER="$1"
USER="admin"

lxc exec -t "$CONTAINER" -- su - "$USER"
