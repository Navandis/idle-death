# Milestone M01: Deterministic numeric and time-authority foundation

**Prompt version:** v0.1  
**Prompt date:** 2026-07-13  
**Prompt status:** Draft  
**Milestone definition:** `docs/codex/MILESTONES.md` — `### M01 — Deterministic numeric and time-authority foundation`  
**Recommended task size:** Medium; one pure-foundation pull request  
**Expected base branch or ref:** `main` at or after M00 merge commit `77c618a1d9adbf8b02380d8509d2afb4c4cbc8ea`  
**Planned prompt path:** `docs/codex/milestone-prompts/M01-deterministic-time-foundation.md`

> This draft proposes the fixed-point decision recorded as proposed `DEC-0026`. Do not execute it until the project owner approves both this prompt and that decision, and the repository copies are updated to `Prompt status: Approved` / `DEC-0026: Accepted`.

> This prompt authorizes only the M01 numeric and time-authority foundation. It does not authorize persistence files, Steam initialization, gameplay production, UI, future milestones, broad cleanup, dependency changes, or silent changes to accepted design and architecture decisions.

## Execution protocol

Before editing:

1. Read `AGENTS.md` completely.
2. Read every document and section listed under **Authoritative context**.
3. Inspect the current repository, M00 harness, tests, addon configuration, and `git status --short`.
4. Confirm that M00 is merged and verified and that the repository contains the canonical Linux and Windows GUT wrappers.
5. Confirm that `DEC-0026` is `Accepted`. If it is still `Proposed`, stop and report that the prompt has not completed owner approval.
6. Briefly state the proposed implementation approach, expected files, fixed-point API shape, time-authority state flow, and verification plan before making non-trivial edits.
7. Report any material mismatch between this prompt and the repository before implementing dependent behavior.

During implementation:

- Limit changes to M01 and its acceptance criteria.
- Preserve unrelated work, existing assets, the temporary dry-run scene, project settings, and pinned addons.
- Keep all authoritative numeric and time code scene-tree independent and directly constructible in GUT tests.
- Keep every time unit explicit in names and comments.
- Do not read device wall time, local UTC, timezone, calendar, file timestamps, registry values, or Steam APIs from authoritative code.
- Do not create a save file, JSON codec, schema version, migration, production Steam adapter, Reaping, Hall, inventory, tutorial, report, or gameplay UI.
- Add junior-readable script and member documentation explaining ownership, units, determinism, overflow handling, residual semantics, and the separation between planning and committing trusted-time reconciliation.
- Add or update every test needed to prove the behavior.
- Create the required milestone-specific owner verification script and generated-log workflow defined below.
- Run every Codex-executable check listed in this prompt and report exact commands and exit codes.
- Leave owner-run Windows checks as `Pending owner verification` until the owner reports a result for the tested PR head.
- Do not create, rewrite, or broaden this prompt or any future milestone prompt.

Do not describe M01 as complete while any merge-gate criterion is failed, blocked, or pending. A pull request may be ready for owner testing with verification `Partial`, but it may not merge until `GATE-FIXED-POINT` and all listed owner gates explicitly pass.

## Objective

Implement the scene-independent numeric and time-authority foundation that every later production, forecast, and offline-resolution system will use. The result must provide one centralized checked fixed-point scale, an authoritative simulation timeline, injected monotonic foreground timing, trusted-time sample contracts, and deterministic reconciliation planning without reading the player's adjustable wall clock.

## Player or developer outcome

From tests and a deterministic developer trace, a developer can:

- represent fractional rates and progress with exact integer subunits and residuals;
- prove that equivalent time chunking produces the same result;
- advance a minimal authoritative timeline from an injected monotonic clock;
- establish a first trusted anchor without retroactive credit;
- continue foreground progress while trusted time is unavailable;
- reconcile a later trusted sample by subtracting already-credited foreground time;
- prove that a repeated sample returns no additional elapsed time;
- inspect explicit rejection and cap diagnostics;
- run the complete Windows validation through one PowerShell command that writes a shareable log.

The required demonstration uses a fake trusted source: establish an anchor, credit ten minutes of foreground time, advance trusted time by one hour, produce exactly fifty minutes of uncredited elapsed time, commit it once, and show that repeating the same sample produces zero.

## Authoritative context

Read the following before editing.

