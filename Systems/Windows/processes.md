# Process Management
```powershell
# List Processes 
Get-Process 

# Find Process Information 
Get-Service -Name <NAME> | Select-Object -Property * 

# Stop the Process 
Stop-Process -Name <NAME> 

# OR 
Stop-Process -Id <INTEGER_ID>
```