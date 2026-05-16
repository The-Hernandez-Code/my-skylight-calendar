# Pull current HA dashboard storage from Pi -> local dashboard.yaml.
# Always run this BEFORE editing dashboard.yaml so UI edits don't get clobbered
# by the next push.
#
# Usage (from repo root or anywhere):
#   .\scripts\pull-dashboard.ps1

$ErrorActionPreference = "Stop"
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $OutputEncoding

$repo = Split-Path $PSScriptRoot -Parent
$localPath = Join-Path $repo "dashboard.yaml"
$piScript = Join-Path $PSScriptRoot "pi\dump-dashboard.py"

Write-Host "==> Copying dump script to Pi..." -ForegroundColor Cyan
scp $piScript papi:/tmp/dump-dashboard.py
if ($LASTEXITCODE -ne 0) { throw "scp failed (exit $LASTEXITCODE)" }

Write-Host "==> Reading storage from Pi..." -ForegroundColor Cyan
$lines = ssh papi "sudo python3 /tmp/dump-dashboard.py"
if ($LASTEXITCODE -ne 0) { throw "ssh failed (exit $LASTEXITCODE)" }
if (-not $lines) { throw "Empty output from Pi" }

# Backup local before overwriting
if (Test-Path $localPath) {
    $backup = "$localPath.bak.$(Get-Date -Format yyyyMMdd-HHmmss)"
    Copy-Item $localPath $backup
    Write-Host "==> Backed up local to: $(Split-Path $backup -Leaf)" -ForegroundColor Yellow
}

# ssh returns an array of lines in PowerShell; join with LF and ensure trailing newline.
$content = ($lines -join "`n") + "`n"
[System.IO.File]::WriteAllText($localPath, $content, [System.Text.UTF8Encoding]::new($false))
Write-Host "==> Wrote $localPath ($($content.Length) bytes)" -ForegroundColor Green

# Clean up Pi tmp
ssh papi "rm -f /tmp/dump-dashboard.py" | Out-Null
