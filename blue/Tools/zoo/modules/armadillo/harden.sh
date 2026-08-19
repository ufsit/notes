#!/bin/sh
# armadillo payload: general system hardening posture (report).
printf "===== KERNEL HARDENING (sysctl) =====\n"
for k in kernel.randomize_va_space net.ipv4.tcp_syncookies net.ipv4.conf.all.rp_filter net.ipv4.conf.all.accept_redirects net.ipv4.ip_forward; do
  printf "%-42s = %s\n" "$k" "$(sysctl -n $k 2>/dev/null || echo '?')"
done
printf "\n===== UID 0 ACCOUNTS =====\n"
awk -F: '($3==0){print $1}' /etc/passwd
printf "\n===== PASSWORD POLICY (login.defs) =====\n"
grep -E '^PASS_(MAX|MIN|WARN)' /etc/login.defs 2>/dev/null || echo "(login.defs not found)"
printf "\n===== FIREWALL TOOLING =====\n"
command -v ufw >/dev/null 2>&1 && echo "ufw present"; command -v nft >/dev/null 2>&1 && echo "nft present"; command -v iptables >/dev/null 2>&1 && echo "iptables present"
printf "\n===== LISTENING SERVICES =====\n"
ss -lntu 2>/dev/null | awk 'NR>1{print $5}' | sort -u
