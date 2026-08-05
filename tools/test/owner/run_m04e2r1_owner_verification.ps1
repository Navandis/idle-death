param(
	[Parameter(Mandatory = $true)][string]$ExpectedSha,
	[Parameter(Mandatory = $true)][string]$GodotBin
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Set-Location $root
$failed = 0
function Invoke-VerificationStep([string]$Name, [scriptblock]$Action) {
	try { & $Action; if ($LASTEXITCODE -ne 0) { throw "$Name exited $LASTEXITCODE" }; Write-Host "PASS $Name" }
	catch { $script:failed++; Write-Error "FAIL $Name: $_" }
}

if (!(Test-Path -LiteralPath $GodotBin)) { throw "Godot console executable was not found: $GodotBin" }
if ((git rev-parse HEAD).Trim() -ne $ExpectedSha) { throw 'Expected SHA does not match HEAD.' }
if (git status --porcelain=v1) { throw 'Working tree must be clean for exact-head verification.' }
Invoke-VerificationStep 'import' { & $GodotBin --headless --path $root --import }
Invoke-VerificationStep 'full-gut' { & $GodotBin --headless --path $root -s res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json }
Invoke-VerificationStep 'focused-r1' { & $GodotBin --headless --path $root -s res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gtest=res://tests/unit/m04e2r1/test_report_ledger.gd }
Invoke-VerificationStep 'trace' { & $GodotBin --headless --path $root -s res://tools/test/m04e2r1/m04e2r1_report_ledger_trace.gd }
Invoke-VerificationStep 'smoke' { & $GodotBin --headless --path $root --quit-after 5 }
Invoke-VerificationStep 'diff-check' { git diff --check }
Write-Host "M04E2R1 owner verification failed-step count: $failed"
if ($failed -ne 0) { exit 1 }
