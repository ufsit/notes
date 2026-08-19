#!/bin/bash
# Suricata: deploy Suricata IDS + connect to ELK.
# Install requires a package + root on the target; this pass checks presence and
# reports readiness. Wire the actual install/eve.json->ELK step where root is available.
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../meow/meow.sh"
log="$HERE/suricata_log/suricata_$(date +%H-%M-%S).out"
meow_deploy "" 'command -v suricata >/dev/null 2>&1 && (echo "suricata present: $(suricata -V 2>/dev/null)"; systemctl is-active suricata 2>/dev/null) || echo "suricata NOT installed (deploy step is root/infra-gated)"' "$log"
printf "\nSaved: %s\n" "$log"
