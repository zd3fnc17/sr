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
  "RAM DIGUNAKAN:" "$total_mb" "$(echo "$total_mb/1024" | bc -l)"

# ================= STORAGE + VPS =================

echo "--------------------------------------"
echo "=== INFORMASI STORAGE ==="

declare -A ZPOOL_MAP=(
  [data1]="zp0"
  [data2]="disk2"
  [data3]="disk3"
  [data4]="disk4"
)

zpool_output=$(zpool list -H -o name,free)

get_free() {
  local pool="$1"
  local free
  free=$(echo "$zpool_output" | awk -v p="$pool" '$1==p{print $2}')
  if [[ -z "$free" ]]; then
    echo "no disk"
  else
    echo "$free"
  fi
}

declare -A VPS_COUNT
while IFS=, read -r pool count; do
  VPS_COUNT["$pool"]="$count"
done < <(
  lxc list --format json | jq -r '
    group_by(.devices.root.pool)
    | map({pool: .[0].devices.root.pool, count: length})
    | .[]
    | "\(.pool),\(.count)"
  '
)

for storage in data1 data2 data3 data4; do
  free_disk=$(get_free "${ZPOOL_MAP[$storage]}")
  vps=${VPS_COUNT[$storage]:-0}

  if [[ "$free_disk" == "no disk" ]]; then
    printf "%-6s : no disk\n" "$storage"
  else
    printf "%-6s : %s VPS | free %s\n" "$storage" "$vps" "$free_disk"
  fi
done

cat <<'EOF'
- jangan membuat paket melebihi batas
- script versi 1.13
----
EOF
