[CmdletBinding()]
param(
    [string]$GodotBin,
    [string[]]$GutArgs = @()
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $PSCommandPath
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..\..")

$ExitMissingGodot = 127
$ExitNotRunnable = 126
$ExitVersionProbeUnavailable = 124
$ExitVersionProbeFailed = 125
$ExitUnsupportedVersion = 3

function Fail {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $true)][int]$Code
    )

    [Console]::Error.WriteLine("error: $Message")
    exit $Code
}

function Resolve-GodotBin {
    if ($GodotBin) { return $GodotBin }
    if ($env:GODOT_BIN) { return $env:GODOT_BIN }
    foreach ($Candidate in @("godot4.7", "godot47", "godot4", "godot")) {
        $Command = Get-Command $Candidate -ErrorAction SilentlyContinue
        if ($Command) { return $Command.Source }
    }
    return $null
}

function Get-ConsoleGodotBin {
    param([Parameter(Mandatory = $true)][string]$ResolvedPath)

    $Command = Get-Command $ResolvedPath -ErrorAction SilentlyContinue
    if ($Command) {
        $ResolvedPath = $Command.Source
    }

    if (-not (Test-Path -LiteralPath $ResolvedPath -PathType Leaf)) {
        Fail -Message "Resolved Godot executable is not a file: $ResolvedPath" -Code $ExitNotRunnable
    }

    $FileName = [System.IO.Path]::GetFileName($ResolvedPath)
    if ($FileName -match '_console\.exe$') {
        return $ResolvedPath
    }

    # Windows GUI Godot executables can return blank CLI output and no native
    # exit code. Prefer the sibling console executable so version/import/GUT
    # probes are observable and cannot be mistaken for success.
    if ($FileName -match '\.exe$') {
        $Directory = [System.IO.Path]::GetDirectoryName($ResolvedPath)
        $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($ResolvedPath)
        $ConsolePath = Join-Path $Directory "$($BaseName)_console.exe"
        if (Test-Path -LiteralPath $ConsolePath -PathType Leaf) {
            Write-Host "Using Godot console executable for command-line tests: $ConsolePath"
            return $ConsolePath
        }

        Fail -Message "Windows command-line tests require the Godot console executable. Pass -GodotBin <path-to>*_console.exe, set GODOT_BIN to the console executable, or place it on PATH. No sibling console executable was found for: $ResolvedPath" -Code $ExitNotRunnable
    }

    return $ResolvedPath
}

function Assert-NativeExitCodeAvailable {
    param(
        [object]$ExitCode,
        [string]$Context
    )

    if ($null -eq $ExitCode) {
        Fail -Message "$Context did not report a native process exit code. Use the Windows Godot *_console.exe executable; blank GUI-executable probes are wrapper failures, not passes." -Code $ExitVersionProbeUnavailable
    }
}

$ResolvedGodot = Resolve-GodotBin
if (-not $ResolvedGodot) {
    Fail -Message "Godot 4.7.x was not found. Pass -GodotBin <path-to>*_console.exe, set GODOT_BIN, or add the Godot console executable to PATH." -Code $ExitMissingGodot
}

$ResolvedGodot = Get-ConsoleGodotBin -ResolvedPath $ResolvedGodot

$VersionOutput = & $ResolvedGodot --version 2>&1
$VersionStatus = $LASTEXITCODE
Write-Host "Godot executable: $ResolvedGodot"
Assert-NativeExitCodeAvailable -ExitCode $VersionStatus -Context "Godot version probe"
$VersionText = ($VersionOutput | Out-String).Trim()
Write-Host "Godot version: $VersionText"
if ([string]::IsNullOrWhiteSpace($VersionText)) {
    Fail -Message "Godot version probe returned blank output. Use the Windows Godot *_console.exe executable; blank version output is a wrapper failure, not a pass." -Code $ExitVersionProbeUnavailable
}
if ([int]$VersionStatus -ne 0) {
    Fail -Message "Godot version probe failed with exit code $VersionStatus." -Code $ExitVersionProbeFailed
}
if ($VersionText -notmatch '^4\.7(\.|-|$)') {
    Fail -Message "Expected Godot 4.7.x, got: $VersionText" -Code $ExitUnsupportedVersion
}

Write-Host "Importing project..."
& $ResolvedGodot --headless --path $RepoRoot --editor --quit
$ImportStatus = $LASTEXITCODE
Assert-NativeExitCodeAvailable -ExitCode $ImportStatus -Context "Godot project import"
if ([int]$ImportStatus -ne 0) {
    Fail -Message "Godot project import failed with exit code $ImportStatus" -Code ([int]$ImportStatus)
}

Write-Host "Running GUT..."
& $ResolvedGodot --headless --path $RepoRoot -s "res://addons/gut/gut_cmdln.gd" "-gconfig=res://.gutconfig.json" "-gexit" @GutArgs
$GutStatus = $LASTEXITCODE
Assert-NativeExitCodeAvailable -ExitCode $GutStatus -Context "GUT run"
Write-Host "GUT exit code: $GutStatus"
exit ([int]$GutStatus)
