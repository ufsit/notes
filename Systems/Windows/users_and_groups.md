# Managing Users and Groups
* List local users
```powwershell
Get-LocalUser
```
* Add a local user, prompts for a password 
```powershell
New-LocalUser -Name "TestUser" -FullName "Test User" -Description "User for tests"
```

* Disable a local user
```powershell
Disable-LocalUser -Name "<user>"
```

* Remove a user
```powershell
Remove-LocalUser -Name "<user>"
```

* Add local user to local group
```powershell
Add-LocalGroupMember -Group "<group>" -Member "<user>"
```

* Remove local group
```powershell
Remove-LocalGroup -Name "<group>"
```

* Display all information on local users
```powershell
Get-LocalUser | Select-Object *
```