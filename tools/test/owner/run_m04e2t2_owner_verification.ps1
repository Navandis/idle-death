# Canonical exact-head Windows owner package for M04E2T2.
param(
    [string]$GodotBin,
    [string]$CommitSha = ""
)

$ErrorActionPreference = "Stop"
$Milestone = "M04E2T2"
$UtcStart = (Get-Date).ToUniversalTime()
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$LogDir = Join-Path $PSScriptRoot "logs"
$TraceRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("death-idle-m04e2t2-" + [System.Guid]::NewGuid().ToString("N"))
$FailedStepCount = 0
$ExitCode = 0
$CleanupResult = "PASS"
$PendingInteractiveChecks = "None for M04E2T2"
$DetectedCommit = "unavailable"

function Resolve-GodotForOwnerRun {
    if (-not [string]::IsNullOrWhiteSpace($GodotBin)) { return $GodotBin }
    if (-not [string]::IsNullOrWhiteSpace($env:GODOT_BIN)) { return $env:GODOT_BIN }
    $Found = Get-Command godot -ErrorAction SilentlyContinue
    if ($Found) { return $Found.Source }
    $Found = Get-Command godot4 -ErrorAction SilentlyContinue
    if ($Found) { return $Found.Source }
    return "unavailable"
}

function Get-SafeRef([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return "unknown-ref" }
    return ($Value -replace '[^A-Za-z0-9_.-]', '-')
}

function Write-LogLine([string]$Line) {
    Write-Host $Line
    Add-Content -LiteralPath $LogPath -Encoding UTF8 -Value $Line
}

function Set-Failed([int]$Code = 1) {
    $script:FailedStepCount += 1
    if ($script:ExitCode -eq 0) { $script:ExitCode = if ($Code -eq 0) { 1 } else { $Code } }
}

function Run-Step([string]$Name, [string]$Description, [scriptblock]$Action, [switch]$ExpectedNonZero) {
    Write-LogLine "=== $Name ==="
    Write-LogLine "Command: $Description"
    $StepExit = 0
    $ActionFailed = $false
    try {
        $global:LASTEXITCODE = 0
        $Output = & $Action 2>&1
        foreach ($Line in $Output) { Write-LogLine "$Line" }
        if ($null -ne $LASTEXITCODE) { $StepExit = $LASTEXITCODE }
    }
    catch {
        $ActionFailed = $true
        $StepExit = 1
        Write-LogLine "ERROR: $($_.Exception.Message)"
    }
    Write-LogLine "Exit code: $StepExit"
    $Passed = (-not $ActionFailed) -and ($(if ($ExpectedNonZero) { $StepExit -ne 0 } else { $StepExit -eq 0 }))
    if (-not $Passed) { Write-LogLine "FAILED: $Name"; Set-Failed $StepExit }
    else { Write-LogLine "PASSED: $Name" }
    Write-LogLine ""
    return $Passed
}

function Skip-Step([string]$Name, [string]$Reason) {
    Write-LogLine "=== $Name ==="
    Write-LogLine "SKIPPED: $Reason"
    Write-LogLine ""
    Set-Failed 1
}

function Invoke-Gut([string[]]$Arguments = @()) {
    & (Join-Path $RepoRoot "tools\test\run_gut.ps1") -GodotBin $ResolvedGodot -GutArgs $Arguments
    if ($LASTEXITCODE -ne 0) { throw "GUT wrapper failed with exit code $LASTEXITCODE." }
}

function Invoke-Godot([string[]]$Arguments) {
    & $ResolvedGodot @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Godot command failed with exit code $LASTEXITCODE." }
}

