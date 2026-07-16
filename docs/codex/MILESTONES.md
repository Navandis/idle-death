# Death Idle Prototype Milestones

**Document role:** Approved implementation sequence and acceptance map for the 0–90 minute prototype  
**Repository path:** `docs/codex/MILESTONES.md`  
**Document status:** Approved rolling-wave milestone map  
**Milestone-map revision:** 15  
**Last updated:** 2026-07-16  
**Primary context:** [Prototype source of truth](../design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md), [Idle-fork source of truth](../design/IDLE_FORK_SOURCE_OF_TRUTH.md), [Architecture](ARCHITECTURE.md), [Data contracts](DATA_AND_CONTENT_CONTRACTS.md), [Testing](TESTING_AND_VALIDATION.md), [Owner verification](OWNER_VERIFICATION_WORKFLOW.md), [Milestone recalibration](MILESTONE_RECALIBRATION_PROPOSAL.md), and [Decisions](DECISIONS.md)

## 1. Purpose and authority

This file divides the approved prototype architecture and first-session sequence into reviewable work items. It defines scope and acceptance, not the implementation prompt text. The owner approved the original map in Phase 7 and approved the post-M03 rolling-wave recalibration on 2026-07-15. From M04 onward, M04–M17 are conceptual epics; only approved lettered implementation slices receive versioned Codex prompts.

Use the source hierarchy in `AGENTS.md`. A milestone definition cannot weaken a protected design invariant or accepted decision. When repository state later differs from an assumption here, update this file and record any architecture/design decision before drafting that milestone's prompt.

## 2. Current repository baseline

After M04A completion:

- Godot 4.7, GDScript, the 1920 × 1080 reference viewport, resizing/stretch settings, and a temporary dry-run main scene exist.
- `AGENTS.md`, project Codex configuration, the maintained design sources, the architecture documents, the approved `PROMPT_TEMPLATE.md`, and `OWNER_VERIFICATION_WORKFLOW.md` are present in the repository.
- GUT 9.7.1 is committed under `addons/gut/`.
- GodotSteam GDExtension 4.20 is committed under `addons/godotsteam/`.
- Development App ID `480` is configured in `project.godot`; automatic Steam initialization is disabled.
- M00 established `.gutconfig.json`, `tools/test/run_gut.sh`, `tools/test/run_gut.ps1`, the initial infrastructure test, and the canonical Linux/Windows verification documentation.
- Linux/Codex Cloud and owner-run Windows M00 verification passed, including failure propagation and clean recovery.
- M01 added `FixedPoint`, the minimal `GameState` simulation timeline, separate `TimeAuthorityState`, monotonic and trusted-time contracts, `TimeReconciliationService`, fakes, focused tests, a deterministic trace, and the milestone-specific Windows verification script.
- M01 Linux/Codex and owner-run Windows verification passed, including the full suite, focused numeric/time tests, source-ownership checks, import preflight, deterministic trusted-time trace, and long-horizon fixed-point trace.
- M02 added the frozen schema-version-1 mapper/validator, canonical signed-64-bit JSON strings, migration seam, atomic primary/temporary/backup storage, corrupt-file retention, persistence tests, trace, and Windows verification package.
- M03 added the typed explicit content catalog, exact canonical IDs, six stable output channels, centralized singular/plural terminology, deterministic normalization/validation, content-revision compatibility, focused tests, trace, Windows automation, and Inspector checklist.
- M03 merged through PR #7 at final head `971cdaa0fd46f641ec7409148e259d54f953d8c7` and merge commit `5e2b9b23878c9280f75b987cc9ad567d8980030d`; Linux/Codex and owner Windows/Inspector verification passed.
- M04A added typed inventory, Form, Threshold/acquisition, Reaping, and tether-capacity state; explicit deep cloning and content-aware validation; schema version 2; immutable v1/v2 fixtures; a production `v1 -> v2` migration; preserved-envelope upgrade persistence; focused tests; a real-file trace; and a corrected Windows owner package.
- M04A merged through PR #8 at final head `04b12d8ba2edeecbf13f252216249341469b40a8` and merge commit `673ad884357fc742a0a26dbb542d5b8d9fe557c9`; Linux/Codex and owner Windows verification passed.
- The repository still has no dispatch/recall command service, elapsed Reaping production, application shell, or player-facing gameplay UI.
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
10. stop for owner approval when a listed decision gate is reached;
11. package owner-run merge gates under `OWNER_VERIFICATION_WORKFLOW.md`, preferring one milestone-specific PowerShell entry point with a generated log and a separate checklist only for interactive observations;
12. identify one primary subsystem owner and one principal behavior or state transition for every implementation slice;
13. complete the `DEC-0033` scope assessment before prompt approval;
14. stop and report material scope growth before adding another subsystem owner, risk dimension, or cross-layer seam;
15. issue prompts only for directly executable implementation slices, never for conceptual epics.

A conceptual epic may be decomposed only through an approved map update. A slice may be split after implementation begins only when the split preserves a demonstrable result and the dependency/status tables are updated before work continues. Do not merge later work merely because Codex can generate a large diff.

### 3.1 Review-surface guardrails

These are planning triggers, not mechanical merge quotas.

| Guardrail | Normal target | Mandatory split review |
|---|---:|---:|
| Primary subsystem owners | 1 | More than 1 |
| New authoritative aggregate families | 0–1 | More than 2 |
| Save-schema transitions | 0–1 | More than 1 |
| New player-facing flows/screens | 0–1 | More than 1 |
| New platform/native integrations | 0–1 | Any platform work mixed with unrelated gameplay |
| Risk dimensions | 0–3 | 4 or more |
| Cross-layer integration seams | 0–2 | More than 2 |
| Non-documentation source/test files | Approximately 10–25 | Forecast above approximately 35 |
| Non-documentation code/test line delta, excluding `.uid` and repetitive authored data | Approximately 500–1,200 | Forecast above approximately 1,500 |
| Bulk `.tres` content | Small fixture set | Production-catalog bulk mixed with a new framework |

A trigger requires a split or an explicit owner-approved exception. Estimates do not authorize extra work, and crossing a number does not automatically invalidate an otherwise coherent slice.

## 4. Status vocabulary

### 4.1 Work-item types

| Type | Meaning |
|---|---|
| Completed milestone | Historical directly executed milestone from M00–M03. |
| Conceptual epic | Approved outcome and dependency container; not directly executable and receives no prompt. |
| Implementation slice | Bounded lettered task that may receive one approved prompt and pull request. |
| Release gate | Required decision or validation outside the prototype implementation sequence. |

### 4.2 Status values

| Field | Values |
|---|---|
| Definition | Proposed, Approved, Superseded |
| Prompt | Not applicable, Not drafted, Drafted, Approved, Superseded |
| Implementation | Not directly executable, Not started, In progress, Pull request open, Merged, Rework required |
| Verification | —, Partial, Passed, Failed, Blocked |

A conceptual epic uses `Prompt: Not applicable` and `Implementation: Not directly executable`. Its completion is derived from the required slices; it does not receive an epic-level implementation pull request.

## 5. Decision and dependency gates

| Gate | Required before | Rule |
|---|---|---|
| `GATE-GUT` | M00 merge | Verify the committed GUT 9.7.1 dependency, retained license, `.gutconfig.json`, required Linux and Windows wrappers, Godot 4.7 execution, and real failure exit codes. |
| `GATE-WINDOWS-HARNESS` | M00 merge | The owner runs `tools/test/run_gut.ps1` on the separate Windows Godot machine and records the result; Codex Cloud cannot satisfy this gate. |
| `GATE-FIXED-POINT` | M01 merge | Implement accepted `DEC-0026`: one centralized scale of `1_000_000` for fractional state, unscaled discrete counts, explicit-period accumulation, checked 64-bit arithmetic, canonical carries, documented bounds, and cross-platform tests including one-item-per-8-hours and one-item-per-24-hours cases. |
| `GATE-SAVE-SCHEMA` | M02 merge | Freeze schema-version-1 key spelling and representative fixtures before gameplay state depends on it. |
| `GATE-CONTENT-CATALOG` | M03 merge | Validate one explicit typed catalog containing the required prototype IDs, `RES_ESSENCE`, stable `CHANNEL_...` sources, centralized `TERM_...` terminology, editable names independent of IDs, normalized values, content-revision compatibility, deterministic ordering, and editor-inspectable `.tres` definitions before simulation depends on content. |
| `GATE-SLICE-SCOPE` | Every post-M03 prompt approval | Complete the `DEC-0033` scope assessment. Split the work or record an explicit owner-approved exception when a mandatory review trigger is crossed. |
| `GATE-GAMEPLAY-SCHEMA` | M04A implementation and merge | Satisfied for prompt drafting by accepted `DEC-0034`: M04A introduces schema version 2 with a production sequential `v1 -> v2` migration. M04A must implement and verify the transactional upgrade, historical fixture, failure preservation, and owner Windows path before merge. |
| `GATE-REAPING-ASSIGNMENT` | M04B prompt approval | Approve `DEC-0035` or a revised assignment contract covering stable recalled Reaping identity, revision guards, Form exclusivity, tether derivation, and nonzero carry handling before Codex implements commands. |
| `GATE-STEAM-TIME` | The applicable M06 slice prompt/implementation | Satisfied for prompt drafting by `DEC-0024`: use pinned GodotSteam 4.20 and development App ID `480`. M06 must still verify license footprint, wrapper API, explicit initialization, and live Windows behavior. |
| `GATE-PRODUCTION-OFFLINE` | The final applicable M16 slice merge | Fake-provider automation plus the owner-run Windows/GodotSteam connected, unavailable, reconnect, clock-change, and repeated-load checks must pass. |
| `RELEASE-GATE-STEAM-APP` | Before external Steam Playtest or commercial distribution | Replace development App ID `480` with Death Idle's assigned App ID and validate package ownership, launch-through-Steam behavior, export contents, and absence of development-only App ID aids. |
| `RELEASE-GATE-SAVE` | Before commercial release, not this prototype map | Profile realistic full-game saves and choose the final codec/threat model under `DEC-0022`. JSON may remain; binary/compression/encryption are not assumed security. |

