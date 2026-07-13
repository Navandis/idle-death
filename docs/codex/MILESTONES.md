# Death Idle Prototype Milestones

**Document role:** Approved implementation sequence and acceptance map for the 0–90 minute prototype  
**Repository path:** `docs/codex/MILESTONES.md`  
**Document status:** Phase 7 approved  
**Milestone-map revision:** 2  
**Last updated:** 2026-07-12  
**Primary context:** [Prototype source of truth](../design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md), [Idle-fork source of truth](../design/IDLE_FORK_SOURCE_OF_TRUTH.md), [Architecture](ARCHITECTURE.md), [Data contracts](DATA_AND_CONTENT_CONTRACTS.md), [Testing](TESTING_AND_VALIDATION.md), and [Decisions](DECISIONS.md)

## 1. Purpose and authority

This file divides the approved prototype architecture and first-session sequence into reviewable Codex tasks. It defines scope and acceptance, not the implementation prompt text. The owner approved this map in Phase 7. Phase 8 creates the reusable prompt template; Phase 9 creates one versioned milestone prompt at a time.

Use the source hierarchy in `AGENTS.md`. A milestone definition cannot weaken a protected design invariant or accepted decision. When repository state later differs from an assumption here, update this file and record any architecture/design decision before drafting that milestone's prompt.

## 2. Current repository baseline

At Phase 7 approval:

- Godot 4.7, GDScript, the 1920 × 1080 reference viewport, resizing/stretch settings, and a temporary dry-run main scene exist.
- `AGENTS.md`, project Codex configuration, the maintained design sources, and the architecture documents are present in the repository; this approved package supersedes their earlier draft/status wording where applicable.
- GUT 9.7.1 is committed under `addons/gut/`.
- GodotSteam GDExtension 4.20 is committed under `addons/godotsteam/`.
- Development App ID `480` is configured in `project.godot`; automatic Steam initialization is disabled.
- The repository still has no approved `.gutconfig.json`, test wrappers, initial test suite, production game-state model, content registry, simulation, persistence implementation, or gameplay UI.
- Existing dry-run assets and scene work are preserved unless a scoped milestone explicitly replaces or integrates them.

## 3. Milestone rules

Every milestone must:

1. fit one focused Codex task and reviewable pull request;
2. leave a developer-visible or player-visible demonstration;
3. add or update the applicable automated tests before completion;
4. state exactly what was and was not manually verified;
5. extend the save contract and fixtures when authoritative state changes;
6. keep provisional balance in content data;
7. avoid unrelated refactors and future-milestone systems;
8. update this status map and every maintained contract made inaccurate by the change;
9. preserve junior-readable code and comments under `AGENTS.md` and `IMPLEMENTATION_RULES.md`;
10. stop for owner approval when a listed decision gate is reached.

A milestone may be split after implementation begins only when the split preserves a demonstrable result and the dependency/status tables are updated first. Do not merge several later milestones merely because Codex can generate a large diff.

## 4. Status vocabulary

| Field | Values |
|---|---|
| Definition | Proposed, Approved, Superseded |
| Prompt | Not drafted, Drafted, Approved, Superseded |
| Implementation | Not started, In progress, Pull request open, Merged, Rework required |
| Verification | —, Partial, Passed, Failed, Blocked |

## 5. Decision and dependency gates

| Gate | Required before | Rule |
|---|---|---|
| `GATE-GUT` | M00 merge | Verify the committed GUT 9.7.1 dependency, retained license, `.gutconfig.json`, required Linux and Windows wrappers, Godot 4.7 execution, and real failure exit codes. |
| `GATE-WINDOWS-HARNESS` | M00 merge | The owner runs `tools/test/run_gut.ps1` on the separate Windows Godot machine and records the result; Codex Cloud cannot satisfy this gate. |
| `GATE-FIXED-POINT` | M01 merge | Record the centralized scale and tested numeric bounds; do not let subsystems choose different scales. |
| `GATE-SAVE-SCHEMA` | M02 merge | Freeze schema-version-1 key spelling and representative fixtures before gameplay state depends on it. |
| `GATE-STEAM-TIME` | M06 prompt/implementation | Satisfied for prompt drafting by `DEC-0024`: use pinned GodotSteam 4.20 and development App ID `480`. M06 must still verify license footprint, wrapper API, explicit initialization, and live Windows behavior. |
| `GATE-PRODUCTION-OFFLINE` | M16 merge | Fake-provider automation plus the owner-run Windows/GodotSteam connected, unavailable, reconnect, clock-change, and repeated-load checks must pass. |
| `RELEASE-GATE-STEAM-APP` | Before external Steam Playtest or commercial distribution | Replace development App ID `480` with Death Idle's assigned App ID and validate package ownership, launch-through-Steam behavior, export contents, and absence of development-only App ID aids. |
| `RELEASE-GATE-SAVE` | Before commercial release, not this prototype map | Profile realistic full-game saves and choose the final codec/threat model under `DEC-0022`. JSON may remain; binary/compression/encryption are not assumed security. |

When trusted time is unavailable, the approved behavior is to grant no guessed closed-session progress, retain pending reconciliation, and continue monotonic foreground production. No milestone may introduce a local-device-time fallback.

## 6. Milestone status map

| ID | Milestone | Definition | Prompt | Implementation | Verification |
|---|---|---|---|---|---|
| M00 | Repository, Godot, GUT, and Codex Cloud harness | Approved | Not drafted | Not started | — |
| M01 | Deterministic numeric and time-authority foundation | Approved | Not drafted | Not started | — |
| M02 | Versioned save codec and atomic storage | Approved | Not drafted | Not started | — |
| M03 | Content catalog, canonical IDs, and configurable prototype data | Approved | Not drafted | Not started | — |
| M04 | Persistent Reaping simulation vertical slice | Approved | Not drafted | Not started | — |
| M05 | Persistent application shell, navigation, and debug access | Approved | Not drafted | Not started | — |
| M06 | Steam trusted-time adapter and transactional offline resolution | Approved | Not drafted | Not started | — |
| M07 | Dialogue and save-safe tutorial orchestration framework | Approved | Not drafted | Not started | — |
| M08 | Opening sequence, scripted four returns, Brand, and first dispatch | Approved | Not drafted | Not started | — |
| M09 | Archive, Recollections, and Soulweave horizon | Approved | Not drafted | Not started | — |
| M10 | First report, Emergency-to-Standard transition, and Soldier Company | Approved | Not drafted | Not started | — |
| M11 | Scribe guarantee, player-driven awakening, and Form comparison | Approved | Not drafted | Not started | — |
| M12 | Broken Watch, minor resonance, second tether, and concurrent Reapings | Approved | Not drafted | Not started | — |
| M13 | Discovery states, hidden Provisions, and forecast confidence | Approved | Not drafted | Not started | — |
| M14 | Larder, Rations, support pressure, and graceful degradation | Approved | Not drafted | Not started | — |
| M15 | Regional 10,000 resonance, optional Recollection choice, and objectives | Approved | Not drafted | Not started | — |
| M16 | Offline forecast, welcome-back report, and guided-opening completion | Approved | Not drafted | Not started | — |
| M17 | Complete 0–90 minute integration, resilience, pacing, and acceptance pass | Approved | Not drafted | Not started | — |

## 7. Dependency sequence

```text
M00
 └─ M01
     └─ M02
         └─ M03
             └─ M04
                 └─ M05
                     ├─ M06  (approved Steam-time dependency required)
                     └─ M07
                         └─ M08
                             └─ M09
                                 └─ M10
                                     └─ M11
                                         └─ M12
                                             └─ M13
                                                 └─ M14
                                                     └─ M15
                                                         └─ M16  (also requires M06)
                                                             └─ M17
```

M06 is intentionally implemented early enough to retire the trusted-time/platform risk before the final offline-return UX. The owner has selected GodotSteam 4.20 and App ID `480` for development, so M06 prompt drafting is no longer blocked by dependency choice. M07–M15 may still use fake trusted-time sources, but M16 cannot merge until M06 and its owner-run Windows verification are complete.

## 8. Changes from the starting hypothesis

The starting M00–M13 hypothesis was useful, but this map makes several deliberate changes:

- **State/time and persistence are split.** Exact numeric/trusted-time accounting (M01) and disk codec/atomic recovery (M02) are different failure domains and are easier to review separately.
- **The content catalog precedes simulation.** M03 prevents the first production slice from hard-coding Forms, Thresholds, milestones, or guarantees.
- **The core Reaping is proven before the application shell.** M04 makes deterministic behavior testable without scenes; M05 then proves the approved lifetime and presentation boundary.
- **Trusted external time receives its own early milestone.** M06 is the sole narrow Steam exception and a dependency-risk milestone, while M16 remains the player-facing offline/report experience.
- **Dialogue/tutorial framework precedes real beats.** M07 proves save/skip/queue behavior with a mock sequence before narrative content depends on it.
- **The first-session beats are smaller vertical slices.** Archive/Soulweave, Soldier Company, Scribe, Broken Watch, discovery, Larder, and the second resonance remain separate reviewable pull requests.
- **Reports are introduced incrementally.** M04 creates the accumulator, M10 creates the first player-facing report/history behavior, and M16 completes welcome-back/offline presentation.
- **Final integration adds no major system.** M17 is an acceptance, resilience, tuning, and measurement pass rather than a container for unfinished features.

## 9. Detailed milestone definitions

### M00 — Repository, Godot, GUT, and Codex Cloud harness

**Definition status:** Approved  
**Prompt status:** Not drafted  
**Implementation status:** Not started  
**Recommended Codex task size:** Medium; one infrastructure pull request.  
**Planned prompt file:** `docs/codex/milestone-prompts/M00-repository-test-harness.md`

#### Purpose

Establish one repeatable cross-platform verification path before gameplay code begins.

#### Player or developer outcome

From a clean checkout, Codex can run the pinned suite in its Linux cloud environment, and the project owner can run the same suite on the separate Windows Godot machine through one PowerShell command. Both receive meaningful exit codes and use the same checked-in configuration.

#### Dependencies

- Approved repository guidance and architecture documents
- Existing Godot 4.7 dry-run project
- GUT 9.7.1 already committed under `addons/gut/`
- GodotSteam 4.20 already committed under `addons/godotsteam/`
- Development App ID `480` configured with automatic Steam initialization disabled

#### Included scope

- Verify and preserve the committed GUT 9.7.1 version and applicable license; do not download or replace it.
- Verify and document the committed GodotSteam 4.20 footprint and applicable license/notice files; do not initialize Steam or call Steam APIs.
- Add `.gutconfig.json`, one passing harness test, and only the shared test support immediately required.
- Create required repository wrappers:
  - `tools/test/run_gut.sh`;
  - `tools/test/run_gut.ps1`.
