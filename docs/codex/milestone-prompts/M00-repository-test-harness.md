# Milestone M00: Repository, Godot, GUT, and Codex Cloud harness

**Prompt version:** v0.1  
**Prompt date:** 2026-07-13  
**Prompt status:** Draft  
**Milestone definition:** `docs/codex/MILESTONES.md` — `### M00 — Repository, Godot, GUT, and Codex Cloud harness`  
**Recommended task size:** Medium; one infrastructure pull request  
**Expected base branch or ref:** `main` after this approved prompt is committed; repository baseline was inspected at commit `749a3593073c39a7ddd0bc089e2b610ff6e28116`  
**Planned prompt path:** `docs/codex/milestone-prompts/M00-repository-test-harness.md`

> This prompt authorizes only the M00 infrastructure scope below. It does not authorize gameplay systems, Steam initialization, future milestones, dependency updates, broad cleanup, or silent changes to accepted design and architecture decisions.

## Execution protocol

Before editing:

1. Read `AGENTS.md` completely.
2. Read every document and section listed under **Authoritative context**.
3. Inspect the current repository, addon metadata, applicable license and notice files, `project.godot`, the configured main scene, existing tests, and `git status --short`.
4. Confirm the expected versions and settings in **Repository state**.
5. Confirm that a Godot 4.7.x executable is available in the Codex Cloud/Linux environment through an explicit path, `GODOT_BIN`, or `PATH`.
6. Briefly state the proposed implementation approach, expected files, wrapper interface, and verification plan before making non-trivial edits.
7. Report any material mismatch between this prompt and the repository before implementing dependent behavior.

During implementation:

- Limit changes to M00 and its acceptance criteria.
- Preserve unrelated work, existing assets, the temporary dry-run scene, project settings, and pinned addon files.
- Do not download, update, replace, or run an updater for GUT or GodotSteam.
- Do not initialize Steam, call Steamworks, or require a Steam client or account.
- Do not implement gameplay state, simulation, saves, content definitions, production UI, or later-milestone systems.
- Keep every command repository-relative and free of committed machine-specific paths.
- Add junior-readable comments to non-obvious project-owned scripts. Do not edit third-party addon source merely to conform it to project style.
- Add the minimum tests and documentation needed to establish the cross-platform harness.
- Run every Codex-executable check listed below and report exact commands and exit codes.
- Leave owner-run Windows and editor checks as `Pending owner verification` until the owner explicitly reports a result for the tested commit or branch.
- Do not create, rewrite, or broaden this prompt or any future milestone prompt.

Do not describe M00 as complete while any merge-gate criterion is failed, blocked, or pending. A pull request may be ready for owner testing with verification `Partial`, but it may not merge until the owner-run Windows gates explicitly pass.

## Objective

Establish one repeatable, repository-owned verification harness for Godot 4.7 and the pinned GUT 9.7.1 dependency. Codex Cloud/Linux and the project owner's separate Windows Godot machine must run the same checked-in test configuration through platform-appropriate wrapper scripts with reliable exit codes.

## Player or developer outcome

From a clean checkout:

- Codex can run one shell command to import the project, execute the full GUT suite, and obtain a trustworthy process result in its Linux environment.
- The project owner can run one PowerShell command to perform the equivalent Windows verification without installing Codex on the Godot machine.
- Both environments can run a focused test, locate the repository from outside its root directory, and diagnose missing or incorrect Godot versions clearly.
- The current dry-run main scene can be started headlessly as a smoke check without Steam initialization.

## Authoritative context

Read the following before editing.

