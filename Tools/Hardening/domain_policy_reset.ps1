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