- Make both wrappers resolve the repository root, locate Godot through explicit argument then `GODOT_BIN` then `PATH`, require Godot 4.7.x, run clean import plus the full GUT suite by default, support documented focused execution, and propagate the real process exit code.
- Document Codex Cloud setup, Windows setup, import, full test, focused test, smoke checks, and result handoff.
- Update `.gitignore` for generated test output and logs without ignoring fixtures.
- Verify the current dry-run main scene rather than redesigning application architecture.
- Verify that the GodotSteam extension can be present during headless import and GUT runs while automatic initialization remains disabled and no Steam client is required.

#### Explicit non-goals

- Gameplay state, simulation, saves, content definitions, or production UI.
- GitHub Actions.
- Steam initialization, trusted-time calls, achievements, Steam Cloud, or any M06 behavior.
- Adding `steam_appid.txt` as a standard prerequisite.
- Replacing the temporary main scene with `GameApp`.
- Updating GUT or GodotSteam.

#### Expected files or subsystems

The exact file list remains subject to repository inspection. Expected areas are:

- `.gutconfig.json`
- `tools/test/run_gut.sh`
- `tools/test/run_gut.ps1`
- `tests/` harness and minimal support
- `.gitignore`
- `README.md`
- `docs/codex/TESTING_AND_VALIDATION.md`
- `docs/codex/MILESTONES.md`
- third-party license/notice documentation only when the committed addon footprint is incomplete or unclear

#### Data and content required

- Pinned GUT 9.7.1 and GodotSteam 4.20 metadata
- Godot 4.7 executable contract
- Development App ID `480` and disabled automatic initialization as existing configuration only

#### Acceptance criteria

- `tools/test/run_gut.sh` runs from Codex Cloud or Linux and succeeds with Godot 4.7.x.
- The owner runs `tools/test/run_gut.ps1` on the separate Windows Godot machine and records a passing result before merge.
- Both wrappers can be invoked from outside the repository root and still locate the project correctly.
- Both wrappers use the same `.gutconfig.json` and default test directories.
- The default wrapper path runs headless import and the full GUT suite.
- A deliberately failing temporary test causes a nonzero wrapper exit in Linux; the failing file is removed before final commit. Windows failure propagation is also verified or explicitly demonstrated with a safe temporary method before merge.
- A focused-test invocation is documented and works.
- The configured main scene starts and exits in a headless smoke check without new parser or resource errors.
- Commands contain no developer-specific absolute paths.
- GodotSteam remains uninitialized during M00 import and tests; no Steam client, account, network access during the test phase, or `steam_appid.txt` is required.
- The addon versions and applicable license/notice footprint are documented.

#### Automated verification

Codex Cloud or Linux:

- Run `tools/test/run_gut.sh`.
- Run the documented focused-test example.
- Run the main-scene smoke command.
- Record the detected Godot version.
- Prove nonzero failure propagation with a temporary failing test, then remove it and rerun cleanly.

Owner-run Windows:

- Run `tools/test/run_gut.ps1`.
- Record the Godot version and final exit result in the pull request.

#### Manual verification

On the Windows Godot machine:

- Open the project in Godot 4.7, let resources and GDExtensions import, and confirm no new errors.
- Run the current dry-run scene once.
- Confirm Steam is not initialized merely by importing or running GUT.

#### Demonstration path

- Clone or reset to a clean working tree in Codex Cloud and run the shell wrapper.
- Pull the same branch on the Windows Godot machine and run the PowerShell wrapper.
- Show matching test discovery, passing summaries, real exit codes, and a clean `git status` apart from intended changes.

#### Save/load expectations

No gameplay save format is introduced. Test fixtures must not write persistent user saves.

#### Documentation updates

- `README.md`
- `TESTING_AND_VALIDATION.md`
- `IMPLEMENTATION_RULES.md` only if the realized wrapper interface differs from the approved contract
- `MILESTONES.md`

#### Known risks

- Codex Cloud setup may need a pinned Godot installation step outside the repository.
- GUT 9.7.1 CLI behavior must be verified against the committed files rather than assumed from another version.
- GodotSteam native libraries may expose environment-specific load failures even when Steam is not initialized.
- The Windows gate depends on timely owner execution and cannot be completed by Codex Cloud.

#### Follow-on dependencies

- All later milestones.

---

### M01 — Deterministic numeric and time-authority foundation

**Definition status:** Approved  
**Prompt status:** Not drafted  
**Implementation status:** Not started  
**Recommended Codex task size:** Medium; one pure-foundation pull request.  
**Planned prompt file:** `docs/codex/milestone-prompts/M01-deterministic-time-foundation.md`

#### Purpose

Define exact simulation units and trusted-time accounting before any production system depends on them.

#### Player or developer outcome

A developer can advance a minimal `GameState` with explicit elapsed milliseconds, establish or withhold a trusted-time anchor, and reconcile a later trusted sample without reading the local device clock or double-crediting foreground time.

#### Dependencies

- M00

#### Included scope

- Create the minimal scene-independent `GameState` timeline required by later systems.
- Select and document one centralized 64-bit fixed-point scale with checked arithmetic and persisted residual semantics.
- Define `MonotonicClock`, `TrustedTimeProvider`, `TrustedTimeSample`, and `TimeAuthorityState` contracts.
- Implement trusted-gap accounting: first anchor, unavailable state, pending reconciliation, subtraction of foreground time already credited since the anchor, caps, diagnostics, and backward-sample rejection.
- Provide fake monotonic and trusted-time sources for tests.
- Ensure simulation-facing code accepts elapsed durations and cannot query clocks directly.

#### Explicit non-goals

- Disk files, JSON encoding, backup rotation, or migrations.
- Steam integration or any production trusted-time adapter.
- Reaping, Hall, inventory, tutorial, report, or UI behavior.
- Final offline cap or production balance.

#### Expected files or subsystems

The exact file list remains subject to repository inspection. Expected areas are:

- `src/domain/state/` minimal aggregate/time state
- `src/simulation/fixed_point.gd` or equivalent centralized utility
- `src/time/` provider interfaces and reconciliation service
- `tests/unit/simulation/` and `tests/unit/domain/`
- `tests/support/fake_monotonic_clock.gd` and `fake_trusted_time_source.gd`

#### Data and content required

- Fixed-point scale and named trusted-time statuses/diagnostic codes. These are architecture constants, not balance values.

#### Acceptance criteria

- Fixed-point operations and residuals are exact for documented prototype bounds and fail clearly on unsupported overflow.
- Foreground elapsed time is derived only from the injected monotonic source.
- No authoritative path reads device date, time, timezone, calendar, registry, or file timestamps.
- The first trusted sample creates an anchor without retroactive gains.
- When trust is unavailable, the pending interval grants nothing while foreground time remains creditable.
- On later trust restoration, `max(0, trusted_gap - foreground_already_credited)` is computed once, capped explicitly, and cannot move the anchor backward.
- Equivalent chunking produces identical time-authority and fixed-point state.

#### Automated verification

- Fixed-point boundary and overflow tests.
- Trusted-time unavailable, reconnect, rollback, cap, and repeated-sample tests.
- Source-ownership check or review test preventing authoritative local-clock calls.
- Chunking-invariance tests for the accounting service.

#### Manual verification

- Run a developer trace using fake values: establish an anchor, advance foreground time, mark trust unavailable, restore a later sample, and inspect the single uncredited interval.

#### Demonstration path

- Anchor at a known trusted value.
- Credit ten minutes of fake monotonic foreground time.
- Advance the fake trusted source by one hour.
- Show that only fifty minutes are returned for closed-session resolution and a repeated sample returns zero.

#### Save/load expectations

State classes expose explicit primitive conversion hooks where useful, but no file or stable schema is committed until M02.

#### Documentation updates

- `ARCHITECTURE.md`, `DATA_AND_CONTENT_CONTRACTS.md`, `IMPLEMENTATION_RULES.md`, `TESTING_AND_VALIDATION.md`, `DECISIONS.md` if the fixed-point scale changes the approved contract, and `MILESTONES.md`.

#### Known risks

- Incorrect anchor updates can lose or duplicate time.
- Fixed-point bounds that are too small can force later migration; bounds must be documented conservatively.

#### Follow-on dependencies

- M02, M04, M06, M16.

---

### M02 — Versioned save codec and atomic storage

**Definition status:** Approved  
**Prompt status:** Not drafted  
**Implementation status:** Not started  
**Recommended Codex task size:** Medium; one persistence pull request.  
**Planned prompt file:** `docs/codex/milestone-prompts/M02-save-codec-atomic-storage.md`

#### Purpose

Make exact, recoverable, migration-ready persistence available before gameplay state expands.

#### Player or developer outcome

A minimal authoritative state, including trusted-time accounting, round-trips through a schema-controlled JSON codec; interrupted or corrupt writes retain at least one valid recoverable snapshot.

#### Dependencies

- M01

#### Included scope

- Define save schema version 1 and exact key spelling for the minimal state envelope.
- Separate runtime state, primitive snapshot schema, payload codec, and storage transaction.
- Implement the prototype `SaveCodec` using JSON with canonical decimal strings for all authoritative integers.
- Implement primary, temporary, and backup storage with reopen/parse/full-validation before replacement.
- Select the highest valid save revision and add a sequential migration seam with fixtures.
- Add explicit corruption diagnostics and preserve suspect files for recovery.
- Document that the JSON codec is not an anti-tamper boundary and can later be replaced without changing domain ownership.

#### Explicit non-goals

- Encryption, obfuscation, DRM, Steam Cloud, accounts, or server authority.
- Full gameplay schema. Later milestones extend versioned substate fields through the same contract.
- Multiple player slots or final file names.
- A binary codec without measured need.

#### Expected files or subsystems

The exact file list remains subject to repository inspection. Expected areas are:

- `src/persistence/save_codec.gd`, JSON codec, schema mapper, validation, storage abstraction, and file storage
- Schema version and migration files
- `tests/unit/persistence/`, `tests/integration/save_load/`, and save fixtures
- Documentation of the prototype save directory and reset procedure

#### Data and content required

- `codec_id`, schema version, content revision placeholder, save revision, `TimeAuthorityState`, minimal `GameState`, and transaction metadata.

#### Acceptance criteria

- Values at and beyond `2^53`, representative trusted epoch values, signed 64-bit limits, and fixed-point residuals round-trip exactly.
- Malformed or numeric JSON values for authoritative integer fields are rejected rather than coerced.
- A valid backup loads when the primary is corrupt or truncated.
- Failure at every documented atomic-write step leaves at least one valid committed snapshot.
- An unsupported future schema or unknown codec is reported without overwriting existing files.
- Loading or saving never derives production from file modification time or device wall time.
- Domain-state round-trip tests do not depend on JSON-specific code.