| Priority | Source | Required sections, labels, or records | Why it applies |
|---:|---|---|---|
| 1 | `AGENTS.md` | Full file, especially **Technology, platform, and distribution**, **Repository map**, **Testing and validation**, **Scope, refactoring, and dependencies**, and **Required final response** | Repository-wide rules, pinned dependencies, split verification responsibility, and handoff format |
| 2 | `docs/codex/MILESTONES.md` | §5 **Decision and dependency gates**; §6 M00 status row; §9 `M00 — Repository, Godot, GUT, and Codex Cloud harness` | Approved scope, gates, acceptance, and non-goals |
| 3 | `docs/codex/PROMPT_TEMPLATE.md` | §2.1 **Prompt authorship boundary**; §2.2 **Owner verification evidence**; instantiated-prompt completion and evidence rules | Prompt ownership and owner-result semantics |
| 4 | `docs/codex/TESTING_AND_VALIDATION.md` | §§1–6; §12.1–12.2; §13; §§15–16; §18 | Planned wrapper contract, environments, commands, artifacts, and definition of validated |
| 5 | `docs/codex/IMPLEMENTATION_RULES.md` | §§2–5; §18 **Testing rules**; §19 **External dependencies**; §21 **Security and storefront boundaries**; §22 **Pull-request scope and review** | Project-owned code quality, dependency constraints, Steam boundary, and review expectations |
| 6 | `docs/codex/ARCHITECTURE.md` | §3 **Deliberate non-goals**; §6.4 **Test construction**; §23 **Test seams**; §24 **Intended source layout** | Confirms that M00 is infrastructure only and future tests must not require the gameplay scene tree |
| 7 | `docs/codex/DECISIONS.md` | `DEC-0006`, `DEC-0017`, `DEC-0023`, `DEC-0024` | Godot/platform boundary, pinned GUT, required wrappers, and GodotSteam/App ID configuration |
| 8 | `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md` | §14 **Technical and production boundaries**; §15 **Current prototype boundary** | Godot 4.7/GDScript direction and prototype scope discipline |
| 9 | `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md` | §3 **Global prototype safeguards**; §17 **Explicit non-goals and deferred hooks** | Determinism and prototype exclusions that the harness will later protect |
| 10 | `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | §1 **Purpose**; §20 **Change-control rule** | Confirms that M00 does not introduce content IDs, runtime schemas, or save contracts |

This prompt is the latest owner-approved task instruction only within M00. It does not supersede accepted decisions or protected design invariants. If applicable sources conflict and the documented hierarchy does not resolve the conflict, stop and report the conflict, practical consequence, and available options.

## Repository state

The expected baseline at task start is:

| Item | Expected state | Evidence or path to inspect |
|---|---|---|
| Required prior milestones | None; M00 is the first implementation milestone | `docs/codex/MILESTONES.md` |
| Godot project | Godot 4.7, GDScript, 1920 × 1080 reference viewport, Compatibility renderer | `project.godot` |
| Main scene | Temporary dry-run scene configured as the project main scene; it is not final `GameApp` architecture | `project.godot`, `test_main_scene.tscn` |
| GUT | Version 9.7.1 already committed; applicable license retained | `addons/gut/plugin.cfg`, `addons/gut/LICENSE.md`, `addons/gut/` |
| GodotSteam | GodotSteam GDExtension 4.20 already committed; updater/plugin metadata and native libraries present | `addons/godotsteam/` |
| Steam project settings | Development App ID `480`; automatic initialization disabled | `project.godot` `[steam]` section |
| Existing test harness | None approved | `.gutconfig.json`, `tools/test/`, and `tests/` should not yet exist except for unrelated repository facts discovered during inspection |
| README | Absent at the inspected baseline | `README.md` |
| Ignore rules | Minimal Godot ignores only | `.gitignore` |
| Gameplay systems | No production game state, simulation, persistence, content registry, or gameplay UI | Repository inspection |
| Working tree | Clean except for task changes | `git status --short` |

The repository baseline was inspected at commit `749a3593073c39a7ddd0bc089e2b610ff6e28116`. Re-check all facts at task start. If the repository is materially ahead of, behind, or inconsistent with this table, report the mismatch and do not overwrite newer work or recreate an existing harness.

## Dependencies

| Dependency or gate | Required state | Required before | How to verify |
|---|---|---|---|
| Godot executable in Codex Cloud/Linux | Godot 4.7.x available through explicit wrapper argument, `GODOT_BIN`, or `PATH` | Final Codex verification | Run the resolved executable with `--version`; wrapper must reject non-4.7 versions |
| GUT dependency | Pinned 9.7.1, no updater or test-time download | Implementation | Inspect `addons/gut/plugin.cfg`, CLI files, and license |
| GodotSteam dependency | Pinned 4.20, automatic initialization disabled, no live Steam use | Import and smoke verification | Inspect addon metadata, GDExtension files, notices, and `project.godot` |
| Windows Godot environment | Owner has Godot 4.7.x and can pull the branch | Merge | Explicit owner result for `tools/test/run_gut.ps1` and manual editor smoke flow |
| `GATE-GUT` | Linux and Windows wrappers, shared config, passing and failing exit behavior verified | Merge | Automated evidence plus explicit owner result |
| `GATE-WINDOWS-HARNESS` | Owner-run Windows verification explicitly passes | Merge | Owner message or pull-request comment naming commit/branch, checks, result, and date |

If Codex Cloud does not expose Godot 4.7.x and the task environment does not permit an approved setup step, report the environment blocker before claiming M00 verification. Do not commit a local executable path or weaken the version requirement.

## Scope

Implement only the following:

1. Inspect and document the committed GUT 9.7.1 and GodotSteam 4.20 dependency footprints, including exact metadata and applicable license/notice paths.
2. Add a minimal checked-in `.gutconfig.json` that discovers project tests under `res://tests`, includes subdirectories, uses stable test naming, and supports deterministic CLI exit behavior.
3. Add one small GUT infrastructure test file that proves test discovery and validates stable project configuration without invoking gameplay or Steam APIs.
4. Add `tools/test/run_gut.sh` for Codex Cloud/Linux.
5. Add `tools/test/run_gut.ps1` for the owner's Windows Godot machine.
6. Make both wrappers resolve the repository root from their own location, locate Godot through the approved precedence, require Godot 4.7.x, run the default import and full GUT suite, support focused GUT arguments, and propagate the real failing or successful process exit code.
7. Document the exact Linux, Windows, focused-test, outside-root, main-scene smoke, and one-time failure-propagation procedures.
8. Add or update only the ignore rules required for actual generated test output and logs observed during implementation. Do not ignore committed fixtures.
9. Create a concise root `README.md` with prerequisites, repository map, canonical test commands, Windows setup using `GODOT_BIN` or `PATH`, and links to maintained documentation.
10. Update `TESTING_AND_VALIDATION.md` and `MILESTONES.md` to describe the realized wrapper interface and the actual M00 implementation/verification state.

