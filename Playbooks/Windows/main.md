<!-- Inheritance from Alex Christy -->
# Windows ASAP Tasks
- Roll passwords (script link here)
- Disable guest account ```net user guest /active:no``` and possibly the Administrator account if given another account that has the same perms
- RDP enabled on firewall
  - Windows Defender Firewall with Advanced Security $\rightarrow$ Inbound Rules
    * Use presets for RDP
    * Terminal
       * `New-NetFirewallRule -Displayname "Allow RDP" -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow` 
       * `Set-NetFirewallProfile -Profile Domain,Private,Public -DefaultInboundAction Block`
- Verify Firewall enabled
  - Control Panel $\rightarrow$ System and Security $\rightarrow$ Windows Defender Firewall $\rightarrow$ Turn Windows Defender Firewall on or off $\rightarrow$ Turn on Windows Defender Firewall (for private, public, and domain networks)
* Verify Group Policy: `Win+R` `gpedit.msc`
  * **Windows Update**
    * Computer Configuration $\rightarrow$ Administrative Templates $\rightarrow$ Windows Components $\rightarrow$ Windows Update $\rightarrow$ Manage End user Experience $\rightarrow$ Configure Automatic Updates: "Enabled"
  * **Windows Defender**
    * Computer Configuration $\rightarrow$ Windows Components $\rightarrow$ Microsoft Defender Antivirus $\rightarrow$ Real-time protection $\rightarrow$  Turn off real-time protection: Disabled
  * **Windows Firewall**
    * Computer Configruation $\rightarrow$ Policies $\rightarrow$ Administrative Templates $\rightarrow$ Network $\rightarrow$ Network Connections $\rightarrow$ Windows Defender $\rightarrow$ Firewall $\rightarrow$ Domain Profile $\rightarrow$ Enable Windows Firewall: Enabled
  * **Control Panel Access**
    * User Configuration $\rightarrow$ Policies $\rightarrow$ Administrative Templatse $\rightarrow$ Control Panel $\rightarrow$ Prohibit Acess to Control Panel and Settings: Disabled
* Find Users with Kerberos No Preauthentication
  * `Get-ADUser -Filter { DoesNotRequirePreAuth -eq $true } -Properties DoesNotRequirePreAuth | select SamAccountName, DoesNotRequirePreAuth`
  * To fix run ```Get-ADuser -Filer {DoesNotRequirePreAuth -eq $true} | ForEach-Object { Set-ADUser $_ -Replace @{DoesNotRequirePreAuth=$false} }```
  * `Get-ADAccountControl - Identity "username" -TRUSTED_FOR_DELEGATION $true`
* Reset Kerberos Creds
  * https://github.com/zjorz/Public-Ad-Scripts/blob/master/Reset-KrbTgt-Password-For-RWDCs-And-RODCs.ps1
* Download AutoRuns from live.systernals.com
* Fix Certificate templates
  * Expand-Archive -Path Locksmith.zip -DestinationPath
  * Import-Module Locksmith.psd1
  * Invoke-Locksmith -Mode 4 #Listen to instructions, follow anything in comments
* Disable SPNs for users
  * `setspn -I <computer_name>`: list SPNs
  * `setspn -d service/name hostname`
# Windows Emergency Sheet
> **WARNING**: The following are likely to break things

* Reset All Group Policies
  * `RD /S /Q "%WinDir%\System32\GroupPolicyUsers" && RD /S /Q "%WinDir%\System32\GroupPolicy"`
  * `gpupdate /force`
* Disable the Firewall
  * `netsh advfirewall set currentprofile state off`
* Edit Group Policy from command line
  * `LGPO.exe`
  * https://www.microsoft.com/en-us/download/details.aspx?id=55319
