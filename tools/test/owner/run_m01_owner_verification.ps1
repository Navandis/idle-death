# Canonical owner-run Windows verification package for M01.
param(
    [string]$GodotBin,
    [string]$CommitSha
)

$ErrorActionPreference = "Stop"
$Milestone = "M01"
$UtcStart = (Get-Date).ToUniversalTime()
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$LogDir = Join-Path $PSScriptRoot "logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$FailedStepCount = 0
$CleanupResult = "PASS"
$PendingInteractiveChecks = "None for M01"
$DetectedCommit = "unavailable"
$DetectedCommitDetail = "unavailable (Git CLI not installed or not on PATH)"
$RequestedCommit = if ([string]::IsNullOrWhiteSpace($CommitSha)) { "not supplied" } else { $CommitSha }

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

function Get-WindowsVersionForLog {
    try {
        $Os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        return "$($Os.Caption) $($Os.Version)"
    }
    catch {
        return [Environment]::OSVersion.VersionString
    }
}

Set-Location $RepoRoot

$GitCommand = Get-Command git -ErrorAction SilentlyContinue
if ($GitCommand) {
    $GitOutput = (& git rev-parse HEAD 2>&1) -join "`n"
    if ($LASTEXITCODE -eq 0) {
        $DetectedCommit = $GitOutput.Trim()
        $DetectedCommitDetail = $DetectedCommit
    }
    else {
        $DetectedCommitDetail = "unavailable (git rev-parse HEAD failed: $($GitOutput.Trim()))"
    }
}

$LogRef = if (-not [string]::IsNullOrWhiteSpace($CommitSha)) { Get-SafeLogRef $CommitSha } elseif ($DetectedCommit -ne "unavailable") { Get-SafeLogRef $DetectedCommit } else { "unknown-ref" }
$Stamp = $UtcStart.ToString("yyyyMMdd-HHmmssZ")
$LogPath = Join-Path $LogDir "M01-owner-verification-$Stamp-$LogRef.log"
"" | Set-Content -LiteralPath $LogPath -Encoding UTF8

function Write-LogLine([string]$Line) {
    Write-Host $Line
    Add-Content -LiteralPath $LogPath -Encoding UTF8 -Value $Line
}

function Write-SummaryAndExit([int]$ExitCode) {
    $AutomatedResult = if ($ExitCode -eq 0) { "PASS" } else { "FAIL" }
    Write-LogLine ""
    Write-LogLine "Summary"
    Write-LogLine "Automated result: $AutomatedResult"
    Write-LogLine "Failed step count: $FailedStepCount"
    Write-LogLine "Pending interactive checks: $PendingInteractiveChecks"
    Write-LogLine "Cleanup result: $CleanupResult"
    Write-LogLine "Log path: $LogPath"
    exit $ExitCode
}

$GodotExecutable = Resolve-GodotForOwnerRun
$GodotVersion = "unavailable"
if ($GodotExecutable -ne "unavailable") {
    $GodotVersionOutput = (& $GodotExecutable --version 2>&1) -join "`n"
    if ($LASTEXITCODE -eq 0) {
        $GodotVersion = $GodotVersionOutput.Trim()
    }
    else {
        $GodotVersion = "unavailable (godot --version failed: $($GodotVersionOutput.Trim()))"
    }
}

Write-LogLine "Milestone: $Milestone"
Write-LogLine "UTC start: $($UtcStart.ToString('yyyy-MM-ddTHH:mm:ssZ'))"
Write-LogLine "Repository root: $RepoRoot"
Write-LogLine "Requested commit or PR head: $RequestedCommit"
Write-LogLine "Detected Git commit, when available: $DetectedCommitDetail"
if ((-not [string]::IsNullOrWhiteSpace($CommitSha)) -and $DetectedCommit -eq "unavailable") {
    Write-LogLine "Detected Git commit: unavailable (Git CLI not installed or not on PATH); owner must confirm the checkout in GitHub Desktop."
}
Write-LogLine "Windows version: $(Get-WindowsVersionForLog)"
Write-LogLine "PowerShell version: $($PSVersionTable.PSVersion.ToString())"
Write-LogLine "Godot executable: $GodotExecutable"
Write-LogLine "Godot version: $GodotVersion"
Write-LogLine "Log path: $LogPath"
Write-LogLine ""