Use the smallest clear implementation. The wrappers are project-owned infrastructure; they should be readable to a junior developer and contain concise comments where platform behavior or exit-code handling is not obvious.

## Non-goals

Do not implement or refactor:

1. Authoritative game state, simulation, fixed-point arithmetic, trusted-time accounting, saves, migrations, content definitions, reports, forecasts, tutorial behavior, or gameplay UI.
2. The final `GameApp` root, navigation shell, or replacement of `test_main_scene.tscn`.
3. Steam initialization, `ISteamUser`, `ISteamUtils`, trusted-time calls, achievements, Steam Cloud, depots, networking, or any M06 behavior.
4. A committed `steam_appid.txt` or any change that makes Steam a prerequisite for import or tests.
5. GUT or GodotSteam updates, re-vendoring, automatic update checks, or another test framework/plugin.
6. GitHub Actions, self-hosted runners, a Codex skill, hooks, custom agents, or release automation.
7. Gameplay test fixtures or empty directory trees for future milestones.
8. Broad asset cleanup, file renaming, reformatting, renderer changes, engine-version changes, or unrelated project-setting edits.
9. Changes to `PROMPT_TEMPLATE.md`, this prompt, or any future milestone prompt during implementation.

## Required behavior

Every row is a binary requirement for this task.

| ID | Required behavior | Source trace |
|---|---|---|
| `RB-01` | The harness uses the already committed GUT 9.7.1 files and does not download, replace, or update them. | `DEC-0017`; M00 Included scope |
| `RB-02` | The repository documents exact GUT and GodotSteam version evidence and the applicable retained license/notice paths. | M00 Acceptance criteria; `IMPLEMENTATION_RULES.md` §19 |
| `RB-03` | Both wrappers derive the repository root from their own file location and work when invoked while the current directory is outside the repository. | `DEC-0023` |
| `RB-04` | Godot executable discovery order is: explicit wrapper argument, then `GODOT_BIN`, then documented command names on `PATH`. | `DEC-0023`; `TESTING_AND_VALIDATION.md` §3.2 |
| `RB-05` | Both wrappers print the resolved executable and version, accept only Godot 4.7.x, and fail clearly with a nonzero exit when Godot is missing or the version is unsupported. | `DEC-0023`; M00 Acceptance criteria |
| `RB-06` | The default wrapper invocation runs a headless project import before the full GUT suite and stops immediately if import fails. | M00 Included scope; `TESTING_AND_VALIDATION.md` §4.1 |
| `RB-07` | Both wrappers use the same checked-in `.gutconfig.json` and default test directories. | `DEC-0023` |
| `RB-08` | The shell wrapper accepts `--godot <path>` and forwards arguments after `--` to GUT. The PowerShell wrapper accepts `-GodotBin <path>` and a `-GutArgs` string array. Equivalent names may be used only if both documentation and tests are updated consistently and the pre-edit plan explains the deviation. | M00 wrapper contract |
| `RB-09` | A focused invocation can run only `res://tests/unit/infrastructure/test_project_harness.gd` without changing `.gutconfig.json`. | M00 Acceptance criteria; `TESTING_AND_VALIDATION.md` §4.4 |
| `RB-10` | A failing GUT test produces a nonzero wrapper result; a passing suite produces zero. Wrappers do not swallow or overwrite the GUT process exit code. | `GATE-GUT`; `DEC-0023` |
| `RB-11` | The infrastructure test validates the project name, configured main-scene resource, Godot 4.7 project feature, Steam App ID `480`, and disabled automatic Steam initialization without calling Steam or initializing the extension. | `DEC-0024`; repository baseline |
| `RB-12` | Headless import, GUT execution, and the main-scene smoke check succeed without a Steam client, Steam account, `steam_appid.txt`, or Steam initialization. | `DEC-0024`; M00 Acceptance criteria |
| `RB-13` | The main-scene smoke command starts the configured dry-run scene headlessly and exits automatically after a short bounded interval. | M00 Acceptance criteria; `TESTING_AND_VALIDATION.md` §4.5 |
| `RB-14` | No committed wrapper, config, documentation, or test contains a developer-specific absolute path, credential, token, or private machine value. | `AGENTS.md`; `DEC-0023` |
| `RB-15` | Temporary failing tests and generated logs/results used for verification are removed before the final diff unless a file is an explicitly approved committed fixture. | `PROMPT_TEMPLATE.md`; `TESTING_AND_VALIDATION.md` §15 |
| `RB-16` | Owner-run Windows checks remain `Pending owner verification` until the owner explicitly reports them; Codex does not infer success from silence. | `PROMPT_TEMPLATE.md` §2.2; `GATE-WINDOWS-HARNESS` |
| `RB-17` | M00 documentation tells a future developer exactly how to run full and focused tests on both operating systems and how to supply a local Godot path without editing repository files. | M00 Player/developer outcome |

