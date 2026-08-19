#!/bin/bash
# Woof: patch system/service misconfigurations across hosts.
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../meow/meow.sh"
log="$HERE/woof_log/woof_$(date +%H-%M-%S).out"
meow_deploy "$HERE/patch.sh" 'sh ~/patch.sh' "$log"
printf "\nSaved: %s\n" "$log"
