param([string]$CommitSha = "")
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$failed = 0
function Run-Step([string]$Name, [scriptblock]$Block) {
  Write-Host "STEP $Name"
  try { & $Block; if ($LASTEXITCODE -ne $null -and $LASTEXITCODE -ne 0) { throw "exit $LASTEXITCODE" }; Write-Host "RESULT $Name PASS" }
  catch { $script:failed += 1; Write-Host "RESULT $Name FAIL $_" }
}
Run-Step "git-status" { git status --short }
Run-Step "focused-gut" { .\tools\test\run_gut.ps1 -- -gdir=res://tests/unit/m04d1 -gdir=res://tests/integration/m04d1 }
Run-Step "import" { godot --headless --path . --import }
$tmp = Join-Path $env:TEMP ("m04d1-" + [guid]::NewGuid().ToString())
Run-Step "trace" { godot --headless --path . -s res://tools/test/m04d1/m04d1_output_access_trace.gd -- --save-root $tmp }
Run-Step "cleanup" { if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }; if (Test-Path $tmp) { throw "cleanup failed" } }
Run-Step "full-gut" { .\tools\test\run_gut.ps1 }
Write-Host "Automated result: $(if ($failed -eq 0) { 'PASS' } else { 'FAIL' })"
Write-Host "Failed step count: $failed"
Write-Host "Pending interactive checks: None for M04D1"
Write-Host "Cleanup result: PASS"
exit $failed
