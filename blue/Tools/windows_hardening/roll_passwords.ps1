param(
    [Parameter(Mandatory=$true, ParameterSetName="Domain")]
    [switch]$D,

    [Parameter(Mandatory=$true, ParameterSetName="Local")]
    [switch]$L
)

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

$DoDomain = $D.IsPresent
$DoLocal = $L.IsPresent
$ComputerName = $env:COMPUTERNAME

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
if ($DoDomain -and (Get-Module -ListAvailable -Name ActiveDirectory)) {
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
function New-ReadablePassword {
    param (
        [int]$WordCount = 3,
        [string]$WordFile = ".\words.txt"
    )

    if (-not (Test-Path $WordFile)) {
        throw "Wordlist file not found: $WordFile"
    }

    $Words = Get-Content $WordFile | Where-Object { $_.Trim() -ne "" }

    if ($Words.Count -lt 100) {
        throw "Wordlist too small to be secure"
    }

    $Rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider

    function Get-RandomIndex ($Max) {
        $Bytes = New-Object byte[] 4
        $Rng.GetBytes($Bytes)
        [Math]::Abs([BitConverter]::ToInt32($Bytes,0)) % $Max
    }

    $ChosenWords = for ($i = 0; $i -lt $WordCount; $i++) {
        $Index = Get-RandomIndex $Words.Count
        $Word  = $Words[$Index]
        $Word.Substring(0,1).ToUpper() + $Word.Substring(1)
    }

    $Number = Get-RandomIndex 1000
    $Special = "!"

    return ($ChosenWords -join "-") + "$Number$Special"
}

# --------------------------
# Enumerate users
# --------------------------
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

    if ($DoLocal -and $Domain -ne $ComputerName) { continue }
    if ($DoDomain -and (-not $DoLocal) -and $Domain -eq $ComputerName) { continue }

    try {
        $NewPassword = New-ReadablePassword

        $AdsiPath = "WinNT://$Domain/$UserName,user"
        $AdsiUser = [ADSI]$AdsiPath
        $AdsiUser.SetPassword($NewPassword)
        $AdsiUser.SetInfo()

        $Plain = "${Domain}\${UserName}:${NewPassword}"
        $Secure = ConvertTo-SecureString $Plain -AsPlainText -Force
        $Encrypted = ConvertFrom-SecureString $Secure
        $Results += $Encrypted


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
