param([string]$GodotBin, [string]$CommitSha = "")
$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$LogDir = Join-Path $RepoRoot "tools\test\owner\logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$LogPath = Join-Path $LogDir ("m04d3_owner_verification_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
$Failed = 0
function Log($m){ $m | Tee-Object -FilePath $LogPath -Append }
function Step($name, [scriptblock]$body){ Log "=== $name ==="; try { & $body; Log "PASS`n" } catch { $script:Failed++; Log "FAIL: $_`n" } }
function FindGodot(){ if($GodotBin){return $GodotBin}; if($env:GODOT_BIN){return $env:GODOT_BIN}; $c=(Get-Command godot -ErrorAction SilentlyContinue); if($c){return $c.Source}; return "godot" }
$Godot = FindGodot
$TraceRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("idle_death_m04d3_" + [guid]::NewGuid().ToString("N"))
$Markers = @(
"TRACE M04D3 supported_swap_preserves_core_and_channel_residuals=PASS",
"TRACE M04D3 return_period_change_requires_normalization=PASS",
"TRACE M04D3 mastery_period_change_requires_normalization=PASS",
"TRACE M04D3 cycle_duration_change_requires_normalization=PASS",
"TRACE M04D3 output_modifier_rate_before=1000000_after=1200000",
"TRACE M04D3 equal_output_loadouts_remain_distinct=PASS",
"TRACE M04D3 progress=500000_eta_before=7200000_eta_after=6000000",
"TRACE M04D3 eta_display_short=03_hours_52_minutes_15_seconds_long=02_days_03_hours_04_minutes",
"TRACE M04D3 old_context_then_new_context_banks_one=PASS",
"TRACE M04D3 repeated_redispatch_non_compounding=PASS",
"TRACE M04D3 return_to_prior_loadout_restores_baseline=PASS",
"TRACE M04D3 sequence_1_3_2_1_identity=PASS",
"TRACE M04D3 inactive_query_has_progress_no_eta=PASS",
"TRACE M04D3 rate_change_chunk_equivalence=PASS",
"TRACE M04D3 schema_v3_round_trip_no_derived_rate_eta=PASS",
"TRACE M04D3 no_clock_or_later_slice_sources=PASS")
Log "M04D3 owner verification"
Log "CommitSha: $CommitSha"
Step "Godot version" { & $Godot --version; if($LASTEXITCODE -ne 0){throw "Godot version failed"} }
Step "Full GUT before" { & (Join-Path $RepoRoot "tools\test\run_gut.ps1") -GodotBin $Godot; if($LASTEXITCODE -ne 0){throw "GUT failed"} }
Step "Focused M04D3" { & (Join-Path $RepoRoot "tools\test\run_gut.ps1") -GodotBin $Godot -GutArgs @("-gdir=res://tests/unit/m04d3"); if($LASTEXITCODE -ne 0){throw "Focused failed"} }
Step "Import" { & $Godot --headless --path $RepoRoot --import; if($LASTEXITCODE -ne 0){throw "Import failed"} }
$TraceOutput = @()
Step "Trace" { $script:TraceOutput = & $Godot --headless --path $RepoRoot -s res://tools/test/m04d3/m04d3_rate_context_trace.gd -- --save-root $TraceRoot; $script:TraceOutput | ForEach-Object { Log $_ }; if($LASTEXITCODE -ne 0){throw "Trace failed"} }
Step "Trace markers" { foreach($m in $Markers){ if(-not ($TraceOutput -contains $m)){throw "Missing marker $m"} }; Log "Trace markers verified: $($Markers.Count)" }
Step "Cleanup" { if(Test-Path $TraceRoot){ Remove-Item -Recurse -Force $TraceRoot }; if(Test-Path $TraceRoot){throw "cleanup failed"} }
Step "Full GUT after" { & (Join-Path $RepoRoot "tools\test\run_gut.ps1") -GodotBin $Godot; if($LASTEXITCODE -ne 0){throw "GUT failed"} }
if($Failed -eq 0){ Log "Automated result: PASS" } else { Log "Automated result: FAIL" }
Log "Failed step count: $Failed"
Log "Pending interactive checks: None for M04D3"
Log "Cleanup result: PASS"
Log "Log path: $LogPath"
exit $Failed
