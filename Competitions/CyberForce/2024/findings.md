# Linux
* spoofed `csh` to `bash`
* empty user password
* credentials in `.bash_history`
* `find` is has `ALL ALL=NOPASSWD` and is SUID enabled
* `vim.basic`, `cp` are SUID enabled
* non-privileged users in the `sudo` or `wheel` group
* hidden directory
* `sudo` v1.8.23 - privesc
* Telnet is enabled
* `chronyd` vulnerable version
* malicious service with a spoofed name starts a revshell
* revshell on a root cronjob
* service account is given a shell


# Windows
* Guest account is enabled
* null authentication is enabled
* weak passwords on local and domain accounts
* kerberoastable users
* asreproastable users
* binary in a public repo runs as Administrator at boot (privesc)
* weak password policy
* no lockout policy
* firewall disabled
* AV disabled through group policy
* sticky keys on login
* accessibility options on login screen are backdoored
* malicious admin account with weak password
* attacker tools installed (Handlekatz and Rubeus_C) or available in public directories
* `ntds.dit` in a public directory

# Services
## SSH
* `PermitEmptyPassword yes`
* `authorized_keys` has an unauthorized entry 
## MySQL
* plaintext PII 
* admins have weak password
## NFS
* Entire filesystem is shared with `rw` perms
## SNMP
* secret commnunity string is weak, an easy to guess secret,
* has `rw` permission
* configured to run `bash` whenever anyone connects 
## SMB
* read/write access on a share
* SMB encryption disabled
* SMBv1 enabled
* SMB signing disabled
## RDP
* no password
## XAMPP
* `xampp` service is enabled (very vulnerable)
* PHP apps running inside of XAMPP do not diable dangerous functions


# Niche
* unncessesary web server - Linux
* unncesseary tftp - Linux
* remove `socat/netcat/nc` binaries; hardening more than a finding - Linux/Windows
* user hash in `C:\Users\Public\Temp\` directory - Windows
* attacker tools left in home directories of users - Windows
* a user has PII on his workstation - Windows