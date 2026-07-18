# Canonical owner-run Windows verification package for M04D2.
param([string]$GodotBin, [string]$CommitSha = "")
$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$LogDir = Join-Path $PSScriptRoot "logs"; New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$Start = (Get-Date).ToUniversalTime(); $SafeRef = if ([string]::IsNullOrWhiteSpace($CommitSha)) { "unknown-ref" } else { $CommitSha -replace '[^A-Za-z0-9_.-]', '-' }
$LogPath = Join-Path $LogDir "M04D2-owner-verification-$($Start.ToString('yyyyMMdd-HHmmssZ'))-$SafeRef.log"
$Failed = 0; $ExitCode = 0; $TraceRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("death-idle-m04d2-" + [System.Guid]::NewGuid().ToString("N"))
function Log([string]$Line) { Write-Host $Line; Add-Content -LiteralPath $LogPath -Encoding UTF8 -Value $Line }
function Fail([int]$Code) { $script:Failed += 1; if ($script:ExitCode -eq 0) { $script:ExitCode = $Code } }
function Resolve-Godot { if ($GodotBin) { return $GodotBin }; if ($env:GODOT_BIN) { return $env:GODOT_BIN }; $g=Get-Command godot -ErrorAction SilentlyContinue; if ($g) { return $g.Source }; $g=Get-Command godot4 -ErrorAction SilentlyContinue; if ($g) { return $g.Source }; return "unavailable" }
function RunStep([string]$Name, [scriptblock]$Block) { Log "=== $Name ==="; try { $out=& $Block 2>&1; foreach($l in $out){Log "$l"}; $code=$LASTEXITCODE } catch { Log "ERROR: $($_.Exception.Message)"; $code=1 }; if ($null -eq $code) { $code=0 }; Log "Exit code: $code"; if ($code -ne 0) { Log "FAILED: $Name"; Fail $code } else { Log "PASSED: $Name" }; Log "" }
$Godot = Resolve-Godot; Set-Location $RepoRoot; "" | Set-Content -LiteralPath $LogPath -Encoding UTF8
$Detected = "unavailable"; $git=Get-Command git -ErrorAction SilentlyContinue; if ($git) { $Detected = ((& git rev-parse HEAD 2>&1) -join "`n").Trim() }
Log "Milestone: M04D2"; Log "UTC start: $($Start.ToString('yyyy-MM-ddTHH:mm:ssZ'))"; Log "Repository root: $RepoRoot"; Log "Requested commit or PR head: $CommitSha"; Log "Detected Git commit, when available: $Detected"; Log "PowerShell version: $($PSVersionTable.PSVersion)"; Log "Godot executable: $Godot"; if ($Godot -ne "unavailable") { Log "Godot version: $((& $Godot --version 2>&1) -join '`n')" }; Log "Log path: $LogPath"; Log ""
if ($CommitSha -and $Detected -ne "unavailable" -and $Detected -ne $CommitSha) { Log "FAILED: checked-out commit does not match -CommitSha."; Fail 67 }
try {
  New-Item -ItemType Directory -Force -Path $TraceRoot | Out-Null
  $Wrapper = Join-Path $RepoRoot "tools\test\run_gut.ps1"
  RunStep "Full suite before" { & $Wrapper -GodotBin $Godot }
  RunStep "Focused M04D2" { & $Wrapper -GodotBin $Godot -GutArgs @('-gdir=res://tests/unit/m04d2','-gdir=res://tests/integration/m04d2') }
  RunStep "Import" { & $Godot --headless --path $RepoRoot --import }
  $TraceOutput = @()
  RunStep "M04D2 trace" { $script:TraceOutput = & $Godot --headless --path $RepoRoot -s res://tools/test/m04d2/m04d2_channel_accumulation_trace.gd -- --save-root $TraceRoot 2>&1; $script:TraceOutput }
  RunStep "Trace marker verification" { $markers=@('TRACE M04D2 content_revision=prototype-content-r2_non_essence_settled=1000000','TRACE M04D2 gloamwood_2h_soldier=24_scribe_progress=250000','TRACE M04D2 gloamwood_8h_soldier=96_scribe_banked=1','TRACE M04D2 broken_watch_6h_provisions=720_maa_progress=250000','TRACE M04D2 broken_watch_24h_provisions=2880_maa_banked=1','TRACE M04D2 locked_channel_no_production_or_creation=PASS','TRACE M04D2 late_unlock_no_backfill=PASS','TRACE M04D2 recall_freezes_redispatch_resumes=PASS','TRACE M04D2 settlement_channel_segmentation=PASS','TRACE M04D2 one_shot_equals_chunks=PASS','TRACE M04D2 banking_events_ordered=PASS','TRACE M04D2 schema_v3_round_trip=PASS','TRACE M04D2 no_duplicate_essence_or_reaping_progress=PASS','TRACE M04D2 no_clock_or_later_slice_sources=PASS'); foreach($m in $markers){ if(-not ($script:TraceOutput | Where-Object {$_ -eq $m})){ throw "Missing trace marker: $m" } }; Write-Output "Trace markers verified: 14" }
  RunStep "Full suite after" { & $Wrapper -GodotBin $Godot }
} finally {
  if (Test-Path -LiteralPath $TraceRoot) { Remove-Item -LiteralPath $TraceRoot -Recurse -Force -ErrorAction SilentlyContinue }
  if (Test-Path -LiteralPath $TraceRoot) { Log "Cleanup result: FAIL"; Fail 1 } else { Log "Cleanup result: PASS" }
}
Log ""; Log "Summary"; Log "Automated result: $(if($ExitCode -eq 0){'PASS'}else{'FAIL'})"; Log "Failed step count: $Failed"; Log "Pending interactive checks: None for M04D2"; Log "Cleanup result: $(if(Test-Path -LiteralPath $TraceRoot){'FAIL'}else{'PASS'})"; Log "Log path: $LogPath"; exit $ExitCode
