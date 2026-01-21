#!/bin/bash

echo "=== INFORMASI VPS sedang RUNNING ==="
printf "%-20s %s\n" "VPS" "RAM"

total_mb=0

while IFS=, read -r name status ram; do
  [[ "$status" != "RUNNING" ]] && continue

  if [[ -z "$ram" ]]; then
    ram="UNLIMITED"
  else
    if [[ $ram == *GB ]]; then
      total_mb=$((total_mb + ${ram%GB} * 1024))
    elif [[ $ram == *GiB ]]; then
      total_mb=$((total_mb + ${ram%GiB} * 1024))
    elif [[ $ram == *MB ]]; then
      total_mb=$((total_mb + ${ram%MB}))
    fi
  fi

  printf "%-20s %s\n" "$name" "$ram"
done < <(lxc list -c n,s,limits.memory --format csv)

echo "--------------------------------------"
printf "%-20s %d MB (%.2f GB)\n" \
  "TOTAL RAM LIMIT:" "$total_mb" "$(echo "$total_mb/1024" | bc -l)"

echo "⚠️  jangan membuat paket melebihi batas"

echo
echo "=== STORAGE TERSISA ==="
df -h /var/snap/lxd/common/lxd/storage-pools/default /data2 \
  | awk 'NR>1 {printf "%-40s %s\n", $6, $4}' \
  | sort -h -k2

echo "ℹ️  silakan pilih storage yang paling banyak tersisa"
