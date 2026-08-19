#!/bin/sh
# woof payload: detect common system/service misconfigurations (report-first).
printf "===== SSHD CONFIG =====\n"
c=/etc/ssh/sshd_config
if [ -r "$c" ]; then
  grep -Ei '^[[:space:]]*PermitRootLogin' "$c" || echo "PermitRootLogin: (default)"
  grep -Ei '^[[:space:]]*PasswordAuthentication' "$c" || echo "PasswordAuthentication: (default)"
  grep -Ei '^[[:space:]]*Port' "$c" || echo "Port: (default 22)"
else
  echo "(sshd_config not readable)"
fi
printf "\n===== WORLD-WRITABLE FILES IN /etc =====\n"
find /etc -xdev -type f -perm -0002 2>/dev/null | head -20 || echo "(none)"
printf "\n===== EMPTY-PASSWORD ACCOUNTS =====\n"
awk -F: '($2==""){print $1}' /etc/shadow 2>/dev/null || echo "(shadow not readable)"
printf "\n===== .rhosts / hosts.equiv =====\n"
ls -la /etc/hosts.equiv 2>/dev/null; find /home -name .rhosts 2>/dev/null; echo "(scan complete)"
