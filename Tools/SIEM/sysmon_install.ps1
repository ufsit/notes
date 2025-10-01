# Sysmon + SwiftOnSecurity Config Installer Script
# Run this script as Administrator

$ErrorActionPreference = "Stop"

# Import BitsTransfer module
Import-Module BitsTransfer -ErrorAction SilentlyContinue

Write-Host "=== Sysmon Installation Script ==="

# Step 1: Define paths
$sysinternalsZip = "C:\SysinternalsSuite.zip"
$sysinternalsDir = "C:\Sysinternals"
$sysmonExe = "$sysinternalsDir\Sysmon.exe"
$configZip = "C:\SysmonConfig.zip"
$configDir = "C:\SysmonConfig"
$configPath = "$configDir\sysmonconfig-export.xml"

# Step 2: Download Sysinternals Suite
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if (-Not (Test-Path $sysinternalsZip)) {
    Write-Host "[+] Downloading Sysinternals Suite..."
    try {
        Invoke-WebRequest -Uri "https://download.sysinternals.com/files/SysinternalsSuite.zip" -OutFile $sysinternalsZip -UseBasicParsing -ErrorAction Stop
    }
    catch {
        Write-Host "[!] Invoke-WebRequest failed, retrying with BITS..."
        Start-BitsTransfer -Source "https://download.sysinternals.com/files/SysinternalsSuite.zip" -Destination $sysinternalsZip -ErrorAction Stop
    }
} else {
    Write-Host "[!] Sysinternals Suite zip already exists, skipping download."
}

# Step 3: Extract Sysinternals Suite
if (-Not (Test-Path $sysinternalsDir)) {
    Write-Host "[+] Extracting Sysinternals Suite..."
    Expand-Archive -Path $sysinternalsZip -DestinationPath $sysinternalsDir
} else {
    Write-Host "[!] Sysinternals directory already exists, skipping extraction."
}

# Step 4: Add Sysinternals to PATH
if ($env:Path -notlike "*$sysinternalsDir*") {
    Write-Host "[+] Adding Sysinternals to PATH..."
    [System.Environment]::SetEnvironmentVariable(
        "Path", 
        $env:Path + ";$sysinternalsDir", 
        [System.EnvironmentVariableTarget]::Machine
    )
    $env:Path += ";$sysinternalsDir"
} else {
    Write-Host "[!] Sysinternals already in PATH."
}

# Step 5: Install Sysmon
if (Test-Path $sysmonExe) {
    Write-Host "[+] Installing Sysmon..."
    Start-Process -FilePath $sysmonExe -ArgumentList "-accepteula -i" -Wait -NoNewWindow
} else {
    Write-Error "[-] Sysmon.exe not found. Check extraction step."
    exit 1
}

# Step 6: Verify Sysmon service
$sysmonService = Get-Service | Where-Object { $_.DisplayName -like "*Sysmon*" }
if ($sysmonService) {
    Write-Host "[+] Sysmon service installed: $($sysmonService.Status)"
} else {
    Write-Error "[-] Sysmon service not found after install."
    exit 1
}

# Step 7: Download SwiftOnSecurity Sysmon config (always use BITS)
if (-Not (Test-Path $configZip)) {
    Write-Host "[+] Downloading SwiftOnSecurity Sysmon config (via BITS)..."
    Start-BitsTransfer -Source "https://github.com/SwiftOnSecurity/sysmon-config/archive/refs/heads/master.zip" -Destination $configZip -ErrorAction Stop
} else {
    Write-Host "[!] Sysmon config zip already exists, skipping download."
}

# Step 8: Extract Sysmon config
if (-Not (Test-Path $configDir)) {
    Write-Host "[+] Extracting Sysmon config..."
    Expand-Archive -Path $configZip -DestinationPath $configDir
    # Move into correct subdirectory (repo extracts into sysmon-config-master)
    $subDir = Join-Path $configDir "sysmon-config-master"
    if (Test-Path $subDir) {
        Move-Item "$subDir\*" $configDir -Force
        Remove-Item $subDir -Recurse -Force
    }
} else {
    Write-Host "[!] Sysmon config directory already exists, skipping extraction."
}

# Step 9: Apply Sysmon config
if (Test-Path $configPath) {
    Write-Host "[+] Applying Sysmon config..."
    Start-Process -FilePath $sysmonExe -ArgumentList "-accepteula -c `"$configPath`"" -Wait -NoNewWindow
    Write-Host "[+] Sysmon config applied successfully."
} else {
    Write-Error "[-] Config file not found at $configPath"
    exit 1
}

Write-Host "=== Installation Complete ==="
