#!/bin/bash
# Nematode: initial per-host enumeration upon successful login (README: pioneer species).
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../meow/meow.sh"
log="$HERE/net_enum_log/net_enum_$(date +%H-%M-%S).out"
meow_deploy "$HERE/net_enum.sh" 'sh ~/net_enum.sh' "$log"
printf "\nSaved: %s\n" "$log"