## State transitions

These are invocation and verification states; M00 introduces no gameplay state.

| ID | Initial state | Trigger or command | Required resulting state | Failure or recovery behavior | Persistence, report, or event effect |
|---|---|---|---|---|---|
| `ST-01` | No explicit Godot path and `GODOT_BIN` unset | Run either wrapper | Wrapper searches documented `PATH` candidates and prints the resolved executable | If none is found, print actionable setup guidance and exit nonzero before import | No repository or user save mutation |
| `ST-02` | Resolved executable reports a version other than 4.7.x | Run either wrapper | No import or tests run | Print expected versus actual version and exit nonzero | No persistent mutation |
| `ST-03` | Godot 4.7.x resolved; project has not been imported in this checkout | Default wrapper run | Headless import completes, then GUT starts | Import failure stops the sequence and its exit code remains nonzero | `.godot/` may be generated locally and remains ignored |
| `ST-04` | Import succeeds; full suite passes | Default wrapper run | Wrapper exits zero and prints a concise success summary | Not applicable | Generated test output remains ignored or cleaned |
| `ST-05` | Import succeeds; one test fails | Focused or full wrapper run | Wrapper exits nonzero | Failure is visible; after temporary test removal, rerun must return zero | No committed failing test remains |
| `ST-06` | Full config exists | Focused invocation | Only the requested test script or method runs while using the same config | Invalid selector fails or reports no match clearly according to verified GUT behavior | No config mutation |
| `ST-07` | Steam client absent and auto initialization disabled | Import, GUT, and smoke checks | Checks complete without attempting a Steam session | A native-library load failure is reported as an environment problem; do not enable Steam as a workaround | No Steam state or save data |
| `ST-08` | Codex/Linux checks pass; owner has not yet run Windows checks | Pull request handoff | M00 verification is `Partial`; Windows gates are `Pending owner verification` | Merge waits for an explicit owner result | `MILESTONES.md` must not say `Passed` or `Merged` |
| `ST-09` | Owner explicitly reports a Windows failure | Triage message or PR comment | Milestone remains failed/partial and the defect is diagnosed | Do not privately patch the owner's wrapper; fix through a reviewed branch and rerun | Later status update records actual outcome |

## Data and content

M00 introduces no gameplay content, canonical IDs, balance values, or save schema.

The only new configuration data is test infrastructure:

- `.gutconfig.json` must use keys supported by the committed GUT 9.7.1 CLI.
- Test directories and file naming must be repository-relative.
- Stable options belong in `.gutconfig.json`; focused selectors belong on the command line.
- Do not enable update checks or test-time downloads.
- Do not change App ID `480` or automatic Steam initialization settings.
- Do not enable the GodotSteam updater plugin.
- Do not add `steam_appid.txt`.

