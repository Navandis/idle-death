<#
Runs the exact-head Windows owner-verification package for M04E2R2.
The retained UTF-8 log is ignored evidence and is never a tracked artifact.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9A-Fa-f]{40}$')]
    [string]$ExpectedHead,
    [string]$GodotBin
)

$ErrorActionPreference = 'Stop'
$script:Failures = 0
$script:LogPath = $null
$script:TempRoot = $null
$script:Backup = $null
$script:Fingerprint = @()
$script:PreparationState = 'PreparationNotStarted'
$script:BackupState = 'NotCreated'
$script:OriginalRemovedForFreshState = $false
$script:RestorationVerified = $false
$script:RecoveryBackupRetained = $false
$script:CleanWorktree = $false
$script:StatusBaseline = ''
$script:IgnoredBaseline = @()
$script:ArtifactBaseline = @()
$script:Stage = @{ full='FAIL'; focused='FAIL'; import='FAIL'; trace='FAIL'; smoke='FAIL'; diff='FAIL'; cleanup='FAIL'; absence='FAIL'; audit='FAIL' }
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$Logs = Join-Path $Root 'tools\test\owner\logs'

# This deliberately occurs before the log, temporary root, backup, or Godot.
$ActualHead = (& git -C $Root rev-parse --verify HEAD 2>$null).Trim()
if ($LASTEXITCODE -ne 0 -or $ActualHead -notmatch '^[0-9A-Fa-f]{40}$') { throw "Exact-head validation failed; expected $ExpectedHead, actual $ActualHead." }
if (-not $ActualHead.Equals($ExpectedHead, [StringComparison]::OrdinalIgnoreCase)) { throw "Exact-head validation failed; expected $ExpectedHead, actual $ActualHead." }

