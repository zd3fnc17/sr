#!/bin/bash

VPS_LIST=(
  Ahong1046
  dhimas1048
  myshms1056
  testing235325423
  vps1053
  vps1054
  vps1057
  vps744571047
)

for VPS in "${VPS_LIST[@]}"; do
  echo "▶️ Memproses VPS: $VPS"

  if lxc info "$VPS" >/dev/null 2>&1; then
    lxc config set "$VPS" limits.cpu 2
    lxc config set "$VPS" limits.cpu.allowance 50%
    echo "✅ $VPS → CPU 2 core | allowance 50%"
  else
    echo "❌ $VPS tidak ditemukan"
  fi

  echo "---------------------------------"
done
