param(
    [Parameter(Mandatory=$true, ParameterSetName="Domain")]
    [switch]$D,
    [Parameter(Mandatory=$true, ParameterSetName="Local")]
    [switch]$L
)
# Rolls EVERY user password in scope (no exclusions) and emits each new
# credential as base64 of "DOMAIN\User:Password" on stdout for the operator.

$DoDomain = $D.IsPresent
$DoLocal  = $L.IsPresent
$ComputerName = $env:COMPUTERNAME

function New-ReadablePassword {
    param([int]$WordCount = 3, [string]$WordFile = ".\words.txt")
    if (-not (Test-Path $WordFile)) { throw "Wordlist file not found: $WordFile" }
    $Words = Get-Content $WordFile | Where-Object { $_.Trim() -ne "" }
    if ($Words.Count -lt 100) { throw "Wordlist too small to be secure" }
    $Rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    function Get-RandomIndex ($Max) {
        $Bytes = New-Object byte[] 4
        $Rng.GetBytes($Bytes)
        [Math]::Abs([BitConverter]::ToInt32($Bytes,0)) % $Max
    }
    $ChosenWords = for ($i = 0; $i -lt $WordCount; $i++) {
        $Word = $Words[(Get-RandomIndex $Words.Count)]
        $Word.Substring(0,1).ToUpper() + $Word.Substring(1)
    }
    return ($ChosenWords -join "-") + "$(Get-RandomIndex 1000)!"
}

$Users = Get-WmiObject Win32_UserAccount
foreach ($User in $Users) {
    $UserName = $User.Name
    $Domain   = $User.Domain
    if ($UserName.EndsWith("$")) { continue }
    if ($DoLocal  -and $Domain -ne $ComputerName) { continue }
    if ($DoDomain -and -not $DoLocal -and $Domain -eq $ComputerName) { continue }
    try {
        $NewPassword = New-ReadablePassword
        $AdsiUser = [ADSI]"WinNT://$Domain/$UserName,user"
        $AdsiUser.SetPassword($NewPassword)
        $AdsiUser.SetInfo()
        $Plain = "${Domain}\${UserName}:${NewPassword}"
        Write-Host ("ZOOCRED:" + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Plain)))
    }
    catch { continue }
}
Write-Host "Password rotation complete."
