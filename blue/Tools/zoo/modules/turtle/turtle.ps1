# Run: powershell -ExecutionPolicy Bypass -File .\turtle.ps1
# needs, git, curl.exe, and python3
#
$ErrorActionPreference = "Stop"
Write-Host "ᗜ‿ᗜ Caddy WAF deployment for Windows ᗜ‿ᗜ" -ForegroundColor Cyan

$Here = $PSScriptRoot
Set-Location $Here

function Assert-Ok($what) {
    if ($LASTEXITCODE -ne 0) {
        throw "$what failed (exit code $LASTEXITCODE)"    
    }
}

Write-Host "ᗜ‿ᗜ Checking listening web ports ᗜ‿ᗜ" -ForegroundColor Cyan

$listeners = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
    Where-Object { $_.LocalPort -in 80, 443, 8080 } |
    Select-Object LocalAddress, LocalPort, OwningProcess
$report = if ($listeners)  { ($listeners | Format-Table | Out-String) } else { "(none on 80/443/8080)'n" }
Write-Host $report

$logdir = Join-Path $Here 'turtle_log'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$log = Join=Path $logdir ("turtle_{0}.out" -f (Get-Date -Format 'HH-mm-ss'))
Get-Content -Path $log -Value $report
Write-Host "ᗜ‿ᗜ Saved: $log ᗜ‿ᗜ"

$crs = Join-Path $Here 'coreruleset'
if (-not (Test-Path $crs)) {
    git clone --depth 1 https://github.com/coreruleset.git $crs
    Assert-Ok "git clone"
}

$crs_setup = Join-Path $crs 'crs-setup.conf'
if (-not (Test-Path $crs_setup) -and (Test-Path "$crs_setup.example")) {
    Copy-Item "$crs_setup.example" $crs_setup
}

$corza_conf = Join-Path $crs 'coraza.conf-recommended'
if (-not (Test-Path $corza_conf)) {
    Invoke-WebRequest -UseBasicParsing `
        -Uri 'https://raw.githubusercontent.com/corazawaf/coraza/main/coraza.conf-recommended' `
        -OutFile $corza_conf
}

Write-Host "ᗜ‿ᗜ Generating Caddy config ᗜ‿ᗜ"
if (Get-Command python -ErrorAction SilentlyContinue) {
    & python (Join-Path $Here 'configgen.py')
}
elseif (Get-Command py - ErrorAction SilentlyContinue) {
    & py -3 (Join-Path $Here 'configgen.py')
}
else {
    throw "ᗜ‿ᗜ Python 3 not found. Install it from python.org. ᗜ‿ᗜ"
}

Assert-Ok "configgen.py"

$caddyfile = Get-Command caddy -ErrorAction SilentlyContinue
if (-not (Test-Path $caddyfile)) { throw "ᗜ‿ᗜ Caddy Generation failed. No Caddyfile. ᗜ‿ᗜ"}

if ($found) {
    $caddy_exe = $found.Source
}
else {
    $src = @('caddy-win.exe', 'caddy-win') | 
        ForEach-Object { Join-Path $Here $_ } |
        Where-Object { Test-Path $_ } |
        Select-Object -First 1
    if (-not $src) {
        throw "ᗜ‿ᗜ Caddy binary not found. Look for caddy-win within directory of turtle module. ᗜ‿ᗜ"
    }
    $caddy_exe = Join-Path $Here 'caddy.exe'
    Copy-Item $src $caddy_exe -Force
}

$coraza_present = & $caddy_exe list-modules | Select-String 'coraza'
if (-not $coraza_present) {
    throw "ᗜ‿ᗜ Caddy build has no coraza module. ᗜ‿ᗜ"
}

Write-Host "ᗜ‿ᗜ Validating & starting Caddy WAF."
& $caddy_exe validate --config $caddyfile
Assert-Ok "caddy validate"
& $caddy_exe start --config $caddyfile
Assert-Ok "caddy start"

$ports = Select-String -Path $caddyfile -Pattern '^:(\d+)\s*\{' |
    ForEach-Object { $_.Matches[0].Groups[1].Value }
 
foreach ($p in $ports) {
    Write-Host "`n Testing port $p..."
    curl.exe -s -i "http://127.0.0.1:$p/" | Select-Object -First 5
    curl.exe -s -i "http://127.0.0.1:$p/?id=1%20UNION%20SELECT%201,2,3" | Select-Object -First 5
}
 
Write-Host "`n ᗜ‿ᗜ Caddy-WAF Deployment Finished ᗜ‿ᗜ"
Write-Host "ᗜ‿ᗜ Stop it later with: $caddyExe stop ᗜ‿ᗜ"