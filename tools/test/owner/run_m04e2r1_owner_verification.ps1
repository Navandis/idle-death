<#
Runs the M04E2R1 owner evidence package at one exact commit.  It deliberately
uses fresh Godot import state and restores any pre-existing .godot directory.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ExpectedSha,
    [string]$GodotBin,
    [ValidateSet('None', 'RestoreCopyFailure')][string]$FaultInjection = 'None'
)

$ErrorActionPreference = 'Stop'
$script:FailedSteps = 0
$script:CleanupResult = 'FAIL'
$script:CleanupAbsence = 'FAIL'
$script:ArtifactAudit = 'FAIL'
$script:ImportResult = 'FAIL'
$script:SmokeResult = 'FAIL'
$script:FullGutSummary = 'FAIL'
$script:FocusedSummary = 'FAIL'
$script:TraceSummary = 'FAIL'
$script:LogPath = $null
$script:TempRoot = $null
$script:GodotBackup = $null
$script:OriginalGodotState = 'PreparationNotStarted'
$script:BackupState = 'NotCreated'
$script:FreshStatePreparationStarted = $false
$script:FreshStatePrepared = $false
$script:RestorationVerified = $false
$script:RecoveryBackupRetained = $false
$script:GodotFingerprint = @()
$script:StatusBaseline = ''
$script:IgnoredBaseline = @()
$script:RelevantArtifactBaseline = @()

$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$LogsRoot = Join-Path $RepositoryRoot 'tools\test\owner\logs'

function Write-Log([string]$Text) {
    $line = '[{0:O}] {1}' -f [DateTime]::UtcNow, $Text
    Write-Host $line
    if ($script:LogPath) { Add-Content -LiteralPath $script:LogPath -Value $line -Encoding UTF8 }
}

function Add-Failure([string]$Message) {
    $script:FailedSteps++
    Write-Log "FAIL $Message"
}

function Resolve-GodotBinary {
    if ($GodotBin) { return $GodotBin }
    if ($env:GODOT_BIN) { return $env:GODOT_BIN }
    $fromPath = Get-Command godot -ErrorAction SilentlyContinue
    if ($fromPath) { return $fromPath.Source }
    $fromPath = Get-Command godot4 -ErrorAction SilentlyContinue
    if ($fromPath) { return $fromPath.Source }
    throw 'Godot 4.7.x was not found. Pass -GodotBin, set GODOT_BIN, or add godot/godot4 to PATH.'
}

