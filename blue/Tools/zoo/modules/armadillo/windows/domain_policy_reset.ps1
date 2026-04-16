# ===============================
# Pre-Reset GPO Backup (HTML + TXT)
# ===============================

Write-Host "Backing up existing GPO settings..." -ForegroundColor Yellow

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$workingDir = Get-Location

$backupGpos = @(
    "Default Domain Policy",
    "Default Domain Controllers Policy"
)

foreach ($gpoName in $backupGpos) {

    try {
        $gpo = Get-GPO -Name $gpoName -ErrorAction Stop
    }
    catch {
        Write-Warning "Skipping backup: $gpoName not found."
        continue
    }

    $baseName = $gpoName.Replace(" ", "_")

    # HTML report (full settings)
    $htmlPath = Join-Path $workingDir "$baseName`_PRE_RESET_$timestamp.html"
    Get-GPOReport `
        -Guid $gpo.Id `
        -ReportType Html `
        -Path $htmlPath

    # TXT report (summary + permissions)
    $txtPath = Join-Path $workingDir "$baseName`_PRE_RESET_$timestamp.txt"

    $txtContent = @()
    $txtContent += "GPO Name: $($gpo.DisplayName)"
    $txtContent += "GUID: $($gpo.Id)"
    $txtContent += "Creation Time: $($gpo.CreationTime)"
    $txtContent += "Modification Time: $($gpo.ModificationTime)"
    $txtContent += "User Version: $($gpo.User.DSVersion)"
    $txtContent += "Computer Version: $($gpo.Computer.DSVersion)"
    $txtContent += ""
    $txtContent += "=== Security Filtering & Delegation ==="

    Get-GPPermission -Guid $gpo.Id -All | ForEach-Object {
        $txtContent += "$($_.Trustee.Name) [$($_.TrusteeType)] : $($_.Permission)"
    }

    $txtContent | Out-File -FilePath $txtPath -Encoding UTF8

    Write-Host "Backed up $gpoName" -ForegroundColor Green
}

Write-Host "Pre-reset GPO backup completed." -ForegroundColor Cyan

Write-Host "Starting secure domain policy reset..." -ForegroundColor Cyan

# ===============================
# Helper: SHA256 Hash (PS 3.0)
# ===============================
function Get-SHA256Hash {
    param ([string]$Path)

    $sha256 = New-Object System.Security.Cryptography.SHA256Managed
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        ($sha256.ComputeHash($stream) | ForEach-Object { $_.ToString("x2") }) -join ""
    }
    finally {
        $stream.Close()
    }
}

# ===============================
# Validate dcgpofix.exe
# ===============================
$dcgpofixPath = "$env:SystemRoot\System32\dcgpofix.exe"

Write-Host "Validating dcgpofix.exe integrity..." -ForegroundColor Yellow

# 1. Existence
if (-not (Test-Path $dcgpofixPath)) {
    Write-Error "dcgpofix.exe not found in System32."
    exit 1
}

# 2. Authenticode signature
$signature = Get-AuthenticodeSignature $dcgpofixPath

if ($signature.Status -ne "Valid") {
    Write-Error "dcgpofix.exe signature is invalid or missing."
    exit 1
}

if ($signature.SignerCertificate.Subject -notmatch "Microsoft") {
    Write-Error "dcgpofix.exe is not signed by Microsoft."
    exit 1
}

# 3. ACL validation (must not be writable by non-privileged users)
$acl = Get-Acl $dcgpofixPath
$unsafeAcl = $acl.Access | Where-Object {
    $_.FileSystemRights.ToString().Contains("Write") -and
    $_.IdentityReference -notmatch "BUILTIN\\Administrators|NT SERVICE\\TrustedInstaller|SYSTEM"
}

if ($unsafeAcl) {
    Write-Error "dcgpofix.exe has unsafe write permissions."
    exit 1
}

# 4. WinSxS hash comparison
$winsxsCopy = Get-ChildItem "$env:SystemRoot\WinSxS" -Recurse -Filter dcgpofix.exe -ErrorAction SilentlyContinue |
              Select-Object -First 1

if ($winsxsCopy) {
    $hashSystem32 = Get-SHA256Hash $dcgpofixPath
    $hashWinSxS   = Get-SHA256Hash $winsxsCopy.FullName

    if ($hashSystem32 -ne $hashWinSxS) {
        Write-Error "dcgpofix.exe hash mismatch with WinSxS copy."
        exit 1
    }
}
else {
    Write-Warning "WinSxS copy not found; hash comparison skipped."
}

