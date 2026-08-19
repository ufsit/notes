#!/bin/bash
# Hawk: nmap sweep of targets to seed the network map.
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../meow/meow.sh"
meow_require_hosts || exit 1
log="$HERE/nmap_log/nmap_$(date +%H-%M-%S).out"; mkdir -p "$(dirname "$log")"; : > "$log"
# Root enables SYN + OS detection; unprivileged falls back to TCP connect.
if [ "$(id -u)" -eq 0 ]; then SCAN="-sS -O"; else SCAN="-sT"; fi
PORTS="${HAWK_PORTS:--p-}"
awk '{print $2}' "$(meow_hosts)" | sort -u | while read -r ip; do
        [ -z "$ip" ] && continue
        mkdir -p "$HERE/nmap_log/$ip"
        printf -- "----- HAWK nmap: %s -----\n" "$ip" | tee -a "$log"
        "$DEPS/nmap" --datadir "$DEPS/nmap-data" -Pn $SCAN -sV $PORTS -oA "$HERE/nmap_log/$ip/$ip" "$ip" >> "$log" 2>&1
done
printf "\nSaved: %s\n" "$log"