function Get-DirectoryFingerprint([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return @() }
    $root = (Resolve-Path -LiteralPath $Path).Path
    $items = Get-ChildItem -LiteralPath $root -Force -Recurse | Sort-Object FullName
    $fingerprint = @()
    foreach ($item in $items) {
        $relative = $item.FullName.Substring($root.Length).TrimStart('\')
        if ($item.PSIsContainer) {
            $fingerprint += "D|$relative"
        } else {
            $hash = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash
            $fingerprint += "F|$relative|$($item.Length)|$hash"
        }
    }
    return $fingerprint
}

function Get-RelevantArtifacts {
    $items = Get-ChildItem -LiteralPath $RepositoryRoot -Force -Recurse -ErrorAction SilentlyContinue |
        Where-Object {
            -not $_.PSIsContainer -and (
                $_.Name -ieq 'godot.log' -or $_.Name -ieq 'steam_appid.txt' -or
                $_.Extension -in @('.tmp', '.temp', '.trace', '.cache') -or
                $_.Name -match '(?i)(trace.*(out|log)|temporary.*\.uid$)'
            )
        } |
        ForEach-Object { $_.FullName.Substring($RepositoryRoot.Length).TrimStart('\') } |
        Sort-Object
    return @($items)
}

function Invoke-NativeStep([string]$Name, [string]$Command, [string[]]$Arguments, [scriptblock]$Validator) {
    Write-Log "COMMAND ${Name}: $Command $($Arguments -join ' ')"
    $output = @(& $Command @Arguments 2>&1)
    $exitCode = $LASTEXITCODE
    Write-Log "NATIVE EXIT ${Name}: $exitCode"
    foreach ($line in $output) { Write-Log "OUTPUT ${Name}: $($line.ToString())" }
    $passed = $exitCode -eq 0
    if ($passed -and $Validator) {
        try {
            $passed = & $Validator (($output | ForEach-Object { $_.ToString() }) -join "`n") $exitCode
            if (-not $passed) { Write-Log "VALIDATOR ${Name}: native output did not meet the required evidence." }
        }
        catch { $passed = $false; Write-Log "VALIDATOR ${Name}: $($_.Exception.Message)" }
    }
    if ($passed) {
        Write-Log "PASS $Name"
    } else {
        Add-Failure "$Name (native exit $exitCode)"
    }
    return $passed
}

function Test-ExactCounts([string]$Output, [int]$Tests, [int]$Passing, [int]$Assertions) {
    $testsMatch = [regex]::Matches($Output, "(?im)^\s*Tests(?:\s*:\s*|\s+)$Tests\s*$")
    $passingMatch = [regex]::Matches($Output, "(?im)^\s*Passing tests(?:\s*:\s*|\s+)$Passing\s*$")
    $assertionMatch = [regex]::Matches($Output, "(?im)^\s*(?:Assertions|Asserts)(?:\s*:\s*|\s+)$Assertions\s*$")
    return $testsMatch.Count -eq 1 -and $passingMatch.Count -eq 1 -and $assertionMatch.Count -eq 1
}

function Test-TraceMarkers([string]$Output) {
    $markers = @(
        'TRACE M04E2R1 apply=PASS',
        'TRACE M04E2R1 duplicate_no_op=PASS',
        'TRACE M04E2R1 forward_gap_reject=PASS',
        'TRACE M04E2R1 source_continuity_and_rejection_no_mutation=PASS',
        'TRACE M04E2R1 active_one_shot_equals_chunks=PASS',
        'TRACE M04E2R1 timeline_one_shot_equals_chunks=PASS',
        'TRACE M04E2R1 settlement_crossing_one_shot_equals_chunks=PASS',
        'TRACE M04E2R1 channel_progress_banking_one_shot_equals_chunks=PASS',
        'TRACE M04E2R1 settlement_once_bank_events_folded=PASS',
        'TRACE M04E2R1 persistence_exclusion=PASS',
        'TRACE M04E2R1 overflow_rejected_without_mutation=PASS'
    )
    foreach ($marker in $markers) {
        if ([regex]::Matches($Output, "(?m)^$([regex]::Escape($marker))$").Count -ne 1) { return $false }
    }
    return $true
}

function Invoke-Cleanup {
    try {
        $godotRoot = Join-Path $RepositoryRoot '.godot'
        if (-not $script:FreshStatePreparationStarted) {
            Write-Log 'Cleanup skipped cache removal because fresh-state preparation never began.'
        } elseif ($script:OriginalGodotState -eq 'OriginalAbsent') {
            if (Test-Path -LiteralPath $godotRoot) {
                Remove-Item -LiteralPath $godotRoot -Recurse -Force
            }
            if (Test-Path -LiteralPath $godotRoot) {
                throw 'A newly generated .godot directory remains after cleanup.'
            }
        } elseif ($script:BackupState -eq 'IndependentBackupVerified') {
            if (-not $script:FreshStatePrepared) {
                $originalStillIntact = (Test-Path -LiteralPath $godotRoot) -and (@(Get-DirectoryFingerprint $godotRoot) -join "`n") -eq (@($script:GodotFingerprint) -join "`n")
                if (-not $originalStillIntact) {
                    throw 'Fresh-state preparation did not complete and the original .godot directory is no longer exact.'
                }
                $script:RestorationVerified = $true
            } else {
                if (Test-Path -LiteralPath $godotRoot) {
                    Remove-Item -LiteralPath $godotRoot -Recurse -Force
                }
                if ($FaultInjection -eq 'RestoreCopyFailure') {
                    throw 'Injected restoration copy failure for isolated recovery validation.'
                }
                Copy-Item -LiteralPath $script:GodotBackup -Destination $godotRoot -Recurse -Force -ErrorAction Stop
                $restored = (Test-Path -LiteralPath $godotRoot) -and (@(Get-DirectoryFingerprint $godotRoot) -join "`n") -eq (@($script:GodotFingerprint) -join "`n")
                if (-not $restored) { throw 'The pre-existing .godot directory was not restored exactly.' }
                $script:RestorationVerified = $true
            }
            if ($script:RestorationVerified) {
                Remove-Item -LiteralPath $script:GodotBackup -Recurse -Force -ErrorAction Stop
                $script:GodotBackup = $null
                $script:BackupState = 'RemovedAfterRestorationVerified'
            }
        } else {
            throw 'Fresh-state preparation began without a verified backup for a pre-existing .godot directory.'
        }
        $script:CleanupResult = 'PASS'
        Write-Log 'Cleanup result: PASS'
    } catch {
        if ($script:BackupState -eq 'IndependentBackupVerified' -and $script:GodotBackup -and (Test-Path -LiteralPath $script:GodotBackup)) {
            $script:RecoveryBackupRetained = $true
            Write-Log "RECOVERY BACKUP RETAINED: $script:GodotBackup"
            Write-Log "RECOVERY ROOT RETAINED: $script:TempRoot"
        }
        Add-Failure "cleanup: $($_.Exception.Message)"
        Write-Log 'Cleanup result: FAIL'
    }

}

function Assert-CleanupAbsence {
    try {
        if ($script:RecoveryBackupRetained) {
            throw "A verified recovery backup was retained at $script:GodotBackup."
        }
        $tempAbsent = -not $script:TempRoot -or -not (Test-Path -LiteralPath $script:TempRoot)
        $backupAbsent = -not $script:GodotBackup -or -not (Test-Path -LiteralPath $script:GodotBackup)
        if (-not $tempAbsent -or -not $backupAbsent) { throw 'Runner-owned temporary state remains.' }
        $script:CleanupAbsence = 'PASS'
        Write-Log 'Cleanup absence proof: PASS'
    } catch {
        Add-Failure "cleanup absence proof: $($_.Exception.Message)"
        Write-Log 'Cleanup absence proof: FAIL'
    }
}

function Invoke-ArtifactAudit {
    try {
        $postStatus = @(git -C $RepositoryRoot status --porcelain=v1) -join "`n"
        if ($postStatus -ne $script:StatusBaseline) { throw 'Ordinary repository status differs from its pre-run baseline.' }
        $postIgnored = @(git -C $RepositoryRoot ls-files --others --ignored --exclude-standard) | Sort-Object
        $baselineIgnored = @($script:IgnoredBaseline) | Sort-Object
        if ((@($postIgnored) -join "`n") -ne (@($baselineIgnored) -join "`n")) { throw 'Ignored-artifact set differs from its pre-run baseline.' }
        $postArtifacts = @(Get-RelevantArtifacts)
        if ((@($postArtifacts) -join "`n") -ne (@($script:RelevantArtifactBaseline) -join "`n")) { throw 'A new relevant generated artifact remains.' }
        & git -C $RepositoryRoot check-ignore -q -- ($script:LogPath.Substring($RepositoryRoot.Length).TrimStart('\'))
        if ($LASTEXITCODE -ne 0) { throw 'The retained owner log is not ignored.' }
        $trackedOwnerLog = @(git -C $RepositoryRoot ls-files -- ($script:LogPath.Substring($RepositoryRoot.Length).TrimStart('\')))
        if ($trackedOwnerLog.Count -ne 0) { throw 'The retained owner log is tracked.' }
        $script:ArtifactAudit = 'PASS'
        Write-Log 'Artifact audit: PASS'
    } catch {
        Add-Failure "artifact audit: $($_.Exception.Message)"
        Write-Log 'Artifact audit: FAIL'
    }
}

New-Item -ItemType Directory -Path $LogsRoot -Force | Out-Null
$script:LogPath = Join-Path $LogsRoot ('M04E2R1-{0:yyyyMMddTHHmmssZ}-{1}.log' -f [DateTime]::UtcNow, [guid]::NewGuid().ToString('N'))
New-Item -ItemType File -Path $script:LogPath -Force | Out-Null

try {
    Set-Location $RepositoryRoot
    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $git) { throw 'Git is required to prove the requested SHA and clean repository state.' }
    $script:StatusBaseline = @(git -C $RepositoryRoot status --porcelain=v1) -join "`n"
    if (-not [string]::IsNullOrEmpty($script:StatusBaseline)) { throw 'The ordinary non-ignored working tree must be clean before verification.' }
    $script:IgnoredBaseline = @(git -C $RepositoryRoot ls-files --others --ignored --exclude-standard) | Sort-Object
    $script:RelevantArtifactBaseline = @(Get-RelevantArtifacts)
    $detectedSha = (git -C $RepositoryRoot rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Could not detect the local Git HEAD.' }
    if ($detectedSha -ne $ExpectedSha) { throw "Requested SHA $ExpectedSha does not match detected HEAD $detectedSha." }
    $resolvedGodot = Resolve-GodotBinary
    if (-not (Test-Path -LiteralPath $resolvedGodot)) { throw "Godot executable does not exist: $resolvedGodot" }
    $godotVersion = @(& $resolvedGodot --version 2>&1) -join "`n"
    if ($LASTEXITCODE -ne 0 -or $godotVersion -notmatch '^4\.7(\.|-|$)') { throw "Godot 4.7.x is required; detected: $godotVersion" }

    Write-Log 'Milestone or slice: M04E2R1'
    Write-Log "UTC start: $([DateTime]::UtcNow.ToString('O'))"
    Write-Log "Repository root: $RepositoryRoot"
    Write-Log "Requested SHA: $ExpectedSha"
    Write-Log "Detected SHA: $detectedSha"
    Write-Log "Windows version: $([Environment]::OSVersion.VersionString)"
    Write-Log "PowerShell version: $($PSVersionTable.PSVersion)"
    Write-Log "Godot executable: $resolvedGodot"
    Write-Log "Godot version: $godotVersion"
	$PowerShellExe = (Get-Command powershell.exe -ErrorAction Stop).Source

    $script:TempRoot = Join-Path ([IO.Path]::GetTempPath()) ('m04e2r1-owner-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $script:TempRoot -Force | Out-Null
    $godotRoot = Join-Path $RepositoryRoot '.godot'
    if (Test-Path -LiteralPath $godotRoot) {
        $script:OriginalGodotState = 'OriginalDetectedUntouched'
        $script:GodotFingerprint = @(Get-DirectoryFingerprint $godotRoot)
        $script:GodotBackup = Join-Path $script:TempRoot 'original-godot'
        Copy-Item -LiteralPath $godotRoot -Destination $script:GodotBackup -Recurse -Force -ErrorAction Stop
        $backupFingerprint = @(Get-DirectoryFingerprint $script:GodotBackup)
        if (-not (Test-Path -LiteralPath $script:GodotBackup) -or (@($backupFingerprint) -join "`n") -ne (@($script:GodotFingerprint) -join "`n")) {
            throw 'The independent .godot backup did not match the original fingerprint.'
        }
        $script:BackupState = 'IndependentBackupVerified'
        Write-Log 'Pre-existing .godot fingerprinted and copied to a verified independent backup.'
        $script:FreshStatePreparationStarted = $true
        Remove-Item -LiteralPath $godotRoot -Recurse -Force -ErrorAction Stop
        $script:OriginalGodotState = 'OriginalRemovedForFreshState'
        $script:FreshStatePrepared = $true
        Write-Log 'Fresh-state preparation completed after independent backup verification.'
    } else {
        $script:OriginalGodotState = 'OriginalAbsent'
        $script:FreshStatePreparationStarted = $true
        if (Test-Path -LiteralPath $godotRoot) {
            Remove-Item -LiteralPath $godotRoot -Recurse -Force -ErrorAction Stop
        }
        $script:FreshStatePrepared = $true
        Write-Log 'No pre-existing .godot directory was present.'
    }

    $wrapperPath = Join-Path $RepositoryRoot 'tools\test\run_gut.ps1'
    $fullOk = Invoke-NativeStep 'full-gut' $PowerShellExe @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $wrapperPath, '-GodotBin', $resolvedGodot) { param($output, $exitCode) Test-ExactCounts $output 186 186 2878 }
    $script:FullGutSummary = if ($fullOk) { 'PASS' } else { 'FAIL' }
    $focusedCommand = "& '$wrapperPath' -GodotBin '$resolvedGodot' -GutArgs @('-gtest=res://tests/unit/m04e2r1/test_report_ledger.gd','-gtest=res://tests/unit/m04e2r1/test_report_ledger_ingestion.gd','-gtest=res://tests/unit/m04e2r1/test_report_ledger_interval_matrix.gd','-gtest=res://tests/integration/m04e2r1/test_report_ledger_persistence_exclusion.gd')"
    $focusedOk = Invoke-NativeStep 'focused-r1' $PowerShellExe @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', $focusedCommand) { param($output, $exitCode) Test-ExactCounts $output 8 8 46 }
    $script:FocusedSummary = if ($focusedOk) { 'PASS' } else { 'FAIL' }
    $importOk = Invoke-NativeStep 'import' $resolvedGodot @('--headless', '--path', $RepositoryRoot, '--import') $null
    $script:ImportResult = if ($importOk) { 'PASS' } else { 'FAIL' }
    $traceOk = Invoke-NativeStep 'trace' $resolvedGodot @('--headless', '--path', $RepositoryRoot, '-s', 'res://tools/test/m04e2r1/m04e2r1_report_ledger_trace.gd') { param($output, $exitCode) Test-TraceMarkers $output }
    $script:TraceSummary = if ($traceOk) { 'PASS' } else { 'FAIL' }
    $smokeOk = Invoke-NativeStep 'main-scene-smoke' $resolvedGodot @('--headless', '--path', $RepositoryRoot, '--quit-after', '5') $null
    $script:SmokeResult = if ($smokeOk) { 'PASS' } else { 'FAIL' }
    Invoke-NativeStep 'diff-check' $git.Source @('-C', $RepositoryRoot, 'diff', '--check') $null | Out-Null
} catch {
    Add-Failure "verification setup: $($_.Exception.Message)"
} finally {
    Invoke-Cleanup
    if ($script:RecoveryBackupRetained) {
        Write-Log "RECOVERY ROOT RETAINED: $script:TempRoot"
    } elseif ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        try { Remove-Item -LiteralPath $script:TempRoot -Recurse -Force } catch { Add-Failure "temporary-root removal: $($_.Exception.Message)" }
    }
    Assert-CleanupAbsence
    Invoke-ArtifactAudit
    $automated = if ($script:FailedSteps -eq 0 -and $script:FullGutSummary -eq 'PASS' -and $script:FocusedSummary -eq 'PASS' -and $script:TraceSummary -eq 'PASS' -and $script:ImportResult -eq 'PASS' -and $script:SmokeResult -eq 'PASS' -and $script:CleanupResult -eq 'PASS' -and $script:CleanupAbsence -eq 'PASS' -and $script:ArtifactAudit -eq 'PASS') { 'PASS' } else { 'FAIL' }
    Write-Log 'Final summary:'
    Write-Log "Full GUT: 186/186 tests, 2878 assertions ($script:FullGutSummary)"
    Write-Log "Focused R1: 8/8 tests, 46 assertions ($script:FocusedSummary)"
    Write-Log "Trace markers: 11/11 ($script:TraceSummary)"
    Write-Log "Import: $script:ImportResult"
    Write-Log "Main-scene smoke: $script:SmokeResult"
    Write-Log "Cleanup result: $script:CleanupResult"
    Write-Log "Cleanup absence proof: $script:CleanupAbsence"
    Write-Log "Artifact audit: $script:ArtifactAudit"
    Write-Log "Automated result: $automated"
    Write-Log "Failed step count: $script:FailedSteps"
    Write-Log 'Pending interactive checks: None for M04E2R1'
    Write-Log "Log path: $script:LogPath"
    if ($automated -ne 'PASS') { exit 1 }
}

exit 0
