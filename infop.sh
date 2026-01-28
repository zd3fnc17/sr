#!/bin/bash

# ======================
# Basic info
# ======================
hostnameip=$(hostname -I | awk '{print $1}')
servername=$(hostname)
username=$(whoami)

# ======================
# SSH port dari sshd_config
# ======================
portssh=$(grep -Ei '^[[:space:]]*Port[[:space:]]+' /etc/ssh/sshd_config \
  | awk '{print $2}' | tail -n 1)
portssh=${portssh:-22}

# ======================
# LXD port dari config
# ======================
lxd_addr=$(lxc config get core.https_address 2>/dev/null)
portlxd=$(echo "$lxd_addr" | awk -F: '{print $NF}')

# ======================
# CPU
# ======================
cpucore=$(nproc)
cpuname=$(awk -F: '/model name/ {print $2; exit}' /proc/cpuinfo | sed 's/^ //')

# ======================
# Memory (GB)
# ======================
memorytotal=$(free -g | awk '/Mem:/ {print $2}')

# ======================
# Storage total (GB, semua disk fisik, tanpa loop)
# ======================
storage=$(lsblk -bd -e 7 -o SIZE | awk '{sum+=$1} END {printf "%.0f", sum/1024/1024/1024}')

# ======================
# Output utama
# ======================
echo "Output tinggal copas:"

echo "hostnameip=$hostnameip"
echo "servername=$servername"
echo "cpucore=$cpucore"
echo "storage=$storage"
echo "portssh=$portssh"
echo "portlxd=$portlxd"
echo "username=$username"
echo "memorytotal=$memorytotal"
echo "cpuname=$cpuname"
echo

# ======================
# Authorized SSH Keys
# ======================
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
        if (comment == "") comment="(no comment)"
        print "- " comment
    }
    ' "$AUTH_KEYS"
else
    echo "- (authorized_keys tidak ditemukan)"
fi