| Priority | Source | Required sections, labels, or records | Why it applies |
|---:|---|---|---|
| 1 | `AGENTS.md` | Full file, especially **Architectural boundaries**, **Simulation invariants**, **Save/load and time requirements**, **Code comments and junior-reviewer documentation**, and **Testing and validation** | Repository-wide ownership, determinism, time, comments, and verification rules |
| 2 | `docs/codex/MILESTONES.md` | §5 `GATE-FIXED-POINT`; §6 M01 row; §9 `M01 — Deterministic numeric and time-authority foundation`; M00 completion record | Approved scope, dependency, and merge gate |
| 3 | `docs/codex/PROMPT_TEMPLATE.md` | §§2.1–2.3 and the instantiated-prompt evidence rules | Prompt ownership and owner verification packaging |
| 4 | `docs/codex/OWNER_VERIFICATION_WORKFLOW.md` | §§2–8 | Required PowerShell package, generated log, cleanup, and owner evidence contract |
| 5 | `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md` | `IF-REQ-07`, `IF-REQ-08`, `IF-REQ-15`, `IF-REQ-16`, `IF-REQ-17`; §9 persistent Reapings and offline resolution | Shared deterministic rules, save integrity, storefront isolation, and trusted-time authority |
| 6 | `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md` | `P90-SAFE-14`; **Online and offline behavior**; `P90-AC07` | Prototype prohibition on local-clock credit and deterministic technical integrity |
| 7 | `docs/codex/ARCHITECTURE.md` | §5.2; §7; §§9.1–9.8; §10.6; §23; §26 | Mutable-state ownership, the three time concepts, reconciliation, numeric accumulation, test seams, and the open fixed-point item |
| 8 | `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | §§9.2–9.3; §§12.1, 12.3, and 12.4; §17 | `TimeAuthorityState`, minimal `GameState`, units, fractional progress, rounding, and runtime validation |
| 9 | `docs/codex/IMPLEMENTATION_RULES.md` | §§5–6; §§10.1–10.9; §18; §§21–22 | Junior-readable code, dependency boundaries, determinism, testing, security, and PR scope |
| 10 | `docs/codex/TESTING_AND_VALIDATION.md` | §§4, 6, 7.1, 8.2, 9.6, 11.1, 12.3, 18, and 19 | Canonical commands, test cases, trusted-time anomalies, demonstration path, and owner logs |
| 11 | `docs/codex/DECISIONS.md` | `DEC-0007`, `DEC-0010`, `DEC-0017`, `DEC-0021`, `DEC-0023`, `DEC-0025`, and accepted `DEC-0026` | State independence, numeric model, test framework, trusted-time policy, split execution, owner logs, and exact scale |
| 12 | M00 merge | PR #4; merge commit `77c618a1d9adbf8b02380d8509d2afb4c4cbc8ea` | Verified test harness and dependency baseline |

This prompt is the latest owner-approved task instruction only within M01. It does not supersede accepted decisions or protected design invariants. If applicable sources conflict and the documented hierarchy does not resolve the conflict, stop and report the conflict, practical consequence, and available options.

## Repository state

The expected baseline at task start is:

| Item | Expected state | Evidence or path to inspect |
|---|---|---|
| Required prior milestone | M00 merged and verification passed | `docs/codex/MILESTONES.md`, PR #4, merge commit `77c618a...` |
| Test harness | Canonical full and focused GUT wrappers exist and pass on Linux and Windows | `.gutconfig.json`, `tools/test/run_gut.sh`, `tools/test/run_gut.ps1`, `tests/unit/infrastructure/` |
| Owner verification workflow | Approved script/log workflow exists | `docs/codex/OWNER_VERIFICATION_WORKFLOW.md`, `DEC-0025` |
| Godot project | Godot 4.7, GDScript, temporary dry-run main scene, Compatibility renderer | `project.godot`, `test_main_scene.tscn` |
| Steam configuration | GodotSteam 4.20 present; App ID `480`; automatic initialization disabled | `addons/godotsteam/`, `project.godot` |
| Production source code | No authoritative `GameState`, fixed-point utility, trusted-time service, save implementation, or gameplay simulation yet | `src/` and repository inspection |
| Persistence | No save schema, JSON codec, disk storage, or migration implementation | Repository inspection; M02 remains unstarted |
| Owner logs | Generated logs are ignored and not committed | `.gitignore`, `tools/test/owner/logs/` when created locally |
| Temporary scaffolding | Existing dry-run scene and assets must be preserved | `test_main_scene.tscn`, `assets/` |
| Working tree | Clean except for task changes | `git status --short` |

Re-check these facts at task start. If the repository is materially ahead of, behind, or inconsistent with this table, report the mismatch. Do not overwrite newer work or recreate an already completed subsystem.

## Dependencies

| Dependency or gate | Required state | Required before | How to verify |
|---|---|---|---|
| M00 | Merged and `Passed` | Implementation | `MILESTONES.md`, PR #4 merge, full harness execution |
| `DEC-0026` | `Accepted` | Implementation | `DECISIONS.md` |
| Godot | 4.7.x available through M00 wrapper resolution | Verification | `./tools/test/run_gut.sh`; owner PowerShell package |
| GUT | Pinned 9.7.1 | Implementation and verification | `addons/gut/plugin.cfg` and wrapper output |
| `GATE-FIXED-POINT` | Exact scale, arithmetic rules, bounds, tests, and documentation recorded | Merge | M01 code, tests, `DEC-0026`, updated contracts, owner log |
| Owner Windows environment | Can run Godot 4.7 console executable and committed PowerShell package | Merge | Explicit owner result and generated M01 log |

Do not weaken a dependency gate to make the task appear complete.

## Scope

Implement only the following:

1. Create a minimal typed, scene-tree-independent `GameState` containing the authoritative `simulation_time_msec` timeline required by later systems. Do not add empty inventory, Reaping, Hall, tutorial, or report placeholders.
2. Create a separate typed `TimeAuthorityState` matching the approved contract. It is paired with `GameState` by services and later belongs to the save envelope; do not duplicate it inside `GameState`.
3. Implement one centralized `FixedPoint` utility using the accepted scale of `1_000_000` subunits per whole unit.
4. Implement checked, deterministic non-negative fixed-point operations sufficient for later rate, multiplier, and residual flows, including integer-millisecond rate accumulation.
5. Define the project-owned monotonic clock contract, a production process-monotonic adapter, and a fake monotonic clock for tests.
6. Define `TrustedTimeProvider`, `TrustedTimeSample`, trusted/unavailable statuses, stable diagnostic codes, and a fake trusted-time provider. Do not implement a Steam adapter.
7. Implement a pure or explicitly non-mutating trusted-time reconciliation planning step and a separately validated commit step so a candidate elapsed interval can be simulated and saved transactionally by later milestones.
8. Implement foreground accounting that advances `GameState.simulation_time_msec` and, when an anchor exists, increments `foreground_credited_since_anchor_msec` atomically in memory.
9. Add comprehensive GUT tests for fixed-point boundaries, residuals, overflow, monotonic behavior, trusted-time unavailable/reconnect/rollback/source mismatch/cap/repeated-sample behavior, stale-plan rejection, and chunking invariance.
10. Add a focused source-ownership test that rejects authoritative device-wall-clock and file-timestamp calls while allowing the one approved monotonic process-clock adapter.
11. Add a deterministic headless M01 trace that prints the anchor → ten foreground minutes → one trusted hour → fifty uncredited minutes → repeated zero sequence and exits nonzero if any value is wrong.
12. Add `tools/test/owner/run_m01_owner_verification.ps1` under the approved owner workflow. It must run the full suite, focused M01 tests, source-ownership check, and trace; capture one UTF-8 log; clean any temporary artifacts; and return the correct process status.
13. Update the maintained architecture, data, implementation, testing, decision, milestone, and applicable README documentation made concrete by the implementation.

Use the smallest clear implementation. M01 is a numeric and time-accounting foundation, not a general framework for all future simulation behavior.

## Non-goals

Do not implement or refactor:

1. Disk files, `user://` saves, JSON, schema version 1, migrations, backup rotation, atomic file replacement, or any M02 behavior.
2. Steam initialization, GodotSteam API calls, server-time sampling, achievements, Steam Cloud, or any M06 behavior.
3. Reaping production, Thresholds, Halls, inventory, Forms, Retinues, reports, forecasts, tutorial progression, or gameplay UI.
4. Final offline cap or production balance. The reconciliation service receives a non-negative cap as an input; tests use explicit fixtures.
5. A general arbitrary-precision library, rational-expression engine, BigInt dependency, native extension, or another third-party dependency.
6. Floating-point authoritative accumulation or per-subsystem fixed-point scales.
7. A gameplay autoload, main-scene replacement, screen, editor plugin, or debug UI.
8. Network time from an unapproved service, local-wall-clock fallback, registry/file timestamp fallback, or manual time entry.
9. GitHub Actions, release automation, telemetry backends, or platform packaging.
10. Broad directory reorganization, unrelated renaming/formatting, dependency upgrades, or modification of third-party addon source.
11. Changes to `PROMPT_TEMPLATE.md`, this prompt, or later milestone prompts during implementation.

