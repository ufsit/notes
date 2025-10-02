# Managing Applications and Software
* Standard Installation
```powershell
Start-Process C:\Doc\7zip.exe
```

* Silent Installation
  * `/s /v/qn` options for silent installation
```powershell
Start-Process C:\Doc\winRAR.exe -ArgumentList "/s /v/qn"
```

* List installed applications
```powershell
Get-WmiObject -Class Win32_Product
```

* Search installed applications
```powershell
Get-WmiObject -Class Win32_Product | Select-Object -Property Name
```

* Uninstall through `Uninstall()`, good for programs listed by previous command
```powershell
$app = Get-WmiObject -Class Win32_Product | Select-Object -Property Name
$app.uninstall()
```

* If PowerShell does not list a program:
```powershell
Get-Package -Provider Programs -IncludeWindowsInstaller -Name "NAME"
Uninstall-Package -Name NAME
```