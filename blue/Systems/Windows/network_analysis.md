# Network Analysis
```powershell
# Base Command 
Get-NetTcpConnection 

# List Listening and Established 
Get-NetTcpConnection -State Listen,Established 

# List Listening and Established and Sort Remote Port Least to Greatest 
Get-NetTcpConnection -State Listen,Established | Sort-Object RemotePort 

# List All Property Details of Connections 
Get-NetTcpConnection -State Listen,Established | Select-Object -Property * 

# List Specific Property Details of Connections 
Get-NetTcpConnection -State Listen,Established | Select-Object -Property State,CreationTime,OwningProcess,Local*,Remote*
```