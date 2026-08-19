#!/bin/bash
# Chomp: custom host-based EDR (detect + block). The blocking agent is a separate
# product; this pass runs a lightweight detection sweep (recent auth failures,
# unexpected listeners, new SUID) and logs it. Active blocking is root/agent-gated.
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../meow/meow.sh"
log="$HERE/chomp_log/chomp_$(date +%H-%M-%S).out"
read -r -d '' SWEEP <<'SW'
printf "== recent failed logins ==\n"; (lastb -n 10 2>/dev/null || grep -i "authentication failure" /var/log/auth.log 2>/dev/null | tail -10 || echo "(no auth log)")
printf "\n== listening processes ==\n"; ss -lntp 2>/dev/null | tail -n +2
printf "\n== SUID files (recent) ==\n"; find / -xdev -perm -4000 -type f -printf "%TY-%Tm-%Td %p\n" 2>/dev/null | sort -r | head -10
printf "\n== root cron ==\n"; ls -la /etc/cron.d /etc/cron.daily 2>/dev/null | head
SW
meow_deploy "" "$SWEEP" "$log"
printf "\nSaved: %s\n" "$log"
