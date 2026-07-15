# Death Idle

Death Idle is a Godot 4.7, GDScript-only prototype for a 2D, UI-led idle and incremental management game.

## Prerequisites

- Godot 4.7.x standard build available either through:
  - `GODOT_BIN` environment variable;
  - `godot` or `godot4` on `PATH`; or
  - the wrapper's explicit Godot path argument.
- On Windows, command-line harness examples should resolve to the console executable, such as `Godot_v4.7-stable_win64_console.exe`. The normal GUI executable is for editor use and is not the documented harness path because it is less reliable for console output and exit-code capture.
- No Steam client, network access, or `steam_appid.txt` is required for the M00 harness.

## Run tests

Linux/Codex Cloud full suite:

```sh
./tools/test/run_gut.sh
```

Linux focused infrastructure test:

```sh
./tools/test/run_gut.sh -- -gtest=res://tests/unit/infrastructure/test_project_harness.gd
```

Linux from outside the repository:

```sh
repo_root="$(pwd)"; tmp_dir="$(mktemp -d)"; (cd "$tmp_dir" && "$repo_root/tools/test/run_gut.sh"); result=$?; rmdir "$tmp_dir"; exit $result
```

Linux with an explicit Godot binary:

```sh
./tools/test/run_gut.sh --godot-bin /path/to/godot
```

Windows PowerShell full suite:

```powershell
.\tools\test\run_gut.ps1
```

Windows focused infrastructure test:

```powershell
.\tools\test\run_gut.ps1 -GutArgs @('-gtest=res://tests/unit/infrastructure/test_project_harness.gd')
```

Windows from outside the repository:

```powershell
$repoRoot = (Get-Location).Path
Push-Location $env:TEMP
& "$repoRoot\tools\test\run_gut.ps1"
$result = $LASTEXITCODE
Pop-Location
exit $result
```

Windows with an explicit Godot binary:

```powershell
.\tools\test\run_gut.ps1 -GodotBin 'C:\Path\To\Godot_v4.7-stable_win64_console.exe'
```

## Main-scene smoke

The current smoke target is the configured temporary dry-run scene. It should start headlessly and exit automatically:

```sh
godot --headless --path . --quit-after 5
```

Use the same Godot executable that the wrapper prints. Do not commit local executable paths.

## Temporary failure-propagation check

Create a temporary failing file under `tests/unit/infrastructure/`, run a focused wrapper command against it, confirm the wrapper exits nonzero, delete the file, then rerun the full wrapper successfully. Do not commit the temporary failing test.

## Dependency and license notes

- GUT 9.7.1 is pinned under `addons/gut/`; its plugin metadata is `addons/gut/plugin.cfg` and license is `addons/gut/LICENSE.md`.
- GodotSteam 4.20 is pinned under `addons/godotsteam/`; its plugin metadata is `addons/godotsteam/plugin.cfg`, GDExtension manifest is `addons/godotsteam/godotsteam.gdextension`, and license is `addons/godotsteam/license.md`.

## Documentation map

- Architecture: `docs/codex/ARCHITECTURE.md`
- Implementation rules: `docs/codex/IMPLEMENTATION_RULES.md`
- Data/content contracts: `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`
- Testing and validation: `docs/codex/TESTING_AND_VALIDATION.md`
- Milestones: `docs/codex/MILESTONES.md`
- Prototype source of truth: `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md`
- Idle Fork source of truth: `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md`

## M01 deterministic foundation

The repository now includes a scene-independent M01 foundation for later simulation work:

- centralized fixed-point arithmetic in `src/domain/fixed_point.gd` with `1_000_000` subunits per whole fractional unit;
- a minimal `GameState` timeline in `src/domain/game_state.gd`;
- separate trusted-time accounting in `src/domain/time_authority_state.gd`;
- monotonic and trusted-time contracts under `src/platform/time/`;
- non-mutating trusted-time planning plus explicit commit in `src/simulation/time_reconciliation_service.gd`.

Focused M01 validation can be run with:

```sh
./tools/test/run_gut.sh -- -gtest=res://tests/unit/m01/test_fixed_point.gd -gtest=res://tests/unit/m01/test_time_authority.gd -gtest=res://tests/unit/m01/test_source_ownership.gd
```

## M02 persistence checks

The prototype persistence foundation writes the default development save set under `user://saves/` through `SaveFileSet`; tests and traces inject disposable roots and do not use the normal user save directory.

Focused persistence tests:

```bash
./tools/test/run_gut.sh -- -gdir=res://tests/unit/persistence -gdir=res://tests/integration/save_load
```

Headless real-file persistence trace:

```bash
godot --headless --path . -s res://tools/test/m02/m02_persistence_trace.gd -- --save-root /tmp/death-idle-m02-trace
```

Owner Windows filesystem verification:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
    -File .\tools\test\owner\run_m02_owner_verification.ps1 `
    -CommitSha "<PR_HEAD_SHA>"
```

The save format is recoverable and exact for the prototype schema; it is not encryption, DRM, anti-tamper, or a final commercial container.

## M03 content catalog

The prototype content catalog is rooted at `content/prototype_content_catalog.tres` and declares revision `prototype-content-r1` with explicit compatibility for `prototype-content-r1` and legacy foundation saves using `prototype-m02`. The root catalog references typed `.tres` resources explicitly; gameplay code should build `ContentRegistry` rather than scanning content directories or keying mechanics from display names.

Focused M03 checks:

```sh
./tools/test/run_gut.sh -- -gdir=res://tests/unit/content -gdir=res://tests/integration/content
godot --headless --path . -s res://tools/test/m03/m03_content_catalog_trace.gd
```