`GATE-GUT` and `GATE-WINDOWS-HARNESS` were satisfied by M00. PR #4 merged on 2026-07-13 at merge commit `77c618a1d9adbf8b02380d8509d2afb4c4cbc8ea`; Linux/Codex Cloud checks passed, and explicit owner evidence covered Windows full and focused GUT, outside-root execution, editor smoke, passive Steam configuration, intentional failure propagation, cleanup, and clean recovery.

`GATE-FIXED-POINT` was satisfied by M01. PR #5 merged on 2026-07-14 at merge commit `a5b231682967e4cb71b4404af158e93ff8bbf261`; its final head was `e2b291e75dab5e3484da7dec1d4420a2fb9637be`. Linux/Codex and owner-run Windows verification passed the full and focused suites, forbidden-time-source checks, import preflight, trusted-time trace, long-horizon fixed-point trace, cleanup, and generated-log requirements.

`GATE-SAVE-SCHEMA` was satisfied by M02. PR #6 merged on 2026-07-14 at merge commit `480a9eae2fe0c3591503da56b07c272be74ec027`; its final head was `0dd0c1d5c799db45aa4a8387d93750e02b2e485f`. Linux/Codex passed the focused persistence suite (`17/17` tests), full suite (`29/29` tests), and real-file trace. The owner passed the same Windows full/focused suites, explicit import, revision-1/revision-2 rotation, corrupt-primary rejection, backup selection, retained corrupt bytes, isolated-directory cleanup, and final clean regression rerun.

`GATE-CONTENT-CATALOG` was satisfied by M03. PR #7 merged on 2026-07-15 at merge commit `5e2b9b23878c9280f75b987cc9ad567d8980030d`; its final head was `971cdaa0fd46f641ec7409148e259d54f953d8c7`. Linux/Codex and owner Windows verification passed the full and focused suites, explicit import, semantic catalog trace, artifact audit, and Godot Inspector checklist.

`GATE-SLICE-SCOPE` is mandatory for every post-M03 prompt. `GATE-GAMEPLAY-SCHEMA` is fully satisfied by M04A: schema version 2, immutable historical support, migration preservation, Linux/Codex verification, and owner Windows verification passed. `GATE-REAPING-ASSIGNMENT` is pending owner approval of proposed `DEC-0035` with the M04B prompt.


When trusted time is unavailable, the approved behavior is to grant no guessed closed-session progress, retain pending reconciliation, and continue monotonic foreground production. No milestone may introduce a local-device-time fallback.

## 6. Milestone status map

| ID | Work item | Type | Definition | Prompt | Implementation | Verification |
|---|---|---|---|---|---|---|
| M00 | Repository, Godot, GUT, and Codex Cloud harness | Completed milestone | Approved | Approved | Merged | Passed |
| M01 | Deterministic numeric and time-authority foundation | Completed milestone | Approved | Approved | Merged | Passed |
| M02 | Versioned save codec and atomic storage | Completed milestone | Approved | Approved | Merged | Passed |
| M03 | Content catalog, canonical IDs, and configurable prototype data | Completed milestone | Approved | Approved | Merged | Passed |
| M04 | Persistent Reaping simulation vertical slice | Conceptual epic | Approved | Not applicable | Not directly executable | — |
| M04A | Gameplay state and persistence foundation | Implementation slice | Approved | Approved | Merged | Passed |
| M04B | Dispatch, recall, and assignment integrity | Implementation slice | Approved | Drafted | Not started | — |
| M04C | Single-Reaping core resolver | Implementation slice | Approved | Not drafted | Not started | — |
| M04D | Output channels and long-horizon acquisition progress | Implementation slice | Approved | Not drafted | Not started | — |
| M04E | Forecast clone, report accumulator, and simulation harness | Implementation slice | Approved | Not drafted | Not started | — |
| M05 | Persistent application shell, navigation, and debug access | Conceptual epic | Approved | Not applicable | Not directly executable | — |
| M06 | Steam trusted-time adapter and transactional offline resolution | Conceptual epic | Approved | Not applicable | Not directly executable | — |
| M07 | Dialogue and save-safe tutorial orchestration framework | Conceptual epic | Approved | Not applicable | Not directly executable | — |
| M08 | Opening sequence, scripted four returns, Brand, and first dispatch | Conceptual epic | Approved | Not applicable | Not directly executable | — |
| M09 | Archive, Recollections, and Soulweave horizon | Conceptual epic | Approved | Not applicable | Not directly executable | — |
| M10 | First report, Emergency-to-Standard transition, and Soldier Company | Conceptual epic | Approved | Not applicable | Not directly executable | — |
| M11 | Scribe guarantee, player-driven awakening, and Form comparison | Conceptual epic | Approved | Not applicable | Not directly executable | — |
| M12 | Broken Watch, minor resonance, second tether, and concurrent Reapings | Conceptual epic | Approved | Not applicable | Not directly executable | — |
| M13 | Discovery states, hidden Provisions, and forecast confidence | Conceptual epic | Approved | Not applicable | Not directly executable | — |
| M14 | Larder, Rations, support pressure, and graceful degradation | Conceptual epic | Approved | Not applicable | Not directly executable | — |
| M15 | Regional 10,000 resonance, optional Recollection choice, and objectives | Conceptual epic | Approved | Not applicable | Not directly executable | — |
| M16 | Offline forecast, welcome-back report, and guided-opening completion | Conceptual epic | Approved | Not applicable | Not directly executable | — |
| M17 | Complete 0–90 minute integration, resilience, pacing, and acceptance pass | Conceptual epic | Approved | Not applicable | Not directly executable | — |

## 7. Dependency sequence

### 7.1 Exact near-term implementation sequence

```text
M00 → M01 → M02 → M03
                      └─ GATE-GAMEPLAY-SCHEMA
                          └─ M04A → M04B → M04C → M04D → M04E
```

| Slice | Requires | Unlocks |
|---|---|---|
| M04A | M03 Passed; `GATE-GAMEPLAY-SCHEMA` satisfied by `DEC-0034`; prompt-level `GATE-SLICE-SCOPE` review | M04B |
| M04B | M04A Merged and Passed | M04C |
| M04C | M04B Merged and Passed | M04D |
| M04D | M04C Merged and Passed | M04E |
| M04E | M04D Merged and Passed | M05 decomposition and prompt drafting |

### 7.2 Conceptual dependency sequence after M04E

```text
M04E
 └─ M05 implementation slices, defined under rolling-wave review
     ├─ M06 implementation slices  (approved Steam-time dependency required)
     └─ M07 implementation slices
         └─ M08 implementation slices
             └─ M09 implementation slices
                 └─ M10 implementation slices
                     └─ M11 implementation slice(s)
                         └─ M12 implementation slices
                             └─ M13 implementation slices
                                 └─ M14 implementation slices
                                     └─ M15 implementation slice(s)
                                         └─ M16 implementation slices  (also requires M06 completion)
                                             └─ M17 implementation slices
```

The post-M04E entries above are conceptual dependencies, not approved prompt IDs. Their preliminary decompositions remain subject to repository inspection and owner approval immediately before each epic. M06 remains early enough to retire the trusted-time/platform risk before M16. M07–M15 may use fake trusted-time providers, but the final applicable M16 slice cannot merge until the M06 live Windows gate is complete.

## 8. Recalibrated planning model

M03 demonstrated that a technically coherent architecture can still become an unsafe implementation task when too many independent correctness domains change at once. The project therefore uses the rolling-wave model in `DEC-0033`.

### 8.1 Conceptual epics versus implementation slices

- M04–M17 preserve durable product and architecture outcomes.
- A conceptual epic never receives a direct prompt or implementation pull request.
- Lettered slices are the only directly executable post-M03 work items.
- Each slice is reassessed against the merged repository immediately before prompt drafting.
- Later decompositions are planning defaults rather than frozen class or file designs.

### 8.2 Preliminary decomposition of later conceptual epics

