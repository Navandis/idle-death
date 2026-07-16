[CmdletBinding()]
param(
  [string]$CommitSha = "",
  [string]$GodotBin = ""
)
$ErrorActionPreference = "Stop"
$logDir = Join-Path $PSScriptRoot "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$log = Join-Path $logDir ("m04a-owner-verification-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
function Resolve-GodotBinary {
  if (-not [string]::IsNullOrWhiteSpace($GodotBin)) { return $GodotBin }
  if (-not [string]::IsNullOrWhiteSpace($env:GODOT_BIN)) { return $env:GODOT_BIN }
  $fromPath = Get-Command godot -ErrorAction SilentlyContinue
  if ($fromPath) { return $fromPath.Source }
  $fromPath = Get-Command godot4 -ErrorAction SilentlyContinue
  if ($fromPath) { return $fromPath.Source }
  throw 'Godot 4.7.x was not found. Set -GodotBin, GODOT_BIN, or add godot/godot4 to PATH.'
}
function Step($Name, [scriptblock]$Body) {
  "STEP: $Name" | Tee-Object -FilePath $log -Append
  & $Body 2>&1 | Tee-Object -FilePath $log -Append
  if ($LASTEXITCODE -ne 0) { throw "Step failed: $Name" }
}
"M04A owner verification CommitSha=$CommitSha" | Tee-Object -FilePath $log
$godot = Resolve-GodotBinary
if (-not (Test-Path -LiteralPath $godot)) { throw "Godot executable does not exist: $godot" }
$temp = Join-Path ([System.IO.Path]::GetTempPath()) ("death-idle-m04a-" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $temp | Out-Null
try {
  Step "Godot version" { & $godot --version }
  Step "Full GUT before" { & powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test\run_gut.ps1 -GodotBin $godot }
  Step "Focused M04A" { & powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test\run_gut.ps1 -GodotBin $godot -GutArgs @('-gdir=res://tests/unit/m04a', '-gdir=res://tests/integration/m04a') }
  Step "Import" { & $godot --headless --path . --import }
  Step "Trace" { & $godot --headless --path . -s res://tools/test/m04a/m04a_state_persistence_trace.gd -- --save-root $temp }
  Remove-Item -Recurse -Force $temp
  if (Test-Path $temp) { throw "Cleanup failed" }
  Step "Full GUT after" { & powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test\run_gut.ps1 -GodotBin $godot }
  "Automated result: PASS`nFailed step count: 0`nPending interactive checks: None for M04A`nCleanup result: PASS`nLog path: $log" | Tee-Object -FilePath $log -Append
} catch {
  "Automated result: FAIL`nError: $_`nLog path: $log" | Tee-Object -FilePath $log -Append
  exit 1
}
