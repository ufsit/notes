# Managing Shares
```powershell
# List SMB Shares 
Get-SmbShare 

# Remove a SMB Share 
Remove-SmbShare -Name <NAME> 

# Check if SMBv1 is Enabled (BAD IF ENABLED) 
Get-SmbServerConfiguration | Select EnableSMB1Protocol 

# Disable SMBv1 if Enabled 
Set-SmbServerConfiguration -EnableSMB1Protocol 0 

# Check if SMBv2 is Enabled (replacement for SMBv1) 
Get-SmbServerConfiguration | Select EnableSMB2Protocol 

# Enable SMBv2 if Disabled 
Set-SmbServerConfiguration -EnableSMB2Protocol 1
```