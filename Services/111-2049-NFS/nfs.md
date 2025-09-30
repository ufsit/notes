# NFS
* `Network File System (NFS)` - a network file system developed by Sun Microsystems and has the same purpose as SMB
* NFS us used between Linux and Unix systems.
  * NFS clients cannot communicate directly with SMB servers
* NFS is an Interent standard that gverns the procedures in a distributed file system
* NFS is based on the `Open Network Computing Remote Procedure Call (ONC-RPC/SUN-RPC)`, exposed on TCP and UDP ports 111
* It has not mechanism for authentication or authorization
  * authentication is completely shifted to the RPC protocol's options
    * most common authentication is via UNIX UID/GID and group memberships
    * since the client and server do not necessarily have to have the same mappings of UID/GID to users nad groups, the server doesn't need ot do anything further, no checks can be done. Only use this method on trusted networks
  * authorization is derived from the avilable file system information
    * the server is responsible for translating the client's user information into the file system's format and converting the corresponding authorization details into the required UNIX syntax as accurately as possible.


|Version|Features|
|:-|:-|
|NFSv2|It is older but is supported by many systems and was initially operated entirely over UDP|
|NFSv3|It has more features, including variable file size and better error reporting, but is not fully compatible with NFSv2 clients|
|NFSv4|It includes Kerberos, works through firewalls and on the Internet, no longer requires portmappers, supports ACLs, applies state-based operations, and provides perofmrnace improvements and high security. It is also the first version to have a stateful protocol.| 

### Default Configuration
* `/etc/exports` contains a table of physical filesystems on an NFS server accessible by the clients
* The default exports file also contains some exmaples of configuring NFS shares
  * first, the foldedr is specified and made available to others
  * then, rights they will have on this NFS share are connected to a host or a subnet
  * finally, additional options can be added ot the hosts or subnet
```
### NFSv2 and NFSv3 example
/srv/homes  hostname1(rw,sync,no_subtree_check) hostname2(ro,sync,no_substree_check)

### NFSv4 example
/srv/nfs4         gss/krb5i(rw,sync,fsid=0,crossmnt,no_subtree_check)
/srv/nfs4/homes   gss/krb5i(rw,sync,no_subtree_check)
```

|Option|Description|
|:-|:-|
|`rw`|read and write permissions|
|`ro`|read only permissions|
|`sync`|synchronous data transfer (bit slower)|
|`async`|asynchronous data transfer (bit faster)|
|`secure`|ports above 1024 will not be used|
|`insecure`|ports above 1024 will be used|
|`no_subtree_check`|disables cehcking subdirectory trees|
|`root_squash`|assigns all permissions to files of root UID/GID 0 to the UID/GID of anonymous, which prevents root from accessing files on an NFS mount|
|Dangerous Settings| |
|`rw`|read and write permissions|
|`insecure`|ports above 1024 will be used|
|`nohide`|if noather file system was mounted bellow an exported directory, this directory is exported by its own exports entry|
|`no_root_squash`|all files created by root are kept with the UID/GID|

### Showing, Mounting, Unmounting NFS Shares
* `showmount -e <IP>`
* `sudo mount -t nfs <NFS_SERVER_IP>:<SHARE_ADDRESS> <LOCAL_MOUNTPOINT> -o nolock`
* `sudo umount <LOCAL_MOUNTPOINT>`

# Misconfigurations & Exploitability
* If an NFS share has write permissions is highly vulnerable
* together with shell access to the system and access to the shared directory, an attacker can perform a number of attacks:
  * making a copy of /usr/bin/bash and place it in the share
  * then, an attacker can mount that share on their system, change the ownership of the copied binary to `root:root` and set the SUID bit
  * then, the attacker can simply run this binary, `./bash -p` and obtain root privileges
* In short, make sure that the NFS share is read-only (`ro`)