Before committing `.gutconfig.json`, use the vendored CLI's effective-options or sample-output capability to verify key names instead of copying unverified options from another GUT version.

## UI and presentation

M00 adds no player-facing UI or final presentation.

- Preserve `test_main_scene.tscn` and its current assets.
- Use the scene only for a bounded headless smoke check and one owner-run editor launch.
- Do not reposition, rename, replace, or polish the scene or its assets.
- The smoke check passes when the configured main scene starts under Godot 4.7, produces no new parser/resource/runtime errors, and exits automatically through the command-line timeout.

## Architecture constraints

- Test infrastructure may depend on Godot and GUT; domain and simulation architecture must not be introduced in M00.
- Do not add a gameplay autoload, application service, persistent state object, or save system.
- Do not add or update a third-party dependency.
- Keep GUT test-only and GodotSteam isolated from project-owned gameplay code.
- Automatic Steam initialization must remain disabled.
- Do not call Steam APIs from the infrastructure test, wrappers, main-scene smoke, or project-owned code.
- Do not change Godot version, renderer, reference viewport, scripting language, or main-scene architecture.
- Do not use local wall-clock time or introduce any time-authority code.
- Wrapper errors must be explicit environment failures, not silent fallback behavior.
- Project-owned shell, PowerShell, and GDScript additions must be readable and documented at the level appropriate to junior developers.

## Expected files

This is an informed expectation, not blanket permission to edit every path. Explain meaningful deviations before editing and in the final response.

| Path or area | Expected action | Purpose |
|---|---|---|
| `.gutconfig.json` | Add | Shared GUT 9.7.1 configuration |
| `tools/test/run_gut.sh` | Add and mark executable | Canonical Codex Cloud/Linux entry point |
| `tools/test/run_gut.ps1` | Add | Canonical Windows entry point |
| `tests/unit/infrastructure/test_project_harness.gd` | Add | Prove GUT discovery and stable project settings |
| `.gitignore` | Modify only as observed artifacts require | Exclude generated import/test output without ignoring fixtures |
| `README.md` | Add | Human setup, run commands, and documentation map |
| `docs/codex/TESTING_AND_VALIDATION.md` | Modify | Replace planned wording with the realized wrapper interface and exact commands |
| `docs/codex/MILESTONES.md` | Modify | Record actual M00 implementation and partial verification state without claiming merge or owner success |
| `docs/codex/IMPLEMENTATION_RULES.md` | Modify only if the approved wrapper interface must be clarified | Keep durable engineering rules synchronized |
| Third-party notice file | Add or modify only if repository inspection shows the committed dependency footprint lacks a clear project notice | Record exact license/notice locations without duplicating full licenses unnecessarily |
| `addons/gut/` | Inspect only | Verify version, CLI behavior, and license |
| `addons/godotsteam/` | Inspect only | Verify version, native footprint, and notices; do not initialize or update |
| `project.godot` | Inspect only | Verify Godot 4.7, App ID `480`, and disabled auto initialization |
| `test_main_scene.tscn` | Inspect and run only | Preserve temporary smoke target |
| `docs/codex/milestone-prompts/M00-repository-test-harness.md` | Do not modify | Current owner-approved task instruction |
| `docs/codex/PROMPT_TEMPLATE.md` | Do not modify | Approved prompt-authoring contract |

Do not create empty directories solely to match a future tree. Do not edit third-party addon code or imported binary files.

## Acceptance criteria

Each criterion is binary and must be mapped to actual evidence.

