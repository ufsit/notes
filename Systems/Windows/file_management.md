# File Management
```powershell
# Delete a File 
Remove-Item -Path <PATH> -Force 

# Recursively Remove Files 
Remove-Item -Path <PATH> -Recurse 

# Remove Files with Special Characters 
(Get-ChildItem = ls) (` = ESC Char) Get-ChildItem | Where-Object Name -Like '*`[*' | ForEach-Object {Remove-Item - LiteralPath $_.Name}

# View contents of a directory, and hidden files
Get-ChildItem -Force \\path\to\directory

# makes a new folder 
New-Item -Path '\\fs\Shared\NewFolder' -ItemType Directory 

# makes a new file 
New-Item -Path '\\fs\Shared\NewFolder\newfile.txt' -ItemType File 

# creates a file and writes data to it 
$text = 'Hello World!' | Out-File $text -FilePath C:\data\text.txt

# Copy a file from one host to another
Copy-Item -Path \\path\to\file.txt -Destination \\path\to\remote\file.txt

# copy files from local directory to remote folder 
Copy-Item C:\data\ -Recurse \\fs\c$\temp

# moves specific backup file from one location to another 
Move-Item -Path \\fs\Shared\Backups\1.bak -Destination \\fs2\Backups\archive\1.bak

# rename an object without changing it
Rename-Item -Path "\\fs\Sahred\temp.txt" -NewName "new_temp.txt"
```

# Permissions
* `SetAccessRule` overwrites 
  * `AddAccessRule` to append a permission
```powershell
$acl = Get-Acl \\fs1\shared\sales 
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("ENTERPRISE\T.Simpson","FullCont rol","Allow") 
$acl.SetAccessRule($AccessRule) 
$acl | Set-Acl \\fs1\shared\sales 
```

* To copy permissions, own both targets
```powershell
Get-Acl \\fs1\shared\accounting | Set-Acl \\fs1\shared\sales
```

* To remove permissions, use RemoveAccessRule
```powershell
$acl = Get-Acl \\fs1\shared\sales $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("ENTERPRISE\T.Simpson","FullCont rol","Allow") $acl.RemoveAccessRule($AccessRule) $acl | Set-Acl \\fs1\shared\sales
```

* To wipe a user's permissions, use the `PurgeAccessRules`, only works with SIDs and explicit permissions, not inherited ones

# Inheritance
* `SetAccesRuleProtection($bool, $bool)` to manage inheritance
  * first parameter: blocking inheritance from parent folder
  * second parameter: whether current inherited permissions are retained or removed
```powershell
# disabling inheritance for "sales" and deleting any inherited permissions 
$acl = Get-Acl \\fs1\shared\sales 
$acl.SetAccessRuleProtection($true,$false) 
$acl | Set-Acl \\fs1\shared\sales
```

# Ownership
* `SetOwner` to set a folder owner
  * The target account must have "Take Ownership", "Read", and "Change Permissions" on the target folder
```powershell
$acl = Get-Acl \\fs1\shared\sales 
$object = New-Object System.Security.Principal.Ntaccount("ENTERPRISE\J.Carter") 
$acl.SetOwner($object) 
$acl | Set-Acl \\fs1\shared\sales 
```
### Access Rights
|**Access Right**|**PS Name**|
|:-|:-|
|Full Control|FullControl|
|Traverse Folder/Execute File|ExecuteFile|
|List Flder/Read Data|ReadData|
|Read Attributes|ReadAttributes|
|Read Extended Attributes|ReadExtendedAttributes|
|Create Files/Write Data|Create Files|
|Create Folder/Append Data|AppendData|
|Write Attributes|WriteAttributes|
|Write Extendede Attributes|WriteExtendedAttributes|
|Delete Subfolders and Files|DeleteSubdirectoriesAndFiles|
|Delete|Delete|
|Read Permissions|ReadPermissions|
|Change Permissions|ChangePermissions|
|Take Ownership|TakeOwnership|

### Access Rights Sets
|**Access Rights Set**|**Rights Included**|**PS Name**|
|:-|:-|
|Read|List Folder/Read Data<br> Read Attributes<br> Read Extended Attributes<br>Read Permissions|Read|
|Write|Create Files/Write Data <br> Create Folders / Append Data <br> Write Attribvutes <br> Write Extended Attributes|Write|
|Read and Execute|Traverse Folder/Execute File <br> List Folder/Read Data <br> Read Attributes <br> Read Extended Attributes <br> Read Permisssions|ReadAndExecute|
|Modify|Traverse Folder/Execute File <br> List Folder / Read Data <br> Read Attributes <br> Read Extended Attributes <br> Create Files/Write Data <br> Create Folders/Append Data <br> Write Attributes <br> Write Extended Attributes <br> Delete <br> Read Permissions|Modify|