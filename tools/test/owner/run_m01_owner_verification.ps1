# Canonical owner-run Windows verification package for M01.
param(
    [string]$GodotBin = $env:GODOT_BIN
)

$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$LogDir = Join-Path $PSScriptRoot "logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$LogPath = Join-Path $LogDir "m01-owner-verification-$Stamp.log"
$ExitCode = 0

function Write-LogLine([string]$Line) {
    $Line | Tee-Object -FilePath $LogPath -Append
}

function Run-Step([string]$Name, [scriptblock]$Command) {
    Write-LogLine "=== $Name ==="
    & $Command 2>&1 | Tee-Object -FilePath $LogPath -Append
    if ($LASTEXITCODE -ne 0) {
        Write-LogLine "FAILED: $Name exited $LASTEXITCODE"
        $script:ExitCode = $LASTEXITCODE
    } else {
        Write-LogLine "PASSED: $Name"
    }
}

Set-Location $RepoRoot
Write-LogLine "Death Idle M01 owner verification"
Write-LogLine "Repository root: $RepoRoot"
Write-LogLine "Log path: $LogPath"

$Wrapper = Join-Path $RepoRoot "tools\test\run_gut.ps1"
$WrapperArgs = @()
if (-not [string]::IsNullOrWhiteSpace($GodotBin)) {
    $WrapperArgs += @("-GodotBin", $GodotBin)
}
$FocusedGutArgs = @(
    "-gtest=res://tests/unit/m01/test_fixed_point.gd",
    "-gtest=res://tests/unit/m01/test_time_authority.gd",
    "-gtest=res://tests/unit/m01/test_source_ownership.gd"
)

function Resolve-GodotForTrace {
    if (-not [string]::IsNullOrWhiteSpace($GodotBin)) { return $GodotBin }
    if (-not [string]::IsNullOrWhiteSpace($env:GODOT_BIN)) { return $env:GODOT_BIN }
    $FromPath = Get-Command godot -ErrorAction SilentlyContinue
    if ($FromPath) { return $FromPath.Source }
    $FromPath = Get-Command godot4 -ErrorAction SilentlyContinue
    if ($FromPath) { return $FromPath.Source }
    throw "Godot 4.7.x was not found for the M01 trace."
}

Run-Step "Full GUT suite" { & $Wrapper @WrapperArgs }
Run-Step "Focused M01 GUT suite" { & $Wrapper @WrapperArgs -GutArgs $FocusedGutArgs }
Run-Step "M01 deterministic trace" {
    $ResolvedGodot = Resolve-GodotForTrace
    & $ResolvedGodot --headless --path $RepoRoot -s res://tools/test/m01/m01_deterministic_trace.gd
}

Write-LogLine "M01 owner verification finished with exit code $ExitCode"
exit $ExitCode
