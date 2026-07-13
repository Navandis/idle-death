<#
Canonical Windows entry point for Death Idle's Godot/GUT test suite.
It validates Godot before importing so setup problems fail with actionable
messages instead of being mistaken for project or GUT failures.
#>
[CmdletBinding()]
param(
    [string]$GodotBin,
    [string[]]$GutArgs = @()
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
$RepoRoot = Resolve-Path (Join-Path $ScriptDir '..\..')

function Resolve-GodotBinary {
    if ($GodotBin) { return $GodotBin }
    if ($env:GODOT_BIN) { return $env:GODOT_BIN }
    $fromPath = Get-Command godot -ErrorAction SilentlyContinue
    if ($fromPath) { return $fromPath.Source }
    $fromPath = Get-Command godot4 -ErrorAction SilentlyContinue
    if ($fromPath) { return $fromPath.Source }
    throw 'Godot 4.7.x was not found. Set -GodotBin, GODOT_BIN, or add godot/godot4 to PATH.'
}

$GodotPath = Resolve-GodotBinary
if (-not (Test-Path -LiteralPath $GodotPath)) {
    throw "Godot executable does not exist: $GodotPath"
}

$VersionOutput = (& $GodotPath --version 2>&1) -join "`n"
if ($LASTEXITCODE -ne 0) {
    throw "Could not run Godot --version with '$GodotPath'. Output: $VersionOutput"
}
if ($VersionOutput -notmatch '^4\.7(\.|-|$)') {
    throw "Death Idle requires Godot 4.7.x for M00 tests; detected: $VersionOutput"
}

Write-Host 'Death Idle test harness'
Write-Host "Repository root: $RepoRoot"
Write-Host "Godot executable: $GodotPath"
Write-Host "Godot version: $VersionOutput"

if ($GutArgs | Where-Object { $_ -like '-gtest*' }) {
    # GUT appends -gtest entries to configured directories. Clearing -gdir
    # keeps focused script runs focused while still loading shared config.
    $GutArgs = @('-gdir=') + $GutArgs
}

Push-Location $RepoRoot
try {
    & $GodotPath --headless --path $RepoRoot --import
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    & $GodotPath --headless --path $RepoRoot -s 'res://addons/gut/gut_cmdln.gd' '-gconfig=res://.gutconfig.json' @GutArgs
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
