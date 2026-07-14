# Canonical owner-run Windows verification package for M02.
param(
    [string]$GodotBin,
    [string]$CommitSha = ""
)

$ErrorActionPreference = "Stop"
$Milestone = "M02"
$UtcStart = (Get-Date).ToUniversalTime()
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$LogDir = Join-Path $PSScriptRoot "logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

$FailedStepCount = 0
$ExitCode = 0
$CleanupResult = "PASS"
$PendingInteractiveChecks = "None for M02"
$RequestedCommit = if ([string]::IsNullOrWhiteSpace($CommitSha)) { "not supplied" } else { $CommitSha }
$DetectedCommit = "unavailable"
$DetectedCommitDetail = "unavailable (Git CLI not installed or not on PATH)"
$TraceRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("death-idle-m02-" + [guid]::NewGuid().ToString("N"))
$LastStepOutput = @()

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
$LogPath = Join-Path $LogDir "M02-owner-verification-$Stamp-$LogRef.log"
"" | Set-Content -LiteralPath $LogPath -Encoding UTF8

function Write-LogLine([string]$Line) {
    Write-Host $Line
    Add-Content -LiteralPath $LogPath -Encoding UTF8 -Value $Line
}

function Set-Failed([int]$Code) {
    $script:FailedStepCount += 1
    if ($script:ExitCode -eq 0) { $script:ExitCode = $Code }
}

function Write-SummaryAndExit([int]$Code) {
    $AutomatedResult = if ($Code -eq 0) { "PASS" } else { "FAIL" }
    Write-LogLine ""
    Write-LogLine "Summary"
    Write-LogLine "Automated result: $AutomatedResult"
    Write-LogLine "Failed step count: $FailedStepCount"
    Write-LogLine "Pending interactive checks: $PendingInteractiveChecks"
    Write-LogLine "Cleanup result: $CleanupResult"
    Write-LogLine "Log path: $LogPath"
    exit $Code
}

function Run-Step([string]$Name, [string]$CommandDescription, [scriptblock]$Command) {
    Write-LogLine "=== $Name ==="
    Write-LogLine "Command: $CommandDescription"
    $StepExitCode = 0
    $script:LastStepOutput = @()
    try {
        $Output = & $Command 2>&1
        foreach ($Line in $Output) {
            $Text = "$Line"
            $script:LastStepOutput += $Text
            Write-LogLine $Text
        }
        if ($null -ne $LASTEXITCODE) { $StepExitCode = $LASTEXITCODE }
    }
    catch {
        $Message = "ERROR: $($_.Exception.Message)"
        $script:LastStepOutput += $Message
        Write-LogLine $Message
        $StepExitCode = 1
    }
    Write-LogLine "Exit code: $StepExitCode"
    if ($StepExitCode -ne 0) {
        Write-LogLine "FAILED: $Name"
        Set-Failed $StepExitCode
    }
    else {
        Write-LogLine "PASSED: $Name"
    }
    Write-LogLine ""
    return ($StepExitCode -eq 0)
}

function Write-SkippedStep([string]$Name, [string]$Reason) {
    Write-LogLine "=== $Name ==="
    Write-LogLine "SKIPPED: $Reason"
    Write-LogLine ""
    Set-Failed 1
}

function Invoke-GutWrapper([string[]]$GutArgs = @()) {
    $Wrapper = Join-Path $RepoRoot "tools\test\run_gut.ps1"
    if (-not [string]::IsNullOrWhiteSpace($GodotBin)) {
        if ($GutArgs.Count -gt 0) { & $Wrapper -GodotBin $ResolvedGodot -GutArgs $GutArgs }
        else { & $Wrapper -GodotBin $ResolvedGodot }
    }
    else {
        if ($GutArgs.Count -gt 0) { & $Wrapper -GutArgs $GutArgs }
        else { & $Wrapper }
    }
}

function Invoke-GodotCommand([string[]]$Arguments) {
    if ($ResolvedGodot -eq "unavailable") { throw "Godot 4.7.x was not found. Set -GodotBin, GODOT_BIN, or PATH." }
    & $ResolvedGodot @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Godot command failed with exit code $LASTEXITCODE." }
}

