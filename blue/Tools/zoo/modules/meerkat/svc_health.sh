#!/bin/sh
# meerkat payload: generic service health (runs on target).
printf "===== FAILED SYSTEMD UNITS =====\n"
systemctl --failed --no-legend 2>/dev/null || echo "(systemd unavailable)"
printf "\n===== RUNNING SERVICES =====\n"
systemctl list-units --type=service --state=running --no-legend 2>/dev/null | awk '{print $1}'
printf "\n===== LISTENING SOCKETS =====\n"
ss -lntup 2>/dev/null || netstat -lntup 2>/dev/null
printf "\n===== UPTIME / LOAD =====\n"
uptime
printf "\n===== DISK USAGE =====\n"
df -h 2>/dev/null | grep -Ev 'tmpfs|loop|overlay'
