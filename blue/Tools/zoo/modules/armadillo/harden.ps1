# armadillo payload (windows): general hardening posture (report only).
Write-Host "===== LOCAL ADMINISTRATORS ====="
try { Get-LocalGroupMember -Group Administrators | ForEach-Object { $_.Name } } catch { net localgroup administrators }

Write-Host "`n===== SMBv1 (should be False) ====="
try { (Get-SmbServerConfiguration).EnableSMB1Protocol } catch { Write-Host "unknown" }

Write-Host "`n===== FIREWALL PROFILES ====="
try { Get-NetFirewallProfile | ForEach-Object { "{0}: {1}" -f $_.Name, $_.Enabled } } catch { netsh advfirewall show allprofiles state }

Write-Host "`n===== NON-SYSTEM SERVICE ACCOUNTS ====="
Get-WmiObject Win32_Service | Where-Object { $_.StartName -and $_.StartName -notlike "NT *" -and $_.StartName -ne "LocalSystem" } | ForEach-Object { "{0} -> {1}" -f $_.Name, $_.StartName }

Write-Host "`n===== LISTENING PORTS ====="
try { Get-NetTCPConnection -State Listen | Select-Object -ExpandProperty LocalPort | Sort-Object -Unique } catch { netstat -ano | Select-String "LISTENING" }

Write-Host "`n===== UAC (EnableLUA, should be 1) ====="
try { (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System").EnableLUA } catch { Write-Host "unknown" }
