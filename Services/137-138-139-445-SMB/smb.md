
# SMB
* Server Message Block (SMB) is a client-server protocol that regulates access to files and entire directories and other network resouces such as printers, routers, or interfaces released for the newtork.
* Mainly used on Windows, whose netowkr services support SMB in a downward-compatible manner
* `Samba` - a solution that enables the use of SMB in Linux and Unix distributions on this cross-platform communication via SMB.
* SMB protocol enables th client to communicate with other participants int he same network to access files or services shared with it on the network
  * both parties must establish a connection, which is why they first exchange corresponding messages
  * which is why in IP networks, SMB uses TCP
* An SMB server can provide arbitrary parts of its local file system as shares
  * therefore the hierarchy visible to a client is partially independent of the structure on the server
### Samba
* It implements the Common Internet File System (CIFS) network protocol
  * it is a dialect of SMB, meaning it is a specific implementation of the SMB protocol originally created by Microsoft. 
  * Which is why it is often referrred toas SMB/CIFS
* CIFS is considered a specific version of the SMB protocol, aligning with SMBv1
  * When SMB commands are transmitted over Samba to an older NetBIOS service, connections typically occur over TCP ports 137,138,139
  * CIFS operates over TCP 445 exclusively
* SMBv2 and SMBv3 offer improvements and are preferred in modern infrastructures, while older versions like SMBv1(CIFS) are considered outdated but may still be used in specific environments

|SMB Version|Supported|Features|
|:-|:-|:-|
|CIFS|Windows NT 4.0|Communication via NetBIOS interface|
|SMBv1|Windows 2000|Direct connection via TCP|
|SMBv2|Windows Vista, Windows Server 2008|Performance upgrades, improved message signing, caching feature|
|SMBv2.1|Windows 7, Windows Server 2008 R2|Locking mechanisms|
|SMBv3|Windows 8, Windows Server 2012|Multichannel connections, end-to-end ecnryption, remote storage access|
|SMBv3.0.2|Windows 8.1, WIndows Server 2012 R2| |
|SMBv3.1.1|Windows 10, Windows Server 2016|Integrity checking, AES-128 encryption|

* With v3, Samba server gained the ability to be a full member of an AD domain.
* With v4, Samba even provides an AD DC. It contains several so-called daemons for this purpose - which are Unix background programs
* The SMB server daemon (`smbd`) belonging to Samba provides the first two functionalities, while the NetBIOS message block daemon (`nmbd`) implements the last two functionalities. The SMB service controls these two background programs
* In a network, each host participates in the same workgroup
  * a workgroup is a group name that identifies an arbitrary collection of computers and their resources on an SMB network.
  * there can be multiple workgroups on the network at any given time
  * IBM developed an API for newtorking computers called the `Network Basic Input/Output System` (NetBIOS)
  * the NetBIOS API provided a blueprint for an application to connect and share data with other computers
  * when a machine goes online, it needs a name, which is done through the `name registration` procedure.
  * Either each host reserves its hostname on the newtork, or the `NetBIOS Name Server` (NBNS) is used for this

### Settings
Located at `/etc/samba/smb.conf`
| Settings                       | Description                                                           |
| :----------------------------- | :-------------------------------------------------------------------- |
| [sharename]                    | The name of the newtork share                                         |
| `workgroup = WORKGROUP/DOMAIN` | Workgroup that will appear when lients query                          |
| `path = /path/here`            | The directory to which user is to be given access                     |
| `server string = STRING`       | The string that will show up when a connection is initiated           |
| `unix password sync = yes`     | Synchronize the UNIX password with the SMB password?                  |
| `usershare allow guests = yes` | Allow non-authenticated users to access defined share?                |
| `map to guest = bad user`      | What to do when a user login request doesn't match a valid UNIX user? |
| `browseable = yes`             | Should this share be shown in the list of available share?            |
| `guest ok = yes`               | Allow connecting to the service without using a password?             |
| `read only = yes`              | Allow user to read files only?                                        |
| `create mask = 0700`           | What permissions need to be set for newly created files?              |
| **Dangerous Settings**         |                                                                       |
| `browseable = yes`             | Allow listing available shares in the current share?                  |
| `read only = no`               | Forbid the creation and modification of files?                        |
| `writeable = yes`              | Allow users to create and modify files?                               |
| `guest ok = yes`               | Allow connecting to the service without using a password?             |
| `enable privileges = yes`      | Honor privileges assigned to specific SID?                            |
| `create mask = 0777`           | What permissions must be assigned to the newly created files?         |
| `directory mask = 0777`        | What permissions must be assigned to the newly created directories?   |
| `logon script = script.sh`     | What script should needs to be executed on the user's login?          |
| `magic script = script.sh`     | Which script should b executed when the script gets closed?           |
| `magic output = script.out`    | Where the output of the magic script needs to be stored?              |

### RPCclient
`rpcclient -U "" <ip>`

| Query                     | Description                                                       |
| :------------------------ | :---------------------------------------------------------------- |
| `srvinfo`                 | Server information                                                |
| `enumdomains`             | Enumerate all domains that are deployed in the network            |
| `querydominfo`            | Provides domain, server, and user information of deployed domains |
| `netshareenumall`         | enumerate all available shares                                    |
| `netsharegetinfo <share>` | provides information about a specific share                       |
| `enumdomusers`            | Enumeratesall domain users                                        |
| `queryuser <RID>`         | Provides information about a specific user                        |
