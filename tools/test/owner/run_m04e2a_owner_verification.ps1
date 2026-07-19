param([string]$GodotBin = "", [string]$CommitSha = "")
$ErrorActionPreference = "Stop"
$Repo = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
$LogDir = Join-Path $Repo "tools\test\owner\logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$Log = Join-Path $LogDir "m04e2a-owner-verification.log"
function Resolve-Godot {
  if ($GodotBin) { return $GodotBin }
  if ($env:GODOT_BIN) { return $env:GODOT_BIN }
  return "godot"
}
function Run-Step([string]$Name, [scriptblock]$Block) {
  "STEP $Name" | Tee-Object -Append -FilePath $Log
  & $Block 2>&1 | Tee-Object -Append -FilePath $Log
  if ($LASTEXITCODE -ne 0) { throw "$Name failed with exit $LASTEXITCODE" }
}
$Godot = Resolve-Godot
try {
  Set-Location $Repo
  "M04E2A owner verification CommitSha=$CommitSha" | Set-Content -Encoding UTF8 $Log
  Run-Step "godot-version" { & $Godot --version }
  Run-Step "full-suite-before" { & .\tools\test\run_gut.ps1 }
  Run-Step "focused-suite" { & .\tools\test\run_gut.ps1 -- -gdir=res://tests/unit/m04e2a -gdir=res://tests/integration/m04e2a }
  Run-Step "import" { & $Godot --headless --path . --import }
  $TraceRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("idle-death-m04e2a-" + [guid]::NewGuid().ToString("N"))
  New-Item -ItemType Directory -Force -Path $TraceRoot | Out-Null
  try { Run-Step "trace" { & $Godot --headless --path . -s res://tools/test/m04e2a/m04e2a_report_state_trace.gd -- --save-root $TraceRoot } }
  finally { Remove-Item -Recurse -Force $TraceRoot -ErrorAction SilentlyContinue }
  if (Test-Path $TraceRoot) { throw "Trace root cleanup failed: $TraceRoot" }
  Run-Step "full-suite-after" { & .\tools\test\run_gut.ps1 }
  "SUMMARY M04E2A OWNER VERIFICATION PASS" | Tee-Object -Append -FilePath $Log
} catch {
  "SUMMARY M04E2A OWNER VERIFICATION FAIL $_" | Tee-Object -Append -FilePath $Log
  exit 1
}