| ID | Pass condition | Verification evidence | Merge gate? |
|---|---|---|---:|
| `AC-01` | `tools/test/run_gut.sh` resolves Godot 4.7.x, imports the project, runs the full GUT suite, and exits `0` in Codex Cloud/Linux. | Exact shell command, detected version, GUT summary, and exit code | Yes |
| `AC-02` | The Linux wrapper succeeds when invoked from a directory outside the repository. | Outside-root command and exit code `0` | Yes |
| `AC-03` | The Linux focused-test invocation runs only the infrastructure test using the checked-in config and exits `0`. | Focused command and GUT discovery summary | Yes |
| `AC-04` | A temporary deliberately failing GUT test makes the Linux wrapper exit nonzero; after removal, the full wrapper returns `0` and the failing file is absent from the diff. | Negative-test command, nonzero code, cleanup evidence, clean rerun | Yes |
| `AC-05` | Missing-Godot and unsupported-version paths fail before import with clear actionable diagnostics. | Safe temporary fake-executable checks or equivalent repeatable wrapper tests | Yes |
| `AC-06` | `.gutconfig.json` is accepted by the committed GUT 9.7.1 CLI and discovers tests recursively under the documented directories. | Effective-options output plus passing full and focused runs | Yes |
| `AC-07` | The configured main scene starts headlessly, produces no new parser/resource/runtime errors, and exits automatically within the documented bound. | Main-scene smoke command and exit code `0` | Yes |
| `AC-08` | Linux import, tests, and smoke succeed without Steam, `steam_appid.txt`, live network access during test execution, or automatic Steam initialization. | Environment statement, project-setting check, repository search, command results | Yes |
| `AC-09` | The repository documents GUT 9.7.1, GodotSteam 4.20, and exact applicable license/notice paths without modifying dependency source. | Changed-file review and cited repository paths | Yes |
| `AC-10` | `tools/test/run_gut.ps1` resolves Windows Godot 4.7.x, imports the project, runs the same full GUT suite, and exits `0`. | Explicit owner result naming tested commit/branch, command, version, result, and date | Yes |
| `AC-11` | The PowerShell wrapper succeeds when invoked from outside the repository and supports the documented focused-test syntax. | Explicit owner result for outside-root and focused commands | Yes |
| `AC-12` | A safe one-time Windows failure-propagation check proves that the PowerShell wrapper returns nonzero for a failing test and returns zero again after cleanup. | Explicit owner result and confirmation that no failing file remains | Yes |
| `AC-13` | The owner opens the project in Godot 4.7, allows import, runs the current dry-run scene once, and observes no new editor, GDExtension, parser, or runtime errors; Steam remains uninitialized. | Explicit owner manual-verification result | Yes |
| `AC-14` | `README.md` and `TESTING_AND_VALIDATION.md` contain exact full, focused, outside-root, smoke, and local Godot-path instructions for both environments. | Documentation review and command copy/paste check | Yes |
| `AC-15` | No new committed file contains a local absolute path, secret, token, temporary failing test, generated log/result, or unapproved dependency change. | Repository search, `git diff --check`, changed-file review, `git status --short` | Yes |
| `AC-16` | All changed non-trivial project-owned GDScript and wrapper logic follows the repository's junior-reviewer documentation rules. | Review changed scripts against `AGENTS.md` and `IMPLEMENTATION_RULES.md` | Yes |
| `AC-17` | Maintained documentation made inaccurate by M00 is updated in the same pull request, while prompt and design files remain unchanged. | Changed-file inventory and relative-link validation | Yes |

Completion rules:

- A criterion is `Passed` only when its listed evidence was actually produced.
- `AC-10` through `AC-13` remain `Pending owner verification` until the owner explicitly reports results.
- Pending owner merge gates keep M00 verification `Partial` and prevent merge.
- Owner silence is not evidence of success.
- A failed criterion returns to troubleshooting and a scoped fix; do not weaken the criterion or privately patch one machine.

## Automated verification

Use the realized wrapper interface documented by this task. If an implementation detail requires a syntax change, update both platform examples and explain the change before editing.

### Codex Cloud or Linux checks

Run in this order:

| Order | Command | Purpose | Required result |
|---:|---|---|---|
| 1 | `git status --short` | Confirm starting worktree | Empty before task edits |
| 2 | `./tools/test/run_gut.sh` | Resolve Godot, import, and run full suite | Godot 4.7.x; exit `0`; no new parser/resource errors |
| 3 | `./tools/test/run_gut.sh -- -gtest=res://tests/unit/infrastructure/test_project_harness.gd` | Focused discovery | Only the infrastructure script runs; exit `0` |
| 4 | `repo_root="$(pwd)"; tmp_dir="$(mktemp -d)"; (cd "$tmp_dir" && "$repo_root/tools/test/run_gut.sh"); result=$?; rmdir "$tmp_dir"; exit $result` | Prove root resolution outside repository | Exit `0` |
| 5 | Use the wrapper-resolved Godot executable with `--headless --path . --quit-after 5` | Main-scene smoke | Starts configured scene and exits `0` without new errors |
| 6 | `find . -iname 'steam_appid.txt' -o -iname '*test*result*' -o -iname '*.log'` | Inspect development aid and generated artifacts | No committed `steam_appid.txt`; no unintended generated artifacts |
| 7 | `git diff --check` | Whitespace and patch sanity | Exit `0` |
| 8 | `git status --short` | Final inventory | Only intended task files remain |

The smoke command must use the same executable-resolution logic or a path printed by the wrapper. Do not commit that path.

### Negative and recovery checks

