#!/bin/bash
# Armadillo: general system hardening.
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../meow/meow.sh"
log="$HERE/armadillo_log/armadillo_$(date +%H-%M-%S).out"
meow_deploy "$HERE/harden.sh" 'sh ~/harden.sh' "$log"
printf "\nSaved: %s\n" "$log"
