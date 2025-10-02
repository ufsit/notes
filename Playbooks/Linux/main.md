# Users
* Roll passwords
  * *script - coming soon*
  * `sudo passwd user`
* verify appropriate group membership of sensitive users
* verify `/etc/sudoers` has no sensitive permissions
* lock out all unecessary users
  * `sudo passwd -l <username>` - lock out an account (passwd may be backdoored, be careful)
  * *script - coming soon*

# Firewall
* Include appropriate [firewall playbook](./firewall.md) for your distro

# Cronjobs
* `/etc/crontab`
* `/etc/cron.d/*`
* `/etc/cron.{hourly.daily,weekly,monthly}/*`
* `/var/spool/cron/*`
* `/var/spool/cron/crontabs/*`
* `/var/spool/anacron/*`
* Delete if appropriate
* if possible, stop cron service: `cron|crond|cronie`



# Network Analysis
* list all ports with listening socket, and their processes
  * `sudo ss -tunlp`


# Backdoored/Tampered Binaries
* Login shells
  * `/bin/bash`
  * `/bin/sync`
  * `/sbin/halt`
  * `/sbin/nologin`
  * `/sbin/shutdown`
  * `/usr/bin/nologin`
  * `/usr/sbin/nologin`
* Miscellaneous
  * `/bin/false`
  * `/usr/bin/passwd`
* Spoofed binaries (`nc` = `systemd-updates`)

# Package Manager
* include appropriate [package manager](./package_manager.md) playbook

# SUID binaries
* `find / -perm -4000 -ls 2>/dev/null`

# PATH Hijacking
* [Inspect Path Script](../../Tools/Management/path_env_inspect.sh) for root's `$PATH` variable
  * the output should contain directories only modifiable by root
  * suspicious directories will likely appear first

# Backup
* directories to archive
  * `/etc/` - all system configurations
  * `/var/log/` - logs, if applicable
  * **service configs**
* using `tar` to archive locally
  * `sudo tar -czf <archive_name.tar.gz> <directory_to_archive>`
* using `rsync` to archive remotely over SSH
  * `rsync -av -e ssh <directory_to_archive> <remote_user>@<remote_ip>:<remote_archive_dest>`
* restore from backup using `tar`
  * `sudo tar -xzvf <archive.tar.gz> -C <destination_directory>` 
* restore from backup using `rsync`
  * `rsync -av <remote_user>@<remote_ip>:<remote_dir> <destination_dir>`

# Aliases
* `grep alias ~/.bashrc ~/.bash_aliases` - look for aliases, verify all benign; repeat for each user

# Neutralize nc
* tend to always be used for backdoors
* variants: `nc`, `netcat`, `ncat`, `netcat-traditional`, `socat`, `netcat-openbsd`
* `which <netcat_variant>`
* Move to `/opt` or delete

# Process analysis
* `ps -auxf` - verbose output, need to know what to look for
  * if applicable, `btop` has a nice TUI
* `ps -u root` - processes for root user
* `sudo kill -9 <pid>` - send the SIGKILL signal to a process
* `sudo pkill -9 <regex_pattern>` - kill processes matching pattern for any attribute of a process `ps -aux` output
* Processes running in uncommon directories
```
1ps aux | awk '$11 !~/^\/(sbin|bin|usr|var|lib|sys|proc|dev|tmp|run|root|home|etc)\// {print}'
```

# Active shells
* `who -u`

# System Logs
* Auth logs
  * `/var/log/secure` or `/var/log/auth.log`
* Login records
  * `/var/log/wtmp` or `/var/log/utmp`
* General logs
  * `/var/log/messages`
* Cron logs
  * `/var/log/cron.log`

# Service Checks
* verify all **required** systemd services have benign configurations, especailly those with open ports
  * `/usr/lib/systemd/system/*.service`
* system logs for a service
  * `sudo journalctl -xau <service_unit>`

# Redteam Files
* `sudo find / type -f -iname "*redteam*" -o -type d -iname "*redteam*" 2>/dev/null`

# Recent Files
* show files recently modified (maybe red team didn't change the date on modified files)
  * `sudo find / -type f -mtime -5 2>/dev/null`

# File Perms
* remove write permissions for stable configs
  * `chmod -w /path/to/config`
* owner-read-only
  * **MIGHT BREAK**
  * `chmod 400 /path/to/config`
* immutable attribute
  * **TEST BEFORE APPLYING**
  * `sudo chattr +i /path/to/config`

# PAM
* Include appropriate [PAM playbook](./pam.md) for appropriate distro
* *script - coming soon*

# opensnitch
<!-- TODO -->

# sysdig
* see exactly what users are running
  * `sysdig -c spy_users`
<!-- TODO -->

# ShellShock Check
* `env x='() { :;}; echo vulnerable' bash -c 'echo hello'`
* update bash if output is "vulnerable"

# Security Programs
## LinPEAS
* easy win for low-hanging priv-esc-fruit
  * `curl -L https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh | sh > linpeas.out`

## ClamAV
<!-- TODO -->

## Lynis
<!-- TODO -->

## rkhunter
<!-- TODO -->

## chkrootkit
<!-- TODO -->

<!-- TODO: remove Systems/Linux/Playbooks/ncae_checklist.pdf; should be integrated here -->