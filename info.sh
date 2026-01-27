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

echo "Hostname        : $HOSTNAME"
echo "IP Addr         : $IP"
echo "SSH Port Config : $SSH_PORT_CONFIG"
echo "SSH Port Active : $SSH_PORT_RUNNING"
echo

# Authorized keys
AUTH_KEYS="$HOME/.ssh/authorized_keys"

echo "Authorized SSH Public Keys (comments):"

if [[ -f "$AUTH_KEYS" ]]; then
    awk '
    /^[[:space:]]*#/ {next}      # skip komentar
    NF < 2 {next}                # skip baris kosong / invalid
    {
        # ambil field ke-3 sampai akhir sebagai comment
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