#### Automated verification

- Primitive-state round trip.
- JSON byte-codec round trip and malformed-input matrix.
- Primary/backup revision selection.
- Atomic failure injection.
- Migration fixture smoke test.
- Time-authority state round trip and interrupted reconciliation transaction.

#### Manual verification

- Create a save, copy it, corrupt the primary deliberately, relaunch, and confirm the backup is selected with a visible diagnostic while the invalid file is retained.

#### Demonstration path

- Write revision 1.
- Write revision 2 through the atomic path.
- Corrupt the primary.
- Load revision 1 backup successfully and show the diagnostic.

#### Save/load expectations

This milestone establishes schema version 1, codec ID, transaction rules, and backup behavior. All later authoritative state must extend this schema and add fixtures/tests.

#### Documentation updates

- `ARCHITECTURE.md`, `DATA_AND_CONTENT_CONTRACTS.md`, `IMPLEMENTATION_RULES.md`, `TESTING_AND_VALIDATION.md`, and `MILESTONES.md`.

#### Known risks

- Windows rename and file-lock behavior.
- Accidentally coupling migrations to JSON instead of primitive schema.
- Misleading checksum or encryption language.

#### Follow-on dependencies

- M03 onward.

---

### M03 — Content catalog, canonical IDs, and configurable prototype data

**Definition status:** Approved  
**Prompt status:** Not drafted  
**Implementation status:** Not started  
**Recommended Codex task size:** Medium; one content-foundation pull request.  
**Planned prompt file:** `docs/codex/milestone-prompts/M03-content-catalog-prototype-data.md`

#### Purpose

Create the typed authored-data layer and validation grammar before systems hard-code prototype content.

#### Player or developer outcome

The Godot editor loads one explicit prototype catalog containing the approved Forms, Thresholds, Writs, Retinue, Halls, recipe, resources, Recollections, milestones, guarantees, resonances, narrative IDs, and tutorial IDs; invalid catalogs fail with actionable diagnostics.

#### Dependencies

- M02

#### Included scope

- Implement typed custom Resource definitions and an explicit `ContentCatalog`.
- Implement `ContentRegistry` normalization, canonical ordering, ID-prefix checks, reference validation, and immutable runtime lookup tables.
- Implement only the finite modifier and progression-effect operations already required by the prototype.
- Author the established prototype IDs and centralized provisional values from `DATA_AND_CONTENT_CONTRACTS.md`.
- Assign and persist a content revision used by save validation.
- Provide minimal fixture catalogs for focused tests.

#### Explicit non-goals

- Functional implementation of all thirty Forms or their Arts.
- Final balance, final narrative text, final assets, or localization pipeline.
- Recursive directory discovery or arbitrary expression/script execution from content.
- Player-facing screens.

#### Expected files or subsystems

The exact file list remains subject to repository inspection. Expected areas are:

- `src/content/definitions/`, registry, validation, and normalization
- `content/prototype_content_catalog.tres` and referenced `.tres` definitions
- Fixture catalogs and content-validation tests
- Optional placeholder presentation references only when files already exist

#### Data and content required

- All canonical IDs in the current contract, including `RECIPE_...`, `MS_...`, `GUA_...`, and `RESONANCE_...`; Man-at-Arms and Scribe are the only functional Form definitions.

#### Acceptance criteria

- The valid catalog loads in deterministic canonical order.
- Duplicate IDs, wrong prefixes, missing references, unsupported effects, invalid reservation requirements, and invalid recipe references fail clearly.
- Provisional rates, costs, coefficients, durations, and floors exist in content data rather than UI or tutorial code.
- Man-at-Arms and Scribe behavior can be distinguished from data without branching on display name.
- A save records and validates the content revision without serializing immutable definition data.

#### Automated verification

- Valid and invalid catalog suites.
- Stable-order tests.
- Modifier/effect grammar validation.
- Save content-revision compatibility test.

#### Manual verification

- Open representative `.tres` definitions in the Godot Inspector and confirm that a provisional value can be changed without editing code.

#### Demonstration path

- Load the valid catalog and print a deterministic summary.
- Swap in an invalid duplicate-ID fixture and show the actionable failure.
- Change one provisional fixture rate and show normalized runtime data changing.

#### Save/load expectations

Saves reference definitions only by canonical ID and record content revision. Unknown required IDs reject a save before simulation.

#### Documentation updates

- `DATA_AND_CONTENT_CONTRACTS.md`, `ARCHITECTURE.md`, source-of-truth files if a content ID changes, and `MILESTONES.md`.

#### Known risks

- Godot Resource circular references or editor import ordering.
- Overbuilding a generic rules engine.
- Treating display names as keys.

#### Follow-on dependencies

- M04 and all content-driven milestones.

---

### M04 — Persistent Reaping simulation vertical slice

**Definition status:** Approved  
**Prompt status:** Not drafted  
**Implementation status:** Not started  
**Recommended Codex task size:** Medium-large but bounded to one operation and three core streams.  
**Planned prompt file:** `docs/codex/milestone-prompts/M04-persistent-reaping-simulation.md`

#### Purpose

Prove the core idle machinery before narrative and production UI are layered over it.

#### Player or developer outcome

Through tests and a developer harness, one Gloamwood Reaping led by Man-at-Arms persists across updates, auto-banks backlog progress, Corrupted Essence, and Mastery, produces report deltas, forecasts the same rules on a clone, and survives save/load.

#### Dependencies

- M01
- M02
- M03

#### Included scope

- Implement scene-independent Threshold, Form, Reaping, inventory, progression-counter, and report-accumulator runtime state needed for one operation.
- Implement dispatch validation, one tether, one Reaping per Threshold, and assignment revision.
- Implement the global segmented `SimulationEngine` for one active Reaping with independent backlog, Essence, Mastery, and configured prototype channels.
- Implement live, supplied-duration offline, forecast-clone, and debug-advance modes through the same resolver.
- Implement stable boundary ordering, fixed-point residuals, zero-duration loop protection, and aggregate report deltas.
- Extend schema version 1 and save fixtures for the new state.

#### Explicit non-goals

- Opening narrative, direct four-soul action, tutorial UI, Archive, Retinues, Halls, second Threshold, discovery presentation, or Steam adapter.
- Final production formula or balance.
- Player-facing report screen.

#### Expected files or subsystems

The exact file list remains subject to repository inspection. Expected areas are:

- `src/domain/state/` Reaping-related state
- `src/domain/services/` dispatch and inventory services
- `src/simulation/simulation_engine.gd`, rate plans, boundary helpers, result/trace types
- Report accumulator and forecast service foundation
- Simulation, persistence, and integration tests
- Developer runner or debug command that does not create a second formula

#### Data and content required

- `FORM_MAN_AT_ARMS`, `THR_GLOAMWOOD`, `WRIT_STANDARD`, Corrupted Essence, Mastery, and a small test channel configuration.

#### Acceptance criteria

- One valid dispatch occupies one tether and persists until an explicit assignment change.
- Resolving one interval or equivalent chunks yields identical authoritative state.
- Backlog, Essence, Mastery, and each configured channel resolve independently and auto-bank immediately.
- Forecast from a clone does not mutate baseline state and matches a committed supplied-duration run.
- Opening or clearing a report accumulator is not required to receive output.
- Save/load preserves operation, residuals, counters, inventory, and report accumulator exactly.
- No screen, Node path, rendered frame, or clock read is required by domain or simulation tests.

#### Automated verification

- Repeatability, chunking, online/offline/forecast equivalence.
- Dispatch/capacity tests.
- Independent-channel and report-banking tests.
- Save round trip with residuals.
- Stable ordering and zero-time-loop tests.

#### Manual verification

- Run the developer harness, advance by a known interval, inspect exact state and report deltas, save/reload, and advance again.

#### Demonstration path

- Dispatch Gloamwood through a debug command.
- Show backlog, Essence, and Mastery changing.
- Open another temporary screen or leave the harness view while advancing.
- Forecast one hour, commit the same supplied interval on a clone, and compare exact results.

#### Save/load expectations

Schema version 1 gains Reaping, Threshold, inventory, progression, and report fields with representative fixtures and migrations/reset policy documented.

#### Documentation updates

- `ARCHITECTURE.md`, `DATA_AND_CONTENT_CONTRACTS.md`, `TESTING_AND_VALIDATION.md`, and `MILESTONES.md`.

#### Known risks

- Boundary logic can become too generic too early.
- Float leakage or unsorted iteration can break equivalence.
- Developer harness could accidentally become an alternate rules path.

#### Follow-on dependencies

- M05, M06, M08, and every later gameplay milestone.

---

### M05 — Persistent application shell, navigation, and debug access

**Definition status:** Approved  
**Prompt status:** Not drafted  
**Implementation status:** Not started  
**Recommended Codex task size:** Medium; one application-shell pull request.  
**Planned prompt file:** `docs/codex/milestone-prompts/M05-application-shell-navigation-debug.md`

#### Purpose

Give the simulation a stable Godot lifetime and a minimal resizable presentation surface without transferring authority into scenes.

#### Player or developer outcome

The project launches into a persistent `GameApp` root, shows a minimal Domain shell, navigates among placeholder screens, exposes developer state/debug controls in debug builds, and keeps one Reaping running while screens change.

#### Dependencies

- M04

#### Included scope

- Replace the temporary main scene with the approved persistent `GameApp` root while preserving existing dry-run assets where useful.
- Compose one `GameSession`, screen router/host, persistent HUD region, overlay hosts, and debug-only layer.
- Add minimal Domain, map, and Threshold placeholder screens backed by read-only view models.
- Wire monotonic foreground updates, startup load/new-game choice, focus/save hooks that do not yet require the production trusted provider, and clean shutdown.
- Add debug commands for supplied-duration advance, state inspection, fixture load, save/load, and reset through normal services.
- Verify reference resolution and ordinary window resizing.

#### Explicit non-goals

- Final visual design, dialogue, tutorial, map art, complete screens, or accessibility polish.
- Gameplay autoloads.
- Steam integration or trusted closed-session credit.
- New simulation formulas.

#### Expected files or subsystems

The exact file list remains subject to repository inspection. Expected areas are:

- `src/presentation/game_app.tscn` and script
- `src/app/game_session.gd` composition
- Screen router, placeholder screens, view models, HUD/overlay hosts
- `src/debug/` panel and commands
- Main-scene project setting update
- Presentation and smoke tests where practical

#### Data and content required

- Only labels and placeholder state required to display the M04 operation.

#### Acceptance criteria

