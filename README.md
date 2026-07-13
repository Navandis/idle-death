# Death Idle

Death Idle is a Godot 4.7, GDScript-only 2D idle/incremental prototype. The current repository is prototype-first and uses the maintained docs under `docs/design/` and `docs/codex/` as implementation guidance.

## Prerequisites

- Godot 4.7.x available on `PATH`, through `GODOT_BIN`, or by passing an explicit wrapper argument.
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
.\tools\test\run_gut.ps1 -GodotBin "C:\Path\To\Godot.exe" -GutArgs "-gtest=res://tests/unit/infrastructure/test_project_harness.gd"
```

Both wrappers resolve the repository root from their own location, import the project headlessly, require Godot 4.7.x, run the checked-in GUT configuration, and return GUT's exit code.

## Documentation

Start with `AGENTS.md`, then read `docs/codex/MILESTONES.md`, `docs/codex/TESTING_AND_VALIDATION.md`, `docs/codex/ARCHITECTURE.md`, and the two source-of-truth files in `docs/design/` for implementation work.
