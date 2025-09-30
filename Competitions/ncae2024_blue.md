# NCAE 2024: UF

## Checklist for ALL
First, backup using `mkdir /.backup` and `rsync -av /etc "/.backup"` and `rsync -av /home "/.backup"`
1. Change passwords for our user and root _except_ for scored users
2. Change ssh keys by running `ssh.sh`
3. Have local backups by running `backup.sh`
4. Remove unnecessary users from `/etc/shadow` and `/etc/passwd`
   - `sudo userdel -r {user name}`
   - Use `cat /etc/group | grep 'adm\|root\|sudo'` to check groups. Remove any users that shouldn't be there with `deluser {user name} {group name}`
   - Use `sudo visudo` to change sudoers!!!
5. Configure firewall!!!
   - Default deny
   - Configure firewall port and service specific
6. Config required ips
   - **At this point we should have services up and running**
7. Threat hunting: 
   - **Remove** malicious services by running `killALL.sh`
      - Manually check `/etc/crontab` to be safe!
   - Look for redteam/malicious files by running `hunt.sh`
   - Check for any aliases by running `al.sh`
   - Look for suid (priveledge escalation) by runnning suid.sh
      - Use winpeas/linpeas for a more thorough check
   - Look for rootkits by using `rkhunter`
   - Update packages by running `pkgUpdate.sh`. **NOTE:** this script takes a while, so you want to use tmux and have this running in the background as you check for other threats
      - Reinstall any packages that have been compromised `apt-install -reinstall {package name}`
   - Look for payloads (Go/Sliver) by running `payload.sh`
9. Service hardening (tbh I'm not sure what this means)
10. Backup to backup server. **ANdrey will be handling this, let him know whenever you want to backup!**
