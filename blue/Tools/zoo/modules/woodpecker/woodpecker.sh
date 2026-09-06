#!/bin/bash
# Woodpecker: probe hosts for default / weak credentials over SSH.
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../meow/meow.sh"
meow_require_hosts || exit 1
log="$HERE/woodpecker_log/woodpecker_$(date +%H-%M-%S).out"; mkdir -p "$(dirname "$log")"; : > "$log"
# default credential list (user:pass) - extend freely
CREDS="root:root root:toor root:password admin:admin admin:password user:user pi:raspberry ubuntu:ubuntu guest:guest test:test"
while read -r adminUser ip adminPass os domain; do
        [ "$os" = windows ] && { printf -- "  (skip %s: windows unsupported by this module)\n" "$ip"; continue; }
        [ -z "$ip" ] && continue
        printf -- "[----- WOODPECKER: %s -----]\n" "$ip" | tee -a "$log"
        for pair in $CREDS; do
                u="${pair%%:*}"; p="${pair#*:}"
                if "$DEPS/sshpass" -p "$p" ssh -T -n -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
                        -o PreferredAuthentications=password -o PubkeyAuthentication=no \
                        "${u}@${ip}" 'exit 0' 2>/dev/null; then
                        printf "  [!] DEFAULT CRED ACCEPTED: %s:%s\n" "$u" "$p" | tee -a "$log"
                else
                        printf "  [ ] rejected %s:%s\n" "$u" "$p" >> "$log"
                fi
        done
done < "$(meow_hosts)"
printf "\nSaved: %s\n" "$log"
