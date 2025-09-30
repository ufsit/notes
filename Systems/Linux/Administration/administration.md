- [Bash](#bash)
- [Environment variables](#environment-variables)
    - [How to set an environment variable](#how-to-set-an-environment-variable)
- [Users and Groups](#users-and-groups)
  - [Users](#users)
    - [User group modifications](#user-group-modifications)
    - [User name change](#user-name-change)
    - [User shell change](#user-shell-change)
  - [Groups](#groups)
- [passwd and shadow files](#passwd-and-shadow-files)
- [Backups](#backups)
  - [rsync](#rsync)
    - [Example](#example)
- [cron](#cron)
- [Hardware Information](#hardware-information)
  - [General](#general)
  - [CPU](#cpu)
  - [Memory](#memory)
  - [USB \& PCI Buses](#usb--pci-buses)
  - [Disk](#disk)
  - [Display details](#display-details)
  - [Low-Level Software](#low-level-software)
- [Checking processes and connections](#checking-processes-and-connections)
  - [netstat](#netstat)
    - [Example](#example-1)
  - [ss](#ss)
  - [ps](#ps)
    - [Example](#example-2)
- [Checking file information](#checking-file-information)
- [Kernel Modules](#kernel-modules)
- [Package Managers](#package-managers)
  - [apt](#apt)
  - [dpkg](#dpkg)
  - [dnf](#dnf)
- [sudo](#sudo)


# Bash
* Redirects (`>`, and `>>`) get spawned with permissions of the current user account
* if you want to redirect something to a restricted file, pipe the data to `sudo tee` and it should work
* store multiline text in a variable using "" across, then echo the variable using ""
```
#! /bin/bash
colors="orange
pink
blue
black
magenta
green
yellow
red
sky-blue
purple
indigo"
echo "$colors" > colors.txt
echo "The output has been printed to a file:"
cat colors.txt
```

# Environment variables
### How to set an environment variable
`export VARIABLE=value`



# Users and Groups
## Users
* `adduser [USER]`
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
    * the entry does contain `/home/test` for the new user, even though this address does not exist either. Even if we set a password with passwd for the *test* user, we would still be unable to create the home directory
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
* `/etc/group`
  * `[GROUP]:x:[GID]:[MEMBER_USERS]`
* `chown [USER]:[GROUP] [FILE]`

# passwd and shadow files
* `/etc/shadow`
  * should not be edited directly; 
    * change user password using `passwd`; 
    * change password aging information with `chage`
* Format:
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

# Backups
## rsync
* for subsequent backups, rsync will copy only the files that have been changed. 
* `rsync [FLAGS] [SOURCE_FILES] [DESTINATION_FILES]`
  * `--archive, -a` - a collection of flags, creates an archive with expected behavior 
  * `--verbose, -v` - verbose 
  * `--delete` - if a file was deleted from source files, then it will delete them in destination path; ensures consistency between source and destination paths
  * `-e` - remote shell, can specify various remote shells
    * `rsync -av -e ssh [SOURCE_FILES] [REMOTE_USER]@[REMOTE_IP_ADDRESS]:[DESTINATION_FILES_ADDRESS]`
    * `rsync -av -e "ssh -i [PRIVATE_KET]" [SOURCE_FILES] [REMOTE_USER]@[REMOTE_IP_ADDRESS]:[DESTINATION_FILES]`
### Example
* To backup 
  * `rsync -av [SOURCE_FILES] [DESTINATION_FILES]`
  * `rsync -ar [SRC] [DEST] --progress --delete --perms`



# cron
* `crontab -e` for editing the current user's crontab
* Location of all user crontabs
  * `/var/spool/cron/crontabs`
* Location of system-wide crontabs
  * `/etc/cron*`
  * `/etc/cron.d`
  * `/etc/cron.daily`
  * `/etc/cron.hourly`
  * `/etc/cron.weekly`
  * `/etc/cron.monthly`
  * `/etc/crontab`
    * it can specify what user can run a cronjob

# Hardware Information
## General
* `sudo lshw` - general hardware details
  * `-C [CLASS]` - specify a specific category of hardware
* `inxi -Fxz` - general hardware details
  * `-F` : full output
  * `-x` : adds details
  * `-z` : masks personally identifying information, like MAC and IP addresses
## CPU
* `lscpu` - CPU details
## Memory
* `sudo  dmidecode -t memory` - memory details 
  * `free -mh` - shows memory and swap memory usage in human readable format
## USB & PCI Buses
* `lspci` - shows pci information on controllers
  * find a controller you are interested, and then grep for its device number for all details on that device
* `lsusb` - shows USB buses
## Disk
* `lsblk` - lists all disks with their defined partitions along with their size
* `sudo fdisk -l` - includes number of sectors, size, filesystem ID and type, start and end sectors of partitions
* `sudo blkid` - lists UUID, TYPE, and PARTUUID of partitions
* `df -h` - list the mounted filesystems, mount points, and space used and available for each

## Display details
* `xdpyinfo | grep 'dimensions:'`

## Low-Level Software
* `dmidecode -t bios` - UEFI/BIOS date and version, and available characteristics
* `uname -a` - all kernel information

# Checking processes and connections
## netstat
* `--tcp|-t` - show tcp traffic
* `--udp|-u` - show udp traffic
* `--numeric|-n` - without this flag, ports information will show the service on that port, this flag will show the port number
* `--listening|-l` - shows listening sockets
* `--program|-p` - shows PID of the process and the process name, only with sudo
* `--all|-a` - shows listening and non-listening sockets
* `--continuous|-c` - shows the selected netstat information continuously
### Example
* All together: `netstat -tunlp`

## ss
* similar flags to netstat, a bit newer and faster, not as detailed as netstat but more concise (for our purposes, their interchangeable)
* netstat is more compatible and widely available

## ps
* `ps` - process inspection
  * `-e|-A` - shows all processes, identical flags
  * `-o [OPTIONS]` - user-defined format, accepted options in `STANDARD FORMAT SPECIFIERS` in man
    * euser - effective text user name
    * pid - pid
    * cmd - command and its arguments
  * `-u [USER_NAME]` - show effective user name of the next argument
    * `-x` - if we write x, i.e. `-ux`, since there are no `x` users, command will print every user's processes
  * `--forest` - ASCII art process tree
  * `-f` - Full-format listing, shows tree
  * `-H` - show process hierarchy
  * `-w` - wide output
### Example
* `ps aux`
* `ps auxf`
* `ps -eo euser,pid,cmd --forest | less`
* `ps -efwH`

# Checking file information
* `file [FILE]` : for files`
* `stat [FILE]` : stats for files
* `fstat [FILE]` : describe file descriptors, bit more secure than `stat`

# Kernel Modules
* `insmod` : inserts module to the kernel
* `lsmod` : lists active kernel modules

# Package Managers
## apt
* used by Debian & derivatives
* `apt update` - updates package repositores
* `apt upgrade` - upgrades the system
* `apt install <PACKAGE>`
* `apt remove <PACKAGE>`
## dpkg
- used by Debian & derivatives
* `sudo dpkg --verify` - checks to see if the installed package differs from the package stored upstream
## dnf
- Used by RHEL & derivatives
- `dnf <upgrade|update>` - system wide upgrade
- `dnf check-upgrade` - updates package repositories

# sudo
* `--login|-i`: Run the shell specified by the target user's password database entry as a login shell
* `-u [USER]|--user=[USER]`: Run the command as a user other than the default target user