## Required behavior

Every row is a binary requirement for this task.

| ID | Required behavior | Source trace |
|---|---|---|
| `RB-01` | `FixedPoint.SCALE` equals `1_000_000`; one whole unit is exactly `1_000_000` subunits and the same scale is used by every M01 fixed-point operation. | Accepted `DEC-0026`; `GATE-FIXED-POINT` |
| `RB-02` | Authoritative fixed-point operations use signed 64-bit GDScript integers but accept only non-negative flow/rate/multiplier inputs in M01 unless a method explicitly documents a signed contract. | `DEC-0010`; `IMPLEMENTATION_RULES.md` §10.7 |
| `RB-03` | Expected invalid inputs and arithmetic overflow return a typed failure result with a stable reason code; they never wrap silently, partially mutate state, or rely on an assertion as the only handling. | `DEC-0010`; action-result and error-handling rules |
| `RB-04` | Integer-millisecond rate accumulation uses deterministic floor semantics and returns the next residual explicitly. Equivalent chunks produce exactly the same produced subunits and residual. | `IF-REQ-08`; `ARCHITECTURE.md` §10.6 |
| `RB-05` | A high-value rate case whose naïve intermediate multiplication would exceed signed 64-bit range succeeds when the mathematical final result fits; a result that cannot fit fails clearly. | `GATE-FIXED-POINT`; `DEC-0026` |
| `RB-06` | `GameState.simulation_time_msec` is a non-negative authoritative timeline and changes only through validated elapsed-time operations. | `ARCHITECTURE.md` §§9.1–9.2; data contract §9.3 |
| `RB-07` | `TimeAuthorityState` remains separate from `GameState` and contains the approved anchor, source, foreground-credit, pending, and diagnostic fields without Steam-specific wrapper data. | Data contract §9.2; `DEC-0021` |
| `RB-08` | The production monotonic adapter obtains process-monotonic milliseconds only; it does not read calendar or wall-clock time. Simulation/domain code receives elapsed durations and never reads the adapter directly. | `DEC-0010`; `IMPLEMENTATION_RULES.md` §§10.1–10.3 |
| `RB-09` | The first monotonic observation establishes a cursor and returns zero elapsed; later non-decreasing samples return the exact delta; a backward sample fails without moving the cursor. | M01 milestone; deterministic time contract |
| `RB-10` | A trusted sample has an explicit status, source ID, UTC milliseconds when trusted, and diagnostic code. Trusted samples validate source and non-negative epoch; unavailable samples provide no elapsed credit. | `ARCHITECTURE.md` §9.3 |
| `RB-11` | The first accepted trusted sample establishes the anchor, clears pending reconciliation, and grants zero retroactive closed-session elapsed time. | `DEC-0021`; `P90-SAFE-14` |
| `RB-12` | When trusted time is unavailable, no closed-session elapsed is returned, the anchor is not guessed or moved, and pending reconciliation is set or retained while foreground accounting remains usable. | `IF-REQ-17`; `DEC-0021` |
| `RB-13` | Foreground credit atomically increments the simulation timeline and, only when an anchor exists, `foreground_credited_since_anchor_msec`; invalid or overflowing input changes neither state. | `ARCHITECTURE.md` §9.2 |
| `RB-14` | Reconciliation planning computes `gross_gap_msec = trusted_now - anchor` and `uncredited_gap_msec = gross_gap - foreground_already_credited` without mutating authoritative state. | `ARCHITECTURE.md` §9.5 |
| `RB-15` | If a trusted sample has not advanced far enough to cover already-credited foreground time, the result grants zero, preserves the current anchor and foreground counter, and reports a stable `TIME_SAMPLE_NOT_AHEAD` diagnostic rather than resetting accounting or over-crediting later. | `DEC-0021`; no-duplicate invariant |
| `RB-16` | A backward sample, source mismatch, malformed sample, stale reconciliation plan, or overflow is rejected with zero credit and no anchor mutation. | `DEC-0021`; `P90-AC07` |
| `RB-17` | A non-negative offline cap is applied after deriving the uncredited gap. The result reports credited and capped-out milliseconds separately; no final game cap is hard-coded. | `ARCHITECTURE.md` §9.5; provisional cap rule |
| `RB-18` | Committing a valid plan updates the anchor, resets foreground credit, clears pending state, and records the diagnostic only after all plan preconditions still match. Recommitting the same or a stale plan fails without mutation. | Transaction seam for M02; `DEC-0021` |
| `RB-19` | After a successful commit, repeating the same trusted sample returns zero additional elapsed time. | Idempotency requirement; `P90-AC07` |
| `RB-20` | No project-owned authoritative source calls device wall-clock, timezone, calendar, registry, file-modification-time, Steam, or unapproved network-time APIs. A source-ownership test enforces the current forbidden API list. | `IF-REQ-16`, `IF-REQ-17`; `P90-SAFE-14` |
| `RB-21` | Tests use fake clocks/providers and do not sleep, initialize Steam, access the network, or depend on the scene tree. | `DEC-0017`; `ARCHITECTURE.md` §23 |
| `RB-22` | The M01 developer trace prints exact expected values and returns nonzero on any mismatch. It must not mutate user saves or require the main scene. | M01 demonstration path |
| `RB-23` | The owner PowerShell script follows `OWNER_VERIFICATION_WORKFLOW.md`, accepts `-CommitSha`, keeps Git optional, writes a UTF-8 log under the ignored log directory, and returns nonzero on any automated failure. | `DEC-0025` |
| `RB-24` | All non-trivial project-owned scripts explain responsibility, owned/non-owned state, collaborators, units, determinism, and error behavior for a junior reviewer. | `AGENTS.md`; `IMPLEMENTATION_RULES.md` §5 |

