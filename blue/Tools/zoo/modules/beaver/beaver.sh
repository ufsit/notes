#!/bin/bash
# Beaver: guard watched files; restore a known-good copy on drift (wrapper on chipmunk).
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../meow/meow.sh"
GOOD="$HERE/good"; mkdir -p "$GOOD"
log="$HERE/beaver_log/beaver_$(date +%H-%M-%S).out"; mkdir -p "$(dirname "$log")"; : > "$log"
# Files to guard (override with BEAVER_WATCH="...").
WATCH="${BEAVER_WATCH:-/etc/hosts /etc/os-release}"
while read -r adminUser ip adminPass os domain; do
        [ "$os" = windows ] && { printf -- "  (skip %s: windows unsupported by this module)\n" "$ip"; continue; }
        [ -z "$ip" ] && continue
        printf -- "[----- BEAVER: %s -----]\n" "$ip" | tee -a "$log"
        for f in $WATCH; do
                name="$(echo "$f" | tr '/' '_')"
                goodfile="$GOOD/$name"
                rhash=$("$DEPS/sshpass" -p "$adminPass" ssh -T -n -o StrictHostKeyChecking=no "${adminUser}@${ip}" "sha256sum '$f' 2>/dev/null | awk '{print \$1}'")
                if [ -z "$rhash" ]; then printf "  %s: absent on target\n" "$f" | tee -a "$log"; continue; fi
                if [ ! -f "$goodfile" ]; then
                        "$DEPS/sshpass" -p "$adminPass" scp -o StrictHostKeyChecking=no "${adminUser}@${ip}:$f" "$goodfile" 2>/dev/null
                        printf "  %s: baselined known-good\n" "$f" | tee -a "$log"; continue
                fi
                ghash=$(sha256sum "$goodfile" | awk '{print $1}')
                if [ "$rhash" = "$ghash" ]; then
                        printf "  %s: OK\n" "$f" | tee -a "$log"
                else
                        printf "  %s: DRIFT -> restoring known-good\n" "$f" | tee -a "$log"
                        "$DEPS/sshpass" -p "$adminPass" scp -o StrictHostKeyChecking=no "$goodfile" "${adminUser}@${ip}:/tmp/${name}.good" 2>/dev/null
                        "$DEPS/sshpass" -p "$adminPass" ssh -T -n -o StrictHostKeyChecking=no "${adminUser}@${ip}" "cp /tmp/${name}.good '$f' 2>/dev/null && echo '    restored' || echo '    restore failed (needs perms)'" | tee -a "$log"
                fi
        done
done < "$(meow_hosts)"
printf "\nSaved: %s\n" "$log"
