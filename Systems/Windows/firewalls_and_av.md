# Firewall 
* status on firewall profiles
  * `Get-NetFirewallProfile`
* Enable all profiles
  * `Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True`
* Enable logging on all profiles
  * `Set-NetFirewallProfile -All -LogAllowed 1`
* Show status of Defender
  * `Get-MpComputerStatus`
* Update Anti-Malware signatures
  * `Update-MpSignature`

# Windows Defender
* Start a Defender scan
  * `Start-MpScan -ScanType FullScan`
* List previously handled threats
  * `Get-MpThreat`
* List active and past threats
  * `Get-MpThreatDetection`
* Reinstall Defender
  * `Get-AppxPackage Microsoft.SecHealthUI -AllUsers | Reset-AppxPackage`

# Malwarebytes
* Third party, free AV 