## State transitions

| ID | Initial state | Trigger or command | Required resulting state | Failure or recovery behavior | Persistence, report, or event effect |
|---|---|---|---|---|---|
| `ST-01` | New monotonic tracker with no cursor | Observe fake monotonic time `1000` | Cursor becomes `1000`; elapsed result is `0` | Invalid negative sample fails without a cursor | No persistence in M01 |
| `ST-02` | Cursor `1000` | Observe `1600` | Elapsed result is `600`; cursor becomes `1600` | Backward `1500` fails and cursor remains `1600` | No persistence in M01 |
| `ST-03` | `GameState.simulation_time_msec = 0`; no trusted anchor | Credit ten foreground minutes | Simulation timeline becomes `600000`; foreground-since-anchor remains `0` | Negative/overflow input leaves both states unchanged | Future save fields only; no disk write |
| `ST-04` | No trusted anchor | Trusted sample from `TEST_TRUSTED_TIME` at known epoch | Anchor is established; source recorded; credit is `0`; pending false | Invalid trusted sample is rejected; no anchor | Future save-envelope state |
| `ST-05` | Trusted anchor exists | Credit ten foreground minutes | Simulation timeline advances by `600000`; foreground-since-anchor becomes `600000` | Overflow leaves state unchanged | Future save-envelope state |
| `ST-06` | Anchor exists | Provider returns `UNAVAILABLE` | Credit is `0`; pending true; anchor and foreground count remain | Repeated unavailable result remains idempotent | Future diagnostic/pending fields |
| `ST-07` | Anchor exists; ten foreground minutes credited | Trusted source advances by one hour | Plan reports `3000000` milliseconds (fifty minutes) uncredited | Source mismatch/backward/invalid sample yields rejected plan | Plan is non-mutating |
| `ST-08` | Valid plan from `ST-07` still matches current authority state | Commit plan after caller accepts elapsed interval | Anchor advances to sample; foreground counter resets; pending false | Stale or repeated plan fails without mutation | M02 later wraps simulation and disk commit |
| `ST-09` | `ST-08` committed | Plan with the same trusted sample again | Credit is `0`; no duplicate timeline advance | None | Idempotent result |
| `ST-10` | Uncredited gap exceeds supplied cap | Plan reconciliation | Credit equals cap; capped-out amount is reported; candidate anchor is the trusted sample | Negative cap is invalid; no mutation | Cap value remains caller-supplied/test data |
| `ST-11` | Foreground count exceeds current trusted gross gap because the source has not advanced enough | Plan reconciliation | Credit `0`; diagnostic `TIME_SAMPLE_NOT_AHEAD`; anchor and foreground count preserved | Later trusted sample can catch up and reconcile once | Prevents granularity-driven over-credit |
| `ST-12` | Fixed-point rate and residual are known | Accumulate one total interval or equivalent chunks | Produced subunits and final residual are identical | Unsupported overflow returns failure with original residual unchanged | Residual is returned to caller; not persisted yet |

State ownership must remain explicit. The time-authority service owns validation and reconciliation state changes; `FixedPoint` owns numeric conversion/arithmetic; fake providers own only test-controlled samples; no UI or tutorial callback owns these rules.

## Data and content

M01 introduces architecture constants and typed runtime contracts, not authored gameplay content.

| Canonical ID, setting, or file | Type | Required value or shape | Status | Source |
|---|---|---|---|---|
| `FixedPoint.SCALE` | Numeric architecture constant | `1_000_000` subunits per whole unit | Proposed by `DEC-0026`; becomes confirmed on owner approval | `DEC-0026` |
| `TrustedTimeStatus.TRUSTED` | Enum/status | Sample contains validated source and epoch | Confirmed | `ARCHITECTURE.md` §9.3 |
| `TrustedTimeStatus.UNAVAILABLE` | Enum/status | No authoritative sample; grants no closed-session time | Confirmed | `DEC-0021` |
| `TEST_TRUSTED_TIME` | Test-only source ID | Fake provider source; never used by release platform code | Test-only | M01 tests |
| `STEAM_SERVER_TIME` | Reserved production source ID | Not sampled or initialized in M01 | Existing/reserved | `DEC-0021`, `DEC-0024` |
| Diagnostic codes | `StringName` constants | Minimum list below | Confirmed contract for M01 | M01 prompt |
| `tools/test/owner/logs/` | Generated evidence directory | UTF-8 logs; ignored by Git | Confirmed | `DEC-0025` |

