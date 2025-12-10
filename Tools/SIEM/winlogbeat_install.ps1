# --- Ensure Administrator ---
function Assert-Admin {
    try {
        $current = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($current)
        if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Error "This script must be run as Administrator."
            exit 1
        }
    } catch {
        Write-Error "Could not determine elevation state: $_"
        exit 1
    }
}
Assert-Admin

# --- Helper functions ---
function Fail([string]$msg) {
    Write-Error $msg
    exit 1
}
function Info([string]$msg) { Write-Host "[INFO] $msg" }
function Debug([string]$msg) { Write-Host "[DEBUG] $msg" }

# -------------------
# CONFIG
# -------------------
$downloadUrl = 'https://artifacts.elastic.co/downloads/beats/winlogbeat/winlogbeat-8.19.6-windows-x86_64.zip'
$tempDir = Join-Path $env:TEMP "winlogbeat_install_$(Get-Random)"
$zipPath = Join-Path $tempDir 'winlogbeat.zip'
$extractDir = Join-Path $tempDir 'extracted'
$installDir = Join-Path $env:ProgramFiles 'Winlogbeat'
$argsFile = Join-Path (Get-Location) 'args.txt'
$winlogbeatRootFromZip = $null

# -------------------
# Prepare temp dirs
# -------------------
try {
    if (Test-Path $tempDir) { Remove-Item -Force -Recurse $tempDir -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
} catch {
    Fail "Failed to create temporary directories: $_"
}

Info "Downloading Winlogbeat..."

# Ensure TLS1.2 for compatibility with Elastic download servers
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {
    Write-Warning "Could not set TLS1.2; HTTPS download may fail."
}

$oldProgress = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
} catch {
    $ProgressPreference = $oldProgress
    Fail "Download failed: $_"
}

$ProgressPreference = $oldProgress

if (-not (Test-Path $zipPath)) {
    Fail "Download did not produce a file."
}

Info "Download complete."

# -------------------
# Extract ZIP using Shell.Application (PS 3.0 compatible)
# -------------------
Info "Extracting ZIP..."

try {
    $shell = New-Object -ComObject Shell.Application
    $zip = $shell.NameSpace($zipPath)
    $dest = $shell.NameSpace($extractDir)

    if (-not $zip -or -not $dest) { Fail "Could not extract ZIP." }

    $dest.CopyHere($zip.Items(), 0x14)

    $maxWait = 30
    $elapsed = 0
    while ($elapsed -lt $maxWait -and -not (Get-ChildItem -Path $extractDir -Recurse | Select-Object -First 1)) {
        Start-Sleep -Seconds 1
        $elapsed++
    }
    if ($elapsed -ge $maxWait) { Fail "Extraction timed out." }
} catch {
    Fail "Extraction failed: $_"
}

Info "Extraction complete."

# Detect root folder
try {
    $children = Get-ChildItem -Path $extractDir | Where-Object { $_.PSIsContainer }
    if ($children.Count -eq 1) {
        $winlogbeatRootFromZip = $children[0].FullName
    } else {
        $match = $children | Where-Object { $_.Name -match '^winlogbeat' } | Select-Object -First 1
        if ($match) { $winlogbeatRootFromZip = $match.FullName }
        else { $winlogbeatRootFromZip = $extractDir }
    }
} catch {
    Fail "Could not determine extracted folder: $_"
}

Debug "Extracted root: ${winlogbeatRootFromZip}"

# -------------------
# Move to Program Files\Winlogbeat
# -------------------
Info "Installing to ${installDir} ..."

try {
    if (Test-Path $installDir) {
        Info "Removing existing directory."
        Stop-Service winlogbeat -ErrorAction SilentlyContinue
        Remove-Item -Recurse -Force $installDir -ErrorAction SilentlyContinue
    }

    try {
        Move-Item $winlogbeatRootFromZip $installDir -Force -ErrorAction Stop
    } catch {
        Info "Move failed; copying instead."
        Copy-Item (Join-Path $winlogbeatRootFromZip '*') $installDir -Recurse -Force
        Remove-Item -Recurse -Force $winlogbeatRootFromZip -ErrorAction SilentlyContinue
    }
} catch {
    Fail "Failed to install to ${installDir}: $_"
}

Info "Install complete."

# -------------------
# Read args.txt
# -------------------
Info "Reading args from args.txt ..."

if (-not (Test-Path $argsFile)) { Fail "args.txt not found at ${argsFile}" }

