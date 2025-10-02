# Managing Scheduled Tasks
```PowerShell
# Set user env variable for later
$User = "Doe"

# List Ready/Running tasks, save to a file
Get-ScheduledTask | Where State -in "Ready","Running" | Set-Content -Path C:\Users\$User\Desktop\Connections.txt 

# Enable a Task (Good for Update or Windows Defender)
Enable-ScheduledTask -TaskName "<NAME>" 

# Enable ALl Tasks in a Folder 
Get-ScheduledTask -TaskPath "\WindowsDefender\" | Enable-ScheduledTask 

# Disable a Task (Disable Any Malicious Task) 
Disable-ScheduledTask -TaskName 

# Disable ALl Tasks in a Folder 
Get-ScheduledTask -TaskPath "\WindowsDefender\" | Disable-ScheduledTask 

# Unregister or Remove a Scheduled Task 
Unregister-ScheduledTask -TaskName "<NAME>" 

# Stop a Scheduled Task 
Stop-ScheduledTask -TaskName "<NAME>" 

# Stop All Tasks in a Folder 
Get-ScheduledTask -TaskPath "<PATH>" | Stop-ScheduledTask
```