Minimum stable diagnostic/reason codes:

```text
TIME_OK
TIME_FIRST_ANCHOR_ESTABLISHED
TIME_SOURCE_UNAVAILABLE
TIME_SOURCE_MISMATCH
TIME_SAMPLE_BACKWARD
TIME_SAMPLE_NOT_AHEAD
TIME_OFFLINE_CAP_APPLIED
TIME_STALE_PLAN
TIME_INVALID_INPUT
TIME_ARITHMETIC_OVERFLOW
MONOTONIC_SAMPLE_BACKWARD
FIXED_POINT_INVALID_INPUT
FIXED_POINT_OVERFLOW
```

Codex may add a narrowly necessary diagnostic but must not rename or merge the listed meanings without reporting the contract change.

Fixed-point rules:

- `1.0` multiplier = `1_000_000`.
- `0.15` additive fraction = `150_000`; `1.15` multiplier = `1_150_000`.
- M01 arithmetic is non-negative and floors toward zero where a whole subunit cannot be produced.
- The unproduced numerator is returned as an explicit canonical remainder for the documented divisor.
- No float or formatted display value enters authoritative arithmetic.
- Each operation documents its accepted range and fails before a mathematical result would exceed signed 64-bit range.
- The rate-accumulation API must support `rate_subunits_per_second = INT64_MAX` for exactly `1000` milliseconds with zero prior residual, producing `INT64_MAX`, while a larger mathematical result is rejected. This prevents a naïve overflowing intermediate multiply.

The reconciliation cap is an explicit non-negative method input. M01 does not select the game's final offline cap.

## UI and presentation

No player-facing UI is implemented.

| Surface or state | Required presentation and interaction | Explicitly deferred |
|---|---|---|
| Headless developer trace | Print anchor, foreground credited, trusted gap, uncredited result, commit result, repeated-sample result, and diagnostics with units | Debug overlay, forecast UI, offline-return screen |
| Owner verification script | Print progress and final log path; log exact commands, versions, exit codes, and PASS/FAIL | Visual/editor/Steam interaction |

The trace and owner script are development tools. They must not load the main scene, create saves, initialize Steam, or become release gameplay surfaces.

## Architecture constraints

- `GameState`, `TimeAuthorityState`, fixed-point types, samples, plans, results, and services are typed `RefCounted` or equivalent scene-independent GDScript objects.
- `GameState` owns `simulation_time_msec`; `TimeAuthorityState` remains a separate save-envelope concern.
- Domain and simulation-facing code receives elapsed integer milliseconds. It does not read clocks, frame delta, Nodes, scenes, input, Steam, or files.
- Only the process-monotonic adapter may call the approved Godot monotonic ticks API. It may not call a system calendar API.
- Reconciliation planning is non-mutating. Commit verifies the plan still matches the expected anchor/source/foreground state before changing anything.
- M01 commits only in-memory state. M02 later supplies schema, storage, and atomic disk transaction semantics.
- Do not add a gameplay autoload, service locator, dependency-injection framework, event sourcing, concurrency, arbitrary precision dependency, or general rules engine.
- Do not introduce authoritative randomness.
- Do not create empty future state objects merely to make `GameState` look complete.

## Expected files

This is an informed expectation, not permission to edit every path. Codex may correct filenames after inspection, but must explain meaningful deviations in its pre-edit plan and final response.