try {
    $raw = Get-Content $argsFile | ForEach-Object { $_.Trim() } |
           Where-Object { $_ -ne '' -and -not $_.StartsWith('#') }
    $parsed = @{}
    foreach ($line in $raw) {
        if ($line -match '^\s*([^=]+)\s*=\s*(.+)$') {
            $parsed[$matches[1].Trim().ToLower()] = $matches[2].Trim()
        }
    }

    if ($parsed.Count -ge 4) {
        $ip          = $parsed['ip']
        $password    = $parsed['password']
        $fingerprint = $parsed['fingerprint']
        $hostname    = $parsed['hostname']
    } else {
        if ($raw.Count -lt 4) { Fail "args.txt must contain 4 values." }
        $ip          = $raw[0]
        $password    = $raw[1]
        $fingerprint = $raw[2]
        $hostname    = $raw[3]
    }
} catch {
    Fail "Could not parse args.txt: $_"
}

Info "Args loaded."

# -------------------
# Install-service-winlogbeat.ps1
# -------------------
$installScript = Join-Path $installDir 'install-service-winlogbeat.ps1'
if (-not (Test-Path $installScript)) {
    Fail "install-service-winlogbeat.ps1 not found in ${installDir}"
}

Info "Running install-service-winlogbeat.ps1 ..."
try {
    Push-Location $installDir
    & $installScript
    Pop-Location
} catch {
    Pop-Location | Out-Null
    Fail "Service install failed: $_"
}

# -------------------
# Run winlogbeat setup
# -------------------
$exe = Join-Path $installDir 'winlogbeat.exe'
if (-not (Test-Path $exe)) { Fail "winlogbeat.exe not found in ${installDir}" }

$kibanaHost = "http://${ip}:5601"
$hostsExpr = "['${ip}:9200']"