- Exactly one `GameSession` owns authoritative state for the application session.
- Changing screens does not recreate, pause, or duplicate the active Reaping.
- Presentation receives committed read models and cannot mutate state directly.
- No gameplay autoload is added.
- Debug controls call normal command/simulation/save paths and are unavailable in release builds.
- The shell remains usable at 1920×1080, 1600×900, 1366×768, and a manually resized non-16:9 window.

#### Automated verification

- Main-scene smoke.
- Session-singleton lifetime test or integration assertion.
- Navigation while supplied time advances.
- Release/debug guard test for debug controls.

#### Manual verification

- Navigate repeatedly while observing production, resize the window, save/reload, and confirm no duplicate session or parser errors.

#### Demonstration path

- Start one Reaping from a fixture.
- Navigate Domain → map → Threshold → Domain.
- Advance time from the debug panel and show one continuous authoritative total.
- Resize the window and reload the save.

#### Save/load expectations

Startup and shutdown use M02 storage. Current screen, hover, and animation state are not authoritative or required to restore.

#### Documentation updates

- `ARCHITECTURE.md`, `IMPLEMENTATION_RULES.md`, `TESTING_AND_VALIDATION.md`, `README.md`, and `MILESTONES.md`.

#### Known risks

- A large `GameSession` or hidden global references.
- UI refresh loops that become authoritative.
- Debug tools bypassing validation.

#### Follow-on dependencies

- M06, M07, and all player-facing milestones.

---

### M06 — Steam trusted-time adapter and transactional offline resolution

**Definition status:** Approved  
**Prompt status:** Not drafted  
**Implementation status:** Not started  
**Recommended Codex task size:** Medium with mandatory owner-run Windows integration checks.  
**Planned prompt file:** `docs/codex/milestone-prompts/M06-steam-trusted-time-adapter.md`

#### Purpose

Implement the selected Steam-backed trusted-time boundary and prove safe transactional closed-session reconciliation without allowing platform code into simulation.

#### Player or developer outcome

On Windows through the pinned GodotSteam 4.20 bridge, the application accepts Steam server time only when an appropriate live connection exists, resolves one pending closed-session interval transactionally, ignores local clock changes, and defers rewards safely when trust is unavailable. Headless tests continue to use fakes.

#### Dependencies

- M00
- M05
- `DEC-0021`, `DEC-0023`, and `DEC-0024`
- GodotSteam 4.20 already committed under `addons/godotsteam/`
- Development App ID `480` already configured with automatic initialization disabled

#### Included scope

- Inspect the pinned GodotSteam 4.20 API and document the exact GDScript methods and callbacks used; do not guess from another release.
- Implement a narrow project-owned Steam bridge and `TrustedTimeProvider` adapter at the platform/application boundary.
- Initialize Steam explicitly through that adapter; keep project-wide automatic initialization disabled.
- Require live-connection behavior equivalent to `ISteamUser::BLoggedOn()` before accepting a sample.
- Obtain server epoch behavior equivalent to `ISteamUtils::GetServerRealTime()` and normalize it to integer milliseconds.
- Keep domain, simulation, save-schema meaning, and fake-provider tests platform-independent.
- Integrate startup, controlled reconnect, focus regain, and graceful quit with working-clone offline resolution and atomic commit.
- Expose minimal diagnostic and pending status in the debug UI.
- Implement unavailable, reconnect, stale/backward sample, cap, and repeated-load behavior.
- Add a fake Steam bridge so adapter logic can be automated without Steam.
- Document the exact owner-run Windows validation procedure and the Codex Cloud fake-provider path.
- Verify the applicable GodotSteam license/notice footprint and record version `4.20` in third-party documentation.

#### Explicit non-goals

- Achievements, Steam Cloud, DRM, depots, rich presence, leaderboards, Workshop, networking, or other Steam APIs.
- Custom backend or always-online requirement.
- Player-facing welcome-back presentation; M16 owns that UX.
- Death Idle's production App ID, package ownership, external Playtest distribution, or launch-through-Steam validation.
- Adding `steam_appid.txt` by default.
- Claims of protection against a patched client or spoofed platform calls.

#### Expected files or subsystems

The exact file list remains subject to repository inspection. Expected areas are:

- Platform Steam bridge and trusted-time adapter
- Composition and lifecycle wiring
- Debug trusted-time status
- Fake provider and fake bridge tests
- Persistence/offline transaction integration tests
- Windows manual-test documentation
- Third-party notice or dependency documentation when needed

#### Data and content required

- Stable source ID `STEAM_SERVER_TIME`
- Trusted sample status and diagnostic codes
- Persisted anchor fields
- Configurable offline cap supporting at least eight hours
- Existing development App ID `480` configuration

#### Acceptance criteria

- No authoritative offline calculation reads the device wall clock, timezone, calendar, registry, file timestamps, or manually supplied time.
- The adapter uses the pinned GodotSteam 4.20 API and records the exact wrapper methods used.
- Steam is initialized explicitly by the adapter; automatic project initialization remains disabled.
- A trusted sample is accepted only when initialization succeeds and the bridge reports live-connection semantics equivalent to `ISteamUser::BLoggedOn()`.
- Accepted server time uses semantics equivalent to `ISteamUtils::GetServerRealTime()` and is normalized deterministically.
- Without a trusted sample, the last committed save loads, foreground production continues, and no guessed closed-session reward is granted.
- On reconnect, already-credited foreground time is subtracted and the remaining eligible interval commits exactly once.
- Changing Windows date, time, timezone, or daylight-saving configuration does not change credited progress.
- A backward, stale, contradictory, disconnected, or failed sample moves no anchor and grants no progress.
- Codex Cloud and unit tests require neither Steam nor a live platform session.
- Development testing works from the project App ID setting without a committed `steam_appid.txt`. If one specific launch path requires a local file, that exception is documented, ignored, and excluded from exports.

#### Automated verification

Codex Cloud/Linux:

- Provider-contract tests with fake samples.
- Adapter tests against a fake Steam bridge covering init, connected, disconnected, sample failure, and method-result normalization.
- Interrupted offline transaction tests.
- Unavailable/reconnect/rollback/cap/duplicate tests.
- Headless import and GUT checks proving Steam is not initialized or required.

Owner-run Windows automation:

- Run `tools/test/run_gut.ps1` before the live checklist.

#### Manual verification

On the Windows Godot machine, run the M06 checklist in `TESTING_AND_VALIDATION.md`:

- GodotSteam load under Godot 4.7;
- App ID `480` initialization;
- connected sample;
- disconnected or Offline Mode behavior;
- reconnect and exactly-once reconciliation;
- local clock and timezone changes;
- repeated loads;
- explicit confirmation that no standard `steam_appid.txt` prerequisite was used.

Record Godot version, GodotSteam version, App ID, connection state, and exact results.

#### Demonstration path

- Save an active M04 Reaping with a trusted anchor.
- Close and relaunch after a short interval with Steam connected; show one credited result.
- Repeat with Steam unavailable; show pending state and no closed credit.
- Reconnect, reconcile once, then reload and show zero duplicate credit.
- Change the local Windows clock and show no change in credited time.

#### Save/load expectations

The trusted anchor, simulation time at anchor, foreground credited since anchor, pending flag, source ID, diagnostic, and offline transaction ID persist and are atomically updated.

#### Documentation updates

- `AGENTS.md`
- `ARCHITECTURE.md`
- `DATA_AND_CONTENT_CONTRACTS.md`
- `IMPLEMENTATION_RULES.md`
- `TESTING_AND_VALIDATION.md`
- `DECISIONS.md` only if the realized API requires a semantic change
- third-party notices
- `MILESTONES.md`

#### Known risks

- Native library loading differences between Windows and Linux.
- GodotSteam wrapper behavior or callback requirements differing from assumptions.
- Steam Offline Mode and reconnect behavior.
- Platform calls accidentally leaking into domain code.
- Manual validation cannot be completed by Codex Cloud alone.
- App ID `480` does not prove Death Idle package or distribution configuration.

#### Follow-on dependencies

- M16 actual welcome-back flow and every release build.

---

### M07 — Dialogue and save-safe tutorial orchestration framework

**Definition status:** Approved  
**Prompt status:** Not drafted  
**Implementation status:** Not started  
**Recommended Codex task size:** Medium; one orchestration-framework pull request.  
**Planned prompt file:** `docs/codex/milestone-prompts/M07-dialogue-tutorial-framework.md`

#### Purpose

Build reusable presentation orchestration before encoding the actual first-session beats.

#### Player or developer outcome

A small mock sequence demonstrates lower-third dialogue, state-based tutorial guidance, one blocking item at a time, narrative skip, conservative mechanical-guidance skip, Help replay, save/resume, and uninterrupted production.

#### Dependencies

- M05

#### Included scope

- Implement dialogue data/presentation, speaker portrait slot, advance, auto, skip, text-speed, and voice-toggle placeholders.
- Implement `TutorialCoordinator` as an observer/requester of normal commands rather than an owner of domain state.
- Implement persisted tutorial state, shown/skipped/help flags, deterministic pending-notice reconstruction, and one-blocking-item selection.
- Implement narrative skip through idempotent scripted commands.
- Implement mechanical guidance skip as dismissal plus Help entry, never an automatic cost-bearing choice.
- Create a deliberately small mock sequence and integration tests while M04 production continues.

#### Explicit non-goals

- Final opening script, voice acting, final portraits, all fourteen production tutorial states, or final visual polish.
- Automatic Scribe awakening or any other skipped strategic choice.
- Inventory, Reaping, Form, Retinue, Hall, or milestone rules inside tutorial code.

#### Expected files or subsystems

The exact file list remains subject to repository inspection. Expected areas are:

- `src/tutorial/` coordinator/state/read models
- Dialogue sequence definitions and overlay scene
- Tutorial overlay/highlight/help components
- Mock content and integration fixtures
- Save schema extension and tests

#### Data and content required

- Mock dialogue/tutorial IDs plus the canonical tutorial-state grammar. Production sequences are authored in later milestones.

#### Acceptance criteria

- Only one blocking dialogue/tutorial presentation can be active; later items remain reconstructible.
- Closing and reloading mid-sequence resumes from authoritative state without repeating scripted grants.
- Narrative skip reaches the same required mock world state exactly once.
- Mechanical guidance skip does not buy, awaken, dispatch, spend, reserve, or grant a strategic choice.
- Production and foreground time continue while dialogue, Help, or tutorial overlays are open.
- The coordinator calls normal commands and contains no duplicate resource logic.

#### Automated verification

- Tutorial state persistence and pending reconstruction.
- Narrative-skip idempotency.
- Mechanical-skip no-domain-mutation test.
- Production-continues-under-overlay integration test.

#### Manual verification

- Run the mock sequence normally, skip it, close/reload mid-line, open Help replay, and observe continuing production.

#### Demonstration path