$ResolvedGodot = Resolve-GodotForOwnerRun
$GodotVersion = "unavailable"
if ($ResolvedGodot -ne "unavailable") {
    $GodotVersionOutput = (& $ResolvedGodot --version 2>&1) -join "`n"
    if ($LASTEXITCODE -eq 0) { $GodotVersion = $GodotVersionOutput.Trim() }
    else { $GodotVersion = "unavailable (godot --version failed: $($GodotVersionOutput.Trim()))" }
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
Write-LogLine "Godot executable: $ResolvedGodot"
Write-LogLine "Godot version: $GodotVersion"
Write-LogLine "Log path: $LogPath"
Write-LogLine "Trace root: $TraceRoot"
Write-LogLine ""

if ((-not [string]::IsNullOrWhiteSpace($CommitSha)) -and $DetectedCommit -ne "unavailable" -and $DetectedCommit -ne $CommitSha) {
    Write-LogLine "FAILED: checked-out commit does not match -CommitSha."
    Set-Failed 67
    Write-SummaryAndExit $ExitCode
}

$FocusedGutArgs = @(
    "-gdir=res://tests/unit/persistence",
    "-gdir=res://tests/integration/save_load"
)

try {
    $GodotVersionPassed = Run-Step "Godot 4.7 version validation" "$ResolvedGodot --version" {
        if ($ResolvedGodot -eq "unavailable") { throw "Godot 4.7.x was not found. Set -GodotBin, GODOT_BIN, or PATH." }
        & $ResolvedGodot --version
        if ($LASTEXITCODE -ne 0) { throw "Godot --version failed with exit code $LASTEXITCODE." }
        $VersionLine = ($script:LastStepOutput -join "`n").Trim()
        if ([string]::IsNullOrWhiteSpace($VersionLine)) { $VersionLine = $GodotVersion }
        if ($GodotVersion -notmatch '^4\.7(\.|-|$)') { throw "Death Idle requires Godot 4.7.x; detected: $GodotVersion" }
    }

    if ($GodotVersionPassed) {
        Run-Step "Full GUT suite before trace" "tools\\test\\run_gut.ps1" { Invoke-GutWrapper }
        Run-Step "Focused M02 GUT suite" "tools\\test\\run_gut.ps1 -GutArgs @('-gdir=res://tests/unit/persistence','-gdir=res://tests/integration/save_load')" { Invoke-GutWrapper $FocusedGutArgs }
        $ImportPassed = Run-Step "Explicit import preflight" "$ResolvedGodot --headless --path $RepoRoot --import" { Invoke-GodotCommand @("--headless", "--path", "$RepoRoot", "--import") }
        if ($ImportPassed) {
            Run-Step "Real-file M02 persistence trace" "$ResolvedGodot --headless --path $RepoRoot -s res://tools/test/m02/m02_persistence_trace.gd -- --save-root $TraceRoot" {
                if ($ResolvedGodot -eq "unavailable") { throw "Godot 4.7.x was not found. Set -GodotBin, GODOT_BIN, or PATH." }
                $TraceOutput = & $ResolvedGodot --headless --path $RepoRoot -s res://tools/test/m02/m02_persistence_trace.gd -- --save-root $TraceRoot 2>&1
                $TraceExitCode = $LASTEXITCODE
                foreach ($Line in $TraceOutput) { Write-Output "$Line" }
                if ($TraceExitCode -ne 0) { throw "M02 trace failed with exit code $TraceExitCode." }
                $TraceText = ($TraceOutput | ForEach-Object { "$_" }) -join "`n"
                $RequiredTraceEvidence = @(
                    "M02_TRACE_OK revision 1 written",
                    "M02_TRACE_OK revision 2 written",
                    "M02_TRACE_OK backup revision 1 exists",
                    "M02_TRACE_OK primary corrupted",
                    "M02_TRACE_OK backup revision selected",
                    "rejected_primary=",
                    "M02_TRACE_OK corrupt primary retained"
                )
                foreach ($Evidence in $RequiredTraceEvidence) {
                    if ($TraceText -notlike "*$Evidence*") { throw "M02 trace output did not include required evidence: $Evidence" }
                }
            }
        }
        else {
            Write-SkippedStep "Real-file M02 persistence trace" "prerequisite failed: Explicit import preflight"
        }
    }
    else {
        Write-SkippedStep "Full GUT suite before trace" "prerequisite failed: Godot 4.7 version validation"
        Write-SkippedStep "Focused M02 GUT suite" "prerequisite failed: Godot 4.7 version validation"
        Write-SkippedStep "Explicit import preflight" "prerequisite failed: Godot 4.7 version validation"
        Write-SkippedStep "Real-file M02 persistence trace" "prerequisite failed: Godot 4.7 version validation"
    }
}
finally {
    Write-LogLine "=== Cleanup isolated M02 trace directory ==="
    Write-LogLine "Command: Remove-Item -Recurse -Force $TraceRoot"
    try {
        if (Test-Path -LiteralPath $TraceRoot) {
            Remove-Item -LiteralPath $TraceRoot -Recurse -Force
        }
        Write-LogLine "Exit code: 0"
        Write-LogLine "PASSED: Cleanup isolated M02 trace directory"
    }
    catch {
        Write-LogLine "ERROR: $($_.Exception.Message)"
        Write-LogLine "Exit code: 1"
        Write-LogLine "FAILED: Cleanup isolated M02 trace directory"
        $CleanupResult = "FAIL"
        Set-Failed 1
    }
    Write-LogLine ""

    $CleanupVerifyPassed = Run-Step "Verify isolated M02 trace directory is absent" "Test-Path -LiteralPath $TraceRoot" {
        if (Test-Path -LiteralPath $TraceRoot) { throw "Trace directory still exists: $TraceRoot" }
        Write-Output "Trace directory absent: $TraceRoot"
    }
    if (-not $CleanupVerifyPassed) { $CleanupResult = "FAIL" }

    if ($ResolvedGodot -ne "unavailable") {
        Run-Step "Full GUT suite after trace and cleanup" "tools\\test\\run_gut.ps1" { Invoke-GutWrapper }
    }
    else {
        Write-SkippedStep "Full GUT suite after trace and cleanup" "prerequisite failed: Godot 4.7 version validation"
    }
}

if (-not (Test-Path -LiteralPath $LogPath)) {
    $CleanupResult = "FAIL"
    Set-Failed 68
}

Write-SummaryAndExit $ExitCode