| Conceptual epic | Preliminary slices | Rationale |
|---|---|---|
| M05 application shell | `M05A` GameApp/GameSession lifetime and startup persistence; `M05B` navigation, read models, resizing, and debug access | Separates lifecycle authority from presentation/tooling |
| M06 Steam trusted time | `M06A` GodotSteam bridge/provider and fake-bridge tests; `M06B` transactional offline lifecycle, reconnect, and live Windows proof | Separates native API risk from save/simulation integration |
| M07 dialogue/tutorial framework | `M07A` dialogue presentation and persisted sequence cursor; `M07B` tutorial coordinator, skip/help, and pending reconstruction | Avoids one framework task owning two orchestration systems |
| M08 opening slice | `M08A` Beats 1–3 through Brand; `M08B` first player-facing dispatch | Separates one-time story transactions from Reaping UI integration |
| M09 Archive/Soulweave | `M09A` Archive restoration and Recollection purchase; `M09B` Soulweave topology and Form detail | Separates domain transactions from a thirty-position UI |
| M10 report/Soldier Company | `M10A` 1,000 boundary, Emergency transition, and first report; `M10B` Muster, reservation ledger, and Soldier Company | Separates boundary/report correctness from reservations |
| M11 Scribe | May remain one slice if the fresh assessment stays within guardrails | Current outcome is comparatively cohesive |
| M12 Broken Watch/concurrency | `M12A` resonance, Threshold unlock, and tether grant; `M12B` second Reaping, reassignment, and map integration | Separates exactly-once progression from concurrency |
| M13 discovery | `M13A` discovery state and hidden banking; `M13B` forecast confidence, disclosure UI, and acquisition-progress presentation | Separates authority from presentation |
| M14 Larder/support | `M14A` Hall/recipe simulation and onboarding guarantee; `M14B` Ration consumption, reduced effect, recovery, and UI | Separates producer and consumer/degradation logic |
| M15 regional resonance | May remain one slice if the fresh assessment stays within guardrails | Current outcome is smaller but still requires reassessment |
| M16 offline-return UX | `M16A` forecast/report-history presentation; `M16B` trusted welcome-back, pending state, and tutorial completion | Separates projection UI from live trusted return |
| M17 acceptance | `M17A` functional/softlock/end-to-end acceptance; `M17B` pacing, telemetry, responsive layout, accessibility, and performance | Separates correctness repair from tuning and measurement |

### 8.3 Changes from the starting hypothesis

- State/time, persistence, and content were correctly separated into M01–M03.
- M04 is now split into five approved implementation slices rather than one large vertical-slice pull request.
- Later first-session outcomes remain conceptually ordered but are decomposed only when their repository state is known.
- Reports, forecasts, trusted time, and presentation remain incremental rather than becoming catch-all work.
- M17 remains an acceptance epic and may not absorb unfinished major systems.

## 9. Detailed milestone definitions

### M00 — Repository, Godot, GUT, and Codex Cloud harness

**Definition status:** Approved  
**Prompt status:** Approved  
**Implementation status:** Merged through PR #4  
**Verification status:** Passed  
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

#### Completion record

- PR #4 merged on 2026-07-13.
- Final PR head: `ad9070cb5a8c2d8b5fd8b12f6e134e672f31c91d`.
- Merge commit: `77c618a1d9adbf8b02380d8509d2afb4c4cbc8ea`.
- Linux/Codex Cloud passed full, focused, outside-root, missing/wrong-version, intentional-failure/recovery, and main-scene smoke checks.
- The owner passed Windows full and focused GUT, outside-root execution, editor dry-run smoke, passive Steam configuration, intentional failing-test exit propagation, temporary-file cleanup, and clean full-suite recovery.
- `GATE-GUT` and `GATE-WINDOWS-HARNESS` are satisfied.
- M01 is unblocked for prompt drafting.

#### Known risks

- Future Godot or dependency upgrades require the M00 wrapper and environment checks to be rerun.
- GodotSteam native libraries may expose environment-specific load failures even when Steam is not initialized.
- Windows, visual, editor, persistence, and live Steam checks remain owner-run where later milestones require them.

#### Follow-on dependencies

- All later milestones.

---

### M01 — Deterministic numeric and time-authority foundation

**Definition status:** Approved  
**Prompt status:** Approved  
**Implementation status:** Merged through PR #5  
**Verification status:** Passed  
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
- Implement accepted `DEC-0026`: `1_000_000` subunits per whole fractional unit, unscaled discrete counts, explicit-period rate accumulation, checked 64-bit arithmetic, whole-unit extraction, and canonical residual semantics.
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
- `tests/support/fake_monotonic_clock.gd` and `fake_trusted_time_provider.gd`
- `tools/test/traces/m01_time_foundation_trace.gd`
- `tools/test/owner/run_m01_owner_verification.ps1` and ignored generated logs

#### Data and content required

- Accepted `FixedPoint.SCALE = 1_000_000` under `DEC-0026`, explicit rate periods, plus named trusted-time statuses and diagnostic codes. These are architecture constants, not balance values.

#### Acceptance criteria

- Fixed-point operations, explicit-period accumulation, whole-unit extraction, and residuals are exact for documented prototype bounds and fail clearly on unsupported overflow.
- Whole inventory/backlog counts remain unscaled integers, while one-item-per-8-hours and one-item-per-24-hours fractional progress reaches exact quarter-progress and one whole unit at the full period.
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
- Long-horizon rate tests: one whole item per eight hours and per twenty-four hours, exact quarter-progress, whole-unit extraction, and equivalent chunks.

#### Manual verification

- Codex creates `tools/test/owner/run_m01_owner_verification.ps1` under `OWNER_VERIFICATION_WORKFLOW.md`.
- The owner runs one PowerShell entry point against the PR head; it executes the full/focused Windows suite and deterministic trace and writes a UTF-8 log under `tools/test/owner/logs/`.
- No separate visual or editor checklist is required because M01 has no player-facing presentation.

#### Demonstration path

- Anchor at a known trusted value.
- Credit ten minutes of fake monotonic foreground time.
- Advance the fake trusted source by one hour.
- Show that only fifty minutes are returned for closed-session resolution and a repeated sample returns zero.

#### Save/load expectations

State classes expose explicit primitive conversion hooks where useful, but no file or stable schema is committed until M02.

#### Documentation updates

- `ARCHITECTURE.md`, `DATA_AND_CONTENT_CONTRACTS.md`, `IMPLEMENTATION_RULES.md`, `TESTING_AND_VALIDATION.md`, `DECISIONS.md`, and `MILESTONES.md`; `OWNER_VERIFICATION_WORKFLOW.md` changes only if implementation exposes a generic workflow defect.

#### Completion record

- PR #5 merged on 2026-07-14.
- Final PR head: `e2b291e75dab5e3484da7dec1d4420a2fb9637be`.
- Merge commit: `a5b231682967e4cb71b4404af158e93ff8bbf261`.
- Added `FixedPoint`, minimal `GameState`, separate `TimeAuthorityState`, monotonic/trusted-time contracts, fake providers, and `TimeReconciliationService`.
- Added focused M01 GUT tests, source-ownership test, deterministic trace, and owner PowerShell verification package.
- Linux/Codex full and focused suites and deterministic trace passed.
- The owner passed the Windows full suite (`12/12` tests), focused M01 suite (`10/10` tests), source-ownership checks, import preflight, deterministic trusted-time trace, fixed-point 24-hour trace, cleanup, and generated-log checks at the final PR head.
- `GATE-FIXED-POINT` is satisfied.

#### Known risks

- Incorrect anchor updates can lose or duplicate time.
- Fixed-point bounds that are too small can force later migration; bounds must be documented conservatively.

#### Follow-on dependencies

- M02, M04, M06, M16.

---

### M02 — Versioned save codec and atomic storage

**Definition status:** Approved  
**Prompt status:** Approved  
**Implementation status:** Merged through PR #6  
**Verification status:** Passed  
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

- `src/persistence/` schema mapper, codec interface, JSON codec, validation, migration registry, save service, storage abstraction, and file storage
- Schema version and representative fixture files
- `tests/unit/persistence/`, `tests/integration/save_load/`, and save fixtures
- `tools/test/m02/` headless persistence trace
- `tools/test/owner/run_m02_owner_verification.ps1` and ignored generated logs
- Documentation of the prototype save directory, isolated test directory, and reset procedure

#### Data and content required

- `codec_id`, schema version, content revision placeholder, save revision, `TimeAuthorityState`, minimal `GameState`, and transaction metadata.

#### Acceptance criteria

- Values at and beyond `2^53`, representative trusted epoch values, signed 64-bit limits, and representative fixed-point residual integers round-trip exactly through the shared integer codec. M02 does not add a production residual field solely for this test; later runtime state uses the same codec when residual fields are introduced.
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

- Codex creates `tools/test/owner/run_m02_owner_verification.ps1` under `OWNER_VERIFICATION_WORKFLOW.md`.
- The owner runs one PowerShell entry point against the PR head. The script uses an isolated Windows temporary directory, runs the full and focused suites, writes two revisions, corrupts the primary, verifies backup selection and suspect-file retention, exercises Windows rename/replacement behavior, cleans the temporary directory, reruns the clean suite, and writes one UTF-8 log.
- No separate visual checklist is required because M02 has no player-facing save UI.

#### Demonstration path

- Write revision 1.
- Write revision 2 through the atomic path.
- Corrupt the primary.
- Load revision 1 backup successfully and show the diagnostic.

#### Save/load expectations

This milestone establishes schema version 1, codec ID, transaction rules, and backup behavior. All later authoritative state must extend this schema and add fixtures/tests.

#### Documentation updates

