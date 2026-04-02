- [vsftpd](#vsftpd)
    - [Install](#install)
    - [Hardening](#hardening)
    - [General Settings](#general-settings)
      - [Footprinting](#footprinting)


# vsftpd
* From HackTheBox:
  > FTP is capable of running in two different modes, active or passive. Active is the default operational method utilized by FTP, meaning that the server listens for a control command PORT from the client, stating what port to use for data transfer. Passive mode enables us to access FTP servers located behind firewalls or a NAT-enabled link that makes direct TCP connections impossible. In this instance, the client would send the PASV command and wait for a response from the server informing the client what IP and port to utilize for the data transfer channel connection. 
### Install
* `sudo dnf|apt install vsftpd`
* `sudo systemctl enable vsftpd`
* `sudo systemctl start vsftpd`

### Hardening
* Disable anonymous FTP access: `sudo nano /etc/vsftpd/vsftpd.conf`
```
anonymous_enable=NO               # Enable anonymous access?
local_enable=YES                  # allow local users to login?
write_enable=YES                  # may be required in competition
chroot_local_user=YES
user_sub_token=$USER
local_root=/home/$USER
allow_writeable_chroot=YES
```
* you can specify users that may never enter ftp:
```
userlist_deny=YES
userlist_enable=YES
userlist_file=/etc/vsftpd.userlist      # create this file
```
  * since all the scored users contain `_`, we can simply grep for the users that do not contain this character:
  * `cat /etc/passwd | cut -d: -f1 | grep -v '_' > vsftpd.userlist`
### General Settings
|Settings|Description|
|:-|:-|
|`listen=NO`|Run from inetd or as a standalone daemon?|
|`listen_ipv6=YES`|Listen on IPv6?|
|`anonymous_enable=NO`|Enable Anonymous access?|
|`local_enable=YES`|Allow local users to login?|
|`dirmessage_enable=YES`|Display active directory messages when users go into certain directories?|
|`use_localtime=YES`|Use local time?|
|`xferlog_enable=YES`|Active logging of uploads/downloads?|
|`connect_from_port_20=YES`|Connect from port 20?|
|`secure_chroot_dir=/var/run/vsftpd/empty`|name of an empty directory|
|`pam_service_name=vsftpd`|This string is the name of the PAM service vsftpd will use|
|`rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem`|The last three options specify the location of the RSA certificate to use for SSL encrypted connections|
|`rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key`| |
|`ssl_enable=NO`| |
|DANGEROUS SETTINGS| |
|`anonymous_enable=YES`|Allowing anonymous login?|
|`anon_upload_enable=YES`|Allowing anonymous to upload files?|
|`anon_mkdir_write_enable=YES`|Allowing anonymous to create new directories?|
|`no_anon_password=YES`|Do not ask anonymous for password?|
|`anon_root=/home/username/ftp`|Directory for anonymous|
|`write_enable=YES`|Allow the usage of FTP commands: STOR, DELE, RNFR, RNTO, MKD, RMD, APPE, and SITE?|
|More Settings| |
|`chown_uploads=YES`|Change ownership of anonymously uploaded files?|
|`chown_username=username`|user who is given ownership of anonymously uploaded files|
|`chroot_local_user=YES`|Place local users in their home directory?|
|`chroot_list_enable=YES`|Use a list of local users that will be placed in their home directory?|
|`hide_ids=YES`|All user and group information in directory listings will be displayed as 'ftp'|
|`ls_recurse_enable=YES`|Allows gives a better overview of the FTP directory structure, see all visible content at once|

* There is a file called `/etc/ftpusers`, which is used to deny certain users access to the FTP service; simply write the usernames in each line.
* For enumeration purposes, we can execute the commands `debug` and `trace` to see more output
* `wget -m --no-passive ftp://anonymous:anonymous@<ip>` - download all available files
#### Footprinting
* NMAP scripts
  * `find / -type f -name "ftp*" 2>/dev/null | grep scripts` - all the nmap ftp scripts
  * `-sC` - for default scripts
  * `ftp-anon` - checks whether the FTP server allows anonymous access, if available, the root directory is rendered for the anonymous user
  * `ftp-syst` - executes the `STAT` command, displaying information about the FTP server status