| Path or area | Expected action | Purpose |
|---|---|---|
| `src/domain/state/game_state.gd` | Add | Minimal authoritative simulation timeline |
| `src/domain/state/time_authority_state.gd` | Add | Trusted anchor, foreground credit, pending, and diagnostics |
| `src/simulation/fixed_point.gd` | Add | Central scale, checked arithmetic, rate accumulation, and residual rules |
| `src/simulation/fixed_point_result.gd` or equivalent | Add if useful | Typed success/failure/value/remainder result |
| `src/time/monotonic_clock.gd` | Add | Project-owned monotonic clock contract |
| `src/time/system_monotonic_clock.gd` | Add | Approved process-monotonic Godot adapter |
| `src/time/monotonic_elapsed_tracker.gd` | Add | Cursor and delta validation |
| `src/time/trusted_time_provider.gd` | Add | Project-owned external-time interface |
| `src/time/trusted_time_sample.gd` | Add | Typed trusted/unavailable sample |
| `src/time/time_reconciliation_plan.gd` | Add | Non-mutating candidate elapsed/anchor transition |
| `src/time/time_authority_service.gd` | Add | Foreground accounting, planning, and commit validation |
| `tests/support/fake_monotonic_clock.gd` | Add | Test-controlled monotonic source |
| `tests/support/fake_trusted_time_provider.gd` | Add | Test-controlled trusted/unavailable samples |
| `tests/unit/simulation/test_fixed_point.gd` | Add | Scale, residual, chunking, bounds, and overflow tests |
| `tests/unit/time/test_monotonic_elapsed_tracker.gd` | Add | First/repeated/forward/backward monotonic behavior |
| `tests/unit/time/test_time_authority_service.gd` | Add | Anchor, unavailable, reconnect, cap, repeat, mismatch, and stale-plan tests |
| `tests/unit/infrastructure/test_time_source_ownership.gd` | Add | Reject forbidden wall-clock/file/Steam calls in authoritative source |
| `tools/test/traces/m01_time_foundation_trace.gd` | Add | Deterministic headless developer demonstration |
| `tools/test/owner/run_m01_owner_verification.ps1` | Add | One-command Windows verification and UTF-8 log |
| `.gitignore` | Inspect; modify only if required | Ensure generated owner logs remain ignored |
| `README.md` | Modify if useful | Add M01 owner command and trace reference |
| `docs/codex/ARCHITECTURE.md` | Modify | Record realized scale, planning/commit seam, and source ownership |
| `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | Modify | Record exact scale, statuses, fields, diagnostics, and bounds |
| `docs/codex/IMPLEMENTATION_RULES.md` | Modify | Record realized fixed-point and time APIs where durable |
| `docs/codex/TESTING_AND_VALIDATION.md` | Modify | Record exact M01 test and owner-script commands |
| `docs/codex/DECISIONS.md` | Modify | Mark accepted `DEC-0026` and record realized bounds if implementation preserves the approved decision |
| `docs/codex/MILESTONES.md` | Modify | Record truthful M01 implementation and verification state |
| `docs/codex/OWNER_VERIFICATION_WORKFLOW.md` | No change expected | Existing generic package applies |

Do not create empty directories solely to match this list. Do not rename or reorganize unrelated assets or temporary scaffolding.

## Acceptance criteria

Each criterion is binary and observable.

| ID | Pass condition | Verification evidence | Merge gate? |
|---|---|---|---:|
| `AC-01` | `FixedPoint.SCALE` is exactly `1_000_000`, documented once as the project scale, and no M01 subsystem defines another scale. | Fixed-point unit test, source search, `DEC-0026`, contract review | Yes |
| `AC-02` | Whole/subunit conversion, ratio conversion, multiplier application, and millisecond rate accumulation return exact expected values and residuals for documented inputs. | `test_fixed_point.gd` | Yes |
| `AC-03` | Equivalent elapsed chunks produce identical fixed-point output and final residual. | Parameterized chunking tests including one-shot, 60 chunks, and 3600 chunks | Yes |
| `AC-04` | Naïve-intermediate-overflow cases whose final result fits succeed; invalid and true-overflow cases return stable failures without state mutation or wraparound. | Boundary tests at signed-64 limits | Yes |
| `AC-05` | Minimal `GameState` and `TimeAuthorityState` are scene-tree independent, validate non-negative units, and preserve their ownership separation. | Direct construction tests and code review | Yes |
| `AC-06` | Monotonic tracking returns zero on first observation, exact positive deltas afterward, and rejects backward samples without moving the cursor. | `test_monotonic_elapsed_tracker.gd` | Yes |
| `AC-07` | The only project-owned production clock call in M01 is the approved process-monotonic ticks call inside its adapter. | Source-ownership test and repository search | Yes |
| `AC-08` | First trusted sample establishes an anchor and returns zero retroactive elapsed time. | Time-authority unit test and trace | Yes |
| `AC-09` | Unavailable trusted time returns zero, preserves the anchor, marks pending reconciliation, and does not block foreground timeline advancement. | Time-authority unit tests | Yes |
| `AC-10` | Anchor + ten foreground minutes + one trusted hour returns exactly `3_000_000` milliseconds once; repeated sample returns zero. | Unit test and headless trace | Yes |
| `AC-11` | A sample not yet ahead of foreground credit preserves the current anchor/counter and grants zero without causing later over-credit. | Granularity/catch-up regression test | Yes |
| `AC-12` | Backward, mismatched-source, malformed, stale-plan, and arithmetic-overflow cases return zero and leave authoritative state unchanged. | Negative/recovery matrix | Yes |
| `AC-13` | Cap handling reports credited and capped-out milliseconds separately and does not hard-code a final game cap. | Cap tests with multiple explicit inputs | Yes |
| `AC-14` | Reconciliation planning is non-mutating; valid commit changes the expected fields once; recommit/stale commit fails without mutation. | Plan/commit tests | Yes |
| `AC-15` | Fake clocks/providers provide deterministic tests without sleep, network, Steam, main scene, or user saves. | Test implementation review and full suite | Yes |
| `AC-16` | The headless M01 trace prints the expected values and exits `0`; deliberately altered expected data causes it to exit nonzero in a safe temporary check or direct unit test. | Trace command and negative coverage | Yes |
| `AC-17` | Codex/Linux full suite and focused M01 tests pass under Godot 4.7 with no new parser/resource errors. | Exact commands and exit code `0` | Yes |
| `AC-18` | `run_m01_owner_verification.ps1` follows `DEC-0025`, writes one UTF-8 log, records the requested revision and all steps, returns nonzero on failure, and leaves no generated log or temporary artifact tracked by Git. | Script review plus owner-generated log | Yes |
| `AC-19` | Owner-run Windows full suite, focused M01 tests, source-ownership check, and trace pass for the reported PR head. | Explicit owner result and uploaded generated log | Yes |
| `AC-20` | All changed non-trivial GDScript and PowerShell follows the repository junior-reviewer documentation rules. | Review against `AGENTS.md` and `IMPLEMENTATION_RULES.md` | Yes |
| `AC-21` | Maintained architecture, data, implementation, testing, decision, milestone, and applicable README documents are synchronized. | Changed-file review and link validation | Yes |
| `AC-22` | No save file, schema, JSON codec, Steam initialization, gameplay production, new dependency, local absolute path, secret, committed owner log, or unrelated refactor is introduced. | Changed-file review, source search, `git diff --check`, `git status --short` | Yes |

Completion rules:

- A criterion is `Passed` only when its listed evidence was actually produced.
- `AC-19` remains `Pending owner verification` until the owner reports the result for the tested PR head and provides the generated log.
- A pending merge-gate criterion prevents merge and keeps M01 verification `Partial`.
- A failed criterion prevents completion even when the main demonstration appears to work.
- Do not weaken or delete an acceptance criterion after implementation begins without owner approval and a prompt version update.

## Automated verification

Use the realized paths if Codex makes a justified low-level filename adjustment. Update documentation and the owner script consistently.

### Codex Cloud or Linux checks

Run in this order:

| Order | Command | Purpose | Required result |
|---:|---|---|---|
| 1 | `git status --short` | Confirm starting worktree | Empty before task edits |
| 2 | `./tools/test/run_gut.sh -- -gtest=res://tests/unit/simulation/test_fixed_point.gd` | Fixed-point scale, arithmetic, residuals, chunking, and overflow | Exit `0` |
| 3 | `./tools/test/run_gut.sh -- -gtest=res://tests/unit/time/test_monotonic_elapsed_tracker.gd` | Monotonic cursor/delta behavior | Exit `0` |
| 4 | `./tools/test/run_gut.sh -- -gtest=res://tests/unit/time/test_time_authority_service.gd` | Anchor, unavailable, reconnect, cap, repeat, mismatch, and plan/commit behavior | Exit `0` |
| 5 | `./tools/test/run_gut.sh -- -gtest=res://tests/unit/infrastructure/test_time_source_ownership.gd` | Forbidden clock/file/Steam source ownership | Exit `0` |
| 6 | Use the wrapper-resolved Godot 4.7 executable with `--headless --path . -s res://tools/test/traces/m01_time_foundation_trace.gd` | Developer-visible exact trace | Prints 10 foreground minutes, 50 uncredited minutes, repeated zero; exit `0` |
| 7 | `./tools/test/run_gut.sh` | Full regression suite | Exit `0`; no new parser/resource errors |
| 8 | `git diff --check` | Patch sanity | Exit `0` |
| 9 | Search project-owned `src/` for forbidden wall-clock, timezone, file-timestamp, registry, Steam, and unapproved network-time APIs | Defense in depth | Only the approved monotonic call is present in its adapter |
| 10 | `git status --short` | Final inventory | Only intended task files remain; no generated log or temporary file |

