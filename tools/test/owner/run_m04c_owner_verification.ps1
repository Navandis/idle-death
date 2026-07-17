param([string]$CommitSha = "")
$ErrorActionPreference = "Continue"
$repo = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$logDir = Join-Path $repo "tools\test\owner\logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$log = Join-Path $logDir ("m04c-owner-{0}.log" -f ((Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss")))
$failed = 0
function Step($Name, $ScriptBlock) {
  "STEP $Name" | Tee-Object -FilePath $log -Append
  & $ScriptBlock 2>&1 | Tee-Object -FilePath $log -Append
  if ($LASTEXITCODE -ne 0) { $script:failed += 1; "STEP $Name FAILED exit=$LASTEXITCODE" | Tee-Object -FilePath $log -Append }
}
Set-Location $repo
"M04C owner verification CommitSha=$CommitSha" | Set-Content -Encoding UTF8 $log
$godot = $env:GODOT4_CONSOLE
if ([string]::IsNullOrWhiteSpace($godot)) { $godot = "godot" }
Step "godot-version" { & $godot --version }
Step "full-gut-before" { & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo "tools\test\run_gut.ps1") }
Step "focused-m04c" { & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo "tools\test\run_gut.ps1") -GutArgs '-gdir=res://tests/unit/m04c -gdir=res://tests/integration/m04c' }
Step "import" { & $godot --headless --path $repo --import }
$temp = Join-Path ([System.IO.Path]::GetTempPath()) ("death-idle-m04c-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $temp | Out-Null
try {
  Step "trace" { & $godot --headless --path $repo -s "res://tools/test/m04c/m04c_core_reaping_trace.gd" -- --save-root $temp }
  $markers = @(
    "TRACE M04C overdue_60s_returns=69_essence=6_mastery=1000000_cycles=1",
    "TRACE M04C one_shot_equals_chunks=PASS",
    "TRACE M04C settlement_boundary_msec=870",
    "TRACE M04C settlement_end_returns=3_backlog=0_lifecycle=SETTLED",
    "TRACE M04C settlement_event_once=PASS",
    "TRACE M04C settled_mastery_and_cycle_continue=PASS",
    "TRACE M04C core_residuals_return=625375_essence=315250_mastery_carry=40000",
    "TRACE M04C inactive_produces_nothing=PASS",
    "TRACE M04C idle_timeline_advances=PASS",
    "TRACE M04C save_round_trip=PASS",
    "TRACE M04C no_clock_sources=PASS")
  $text = Get-Content $log -Raw
  foreach ($m in $markers) { if ($text -notlike "*$m*") { $failed += 1; "MISSING MARKER $m" | Tee-Object -FilePath $log -Append } }
} finally {
  if (Test-Path $temp) { Remove-Item -Recurse -Force $temp }
}
if (Test-Path $temp) { $failed += 1; $cleanup = "FAIL" } else { $cleanup = "PASS" }
Step "full-gut-after" { & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo "tools\test\run_gut.ps1") }
"Automated result: $(if ($failed -eq 0) { 'PASS' } else { 'FAIL' })" | Tee-Object -FilePath $log -Append
"Failed step count: $failed" | Tee-Object -FilePath $log -Append
"Pending interactive checks: None for M04C" | Tee-Object -FilePath $log -Append
"Cleanup result: $cleanup" | Tee-Object -FilePath $log -Append
exit $(if ($failed -eq 0) { 0 } else { 1 })