- Start the mock sequence over an active Reaping.
- Advance one step, save, reload, and resume.
- Skip a narrative step and inspect equivalent world state.
- Dismiss mechanical guidance and show the required action remains for the player.

#### Save/load expectations

Tutorial, story checkpoint, skip/help, and presented-notice fields persist. Transient UI queues are rebuilt, not saved as Node state.

#### Documentation updates

- `ARCHITECTURE.md`, `DATA_AND_CONTENT_CONTRACTS.md`, `TESTING_AND_VALIDATION.md`, and `MILESTONES.md`.

#### Known risks

- Tutorial callbacks mutating domain state.
- Transient queue loss after reload.
- Framework scope expanding before real beats exercise it.

#### Follow-on dependencies

- M08 through M17.

---

### M08 — Opening sequence, scripted four returns, Brand, and first dispatch

**Definition status:** Approved  
**Prompt status:** Not drafted  
**Implementation status:** Not started  
**Recommended Codex task size:** Medium-large but limited to Beats 1–4.  
**Planned prompt file:** `docs/codex/milestone-prompts/M08-opening-first-dispatch.md`

#### Purpose

Deliver Beats 1–4 as the first player-visible vertical slice.

#### Player or developer outcome

A new game moves from Death waking to the one-time `1,000,000 → 999,996` action, introduces Eustace and the first Man-at-Arms, applies the Brand, and dispatches an Emergency Reaping that continues behind other presentation.

#### Dependencies

- M04
- M07

#### Included scope

- Author and present `TUT_00_BOOT` through `TUT_04_FIRST_DISPATCH`.
- Implement the one-time `Reach Through the Threshold` command and exact four-return transaction.
- Persist Death, Eustace, rat, wolf, Man-at-Arms, seal/chain, and Brand story state needed by later beats.
- Awaken Man-at-Arms through the approved narrative exception.
- Configure and dispatch the existing Reaping runtime with `WRIT_EMERGENCY_FIRST_RETURN`.
- Implement minimal Sanctum, window, Gloamwood first-visit, Threshold configuration, and placeholder overlay/audio hooks.
- Use pacing instrumentation without hard-coding real-time unlock timers.

#### Explicit non-goals

- Archive, Soulweave, Soldier Company, Scribe, Broken Watch, Larder, final dialogue, voice, or final assets.
- A repeatable direct Reap button.
- Counting the scripted four toward persistent-Reaping or regional milestones.

#### Expected files or subsystems

The exact file list remains subject to repository inspection. Expected areas are:

- Opening dialogue/tutorial content
- Sanctum/window and minimal Gloamwood/Threshold presentation
- Opening/Brand/domain commands and story state
- Emergency dispatch wiring
- Assets or explicit placeholders
- Opening integration and save fixtures

#### Data and content required

- Canonical character/dialogue/tutorial IDs, Gloamwood initial backlog, Man-at-Arms, Emergency Writ, and one tether.

#### Acceptance criteria

- First input is available within the pacing target under the configured prototype content.
- The direct action executes once, removes itself permanently, and leaves backlog exactly `999,996`.
- Scripted returns equal four while all persistent-Reaping and regional counters remain zero.
- Skipping or reloading the narrative reaches the same persistent story state without repeating the four.
- Man-at-Arms is awakened through Brand with no Form Soul cost.
- The Emergency Reaping begins with one tether and continues while dialogue or another screen is open.
- Save/load works at every tutorial-state boundary in this slice.

#### Automated verification

- Opening-four exclusion and one-time command tests.
- Narrative skip/reload fixtures.
- Brand exception and dispatch tests.
- Production-under-dialogue integration test.

#### Manual verification

- Play from new game through first dispatch, then repeat using skip and one mid-dialogue quit/reload. Record observed first-input and dispatch times.

#### Demonstration path

- New game.
- Advance/focus the window.
- Execute the one-time direct action and observe the exact decrement.
- Skip or play the return dialogue.
- Brand Man-at-Arms and dispatch the Emergency Reaping.
- Open another screen and show progress continuing.

#### Save/load expectations

Checkpoint after every tutorial transition, the four-return transaction, Brand completion, Man-at-Arms awakening, and dispatch. Repeated load cannot replay irreversible actions.

#### Documentation updates

- `PROTOTYPE_0_90_SOURCE_OF_TRUTH.md` only if approved behavior changes, content contracts, tests, and `MILESTONES.md`.

#### Known risks

- Pacing depends on provisional dialogue and rate data.
- Presentation could accidentally become the only trigger for story state.
- Existing placeholder assets may not fit final composition.

#### Follow-on dependencies

- M09 and all later beats.

---

### M09 — Archive, Recollections, and Soulweave horizon

**Definition status:** Approved  
**Prompt status:** Not drafted  
**Implementation status:** Not started  
**Recommended Codex task size:** Medium; one Beat-5 pull request.  
**Planned prompt file:** `docs/codex/milestone-prompts/M09-archive-recollections-soulweave.md`

#### Purpose

Deliver Beat 5 and expose the long-term Form structure without implementing future Forms.

#### Player or developer outcome

The player converts the frayed rat/wolf result into the configured Essence event, restores the Archive with Eustace as Keeper, purchases The Weave Remembered, opens a thirty-position Soulweave, and inspects Man-at-Arms Trait, slots, Mastery, and locked Art placeholders while the Reaping continues.

#### Dependencies

- M08

#### Included scope

- Author `TUT_05_ARCHIVE` and `TUT_06_SOULWEAVE`.
- Implement Archive restoration and Recollection purchase through normal services and secured mandatory cost floors.
- Represent Eustace as the unique prototype Keeper without adding Keeper optimization.
- Implement the fixed 8→7→6→5→4 Soulweave topology as presentation/content data.
- Implement Form detail for Man-at-Arms and veiled placeholders; show three locked Art positions without Art behavior.
- Expose live Mastery from M04 and verify Emergency completion can queue while Soulweave is open.

#### Explicit non-goals

- Functional Forms beyond Man-at-Arms and Scribe.
- Form Arts, advanced Codex, Keeper assignment systems, final art, or Scribe awakening.
- A separate production formula in the Soulweave UI.

#### Expected files or subsystems

The exact file list remains subject to repository inspection. Expected areas are:

- Archive/Recollections screen and services
- Soulweave topology data, scene, and Form detail view model
- Mandatory-cost guarantee definitions/effects
- Tutorial/dialogue content and tests
- Save schema additions for Halls/Recollections if not already present

#### Data and content required

- `HALL_ARCHIVE`, `REC_WEAVE_REMEMBERED`, `GUA_ARCHIVE_WEAVE_COST_FLOOR`, thirty topology positions/threads, and Man-at-Arms detail.

#### Acceptance criteria

- Archive restoration and Weave purchase validate and consume only available resources through domain services.
- The cost floor grants or secures only the missing amount and is idempotent.
- The Soulweave shows all thirty positions and correct ancestry threads, but only approved prototype Forms can become functional.
- Man-at-Arms displays data-driven Trait, slot profile, current Mastery, and locked Art placeholders.
- Production and queued Emergency completion continue while Archive/Soulweave screens are open.
- Save/load preserves restoration, purchase, Keeper/story state, screen unlock, and Mastery.

#### Automated verification

- Cost-floor top-up/idempotency.
- Recollection purchase exactly once.
- Soulweave topology/reference validation.
- Emergency-completes-while-screen-open integration test.
- Save round trip.

#### Manual verification

- Restore Archive, buy Weave, inspect the full topology and Man-at-Arms detail, leave the screen open across a production boundary, and reload.

#### Demonstration path

- Reach the Archive beat.
- Restore it and purchase The Weave Remembered.
- Open Soulweave, inspect the horizon, and show live Mastery.
- Let the Reaping cross a boundary without interruption.

#### Save/load expectations

Checkpoint after Archive restoration, Recollection purchase, tutorial transitions, and any queued report/unlock event.

#### Documentation updates

- Content contracts, tests, and `MILESTONES.md`; design source only for approved sequence changes.

#### Known risks

- Thirty-node layout readability at smaller resolutions.
- Topology data accidentally implying functional future content.
- Mandatory cost protection duplicated in tutorial code.

#### Follow-on dependencies

- M10 and M11.

---

### M10 — First report, Emergency-to-Standard transition, and Soldier Company

**Definition status:** Approved  
**Prompt status:** Not drafted  
**Implementation status:** Not started  
**Recommended Codex task size:** Medium-large but bounded to Beat 6 and one Retinue.  
**Planned prompt file:** `docs/codex/milestone-prompts/M10-first-report-soldier-company.md`

#### Purpose

Complete the first operation loop and prove reserved Calling Soul support.

#### Player or developer outcome

At 1,000 post-dispatch Gloamwood returns, the same Reaping transitions seamlessly to Standard, all output is already banked, the first report summarizes it, Soldier Souls top up to twelve, The Muster Remembered unlocks Retinues, and the player fields/removes Soldier Company without consuming its Souls.

#### Dependencies

- M09

#### Included scope

- Author `TUT_07_RETINUE` and first report presentation.
- Implement the 1,000 milestone, Emergency-to-Standard state boundary, Essence floor, and Soldier top-up.
- Implement report snapshot/history behavior needed by the first report.
- Implement The Muster Remembered and Retinue-system unlock.
- Implement slot compatibility, one Soldier Company card, twelve-Soul reservation ledger, assignment/removal, modifier trace, and simple forecast delta.
- Introduce configured Ration pressure and reduced-effect state in domain/simulation, using a temporary onboarding buffer where required; M14 adds the producer chain.

#### Explicit non-goals

- Calling Soul attrition, service turnover, relief, scattering, additional Retinues, Armaments, or Hall production.
- Stopping and redispatching the Reaping at 1,000.
- Claim-gated reports.

#### Expected files or subsystems

The exact file list remains subject to repository inspection. Expected areas are:

- Milestone/progression effects
- Report screen/view model/history
- Retinue definitions/state/service and picker
- Reservation ledger UI
- Support-state foundation and tests
- Tutorial/dialogue content and save fixtures

#### Data and content required

- `MS_GLOAMWOOD_REAPING_1000`, `WRIT_EMERGENCY_FIRST_RETURN → WRIT_STANDARD`, `GUA_SOLDIER_SOULS_12`, `GUA_MUSTER_COST_FLOOR`, `REC_MUSTER_REMEMBERED`, `RET_SOLDIER_COMPANY`, `SOUL_CALLING_SOLDIER`, and provisional support/effect data.

#### Acceptance criteria

