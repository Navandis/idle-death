# Canonical owner-run Windows verification package for M04E2T1.
param(
    [string]$GodotBin,
    [string]$CommitSha = ""
)

$ErrorActionPreference = "Stop"
$Milestone = "M04E2T1"
$UtcStart = (Get-Date).ToUniversalTime()
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$LogDir = Join-Path $PSScriptRoot "logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$FailedStepCount = 0
$ExitCode = 0
$CleanupResult = "PASS"
$PendingInteractiveChecks = "None for M04E2T1"
$DetectedCommit = "unavailable"
$TraceRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("death-idle-m04e2t1-" + [System.Guid]::NewGuid().ToString("N"))

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
    if ($script:ExitCode -eq 0) { $script:ExitCode = $Code }
}

function Run-Step([string]$Name, [string]$Description, [scriptblock]$Action, [switch]$ExpectedNonZero) {
    Write-LogLine "=== $Name ==="
    Write-LogLine "Command: $Description"
    $StepExit = 0
    $ActionFailed = $false
    $script:LastStepOutput = @()
    try {
        # Native exit codes persist across PowerShell commands. Clear stale state
        # so a step with no native command cannot inherit an earlier failure.
        $global:LASTEXITCODE = 0
        $Output = & $Action 2>&1
        foreach ($Line in $Output) {
            $Text = "$Line"
            $script:LastStepOutput += $Text
            Write-LogLine $Text
        }
        if ($null -ne $LASTEXITCODE) { $StepExit = $LASTEXITCODE }
    }
    catch {
        $ActionFailed = $true
        $StepExit = 1
        Write-LogLine "ERROR: $($_.Exception.Message)"
    }
    Write-LogLine "Exit code: $StepExit"
    $StepPassed = (-not $ActionFailed) -and ($StepExit -eq 0)
    if ($ExpectedNonZero) { $StepPassed = (-not $ActionFailed) -and ($StepExit -ne 0) }
    if (-not $StepPassed) { Write-LogLine "FAILED: $Name"; Set-Failed $StepExit }
    else { Write-LogLine "PASSED: $Name" }
    Write-LogLine ""
    return $StepPassed
}

function Skip-Step([string]$Name, [string]$Reason) {
    Write-LogLine "=== $Name ==="
    Write-LogLine "SKIPPED: $Reason"
    Write-LogLine ""
    Set-Failed 1
}

function Invoke-Gut([string[]]$Arguments = @()) {
    $Wrapper = Join-Path $RepoRoot "tools\test\run_gut.ps1"
    & $Wrapper -GodotBin $ResolvedGodot -GutArgs $Arguments
    if ($LASTEXITCODE -ne 0) { throw "GUT wrapper failed with exit code $LASTEXITCODE." }
}

function Invoke-Godot([string[]]$Arguments) {
    & $ResolvedGodot @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Godot command failed with exit code $LASTEXITCODE." }
}

function Verify-TraceMarkers([string[]]$Output) {
    $Required = @(
        "TRACE M04E2T1 private_candidate_single_commit=PASS",
        "TRACE M04E2T1 run_context_captured_once=PASS",
        "TRACE M04E2T1 core_mutation_fact_shared_provenance=PASS",
        "TRACE M04E2T1 channel_mutation_fact_shared_provenance=PASS",
        "TRACE M04E2T1 settlement_boundary_fact_shared_provenance=PASS",
        "TRACE M04E2T1 timeline_only_transaction=PASS",
        "TRACE M04E2T1 partial_candidate_failure_preserves_live=PASS",
        "TRACE M04E2T1 compatibility_summary_derived_from_journal=PASS",
        "TRACE M04E2T1 events_derived_from_journal=PASS",
        "TRACE M04E2T1 one_hour_eight_hour_settlement_unchanged=PASS",
        "TRACE M04E2T1 forecast_commit_chunk_mode_equivalence=PASS",
        "TRACE M04E2T1 schema_v3_no_later_slice_artifacts=PASS"
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
    if (Get-ChildItem -LiteralPath $RepoRoot -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -in @("steam_appid.txt", "godot.log") }) {
        throw "Prohibited root artifact detected."
    }
    if ($GitAvailable) {
        $Tracked = (& git ls-files -- "tools/test/owner/logs/*.log" 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "git ls-files failed." }
        if ($Tracked.Count -gt 0) { throw "Owner logs are tracked." }
    }
    Write-LogLine "Artifact audit complete."
}

