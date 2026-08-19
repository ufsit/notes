#!/bin/sh
# lynx payload: analyze PAM configs for weak/backdoor settings (runs on target).
printf "===== /etc/pam.d LISTING =====\n"
ls -la /etc/pam.d 2>/dev/null
printf "\n===== SUSPICIOUS DIRECTIVES (permit/nullok/exec) =====\n"
grep -REn 'pam_permit\.so|nullok|pam_exec\.so|pam_python\.so' /etc/pam.d 2>/dev/null || echo "(none found)"
printf "\n===== PAM MODULES REFERENCED =====\n"
grep -RhoE 'pam_[a-z0-9_]+\.so' /etc/pam.d 2>/dev/null | sort | uniq -c | sort -rn
printf "\n===== WORLD-WRITABLE PAM FILES =====\n"
find /etc/pam.d -type f -perm -0002 2>/dev/null || echo "(none)"
printf "\n===== PAM .so ON DISK (recent mtime first) =====\n"
find /lib /lib64 /usr/lib -name 'pam_*.so' -printf '%TY-%Tm-%Td  %p\n' 2>/dev/null | sort -r | head -20
