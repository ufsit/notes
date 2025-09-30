# Config
Check `etc/ssh/ssh_config` but more importantly, `etc/ssh/sshd_config`
- PermitRootLogin no
- ListenAddress to secure
Use `ssh-keygen -t rsa -b 2048`

## No passwd
Check `sudo vi /etc/ssh/sshd_config.d/disable_root_login.conf`
- ChallengeResponseAuthentication no
- PasswordAuthentication no
- UsePAM no
- PermitRootLogin no
