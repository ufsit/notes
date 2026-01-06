# ==========================================
# Service Account Inventory Script
# Account Scope Aware
# PowerShell 3.0 Compatible
# Any Windows Machine
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

    # Defaults
    $Account     = ""
    $AccountType = ""
    $AccountUI   = ""

    # --------------------------
    # Account classification
    # --------------------------
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

        # Managed Service Account / gMSA
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
        ServiceName = $ServiceName
        DisplayName = $DisplayName
        StartMode   = $StartMode
        State       = $State
        Account     = $Account
        AccountType = $AccountType
        AccountUI   = $AccountUI
        Evidence    = "Win32_Service.StartName"
    }
}

# --------------------------
# Export results
# --------------------------
$Results |
    Sort-Object ServiceName |
    Export-Csv $OutputFile -NoTypeInformation

Write-Host "Service inventory complete."
Write-Host "Results saved to service_account_inventory.csv"
