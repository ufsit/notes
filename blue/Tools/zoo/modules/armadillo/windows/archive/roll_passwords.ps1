# ==========================================
# Password Rotation Script
# Service-Aware with Review Output
# PowerShell 3.0 Compatible
# ==========================================

$NoChangeFile = ".\no_change.txt"
$ReviewFile   = ".\service_account_review.csv"
$OutputFile   = ".\changed_passwords.txt"

$ExcludeSet = New-Object System.Collections.Generic.HashSet[string]
$ReviewList = @()

# --------------------------
# Manual exclusions
# --------------------------
if (Test-Path $NoChangeFile) {
    Get-Content $NoChangeFile | ForEach-Object {
        $User = $_.Trim().ToLower()
        if ($ExcludeSet.Add($User)) {
            $ReviewList += [PSCustomObject]@{
                UserName = $User
                Domain   = ""
                Source   = "Manual"
                Evidence = "Listed in no_change.txt"
            }
        }
    }
}

# Always exclude krbtgt
if ($ExcludeSet.Add("krbtgt")) {
    $ReviewList += [PSCustomObject]@{
        UserName = "krbtgt"
        Domain   = ""
        Source   = "System"
        Evidence = "Kerberos service account"
    }
}

# --------------------------
# Discover service accounts
# --------------------------
Get-WmiObject Win32_Service |
    Where-Object {
        $_.StartName -and
        $_.StartName -ne "LocalSystem" -and
        $_.StartName -notlike "NT AUTHORITY*" -and
        $_.StartName -notlike "NT SERVICE*"
    } |
    ForEach-Object {

        $Parts  = $_.StartName.Split('\')
        $Domain = if ($Parts.Count -gt 1) { $Parts[0] } else { "" }
        $User   = $Parts[-1].ToLower()

        if ($ExcludeSet.Add($User)) {
            $ReviewList += [PSCustomObject]@{
                UserName = $User
                Domain   = $Domain
                Source   = "Windows Service"
                Evidence = $_.Name
            }
        }
    }

# --------------------------
# Discover AD SPN accounts
# --------------------------
if (Get-Module -ListAvailable -Name ActiveDirectory) {
    Import-Module ActiveDirectory -ErrorAction SilentlyContinue

    Get-ADUser -Filter 'ServicePrincipalName -like "*"' -Properties ServicePrincipalName |
        ForEach-Object {

            $User = $_.SamAccountName.ToLower()

            if ($ExcludeSet.Add($User)) {
                $ReviewList += [PSCustomObject]@{
                    UserName = $User
                    Domain   = ""
                    Source   = "Active Directory SPN"
                    Evidence = ($_.ServicePrincipalName -join "; ")
                }
            }
        }
}

# --------------------------
# Export review list
# --------------------------
$ReviewList |
    Sort-Object UserName -Unique |
    Export-Csv $ReviewFile -NoTypeInformation

# --------------------------
# Password generation
# --------------------------
function New-RandomPassword {
    param ([int]$Length)

    if ($Length -lt 1) {
        throw "Password length must be at least 1"
    }

    $AlphaNumeric = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    $SpecialChar  = "!"
    $Rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider

    # Generate remaining characters
    $RemainingLength = $Length - 1
    $Bytes = New-Object byte[] $RemainingLength
    $Rng.GetBytes($Bytes)

    $Chars = for ($i = 0; $i -lt $RemainingLength; $i++) {
        $AlphaNumeric[$Bytes[$i] % $AlphaNumeric.Length]
    }

    # Add mandatory !
    $Chars += $SpecialChar

    # Shuffle characters (Fisher-Yates)
    for ($i = $Chars.Count - 1; $i -gt 0; $i--) {
        $SwapByte = New-Object byte[] 1
        $Rng.GetBytes($SwapByte)
        $j = $SwapByte[0] % ($i + 1)

        $Temp = $Chars[$i]
        $Chars[$i] = $Chars[$j]
        $Chars[$j] = $Temp
    }

    return -join $Chars
}

# --------------------------
# Enumerate users
# --------------------------
$PasswordLength = 12
$Results = @()
$Users = Get-WmiObject Win32_UserAccount

foreach ($User in $Users) {

    $UserName  = $User.Name
    $UserLower = $UserName.ToLower()
    $Domain    = $User.Domain

    # Skip machine accounts
    if ($UserName.EndsWith("$")) { continue }

    # Skip excluded/service accounts
    if ($ExcludeSet.Contains($UserLower)) { continue }

    try {
        $NewPassword = New-RandomPassword -Length $PasswordLength

        $AdsiPath = "WinNT://$Domain/$UserName,user"
        $AdsiUser = [ADSI]$AdsiPath
        $AdsiUser.SetPassword($NewPassword)
        $AdsiUser.SetInfo()

        $Results += "${Domain}\${UserName}:${NewPassword}"

    }
    catch {
        # Intentionally silent; failures are not written to credential output
        continue
    }
}

# --------------------------
# Output credentials
# --------------------------
$Results | Set-Content $OutputFile

Write-Host "Password rotation complete."
Write-Host "Changed credentials saved to changed_passwords.txt"
Write-Host "Excluded accounts review saved to service_account_review.csv"