The trace command must use the same executable that the wrapper resolves. Do not commit its machine path.

### Negative and recovery checks

| Scenario | Method | Expected result |
|---|---|---|
| Negative fixed-point/time input | Direct unit tests | Stable invalid-input result; no mutation |
| True int64 overflow | Boundary tests | Stable overflow result; no wrap or mutation |
| Intermediate-overflow trap | Use a rate/elapsed pair whose final result fits but naïve multiplication does not | Exact success |
| Backward monotonic sample | Fake clock test | Failure; cursor unchanged |
| Unavailable trusted source | Fake provider | Zero credit; pending true; foreground still creditable |
| Backward trusted epoch | Fake provider | Rejected; anchor unchanged |
| Trusted source mismatch | Fake provider | Rejected; anchor unchanged |
| Trusted sample not ahead of foreground | Fake provider | Zero; anchor/counter preserved until catch-up |
| Stale/repeated reconciliation plan | Apply after state revision/commit | Rejected; no duplicate state change |
| Cap smaller than uncredited gap | Explicit fixture cap | Credited/capped-out values exact |
| Forbidden source API | Add a temporary forbidden call only in a disposable copy or prove the scanner's matcher directly | Source-ownership test detects it; no temporary file remains |

Do not leave deliberately failing tests, temporary copies, logs, generated result files, or debug-only state in the final diff.

### Owner-run Windows automated checks

**Owner package for this milestone:** Milestone-specific PowerShell script  
**Expected PowerShell path:** `tools/test/owner/run_m01_owner_verification.ps1`  
**Generated log path:** `tools/test/owner/logs/`  
**Expected owner invocation:**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
    -File .\tools\test\owner\run_m01_owner_verification.ps1 `
    -CommitSha "<PR_HEAD_SHA>"
```

When `GODOT_BIN` is not configured:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
    -File .\tools\test\owner\run_m01_owner_verification.ps1 `
    -GodotBin "C:\Path\To\Godot_v4.7-stable_win64_console.exe" `
    -CommitSha "<PR_HEAD_SHA>"
```

**Interactive checklist path:** Not applicable — M01 has no player-facing UI, editor interaction, visual, audio, A/B, persistence-file, or live Steam behavior.

The owner script must:

1. resolve the repository root from its own location;
2. accept `-GodotBin` and optional `-CommitSha` under `OWNER_VERIFICATION_WORKFLOW.md`;
3. keep Git CLI optional while rejecting a supplied/detected SHA mismatch when both exist;
4. create `tools/test/owner/logs/` and one UTF-8 `M01-owner-verification-<UTC>-<short-sha>.log`;
5. record the evidence header required by the workflow;
6. run the canonical full Windows wrapper;
7. run the focused fixed-point, monotonic, time-authority, and source-ownership tests;
8. run the headless deterministic trace;
9. record every command, meaningful output, and exit code;
10. fail nonzero if any required step fails;
11. verify that no temporary test, UID companion, save, or generated project file remains;
12. print and log the final PASS/FAIL summary and full log path.

Codex cannot mark this owner check as passed. Its handoff must say `Pending owner verification` until the owner uploads or quotes the generated log and reports the result for the tested PR head.

## Manual verification

No additional visual or editor checklist is required for M01.

The owner performs only the milestone-specific PowerShell package above, reviews that its final summary is `PASS`, and uploads the generated `.log` file in the planning conversation. The explicit owner result should use:

```text
Owner verification: PASS|FAIL — PR head <sha> — M01 Windows full/focused GUT, time-source ownership, and deterministic trace — YYYY-MM-DD.
Log: <generated filename>
Observed warnings or failures: <none or concise description>
```

## Save/load verification

M01 changes authoritative in-memory state contracts but deliberately introduces no file, byte codec, stable schema version, migration, save directory, or offline disk transaction.

Required checks:

| Scenario | Setup and save point | Reload, retry, or recovery action | Expected result |
|---|---|---|---|
| State duplication | Construct valid `GameState` and `TimeAuthorityState` | Clone/copy through project-owned typed methods if implemented | Values and ownership remain exact; no shared mutable aliasing |
| Repeated reconciliation | Commit one trusted plan | Repeat same sample/plan | Zero new elapsed; stale/repeated commit rejected |
| Interrupted future transaction seam | Create plan without commit | Discard plan and plan again from unchanged state | Same result; planning caused no mutation |

Do not write `user://` files. Do not call JSON. Do not freeze schema key spelling. If primitive debug conversion is added, mark it unstable and test-only; M02 owns the production snapshot schema.

