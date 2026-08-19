#!/bin/bash
# Turtle: Caddy WAF deployment. Full deploy needs the caddy binary + root on the
# target; configgen.py/logparse.py in this dir build the config. This pass reports
# the target's web-server footprint so the WAF can be slotted in front of it.
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../meow/meow.sh"
log="$HERE/turtle_log/turtle_$(date +%H-%M-%S).out"; mkdir -p "$(dirname "$log")"
meow_deploy "" 'echo "web servers:"; ss -lntp 2>/dev/null | grep -E ":80|:443|:8080" || echo "(none on 80/443/8080)"; command -v caddy >/dev/null 2>&1 && echo "caddy present" || echo "caddy NOT installed (deploy is root/infra-gated)"' "$log"
printf "\nSaved: %s\n" "$log"