- `ARCHITECTURE.md`, `DATA_AND_CONTENT_CONTRACTS.md`, `IMPLEMENTATION_RULES.md`, `TESTING_AND_VALIDATION.md`, `MILESTONES.md`, and `README.md`; `OWNER_VERIFICATION_WORKFLOW.md` changes only if implementation exposes a generic workflow defect.

#### Completion record

- PR #6 merged on 2026-07-14.
- Final PR head: `0dd0c1d5c799db45aa4a8387d93750e02b2e485f`.
- Merge commit: `480a9eae2fe0c3591503da56b07c272be74ec027`.
- Added schema-version-1 runtime mapping, deterministic `JSON_V1`, canonical signed-64-bit string encoding, sequential primitive migrations, injectable storage, primary/temporary/backup transactions, suspect preservation, and working-candidate reconciliation persistence.
- Linux/Codex passed the focused M02 suite (`17/17`), full suite (`29/29`), source-ownership checks, and real-file corruption/recovery trace.
- The owner passed the Windows full suite before and after the trace (`29/29` each), focused M02 suite (`17/17`), import preflight, revision/backup/corruption fallback trace, corrupt-byte retention, cleanup, and generated-log contract at the final head.
- `GATE-SAVE-SCHEMA` is satisfied.

#### Known risks

- Windows rename and file-lock behavior.
- Accidentally coupling migrations to JSON instead of primitive schema.
- Misleading checksum or encryption language.

#### Follow-on dependencies

- M03 onward.

---

### M03 — Content catalog, canonical IDs, and configurable prototype data

**Definition status:** Approved  
**Prompt status:** Approved  
**Implementation status:** Merged through PR #7  
**Verification status:** Passed  
**Recommended Codex task size:** Medium-large but bounded to authored data, normalization, validation, save-revision compatibility, and developer verification.  
**Planned prompt file:** `docs/codex/milestone-prompts/M03-content-catalog-prototype-data.md`

#### Purpose

Create the typed authored-data layer and validation grammar before systems hard-code prototype content.

#### Player or developer outcome

The Godot editor loads one explicit prototype catalog containing the approved Forms, Thresholds, output channels, Writs, Retinue, Halls, recipe, items, Recollections, milestones, guarantees, resonances, narrative identities, tutorial states, and a centralized terminology catalog. Player-facing names can change without changing canonical IDs, the sole resource term is Essence, the registry presents deterministic normalized data, existing M02 saves are accepted through an explicit compatibility list, and invalid catalogs fail with aggregated actionable diagnostics.

#### Dependencies

- M00, M01, and M02 merged and Passed.
- `GATE-GUT`, `GATE-FIXED-POINT`, and `GATE-SAVE-SCHEMA` satisfied.
- Accepted `DEC-0029` through `DEC-0032`.

#### Included scope

- Implement typed custom `Resource` definitions and an explicit `ContentCatalog` stored as text `.tres` files.
- Implement editable fallback names/optional localization keys and one `CoreTerminologyDefinition` using stable `TERM_...` entries.
- Use stable inline Trait IDs with editable names; prepare the base naming contract for future Arts and Denizens without implementing those systems.
- Implement `ContentRegistry` structural validation, production completeness validation, canonical ordering, ID-prefix checks, reference/type validation, authored-float normalization, and source-Resource isolation.
- Implement only the finite modifier, condition, target-scope, progression-effect, cost, and reward grammars already required by the prototype.
- Author the established prototype IDs and centrally labelled scaffold values from `DATA_AND_CONTENT_CONTRACTS.md`, using `RES_ESSENCE` and the approved Essence channel IDs.
- Add first-class stable `CHANNEL_...` definitions for the six current Threshold item channels. Backlog and active Form Mastery remain core streams rather than item-channel definitions.
- Define immutable baseline channel rates, explicit periods, progress-display flags, and modifier inputs needed by `DEC-0027` and `DEC-0028`, without implementing accumulation or effective-rate evaluation.
- Establish catalog revision `prototype-content-r1` with an explicit compatibility allowlist containing `prototype-m02` and the current revision.
- Require new saves to receive the current catalog revision explicitly; keep persistence independent of `ContentRegistry` and leave schema version 1 unchanged.
- Provide valid and invalid fixture coverage, a deterministic headless catalog trace, a Windows owner script, and an Inspector checklist.

#### Explicit non-goals

- Gameplay state, production resolution, inventory, dispatch, acquisition progress, modifier evaluation, progression application, tutorial control, save UI, or player-facing screens.
- Functional implementation of the remaining twenty-eight Forms, any Form Art behavior, Denizen Souls, Roadwarden content, advanced Writs, additional Retinues, multiple recipes, final dialogue, a complete translation/localization pipeline or translated content, final art, or final balance. Optional localization keys and fallback English text are in scope.
- Recursive directory discovery, arbitrary expression evaluation, Callables, or script paths embedded in content.
- A save-schema version bump or serialization of immutable definitions, effective rates, ETAs, or future gameplay dictionaries.

#### Expected files or subsystems

- `src/content/definitions/` typed Resource classes and bounded supporting Resources.
- `src/content/content_catalog.gd`, `content_registry.gd`, validation/result types, finite grammar constants, and normalized runtime records.
- `content/prototype_content_catalog.tres` plus referenced production `.tres` definitions.
- `tests/unit/content/`, `tests/integration/content/`, and fixture Resources or builders.
- `tools/test/m03/m03_content_catalog_trace.gd`.
- `tools/test/owner/run_m03_owner_verification.ps1` and ignored generated logs; prior ignored owner logs must not cause artifact-audit failure.
- `docs/codex/owner-checklists/M03-owner-verification.md`.
- Focused persistence changes that require an explicit content revision and validate compatibility without importing content into `SaveService`.

#### Data and content required

- Fifty-four required top-level definitions plus six first-class output-channel definitions, plus one core terminology Resource containing twenty `TERM_...` entries.
- Required identities include `RES_ESSENCE`, the approved Essence channels, `TRAIT_OLD_DRILL`, `TRAIT_UNCLOSED_LEDGER`, and all stable IDs in the current contract.
- Forms: Man-at-Arms and Scribe only as functional Forms.
- Items, Thresholds, Writs, Soldier Company, Archive, Larder, one recipe, five Recollections, six milestones, six guarantees, two resonances, fourteen tutorial states, and five narrative identities.
- Accepted catalog revision/compatibility, channel-ID, editable naming, centralized terminology, and Essence identity contracts in `DEC-0029` through `DEC-0032`.
- All rates, costs, coefficients, floors, durations, and rewards identified as prototype scaffold remain editable content and change the content revision when adjusted.

#### Acceptance criteria

- The production catalog loads from one explicit root and contains every required definition exactly once.
- Display names and shared terminology are editable content; lookups, rules, and saves remain keyed by canonical IDs.
- Renaming Unclosed Ledger, a Recollection, or `TERM_THRESHOLD` changes presentation data without changing Form/`REC_...`/`THR_...` identity or save compatibility.
- `RES_ESSENCE`, `CHANNEL_GLOAMWOOD_ESSENCE`, and `CHANNEL_BROKEN_WATCH_ESSENCE` are the only production Essence identities; deprecated IDs are rejected.
- Duplicate IDs, wrong prefixes, missing/wrong-type references, missing required definitions, unsupported grammar tokens, invalid costs/rates/periods, invalid Soldier requirement, invalid recipes, invalid tutorial states, and invalid compatibility lists fail with stable field-level diagnostics.
- Registry lookup and iteration use deterministic canonical ID order and never depend on filesystem enumeration or `Dictionary` insertion order.
- Normalized runtime values contain fixed-point integers and explicit periods rather than authoritative floats; mutating a source Resource after registry construction cannot change normalized data.
- Man-at-Arms and Scribe have data-driven, mechanically distinct modifiers and slot profiles without display-name branching.
- Long-horizon channel definitions use stable `CHANNEL_...` IDs, whole-item outputs, explicit stable periods, and valid progress-display metadata.
- Existing `prototype-m02` saves are explicitly compatible; new save snapshots receive `prototype-content-r1`; an unknown revision is rejected before simulation without a schema bump.
- Provisional values live in `.tres` data, not UI, tutorial, save, or registry code.
- The valid catalog trace, invalid duplicate-ID trace, and provisional-override normalization trace pass.
- Linux full/focused tests, Windows owner script, and Inspector checklist pass before merge.

#### Automated verification

- Valid production catalog and deterministic summary.
- Required-ID completeness and global uniqueness.
- Prefix, reference, type, grammar, range, period, progress-display, recipe, Retinue, tutorial, and revision-compatibility matrices.
- Authored-float normalization and source-mutation isolation.
- Data-driven Man-at-Arms/Scribe distinction.
- Existing M02 save compatibility, current-revision save creation, and unknown-revision rejection.
- Full regression suite and parser/resource import.

#### Manual verification

- Codex creates `tools/test/owner/run_m03_owner_verification.ps1` under `OWNER_VERIFICATION_WORKFLOW.md` to run full/focused suites, import, trace, and clean regression with one generated log.
- Codex creates `docs/codex/owner-checklists/M03-owner-verification.md` for Godot Inspector review of the catalog, representative definitions, typed fields, Resource references, provisional values, editable names, stable Trait IDs, and core terminology entries.
- No gameplay or visual-presentation checklist is required.

