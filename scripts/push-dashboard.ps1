# Push local dashboard.yaml -> HA storage on Pi, then restart HA.
# Reminder: run .\scripts\pull-dashboard.ps1 first if there's any chance you
# edited the dashboard through the HA UI since the last sync.
#
# Usage (from repo root or anywhere):
#   .\scripts\push-dashboard.ps1

$ErrorActionPreference = "Stop"
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $OutputEncoding

$repo = Split-Path $PSScriptRoot -Parent
$localPath = Join-Path $repo "dashboard.yaml"
$piScript = Join-Path $PSScriptRoot "pi\merge-dashboard.py"

if (-not (Test-Path $localPath)) { throw "$localPath not found" }

$ts = Get-Date -Format yyyyMMdd-HHmmss
Write-Host "==> Backing up Pi storage (.bak.$ts)..." -ForegroundColor Cyan
ssh papi "sudo cp /home/papi/ha-config/.storage/lovelace.dashboard_skylight /home/papi/ha-config/.storage/lovelace.dashboard_skylight.bak.$ts"
if ($LASTEXITCODE -ne 0) { throw "Pi backup failed (exit $LASTEXITCODE)" }

Write-Host "==> Copying dashboard.yaml + merge script to Pi..." -ForegroundColor Cyan
scp $localPath papi:/tmp/dashboard.yaml
if ($LASTEXITCODE -ne 0) { throw "scp dashboard.yaml failed (exit $LASTEXITCODE)" }
scp $piScript papi:/tmp/merge-dashboard.py
if ($LASTEXITCODE -ne 0) { throw "scp merge-dashboard.py failed (exit $LASTEXITCODE)" }

Write-Host "==> Merging into storage..." -ForegroundColor Cyan
ssh papi "sudo python3 /tmp/merge-dashboard.py && sudo chown root:root /home/papi/ha-config/.storage/lovelace.dashboard_skylight && rm -f /tmp/dashboard.yaml /tmp/merge-dashboard.py"
if ($LASTEXITCODE -ne 0) { throw "Merge failed (exit $LASTEXITCODE)" }

Write-Host "==> Restarting HA container (via Docker socket)..." -ForegroundColor Cyan
# Talk to dockerd directly because the docker CLI on this Pi crashes
# (Go runtime panic during init on aarch64 + kernel 6.12).
$restartCode = ssh papi "sudo curl -s -o /dev/null --unix-socket /var/run/docker.sock -X POST http://localhost/containers/homeassistant/restart -w '%{http_code}'"
if ($restartCode -ne "204") { throw "Docker socket restart failed (got HTTP $restartCode, expected 204)" }

# Poll for HA to come back (up to ~30s)
$ready = $false
for ($i = 0; $i -lt 15; $i++) {
    Start-Sleep -Seconds 2
    $status = ssh papi "curl -s -o /dev/null -w '%{http_code}' http://localhost:8123/" 2>$null
    if ($status -eq "200") { $ready = $true; break }
}
if ($ready) {
    Write-Host "==> HA is up (200). Hard-refresh your browser." -ForegroundColor Green
} else {
    Write-Host "==> HA did not return 200 within 30s. Check 'ssh papi docker logs --tail 30 homeassistant'." -ForegroundColor Red
}
