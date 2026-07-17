# Canonical owner-run Windows verification package for M04C.
param(
    [string]$GodotBin,
    [string]$CommitSha = ""
)

$ErrorActionPreference = "Stop"
$Milestone = "M04C"
$ParentEpic = "M04"
$UtcStart = (Get-Date).ToUniversalTime()
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$LogDir = Join-Path $PSScriptRoot "logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

$FailedStepCount = 0
$ExitCode = 0
$CleanupResult = "PASS"
$PendingInteractiveChecks = "None for M04C"
$RequestedCommit = if ([string]::IsNullOrWhiteSpace($CommitSha)) { "not supplied" } else { $CommitSha }
$DetectedCommit = "unavailable"
$DetectedCommitDetail = "unavailable (Git CLI not installed or not on PATH)"
$LastStepOutput = @()
$TraceRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("death-idle-m04c-" + [System.Guid]::NewGuid().ToString("N"))

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
    catch { return [Environment]::OSVersion.VersionString }
}

Set-Location $RepoRoot
$GitCommand = Get-Command git -ErrorAction SilentlyContinue
if ($GitCommand) {
    $GitOutput = (& git rev-parse HEAD 2>&1) -join "`n"
    if ($LASTEXITCODE -eq 0) {
        $DetectedCommit = $GitOutput.Trim()
        $DetectedCommitDetail = $DetectedCommit
    }
    else { $DetectedCommitDetail = "unavailable (git rev-parse HEAD failed: $($GitOutput.Trim()))" }
}

$LogRef = if (-not [string]::IsNullOrWhiteSpace($CommitSha)) { Get-SafeLogRef $CommitSha } elseif ($DetectedCommit -ne "unavailable") { Get-SafeLogRef $DetectedCommit } else { "unknown-ref" }
$Stamp = $UtcStart.ToString("yyyyMMdd-HHmmssZ")
$LogPath = Join-Path $LogDir "M04C-owner-verification-$Stamp-$LogRef.log"
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
    if ($Name -eq "Focused M04C") {
        $JoinedOutput = $script:LastStepOutput -join "`n"
        if (($JoinedOutput -match "Passing Tests\s+none") -or ($JoinedOutput -notmatch "Passing Tests\s+[1-9]")) {
            Write-LogLine "ERROR: Focused M04C GUT output did not report any passing tests."
            $StepExitCode = 1
        }
    }
    Write-LogLine "Exit code: $StepExitCode"
    if ($StepExitCode -ne 0) { Write-LogLine "FAILED: $Name"; Set-Failed $StepExitCode }
    else { Write-LogLine "PASSED: $Name" }
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
    if ($GutArgs.Count -gt 0) { & $Wrapper -GodotBin $ResolvedGodot -GutArgs $GutArgs }
    else { & $Wrapper -GodotBin $ResolvedGodot }
}

function Invoke-GodotCommand([string[]]$Arguments) {
    if ($ResolvedGodot -eq "unavailable") { throw "Godot 4.7.x was not found. Set -GodotBin, GODOT_BIN, or PATH." }
    & $ResolvedGodot @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Godot command failed with exit code $LASTEXITCODE." }
}

function Invoke-TraceMarkerVerification {
    param([string[]]$TraceOutput)

    $RequiredMarkers = @(
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
        "TRACE M04C no_clock_sources=PASS"
    )
    foreach ($Marker in $RequiredMarkers) {
        if (-not ($TraceOutput | Where-Object { $_ -eq $Marker })) { throw "Missing trace marker: $Marker" }
    }
    Write-Output "Trace markers verified: $($RequiredMarkers.Count)"
}


function Invoke-ArtifactAudit {
    if (-not (Test-Path -LiteralPath $LogPath -PathType Leaf)) { throw "Current owner verification log was not created: $LogPath" }
    $GitIgnorePath = Join-Path $RepoRoot ".gitignore"
    if (-not (Test-Path -LiteralPath $GitIgnorePath -PathType Leaf)) { throw ".gitignore is missing." }
    $GitIgnoreText = Get-Content -LiteralPath $GitIgnorePath -Raw
    if ($GitIgnoreText -notmatch '(?m)^/tools/test/owner/logs/$') { throw ".gitignore must contain /tools/test/owner/logs/ so owner evidence remains local." }
    $PriorLogs = Get-ChildItem -LiteralPath $LogDir -Filter "*.log" -File -ErrorAction SilentlyContinue
    Write-Output "Owner log directory may contain ignored prior evidence; found $($PriorLogs.Count) .log file(s)."
    if ($GitCommand) {
        $TrackedLogs = (& git ls-files -- "tools/test/owner/logs/*.log" 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "git ls-files failed while checking tracked owner logs: $($TrackedLogs -join "`n")" }
        if ($TrackedLogs.Count -gt 0) { throw "Owner logs are tracked and must be removed from the index: $($TrackedLogs -join ', ')" }
        $Status = (& git status --short 2>&1) -join "`n"
        Write-Output $Status
    }
    else { Write-Output "Git CLI unavailable; tracked-log detection skipped. The repository ignore rule was verified." }
    $TemporaryArtifacts = @()
    $TemporaryArtifacts += Get-ChildItem -LiteralPath $RepoRoot -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -in @("steam_appid.txt", "godot.log") }
    $TemporaryArtifacts += Get-ChildItem -LiteralPath (Join-Path $RepoRoot "tools\test") -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '(^tmp_|\.tmp$|\.bak$|\.orig$)' }
    if ($TemporaryArtifacts.Count -gt 0) { throw "Prohibited temporary/generated artifacts found outside ignored owner logs: $($TemporaryArtifacts.FullName -join ', ')" }
    Write-Output "Artifact audit complete."
}

