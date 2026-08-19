#!/bin/bash
# Meerkat: generic service health checks (whatever woodpecker doesn't cover).
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../meow/meow.sh"
log="$HERE/meerkat_log/meerkat_$(date +%H-%M-%S).out"
meow_deploy "$HERE/svc_health.sh" 'sh ~/svc_health.sh' "$log"
printf "\nSaved: %s\n" "$log"