$setupArgs = @(
    'setup',
    '-E', "setup.kibana.host=`"$kibanaHost`"",
    '-E', 'setup.kibana.username="elastic"',
    '-E', "setup.kibana.password=`"$password`"",
    '-E', "output.elasticsearch.hosts=`"$hostsExpr`"",
    '-E', 'output.elasticsearch.protocol="https"',
    '-E', 'output.elasticsearch.username="elastic"',
    '-E', "output.elasticsearch.password=`"$password`"",
    '-E', 'output.elasticsearch.ssl.enabled="true"',
    '-E', "output.elasticsearch.ssl.ca_trusted_fingerprint=`"$fingerprint`""
)

Info "Running winlogbeat setup..."

try {
    Push-Location $installDir
    & $exe @setupArgs
    Pop-Location
} catch {
    Pop-Location | Out-Null
    Fail "Setup failed: $_"
}

# -------------------
# Retrieve Elasticsearch API Key (robust)
# -------------------
Info "Retrieving API key from Elasticsearch at https://${ip}:9200 ..."

try {
    # Ensure TLS1.2
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

    # Trust all certs (keeps prior behavior; insecure on public networks)
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

    # Build credential
    $username = "elastic"
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($username, $securePassword)

    # Body as JSON
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

    $uri = "https://${ip}:9200/_security/api_key?pretty"

    # Prefer Invoke-RestMethod because it returns parsed JSON objects (available in PS3+)
    $resp = $null
    try {
        $resp = Invoke-RestMethod -Uri $uri -Method Post -Credential $credential -ContentType 'application/json' -Body $body -ErrorAction Stop
    } catch {
        # Fallback to Invoke-WebRequest and try to parse content
        $iw = Invoke-WebRequest -Uri $uri -Method Post -Credential $credential -ContentType 'application/json' -Body $body -ErrorAction Stop
        if ($iw -and $iw.Content) {
            try {
                $resp = $iw.Content | ConvertFrom-Json
            } catch {
                $resp = $iw.Content
            }
        } else {
            throw $_
        }
    }

    # Defensive parsing: accept multiple possible shapes
    $idVal = $null; $apiKeyVal = $null

    if ($null -ne $resp) {
        # If resp is already a PSCustomObject with properties
        if ($resp -is [System.Management.Automation.PSCustomObject] -or $resp -is [hashtable]) {
            if ($resp.PSObject.Properties.Name -contains 'id') { $idVal = $resp.id }
            if ($resp.PSObject.Properties.Name -contains 'api_key') { $apiKeyVal = $resp.api_key }

            # Some shapes might nest the api key under "api_key" object
            if (-not $idVal -and $resp.api_key -and $resp.api_key.id) { $idVal = $resp.api_key.id }
            if (-not $apiKeyVal -and $resp.api_key -and $resp.api_key.api_key) { $apiKeyVal = $resp.api_key.api_key }

            # Some responses may return _id/_api_key
            if (-not $idVal -and $resp._id) { $idVal = $resp._id }
            if (-not $apiKeyVal -and $resp._api_key) { $apiKeyVal = $resp._api_key }
        } elseif ($resp -is [string]) {
            # resp is a raw JSON string; try to convert
            try {
                $parsed = $resp | ConvertFrom-Json
                if ($parsed) {
                    if ($parsed.id) { $idVal = $parsed.id }
                    if ($parsed.api_key) { $apiKeyVal = $parsed.api_key }
                }
            } catch {
                # leave as-is
            }
        }
    }

    # Validate
    if ([string]::IsNullOrWhiteSpace($idVal) -or [string]::IsNullOrWhiteSpace($apiKeyVal)) {
        # Provide diagnostic output to help debug (redact password)
        $diagnostic = @{}
        $diagnostic['request_uri'] = $uri
        $diagnostic['request_body_snippet'] = ($body -split "`n" | Select-Object -First 3) -join "`n"
        $diagnostic['response_raw'] = $null
        try {
            if ($resp -is [string]) { $diagnostic['response_raw'] = $resp }
            else { $diagnostic['response_parsed'] = $resp | ConvertTo-Json -Depth 6 }
        } catch {
            $diagnostic['response_error'] = "Could not convert response to JSON for diagnostics: $_"
        }
        Write-Host "API key retrieval failed to parse id/api_key. Diagnostics (sensitive fields redacted):"
        Write-Host ($diagnostic | ConvertTo-Json -Depth 6)
        throw "API key retrieval succeeded but id/api_key not present or could not be parsed."
    }

    # Compose the final api key string
    $api_key = "${idVal}:${apiKeyVal}"
    Info "API key successfully retrieved."   # do not print the key to logs

} catch {
    Fail "Failed to obtain API key: $_"
}

# -------------------
# Append to winlogbeat.yml
# -------------------
$yml = Join-Path $installDir 'winlogbeat.yml'
if (-not (Test-Path $yml)) {
    New-Item $yml -ItemType File -Force | Out-Null
}

try {
    "output.elasticsearch.hosts: [`"https://${ip}:9200`"]"    | Out-File $yml -Append -Encoding UTF8
    "output.elasticsearch.api_key: `"$api_key`""              | Out-File $yml -Append -Encoding UTF8
    "output.elasticsearch.ssl.enabled: true"                  | Out-File $yml -Append -Encoding UTF8
    "output.elasticsearch.ssl.ca_trusted_fingerprint: `"$fingerprint`"" | Out-File $yml -Append -Encoding UTF8
} catch {
    Fail "Failed to update winlogbeat.yml: $_"
}

# --- Comment out default localhost hosts line in winlogbeat.yml ---
Info "Commenting out default hosts entry in winlogbeat.yml..."

$ymlPath = Join-Path $installDir "winlogbeat.yml"

if (-not (Test-Path $ymlPath)) {
    Fail "winlogbeat.yml not found at ${ymlPath}"
}

try {
    $yml = Get-Content $ymlPath

    # Comment out any line containing: hosts: ["localhost:9200"]
    $newYml = $yml -replace '^\s*hosts:\s*\["localhost:9200"\]', '# hosts: ["localhost:9200"]'

    # Write back
    Set-Content -Path $ymlPath -Value $newYml -Encoding UTF8

    Info "Default hosts entry commented out."
} catch {
    Fail "Failed to edit winlogbeat.yml: $_"
}

# -------------------
# Start service
# -------------------
Info "Starting winlogbeat service..."

try {
    Start-Service winlogbeat -ErrorAction Stop
} catch {
    Fail "Failed to start Winlogbeat service: $_"
}

# -------------------
# Cleanup temp dir
# -------------------
try {
    Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
} catch {
    Write-Warning "Could not remove temporary directory ${tempDir}: $_"
}

# -------------------
# Delete args.txt
# -------------------
Info "Deleting args.txt..."

try {
    if (Test-Path $argsFile) {
        Remove-Item -Force $argsFile -ErrorAction Stop
        Info "args.txt deleted."
    } else {
        Info "args.txt not found."
    }
} catch {
    Write-Warning "Failed to delete args.txt: $_"
}

Info "Winlogbeat installation and configuration complete."
