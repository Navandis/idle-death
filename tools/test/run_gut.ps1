[CmdletBinding()]
param(
    [string]$GodotBin,
    [string[]]$GutArgs = @()
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $PSCommandPath
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..\..")

function Resolve-GodotBin {
    if ($GodotBin) { return $GodotBin }
    if ($env:GODOT_BIN) { return $env:GODOT_BIN }
    foreach ($Candidate in @("godot4.7", "godot47", "godot4", "godot")) {
        $Command = Get-Command $Candidate -ErrorAction SilentlyContinue
        if ($Command) { return $Command.Source }
    }
    return $null
}

$ResolvedGodot = Resolve-GodotBin
if (-not $ResolvedGodot) {
    Write-Error "Godot 4.7.x was not found. Pass -GodotBin <path>, set GODOT_BIN, or add godot4.7/godot4/godot to PATH."
    exit 127
}

$VersionOutput = & $ResolvedGodot --version 2>&1
$VersionStatus = $LASTEXITCODE
Write-Host "Godot executable: $ResolvedGodot"
Write-Host "Godot version: $VersionOutput"
if ($VersionStatus -ne 0) { exit $VersionStatus }
if ($VersionOutput -notmatch '^4\.7(\.|-|$)') {
    Write-Error "Expected Godot 4.7.x, got: $VersionOutput"
    exit 3
}

Write-Host "Importing project..."
& $ResolvedGodot --headless --path $RepoRoot --editor --quit
$ImportStatus = $LASTEXITCODE
if ($ImportStatus -ne 0) {
    Write-Error "Godot project import failed with exit code $ImportStatus"
    exit $ImportStatus
}

Write-Host "Running GUT..."
& $ResolvedGodot --headless --path $RepoRoot -s "res://addons/gut/gut_cmdln.gd" "-gconfig=res://.gutconfig.json" "-gexit" @GutArgs
$GutStatus = $LASTEXITCODE
Write-Host "GUT exit code: $GutStatus"
exit $GutStatus
