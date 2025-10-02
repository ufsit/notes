# Service Management
```powershell
# List Services 
Get-Service 

# Find Service Information 
Get-Service -Name <NAME> | Select-Object -Property * 

# Stop Service (e.g., get rid of print "Spooler") 
Stop-Service -Name <NAME> 

# Change Service Startup Type to Disabled 
Set-Service <NAME> -StartupType Disabled 
```