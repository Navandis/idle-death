param([string]$CommitSha = "")
$ErrorActionPreference = "Stop"
$logDir = Join-Path $PSScriptRoot "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$log = Join-Path $logDir ("m04a-owner-verification-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
function Step($Name, [scriptblock]$Body) {
  "STEP: $Name" | Tee-Object -FilePath $log -Append
  & $Body 2>&1 | Tee-Object -FilePath $log -Append
  if ($LASTEXITCODE -ne 0) { throw "Step failed: $Name" }
}
"M04A owner verification CommitSha=$CommitSha" | Tee-Object -FilePath $log
$godot = $env:GODOT4_CONSOLE
if ([string]::IsNullOrWhiteSpace($godot)) { $godot = "godot" }
$temp = Join-Path ([System.IO.Path]::GetTempPath()) ("death-idle-m04a-" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $temp | Out-Null
try {
  Step "Godot version" { & $godot --version }
  Step "Full GUT before" { & powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test\run_gut.ps1 }
  Step "Focused M04A" { & powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test\run_gut.ps1 -- -gdir=res://tests/unit/m04a -gdir=res://tests/integration/m04a }
  Step "Import" { & $godot --headless --path . --import }
  Step "Trace" { & $godot --headless --path . -s res://tools/test/m04a/m04a_state_persistence_trace.gd -- --save-root $temp }
  Remove-Item -Recurse -Force $temp
  if (Test-Path $temp) { throw "Cleanup failed" }
  Step "Full GUT after" { & powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test\run_gut.ps1 }
  "Automated result: PASS`nFailed step count: 0`nPending interactive checks: None for M04A`nCleanup result: PASS`nLog path: $log" | Tee-Object -FilePath $log -Append
} catch {
  "Automated result: FAIL`nError: $_`nLog path: $log" | Tee-Object -FilePath $log -Append
  exit 1
}
