# Linux to Windows cheat sheet
|Action|Linux|Windows|
|:-|:-|:-|
|search in files|`grep pattern file`|`Select-String -Pattern pattern file`|
|find files (ex .txt files)|`find /path -name "*.txt"`|`Get-Children -Path /path -Recurse -Filter *.txt -ErrorAction SilentlyContinue`|
||`kill PID`|`Stop-Process -Id PID -Force`  |
|disk usage |`df -h`|`Get-PSDrive` |
|total visble memory|`free -h` |`Get-CimInstance Win32_OperatingSystem`|
|Computer Information|`uname -a`|`Get-ComputerInfo`  |
|network info|`ip a`|`Get-NetIPAddress`|
|show active connections |`netstat -tuapn`|`Get-NetTCPConnection` and `Get-NetUDPEndpoint`|
|fetch web content|`curl url`|`Invoke-WebRequest url`|
|download file |`Invoke-WebRequest url -OutFile file`|`wget url`|
|show usr privs and groups|`id`|`whoami /all`|
|list environment vars|`env`|`Get-ChildItem Env:` |
|binary source|`which [cmd]`| `Get-Command [cmd]`|
|show routing table|`ip route`|`Get-NetRoute` |
|resolve a domain|`dig some.domain.com` and `nslookup`|`Resolve-DnsName domain`  |
|process analysis|`ps -aux`|`Get-Process`|
|service status|`service name status`|`Get-Service -Name name`|
|service start/stop|`service name stop/start`|`Stop-Service -Name name`/`Start-Service -Name name`  |
|logged in users|`who -u`|`query user`|
|add a user|`adduser name`|`New-LocalUser name` |
|password change|`passwd user`|`Set-LocalUser -Name user -Password (Read-Host -AsSecureString)`  |
|delete a user|`userdel name`|`Remove-LocalUser name`|
|view sys logs|`journalctl -xe`|`Get-WinEvent -LogName System -MaxEvents 20`|
|moniter live logs|`tail -f /var/syslog`|`Get-Content -Path C:\Windows\System32\winevt\Logs\System.evtx -Wait`|
|create alias|`alias`|`Get-Alias`, `Set-Alias alias cmd`, `Remove-Item Alias:alias`|
|word search|`grep`|`findstr`|
|create a file|`touch`|`New-Item`|
  
