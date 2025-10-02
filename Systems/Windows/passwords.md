# Passwords
* Resetting a password
```powershell
$Password = Read-Host -AsSecureString
-> [Enter Password]
$UserAccount = Get-LocalUser -Name <user>
$UserAccount | Set-LocalUser -Password $Password
```

* Modify Local Password Policies
  * Local Group Policy Editor $\rightarrow$ Computer Configuration $\rightarrow$ Windows Settings $\rightarrow$ Security Settings $\rightarrow$ Account Policies $\rightarrow$ Password Policy