#### Demonstration path

- Load the production catalog and print revision, compatibility list, per-group counts, canonical IDs, and representative normalized values.
- Show the eight-hour Scribe Soul and twenty-four-hour Man-at-Arms Soul channel periods and progress-display metadata.
- Load an invalid duplicate-ID catalog and print the stable actionable error.
- Load or construct a provisional override and show the normalized value changing without code changes.
- Validate an M02 save revision as compatible and reject an unknown revision.

#### Save/load expectations

Schema version 1 and its key spelling remain unchanged. New-save calls pass the current catalog revision explicitly. `prototype-m02` remains compatible because M02 saves contain only the minimal M01 state and no content IDs. Immutable definitions, effective rates, ETAs, and catalog Resources are never serialized. Later gameplay fields reference canonical IDs and use the same revision policy.

#### Documentation updates

- `DATA_AND_CONTENT_CONTRACTS.md`, `ARCHITECTURE.md`, `IMPLEMENTATION_RULES.md`, `TESTING_AND_VALIDATION.md`, `MILESTONES.md`, and `README.md` as made inaccurate by the implementation.
- `DECISIONS.md` records accepted `DEC-0029` through `DEC-0032`.
- Design source-of-truth files change only if an approved content identity changes.

#### Completion record

- PR #7 merged on 2026-07-15.
- Final PR head: `971cdaa0fd46f641ec7409148e259d54f953d8c7`.
- Merge commit: `5e2b9b23878c9280f75b987cc9ad567d8980030d`.
- Added typed definition families and subresources, one explicit grouped catalog, the exact sixty canonical definitions, twenty singular/plural terminology entries, deterministic normalization/validation, revision compatibility, and content-only derived previews.
- Corrected and validated Threshold backlogs/tags, channel discovery/frequency metadata, modifier operands, milestone/guarantee mappings, resonance effects, and editable naming isolation.
- Linux/Codex and owner Windows verification passed the full suite (`42/42`, `496` assertions), focused M03 suite (`13/13`, `243` assertions), import, semantic trace, artifact audit, and Inspector checklist.
- `GATE-CONTENT-CATALOG` is satisfied.

#### Known risks

- Overbuilding a generic rules engine instead of the finite prototype grammar.
- Resource circular references, editor import ordering, or source-Resource mutation leaking into normalized runtime data.
- Treating display names or filenames as stable IDs.
- Silently accepting incompatible save content revisions.
- Provisional scaffold values being mistaken for final balance.

#### Follow-on dependencies

- M04A–M04E and every later content-driven implementation slice.

---

### M04 — Persistent Reaping simulation vertical slice

**Work item type:** Conceptual epic  
**Definition status:** Approved  
**Prompt status:** Not applicable — no direct epic prompt  
**Implementation status:** Not directly executable  
**Verification status:** —  
**Decomposition:** M04A → M04B → M04C → M04D → M04E

#### Purpose

Prove the core idle machinery before narrative and production UI are layered over it, while keeping state, commands, simulation, long-horizon channels, forecasts, and reports reviewable as separate slices.

#### Epic outcome

After M04A–M04E pass, one Gloamwood Reaping led by Man-at-Arms can be constructed, dispatched, advanced deterministically, saved, loaded, recalled, redispatched, forecast on a clone, and reported without claim-gating. Backlog, Essence, Mastery, and configured output channels use one scene-independent rules path.

#### Epic completion rule

M04 is complete only when M04A through M04E are all Merged and Passed. No `M04-persistent-reaping-simulation.md` prompt is valid.

---

### M04A — Gameplay state and persistence foundation

**Work item type:** Implementation slice  
**Parent epic:** M04  
**Definition status:** Approved  
**Prompt status:** Approved  
**Implementation status:** Merged through PR #8  
**Verification status:** Passed  
**Recommended Codex task size:** Small-medium; one authoritative-state and schema-migration pull request.  
**Planned prompt file:** `docs/codex/milestone-prompts/M04A-gameplay-state-persistence-foundation.md`

#### Purpose

Create the smallest scene-independent gameplay aggregate that later assignment and simulation slices can use, and establish the first production save migration without mixing in elapsed production.

#### Player or developer outcome

A developer can construct one valid Gloamwood/Man-at-Arms state fixture, validate it against the M03 catalog, deep-clone it, save it as schema version 2, load it exactly, and migrate a real schema-version-1 foundation save transactionally without losing the original valid bytes.

#### Dependencies

- M03 Merged and Passed; `GATE-CONTENT-CATALOG` satisfied.
- `GATE-GAMEPLAY-SCHEMA` satisfied for prompt drafting by accepted `DEC-0034`.
- `GATE-SLICE-SCOPE` is satisfied by the approved M04A prompt's completed scope assessment.
- Existing M02 codec, migration registry, primary/temporary/backup storage, and failure injection remain the persistence foundation.

#### Included scope

- Add typed `InventoryState`, `InventoryEntryState`, `FormState`, `ThresholdState`, `ThresholdAcquisitionState`, `ReapingState`, and `ProgressionState` owned by `GameState`.
- Implement deterministic state validation, exact explicit deep cloning, and a hand-calculable Gloamwood/Man-at-Arms fixture. No generic reflection serializer or object dump is permitted.
- Validate canonical IDs and authored bounds through the already-built M03 `ContentRegistry` while keeping `SaveService` content-agnostic.
- Introduce schema-version constants for frozen version 1 and current version 2, preserve a version-1 validator/fixture, and add a version-dispatching validator.
- Implement the exact version-2 wire shape and explicit runtime mapping in `DATA_AND_CONTENT_CONTRACTS.md`.
- Implement the production sequential `v1 -> v2` primitive-dictionary migration accepted in `DEC-0034`.
- Add a scene-independent runtime persistence coordinator or equivalent working-candidate boundary that validates schema, migration, domain state, and content compatibility, atomically persists a required upgrade, and exposes live runtime state only after success.
- Preserve the original version-1 candidate on every migration, validation, revision-overflow, or write failure. Already-current version-2 loads must not rewrite automatically.
- Add immutable schema-version-1 and representative schema-version-2 fixtures, focused tests, a deterministic real-file headless trace, and one Windows owner-verification script/log package.
- Update maintained documentation made inaccurate by the implementation.

#### Explicit non-goals

- Dispatch, recall, tether grants, assignment commands, or assignment mutation.
- Elapsed production, backlog reduction, Essence gain, Mastery gain, channel accumulation, forecasts, reports, milestones, guarantees, or progression effects.
- New-game story/bootstrap behavior, opening-four state, tutorial state, Halls, Recollections, or player-facing save/reset UI.
- Steam initialization, trusted-time-provider changes, closed-session resolution changes, Steam Cloud, multiple slots, encryption, compression, binary codecs, or anti-tamper claims.
- Updating schema version for speculative later substates. Later persisted meaning changes use later explicit schema decisions/migrations.

#### Expected files or subsystems

- `src/domain/` or `src/domain/state/` typed gameplay-state classes and validation/clone support.
- `src/persistence/save_envelope.gd`, version-aware validators/mappers, production migration registration, and a narrow validated-runtime load/save coordinator.
- Existing `SaveService`, codec, and storage modified only as required for version-aware candidates and transactional upgrade persistence.
- `tests/unit/m04a/`, `tests/integration/m04a/`, and immutable save fixtures.
- `tools/test/m04a/m04a_state_persistence_trace.gd`.
- `tools/test/owner/run_m04a_owner_verification.ps1` and ignored generated logs.
- Documentation listed by the approved prompt.

#### Data and content required

- Schema version 1 remains the frozen M02 input; schema version 2 becomes the current M04A writer.
- Codec ID remains `JSON_V1`.
- M03 catalog revision compatibility remains independent of schema migration.
- Representative state uses `FORM_MAN_AT_ARMS`, `THR_GLOAMWOOD`, `WRIT_STANDARD`, `RES_ESSENCE`, and applicable Gloamwood channel IDs.
- Migration default adds empty gameplay maps and command-tether capacity zero; it grants or unlocks nothing.

#### Acceptance criteria

- A valid typed fixture constructs and validates without a scene tree, clock, Steam client, or UI.
- Clone mutation cannot affect the baseline at any nesting depth.
- Invalid negative counts, reservation over-commitment, unresolved/wrong-type IDs, contradictory lifecycle state, invalid channel ownership/carry, inactive/active Reaping contradictions, and tether over-capacity fail without partial live mutation.
- Version-1 key spelling/meaning and validator remain intact after version 2 becomes current.
- Version-2 snapshots use the exact approved key set and canonical integer-string rules.
- The production `v1 -> v2` migration preserves all version-1 authority and adds only canonical empty gameplay state.
- Migration validates source and target, preserves content revision, and never invents progress or achievements.
- A required migrated upgrade increments save revision once and is atomically persisted before runtime state is exposed.
- Migration or write failure preserves the original valid version-1 bytes and exposes no migrated live state.
- A successful upgrade retains a recoverable prior valid snapshot under the M02 transaction rules.
- Already-current version-2 load performs no automatic rewrite or revision increment.
- Unknown future schema and incompatible content revision are rejected without overwrite.
- New saves write schema version 2 and the current content revision explicitly through the validated coordinator.
- A developer reset, if implemented, is explicit, preserves/archive the old file, and is not used as the supported migration path.
- Linux full/focused tests, Windows owner automation, real-file trace, cleanup, and clean regression pass before merge.