Write-Host "dcgpofix.exe validation passed." -ForegroundColor Green

# ===============================
# Group Policy Reset
# ===============================
if (-not (Get-Module -ListAvailable -Name GroupPolicy)) {
    Write-Error "GroupPolicy module not available."
    exit 1
}

Import-Module GroupPolicy

Write-Host "Resetting Default Domain Policy..." -ForegroundColor Yellow
& $dcgpofixPath /target:Domain

Write-Host "Resetting Default Domain Controllers Policy..." -ForegroundColor Yellow
& $dcgpofixPath /target:DC

# ===============================
# Permission Hardening
# ===============================
$gpoNames = @(
    "Default Domain Policy",
    "Default Domain Controllers Policy"
)

foreach ($gpoName in $gpoNames) {

    Write-Host "Hardening permissions on $gpoName..." -ForegroundColor Yellow

    try {
        $gpo = Get-GPO -Name $gpoName -ErrorAction Stop
    }
    catch {
        Write-Error "Unable to locate $gpoName."
        continue
    }

    # Everyone: Read only
    Set-GPPermission `
        -Guid $gpo.Id `
        -TargetName "Everyone" `
        -TargetType Group `
        -PermissionLevel GpoRead `
        -ErrorAction SilentlyContinue

    # Guest: No access
    Set-GPPermission `
        -Guid $gpo.Id `
        -TargetName "Guest" `
        -TargetType User `
        -PermissionLevel None `
        -ErrorAction SilentlyContinue
}

Write-Host "Domain policy reset and hardening completed successfully." -ForegroundColor Cyan

# ===============================
# Active GPO Enumeration (Correct)
# ===============================

Write-Host "Enumerating active (linked) GPOs in the domain..." -ForegroundColor Yellow

$linkedGpoGuids = New-Object System.Collections.Generic.HashSet[Guid]

# ---- Domain-level links ----
$domainInheritance = Get-GPInheritance -Target (Get-ADDomain).DistinguishedName
foreach ($link in $domainInheritance.GpoLinks) {
    if ($link.Enabled) {
        $linkedGpoGuids.Add($link.GpoId) | Out-Null
    }
}

# ---- OU-level links ----
$ous = Get-ADOrganizationalUnit -Filter *

foreach ($ou in $ous) {
    $ouInheritance = Get-GPInheritance -Target $ou.DistinguishedName
    foreach ($link in $ouInheritance.GpoLinks) {
        if ($link.Enabled) {
            $linkedGpoGuids.Add($link.GpoId) | Out-Null
        }
    }
}

# ---- All GPOs ----
$allGpos = Get-GPO -All

$defaultGpos = @(
    "Default Domain Policy",
    "Default Domain Controllers Policy"
)

$otherGpos = $allGpos | Where-Object {
    $defaultGpos -notcontains $_.DisplayName
}

if (-not $otherGpos) {
    Write-Host "No additional GPOs exist in the domain." -ForegroundColor Green
}
else {

    Write-Host "Additional GPOs detected:" -ForegroundColor Cyan

    foreach ($gpo in $otherGpos) {

    $isLinked = $linkedGpoGuids.Contains($gpo.Id)

    # ---- Safe filename (Windows) ----
    $safeName = $gpo.DisplayName -replace '[\\/:*?"<>|]', '_'
    $htmlPath = Join-Path (Get-Location) "$safeName.html"

    try {
        Get-GPOReport `
            -Guid $gpo.Id `
            -ReportType Html `
            -Path $htmlPath
    }
    catch {
        Write-Warning "Failed to generate HTML report for $($gpo.DisplayName)"
    }

    Write-Host "----------------------------------------" -ForegroundColor DarkGray
    Write-Host "Name: $($gpo.DisplayName)"
    Write-Host "GUID: $($gpo.Id)"
    Write-Host "Linked: $isLinked"
    Write-Host "User Enabled: $($gpo.User.Enabled)"
    Write-Host "Computer Enabled: $($gpo.Computer.Enabled)"
    Write-Host "HTML Report: $htmlPath"
}
}

Write-Host "Active GPO enumeration completed." -ForegroundColor Cyan

