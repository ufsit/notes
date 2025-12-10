.SYNOPSIS
    Download, install, configure and start Winlogbeat (compatible back to PowerShell 3.0).

.DESCRIPTION
    - Downloads winlogbeat zip using System.Net.WebClient (no progress bar)
    - Extracts using Shell.Application (compatible with older PowerShell)
    - Moves to Program Files and names folder "Winlogbeat"
    - Reads arguments from args.txt (ip, password, fingerprint, hostname)
    - Runs install-service-winlogbeat.ps1
    - Runs winlogbeat.exe setup with provided credentials
    - Requests an API key from Elasticsearch and appends configuration to winlogbeat.yml
    - Starts the Winlogbeat service
    - Contains error checking at each step

.NOTES
    Requires Administrator privileges.
#>

# --- Ensure running as Administrator ---
function Assert-Admin {
    try {
        $current = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($current)
        if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Error "This script must be run as Administrator. Exiting."
            exit 1
        }
    } catch {
        Write-Error "Could not determine elevation state: $_"
        exit 1
    }
}
Assert-Admin

# --- Configuration ---
$downloadUrl = 'https://artifacts.elastic.co/downloads/beats/winlogbeat/winlogbeat-8.19.6-windows-x86_64.zip'
$tempDir = Join-Path $env:TEMP "winlogbeat_install_$(Get-Random)"
$zipPath = Join-Path $tempDir 'winlogbeat.zip'
$extractDir = Join-Path $tempDir 'extracted'
$installDir = Join-Path $env:ProgramFiles 'Winlogbeat'   # final directory
$argsFile = Join-Path (Get-Location) 'args.txt'         # expects args.txt in current directory
$winlogbeatRootFromZip = $null                          # will be detected after extraction

# --- Helpers ---
function Fail([string]$msg) {
    Write-Error $msg
    exit 1
}
function Info([string]$msg) { Write-Host "[INFO] $msg" }
function Debug([string]$msg) { Write-Host "[DEBUG] $msg" }

# --- Prepare workspace ---
try {
    if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
} catch {
    Fail "Failed to create temporary directories: $_"
}

# --- Download (Invoke-WebRequest with no progress bar) ---
Info "Downloading Winlogbeat from $downloadUrl to $zipPath (no progress shown)..."

# Disable progress bar
$oldProgress = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
} catch {
    $ProgressPreference = $oldProgress
    Fail "Download failed: $_"
}

# Restore progress bar behavior
$ProgressPreference = $oldProgress

if (-not (Test-Path $zipPath)) {
    Fail "Download did not produce a file at $zipPath"
}

Info "Download complete."


# --- Extract using Shell.Application (old-friendly) ---
Info "Extracting zip using Shell.Application..."
try {
    $shell = New-Object -ComObject Shell.Application
    $zipFolder = $shell.NameSpace($zipPath)
    if (-not $zipFolder) { Fail "Could not open ZIP file for extraction." }
    $targetFolder = $shell.NameSpace($extractDir)
    if (-not $targetFolder) { Fail "Could not prepare extraction target folder." }
    # CopyHere may trigger UI in some contexts; use flags to suppress prompts (4+16 = no progress UI + respond Yes to All)
    $flags = 0x14
    $targetFolder.CopyHere($zipFolder.Items(), $flags)
    # Wait for files to appear (simple polling)
    $maxWait = 30
    $waited = 0
    while (($null -eq (Get-ChildItem -Path $extractDir -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1)) -and ($waited -lt $maxWait)) {
        Start-Sleep -Seconds 1
        $waited++
    }
    if ($waited -ge $maxWait) {
        Fail "Extraction timed out or failed (no files found in $extractDir)."
    }
} catch {
    Fail "Extraction failed: $_"
}
Info "Extraction complete."

# Determine root folder from extracted contents (common pattern: winlogbeat-<version>-windows-x86_64)
try {
    $children = Get-ChildItem -Path $extractDir -Force | Where-Object { $_.PSIsContainer } 
    if ($children.Count -eq 1) {
        $winlogbeatRootFromZip = $children[0].FullName
    } else {
        # If multiple, attempt to find a folder starting with "winlogbeat"
        $found = $children | Where-Object { $_.Name -match '^winlogbeat' } | Select-Object -First 1
        if ($found) { $winlogbeatRootFromZip = $found.FullName } else {
            # fallback to extractDir itself (some zips extract flat)
            $winlogbeatRootFromZip = $extractDir
        }
    }
    if (-not (Test-Path $winlogbeatRootFromZip)) { Fail "Could not determine extracted Winlogbeat root folder." }
} catch {
    Fail "Error identifying extracted root folder: $_"
}
Debug "Detected winlogbeat root: $winlogbeatRootFromZip"

