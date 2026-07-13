# Death Idle

Death Idle is a Godot 4.7, GDScript-only 2D idle/incremental prototype. The current repository is prototype-first and uses the maintained docs under `docs/design/` and `docs/codex/` as implementation guidance.

## Prerequisites

- Godot 4.7.x available on `PATH`, through `GODOT_BIN`, or by passing an explicit wrapper argument. On Windows, use the Godot console executable, for example `Godot_v4.7-stable_win64_console.exe`; if the wrapper receives the sibling GUI executable, it attempts to switch to the matching `_console.exe` and prints a notice.
- The pinned GUT 9.7.1 addon already committed under `addons/gut/`.
- The pinned GodotSteam 4.20 GDExtension already committed under `addons/godotsteam/`. M00 tests do not initialize Steam and do not require a Steam client, account, or `steam_appid.txt`.

## Repository map

- `project.godot` — Godot project settings and temporary main scene configuration.
- `test_main_scene.tscn` — current dry-run scene, not final application architecture.
- `addons/gut/` — pinned GUT 9.7.1 test dependency.
- `addons/godotsteam/` — pinned GodotSteam 4.20 dependency for later trusted-time work.
- `tests/` — GUT tests discovered by `.gutconfig.json`.
- `tools/test/` — platform wrappers for the shared GUT configuration.
- `docs/design/` — maintained design source-of-truth documents.
- `docs/codex/` — architecture, implementation, milestone, decision, and validation docs.

## Canonical test commands

Linux/Codex Cloud:

```bash
./tools/test/run_gut.sh
./tools/test/run_gut.sh --godot /path/to/godot -- -gtest=res://tests/unit/infrastructure/test_project_harness.gd
```

Windows PowerShell:

```powershell
.\tools\test\run_gut.ps1
.\tools\test\run_gut.ps1 -GodotBin "C:\Path\To\Godot_v4.7-stable_win64_console.exe" -GutArgs "-gtest=res://tests/unit/infrastructure/test_project_harness.gd"
```

Outside the repository root:

```powershell
$repo = Resolve-Path .
$tmp = New-Item -ItemType Directory -Path ([System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.Guid]::NewGuid().ToString()))
Push-Location $tmp.FullName
& "$repo\tools\test\run_gut.ps1" -GodotBin "C:\Path\To\Godot_v4.7-stable_win64_console.exe"
$exitCode = $LASTEXITCODE
Pop-Location
Remove-Item -Recurse -Force $tmp.FullName
exit $exitCode
```

Safe one-time failure propagation check:

```powershell
$tempTest = "tests/unit/infrastructure/test_temporary_failure.gd"
@'
extends GutTest

func test_temporary_failure() -> void:
	assert_true(false, "temporary failure propagation check")
'@ | Set-Content -NoNewline $tempTest
.\tools\test\run_gut.ps1 -GodotBin "C:\Path\To\Godot_v4.7-stable_win64_console.exe"
$failingExit = $LASTEXITCODE
Remove-Item $tempTest
.\tools\test\run_gut.ps1 -GodotBin "C:\Path\To\Godot_v4.7-stable_win64_console.exe"
$cleanExit = $LASTEXITCODE
if ($failingExit -eq 0 -or $cleanExit -ne 0) { exit 1 }
```

Both wrappers resolve the repository root from their own location, import the project headlessly, require Godot 4.7.x, run the checked-in GUT configuration, and return GUT's exit code. On Windows, blank version output is an explicit wrapper failure, not a passing result; use the console executable for command-line verification.

## Documentation

Start with `AGENTS.md`, then read `docs/codex/MILESTONES.md`, `docs/codex/TESTING_AND_VALIDATION.md`, `docs/codex/ARCHITECTURE.md`, and the two source-of-truth files in `docs/design/` for implementation work.