#### Automated verification

- Typed construction, domain validation, clone isolation, and exact equality.
- Version-1 and version-2 structural validators and malformed-input matrices.
- Exact runtime ↔ primitive ↔ JSON ↔ primitive ↔ runtime round trips.
- Sequential migration, missing-step, future-version, revision-overflow, incompatible-content, and already-current no-rewrite tests.
- Atomic failure injection at every migration-upgrade write boundary, proving original/fallback preservation and no live-state exposure.
- Real-file trace with version-1 primary, successful version-2 upgrade, save-revision increment, prior-version backup, exact time-state preservation, and cleanup.
- Full regression suite.

#### Manual verification

- Codex creates `tools/test/owner/run_m04a_owner_verification.ps1` under `OWNER_VERIFICATION_WORKFLOW.md`.
- The owner runs one PowerShell entry point against the PR head. It uses an isolated Windows temporary directory, runs full/focused suites, import, the real-file migration trace, cleanup, and the clean full suite again, then writes one UTF-8 log.
- Git CLI remains optional. Prior ignored owner logs do not fail artifact checks.
- No visual or Inspector checklist is required because M04A adds no player-facing UI or authored Resource type.

#### Demonstration path

- Construct and validate the Gloamwood/Man-at-Arms fixture.
- Deep-clone it and mutate nested inventory, Threshold, and acquisition values to prove isolation.
- Save and reload a version-2 snapshot and compare exact state.
- Write a canonical version-1 foundation save in an isolated directory.
- Load it through the migration coordinator, persist version 2, verify revision increment and version-1 backup, and compare preserved simulation/time-authority fields plus canonical empty gameplay defaults.
- Clean the isolated directory and rerun the full suite.

#### Save/load expectations

M04A makes schema version 2 current. Version 1 remains a supported historical input with an immutable fixture and production migration. Migration works on a candidate, validates domain/content compatibility, persists atomically, and exposes runtime only after success. The current JSON codec and primary/temporary/backup roles remain unchanged.

#### Documentation updates

- `DECISIONS.md`, `DATA_AND_CONTENT_CONTRACTS.md`, `ARCHITECTURE.md`, `IMPLEMENTATION_RULES.md`, `TESTING_AND_VALIDATION.md`, `MILESTONES.md`, and `README.md` where implementation makes them inaccurate.
- `OWNER_VERIFICATION_WORKFLOW.md` changes only if implementation exposes a generic workflow defect.

#### Completion record

- PR #8 merged on 2026-07-16.
- Final PR head: `04b12d8ba2edeecbf13f252216249341469b40a8`.
- Merge commit: `673ad884357fc742a0a26dbb542d5b8d9fe557c9`.
- Added typed gameplay-state families, deep-clone isolation, content-aware validation, schema version 2, frozen schema-version-1 support, immutable v1/v2 fixtures, and a production sequential migration.
- Corrected the upgrade path so non-empty metadata, offline-resolution identity, content revision, simulation time, and time-authority state remain preserved before only the save revision changes.
- Added expanded state/schema/migration failure matrices, StringName-to-wire-key normalization, a real-file trace, and a Windows PowerShell owner package with guaranteed cleanup and artifact auditing.
- Linux/Codex focused/import/trace/full checks passed.
- Owner Windows verification passed against the final head:
  - full suite before and after: `59/59` tests and `722` assertions;
  - focused M04A: `16/16` tests and `207` assertions;
  - import, six trace markers, cleanup, cleanup proof, artifact audit, and final summary passed;
  - failed step count `0`; no interactive checks required.
- Final pull-request scope: 28 changed files, 1,352 additions, and 61 deletions; it remained inside the approved M04A guardrails.
- `GATE-GAMEPLAY-SCHEMA` is satisfied.

#### Known risks

- Future schema changes still require explicit versioning and migrations.
- Assignment services must not mutate persistence primitives directly.
- M04B must preserve the stable state/carry ownership established here.

#### Follow-on dependencies

- M04B.

---

### M04B — Dispatch, recall, and assignment integrity

**Work item type:** Implementation slice  
**Parent epic:** M04  
**Definition status:** Approved  
**Prompt status:** Drafted  
**Implementation status:** Not started  
**Verification status:** —  
**Recommended Codex task size:** Small-medium; one command/assignment pull request.  
**Planned prompt file:** `docs/codex/milestone-prompts/M04B-dispatch-recall-assignment-integrity.md`

#### Purpose

Establish valid persistent assignment state before any elapsed production depends on it.

#### Player or developer outcome

Through commands and tests, Man-at-Arms can be dispatched to Gloamwood, recalled, and redispatched while one tether, one-Reaping-per-Threshold, and assignment revision remain exact.

#### Dependencies

- M04A Merged and Passed.
- `GATE-SLICE-SCOPE` is completed in the M04B draft and must be approved with the prompt.
- `GATE-REAPING-ASSIGNMENT` is pending approval of proposed `DEC-0035`.

#### Included scope

- Add one focused Reaping assignment service with initial dispatch, recall, and redispatch of an inactive record.
- Use typed command inputs/results, stable rejection codes, ordered assignment events, and save-checkpoint requests.
- Validate awakened and active-unique Form, available Threshold, enabled Writ, exact expected revision, tether capacity, and duplicate occupancy before mutation.
- Retain one stable Reaping record per Threshold through recall; derive tether occupancy from active records.
- Increment assignment revision exactly once only on committed changes; check overflow and stale input.
- Preserve Threshold-owned state and frozen operation phase/carries. Reject a changed Form/Writ with unresolved rate-dependent phase/carry until later resolution exists.
- Preserve assignment state across schema-v2 save/load without a schema bump.
- Add invalid-command no-mutation tests, a headless assignment/save trace, and one M04B Windows owner package.

#### Explicit non-goals

- Elapsed production, command-time advancement, backlog reduction, Essence, Mastery, output channels, forecasts, reports, UI, or tutorial flow.
- Active in-place Form/Writ reconfiguration with nonzero production state; M04C/M04D own resolve-before-change behavior.
- Retinue assignment, support buffers, second tether grants, or second-Threshold progression.

#### Acceptance criteria

- A valid initial dispatch creates revision 1, one active assignment, one derived occupied tether, and one committed event without advancing simulation time.
- Invalid Form, Threshold, Writ, capacity, duplicate Threshold, already-assigned Form, or stale revision fails without partial mutation.
- Recall retains the stable record, freezes operation-owned state, frees the derived tether, and increments the revision once.
- Redispatch of the inactive record increments once, preserves the original start timestamp and Threshold-owned progress, and updates the configuration timestamp.
- Repeating or replaying a stale command cannot duplicate a Reaping, tether, event, or revision increment.
- Changed Form/Writ with nonzero rate-dependent operation state is rejected until later resolve-before-change support exists.
- Save/load preserves active/inactive assignment, Form/Writ IDs, revision, timestamps, frozen phase/carries, and Threshold progress.
- No schema bump, elapsed production, clock read, or file write occurs inside the assignment service.

#### Automated verification

- Dispatch/capacity/duplicate/Form-exclusivity/stale-revision matrix.
- Recall/redispatch continuity, overflow, no-op, and resolve-required cases.
- Typed result/event/save-checkpoint contract.
- Active and inactive schema-v2 round trips and malformed-assignment rejection.
- Full regression, deterministic assignment trace, and owner Windows package.

#### Manual verification

- Codex creates `tools/test/owner/run_m04b_owner_verification.ps1`; the owner runs one generated-log package against the PR head.
- No editor, visual, gameplay, audio, A/B, or Steam checklist is required because M04B exposes no player-facing UI.

#### Demonstration path

- Construct an available Gloamwood, awakened Man-at-Arms, one-tether state at a known simulation cursor.
- Dispatch with Standard Writ and show revision 1, one occupied tether, one event, and unchanged simulation time.
- Reject duplicate/stale commands with exact state equality.
- Save/load the active record.
- Recall to revision 2, prove tether release and preserved Threshold/operation state, then save/load inactive state.
- Redispatch to revision 3, prove one tether occupied again, and show zero production delta.

#### Save/load expectations

Schema version 2 already persists every M04B field. Active and inactive records, revisions, timestamps, and frozen operation/Threshold state round trip exactly. Tether occupancy remains derived and is not serialized. M04B does not bump the schema.

#### Follow-on dependencies

- M04C.

---

### M04C — Single-Reaping core resolver

**Work item type:** Implementation slice  
**Parent epic:** M04  
**Definition status:** Approved  
**Prompt status:** Not drafted  
**Implementation status:** Not started  
**Verification status:** —  
**Recommended Codex task size:** Medium; one deterministic core-stream simulation pull request.  
**Planned prompt file:** `docs/codex/milestone-prompts/M04C-single-reaping-core-resolver.md`

#### Purpose

Implement one deterministic elapsed-time resolver for Gloamwood backlog, Essence, and Man-at-Arms Mastery before item channels or projection systems are added.

#### Player or developer outcome

A developer can supply elapsed milliseconds to one active Reaping and obtain exact backlog, Essence, Mastery, lifecycle, and residual state that is invariant under equivalent chunking.