- The same Reaping runtime, tether, Threshold, Form, Mastery, residuals, and report accumulator survive the Writ transition.
- Remaining elapsed time after the 1,000 boundary resolves under Standard behavior.
- Inventory and progress were committed before the report opens; dismissing or clearing it changes no gain.
- The Soldier guarantee tops up only to twelve and records completion even when no grant is needed.
- Fielding reserves exactly twelve owned Souls; removal releases the same reservation; no Soul is consumed or recreated.
- The forecast shows a data-driven before/after effect and future Ration pressure.
- Repeated load cannot duplicate the report, Writ transition, guarantee, Muster purchase, or reservation.

#### Automated verification

- Emergency continuity boundary test.
- Report-versus-inventory integrity.
- Guarantee and exactly-once tests.
- Reservation create/release/save tests.
- Support reduced-floor test with base production continuing.

#### Manual verification

- Cross 1,000 with Archive/Soulweave open, inspect the queued report, purchase Muster, field/remove/re-field Soldier Company, and reload at each step.

#### Demonstration path

- Let the Emergency Reaping cross 1,000.
- Show it never stops and now uses Standard.
- Open the already-bank-ready report.
- Unlock and field Soldier Company; compare owned/reserved/available and forecast.

#### Save/load expectations

Checkpoint at milestone, Writ transition, guarantee, report snapshot/archive, Recollection purchase, Retinue assignment/removal, and tutorial state.

#### Documentation updates

- `DATA_AND_CONTENT_CONTRACTS.md`, `TESTING_AND_VALIDATION.md`, and `MILESTONES.md`; source-of-truth only if approved behavior changes.

#### Known risks

- Old beat wording may tempt a stop/redispatch implementation.
- Reservation UI may mislabel owned versus available.
- Support behavior may become overbuilt before Larder exists.

#### Follow-on dependencies

- M11, M12, M14.

---

### M11 — Scribe guarantee, player-driven awakening, and Form comparison

**Definition status:** Approved  
**Prompt status:** Not drafted  
**Implementation status:** Not started  
**Recommended Codex task size:** Small-medium; one Beat-7 pull request.  
**Planned prompt file:** `docs/codex/milestone-prompts/M11-scribe-awakening-form-comparison.md`

#### Purpose

Deliver Beat 7 and establish that Forms are qualitatively different economic strategies.

#### Player or developer outcome

At 2,500 post-dispatch Gloamwood returns, the player has one secured Scribe Form Soul and required Essence, opens Soulweave, presses Awaken, and sees Scribe compared with Man-at-Arms through discovery and forecast-confidence advantages rather than raw throughput.

#### Dependencies

- M10

#### Included scope

- Author `TUT_08_SCRIBE`.
- Implement 2,500 milestone, Scribe Soul top-up, awakening-cost protection, and normal Form-awakening command.
- Implement Scribe node reveal/awakened states and Form detail.
- Implement data-driven Scribe Trait inputs needed by later discovery/forecast systems.
- Implement a comparison view that can show current known differences without exposing unknown Broken Watch data.
- Preserve the conservative mechanical-skip rule: guidance may be dismissed, but Scribe is not auto-awakened.

#### Explicit non-goals

- Broken Watch, second tether, actual Provisions discovery, Specialist Retinues, or Form Arts.
- Automatic awakening by tutorial code.
- Final Scribe balance.

#### Expected files or subsystems

The exact file list remains subject to repository inspection. Expected areas are:

- Form service and awakening command
- Scribe milestone/guarantees
- Soulweave/Form comparison UI
- Tutorial/dialogue content
- Persistence and tests

#### Data and content required

- `MS_GLOAMWOOD_REAPING_2500`, `GUA_SCRIBE_SOUL_1`, `GUA_SCRIBE_AWAKENING_COST_FLOOR`, `FORM_SCRIBE`, `SOUL_FORM_SCRIBE`, and Unclosed Ledger modifiers.

#### Acceptance criteria

- At the milestone, owned Scribe Souls are at least one without overwriting legitimate earlier drops.
- Mandatory Essence remains available for awakening despite unrelated spending attempts.
- The player must issue Awaken; tutorial code never sets the awakened flag directly.
- The normal Form service validates and consumes the configured costs exactly once.
- Comparison presents data-driven role, Trait, slot profile, and current forecast/discovery implications.
- Save/load before and after awakening is idempotent; skipped guidance leaves the required action available through Help.

#### Automated verification

- Early-drop and zero-top-up cases.
- Protected-cost spending rejection.
- Player-command awakening and duplicate rejection.
- Mechanical-skip no-auto-awaken.
- Save round trip and comparison trace tests.

#### Manual verification

- Reach 2,500 with and without an early Scribe Soul fixture, attempt unrelated spending, dismiss guidance once, then awaken manually and reload.

#### Demonstration path

- Cross 2,500.
- Inspect secured Soul/Essence.
- Compare Scribe with Man-at-Arms.
- Press Awaken and show the normal cost transaction and saved state.

#### Save/load expectations

Checkpoint at milestone/top-ups, protection changes, awakening, tutorial presentation, and Help state.

#### Documentation updates

- Content contracts, tests, and `MILESTONES.md`.

#### Known risks

- Comparison could reveal content that should remain Unknown.
- Cost protection may be confused with extra inventory.
- Scribe Trait could be hard-coded in UI.

#### Follow-on dependencies

- M12 and M13.

---

### M12 — Broken Watch, minor resonance, second tether, and concurrent Reapings

**Definition status:** Approved  
**Prompt status:** Not drafted  
**Implementation status:** Not started  
**Recommended Codex task size:** Medium; one Beat-8 pull request.  
**Planned prompt file:** `docs/codex/milestone-prompts/M12-broken-watch-second-tether.md`

#### Purpose

Deliver Beat 8 and prove shared simulation under real concurrent assignments.

#### Player or developer outcome

At 5,000 Gloamwood persistent returns with Scribe awakened, a minor first resonance occurs once, Broken Watch is charted/available, tether capacity becomes two, and any valid assignment pairing can operate concurrently and be reassigned without losing elapsed progress.

#### Dependencies

- M11

#### Included scope

- Author `TUT_09_SECOND_THRESHOLD`.
- Implement the 5,000 condition, distinct minor resonance, Broken Watch unlock, and tether-capacity grant.
- Implement regional map presentation for Gloamwood, Broken Watch, and veiled future anchors.
- Extend global simulation to two active Reapings sharing state and stable ordering.
- Implement assignment comparison/reassignment through commands and accept any valid pairing.
- Add slower fallback readiness for later discovery without completing the discovery beat yet.

#### Explicit non-goals

- 10,000 regional resonance, Provisions identification, Larder, additional Thresholds, or final map art.
- Forcing Scribe to Broken Watch.
- Independent per-Reaping timer loops.

#### Expected files or subsystems

The exact file list remains subject to repository inspection. Expected areas are:

- Broken Watch content/runtime state
- Map and tether-line presentation
- Progression/resonance effect
- Concurrent simulation and assignment services
- Comparison UI extensions
- Tests and save fixtures

#### Data and content required

- `MS_GLOAMWOOD_REAPING_5000`, `RESONANCE_GLOAMWOOD_5000_MINOR`, `THR_BROKEN_WATCH`, tether capacity 2, Broken Watch provisional data, and veiled POI metadata.

#### Acceptance criteria

- Condition requires 5,000 post-dispatch Gloamwood returns plus Scribe awakened.
- Minor resonance, Broken Watch, and tether 2 apply exactly once and use IDs distinct from the 10,000 event.
- Two Reapings resolve through one global engine and produce deterministic results independent of external iteration order.
- Any valid Form pairing occupies both tethers and advances the tutorial.
- Reassignment resolves elapsed time before changing Form and increments assignment revision.
- Save/load preserves both operations, tether capacity, map knowledge, resonance, residuals, and report events.

#### Automated verification

- Exactly-once resonance/unlock.
- Two-Reaping repeatability and chunking.
- Stable ID order.
- Reassignment-at-command-time.
- Non-recommended arrangement accepted.
- Save round trip.

#### Manual verification

- Unlock Broken Watch, try both recommended and reversed pairings, reassign during progress, navigate away, and reload.

#### Demonstration path

- Cross 5,000 with Scribe awakened.
- Show minor resonance and second tether.
- Dispatch both Thresholds.
- Swap Forms and compare forecast summaries without pausing either operation.

#### Save/load expectations

Checkpoint at milestone/resonance, Threshold knowledge/availability, tether grant, each dispatch/reassignment, and tutorial transition.

#### Documentation updates

- Architecture/tests for concurrency changes, content contracts, and `MILESTONES.md`.

#### Known risks

- Concurrent shared-resource ordering bugs.
- Map presentation implying unavailable content.
- Tutorial accidentally requiring the recommended pairing.

#### Follow-on dependencies

- M13, M14, M15.

---

### M13 — Discovery states, hidden Provisions, and forecast confidence

**Definition status:** Approved  
**Prompt status:** Not drafted  
**Implementation status:** Not started  
**Recommended Codex task size:** Medium; one Beat-9 pull request.  
**Planned prompt file:** `docs/codex/milestone-prompts/M13-discovery-provisions-forecasts.md`

#### Purpose

Deliver Beat 9 and make Scribe’s information value immediately observable.

#### Player or developer outcome

Broken Watch produces Provisions before they are known; Scribe identifies the channel after the configured accelerated path, a non-Scribe assignment reaches the same required state through a slower fallback, and forecasts disclose progressively better information without changing underlying production.

#### Dependencies

- M12

#### Included scope

- Author `TUT_10_DISCOVERY`.
- Implement per-channel Unknown, Identified, and Charted state/progress.
- Bank hidden output normally and filter only its player-facing disclosure.
- Implement Scribe discovery modifier and forecast-uncertainty modifier through shared data-driven evaluation.
- Implement the configured Scribe and fallback cycle thresholds.
- Extend Threshold/report/forecast UI with unknown rows, identification event, qualitative frequency, charting progress, and trace attribution.

#### Explicit non-goals

- Larder, Rations, additional materials, advanced Codex, stochastic loot, or hidden-output retroactive generation.
- A softlock when Scribe is elsewhere.

#### Expected files or subsystems

The exact file list remains subject to repository inspection. Expected areas are:

- Discovery runtime/service/boundaries
- Broken Watch Provisions channel
- Disclosure-aware view models
- Forecast range/trace presentation
- Report discovery event
- Tests and fixtures

#### Data and content required

- `RES_PROVISIONS`, Broken Watch material channel, Scribe/fallback discovery thresholds, Unclosed Ledger trace labels, and discovery state IDs.

#### Acceptance criteria

- Provisions increase authoritative inventory while the channel is Unknown.
- Identification reveals the existing banked total without granting or deleting output.
- Scribe and fallback paths reach the same required state at different configured speeds.
- Forecast uncertainty/disclosure changes, but the deterministic underlying production result does not.
- The event attributes accelerated discovery to Scribe when applicable.
- Save/load preserves hidden inventory, discovery progress/state, completed cycles, and queued presentation exactly.

