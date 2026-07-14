param(
    [string]$GodotBin = $env:GODOT_BIN,
    [string]$CommitSha = ""
)
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..\..\..")
$LogDir = Join-Path $RepoRoot "tools\test\owner\logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$LogPath = Join-Path $LogDir "m02-owner-$Stamp.log"
$Failed = 0
function Log($Message) { $Message | Tee-Object -FilePath $LogPath -Append }
function Run-Step($Name, [scriptblock]$Block) {
    Log "STEP $Name"
    try { & $Block; $code = $LASTEXITCODE; if ($null -eq $code) { $code = 0 } } catch { Log "ERROR $_"; $code = 1 }
    Log "EXIT $Name $code"
    if ($code -ne 0) { $script:Failed += 1 }
}
if ([string]::IsNullOrWhiteSpace($GodotBin)) { $GodotBin = "godot" }
$TraceRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("death-idle-m02-" + [guid]::NewGuid().ToString("N"))
Log "M02 owner verification"
Log "RepoRoot=$RepoRoot"
Log "RequestedCommitSha=$CommitSha"
Log "PowerShell=$($PSVersionTable.PSVersion)"
Run-Step "Godot version" { & $GodotBin --version }
Run-Step "Full GUT before" { & (Join-Path $RepoRoot "tools\test\run_gut.ps1") -GodotBin $GodotBin }
Run-Step "Focused M02 GUT" { & (Join-Path $RepoRoot "tools\test\run_gut.ps1") -GodotBin $GodotBin -- -gdir=res://tests/unit/persistence -gdir=res://tests/integration/save_load }
Run-Step "Import preflight" { & $GodotBin --headless --path $RepoRoot --import }
Run-Step "M02 trace" { & $GodotBin --headless --path $RepoRoot -s res://tools/test/m02/m02_persistence_trace.gd -- --save-root $TraceRoot }
if (Test-Path $TraceRoot) { Remove-Item -Recurse -Force $TraceRoot }
if (Test-Path $TraceRoot) { Log "CLEANUP FAIL $TraceRoot"; $Failed += 1 } else { Log "CLEANUP PASS $TraceRoot" }
Run-Step "Full GUT after" { & (Join-Path $RepoRoot "tools\test\run_gut.ps1") -GodotBin $GodotBin }
Log "PendingInteractiveChecks=None for M02"
Log "FailedStepCount=$Failed"
if ($Failed -eq 0) { Log "RESULT PASS"; Log "LogPath=$LogPath"; exit 0 }
Log "RESULT FAIL"
Log "LogPath=$LogPath"
exit 1