| Scenario | Method | Expected result |
|---|---|---|
| Missing Godot | Run the shell wrapper with `PATH` constrained and no explicit path or `GODOT_BIN` | Clear diagnostic; nonzero exit before import |
| Unsupported Godot | Supply a temporary executable that prints a representative 4.6 version and exits successfully | Wrapper rejects it; nonzero exit before import |
| Failing GUT test | Create a temporary `test_m00_expected_failure.gd`, run it through the focused wrapper, capture the nonzero result, then delete it | Nonzero while present; file removed; clean full run returns `0` |
| Import failure | Where practical, use a safe temporary invalid project copy or controlled fake executable response rather than corrupting the working tree | Wrapper stops before GUT and returns nonzero |
| Steam unavailable | Run in the normal Codex Cloud/Linux environment with no Steam client | Import, tests, and smoke still pass; no Steam initialization attempt |

Do not leave temporary executables, test files, directories, logs, or results in the final diff.

### Owner-run Windows automated checks

Codex must place exact commands in `README.md` and `TESTING_AND_VALIDATION.md`. The expected interface is:

| Command or action | Purpose | Required result | Merge gate? |
|---|---|---|---:|
| `.\tools\test\run_gut.ps1` | Full Windows import and GUT suite | Godot 4.7.x; exit `0` | Yes |
| `.\tools\test\run_gut.ps1 -GutArgs @('-gtest=res://tests/unit/infrastructure/test_project_harness.gd')` | Focused infrastructure test | Only requested test runs; exit `0` | Yes |
| Invoke the wrapper from `$env:TEMP` using its absolute repository path | Outside-root resolution | Exit `0` | Yes |
| Documented temporary failing-test procedure | One-time PowerShell failure propagation | Nonzero while failing test exists; zero after cleanup | Yes |

The owner may supply Godot through `-GodotBin`, `GODOT_BIN`, or `PATH`. The owner must not edit the wrapper to insert a private path.

Codex cannot mark these checks as passed. In the handoff, label each one `Pending owner verification` until the owner reports it for the tested commit or branch.

## Manual verification

| Step | Actor/environment | Action | Expected result | Merge gate? |
|---:|---|---|---|---:|
| 1 | Codex Cloud/Linux | Inspect addon metadata, GDExtension declarations, project Steam settings, and license/notice paths | Versions/settings match the baseline; no updater or Steam initialization is used | Yes |
| 2 | Project owner, Windows Godot machine | Pull the exact branch/commit and run the full PowerShell wrapper | Same test count/config as Linux where platform-neutral; exit `0` | Yes |
| 3 | Project owner, Windows Godot machine | Run focused and outside-root PowerShell checks | Both succeed with the documented syntax | Yes |
| 4 | Project owner, Windows Godot machine | Perform the one-time temporary failure-propagation procedure, then remove the failing file and rerun full | Failure returns nonzero; clean rerun returns zero; working tree contains no temporary file | Yes |
| 5 | Project owner, Godot 4.7 editor | Open the project, allow imports/GDExtensions to settle, inspect Output/Debugger, and run the configured dry-run scene once | No new import, GDExtension, parser, or runtime errors; existing Death/Eustace dry-run presentation appears | Yes |
| 6 | Project owner, Windows environment | Confirm the test/editor flow does not require a `steam_appid.txt`; where practical, perform one automated run with the Steam client exited | Project still imports/tests; automatic Steam initialization remains disabled | Yes |
| 7 | Reviewer | Inspect the changed-file list and documentation links | No gameplay, dependency, asset, engine, renderer, or prompt scope creep | Yes |

Minimum owner evidence format:

```text
Owner verification: PASS|FAIL — commit <sha> — Windows full GUT, focused/outside-root, failure propagation, and M00 editor smoke — YYYY-MM-DD.
```

The owner may add concise failure details when any check fails. No manual Markdown edit is required merely to report the result.

## Save/load verification

Not applicable — M00 introduces no authoritative gameplay state, serialized fields, save checkpoints, migrations, or offline resolution.

Requirements still apply to test hygiene:

- The infrastructure test must not create persistent gameplay saves under `user://`.
- The main-scene smoke must not introduce or depend on a save file.
- Temporary test artifacts must use disposable locations and be cleaned.
- M00 must not create a placeholder save schema for future milestones.

## Documentation updates