#### Automated verification

- Hidden-production-before-discovery.
- No duplicate grant at identification.
- Scribe versus fallback thresholds.
- Forecast non-mutation and uncertainty trace.
- Save round trip at each discovery state.

#### Manual verification

- Run from the same fixture with Scribe at Broken Watch and with Man-at-Arms there; inspect unknown, identified, and charted presentation and banked totals.

#### Demonstration path

- Start Broken Watch with Provisions unknown.
- Show hidden inventory through debug only while UI stays unknown.
- Complete Scribe discovery and reveal the existing total.
- Repeat fallback path and compare elapsed cycles and forecast confidence.

#### Save/load expectations

Checkpoint on discovery state transitions and tutorial progression; hidden resources are ordinary inventory and persist regardless of disclosure.

#### Documentation updates

- Content contracts, architecture/test docs if discovery semantics change, and `MILESTONES.md`.

#### Known risks

- Debug information leaking into player UI.
- Discovery used as an output gate.
- Forecast range presentation implying random production.

#### Follow-on dependencies

- M14.

---

### M14 — Larder, Rations, support pressure, and graceful degradation

**Definition status:** Approved  
**Prompt status:** Not drafted  
**Implementation status:** Not started  
**Recommended Codex task size:** Medium-large but bounded to one Hall, one recipe, one Store, and one consumer.  
**Planned prompt file:** `docs/codex/milestone-prompts/M14-larder-rations-support.md`

#### Purpose

Deliver Beat 10 as one complete raw-material-to-support chain.

#### Player or developer outcome

After Provisions are identified, the player receives only the missing onboarding floor, restores the Larder, runs Provisions → Rations under Maintain 50, and sees Soldier Company move between full and reduced effect while base Reaping never stops.

#### Dependencies

- M13
- M10 support foundation

#### Included scope

- Author `TUT_11_LARDER`.
- Implement the derived Provisions top-up: restoration + first batch + configured buffer.
- Implement Larder restoration, one recipe, deterministic cycle/input/output state, and Maintain 50 target.
- Integrate Hall boundaries with the same global SimulationEngine as both Reapings.
- Implement support consumption, low/depleted warnings, reduced Soldier Company floor, and recovery when Rations become available.
- Implement Larder detail and before/after stable-runtime/bottleneck forecast presentation.

#### Explicit non-goals

- Recipe queues, multiple recipes, Keepers, protected reserves, auto-switching, Armaments, additional Halls, or advanced Store policies.
- Hard shutdown of base Reaping.

#### Expected files or subsystems

The exact file list remains subject to repository inspection. Expected areas are:

- Hall/recipe state and services
- Larder/recipe content
- Hall simulation boundaries
- Support policy/state integration
- Larder and forecast UI
- Guarantee/progression effects and tests

#### Data and content required

- `HALL_LARDER`, `RECIPE_LARDER_PROVISIONS_TO_RATIONS`, `STORE_RATIONS`, `GUA_PROVISIONS_ONBOARDING_FLOOR`, Maintain 50, and provisional rates/consumption/floor values.

#### Acceptance criteria

- The guarantee derives its floor from current configured costs and grants only the missing Provisions.
- Larder output banks immediately online and through supplied/offline resolution.
- Two Reapings and the Hall resolve in one global timeline.
- At a same-time Hall-output/support-depletion boundary, the documented stable order is applied.
- At zero Rations, Soldier Company uses the configured reduced effect while base backlog, Essence, and Mastery continue.
- Forecast names the bottleneck, full-support duration, and post-depletion behavior and updates after activation.
- Save/load preserves partial Hall cycle, target, inventories, support state, and report events.

#### Automated verification

- Provisions-floor cases.
- Hall cycle/input/target tests.
- Global shared-resource and same-time-boundary tests.
- Support depletion/recovery and base-progress tests.
- Online/offline/forecast equivalence with Hall active.
- Save round trip mid-cycle.

#### Manual verification

- Identify Provisions, restore/activate Larder, observe one batch, force Ration depletion through debug time, observe reduced effect, then recover with Hall output and reload mid-cycle.

#### Demonstration path

- Show impending support pressure.
- Restore Larder and set Maintain 50.
- Compare forecast before/after.
- Advance through depletion and recovery while confirming base progress never stops.

#### Save/load expectations

Checkpoint at guarantee, Hall restoration/activation/target changes, support transitions where required, tutorial state, and normal lifecycle saves.

#### Documentation updates

- Architecture/data/testing docs for Hall/support changes, and `MILESTONES.md`.

#### Known risks

- Circular boundary calculations between producer and consumer.
- Guarantee values duplicated outside content.
- UI presenting stable runtime as total shutdown time.

#### Follow-on dependencies

- M15 and M16.

---

### M15 — Regional 10,000 resonance, optional Recollection choice, and objectives

**Definition status:** Approved  
**Prompt status:** Not drafted  
**Implementation status:** Not started  
**Recommended Codex task size:** Small-medium; one Beat-11 pull request.  
**Planned prompt file:** `docs/codex/milestone-prompts/M15-second-resonance-recollection-choice.md`

#### Purpose

Deliver Beat 11 and transition the player from directed onboarding toward agency.

#### Player or developer outcome

At 10,000 regional persistent returns, a second distinct resonance fires once, grants its configured Essence bundle, exposes three nonexclusive affordable Recollections, applies the chosen data-driven effect, updates a forecast, and presents immediate/developmental/long-term objectives.

#### Dependencies

- M14

#### Included scope

- Author `TUT_12_SEAL_CHOICE`.
- Implement regional persistent-return aggregation and 10,000 condition.
- Implement `RESONANCE_REGION_10000`, configured Essence reward, and optional-choice access.
- Implement Quicker Reckoning, Names Kept, and Open Ledgers with only their approved prototype effect grammar.
- Implement Seal/choice presentation, short effect feedback, forecast before/after, and objective panel foundation.
- Keep unchosen nodes available and expose the 25,000 regional objective without implementing unapproved reward content beyond a configured placeholder/hint.

#### Explicit non-goals

- Full seal break, exclusive choice, additional Recollections, prestige, next region, or final audiovisual polish.
- Counting the opening four toward regional returns.

#### Expected files or subsystems

The exact file list remains subject to repository inspection. Expected areas are:

- Regional counter and milestone/effect content
- Seal/resonance presentation
- Recollection choice UI and modifiers
- Objective view model/panel
- Tutorial content and tests

#### Data and content required

- `MS_REGION_REAPING_10000`, `RESONANCE_REGION_10000`, configured Essence bundle, three optional Recollections, and `MS_REGION_REAPING_25000` objective metadata.

#### Acceptance criteria

- Regional counter sums only persistent-Reaping returns from active prototype Thresholds.
- The 10,000 resonance is distinct from the 5,000 event and fires exactly once.
- Reward and choice access survive repeated load without duplication.
- Each option is affordable under the configured reward/floor, nonexclusive, and remains available if not selected.
- Purchasing one uses the normal transaction/effect grammar and changes an explained forecast value.
- The objective panel shows one immediate, one developmental, and one long-term objective from authoritative state.

#### Automated verification

- Regional-counter and opening-four exclusion.
- Exactly-once reward/resonance.
- Recollection purchase and modifier trace.
- Nonexclusive availability.
- Forecast before/after and save round trip.

#### Manual verification

- Cross 10,000 with different Form arrangements, inspect the resonance, choose each option from separate fixtures, reload, and inspect objectives.

#### Demonstration path

- Cross the regional threshold.
- Show the separate resonance and reward.
- Choose one Recollection.
- Show the forecast change and remaining options/objectives.

#### Save/load expectations

Checkpoint at milestone/resonance/reward, choice availability, purchase, objective/tutorial state, and report event.

#### Documentation updates

- Prototype source only if approved behavior changes, data/testing docs, and `MILESTONES.md`.

#### Known risks

- Confusing the two resonances.
- Optional values becoming hard-coded in UI.
- Choice presentation implying exclusivity.

#### Follow-on dependencies

- M16 and M17.

---

### M16 — Offline forecast, welcome-back report, and guided-opening completion

**Definition status:** Approved  
**Prompt status:** Not drafted  
**Implementation status:** Not started  
**Recommended Codex task size:** Medium; one Beat-12/offline-UX pull request.  
**Planned prompt file:** `docs/codex/milestone-prompts/M16-offline-return-welcome-back.md`

#### Purpose

Deliver Beat 12 and make the unattended-progress promise visible through the trusted-time path.

#### Player or developer outcome

The player can view one-hour and eight-hour forecasts, close and return through the trusted-time adapter, receive a segmented welcome-back report whose gains were already banked, see pending-reconciliation messaging when Steam time is unavailable, and complete mandatory guidance at `TUT_13_COMPLETE`.

#### Dependencies

- M06
- M15

#### Included scope

- Author `TUT_13_COMPLETE` and closing Eustace presentation.
- Complete forecast UI for one-hour/eight-hour horizons, segment summaries, support degradation, milestones, and end state.
- Implement welcome-back report creation from the committed offline transaction, bounded report history, archive/dismiss behavior, and changed-estimate summaries.
- Implement player-facing trusted-time unavailable, pending, and reconciled states without exposing technical secrets or guessing progress.
- Ensure the actual committed return and unchanged-state forecast use the same engine and content.
- Expose three objective horizons and the Settled Passage explanatory tooltip.
- Complete normal guided-flow exit when the forecast is shown, opened, or dismissed as specified.

#### Explicit non-goals

- Steam Cloud, achievements, release packaging, final offline cap, full Codex analytics, or backend authority.
- Claim buttons for already-earned output.
- Full-game Settled Passage tutorial before actual settlement.
- Claiming Death Idle's production Steam configuration is validated from App ID `480`.

#### Expected files or subsystems

The exact file list remains subject to repository inspection. Expected areas are:

- Forecast and offline-return screens and view models
- Report history/archive and welcome-back records
- Trusted-time status presentation
- Tutorial closing content
- Integration tests and save fixtures

#### Data and content required

- One-hour and eight-hour horizons
- Report-history limit
- Offline cap supporting eight hours
- Trusted-time player-facing status text
- Objective metadata

#### Acceptance criteria

- Forecasting mutates only a clone and does not create saves, reports, tutorial progress, or inventory gains.
- Under unchanged state and content, actual trusted offline resolution matches the eight-hour forecast exactly for authoritative values.
- Offline gains are committed before the welcome-back report is shown; dismissing it changes no inventory.
- Unavailable trusted time shows a pending state, grants no guessed progress, permits foreground play, and later reconciles once.
- Report history survives save/load and the same offline transaction is never reported or credited twice.
- Opening or dismissing the required forecast transitions the tutorial to `TUT_13_COMPLETE` while both operations continue.
- The screen explains post-depletion and milestone segments clearly enough for manual comprehension checks.
- Automated equivalence tests use the fake provider and do not depend on Steam.
- The owner-run Windows proof uses the M06 GodotSteam adapter and App ID `480`, and is labelled an internal technical proof rather than production App-ID validation.