#### Dependencies

- M04B Merged and Passed.
- `GATE-SLICE-SCOPE` satisfied for the M04C prompt.

#### Included scope

- Add the scene-independent core `SimulationEngine` path for one active Reaping.
- Resolve backlog returns, Essence, and active Form Mastery from normalized M03 content.
- Preserve fixed-point residuals and integer time units.
- Implement deterministic boundary ordering, Overdue-to-Settled transition for core streams, and zero-duration-loop protection.
- Expose supplied-duration and debug-advance adapters that call the same resolver.
- Persist core counters, lifecycle state, and residuals.

#### Explicit non-goals

- Item output channels, discovery, long-horizon progress, loadout rate changes, forecasts, reports, milestones, guarantees, UI, or trusted-time adapters.

#### Acceptance criteria

- One interval and equivalent chunks produce identical authoritative state.
- Backlog never becomes negative; zero backlog transitions lifecycle exactly once.
- Essence banks immediately and Mastery accumulates independently from backlog.
- Inactive or recalled assignments produce no progress.
- The resolver reads no clock, scene, frame, input, Steam, or UI state.
- A zero-time boundary without state change fails clearly rather than looping.
- Save/load preserves core progress and residuals exactly.

#### Automated verification

- Repeatability and chunking matrices.
- Backlog/Essence/Mastery independence.
- Overdue-to-Settled core transition.
- Inactive assignment, invalid elapsed, overflow, and zero-time-loop failures.
- Save round trip and full regression.

#### Manual verification

- Owner automation and deterministic trace only; no visual checklist.

#### Demonstration path

- Dispatch the M04B fixture.
- Advance a small hand-calculable interval once and in chunks.
- Print identical backlog, Essence, Mastery, lifecycle, and residual state.
- Save/load and repeat.

#### Save/load expectations

Persist every new core counter and residual through the M04A-approved schema policy with exact integer strings and fixtures.

#### Follow-on dependencies

- M04D.

---

### M04D — Output channels and long-horizon acquisition progress

**Work item type:** Implementation slice  
**Parent epic:** M04  
**Definition status:** Approved  
**Prompt status:** Not drafted  
**Implementation status:** Not started  
**Verification status:** —  
**Recommended Codex task size:** Medium; one Threshold-channel accumulation pull request.  
**Planned prompt file:** `docs/codex/milestone-prompts/M04D-output-channels-long-horizon-progress.md`

#### Purpose

Add Threshold-owned item-channel accumulation and prove that long-horizon normalized work survives configuration changes without compounding bonuses.

#### Player or developer outcome

Configured Gloamwood channels bank whole items while preserving exact partial progress and carry through recall, redispatch, rate changes, settlement, and save/load.

#### Dependencies

- M04C Merged and Passed.
- `GATE-SLICE-SCOPE` satisfied for the M04D prompt.
- Accepted `DEC-0027`, `DEC-0028`, and M03 channel contracts.

#### Included scope

- Accumulate configured M03 item channels independently from backlog, Essence, and Mastery.
- Store durable progress by `Threshold ID + Channel ID`.
- Extract whole inventory units and retain normalized progress/carry.
- Freeze progress while inactive and resume it on redispatch.
- Resolve the old rate to a command/modifier boundary, then derive future rate from immutable baseline plus current bounded modifier context.
- Preserve progress through Overdue-to-Settled when the channel remains available.
- Persist inventory, per-channel progress, and carry.

#### Explicit non-goals

- Player-facing progress bars, discovery disclosure, Retinue/Recollection purchase systems, forecast UI, reports, randomness, or additional Thresholds.
- A complete future modifier framework; implement only the bounded rate-plan seam required by the tested contexts.

#### Acceptance criteria

- One-item-per-eight-hours and one-item-per-twenty-four-hours channels reach exact quarter progress and whole extraction.
- Whole inventory remains unscaled; no fractional Soul is stored.
- Recall freezes and redispatch resumes the same Threshold/channel progress.
- Changing the future rate preserves stored normalized work and exact carry.
- A four-hour fixture at `50.0%` remains `50.0%` after a 20% future rate increase while ETA changes from two hours to one hour forty minutes.
- Repeating recall/redispatch with unchanged state does not apply the bonus again.
- Effective rate is re-derived from baseline content rather than the prior effective rate.
- Equivalent chunks and save/load yield identical inventory, progress, and carry.
- Settlement does not reset a retained channel.

#### Automated verification

- Eight-/twenty-four-hour exact cases and multiple-whole extraction.
- Recall/redispatch, rate-boundary, non-compounding, settlement, overflow, and chunking matrices.
- Threshold/channel ownership validation and save round trip.
- Full regression and long-horizon trace.

#### Manual verification

- Owner automation only; disclosure and progress-bar observation remain M13.

#### Demonstration path

- Advance the long-horizon fixture to partial progress.
- Recall, change the bounded rate context, redispatch, and compare progress versus ETA.
- Complete one whole item, save/load, and prove exact carry.

#### Save/load expectations

Persist per-channel progress and arithmetic carry with one documented owner. Unknown disclosure does not remove or rewrite authoritative progress.

#### Follow-on dependencies

- M04E.

---

### M04E — Forecast clone, report accumulator, and simulation harness

**Work item type:** Implementation slice  
**Parent epic:** M04  
**Definition status:** Approved  
**Prompt status:** Not drafted  
**Implementation status:** Not started  
**Verification status:** —  
**Recommended Codex task size:** Medium; one projection/report/developer-harness pull request.  
**Planned prompt file:** `docs/codex/milestone-prompts/M04E-forecast-report-simulation-harness.md`

#### Purpose

Complete the non-UI Reaping epic by adding clone-based forecast, already-applied report deltas, and one deterministic developer demonstration without creating another rules path.

#### Player or developer outcome

A developer can forecast one hour on a deep clone, commit the same supplied interval separately, compare exact results, inspect already-applied report deltas, clear/snapshot the accumulator without changing inventory, and repeat after save/load.

#### Dependencies

- M04D Merged and Passed.
- `GATE-SLICE-SCOPE` satisfied for the M04E prompt.

#### Included scope

- Add forecast service on a deep clone using the M04C/M04D resolver.
- Provide supplied-duration live, offline-fixture, forecast, and debug adapters with one rule path; no trusted-time acquisition is added.
- Add report accumulator entries for already-committed deltas and bounded snapshot/clear foundations needed by later UI.
- Persist report state only if it becomes authoritative in this slice.
- Add a deterministic developer harness/trace and slice-specific owner script.

#### Explicit non-goals

- Player-facing report or forecast screens, application shell, Steam time, welcome-back UX, tutorial, narrative, milestones, or claim buttons.

#### Acceptance criteria

- Forecast never mutates baseline state, saves, reports, tutorial state, or inventory.
- Forecast and separately committed supplied-duration runs match exactly under unchanged state/content.
- Live/supplied-duration/offline-fixture/debug modes use the same resolver and normalized content.
- Gains exist in authoritative inventory before report inspection.
- Clearing or snapshotting the report accumulator changes no inventory, backlog, Mastery, or channel progress.
- Report state round trips exactly when serialized.
- The harness exposes one traceable rules path and no duplicate formula.

#### Automated verification

- Forecast non-mutation and equivalence.
- Mode-equivalence and repeatability.
- Report-versus-inventory integrity, clear/snapshot behavior, and duplicate prevention.
- Save round trip where applicable, full regression, and final M04 developer trace.

#### Manual verification

- Owner runs one M04E PowerShell package and uploads the log.
- No player-facing visual checklist is expected; the application shell belongs to M05.

#### Demonstration path

- Load the M04D fixture.
- Forecast one hour.
- Commit the same interval on a separate clone.
- Print exact state equality and report deltas.
- Clear/snapshot the accumulator and prove inventory is unchanged.

#### Save/load expectations

Any report state introduced here follows the M04A-approved schema policy. Forecasts create no save and mutate no baseline state.

#### Follow-on dependencies

- M05 conceptual epic; define and approve its actual slices before prompt drafting.

---

### M05 — Persistent application shell, navigation, and debug access

**Work item type:** Conceptual epic  
**Definition status:** Approved  
**Prompt status:** Not applicable — decompose before drafting  
**Implementation status:** Not directly executable  
**Verification status:** —  
**Recommended planning action:** Reassess and approve lettered slices under `DEC-0033` immediately before implementation.  
**Planned prompt file:** Not applicable — no direct epic prompt.

> This section defines a conceptual outcome and boundary. It is not a Codex task. Use the preliminary split in §8 only as a starting hypothesis, then approve the actual lettered slice definitions from the current repository.


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

**Work item type:** Conceptual epic  
**Definition status:** Approved  
**Prompt status:** Not applicable — decompose before drafting  
**Implementation status:** Not directly executable  
**Verification status:** —  
**Recommended planning action:** Reassess and approve lettered slices under `DEC-0033` immediately before implementation.  
**Planned prompt file:** Not applicable — no direct epic prompt.

> This section defines a conceptual outcome and boundary. It is not a Codex task. Use the preliminary split in §8 only as a starting hypothesis, then approve the actual lettered slice definitions from the current repository.


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

