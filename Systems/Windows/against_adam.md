# Going through Adam Crow's windows slides and making defenses
https://docs.google.com/presentation/d/1b4aMRHCkMAyvT-2Hnvr6GwgheSTolL4L5VN97oONhv8/edit?slide=id.g39df437c524_0_23#slide=id.g39df437c524_0_23
## Server Message Block (SMB) - Password Attacks
### Null Session & Anonymous login
* Local Computer Policy, navigate to Computer Configuration\Administrative Templates\Network\Lanman Workstation  
  * **Disable** insecure guest logons  
* Go to Turn Windows features on or off
  * uncheck "SMB 1.0/CIFS File Sharing Support
* Turn off Null sessions
  * 1. Network access: Allow anonymous SID/Name translation; 2. Network access: Do not allow anonymous enumeration of SAM accounts; 3. Network access: Do not allow anonymous enumeration of SAM accounts and shares; 4. Network access: Let Everyone permissions apply to anonymous users; 5. Network access: Named Pipes that can be accessed anonymously; 6. Network access: Shares that can be accessed anonymously
  * disable policies 1 and 4, enable policies 2 and 3, and specifying empty lists for policies 5 and 6.
### Password Spraying
* Make a lockout policy
### EternalBlue
* Turn on SMB signing
## Remote Desktop Protocol
### BlueKeep
* **Enable** Require user authentication for remote connections by using Network Level Authentication in security group policies
### DejaBlue
* Disable old protocols: TLS 1.0, RC4, and RDP 8.0 if possible
### Clipboard/Drive Redirection Abuse
* Computer Configuration → Administrative Templates → Windows Components → Remote Desktop Services → Remote Desktop Session Host → Device and Resource Redirection
  * Do not allow drive redirection → Enabled
  * Do not allow clipboard redirection → Enabled
## Windows Remote Management (WinRM)
### EvilWinRM
* *needs to be tested*
  ```
  # Disable unencrypted
  winrm set winrm/config/service @{AllowUnencrypted="false"}
  # Disable Basic auth & CredSSP; allow Kerberos/Negotiate
  winrm set winrm/config/service/auth @{Basic="false"; CredSSP="false"; Kerberos="true"; Negotiate="true"}
  ```
## Lightweight Directory Access Protocol (LDAP) - Queries
### LDAP enumeration
```
Get-Item "AD:\CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,DC=<domain>,DC=com" | 
Select-Object -ExpandProperty dsHeuristics
```
If it is null or doesn't include a 2 at the 7th character then it's fine
If it is anything else:
* Active Directory Service Interfaces (ADSI Edit)
  * Configuration → Services → Windows NT → Directory Service
    * Open Properties → dsHeuristics, ensure it does not contain 2 in position 7
* Computer Configuration → Windows Settings → Security Settings → Local Policies → Security Options
  * Domain controller: LDAP server signing requirements: → Require signing
  * Domain controller: LDAP client signing requirements: → Require signing
## Microsoft SQL Server (MSSQL)
### MSSQL Enumeration
Run this as a sysadmin in SQL Server Management Studio (or via sqlcmd):
```
-- Check current status:
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE WITH OVERRIDE;
EXEC sp_configure 'xp_cmdshell';

-- Disable xp_cmdshell
EXEC sp_configure 'xp_cmdshell', 0;
RECONFIGURE WITH OVERRIDE;
```
## Kerberos
### Kerberoasting
* Computer Configuration → Administrative Templates → System → KDC → Supported Encryption Types for Kerberos
  * Set it to allow only AES256 and AES128
cmd to test
```
New-ADFineGrainedPasswordPolicy -Name "ServiceAccountPolicy" -Precedence 1 -MinPasswordLength 50 -PasswordComplexityEnabled $true -PasswordHistoryCount 24
Add-ADFineGrainedPasswordPolicySubject -Identity "ServiceAccountPolicy" -Subjects "svc_sql","svc_iis"
```
### AS-REP Roasting
* Turn on requiring pre-auth for keberos
## Coercion & Relay Attacks
### Coercion Attacks
* Disable NTLM
* Turn on SMB signing
  * Microsoft network server: Digitally sign communications (always) — Enabled.
  * Microsoft network client: Digitally sign communications (if server agrees) — Enabled
### Relay & Hash Capture
* Turn on SMB signing
* Disable NTLM
* Also test out:
  * Computer Configuration → Administrative Templates → Network → DNS Client → Turn off multicast name resolution = Enabled
## noPAC
* Check who can create system accounts, need more testing and looking into to get a concrete plan for this
## PrintNightmare
* Easiest way is to disable the Spooler service using Stop-Service
* Computer Configuration → Administrative Templates → Printers → Allow Print Spooler to accept client connections = Disabled
## Sticky Keys
* Open Settings → Go to Accessibility (Windows 11) or Ease of Access (Windows 10) → Keyboard → Under Sticky keys, toggle Off → ALSO turn off any boxes for shortcuts like “Allow the shortcut key to start Sticky Keys”
