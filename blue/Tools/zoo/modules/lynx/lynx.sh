#!/bin/bash
# Lynx: PAM debugger - analyze bad PAM configs and backdoors.
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../meow/meow.sh"
log="$HERE/lynx_log/lynx_$(date +%H-%M-%S).out"
meow_deploy "$HERE/pam_audit.sh" 'sh ~/pam_audit.sh' "$log"
printf "\nSaved: %s\n" "$log"
