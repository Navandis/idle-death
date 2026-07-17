param([string]$CommitSha = "")
$ErrorActionPreference = "Stop"
$repo = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$logDir = Join-Path $repo "tools\test\owner\logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$log = Join-Path $logDir ("m04c-owner-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
function Write-Log($m) { $m | Tee-Object -FilePath $log -Append }
try {
  Write-Log "M04C owner verification"
  if ($CommitSha) { Write-Log "Expected commit: $CommitSha" }
  Push-Location $repo
  & .\tools\test\run_gut.ps1 | Tee-Object -FilePath $log -Append
  if ($LASTEXITCODE -ne 0) { throw "Full GUT before failed" }
  & .\tools\test\run_gut.ps1 -- -gdir=res://tests/unit/m04c -gdir=res://tests/integration/m04c | Tee-Object -FilePath $log -Append
  if ($LASTEXITCODE -ne 0) { throw "Focused M04C failed" }
  $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("m04c-trace-" + [guid]::NewGuid())
  New-Item -ItemType Directory -Force -Path $tmp | Out-Null
  godot --headless --path . -s res://tools/test/m04c/m04c_core_reaping_trace.gd -- --save-root $tmp | Tee-Object -FilePath $log -Append
  if ($LASTEXITCODE -ne 0) { throw "Trace failed" }
  Remove-Item -Recurse -Force $tmp
  & .\tools\test\run_gut.ps1 | Tee-Object -FilePath $log -Append
  if ($LASTEXITCODE -ne 0) { throw "Full GUT after failed" }
  Write-Log "Automated result: PASS"; Write-Log "Failed step count: 0"; Write-Log "Pending interactive checks: None for M04C"; Write-Log "Cleanup result: PASS"
} finally { Pop-Location }
