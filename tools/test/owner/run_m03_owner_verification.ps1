# Canonical owner-run Windows verification package for M03.
param(
    [string]$GodotBin,
    [string]$CommitSha = ""
)

$ErrorActionPreference = "Stop"
$Milestone = "M03"
$UtcStart = (Get-Date).ToUniversalTime()
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$LogDir = Join-Path $PSScriptRoot "logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

$FailedStepCount = 0
$ExitCode = 0
$CleanupResult = "PASS"
$PendingInteractiveChecks = "M03 Inspector checklist"
$RequestedCommit = if ([string]::IsNullOrWhiteSpace($CommitSha)) { "not supplied" } else { $CommitSha }
$DetectedCommit = "unavailable"
$DetectedCommitDetail = "unavailable (Git CLI not installed or not on PATH)"
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
$LogPath = Join-Path $LogDir "M03-owner-verification-$Stamp-$LogRef.log"
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
Write-LogLine ""

if ((-not [string]::IsNullOrWhiteSpace($CommitSha)) -and $DetectedCommit -ne "unavailable" -and $DetectedCommit -ne $CommitSha) {
    Write-LogLine "FAILED: checked-out commit does not match -CommitSha."
    Set-Failed 67
    Write-SummaryAndExit $ExitCode
}

$FocusedGutArgs = @("-gdir=res://tests/unit/content", "-gdir=res://tests/integration/content")

$GodotVersionPassed = Run-Step "Godot 4.7 version validation" "$ResolvedGodot --version" {
    if ($ResolvedGodot -eq "unavailable") { throw "Godot 4.7.x was not found. Set -GodotBin, GODOT_BIN, or PATH." }
    & $ResolvedGodot --version
    if ($LASTEXITCODE -ne 0) { throw "Godot --version failed with exit code $LASTEXITCODE." }
    if ($GodotVersion -notmatch '^4\.7(\.|-|$)') { throw "Death Idle requires Godot 4.7.x; detected: $GodotVersion" }
}

if ($GodotVersionPassed) {
    Run-Step "Full GUT suite before M03 trace" "tools\\test\\run_gut.ps1 -GodotBin <resolved>" { Invoke-GutWrapper }
    Run-Step "Focused M03 GUT suite" "tools\\test\\run_gut.ps1 -GodotBin <resolved> -GutArgs @('-gdir=res://tests/unit/content','-gdir=res://tests/integration/content')" { Invoke-GutWrapper $FocusedGutArgs }
    $ImportPassed = Run-Step "Explicit import preflight" "$ResolvedGodot --headless --path $RepoRoot --import" { Invoke-GodotCommand @("--headless", "--path", "$RepoRoot", "--import") }
    if ($ImportPassed) {
        Run-Step "M03 content catalog trace" "$ResolvedGodot --headless --path $RepoRoot -s res://tools/test/m03/m03_content_catalog_trace.gd" { Invoke-GodotCommand @("--headless", "--path", "$RepoRoot", "-s", "res://tools/test/m03/m03_content_catalog_trace.gd") }
    }
    else { Write-SkippedStep "M03 content catalog trace" "prerequisite failed: Explicit import preflight" }
    Run-Step "Artifact and temporary-file audit" "git status --short plus owner log guard" {
        $Status = ""
        if ($GitCommand) { $Status = (& git status --short 2>&1) -join "`n"; Write-Output $Status }
        $BadLogs = Get-ChildItem -LiteralPath $LogDir -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -ne $LogPath }
        if ($BadLogs) { throw "Unexpected committed/generated owner logs found: $($BadLogs.Name -join ', ')" }
        Write-Output "Artifact audit complete."
    }
    Run-Step "Full GUT suite after M03 trace" "tools\\test\\run_gut.ps1 -GodotBin <resolved>" { Invoke-GutWrapper }
}
else {
    Write-SkippedStep "Full GUT suite before M03 trace" "prerequisite failed: Godot 4.7 version validation"
    Write-SkippedStep "Focused M03 GUT suite" "prerequisite failed: Godot 4.7 version validation"
    Write-SkippedStep "Explicit import preflight" "prerequisite failed: Godot 4.7 version validation"
    Write-SkippedStep "M03 content catalog trace" "prerequisite failed: Godot 4.7 version validation"
    Write-SkippedStep "Artifact and temporary-file audit" "prerequisite failed: Godot 4.7 version validation"
    Write-SkippedStep "Full GUT suite after M03 trace" "prerequisite failed: Godot 4.7 version validation"
}

Write-SummaryAndExit $ExitCode
