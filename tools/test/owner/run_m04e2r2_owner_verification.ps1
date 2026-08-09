<#
Runs the exact-head owner verification package for M04E2R2. The generated log
is UTF-8, lives under the ignored owner-artifact directory, and is removed when
all checks pass so cleanup absence is directly observable.
#>
[CmdletBinding()]
param([string]$GodotBin)

$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
$logDirectory = Join-Path $root 'artifacts\owner-verification'
$logPath = Join-Path $logDirectory 'm04e2r2-owner-verification.log'
New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null
try {
    & (Join-Path $root 'tools\test\run_gut.ps1') -GodotBin $GodotBin -GutArgs @('-gtest=res://tests/unit/m04e2r1/test_report_ledger.gd', '-gtest=res://tests/unit/m04e2r1/test_report_ledger_ingestion.gd', '-gtest=res://tests/unit/m04e2r1/test_report_ledger_interval_matrix.gd', '-gtest=res://tests/integration/m04e2r1/test_report_ledger_persistence_exclusion.gd', '-gtest=res://tests/unit/m04e2r2/test_report_ledger_r2_state.gd', '-gtest=res://tests/unit/m04e2r2/test_report_ledger_snapshot.gd', '-gtest=res://tests/unit/m04e2r2/test_report_ledger_reads.gd', '-gtest=res://tests/integration/m04e2r2/test_report_ledger_rollover_ingestion.gd', '-gtest=res://tests/integration/m04e2r2/test_report_ledger_persistence_exclusion.gd') *>&1 | Tee-Object -FilePath $logPath
    if ($LASTEXITCODE -ne 0) { throw "Focused R1/R2 tests failed with $LASTEXITCODE." }
    & $GodotBin --headless --path $root -s 'res://tools/test/m04e2r2/m04e2r2_report_history_trace.gd' *>&1 | Tee-Object -FilePath $logPath -Append
    if ($LASTEXITCODE -ne 0) { throw "M04E2R2 trace failed with $LASTEXITCODE." }
    git -C $root diff --check
    if ($LASTEXITCODE -ne 0) { throw 'git diff --check failed.' }
}
finally {
    if (Test-Path -LiteralPath $logPath) { Remove-Item -LiteralPath $logPath -Force }
}
if (Test-Path -LiteralPath $logPath) { throw 'Owner log cleanup failed.' }
Write-Host 'M04E2R2 owner verification package completed; cleanup=PASS.'