| Document | Required update |
|---|---|
| `README.md` | Add Godot 4.7 prerequisite, `GODOT_BIN`/PATH setup, full/focused test commands, smoke commands, two-machine workflow, and documentation links |
| `docs/codex/TESTING_AND_VALIDATION.md` | Replace future/planned M00 wording with the exact implemented wrapper interface, paths, commands, artifact behavior, and split verification process |
| `docs/codex/MILESTONES.md` | Set M00 implementation to the truthful current stage and verification to `Partial` while owner gates are pending; do not mark `Merged` or `Passed` |
| `docs/codex/IMPLEMENTATION_RULES.md` | No change expected unless the implemented wrapper interface requires a durable clarification |
| `docs/codex/ARCHITECTURE.md` | No change expected |
| `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | No change expected |
| `docs/codex/DECISIONS.md` | No new decision expected; do not add one for ordinary wrapper implementation details |
| Design source-of-truth files | No change expected |
| `docs/codex/PROMPT_TEMPLATE.md` | Do not modify |
| Current and future milestone prompts | Do not modify or create |

Do not mark owner-run checks passed or the milestone merged before those facts are true. A later planning/status update may synchronize `MILESTONES.md` after the owner reports results and the pull request merges.

## Stop and ask conditions

Stop before implementing or expanding the affected part when any of the following occurs:

1. GUT is missing, not version 9.7.1, appears locally modified, or its applicable license is missing.
2. GodotSteam is missing, not the approved 4.20 footprint, lacks required Linux/Windows native libraries, or its applicable license/notice obligations cannot be determined from the repository.
3. `project.godot` no longer targets Godot 4.7, App ID `480` is missing, or automatic Steam initialization is enabled.
4. The current repository already contains a materially different test harness or wrapper contract.
5. Godot 4.7.x cannot be made available in Codex Cloud through the approved environment without adding a machine-specific path, unapproved download, or repository dependency.
6. Headless import requires changing the engine, renderer, main scene, addon source, or Steam initialization behavior.
7. The committed GUT 9.7.1 CLI behaves differently enough that the required shared config, focused selection, or failure exit semantics cannot be implemented honestly.
8. The task would require a new dependency, GitHub Actions, a self-hosted runner, a Steam API call, or another native extension.
9. A pre-existing parser/resource/GDExtension failure cannot be isolated safely within M00.
10. The required result cannot fit one focused infrastructure pull request without implementing later milestone systems.

Do not stop for ordinary wrapper implementation choices that remain within the required behavior. Make the smallest clear choice, document it, and report it under assumptions.

Owner-run Windows checks being unavailable to Codex are not themselves a stop condition. Implement and verify the Linux scope, open the handoff for owner testing, and keep those merge gates pending.

## Deliverables

The completed M00 task must provide:

- `.gutconfig.json` accepted by the committed GUT 9.7.1 CLI;
- `tools/test/run_gut.sh` with executable mode;
- `tools/test/run_gut.ps1`;
- one passing infrastructure test under `tests/unit/infrastructure/`;
- a concise `README.md`;
- only the required `.gitignore` additions;
- synchronized testing and milestone documentation;
- exact GUT/GodotSteam version and license/notice-path documentation;
- Linux full, focused, outside-root, smoke, missing/wrong-version, and failing-test evidence;
- explicit owner-run Windows commands and manual editor steps marked pending until reported;
- a complete changed-file inventory;
- no temporary failing tests, generated logs, private paths, secrets, addon updates, or unrelated changes.

## Final response format

Use exactly these headings.

### Implementation completed

Summarize the harness behavior and the M00 developer outcome. Do not present owner-pending work as complete.

### Files changed

List every added, modified, renamed, or deleted file and its purpose. Identify inspected third-party metadata/license files without implying they were modified.

### Verification

Report separately:

- Codex Cloud/Linux full wrapper command, detected Godot version, test count, exit code, and result;
- focused and outside-root commands and results;
- negative checks for missing/wrong Godot and failing-test propagation;
- main-scene smoke result;
- proof that Steam was not initialized or required;
- owner-run Windows full, focused, outside-root, failure-propagation, and editor checks as `Pending owner verification`, `Passed`, or `Failed` based only on explicit owner evidence;
- acceptance criteria that remain unverified.

### Assumptions

List only assumptions not established by the repository or authoritative documents. Distinguish safe wrapper implementation choices from project requirements.

### Known limitations and risks

State environment-specific limitations, native-library concerns, documentation caveats, and every check not yet performed.

### Deferred work

List gameplay testing, deterministic numeric/time foundations, persistence, CI, Steam trusted-time integration, and other later milestones that were intentionally excluded.

### Suggested next task

Name `M01 — Deterministic numeric and time-authority foundation` only after M00 is merged and both `GATE-GUT` and `GATE-WINDOWS-HARNESS` have passed. Do not begin it.
