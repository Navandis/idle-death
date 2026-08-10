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
$script:GodotState = 'NotStarted'
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
function Run([string]$Name, [string]$Exe, [string[]]$Args, [scriptblock]$Validator) {
    Log "COMMAND ${Name}: $Exe $($Args -join ' ')"
    $output = @(& $Exe @Args 2>&1); $code = $LASTEXITCODE
    Log "NATIVE EXIT ${Name}: $code"; foreach ($line in $output) { Log "OUTPUT ${Name}: $($line.ToString())" }
    $ok = $code -eq 0
    if ($ok -and $Validator) { try { $ok = & $Validator (Lines $output) } catch { $ok = $false; Log "VALIDATOR ${Name}: $($_.Exception.Message)" } }
    if ($ok) { $script:Stage[$Name] = 'PASS'; Log "PASS $Name" } else { Fail "$Name (native exit $code)" }
}
function Cleanup {
    try {
        $godot = Join-Path $Root '.godot'
        if ($script:GodotState -eq 'NotStarted') { Log 'Cleanup cache action: fresh-state preparation did not begin; pre-existing state was not altered.' }
        elseif ($script:GodotState -eq 'Absent') { if (Test-Path $godot) { Remove-Item $godot -Recurse -Force }; if (Test-Path $godot) { throw 'Generated .godot remains.' } }
        elseif ($script:GodotState -eq 'BackedUp') {
            if (Test-Path $godot) { Remove-Item $godot -Recurse -Force }
            Copy-Item $script:Backup $godot -Recurse -Force
            if ((Lines (Fingerprint $godot)) -ne (Lines $script:Fingerprint)) { throw '.godot restoration fingerprint mismatch.' }
            Remove-Item $script:Backup -Recurse -Force; $script:Backup = $null
        }
        Log 'Cleanup result: PASS'; $script:Stage.cleanup = 'PASS'
    } catch { Fail "cleanup: $($_.Exception.Message)"; Log 'Cleanup result: FAIL' }
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
    $Godot = $null
    try {
        $Godot = Get-Godot; Log "Godot executable: $Godot"
        if (-not (Test-Path $Godot)) { throw "Godot executable does not exist: $Godot" }
        $versionOutput = @(& $Godot --version 2>&1); $versionExit = $LASTEXITCODE; $version = $versionOutput -join [Environment]::NewLine
        Log "COMMAND godot-version: $Godot --version"; Log "NATIVE EXIT godot-version: $versionExit"; foreach ($line in $versionOutput) { Log "OUTPUT godot-version: $($line.ToString())" }
        if ($versionExit -ne 0 -or $version -notmatch '^4\.7(\.|-|$)') { Log 'FAIL godot-version'; throw "Godot 4.7.x is required; detected: $version" }
        Log 'PASS godot-version'; Log "Godot version: $version"
    } catch { Log "Godot executable: $Godot"; Log 'Godot version: UNAVAILABLE'; Fail "godot-resolution: $($_.Exception.Message)"; $Godot = $null }
    if ($Godot) {
        $script:TempRoot = Join-Path ([IO.Path]::GetTempPath()) ('m04e2r2-owner-' + [guid]::NewGuid().ToString('N')); New-Item -ItemType Directory -Force -Path $script:TempRoot | Out-Null
        $cache = Join-Path $Root '.godot'
        if (Test-Path $cache) { $script:Fingerprint = @(Fingerprint $cache); $script:Backup = Join-Path $script:TempRoot 'original-godot'; Copy-Item $cache $script:Backup -Recurse -Force; if ((Lines (Fingerprint $script:Backup)) -ne (Lines $script:Fingerprint)) { throw 'Independent .godot backup fingerprint mismatch.' }; Remove-Item $cache -Recurse -Force; $script:GodotState = 'BackedUp'; Log 'Pre-existing .godot fingerprinted and independently backed up.' } else { $script:GodotState = 'Absent'; Log 'No pre-existing .godot directory was present.' }
        $ps = (Get-Command powershell.exe -ErrorAction Stop).Source; $wrapper = Join-Path $Root 'tools\test\run_gut.ps1'
        Run 'full' $ps @('-NoProfile','-ExecutionPolicy','Bypass','-File',$wrapper,'-GodotBin',$Godot) { param($out) Exact $out 207 207 5752 }
        $suite = @('tests/unit/m04e2r1/test_report_ledger.gd','tests/unit/m04e2r1/test_report_ledger_ingestion.gd','tests/unit/m04e2r1/test_report_ledger_interval_matrix.gd','tests/integration/m04e2r1/test_report_ledger_persistence_exclusion.gd','tests/unit/m04e2r2/test_report_ledger_r2_state.gd','tests/unit/m04e2r2/test_report_ledger_snapshot.gd','tests/unit/m04e2r2/test_report_ledger_reads.gd','tests/integration/m04e2r2/test_report_ledger_rollover_ingestion.gd','tests/integration/m04e2r2/test_report_ledger_persistence_exclusion.gd')
        $env:M04E2R2_OWNER_WRAPPER = $wrapper; $env:M04E2R2_OWNER_GODOT = $Godot
        $focus = '& $env:M04E2R2_OWNER_WRAPPER -GodotBin $env:M04E2R2_OWNER_GODOT -GutArgs @(' + (($suite | ForEach-Object { "'-gtest=res://$_'" }) -join ',') + ')'
        Run 'focused' $ps @('-NoProfile','-ExecutionPolicy','Bypass','-Command',$focus) { param($out) Exact $out 29 29 2920 }
        Run 'import' $Godot @('--headless','--path',$Root,'--import') $null
        Run 'trace' $Godot @('--headless','--path',$Root,'-s','res://tools/test/m04e2r2/m04e2r2_report_history_trace.gd') { param($out) Trace $out }
        Run 'smoke' $Godot @('--headless','--path',$Root,'--quit-after','5') $null
        Run 'diff' $git @('-C',$Root,'diff','--check') $null
    } else { foreach ($name in @('full','focused','import','trace','smoke','diff')) { Log "STAGE ${name}: NOT RUN (Godot validation failed)"; Fail "$name (Godot validation failed)" } }
} catch { Fail "verification setup: $($_.Exception.Message)" }
finally {
    Cleanup
    if ($script:TempRoot -and (Test-Path $script:TempRoot)) { try { Remove-Item $script:TempRoot -Recurse -Force } catch { Fail "temporary-root removal: $($_.Exception.Message)" } }
    try { if ($script:TempRoot -and (Test-Path $script:TempRoot)) { throw 'Runner temporary root remains.' }; if ($script:Backup -and (Test-Path $script:Backup)) { throw 'Runner backup remains.' }; $script:Stage.absence = 'PASS'; Log 'Cleanup absence proof: PASS' } catch { Fail "cleanup absence proof: $($_.Exception.Message)"; Log 'Cleanup absence proof: FAIL' }
    try {
        $relativeLog = $script:LogPath.Substring($Root.Length).TrimStart('\')
        if ((Lines @(git -C $Root status --porcelain=v1)) -ne $script:StatusBaseline) { throw 'Ordinary repository status differs from baseline.' }
        if ((Lines @(git -C $Root ls-files --others --ignored --exclude-standard | Where-Object { $_ -ne $relativeLog } | Sort-Object)) -ne (Lines $script:IgnoredBaseline)) { throw 'Ignored artifacts differ outside retained log.' }
        if ((Lines (Artifacts)) -ne (Lines $script:ArtifactBaseline)) { throw 'Generated artifact remains.' }
        & git -C $Root check-ignore -q -- $relativeLog; if ($LASTEXITCODE -ne 0) { throw 'Retained owner log is not ignored.' }
        if (@(git -C $Root ls-files -- $relativeLog).Count -ne 0) { throw 'Retained owner log is tracked.' }
        $script:Stage.audit = 'PASS'; Log 'Artifact audit: PASS'
    } catch { Fail "artifact audit: $($_.Exception.Message)"; Log 'Artifact audit: FAIL' }
    $pass = $script:Failures -eq 0 -and @($script:Stage.Values | Where-Object { $_ -ne 'PASS' }).Count -eq 0
    Log "UTC end: $([DateTime]::UtcNow.ToString('O'))"; Log "Full GUT: Tests 207; Passing tests 207; Assertions/Asserts 5752 ($($script:Stage.full))"; Log "Focused R1/R2: Tests 29; Passing tests 29; Assertions/Asserts 2920 ($($script:Stage.focused))"; Log "Import result: $($script:Stage.import)"; Log "Trace-marker result: $($script:Stage.trace)"; Log "Main-scene smoke result: $($script:Stage.smoke)"; Log "Diff-check result: $($script:Stage.diff)"; Log "Cleanup result: $($script:Stage.cleanup)"; Log "Cleanup-absence result: $($script:Stage.absence)"; Log "Artifact-audit result: $($script:Stage.audit)"; Log "Automated result: $(if ($pass) {'PASS'} else {'FAIL'})"; Log "Failed step count: $script:Failures"; Log 'Pending interactive checks: None'; Log "Retained log path: $script:LogPath"; Write-Host "RETAINED OWNER LOG: $script:LogPath"
    if (-not $pass) { exit 1 }
}
exit 0
