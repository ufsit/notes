#!/bin/bash
# Phoenix: automated firewall tasks. This pass AUDITS posture; applying a
# default-deny / whitelist ruleset requires root on the target (see README).
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../meow/meow.sh"
log="$HERE/phoenix_log/phoenix_$(date +%H-%M-%S).out"
printf "[phoenix] auditing firewall posture; rule application is root-gated and NOT executed here.\n"
meow_deploy "$HERE/fw_audit.sh" 'sh ~/fw_audit.sh' "$log"
printf "\nSaved: %s\n" "$log"