#### Automated verification

Codex Cloud/Linux:

- Forecast non-mutation and equivalence with controlled fake trusted-time samples.
- Offline transaction and report duplicate prevention.
- Unavailable and reconnect presentation-state integration.
- Report clear/history save tests.
- Tutorial completion and objective-state tests.
- Full `tools/test/run_gut.sh` run.

Owner-run Windows automation:

- Full `tools/test/run_gut.ps1` run.

#### Manual verification

On the Windows Godot machine:

- Run connected and unavailable trusted-time flows through the live GodotSteam adapter.
- Compare an eight-hour forecast to a controlled fake-provider result.
- Repeat a short real Steam return with App ID `480`.
- Open and dismiss reports, reload, and verify no duplicate result.
- Record clearly that Death Idle's own App ID and package configuration remain unverified.

#### Demonstration path

- View the eight-hour forecast.
- Close and relaunch through a trusted sample and show already-banked segmented gains.
- Repeat with trusted time unavailable and show pending state plus foreground continuation.
- Reconnect, reconcile once, and complete guidance.

#### Save/load expectations

Create checkpoints before and after the offline transaction, after report snapshot/archive/dismiss, at trusted-status transitions, after the forecast-shown tutorial flag, and at `TUT_13_COMPLETE`.

#### Documentation updates

- `TESTING_AND_VALIDATION.md`
- content/data contracts for statuses
- source of truth only for approved UX changes
- `MILESTONES.md`

#### Known risks

- Player confusion when trusted time is unavailable.
- Forecast disclosure leaking unknown channels.
- Report history growth.
- Differences between fake and real Steam lifecycle behavior.
- App ID `480` masking a later production package/configuration issue.

#### Follow-on dependencies

- M17.

---

### M17 — Complete 0–90 minute integration, resilience, pacing, and acceptance pass

**Definition status:** Approved  
**Prompt status:** Not drafted  
**Implementation status:** Not started  
**Recommended Codex task size:** Medium-large acceptance pass with no new major subsystem; split only when defects are independently reviewable.  
**Planned prompt file:** `docs/codex/milestone-prompts/M17-prototype-integration-acceptance.md`

#### Purpose

Validate the assembled prototype as one coherent first session without adding another major system.

#### Player or developer outcome

The complete recommended, skipped, interrupted, and non-recommended paths reach the required end state; pacing/debug tools support iteration; local-only telemetry and performance measurements identify remaining issues; the prototype is ready for structured playtesting.

#### Dependencies

- M16

#### Included scope

- Run and repair the full tutorial state sequence and all documented softlock/deviation paths.
- Add or finalize local-only playtest event recording through the approved event sink; no network telemetry.
- Add bounded pacing/debug setup states that use normal commands and satisfy required world state.
- Tune centralized provisional data to approach first-input, first-dispatch, guided-to-player-led, and 75–90 minute targets without hard-coded timers.
- Complete responsive-layout, keyboard/focus, text readability, placeholder consistency, and basic audio/effect hooks needed for the prototype.
- Measure two-Reaping/one-Hall/report performance and prototype save size/encode/write/load timing.
- Run comprehension and acceptance checklist preparation, record known limitations, and update milestone status/handoffs.

#### Explicit non-goals

- New Forms, Retinues, Halls, Thresholds, Writs, backend, Steam Cloud, achievements, final art/voice, launch balancing, or release packaging.
- The commercial save-format/threat-model gate; M17 records prototype measurements but does not promise the final container or tamper model.
- Broad architectural refactors unrelated to failing acceptance criteria.

#### Expected files or subsystems

The exact file list remains subject to repository inspection. Expected areas are:

- End-to-end integration tests and fixtures
- Local telemetry/event sink and optional exportable playtest log
- Pacing/debug setup tools
- Focused UI/audio/effect fixes
- Performance/save measurement notes
- Updated acceptance/handoff documentation

#### Data and content required

- Centralized tuning values only; every adjustment records rationale and remains configurable. No new unapproved content IDs.

#### Acceptance criteria

- Normal recommended play reaches two active Reapings, two awakened Forms, one fielded Soldier Company, Archive, active Larder, both resonances, one optional Recollection, reports, forecast, and `TUT_13_COMPLETE`.
- All documented quit/load/skip/early-completion/non-recommended/support-depletion/trusted-time paths reach a valid recoverable end state.
- No required reward, unlock, reservation, report, or offline interval duplicates across repeated loads.
- Production continues under every menu/dialogue/tutorial screen tested.
- The prototype remains responsive with two Reapings, one Hall, report aggregation, and normal UI animation.
- Window/resolution targets pass the documented manual matrix.
- Pacing telemetry can identify time-to-input, dispatch, 1,000/2,500/5,000/10,000 milestones, player-led transition, and completion without network services.
- Prototype save performance and size are recorded, with no claim that JSON is the final secure full-game format.
- Every completion-checklist item has an automated or manual result and unresolved failures are stated explicitly.

#### Automated verification

- Full recommended path.
- All softlock/deviation fixtures.
- Repeated-load exactly-once suite.
- Performance smoke and bounded-report tests.
- Import, full GUT, and main-scene smoke.

#### Manual verification

- Complete the full 0–90 flow at target resolutions; run skip/resume and non-recommended variants; perform Windows Steam trusted-time check; answer the ten comprehension questions in structured playtests; record performance and pacing.

#### Demonstration path

- Run the full recommended first session with accelerated debug time only where needed for review.
- Show each major beat and end state.
- Load selected failure/deviation fixtures and demonstrate recovery.
- Present the acceptance matrix, pacing log, performance/save measurements, and known limitations.

#### Save/load expectations

The final prototype save path is exercised after every tutorial state, one-time guarantee/unlock, dispatch/reassignment, awakening, reservation, Hall action, resonance, report transition, and offline transaction. Backup recovery and migration fixtures remain passing.

#### Documentation updates

- All maintained documents whose status, commands, contracts, or known limitations changed; `MILESTONES.md` status table; milestone handoff in the pull request.

#### Known risks

- Final integration may reveal cross-system defects requiring narrowly scoped follow-up PRs.
- Pacing data from developers is not a substitute for external first-time-player testing.
- Placeholder presentation can distort comprehension results.

#### Follow-on dependencies

- Structured external playtesting, approved defect milestones, vertical-slice planning, and the later commercial save-format/threat-model release gate.

---
## 10. Beat and tutorial-state coverage

| Prototype segment | Primary milestone |
|---|---|
| Technical/test foundation | M00–M06 |
| Tutorial/dialogue infrastructure | M07 |
| Beats 1–4 / `TUT_00_BOOT`–`TUT_04_FIRST_DISPATCH` | M08 |
| Beat 5 / `TUT_05_ARCHIVE`–`TUT_06_SOULWEAVE` | M09 |
| Beat 6 / `TUT_07_RETINUE` | M10 |
| Beat 7 / `TUT_08_SCRIBE` | M11 |
| Beat 8 / `TUT_09_SECOND_THRESHOLD` | M12 |
| Beat 9 / `TUT_10_DISCOVERY` | M13 |
| Beat 10 / `TUT_11_LARDER` | M14 |
| Beat 11 / `TUT_12_SEAL_CHOICE` | M15 |
| Beat 12 / `TUT_13_COMPLETE` | M16 |
| Full path, deviations, pacing, telemetry, and acceptance | M17 |

## 11. Cross-milestone safeguards

The following are never deferred merely because a later milestone adds fuller presentation:

- output auto-banks from the first simulation slice;
- reports never gate claims;
- menus, dialogue, and tutorial overlays never pause production;
- offline/forecast modes never use different balance rules;
- no authoritative closed-session credit comes from local device time;
- the scripted opening four never enter persistent-Reaping counters;
- Emergency transitions the same operation to Standard;
- guarantees top up only missing amounts and record exactly once;
- Soldier Company reserves twelve Souls and does not consume them;
- support depletion never removes valid base production;
- hidden production remains real before discovery;
- any valid two-Reaping arrangement remains recoverable;
- all authoritative changes extend tests and save fixtures when introduced.

## 12. Post-prototype release gate `RG01` — Save format, Steam Cloud, and threat model

`RG01` is not an implementation milestone in the 0–90 minute prototype and is not a reason to add release infrastructure early. It is a mandatory product/release decision before a public commercial build.

### Purpose

Determine whether the prototype JSON codec still meets measured full-game requirements and state honestly what protection the game promises.

### Required inputs

- representative early-game, completed-prototype, projected full-game, and stress save fixtures;
- measured payload/container size, encode/decode time, validation time, write/replace time, peak memory where practical, and backup-recovery behavior;
- planned Steam Cloud file count, conflict, multi-machine, and transfer behavior;
- achievement, leaderboard, economy, or other outcomes whose integrity matters;
- the current threat model: accidental corruption, casual editing, or a determined user controlling the client.

### Required decision

Approve one documented approach: retain JSON, compress/wrap the JSON payload, or introduce another codec through the existing `SaveCodec` boundary. The decision must include migration/backward-compatibility policy and a precise security claim.

### Guardrails

- Binary encoding, compression, obfuscation, local encryption, and a client-held HMAC key may deter casual edits but are not strong protection from a determined client owner.
- Steam Cloud synchronization is handled separately from schema validity and integrity.
- Outcomes that require strong protection need an external authority or server-held secret; they cannot be guaranteed by a local file extension.
- A codec change must pass the same schema, migration, atomic-storage, backup, and interrupted-resolution suites as the prototype JSON codec.

### Output

Create or update a dedicated accepted decision record and, when implementation is required, define a separate release milestone rather than expanding M17 retroactively.

## 13. Status and maintenance procedure

When a definition is approved, change only its Definition column to **Approved**. Phase 8 adds `PROMPT_TEMPLATE.md`; Phase 9 creates one prompt at a time and updates Prompt status. Implementation pull requests update Implementation and Verification status only after the relevant checks have actually run.

When a milestone reveals a planning problem:

1. stop the affected prompt or implementation;
2. identify the conflicting source or missing dependency;
3. update this map and, when necessary, `DECISIONS.md` and the architecture/contracts;
4. preserve superseded definitions or prompt versions through Git history and explicit status rather than silently changing accepted scope;
5. resume only after the revised definition is approved.

The commercial save-format/threat-model review remains a release gate, not an excuse to add encryption, binary encoding, Steam Cloud, or a backend to the 0–90 minute prototype without a new approved milestone.
