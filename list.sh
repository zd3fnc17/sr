#!/bin/bash

printf "%-20s | %s\n" "SCRIPT" "DESKRIPSI"
printf "%-20s | %s\n" "--------------------" "----------------------------------------"

for f in *.sh; do
    desc=$(grep '^# DESC:' "$f" | head -n1 | sed 's/# DESC:[[:space:]]*//')

    if [ -z "$desc" ]; then
        desc="-"
    fi

    printf "%-20s | %s\n" "$f" "$desc"
done
