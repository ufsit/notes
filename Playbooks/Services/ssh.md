# SSH
* mv `authorized_keys` to `unathorized_keys`
* `/etc/ssh/sshd_config`
* `PermitEmptyPassword no`
* Do this at your own risk: `PermitRootLogin no`
* Ensure SSH is using protocol version 2
  * `Protocol 2` - SSH does this by default so doesn't even have this line at all; watch out for `Protocol 1`
* Allow only select users through SSH
  * `AllowUsers <user1> <user2>` - SSH user whitelist
  * `Tools/Hardening/StartScripts/ssh_allowed_users.sh`
* `MaxSessions 5` - limit active connections, reduce session hijacking risk, conserve resources
<br><br>

* write firewall rules
