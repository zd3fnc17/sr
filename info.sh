#!/bin/bash

HOSTNAME=$(hostname)
IP=$(hostname -I | awk '{print $1}')

# Port dari sshd_config (belum tentu aktif)
SSH_PORT_CONFIG=$(grep -Ei '^[[:space:]]*Port[[:space:]]+' /etc/ssh/sshd_config \
  | awk '{print $2}' | tail -n 1)
SSH_PORT_CONFIG=${SSH_PORT_CONFIG:-22}

# Port SSH yang sedang berjalan
SSH_PORT_RUNNING=$(sshd -T 2>/dev/null | awk '/^port / {print $2}')
SSH_PORT_RUNNING=${SSH_PORT_RUNNING:-22}

# CPU info
CPU_NAME=$(awk -F: '/model name/ {print $2; exit}' /proc/cpuinfo | sed 's/^ //')
CPU_CORES=$(nproc)

# RAM info
RAM_TOTAL_MB=$(free -m | awk '/Mem:/ {print $2}')
RAM_TOTAL_GB=$(awk "BEGIN {printf \"%.2f\", $RAM_TOTAL_MB/1024}")

echo "Hostname        : $HOSTNAME"
echo "IP Addr         : $IP"
echo "SSH Port Config : $SSH_PORT_CONFIG"
echo "SSH Port Active : $SSH_PORT_RUNNING"
echo
echo "CPU Name        : $CPU_NAME"
echo "CPU Cores       : $CPU_CORES"
echo "Total RAM       : ${RAM_TOTAL_GB} GB"
echo

# Disk hardware info
echo "Disk Hardware:"
lsblk -d -o NAME,SIZE,MODEL | sed 1d | while read -r name size model; do
    echo "- /dev/$name : $size ${model:-"(unknown)"}"
done
echo

# Authorized keys
AUTH_KEYS="$HOME/.ssh/authorized_keys"
echo "Authorized SSH Public Keys (comments):"

if [[ -f "$AUTH_KEYS" ]]; then
    awk '
    /^[[:space:]]*#/ {next}
    NF < 2 {next}
    {
        comment=""
        for (i=3; i<=NF; i++) {
            comment = comment $i (i<NF ? " " : "")
        }
        if
