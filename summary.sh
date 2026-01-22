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

# ================= DISK ZFS =================
# mapping:
# data1 -> zp0
# data2   -> disk2
# data3   -> disk3
# data4   -> disk4

zpool_output=$(zpool list -H -o name,free)

get_free() {
  local pool="$1"
  local free
  free=$(echo "$zpool_output" | awk -v p="$pool" '$1==p{print $2}')
  echo "${free:-tidak ada disk}"
}

data1_free=$(get_free zp0)
data2_free=$(get_free disk2)
data3_free=$(get_free disk3)
data4_free=$(get_free disk4)

echo "--------------------------------------"
printf "%-20s %s\n" "data1:" "$data1_free"
printf "%-20s %s\n" "data2:"   "$data2_free"
printf "%-20s %s\n" "data3:"   "$data3_free"
printf "%-20s %s\n" "data4:"   "$data4_free"

cat <<'EOF'
⚠️  jangan membuat paket melebihi batas
- script update versi 1.0 pada 22 Jan 2026
- gunakan perintah ini jika ingin meng update script 
----
cd ~/sr/ && git restore . && git pull && chmod +x *.sh
----
EOF

