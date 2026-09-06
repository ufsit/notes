#!/bin/bash
# Hawk: nmap sweep of targets to seed the network map, plus OS fingerprinting.
#   - Sourced: exposes hawk_osmap (used by elephant to tag host OS).
#   - Executed: runs the full sweep of the inventory (hawk_scan).
HAWK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HAWK_DIR/../meow/meow.sh"

# hawk_osmap [IP...]: classify each IP as linux/windows/unknown from a quick
# nmap port probe. IPs from args or stdin. Prints "IP OS" per line.
#   22 open            -> linux
#   445/3389/5985/135/139 open (and no 22) -> windows
#   otherwise          -> unknown (operator decides)
hawk_osmap() {
        _ips="$*"; [ -z "$_ips" ] && _ips="$(cat)"
        for _ip in $_ips; do
                [ -z "$_ip" ] && continue
                _o="$("$DEPS/nmap" --datadir "$DEPS/nmap-data" -Pn -T4 -p 22,135,139,445,3389,5985 "$_ip" 2>/dev/null)"
                if printf '%s\n' "$_o" | grep -qE '^22/tcp[[:space:]]+open'; then
                        printf '%s linux\n' "$_ip"
                elif printf '%s\n' "$_o" | grep -qE '^(135|139|445|3389|5985)/tcp[[:space:]]+open'; then
                        printf '%s windows\n' "$_ip"
                else
                        printf '%s unknown\n' "$_ip"
                fi
        done
}

# hawk_scan: full nmap sweep (-sV, OS detect when root) of every inventory host.
hawk_scan() {
        meow_require_hosts || return 1
        log="$HAWK_DIR/nmap_log/nmap_$(date +%H-%M-%S).out"; mkdir -p "$(dirname "$log")"; : > "$log"
        # Root enables SYN + OS detection; unprivileged falls back to TCP connect.
        if [ "$(id -u)" -eq 0 ]; then SCAN="-sS -O"; else SCAN="-sT"; fi
        PORTS="${HAWK_PORTS:--p-}"
        awk '{print $2}' "$(meow_hosts)" | sort -u | while read -r ip; do
                [ -z "$ip" ] && continue
                mkdir -p "$HAWK_DIR/nmap_log/$ip"
                printf -- "----- HAWK nmap: %s -----\n" "$ip" | tee -a "$log"
                "$DEPS/nmap" --datadir "$DEPS/nmap-data" -Pn $SCAN -sV $PORTS -oA "$HAWK_DIR/nmap_log/$ip/$ip" "$ip" >> "$log" 2>&1
        done
        printf "\nSaved: %s\n" "$log"
}

# Run the sweep only when executed directly (sourcing just loads the functions).
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
        hawk_scan
fi
