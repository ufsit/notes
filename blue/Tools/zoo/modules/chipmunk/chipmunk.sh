#!/bin/bash
# Chipmunk: create, fetch, and host backups.
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../meow/meow.sh"
log="$HERE/baks/baks_log/chipmunk_$(date +%H-%M-%S).out"; mkdir -p "$(dirname "$log")"; : > "$log"
# 1) create a fresh backup on each target
meow_deploy "$HERE/mkbak.sh" 'sh ~/mkbak.sh' "$log"
# 2) pull the newest backup from each host into chipmunk/baks/<ip>/
while read -r adminUser ip adminPass; do
        [ -z "$ip" ] && continue
        latest=$("$DEPS/sshpass" -p "$adminPass" ssh -T -n -o StrictHostKeyChecking=no "${adminUser}@${ip}" 'ls -t ~/baks/*.tar.gz 2>/dev/null | head -1')
        if [ -z "$latest" ]; then printf "%s: no backup found\n" "$ip" | tee -a "$log"; continue; fi
        mkdir -p "$HERE/baks/$ip"
        "$DEPS/sshpass" -p "$adminPass" scp -o StrictHostKeyChecking=no "${adminUser}@${ip}:$latest" "$HERE/baks/$ip/" 2>/dev/null \
                && printf "%s: pulled %s\n" "$ip" "$(basename "$latest")" | tee -a "$log"
done < "$(meow_hosts)"
printf "\nSaved: %s\n" "$log"