if ((-not [string]::IsNullOrWhiteSpace($CommitSha)) -and $DetectedCommit -ne "unavailable" -and $DetectedCommit -ne $CommitSha) {
    Write-LogLine "FAILED: checked-out commit does not match -CommitSha."
    $FailedStepCount += 1
    Write-SummaryAndExit 67
}

function Run-Step([string]$Name, [scriptblock]$Command) {
    Write-LogLine "=== $Name ==="
    $StepExitCode = 0
    try {
        & $Command 2>&1 | ForEach-Object { Write-LogLine "$($_)" }
        if ($null -ne $LASTEXITCODE) { $StepExitCode = $LASTEXITCODE }
    }
    catch {
        Write-LogLine "ERROR: $($_.Exception.Message)"
        $StepExitCode = 1
    }
    Write-LogLine "Exit code: $StepExitCode"
    if ($StepExitCode -ne 0) {
        Write-LogLine "FAILED: $Name"
        $script:FailedStepCount += 1
        $script:ExitCode = if ($script:ExitCode -eq 0) { $StepExitCode } else { $script:ExitCode }
    } else {
        Write-LogLine "PASSED: $Name"
    }
    Write-LogLine ""
    return ($StepExitCode -eq 0)
}

function Write-SkippedStep([string]$Name, [string]$Reason) {
    Write-LogLine "=== $Name ==="
    Write-LogLine "SKIPPED: $Reason"
    Write-LogLine ""
}

$ExitCode = 0
$Wrapper = Join-Path $RepoRoot "tools\test\run_gut.ps1"
$WrapperBaseParams = @{}
if (-not [string]::IsNullOrWhiteSpace($GodotBin)) {
    $WrapperBaseParams["GodotBin"] = $GodotBin
}
$FocusedGutArgs = @(
    "-gtest=res://tests/unit/m01/test_fixed_point.gd",
    "-gtest=res://tests/unit/m01/test_time_authority.gd",
    "-gtest=res://tests/unit/m01/test_source_ownership.gd"
)
$FocusedWrapperParams = @{}
foreach ($Key in $WrapperBaseParams.Keys) {
    $FocusedWrapperParams[$Key] = $WrapperBaseParams[$Key]
}
$FocusedWrapperParams["GutArgs"] = $FocusedGutArgs

$FullSuitePassed = Run-Step "Full GUT suite" { & $Wrapper @WrapperBaseParams }
$FocusedSuitePassed = Run-Step "Focused M01 GUT suite" { & $Wrapper @FocusedWrapperParams }
$TraceImportPassed = Run-Step "M01 deterministic trace import preflight" {
    if ($GodotExecutable -eq "unavailable") {
        Write-Error "Godot 4.7.x was not found for the M01 trace import preflight."
    }
    else {
        & $GodotExecutable --headless --path $RepoRoot --import
    }
}
if ($TraceImportPassed) {
    Run-Step "M01 deterministic trace" {
        & $GodotExecutable --headless --path $RepoRoot -s res://tools/test/m01/m01_deterministic_trace.gd
    }
}
else {
    Write-SkippedStep "M01 deterministic trace" "prerequisite failed: M01 deterministic trace import preflight"
}

$GeneratedLogExists = Test-Path -LiteralPath $LogPath
if (-not $GeneratedLogExists) {
    $CleanupResult = "FAIL"
    $FailedStepCount += 1
    if ($ExitCode -eq 0) { $ExitCode = 68 }
}

Write-SummaryAndExit $ExitCode