function Write-SummaryAndExit([int]$Code) {
    $Result = if ($Code -eq 0) { "PASS" } else { "FAIL" }
    Write-LogLine "Summary"
    Write-LogLine "Automated result: $Result"
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
$LogPath = Join-Path $LogDir ("M04E2T1-owner-verification-{0}-{1}.log" -f $UtcStart.ToString("yyyyMMdd-HHmmssZ"), $LogRef)
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

if (-not [string]::IsNullOrWhiteSpace($CommitSha) -and $DetectedCommit -ne "unavailable" -and $DetectedCommit -ne $CommitSha) {
    Write-LogLine "FAILED: checked-out commit does not match -CommitSha."
    Set-Failed 67
    Write-SummaryAndExit $ExitCode
}

$Focused = @(
    "-gdir=res://tests/unit/m04c",
    "-gdir=res://tests/unit/m04d2",
    "-gdir=res://tests/unit/m04d3",
    "-gdir=res://tests/unit/m04e1",
    "-gdir=res://tests/unit/m04e2t1",
    "-gdir=res://tests/integration/m04e1",
    "-gdir=res://tests/integration/m04e2t1"
)

try {
    New-Item -ItemType Directory -Force -Path $TraceRoot | Out-Null
    $GodotOk = Run-Step "Godot version validation" "$ResolvedGodot --version" {
        if ($ResolvedGodot -eq "unavailable") { throw "Godot 4.7.x was not found." }
        $Version = (& $ResolvedGodot --version 2>&1) -join "`n"
        Write-LogLine $Version
        if ($LASTEXITCODE -ne 0 -or $Version -notmatch '^4\.7(\.|-|$)') { throw "Godot 4.7.x is required; detected $Version" }
    }
    if ($GodotOk) {
        $FullBefore = Run-Step "Full GUT before" "tools\test\run_gut.ps1 -GodotBin <resolved>" { Invoke-Gut }
        $FocusedOk = $false
        if ($FullBefore) { $FocusedOk = Run-Step "Focused M04C-M04E2T1" "tools\test\run_gut.ps1 with seven focused directories" { Invoke-Gut $Focused } }
        else { Skip-Step "Focused M04C-M04E2T1" "prerequisite failed: Full GUT before" }
        $ImportOk = $false
        if ($FocusedOk) { $ImportOk = Run-Step "Import" "$ResolvedGodot --headless --path <repo> --import" { Invoke-Godot @("--headless", "--path", "$RepoRoot", "--import") } }
        else { Skip-Step "Import" "prerequisite failed: focused suite" }
        $TraceOk = $false
        if ($ImportOk) {
            $TraceOk = Run-Step "M04E2T1 trace" "$ResolvedGodot --headless --path <repo> -s m04e2t1_transaction_trace.gd -- --work-root <isolated>" { Invoke-Godot @("--headless", "--path", "$RepoRoot", "-s", "res://tools/test/m04e2t1/m04e2t1_transaction_trace.gd", "--", "--work-root", "$TraceRoot") }
            if ($TraceOk) {
                # Verify the persisted trace lines so marker checking observes the
                # same complete UTF-8 evidence that the owner receives in the log.
                Run-Step "Exact trace marker verification" "verify all 12 M04E2T1 markers" { Verify-TraceMarkers (Get-Content -LiteralPath $LogPath) }
            }
            else { Skip-Step "Exact trace marker verification" "prerequisite failed: trace" }
        }
        else {
            Skip-Step "M04E2T1 trace" "prerequisite failed: import"
            Skip-Step "Exact trace marker verification" "prerequisite failed: import"
        }
        Run-Step "Missing-root trace must fail" "$ResolvedGodot --headless ... m04e2t1_transaction_trace.gd (no --work-root)" {
            # Godot reports the intentional missing-root assertion on stderr. Do
            # not let that expected native diagnostic become a PowerShell throw;
            # a throw from the explicit success assertion below must still fail.
            $previousErrorActionPreference = $ErrorActionPreference
            $ErrorActionPreference = "Continue"
            try {
                & $ResolvedGodot --headless --path "$RepoRoot" -s "res://tools/test/m04e2t1/m04e2t1_transaction_trace.gd"
                $negativeExit = $LASTEXITCODE
            }
            finally {
                $ErrorActionPreference = $previousErrorActionPreference
            }
            if ($negativeExit -eq 0) { throw "Missing-root trace unexpectedly succeeded." }
            Write-Output "Negative trace exit confirmed: $negativeExit"
        } -ExpectedNonZero
    }
    else {
        Skip-Step "Full GUT before" "prerequisite failed: Godot version validation"
        Skip-Step "Focused M04C-M04E2T1" "prerequisite failed: Godot version validation"
        Skip-Step "Import" "prerequisite failed: Godot version validation"
        Skip-Step "M04E2T1 trace" "prerequisite failed: Godot version validation"
        Skip-Step "Exact trace marker verification" "prerequisite failed: Godot version validation"
        Skip-Step "Missing-root trace must fail" "prerequisite failed: Godot version validation"
    }
}
finally {
    $Clean = Run-Step "Cleanup" "remove isolated trace directory" { if (Test-Path -LiteralPath $TraceRoot) { Remove-Item -LiteralPath $TraceRoot -Recurse -Force } }
    $Proof = Run-Step "Cleanup absence proof" "test isolated trace directory is absent" { if (Test-Path -LiteralPath $TraceRoot) { throw "Trace root remains: $TraceRoot" } }
    if (-not $Clean -or -not $Proof) { $CleanupResult = "FAIL" }
}

Run-Step "Artifact audit" "owner log, ignore rule, and generated-artifact checks" { Invoke-ArtifactAudit }
Run-Step "Full GUT after" "tools\test\run_gut.ps1 -GodotBin <resolved>" { Invoke-Gut }
Write-SummaryAndExit $ExitCode