function Verify-TraceMarkers([string[]]$Output) {
    $Required = @(
        "TRACE M04E2T2 typed_result_envelope=PASS",
        "TRACE M04E2T2 segment_historical_identity=PASS",
        "TRACE M04E2T2 channel_endpoint_contract=PASS",
        "TRACE M04E2T2 channel_event_closed_union=PASS",
        "TRACE M04E2T2 settlement_event_closed_union=PASS",
        "TRACE M04E2T2 timeline_only_positive=PASS",
        "TRACE M04E2T2 zero_and_failure_no_authority=PASS",
        "TRACE M04E2T2 one_hour_values_unchanged=PASS",
        "TRACE M04E2T2 eight_hour_values_unchanged=PASS",
        "TRACE M04E2T2 settlement_segments_and_order=PASS",
        "TRACE M04E2T2 same_timestamp_attribution=PASS",
        "TRACE M04E2T2 equal_output_identity_distinct=PASS",
        "TRACE M04E2T2 forecast_commit_mode_equivalence=PASS",
        "TRACE M04E2T2 raw_public_grammar_removed=PASS",
        "TRACE M04E2T2 schema_v3_no_result_artifacts=PASS"
    )
    foreach ($Marker in $Required) {
        if (-not ($Output | Where-Object { $_ -eq $Marker })) { throw "Missing trace marker: $Marker" }
    }
    Write-LogLine "Trace markers verified: $($Required.Count)"
}

function Invoke-ArtifactAudit {
    $IgnorePath = Join-Path $RepoRoot ".gitignore"
    if (-not (Test-Path -LiteralPath $IgnorePath)) { throw ".gitignore is missing." }
    $IgnoreText = Get-Content -LiteralPath $IgnorePath -Raw
    if ($IgnoreText -notmatch '(?m)^/tools/test/owner/logs/$') { throw "Owner log ignore rule is missing." }
    if (Test-Path -LiteralPath $TraceRoot) { throw "Trace root remains before artifact audit." }
    if ($GitAvailable) {
        $Tracked = (& git ls-files -- "tools/test/owner/logs/*.log" 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "git ls-files failed." }
        if ($Tracked.Count -gt 0) { throw "Owner logs are tracked." }
    }
}

function Write-SummaryAndExit([int]$Code) {
    Write-LogLine "Summary"
    Write-LogLine ("Automated result: " + $(if ($Code -eq 0) { "PASS" } else { "FAIL" }))
    Write-LogLine "Failed step count: $FailedStepCount"
    Write-LogLine "Pending interactive checks: $PendingInteractiveChecks"
    Write-LogLine "Cleanup result: $CleanupResult"
    Write-LogLine "Log path: $LogPath"
    exit $Code
}

Set-Location $RepoRoot
$GitAvailable = [bool](Get-Command git -ErrorAction SilentlyContinue)
if ($GitAvailable) {
    $DetectedOutput = (& git rev-parse HEAD 2>&1) -join "`n"
    if ($LASTEXITCODE -eq 0) { $DetectedCommit = $DetectedOutput.Trim() }
}
$ResolvedGodot = Resolve-GodotForOwnerRun
$RequestedRef = if ([string]::IsNullOrWhiteSpace($CommitSha)) { "not supplied" } else { $CommitSha }
$LogRef = if (-not [string]::IsNullOrWhiteSpace($CommitSha)) { Get-SafeRef $CommitSha } else { Get-SafeRef $DetectedCommit }
$LogPath = Join-Path $LogDir ("M04E2T2-owner-verification-{0}-{1}.log" -f $UtcStart.ToString("yyyyMMdd-HHmmssZ"), $LogRef)
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
"" | Set-Content -LiteralPath $LogPath -Encoding UTF8

Write-LogLine "Milestone: $Milestone"
Write-LogLine "UTC start: $($UtcStart.ToString('yyyy-MM-ddTHH:mm:ssZ'))"
Write-LogLine "Repository root: $RepoRoot"
Write-LogLine "Requested commit or PR head: $RequestedRef"
Write-LogLine "Detected Git commit, when available: $DetectedCommit"
Write-LogLine "Windows version: $([Environment]::OSVersion.VersionString)"
Write-LogLine "PowerShell version: $($PSVersionTable.PSVersion.ToString())"
Write-LogLine "Godot executable: $ResolvedGodot"
Write-LogLine "Godot version: unavailable until validation"
Write-LogLine "Log path: $LogPath"
Write-LogLine ""

if (-not [string]::IsNullOrWhiteSpace($CommitSha)) {
    if ($DetectedCommit -eq "unavailable" -or $DetectedCommit -ne $CommitSha) {
        Write-LogLine "FAILED: supplied -CommitSha requires an exact detected Git head."
        Set-Failed 67
        Write-SummaryAndExit $ExitCode
    }
}