**Work item type:** Conceptual epic  
**Definition status:** Approved  
**Prompt status:** Not applicable — decompose before drafting  
**Implementation status:** Not directly executable  
**Verification status:** —  
**Recommended planning action:** Reassess and approve lettered slices under `DEC-0033` immediately before implementation.  
**Planned prompt file:** Not applicable — no direct epic prompt.

> This section defines a conceptual outcome and boundary. It is not a Codex task. Use the preliminary split in §8 only as a starting hypothesis, then approve the actual lettered slice definitions from the current repository.


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

**Work item type:** Conceptual epic  
**Definition status:** Approved  
**Prompt status:** Not applicable — decompose before drafting  
**Implementation status:** Not directly executable  
**Verification status:** —  
**Recommended planning action:** Reassess and approve lettered slices under `DEC-0033` immediately before implementation.  
**Planned prompt file:** Not applicable — no direct epic prompt.

> This section defines a conceptual outcome and boundary. It is not a Codex task. Use the preliminary split in §8 only as a starting hypothesis, then approve the actual lettered slice definitions from the current repository.


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

**Work item type:** Conceptual epic  
**Definition status:** Approved  
**Prompt status:** Not applicable — decompose before drafting  
**Implementation status:** Not directly executable  
**Verification status:** —  
**Recommended planning action:** Reassess and approve lettered slices under `DEC-0033` immediately before implementation.  
**Planned prompt file:** Not applicable — no direct epic prompt.

> This section defines a conceptual outcome and boundary. It is not a Codex task. Use the preliminary split in §8 only as a starting hypothesis, then approve the actual lettered slice definitions from the current repository.


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

**Work item type:** Conceptual epic  
**Definition status:** Approved  
**Prompt status:** Not applicable — decompose before drafting  
**Implementation status:** Not directly executable  
**Verification status:** —  
**Recommended planning action:** Reassess and approve lettered slices under `DEC-0033` immediately before implementation.  
**Planned prompt file:** Not applicable — no direct epic prompt.

> This section defines a conceptual outcome and boundary. It is not a Codex task. Use the preliminary split in §8 only as a starting hypothesis, then approve the actual lettered slice definitions from the current repository.


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

**Work item type:** Conceptual epic  
**Definition status:** Approved  
**Prompt status:** Not applicable — decompose before drafting  
**Implementation status:** Not directly executable  
**Verification status:** —  
**Recommended planning action:** Reassess and approve lettered slices under `DEC-0033` immediately before implementation.  
**Planned prompt file:** Not applicable — no direct epic prompt.

> This section defines a conceptual outcome and boundary. It is not a Codex task. Use the preliminary split in §8 only as a starting hypothesis, then approve the actual lettered slice definitions from the current repository.


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

**Work item type:** Conceptual epic  
**Definition status:** Approved  
**Prompt status:** Not applicable — decompose before drafting  
**Implementation status:** Not directly executable  
**Verification status:** —  
**Recommended planning action:** Reassess and approve lettered slices under `DEC-0033` immediately before implementation.  
**Planned prompt file:** Not applicable — no direct epic prompt.

> This section defines a conceptual outcome and boundary. It is not a Codex task. Use the preliminary split in §8 only as a starting hypothesis, then approve the actual lettered slice definitions from the current repository.


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

**Work item type:** Conceptual epic  
**Definition status:** Approved  
**Prompt status:** Not applicable — decompose before drafting  
**Implementation status:** Not directly executable  
**Verification status:** —  
**Recommended planning action:** Reassess and approve lettered slices under `DEC-0033` immediately before implementation.  
**Planned prompt file:** Not applicable — no direct epic prompt.

> This section defines a conceptual outcome and boundary. It is not a Codex task. Use the preliminary split in §8 only as a starting hypothesis, then approve the actual lettered slice definitions from the current repository.


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
- Add the generic known-channel acquisition progress presentation required by `DEC-0027`: Threshold-level bar, one-decimal floored percentage, and no fractional item count. Use a fixture or existing suitable channel; do not invent a new rare content item solely for the UI.

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
- Unknown acquisition progress remains hidden; once disclosure permits it, the bar survives reassignment/reload, never rounds to `100.0%` before banking, and never displays a fractional Soul/material count.
- Save/load preserves hidden inventory, discovery progress/state, completed cycles, and queued presentation exactly.

#### Automated verification

- Hidden-production-before-discovery.
- No duplicate grant at identification.
- Scribe versus fallback thresholds.
- Forecast non-mutation and uncertainty trace.
- Save round trip at each discovery state.
- Disclosure-aware long-horizon progress bar formatting and persistence.

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

**Work item type:** Conceptual epic  
**Definition status:** Approved  
**Prompt status:** Not applicable — decompose before drafting  
**Implementation status:** Not directly executable  
**Verification status:** —  
**Recommended planning action:** Reassess and approve lettered slices under `DEC-0033` immediately before implementation.  
**Planned prompt file:** Not applicable — no direct epic prompt.

> This section defines a conceptual outcome and boundary. It is not a Codex task. Use the preliminary split in §8 only as a starting hypothesis, then approve the actual lettered slice definitions from the current repository.


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

**Work item type:** Conceptual epic  
**Definition status:** Approved  
**Prompt status:** Not applicable — decompose before drafting  
**Implementation status:** Not directly executable  
**Verification status:** —  
**Recommended planning action:** Reassess and approve lettered slices under `DEC-0033` immediately before implementation.  
**Planned prompt file:** Not applicable — no direct epic prompt.

> This section defines a conceptual outcome and boundary. It is not a Codex task. Use the preliminary split in §8 only as a starting hypothesis, then approve the actual lettered slice definitions from the current repository.


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

**Work item type:** Conceptual epic  
**Definition status:** Approved  
**Prompt status:** Not applicable — decompose before drafting  
**Implementation status:** Not directly executable  
**Verification status:** —  
**Recommended planning action:** Reassess and approve lettered slices under `DEC-0033` immediately before implementation.  
**Planned prompt file:** Not applicable — no direct epic prompt.

> This section defines a conceptual outcome and boundary. It is not a Codex task. Use the preliminary split in §8 only as a starting hypothesis, then approve the actual lettered slice definitions from the current repository.


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

**Work item type:** Conceptual epic  
**Definition status:** Approved  
**Prompt status:** Not applicable — decompose before drafting  
**Implementation status:** Not directly executable  
**Verification status:** —  
**Recommended planning action:** Reassess and approve lettered slices under `DEC-0033` immediately before implementation.  
**Planned prompt file:** Not applicable — no direct epic prompt.

> This section defines a conceptual outcome and boundary. It is not a Codex task. Use the preliminary split in §8 only as a starting hypothesis, then approve the actual lettered slice definitions from the current repository.


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
| Technical, persistence, and content foundation | M00–M03 |
| Core Reaping implementation | M04A–M04E |
| Application/platform/tutorial infrastructure | Lettered slices under M05–M07 |
| Beats 1–4 / `TUT_00_BOOT`–`TUT_04_FIRST_DISPATCH` | Lettered slices under M08 |
| Beat 5 / `TUT_05_ARCHIVE`–`TUT_06_SOULWEAVE` | Lettered slices under M09 |
| Beat 6 / `TUT_07_RETINUE` | Lettered slices under M10 |
| Beat 7 / `TUT_08_SCRIBE` | Lettered slices under M11 |
| Beat 8 / `TUT_09_SECOND_THRESHOLD` | Lettered slices under M12 |
| Beat 9 / `TUT_10_DISCOVERY` | Lettered slices under M13 |
| Beat 10 / `TUT_11_LARDER` | Lettered slices under M14 |
| Beat 11 / `TUT_12_SEAL_CHOICE` | Lettered slices under M15 |
| Beat 12 / `TUT_13_COMPLETE` | Lettered slices under M16 |
| Full path, deviations, pacing, telemetry, and acceptance | Lettered slices under M17 |

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
- conceptual epics never receive direct implementation prompts; only approved slices do;
- frozen save schemas are never silently extended; each state-changing slice follows an approved migration or reset policy;
- material scope growth stops for owner-visible replanning rather than being absorbed into the current pull request.

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

When a definition is approved, change only its Definition column to **Approved**. A conceptual epic never advances to Prompt or Implementation status. The planning workflow creates one lettered slice prompt at a time and updates Prompt status only when that prompt actually exists. Implementation pull requests update Implementation and Verification status only after the relevant checks have actually run.

Before each new slice prompt:

1. inspect the merged repository and prior-slice evidence;
2. confirm the parent epic and exact dependency state;
3. complete the `DEC-0033` scope assessment and `GATE-SLICE-SCOPE` review;
4. resolve any listed decision gate, including `GATE-GAMEPLAY-SCHEMA` before M04A;
5. draft only the next slice prompt and obtain owner approval.

When a slice reveals a planning problem:

1. stop the affected prompt or implementation;
2. identify the conflicting source, missing dependency, new subsystem owner, or scope-growth trigger;
3. update this map and, when necessary, `DECISIONS.md` and the architecture/contracts;
4. preserve superseded definitions or prompt versions through Git history and explicit status rather than silently changing accepted scope;
5. resume only after the revised definition or prompt is approved.

The commercial save-format/threat-model review remains a release gate, not an excuse to add encryption, binary encoding, Steam Cloud, or a backend to the 0–90 minute prototype without a new approved milestone.