$ResolvedGodot = Resolve-GodotForOwnerRun
$GodotVersion = "unavailable"
if ($ResolvedGodot -ne "unavailable") {
    $GodotVersionOutput = (& $ResolvedGodot --version 2>&1) -join "`n"
    if ($LASTEXITCODE -eq 0) { $GodotVersion = $GodotVersionOutput.Trim() }
    else { $GodotVersion = "unavailable (godot --version failed: $($GodotVersionOutput.Trim()))" }
}

Write-LogLine "Milestone: $Milestone"
Write-LogLine "Parent epic: $ParentEpic"
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
Write-LogLine "Isolated trace directory: $TraceRoot"
Write-LogLine "Log path: $LogPath"
Write-LogLine ""

if ((-not [string]::IsNullOrWhiteSpace($CommitSha)) -and $DetectedCommit -ne "unavailable" -and $DetectedCommit -ne $CommitSha) {
    Write-LogLine "FAILED: checked-out commit does not match -CommitSha."
    Set-Failed 67
    Write-SummaryAndExit $ExitCode
}

$FocusedGutArgs = @("-gdir=res://tests/unit/m04c", "-gdir=res://tests/integration/m04c")

try {
    New-Item -ItemType Directory -Force -Path $TraceRoot | Out-Null
    $GodotVersionPassed = Run-Step "Godot version validation" "$ResolvedGodot --version" {
        if ($ResolvedGodot -eq "unavailable") { throw "Godot 4.7.x was not found. Set -GodotBin, GODOT_BIN, or PATH." }
        & $ResolvedGodot --version
        if ($LASTEXITCODE -ne 0) { throw "Godot --version failed with exit code $LASTEXITCODE." }
        if ($GodotVersion -notmatch '^4\.7(\.|-|$)') { throw "Death Idle requires Godot 4.7.x; detected: $GodotVersion" }
    }
    if ($GodotVersionPassed) {
        Run-Step "Full GUT before" "tools\test\run_gut.ps1 -GodotBin <resolved>" { Invoke-GutWrapper }
        Run-Step "Focused M04C" "tools\test\run_gut.ps1 -GodotBin <resolved> -GutArgs @('-gdir=res://tests/unit/m04c','-gdir=res://tests/integration/m04c')" { Invoke-GutWrapper $FocusedGutArgs }
        $ImportPassed = Run-Step "Import" "$ResolvedGodot --headless --path $RepoRoot --import" { Invoke-GodotCommand @("--headless", "--path", "$RepoRoot", "--import") }
        if ($ImportPassed) {
            $TracePassed = Run-Step "Trace" "$ResolvedGodot --headless --path $RepoRoot -s res://tools/test/m04c/m04c_core_reaping_trace.gd -- --save-root $TraceRoot" { Invoke-GodotCommand @("--headless", "--path", "$RepoRoot", "-s", "res://tools/test/m04c/m04c_core_reaping_trace.gd", "--", "--save-root", "$TraceRoot") }
            $CapturedTraceOutput = @($script:LastStepOutput)
            if ($TracePassed) { Run-Step "Trace-result marker verification" "verify required TRACE M04C markers" { Invoke-TraceMarkerVerification -TraceOutput $CapturedTraceOutput } }
            else { Write-SkippedStep "Trace-result marker verification" "prerequisite failed: Trace" }
        }
        else {
            Write-SkippedStep "Trace" "prerequisite failed: Import"
            Write-SkippedStep "Trace-result marker verification" "prerequisite failed: Import"
        }
    }
    else {
        Write-SkippedStep "Full GUT before" "prerequisite failed: Godot version validation"
        Write-SkippedStep "Focused M04C" "prerequisite failed: Godot version validation"
        Write-SkippedStep "Import" "prerequisite failed: Godot version validation"
        Write-SkippedStep "Trace" "prerequisite failed: Godot version validation"
        Write-SkippedStep "Trace-result marker verification" "prerequisite failed: Godot version validation"
    }
}
finally {
    Run-Step "Cleanup" "Remove isolated trace directory" {
        if (Test-Path -LiteralPath $TraceRoot) { Remove-Item -LiteralPath $TraceRoot -Recurse -Force }
    }
    Run-Step "Cleanup proof" "Test isolated trace directory absent" {
        if (Test-Path -LiteralPath $TraceRoot) { throw "Trace directory still exists: $TraceRoot" }
    }
}

Run-Step "Artifact audit" "owner log, ignored logs, and temp artifact checks" { Invoke-ArtifactAudit }
Run-Step "Full GUT after" "tools\test\run_gut.ps1 -GodotBin <resolved>" { Invoke-GutWrapper }
Write-SummaryAndExit $ExitCode