function Log([string]$Text) {
    $line = '[{0:O}] {1}' -f [DateTime]::UtcNow, $Text
    Write-Host $line
    if ($script:LogPath) { Add-Content -LiteralPath $script:LogPath -Encoding UTF8 -Value $line }
}
function Fail([string]$Text) { $script:Failures++; Log "FAIL $Text" }
function Lines([object[]]$Value) { return (@($Value) -join [Environment]::NewLine) }
function Get-Godot {
    if ($GodotBin) { return $GodotBin }
    if ($env:GODOT_BIN) { return $env:GODOT_BIN }
    foreach ($name in @('godot', 'godot4')) { $found = Get-Command $name -ErrorAction SilentlyContinue; if ($found) { return $found.Source } }
    throw 'Godot 4.7.x was not found. Pass -GodotBin, set GODOT_BIN, or add godot/godot4 to PATH.'
}
function Fingerprint([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return @() }
    $base = (Resolve-Path $Path).Path
    return @(Get-ChildItem -LiteralPath $base -Force -Recurse | Sort-Object FullName | ForEach-Object {
        $relative = $_.FullName.Substring($base.Length).TrimStart('\')
        if ($_.PSIsContainer) { "D|$relative" } else { "F|$relative|$($_.Length)|$((Get-FileHash $_.FullName -Algorithm SHA256).Hash)" }
    })
}
function Artifacts {
    return @(Get-ChildItem -LiteralPath $Root -Force -Recurse -ErrorAction SilentlyContinue | Where-Object {
        -not $_.PSIsContainer -and ($_.Name -ieq 'godot.log' -or $_.Name -ieq 'steam_appid.txt' -or $_.Extension -in @('.tmp','.temp','.trace','.cache','.uid') -or $_.Name -match '(?i)(trace.*(out|log)|temporary.*\.uid$)')
    } | ForEach-Object { $_.FullName.Substring($Root.Length).TrimStart('\') } | Sort-Object)
}
function Exact([string]$Output, [int]$Tests, [int]$Passing, [int]$Asserts) {
    return [regex]::Matches($Output, "(?im)^\s*Tests(?:\s*:\s*|\s+)$Tests\s*$").Count -eq 1 -and [regex]::Matches($Output, "(?im)^\s*Passing tests(?:\s*:\s*|\s+)$Passing\s*$").Count -eq 1 -and [regex]::Matches($Output, "(?im)^\s*(?:Assertions|Asserts)(?:\s*:\s*|\s+)$Asserts\s*$").Count -eq 1
}
function Trace([string]$Output) {
    $markers = @('apply','retention','pruning','no_op','reads','settlement','continuity','equivalence','overflow','exclusion','complete')
    foreach ($marker in $markers) { if ([regex]::Matches($Output, "(?m)^TRACE M04E2R2 $marker=PASS\r?$").Count -ne 1) { return $false } }
    return [regex]::Matches($Output, '(?m)^TRACE M04E2R2 .*=FAIL\r?$').Count -eq 0
}
function Run([string]$Name, [string]$Exe, [string[]]$CommandArgs, [scriptblock]$Validator) {
    # Keep the received lines in a mutable list so the streaming pipeline and
    # the validator use the same complete output, without delaying log output.
    $output = [System.Collections.Generic.List[string]]::new()
    $nativeExitRecorded = $false
    $validatorRecorded = $false
    $stageRecorded = $false
    $failureRecorded = $false
    try {
        Log "COMMAND ${Name}: $Exe $($CommandArgs -join ' ')"
        & $Exe @CommandArgs 2>&1 | ForEach-Object {
            $line = $_.ToString()
            [void]$output.Add($line)
            Log "OUTPUT ${Name}: $line"
        }
        $code = $LASTEXITCODE
        $nativeExitRecorded = $true
        Log "NATIVE EXIT ${Name}: $code"

        $ok = $code -eq 0
        if ($Validator) {
            try {
                if ($ok) { $ok = & $Validator (Lines $output.ToArray()) }
                Log "VALIDATOR ${Name}: $(if ($ok) {'PASS'} else {'FAIL'})"
            } catch {
                $ok = $false
                Log "VALIDATOR ${Name}: $($_.Exception.Message)"
            }
        } else {
            Log "VALIDATOR ${Name}: NOT REQUIRED"
        }
        $validatorRecorded = $true

        if ($ok) {
            $script:Stage[$Name] = 'PASS'
            Log "PASS $Name"
        } else {
            Fail "$Name (native exit $code)"
            $failureRecorded = $true
        }
        $stageRecorded = $true
    } catch {
        if (-not $nativeExitRecorded) { Log "NATIVE EXIT ${Name}: UNRECORDED (interrupted before child completion)" }
        if (-not $validatorRecorded) { Log "VALIDATOR ${Name}: UNRECORDED (interrupted before validation)" }
        Fail "$Name (interrupted before completion: $($_.Exception.Message))"
        $failureRecorded = $true
    } finally {
        if (-not $stageRecorded) {
            $script:Stage[$Name] = 'FAIL'
            Log "STAGE ${Name}: FAIL (incomplete command accounting)"
        }
        if (-not $failureRecorded -and -not $stageRecorded) {
            Fail "$Name (incomplete command accounting)"
        }
    }
}
function Retain-RecoveryBackup([string]$Reason) {
    if ($script:Backup -and (Test-Path -LiteralPath $script:Backup)) {
        $script:RecoveryBackupRetained = $true
        $script:BackupState = 'RecoveryBackupRetainedAfterFailure'
        Log "RECOVERY BACKUP RETAINED: $script:Backup"
        Log "RECOVERY ROOT RETAINED: $script:TempRoot"
        Log "RECOVERY REASON: $Reason"
    }
}
function Cleanup {
    try {
        $godot = Join-Path $Root '.godot'
        if ($script:PreparationState -eq 'PreparationNotStarted') {
            Log 'Cleanup cache action: fresh-state preparation did not begin; pre-existing state was not altered.'
        } elseif ($script:PreparationState -eq 'OriginalAbsent') {
            if (Test-Path -LiteralPath $godot) { Remove-Item -LiteralPath $godot -Recurse -Force }
            if (Test-Path -LiteralPath $godot) { throw 'Generated .godot remains.' }
        } elseif ($script:BackupState -eq 'VerifiedIndependentBackupCreated' -or $script:BackupState -eq 'RecoveryBackupRetainedAfterFailure') {
            $currentMatchesOriginal = (Test-Path -LiteralPath $godot) -and ((Lines (Fingerprint $godot)) -eq (Lines $script:Fingerprint))
            if (-not $currentMatchesOriginal) {
                if (Test-Path -LiteralPath $godot) { Remove-Item -LiteralPath $godot -Recurse -Force }
                if (Test-Path -LiteralPath $godot) { throw 'Unable to remove incomplete fresh .godot state before recovery.' }
                Copy-Item -LiteralPath $script:Backup -Destination $godot -Recurse -Force
                if ((Lines (Fingerprint $godot)) -ne (Lines $script:Fingerprint)) { throw '.godot restoration fingerprint mismatch.' }
            }
            $script:RestorationVerified = $true
            Log 'Pre-existing .godot restoration verified exactly.'
            if ($script:Failures -gt 0) {
                Retain-RecoveryBackup 'Preparation or package execution failed after an independent backup was verified.'
                throw 'Verified recovery backup retained after a preparation or package execution failure.'
            }
            Remove-Item -LiteralPath $script:Backup -Recurse -Force
            if (Test-Path -LiteralPath $script:Backup) { throw 'Verified .godot backup remains after successful restoration.' }
            $script:Backup = $null
            $script:BackupState = 'RemovedAfterVerifiedRestoration'
        }
        Log 'Cleanup result: PASS'; $script:Stage.cleanup = 'PASS'
    } catch {
        Retain-RecoveryBackup $_.Exception.Message
        Fail "cleanup: $($_.Exception.Message)"
        Log 'Cleanup result: FAIL'
    }
}

New-Item -ItemType Directory -Force -Path $Logs | Out-Null
$script:LogPath = Join-Path $Logs ('M04E2R2-{0:yyyyMMddTHHmmssZ}-{1}.log' -f [DateTime]::UtcNow, $ActualHead.Substring(0,12))
New-Item -ItemType File -Force -Path $script:LogPath | Out-Null
try {
    $git = (Get-Command git -ErrorAction Stop).Source
    $relativeLog = $script:LogPath.Substring($Root.Length).TrimStart('\')
    $script:StatusBaseline = Lines @(git -C $Root status --porcelain=v1)
    $script:IgnoredBaseline = @(git -C $Root ls-files --others --ignored --exclude-standard | Where-Object { $_ -ne $relativeLog } | Sort-Object)
    $script:ArtifactBaseline = @(Artifacts)
    Log 'Milestone or slice: M04E2R2'; Log "UTC start: $([DateTime]::UtcNow.ToString('O'))"; Log "Repository root: $Root"; Log "Requested SHA: $ExpectedHead"; Log "Detected SHA: $ActualHead"; Log 'Exact-head validation: PASS'; Log "Windows version: $([Environment]::OSVersion.VersionString)"; Log "PowerShell version: $($PSVersionTable.PSVersion)"
    if ($script:StatusBaseline -ne '') {
        Fail 'clean-worktree: ordinary tracked worktree must be clean before package execution.'
        Log "Clean-worktree result: FAIL`n$($script:StatusBaseline)"
    } else {
        $script:CleanWorktree = $true
        Log 'Clean-worktree result: PASS'
    }
    $Godot = $null
    if ($script:CleanWorktree) {
        try {
            $Godot = Get-Godot; Log "Godot executable: $Godot"
            if (-not (Test-Path $Godot)) { throw "Godot executable does not exist: $Godot" }
            $versionOutput = @(& $Godot --version 2>&1); $versionExit = $LASTEXITCODE; $version = $versionOutput -join [Environment]::NewLine
            Log "COMMAND godot-version: $Godot --version"; Log "NATIVE EXIT godot-version: $versionExit"; foreach ($line in $versionOutput) { Log "OUTPUT godot-version: $($line.ToString())" }
            if ($versionExit -ne 0 -or $version -notmatch '^4\.7(\.|-|$)') { Log 'FAIL godot-version'; throw "Godot 4.7.x is required; detected: $version" }
            Log 'PASS godot-version'; Log "Godot version: $version"
        } catch { Log "Godot executable: $Godot"; Log 'Godot version: UNAVAILABLE'; Fail "godot-resolution: $($_.Exception.Message)"; $Godot = $null }
    }
    if ($Godot -and $script:CleanWorktree) {
        $script:TempRoot = Join-Path ([IO.Path]::GetTempPath()) ('m04e2r2-owner-' + [guid]::NewGuid().ToString('N')); New-Item -ItemType Directory -Force -Path $script:TempRoot | Out-Null
        $cache = Join-Path $Root '.godot'
        $script:PreparationState = 'PreparationStarted'
        if (Test-Path -LiteralPath $cache) {
            $script:Fingerprint = @(Fingerprint $cache)
            $script:Backup = Join-Path $script:TempRoot 'original-godot'
            Copy-Item -LiteralPath $cache -Destination $script:Backup -Recurse -Force
            if ((Lines (Fingerprint $script:Backup)) -ne (Lines $script:Fingerprint)) { throw 'Independent .godot backup fingerprint mismatch.' }
            $script:BackupState = 'VerifiedIndependentBackupCreated'
            Log 'Pre-existing .godot fingerprinted and independently backed up; verified independent backup created.'
            Remove-Item -LiteralPath $cache -Recurse -Force
            if (Test-Path -LiteralPath $cache) { throw 'Unable to remove pre-existing .godot directory for fresh-state preparation.' }
            $script:OriginalRemovedForFreshState = $true
            $script:PreparationState = 'OriginalRemovedForFreshState'
            Log 'Pre-existing .godot removed for fresh-state preparation.'
        } else {
            $script:PreparationState = 'OriginalAbsent'
            Log 'No pre-existing .godot directory was present.'
        }
        $ps = (Get-Command powershell.exe -ErrorAction Stop).Source; $wrapper = Join-Path $Root 'tools\test\run_gut.ps1'
        Run 'full' $ps @('-NoProfile','-ExecutionPolicy','Bypass','-File',$wrapper,'-GodotBin',$Godot) { param($out) Exact $out 208 208 5807 }
        $suite = @('tests/unit/m04e2r1/test_report_ledger.gd','tests/unit/m04e2r1/test_report_ledger_ingestion.gd','tests/unit/m04e2r1/test_report_ledger_interval_matrix.gd','tests/integration/m04e2r1/test_report_ledger_persistence_exclusion.gd','tests/unit/m04e2r2/test_report_ledger_r2_state.gd','tests/unit/m04e2r2/test_report_ledger_snapshot.gd','tests/unit/m04e2r2/test_report_ledger_reads.gd','tests/integration/m04e2r2/test_report_ledger_rollover_ingestion.gd','tests/integration/m04e2r2/test_report_ledger_persistence_exclusion.gd')
        $env:M04E2R2_OWNER_WRAPPER = $wrapper; $env:M04E2R2_OWNER_GODOT = $Godot
        $focus = '& $env:M04E2R2_OWNER_WRAPPER -GodotBin $env:M04E2R2_OWNER_GODOT -GutArgs @(' + (($suite | ForEach-Object { "'-gtest=res://$_'" }) -join ',') + ')'
        Run 'focused' $ps @('-NoProfile','-ExecutionPolicy','Bypass','-Command',$focus) { param($out) Exact $out 30 30 2975 }
        Run 'import' $Godot @('--headless','--path',$Root,'--import') $null
        Run 'trace' $Godot @('--headless','--path',$Root,'-s','res://tools/test/m04e2r2/m04e2r2_report_history_trace.gd') { param($out) Trace $out }
        Run 'smoke' $Godot @('--headless','--path',$Root,'--quit-after','5') $null
        Run 'diff' $git @('-C',$Root,'diff','--check') $null
    } elseif ($script:CleanWorktree) { foreach ($name in @('full','focused','import','trace','smoke','diff')) { Log "STAGE ${name}: NOT RUN (Godot validation failed)"; Fail "$name (Godot validation failed)" } } else { foreach ($name in @('full','focused','import','trace','smoke','diff')) { Log "STAGE ${name}: NOT RUN (clean-worktree validation failed)"; Fail "$name (clean-worktree validation failed)" } }
} catch { Fail "verification setup: $($_.Exception.Message)" }
finally {
    Cleanup
    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot) -and -not $script:RecoveryBackupRetained) { try { Remove-Item -LiteralPath $script:TempRoot -Recurse -Force } catch { Fail "temporary-root removal: $($_.Exception.Message)" } }
    try { if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) { throw 'Runner temporary root remains.' }; if ($script:Backup -and (Test-Path -LiteralPath $script:Backup)) { throw 'Runner backup remains.' }; $script:Stage.absence = 'PASS'; Log 'Cleanup absence proof: PASS' } catch { Fail "cleanup absence proof: $($_.Exception.Message)"; Log 'Cleanup absence proof: FAIL' }
    try {
        $relativeLog = $script:LogPath.Substring($Root.Length).TrimStart('\')
        if ((Lines @(git -C $Root status --porcelain=v1)) -ne '') { throw 'Ordinary repository status is not clean.' }
        if ((Lines @(git -C $Root ls-files --others --ignored --exclude-standard | Where-Object { $_ -ne $relativeLog } | Sort-Object)) -ne (Lines $script:IgnoredBaseline)) { throw 'Ignored artifacts differ outside retained log.' }
        if ((Lines (Artifacts)) -ne (Lines $script:ArtifactBaseline)) { throw 'Generated artifact remains.' }
        & git -C $Root check-ignore -q -- $relativeLog; if ($LASTEXITCODE -ne 0) { throw 'Retained owner log is not ignored.' }
        if (@(git -C $Root ls-files -- $relativeLog).Count -ne 0) { throw 'Retained owner log is tracked.' }
        $script:Stage.audit = 'PASS'; Log 'Artifact audit: PASS'
    } catch { Fail "artifact audit: $($_.Exception.Message)"; Log 'Artifact audit: FAIL' }
    $pass = $script:Failures -eq 0 -and @($script:Stage.Values | Where-Object { $_ -ne 'PASS' }).Count -eq 0
    Log "UTC end: $([DateTime]::UtcNow.ToString('O'))"; Log "Full GUT: Tests 208; Passing tests 208; Assertions/Asserts 5807 ($($script:Stage.full))"; Log "Focused R1/R2: Tests 30; Passing tests 30; Assertions/Asserts 2975 ($($script:Stage.focused))"; Log "Import result: $($script:Stage.import)"; Log "Trace-marker result: $($script:Stage.trace)"; Log "Main-scene smoke result: $($script:Stage.smoke)"; Log "Diff-check result: $($script:Stage.diff)"; Log "Cleanup result: $($script:Stage.cleanup)"; Log "Cleanup-absence result: $($script:Stage.absence)"; Log "Artifact-audit result: $($script:Stage.audit)"; Log "Automated result: $(if ($pass) {'PASS'} else {'FAIL'})"; Log "Failed step count: $script:Failures"; Log 'Pending interactive checks: None'; Log "Retained log path: $script:LogPath"; Write-Host "RETAINED OWNER LOG: $script:LogPath"
    if (-not $pass) { exit 1 }
}
exit 0
