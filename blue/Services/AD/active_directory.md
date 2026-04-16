# Active Directory Overview
* **Active Directory (AD)**
  * Microsoft's directory service
  * stores data objects on your local network environment
  * records data on users, devices, applications, groups, and devices in a hierarchical structure
  * The server that runs this service is called the **Domain Controller (DC)**
* **Windows Domain**
  * A group of users and computers under the administration of a business
  * AD centralizes administration of a domain

# Install AD
* Must have *Windows Professional* or *Windows Enterprise*
### Method 1
* Settings $\rightarrow$ Apps $\rightarrow$ Manage optional features $\rightarrow$ Add Features
* Select `Active Directory Domain Services and Lightweight Directory Tools`
* Select `Install`

### Method 2
* Control Panel $\rightarrow$ Programs $\rightarrow$ Programs and Features $\rightarrow$ Turn Windows features on or off
* Select `Remote Server Administration Tools`
* Select `Role Administration Tools`
* Select `AD DS` and `AD LDS Tools`
  * Verify `AD DS Tools` has been automatically checked
* Select `Ok`

# How to Set Up a Domain Controller
* install AD on the server
### Configure Domain Controller
1. Assign a static IP address to the DC
2. Open `Server Manager`, then select `Roles Summary` $\rightarrow$ `Add Roles and features`
3. Select `Next`
4. Select `Remote Desktop Services Installation` (if you're on a VM), or `role-based` or `featured-based installation`
5. Select a server from the pool
6. Select `Active Directory Domain Services` from the list and select `Next`
7. Leave the Features checked by default and press `Next`
8. Click `Restart the destination server automatically if required` and click `Install`. Close the window once complete 
9. Once the AD DS role has been installed a notification will display next to the `Manage` menu. Press `Promote this server into a domain controller`
10. Now click `Add a new forest` and enter a `Root domain name`. Press `Next`. 
11. Select the `Domain functional level` you desire and enter a password into the `Type the Directory Services Restore Mode (DSRM password)` section. Click `Next`. 
12. When the DNS Options page displays click `Next`. 
13. Enter a domain in the `NetBios Domain name` box (usually the same as root domain name). Press `Next`. 
14. Select a folder to store your database and log files. Click `Next`. 
15. Press `Install` to finish. The system will reboot.

# AD Objects
## Users
* most common object type in AD
* an example of a `security principal`:
  * these objects can be authenticated by the domain, receive privileges over **resources** (i.e. files)
  * an entity that can affect resources in the network
* **Users** can represent two types of entities:
  * **People**: represents actual people in the organization
  * **Services**: normal services require a **user account** to be able to run; these accounts have special permissions to reflect this

## Machines
* an *machine object* is created for every computer that joins the AD domain
* considered *security principals* and are assigned an account like a normal user
  * this account is somewhat limited rights
* machine accounts themselves are local administrators on the assigned computer

## Groups
* you can define and assign user group objects certain access rights (permission) to resources
* **Security groups**: considered *security principals* and have certain privileges over resources on the newtork; a user can be a part of many security groups. 
* Groups can have both users and machines as members, and even other groups

|**Security Group**|**Description**|
|:-|:-|
|Domain Admins|Have administrative privilegse over the entire domain; by default, they can administer any computer on the domain|
|Server Operators|Can administer Domain Controllers; cannot change any administrative group memberships|
|Backup Operators|Have access to any file, ignoring their permissions; used to perform backups of data on computer|
|Account Operators|Can create or modify other accounts in the domain|
|Domain Users|All existing user accounts in the domain|
|Domain Computers|All existing computers in the domain|
|Domain Controllers|All existing DCs on the domain|

# Active Directory Users and Computers
* management console for users and computers
* shows the hiearchy of users, computers, and groups that exist in the domain
## Organizational Units (OUs)
* Containers for organizing the above objects
  * Some default containers:
  * **Computers**: any machine joining the network; they're put here by default
    * can be useful to divy up machines into proper OUs (put servers and workstations in separate OUs to apply policies more easily)
  * **Domain Controllers**: the OU for the DCs
  * **Users**: default OU for domain-wide users and group
  * **Managed Service Accounts**: accounts used by service in the Domain
* A user can only be a member of a single OU at a time
* OUs can be referenced by policies
* To delete an OU,
  * enable `Advaned Features` in the `View` tab.
  * right-click on an OU, open `Properties`, open `Object` tab, disable protection

### Delegation
* To give users control over an OU
* meant to allow a user to perform administrative tasks without the Domain Administrator's constant approval
* To delegate:
  * Right-click on an OU, select `Delegate Control`
  * add users in the new window, and specify tasks for each added user

# Group Policy
* We can manage configurations to users through **Group Policy Objects (GPOs)**
  * one GPO is a collection of policies/settings that are applied onto OUs
## Group Policy Management
* the console for managing domain-level GPOs
* You create a GPO under **Group Policy Objects**, then link it to the OU you want the policies to apply to
  * any GPO linked to an OU will also apply to any sub-OUs under it
* When selecting a GPO, 
  * you can see its **scope**, showing where the GPO is linked to 
  * apply **security filterin**: GPO only affects specific entities under an OU
    * by default, GPOs apply to **Authenticated Users** group (includes all users and PCs)
  * inspect the **Settings** tab, containing the actual contents of the GPO
* **Default Domain Policy** GPO indicates basic configuration that should apply to most domains (e.g. password and account policies)
* To edit a policy, right-click on a GPO and select `Edit`
* `SYSVOL`: the DC network share where GPOs are distributed from

# AD Forests and Trees
* a **tree** is an entity wit a single domain or group of objects that is followed by child domains
  * many trees make a forest
* a **forest** is a group of domains put together
* Trees in a forest connect to each other through **trust relationships**
  * lets domains share information
  * all domains trust each other automatically (a user in another domain can still login)
* Each forest uses one unified database
  * this db sits on the highest level of the hierarhcy (tree is at the bottom)
* Many types of forest designs:
  * **Single-Forest Design** - easier to manage
  * **Multi-Forest design** - increases security, a nightmare for administrative tasks

## Trust Relationships and Types
* **Trusts** facilitate communication between domains (authentication, resource access)
  * the domains can be a *trusting domain* or a *trusted domain*. 
* one-way trust:
  * the trusting domain accesses the authentication details of the trusted domain
* two-way trust:
  * both domains accept the other's authentication details
* by default, all trusts are two-way<br><br>
* Use `New Trust Wizard` for creating trusts
  * can inpect the `Domain Name`, `Trust Type`, and `Transitive` status of existing trusts

|**Trust Type**|**Transit Type**|**Direction**|**Default**|**Description**|
|:-|:-|:-|:-|:-|
|Parent and Child|Transitive|Two-Way|Yes|Established when a child domain is added to a domain tree|
|Tree-root|Transitive|Two-Way|Yes|Established the moment a domain tree is created within a forest|
|External|Non-Transitive|One-way or Two-way|No|Provides access to resources in a Windows NT 4.0 domain or a domain located in a different forest that isn't supported by a forest trust|
|Realm|Transitive or non-transitive|One-way or Two-way|No|Forms a trust relationship between a non-Windows Kerberos realm and a Windows Server 2003 domain|
|Forest|Transitive|One-way or Two-way|No|Shares resources between forests|
|Shortcut|Transitive|One-way or Two-way|No|Reduces user logon times between two domains within a Windows Server 2003 forest|