# --- Move to Program Files and rename to Winlogbeat ---
Info "Moving extracted files to $installDir ..."
try {
    if (Test-Path $installDir) {
        Info "Existing $installDir found. Attempting to remove it first."
        try {
            Stop-Service -Name 'winlogbeat' -ErrorAction SilentlyContinue
        } catch { }
        Remove-Item -Path $installDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    # Use Move-Item where possible; if Move fails across volumes, copy then remove
    try {
        Move-Item -Path $winlogbeatRootFromZip -Destination $installDir -Force -ErrorAction Stop
    } catch {
        Info "Move-Item failed, fallback to Copy-Item then remove source: $_"
        Copy-Item -Path (Join-Path $winlogbeatRootFromZip '*') -Destination $installDir -Recurse -Force -ErrorAction Stop
        Remove-Item -Path $winlogbeatRootFromZip -Recurse -Force -ErrorAction SilentlyContinue
    }
} catch {
    Fail "Failed to move install files to $installDir : $_"
}
if (-not (Test-Path $installDir)) { Fail "Install directory $installDir does not exist after move." }
Info "Files moved to $installDir."

# --- Read args.txt ---
Info "Reading arguments from $argsFile ..."
if (-not (Test-Path $argsFile)) { Fail "Arguments file not found at $argsFile" }
try {
    $rawLines = Get-Content -Path $argsFile -ErrorAction Stop | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' -and -not $_.StartsWith('#') }
    if ($rawLines.Count -eq 0) { Fail "args.txt is empty or contains only comments/blank lines." }

    # Accept either key=value lines or positional lines
    $parsed = @{}
    foreach ($line in $rawLines) {
        if ($line -match '^\s*([^=]+)\s*=\s*(.+)$') {
            $k = $matches[1].Trim().ToLower()
            $v = $matches[2].Trim()
            $parsed[$k] = $v
        }
    }
    if ($parsed.Count -ge 4) {
        # use keys if present
        $ip = $parsed['ip']   ; $password = $parsed['password'] ; $fingerprint = $parsed['fingerprint'] ; $hostname = $parsed['hostname']
    } else {
        # fallback: positional order
        if ($rawLines.Count -lt 4) { Fail "args.txt must contain at least 4 non-empty lines (ip, password, fingerprint, hostname) or key=value pairs." }
        $ip = $rawLines[0]
        $password = $rawLines[1]
        $fingerprint = $rawLines[2]
        $hostname = $rawLines[3]
    }

    foreach ($name in @('ip','password','fingerprint','hostname')) {
        if (-not (Get-Variable -Name $name -Scope 1 -ErrorAction SilentlyContinue)) {
            Fail "Missing required argument: $name"
        }
        if ([string]::IsNullOrWhiteSpace((Get-Variable -Name $name -ValueOnly -Scope 1))) {
            Fail "Argument '$name' is empty."
        }
    }
} catch {
    Fail "Failed to parse args.txt: $_"
}
Info "Arguments loaded: ip=$ip, hostname=$hostname, fingerprint=(redacted), password=(redacted)"

# --- Run install-service-winlogbeat.ps1 ---
$installScript = Join-Path $installDir 'install-service-winlogbeat.ps1'
if (-not (Test-Path $installScript)) {
    Fail "Installer script not found at $installScript"
}
Info "Running installer script: $installScript"
try {
    # Change to install dir for relative paths
    Push-Location $installDir
    # Bypass the execution policy for the script invocation only
    & $installScript
    $exit = $LASTEXITCODE
    Pop-Location
    if ($exit -ne 0) {
        Write-Warning "Installer script returned exit code $exit. Continuing but verify installation."
    }
} catch {
    Pop-Location -ErrorAction SilentlyContinue
    Fail "Failed to run installer script: $_"
}
Info "Installer script invoked."

# --- Run winlogbeat.exe setup with substituted values ---
$exePath = Join-Path $installDir 'winlogbeat.exe'
if (-not (Test-Path $exePath)) { Fail "winlogbeat.exe not found at $exePath" }

# Build argument list. We will set Kibana host to http://<ip>:5601 per your example.
$kibanaHost = "http://$ip:5601"
$esHostExpr = "['$ip:9200']"    # as in your example (note single quotes inside)
$setupArgs = @(
    'setup',
    '-E', "setup.kibana.host=`"$kibanaHost`"",
    '-E', 'setup.kibana.username="elastic"',
    '-E', "setup.kibana.password=`"$password`"",
    '-E', "output.elasticsearch.hosts=`"$esHostExpr`"",
    '-E', 'output.elasticsearch.protocol="https"',
    '-E', 'output.elasticsearch.username="elastic"',
    '-E', "output.elasticsearch.password=`"$password`"",
    '-E', 'output.elasticsearch.ssl.enabled="true"',
    '-E', "output.elasticsearch.ssl.ca_trusted_fingerprint=`"$fingerprint`""
)

Info "Running winlogbeat setup (this may take a short while)..."
try {
    Push-Location $installDir
    & $exePath @setupArgs
    $setupExit = $LASTEXITCODE
    Pop-Location
    if ($setupExit -ne 0) {
        Write-Warning "winlogbeat setup returned exit code $setupExit. Check output for details."
    } else {
        Info "winlogbeat setup completed successfully (exit code 0)."
    }
} catch {
    Pop-Location -ErrorAction SilentlyContinue
    Fail "Failed while running winlogbeat setup: $_"
}

# --- Obtain API key from Elasticsearch ---
Info "Requesting API key from Elasticsearch at https://$ip:9200 ..."
try {
    # Ensure TLS12 and trust invalid certs (per your snippet)
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) { return true; }
}
"@ -ErrorAction Stop
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

    $username = "elastic"
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($username, $securePassword)

    $body = @"
{
  "name": "$hostname",
  "role_descriptors": {
    "winlogbeat_writer": {
      "cluster": ["monitor","read_ilm","read_pipeline"],
      "index": [
        {
          "names": ["winlogbeat-*"],
          "privileges": ["view_index_metadata","create_doc","auto_configure"]
        }
      ]
    }
  }
}
"@

    # Use Invoke-WebRequest -Method Post -Credential ... -Body $body -ContentType 'application/json'
    $uri = "https://$ip:9200/_security/api_key?pretty"
    $invokeResponse = Invoke-WebRequest -Uri $uri -Method Post -Credential $credential -ContentType 'application/json' -Body $body -ErrorAction Stop

    # The response content should be JSON. Parse it.
    $json = $invokeResponse.Content | ConvertFrom-Json
    if (-not $json) { Fail "API key response could not be parsed as JSON." }
    if ($json.id -and $json.api_key) {
        $api_key = "$($json.id):$($json.api_key)"
    } else {
        # Some ES versions may nest the object; attempt to find fields
        if ($json._id -and $json._api_key) {
            $api_key = "$($json._id):$($json._api_key)"
        } else {
            Fail "Unable to locate id and api_key in response: $($invokeResponse.Content)"
        }
    }
    if (-not $api_key) { Fail "API key not retrieved or empty." }
} catch {
    Fail "Failed to get API key from Elasticsearch: $_"
}
Info "API key obtained (value redacted in logs)."

# --- Append required settings to winlogbeat.yml ---
$ymlPath = Join-Path $installDir 'winlogbeat.yml'
if (-not (Test-Path $ymlPath)) {
    # If file doesn't exist, create it (some packaging uses winlogbeat.yml.dist)
    Write-Warning "winlogbeat.yml not found at $ymlPath. Creating new file."
    New-Item -Path $ymlPath -ItemType File -Force | Out-Null
}

try {
    $out1 = "output.elasticsearch.hosts: [""https://$ip:9200""]"
    $out2 = "output.elasticsearch.api_key: `"$api_key`""
    $out3 = "output.elasticsearch.ssl.enabled: true"
    $out4 = "output.elasticsearch.ssl.ca_trusted_fingerprint: `"$fingerprint`""

    # Use Out-File with -Append and UTF8 encoding (PowerShell 3 supports -Encoding)
    $out1 | Out-File -FilePath $ymlPath -Append -Encoding UTF8
    $out2 | Out-File -FilePath $ymlPath -Append -Encoding UTF8
    $out3 | Out-File -FilePath $ymlPath -Append -Encoding UTF8
    $out4 | Out-File -FilePath $ymlPath -Append -Encoding UTF8
} catch {
    Fail "Failed while appending settings to $ymlPath : $_"
}
Info "Configuration appended to $ymlPath."

# --- Start the winlogbeat service ---
Info "Attempting to start service 'winlogbeat'..."
try {
    Start-Service -Name 'winlogbeat' -ErrorAction Stop
    Start-Sleep -Seconds 2
    $svc = Get-Service -Name 'winlogbeat' -ErrorAction Stop
    if ($svc.Status -ne 'Running') {
        Write-Warning "Service 'winlogbeat' did not reach Running state. Current state: $($svc.Status)"
    } else {
        Info "Service 'winlogbeat' is running."
    }
} catch {
    Fail "Failed to start Winlogbeat service: $_"
}

# --- Cleanup temporary files ---
try {
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
} catch {
    Write-Warning "Could not remove temporary directory $tempDir: $_"
}

# --- Delete args.txt ---
Info "Removing args.txt for security..."

try {
    if (Test-Path $argsFile) {
        Remove-Item -Path $argsFile -Force -ErrorAction Stop
        Info "args.txt deleted."
    } else {
        Info "args.txt not found; nothing to delete."
    }
} catch {
    Write-Warning "Failed to delete args.txt: $_"
}

Info "Winlogbeat installation + configuration completed."
