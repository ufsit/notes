# ==========================================
# Service Account + Signature Tier Inventory
# PowerShell 3.0 Compatible
# ==========================================

$OutputFile = ".\service_account_inventory.csv"
$Results = @()

Write-Host "Collecting service inventory..." -ForegroundColor Cyan

Get-WmiObject Win32_Service | ForEach-Object {

    $ServiceName = $_.Name
    $DisplayName = $_.DisplayName
    $StartMode   = $_.StartMode
    $State       = $_.State
    $StartName   = $_.StartName
    $PathName    = $_.PathName

    # ---------------------------------
    # Extract executable path
    # ---------------------------------
    $ExePath = $null

    if ($PathName) {
        if ($PathName.StartsWith('"')) {
            $ExePath = $PathName.Split('"')[1]
        } else {
            $ExePath = $PathName.Split(" ")[0]
        }
    }

    # ---------------------------------
    # Signature Analysis
    # ---------------------------------
    $SignatureStatus = "Unknown"
    $Publisher       = "None"
    $SignatureTier   = 0   # Default = Unsigned/Invalid

    if ($ExePath -and (Test-Path $ExePath)) {
        try {
            $Sig = Get-AuthenticodeSignature $ExePath
            $SignatureStatus = $Sig.Status

            if ($Sig.SignerCertificate) {
                $Publisher = $Sig.SignerCertificate.Subject
            }

            if ($Sig.Status -eq "Valid") {

                if ($Publisher -match "Microsoft") {
                    $SignatureTier = 2   # Microsoft signed
                }
                else {
                    $SignatureTier = 1   # Valid but non-Microsoft
                }
            }
            else {
                $SignatureTier = 0       # Invalid or NotSigned
            }
        }
        catch {
            $SignatureStatus = "Error"
            $SignatureTier   = 0
        }
    }

    # --------------------------
    # Account classification
    # --------------------------
    $Account     = ""
    $AccountType = ""
    $AccountUI   = ""

    if (-not $StartName -or $StartName -eq "LocalSystem") {
        $Account     = "LocalSystem"
        $AccountType = "Built-in"
        $AccountUI   = "N/A"
    }
    elseif ($StartName -like "NT AUTHORITY*") {
        $Account     = $StartName
        $AccountType = "Built-in"
        $AccountUI   = "N/A"
    }
    elseif ($StartName -like "NT SERVICE*") {
        $Account     = $StartName
        $AccountType = "Virtual Service Account"
        $AccountUI   = "N/A"
    }
    elseif ($StartName -match "^[^\\]+\\[^\\]+$") {

        $Parts  = $StartName.Split('\')
        $Prefix = $Parts[0]
        $User   = $Parts[1]

        $Account = $StartName.ToLower()

        if ($User.EndsWith("$")) {
            $AccountType = "Managed Service Account"
            $AccountUI   = "dsa.msc (Do Not Rotate)"
        }
        elseif ($Prefix -ieq $env:COMPUTERNAME) {
            $AccountType = "Local User"
            $AccountUI   = "lusrmgr.msc"
        }
        else {
            $AccountType = "Domain User"
            $AccountUI   = "dsa.msc"
        }
    }
    else {
        $Account     = $StartName
        $AccountType = "Unknown"
        $AccountUI   = "Review Manually"
    }

    # --------------------------
    # Record result
    # --------------------------
    $Results += [PSCustomObject]@{
        SignatureTier   = $SignatureTier
        ServiceName     = $ServiceName
        DisplayName     = $DisplayName
        StartMode       = $StartMode
        State           = $State
        Account         = $Account
        AccountType     = $AccountType
        ExecutablePath  = $ExePath
        SignatureStatus = $SignatureStatus
        Publisher       = $Publisher
        Evidence        = "Win32_Service + Authenticode"
    }
}

# --------------------------
# Export results
# --------------------------
$Results |
    Sort-Object SignatureTier, ServiceName |
    Select-Object * -ExcludeProperty SignatureTier |
    Export-Csv $OutputFile -NoTypeInformation

Write-Host "Service inventory complete."
Write-Host ""
Write-Host "Order:"
Write-Host "  1) Unsigned / Invalid"
Write-Host "  2) Signed (Non-Microsoft)"
Write-Host "  3) Microsoft Signed"
Write-Host ""
Write-Host "Results saved to service_account_inventory.csv"
