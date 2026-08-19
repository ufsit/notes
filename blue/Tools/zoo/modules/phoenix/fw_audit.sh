#!/bin/sh
# phoenix payload: report firewall posture (applying rules requires root).
printf "===== IPTABLES (filter) =====\n"; iptables -S 2>/dev/null || echo "(iptables unreadable / absent)"
printf "\n===== NFTABLES =====\n"; nft list ruleset 2>/dev/null | head -40 || echo "(nft absent)"
printf "\n===== UFW STATUS =====\n"; ufw status verbose 2>/dev/null || echo "(ufw absent)"
printf "\n===== LISTENING PORTS (candidate allow-list) =====\n"; ss -lntu 2>/dev/null | awk 'NR>1{print $1, $5}'
printf "\n===== ESTABLISHED OUTBOUND =====\n"; ss -ntu state established 2>/dev/null | awk 'NR>1{print $5}' | sort -u | head -20
