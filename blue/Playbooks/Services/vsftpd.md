* `/etc/vsftpd.conf`
* FTP over SSL, force encryption|
  * `ssl_enable=YES`
* disable anonymous login|
  * `anonymous_enable=NO`
* Configure passive port ranges
  * `pasv_min_port=40000`
  * `pasv_max_port=40100`
  * **UPDATE FIREWALL RULES**: allow this range over tcp
* force strong encryption ciphers
  * `ssl_ciphers=HIGH`
  * **UPDATE FIREWALL RULES**: allow 990/tcp and 989/tcp
* limit access to user's home directory
  * `chroot_local_user=YES`
* enable logging
  * `xferlog_enable=YES`
* Rate limite connection attempts (reduce brute forcing attacks)
  * `max_per_ip=5`
* If appropriate, backup scored files
  * `rsync -av -e ssh <source_files>  <remote_user>@<remote_ip>:<remote_path>`

<br>

#### Sources
* [hackviser](https://hackviser.com/tactics/hardening/vsftpd)