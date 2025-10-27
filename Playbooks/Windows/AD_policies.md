# Active Directory Group Policy Playbook 
The order of doing these things is flexible  
All of these will be in the group policy editor  
For most of these changes you should run ```gpupdate /force``` to make sure the changes take effect  
*Note: atm this is local paths but some are different in domain policies*
## Local Computer Policy $\rightarrow$ Computer Configurations $\rightarrow$ Windows Settings $\rightarrow$ Security Settings $\rightarrow$ Account Policies
### In Password Policy change:  
* Enforce password history to 3-5 (just make sure it isn't **0**)
* Set min password length to at least 8 characters
* Make sure complexity requirements is enabled
* Make sure storing password using reversible encryption is **disabled**
### In Account Lockout Policy
* Set lockout threshold to at least 2-3
* Change the other two settings accordingly
## Local Computer Policy $\rightarrow$ Computer Configurations $\rightarrow$ Windows Settings $\rightarrow$ Security Settings $\rightarrow$ Local Policies
### Audit Policy
We will be auditing things in other places, however, if logs are not being generated start turning things on here  
### User Rights Assignment
Here you can choose who can access the machine which can be changed on a competition to competition basis  
* Should deny access to this computer from the network of the Guest and Anonymous Logon accounts
### Security Options
**This is a big one**  
* Disable the guest account if not already and if you have an account with admin perms also the Administrator account
* Could rename the admin account here if team deems it acceptible
* Accounts: Limit local account use of blank passwords to connect logon only: **Enabled**
* Domain Controller: LDAP server signing requirements **Required Signing**
* Domain Member: Require strong (Windows 2000 or later) session key: **Enabled**
* Domain member: Digitall encrypt or sign secure channel data (always): **Enabled** (enable the when possible for these rules as well just in case)
* Audit: Force audit policy subcategory settings (Windows Vista or later) to override audit policy category settings: **Enabled**
* Devices: Prevent users from installing printer drivers: **Enabled**
* Interactive logon: Number of previous logons to cache (in case domain controller is not available): **0**
* Interactive logon: Require Domain Controller authentication to unlock workstation: **Enabled**
* Microsoft network client: Digitally sign communications (always): **Enabled**
* Microsoft network server: Digitally sign communications (always): **Enabled**
* Network access: Allow anonymous SID/Name translation: **Disabled**
* Network access: Do not allow anonymous enumeration of SAM accounts: **Enabled**
* Network access: Do not allow anonymous enumeration of SAM accountsand shares: **Enabled**
* Network access: Let Everyone permissions apply to anonymous users: **Disabled**
* Network access: Restrict anonymous access to Named Pipes and Shares: **Enabled**
* Network access: Shares that can be accessed anonymously: Type in **None**
* Network access: Do not allow storage of passwords and credentials for network authentication: **Enabled**
* Network security: Allow LocalSystem NULL session fallback: **Disabled**
* Network security: Do not store LAN Manager hash value on next password change: **Enabled**
* Network security: Configure encryption types allowed for Kerberos: Allow only both AES encryption types
* Network security: Force logoff when logon hours expire: **Enabled**
* Network security: LAN Manager authentication level: **Send NTLMv2 response only. Refuse LM & NTLM**
* Network Security: LDAP client signing requirements: **Require signing**
* Network security: Restrict NTLM: Incoming/Outgoing NTLM traffic: **Deny all** (make sure none of your serrvices are legacy services that require NTLM if they do audit instead)
* Recovery console: Allow automatic administrative logon: **Disabled**
* System objects: Strengthen default permissions of internal system objects (e.g., Symbolic Links): **Enabled**
* User Account Control: Detect application installations and prompt for elevation: **Enabled**
* User Account Control: Run all administrators in Admin Approval Mode: **Enabled**
* User Account Control: Behavior of the elevation prompt for administrators in Admin Approval Mode: **Prompt for consent on the secure desktop**
## Computer Configuration → Windows Settings → Security Settings → Advanced Audit Policy Configuration → System Audit Policies
## Logon/Logoff
* Audit Logon: **Success and Failure**
* Audit Logoff: **Success**
* Audit other Logon/Logoff Events: **Success and Failure**

## Computer Congifuration $\rightarrow$ Administrative Templates $\rightarrow$ System $\rightarrow$ Kerberos
* Alwyas send compound authentication first: **Enabled**
* Require strict target SPN match on remote procedure calls: **Enabled**
* Require strict KDC validation: **Enabled**
