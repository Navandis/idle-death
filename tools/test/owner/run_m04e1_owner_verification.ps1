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
    foreach ($Marker in @(
        "TRACE M04E1 forecast_1h_returns=4140_essence=360_mastery=60000000_cycles=60_soldier=12_scribe_progress=125000",
        "TRACE M04E1 forecast_8h_returns=33120_essence=2880_mastery=480000000_cycles=480_soldier=96_scribe_banked=1",
        "TRACE M04E1 generic_channel_passthrough=PASS",
        "TRACE M04E1 baseline_unchanged_and_projection_detached=PASS",
        "TRACE M04E1 forecast_equals_committed_clone=PASS",
        "TRACE M04E1 settlement_boundary_equivalence=PASS",
        "TRACE M04E1 foreground_offline_fixture_debug_equivalent=PASS",
        "TRACE M04E1 debug_adapter_uses_shared_runner=PASS",
        "TRACE M04E1 one_shot_equals_chunks=PASS",
        "TRACE M04E1 zero_and_failure_no_mutation=PASS",
        "TRACE M04E1 events_and_deltas_match_engine=PASS",
        "TRACE M04E1 schema_v3_content_r2_unchanged=PASS",
        "TRACE M04E1 isolated_save_bytes_unchanged=PASS",
        "TRACE M04E1 no_report_tutorial_or_checkpoint_side_effects=PASS",
        "TRACE M04E1 no_clock_scene_platform_or_duplicate_rules=PASS"
    )) {
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
Run-Step "M04E1 Trace" "$ResolvedGodot --headless --path $RepoRoot --script res://tools/test/m04e1/m04e1_forecast_trace.gd -- --save-root $TraceRoot" { & $ResolvedGodot --headless --path $RepoRoot --script res://tools/test/m04e1/m04e1_forecast_trace.gd -- --save-root $TraceRoot }
Write-SummaryAndExit $ExitCode