## Documentation updates

| Document | Required update |
|---|---|
| `docs/codex/MILESTONES.md` | Record actual M01 implementation/verification stage, realized paths, fixed-point gate status, and owner package |
| `docs/codex/ARCHITECTURE.md` | Replace the open scale item with accepted `DEC-0026`; record realized planning/commit and monotonic-source seams |
| `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | Record exact scale, supported fixed-point semantics, state/status/diagnostic fields, and validated bounds |
| `docs/codex/IMPLEMENTATION_RULES.md` | Record the realized utility/service API conventions only where durable |
| `docs/codex/TESTING_AND_VALIDATION.md` | Add exact M01 focused tests, trace, owner script, and log evidence requirements |
| `docs/codex/OWNER_VERIFICATION_WORKFLOW.md` | No change expected unless implementation exposes a generic workflow defect |
| `docs/codex/DECISIONS.md` | Mark `DEC-0026` Accepted and record any narrower realized bounds without changing the approved scale |
| Design source-of-truth files | No change expected |
| `README.md` | Add concise M01 owner-verification invocation or link if it improves discoverability |
| `AGENTS.md` | No change expected |

Do not mark M01 `Merged` or verification `Passed` before those facts are true. The implementation task should use the truthful stage, normally `Pull request open` / `Partial`, while owner verification is pending.

## Stop and ask conditions

Stop before implementing or expanding the affected part when any of the following occurs:

1. M00 is not merged/passed or the canonical wrappers no longer work.
2. `DEC-0026` is not Accepted.
3. The exact scale or non-negative flow contract conflicts with an accepted requirement.
4. Correct checked arithmetic would require a new third-party dependency, native extension, arbitrary-precision library, or engine change.
5. The required final-fit/intermediate-overflow case cannot be implemented honestly with documented 64-bit operations.
6. A required method would need floating-point authoritative state or a second subsystem scale.
7. A proposed solution would read local wall time, timezone, calendar, file timestamps, registry values, Steam, or an unapproved network source.
8. A proposed solution would update the trusted anchor before the future elapsed interval is accepted for commit, or would erase foreground accounting when the trusted sample has not caught up.
9. The task would require schema versioning, JSON, disk saves, migration, backup rotation, or another M02 behavior.
10. The task would require Steam initialization or a production provider, which belongs to M06.
11. Tests expose a pre-existing harness failure that cannot be isolated safely within M01.
12. The required result cannot fit one reviewable foundation pull request without implementing later gameplay systems.
13. A new design/architecture decision beyond accepted `DEC-0026` is required.

Do not stop for ordinary local implementation choices already bounded by the prompt. Make the smallest clear choice, document it, and report it under assumptions.

Owner-run Windows checks being unavailable to Codex are not themselves a stop condition. Implement and verify the Linux scope, open the handoff for owner testing, and keep the merge gate pending.

## Deliverables

The completed task must provide:

- minimal typed `GameState` and separate `TimeAuthorityState`;
- centralized `FixedPoint` implementation using scale `1_000_000`;
- checked arithmetic and explicit residual results;
- monotonic clock contract, production adapter, and fake;
- trusted-time provider/sample contracts and fake;
- reconciliation plan/result/commit seam;
- full unit, boundary, chunking, source-ownership, and negative tests;
- deterministic headless M01 trace;
- `tools/test/owner/run_m01_owner_verification.ps1`;
- ignored generated-log path and complete owner invocation;
- synchronized architecture, data, implementation, testing, decision, milestone, and applicable README documentation;
- junior-readable comments for non-obvious numeric and time logic;
- complete changed-file inventory and exact verification evidence;
- no save implementation, Steam behavior, gameplay production, new dependency, temporary artifact, committed owner log, private path, secret, or unrelated change.

## Final response format

Use exactly these headings.

### Implementation completed

Summarize the fixed-point and time-authority result. Do not present owner-pending work as complete.

### Files changed

List every added, modified, renamed, or deleted file and its purpose. Note any expected path that changed after repository inspection and why.

### Verification

Report separately:

- Codex Cloud/Linux fixed-point, monotonic, time-authority, source-ownership, trace, and full-suite commands with versions, test counts, exit codes, and results;
- high-value arithmetic, true-overflow, unavailable, backward, mismatch, not-ahead, cap, stale-plan, repeat, and cleanup checks;
- owner script path and generated-log contract;
- owner-run Windows package as `Pending owner verification`, `Passed`, or `Failed` based only on explicit owner evidence;
- acceptance criteria that remain unverified.

### Assumptions

List only assumptions not directly established by authoritative context. Distinguish safe implementation choices from requirements.

### Known limitations and risks

State anything incomplete, provisional, environment-dependent, performance-sensitive, or not verified. Explicitly note that M01 does not yet resolve gameplay production or write saves.

### Deferred work

List disk persistence (M02), content normalization (M03), simulation production (M04), application lifecycle wiring (M05), Steam trusted-time adapter (M06), and later UI/report work as applicable.

### Suggested next task

Name M02 only after M01 merge and verification gates pass. Do not begin it.
