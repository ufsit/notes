#!/bin/bash
# Suricata: deploy Suricata IDS + connect to ELK.

HERE="$(cd "$(dirname "$0")" && pwd)"

. "$HERE/../meow/meow.sh"

meow_require_hosts || exit 1

log="$HERE/suricata_log/suricata_$(date +%H-%M-%S).out"

payload="$HERE/install_suricata.sh"

meow_deploy \
    "$payload" \
    'sudo sh ~/install_suricata.sh' \
     "$log"

printf "\nSaved: %s\n" "$log"