$Focused = @(
    "-gdir=res://tests/unit/m04c",
    "-gdir=res://tests/unit/m04d2",
    "-gdir=res://tests/unit/m04d3",
    "-gdir=res://tests/unit/m04e1",
    "-gdir=res://tests/unit/m04e2t1",
    "-gdir=res://tests/unit/m04e2t2",
    "-gdir=res://tests/integration/m04e1",
    "-gdir=res://tests/integration/m04e2t1",
    "-gdir=res://tests/integration/m04e2t2"
)

try {
    New-Item -ItemType Directory -Force -Path $TraceRoot | Out-Null
    $GodotOk = Run-Step "Godot version validation" "$ResolvedGodot --version" {
        if ($ResolvedGodot -eq "unavailable") { throw "Godot 4.7.x was not found." }
        $Version = (& $ResolvedGodot --version 2>&1) -join "`n"
        Write-LogLine $Version
        if ($LASTEXITCODE -ne 0 -or $Version -notmatch '^4\.7(\.|-|$)') { throw "Godot 4.7.x is required; detected $Version" }
    }
    $FullBefore = $false
    $FocusedOk = $false
    $ImportOk = $false
    if ($GodotOk) { $FullBefore = Run-Step "Full GUT before" "tools\test\run_gut.ps1" { Invoke-Gut } }
    else { Skip-Step "Full GUT before" "prerequisite failed: Godot version validation" }
    if ($FullBefore) { $FocusedOk = Run-Step "Focused M04C-M04E2T2" "tools\test\run_gut.ps1 with nine focused directories" { Invoke-Gut $Focused } }
    else { Skip-Step "Focused M04C-M04E2T2" "prerequisite failed: full GUT before" }
    if ($FocusedOk) { $ImportOk = Run-Step "Import" "$ResolvedGodot --headless --path <repo> --import" { Invoke-Godot @("--headless", "--path", "$RepoRoot", "--import") } }
    else { Skip-Step "Import" "prerequisite failed: focused suite" }
    $TraceOk = $false
    if ($ImportOk) {
        $TraceOk = Run-Step "M04E2T2 trace" "$ResolvedGodot --headless --path <repo> -s m04e2t2_finalized_facts_trace.gd -- --work-root <isolated>" { Invoke-Godot @("--headless", "--path", "$RepoRoot", "-s", "res://tools/test/m04e2t2/m04e2t2_finalized_facts_trace.gd", "--", "--work-root", "$TraceRoot") }
        if ($TraceOk) { Run-Step "Exact 15-marker verification" "verify all M04E2T2 markers" { Verify-TraceMarkers (Get-Content -LiteralPath $LogPath) } }
        else { Skip-Step "Exact 15-marker verification" "prerequisite failed: trace" }
    }
    else {
        Skip-Step "M04E2T2 trace" "prerequisite failed: import"
        Skip-Step "Exact 15-marker verification" "prerequisite failed: import"
    }
    Run-Step "Missing-root trace must fail" "$ResolvedGodot --headless ... m04e2t2_finalized_facts_trace.gd (no --work-root)" {
        $oldPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        try {
            & $ResolvedGodot --headless --path "$RepoRoot" -s "res://tools/test/m04e2t2/m04e2t2_finalized_facts_trace.gd"
            $negativeExit = $LASTEXITCODE
        }
        finally { $ErrorActionPreference = $oldPreference }
        if ($negativeExit -eq 0) { throw "Missing-root trace unexpectedly succeeded." }
        Write-Output "Negative trace exit confirmed: $negativeExit"
    } -ExpectedNonZero
}
finally {
    $Clean = Run-Step "Cleanup" "remove isolated trace directory" { if (Test-Path -LiteralPath $TraceRoot) { Remove-Item -LiteralPath $TraceRoot -Recurse -Force } }
    $Proof = Run-Step "Cleanup absence proof" "test isolated trace directory is absent" { if (Test-Path -LiteralPath $TraceRoot) { throw "Trace root remains: $TraceRoot" } }
    if (-not $Clean -or -not $Proof) { $CleanupResult = "FAIL" }
}

Run-Step "Artifact audit" "owner log ignore and generated-artifact checks" { Invoke-ArtifactAudit }
Run-Step "Full GUT after" "tools\test\run_gut.ps1" { Invoke-Gut }
Write-SummaryAndExit $ExitCode
