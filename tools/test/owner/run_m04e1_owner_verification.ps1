# Canonical owner-run Windows verification package for M04E1.
param(
    [string]$GodotBin,
    [string]$CommitSha = ""
)

$ErrorActionPreference = "Stop"
$Milestone = "M04E1"
$UtcStart = (Get-Date).ToUniversalTime()
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$LogDir = Join-Path $PSScriptRoot "logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$FailedStepCount = 0
$ExitCode = 0
$CleanupResult = "PASS"
$PendingInteractiveChecks = "None for M04E1"
$TraceRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("death-idle-m04e1-" + [System.Guid]::NewGuid().ToString("N"))

function Get-SafeLogRef([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return "unknown-ref" }
    return ($Value -replace '[^A-Za-z0-9_.-]', '-')
}
function Resolve-GodotForOwnerRun {
    if (-not [string]::IsNullOrWhiteSpace($GodotBin)) { return $GodotBin }
    if (-not [string]::IsNullOrWhiteSpace($env:GODOT_BIN)) { return $env:GODOT_BIN }
    $FromPath = Get-Command godot -ErrorAction SilentlyContinue
    if ($FromPath) { return $FromPath.Source }
    $FromPath = Get-Command godot4 -ErrorAction SilentlyContinue
    if ($FromPath) { return $FromPath.Source }
    return "unavailable"
}

Set-Location $RepoRoot
$DetectedCommit = "unavailable"
$GitCommand = Get-Command git -ErrorAction SilentlyContinue
if ($GitCommand) {
    $GitOutput = (& git rev-parse HEAD 2>&1) -join "`n"
    if ($LASTEXITCODE -eq 0) { $DetectedCommit = $GitOutput.Trim() }
}
$LogRef = if (-not [string]::IsNullOrWhiteSpace($CommitSha)) { Get-SafeLogRef $CommitSha } elseif ($DetectedCommit -ne "unavailable") { Get-SafeLogRef $DetectedCommit } else { "unknown-ref" }
$LogPath = Join-Path $LogDir ("M04E1-owner-verification-" + $UtcStart.ToString("yyyyMMdd-HHmmssZ") + "-$LogRef.log")
"" | Set-Content -LiteralPath $LogPath -Encoding UTF8
function Write-LogLine([string]$Line) { Write-Host $Line; Add-Content -LiteralPath $LogPath -Encoding UTF8 -Value $Line }
function Set-Failed([int]$Code) { $script:FailedStepCount += 1; if ($script:ExitCode -eq 0) { $script:ExitCode = $Code } }
function Run-Step([string]$Name, [string]$CommandDescription, [scriptblock]$Command) {
    Write-LogLine "=== $Name ==="; Write-LogLine "Command: $CommandDescription"
    $StepExitCode = 0; $Output = @()
    try { $Output = & $Command 2>&1; if ($null -ne $LASTEXITCODE) { $StepExitCode = $LASTEXITCODE } }
    catch { $Output = @("ERROR: $($_.Exception.Message)"); $StepExitCode = 1 }
    foreach ($Line in $Output) { Write-LogLine "$Line" }
    $Joined = $Output -join "`n"
    if ($Name -eq "Focused M04E1 GUT" -and (($Joined -match "Passing Tests\s+none") -or ($Joined -notmatch "Passing Tests\s+[1-9]"))) { Write-LogLine "ERROR: no focused passing tests detected."; $StepExitCode = 1 }
    foreach ($Marker in @("eight_hour_forecast_core_and_channels=PASS", "settlement_forecast_commit_event_order=PASS", "generic_broken_watch_channels=PASS", "baseline_save_bytes_unchanged_by_forecast=PASS", "run_service_source_audit_no_clock_storage_report_or_whitelist=PASS")) {
        if ($Name -eq "M04E1 Trace" -and ($Joined -notmatch [regex]::Escape($Marker))) { Write-LogLine "ERROR: missing marker $Marker"; $StepExitCode = 1 }
    }
    Write-LogLine "Exit code: $StepExitCode"
    if ($StepExitCode -ne 0) { Write-LogLine "FAILED: $Name"; Set-Failed $StepExitCode } else { Write-LogLine "PASSED: $Name" }
    Write-LogLine ""
}
function Write-SummaryAndExit([int]$Code) {
    try { if (Test-Path $TraceRoot) { Remove-Item -Recurse -Force $TraceRoot } } catch { $script:CleanupResult = "FAIL: $($_.Exception.Message)"; if ($Code -eq 0) { $Code = 90 } }
    Write-LogLine "Summary"
    Write-LogLine "Milestone: $Milestone"
    Write-LogLine "Commit requested: $CommitSha"
    Write-LogLine "Commit detected: $DetectedCommit"
    Write-LogLine "Automated result: $(if ($Code -eq 0) { 'PASS' } else { 'FAIL' })"
    Write-LogLine "Failed step count: $FailedStepCount"
    Write-LogLine "Pending interactive checks: $PendingInteractiveChecks"
    Write-LogLine "Cleanup result: $CleanupResult"
    Write-LogLine "Log path: $LogPath"
    exit $Code
}

Write-LogLine "Death Idle owner verification: $Milestone"
Write-LogLine "Repository root: $RepoRoot"
Write-LogLine "Detected commit: $DetectedCommit"
$ResolvedGodot = Resolve-GodotForOwnerRun
Write-LogLine "Godot executable: $ResolvedGodot"
if ($ResolvedGodot -eq "unavailable") { Write-LogLine "Godot executable unavailable."; Write-SummaryAndExit 91 }
New-Item -ItemType Directory -Force -Path $TraceRoot | Out-Null
Run-Step "Godot Version" "$ResolvedGodot --version" { & $ResolvedGodot --version }
Run-Step "Focused M04E1 GUT" "$ResolvedGodot --headless --path $RepoRoot -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit/m04e1" { & $ResolvedGodot --headless --path $RepoRoot -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit/m04e1 }
Run-Step "M04E1 Trace" "$ResolvedGodot --headless --path $RepoRoot --script res://tools/test/m04e1/m04e1_forecast_run_trace.gd -- --save-root $TraceRoot" { & $ResolvedGodot --headless --path $RepoRoot --script res://tools/test/m04e1/m04e1_forecast_run_trace.gd -- --save-root $TraceRoot }
Write-SummaryAndExit $ExitCode
