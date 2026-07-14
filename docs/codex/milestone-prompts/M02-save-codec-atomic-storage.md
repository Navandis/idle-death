# Milestone M02: Versioned save codec and atomic storage

**Prompt version:** v0.1  
**Prompt date:** 2026-07-14  
**Prompt status:** Draft  
**Milestone definition:** `docs/codex/MILESTONES.md` — `### M02 — Versioned save codec and atomic storage`  
**Recommended task size:** Medium; one persistence pull request  
**Expected base branch or ref:** current `main` after M01 merge commit `a5b231682967e4cb71b4404af158e93ff8bbf261`  
**Planned prompt path:** `docs/codex/milestone-prompts/M02-save-codec-atomic-storage.md`

> This prompt authorizes only the M02 persistence foundation. It does not authorize gameplay systems, content definitions, Reaping simulation, Steam initialization, player-facing save UI, cloud saves, encryption, broad cleanup, dependency changes, or future milestones.

## Execution protocol

Before editing:

1. Read `AGENTS.md` completely.
2. Read every document and section listed under **Authoritative context**.
3. Inspect the current M01 implementation, tests, owner-verification workflow, project configuration, and `git status --short`.
4. Confirm that M01 is merged and verified and that `GATE-FIXED-POINT` is satisfied.
5. Confirm that the repository contains the M01 classes and tests named in **Repository state**.
6. Confirm that `DEC-0011`, `DEC-0021`, `DEC-0022`, `DEC-0025`, `DEC-0026`, `DEC-0027`, and `DEC-0028` are `Accepted`.
7. Briefly state the proposed schema mapper, codec boundary, file-transaction order, migration seam, failure-injection strategy, owner-verification package, and expected files before making non-trivial edits.
8. Report any material mismatch between this prompt and the repository before implementing dependent behavior.

During implementation:

- Limit changes to M02 and its acceptance criteria.
- Preserve M01 numeric and time-authority semantics; do not redesign `FixedPoint` or trusted-time reconciliation merely to simplify serialization.
- Keep runtime state, primitive snapshot schema, byte codec, storage operations, migrations, and application transaction orchestration as separate responsibilities.
- Keep all persistence code scene-tree independent and directly constructible in tests.
- Use exact canonical decimal strings for authoritative integers at the JSON boundary.
- Never derive gameplay progress from local wall time, file timestamps, registry values, or path metadata.
- Do not initialize Steam or call GodotSteam.
- Do not add a digest, encryption, compression, binary codec, cloud save, multiple slots, final release file naming, or anti-tamper claim unless this prompt explicitly requires it. It does not.
- Do not implement future gameplay substates merely to fill the final save outline.
- Add junior-readable script and member documentation explaining ownership, schema versus codec, integer encoding, validation, migration, file replacement, backup selection, and failure recovery.
- Add or update every test needed to prove the behavior.
- Create the required M02 owner-verification script and generated-log workflow defined below.
- Run every Codex-executable check listed in this prompt and report exact commands and exit codes.
- Leave owner-run Windows filesystem checks as `Pending owner verification` until the owner supplies a result for the tested PR head.
- Do not create, rewrite, or broaden this prompt or any future milestone prompt.

Do not describe M02 as complete while any merge-gate criterion is failed, blocked, or pending. A pull request may be ready for owner testing with verification `Partial`, but it may not merge until `GATE-SAVE-SCHEMA` and all listed owner gates explicitly pass.

## Objective

Implement the first exact, recoverable, migration-ready persistence layer for Death Idle. The result must map the current M01 runtime state to a frozen schema-version-1 primitive snapshot, encode and decode it through a project-owned JSON codec without losing 64-bit integers, and save it through a primary/temporary/backup transaction that retains at least one valid committed snapshot across tested failures.

## Player or developer outcome

From tests and one headless persistence trace, a developer can:

- convert the minimal M01 `GameState` and `TimeAuthorityState` to a schema-controlled primitive snapshot and reconstruct them exactly;
- encode authoritative integers at `0`, ordinary values, values around `2^53`, representative trusted epochs, and signed-64-bit limits without JSON-number coercion;
- reject malformed integer strings, JSON numeric values in integer fields, unsupported codecs, unsupported future schemas, and invalid cross-field combinations;
- write a first primary save;
- write a second revision while retaining the previous valid primary as backup;
- corrupt the primary and load the valid backup without deleting or rewriting the corrupt bytes;
- choose the highest valid save revision rather than blindly preferring a filename;
- simulate documented file-operation failures and show that at least one valid committed snapshot remains;
- exercise a sequential migration seam without coupling migrations to JSON;
- prepare and commit a trusted-time candidate snapshot without mutating the caller's previously committed runtime state when persistence fails;
- run the complete Windows filesystem validation through one PowerShell command that writes a shareable log.

The required demonstration writes revision 1, writes revision 2 through the atomic path, corrupts revision 2's primary file, loads revision 1 from backup, reports why the primary was rejected, proves that the corrupt primary bytes still exist for diagnosis, cleans the isolated test directory, and reruns the clean suite.

## Authoritative context

Read the following before editing.

| Priority | Source | Required sections, labels, or records | Why it applies |
|---:|---|---|---|
| 1 | `AGENTS.md` | Full file, especially **Architectural boundaries**, **Save/load and time requirements**, **Code comments and junior-reviewer documentation**, **Testing and validation**, and **Scope, refactoring, and dependencies** | Repository-wide persistence, security, comments, and verification rules |
| 2 | `docs/codex/MILESTONES.md` | §5 `GATE-SAVE-SCHEMA`; §6 M01/M02 rows; §9 `M01` completion and `M02 — Versioned save codec and atomic storage` | Approved dependency, scope, and merge gate |
| 3 | `docs/codex/PROMPT_TEMPLATE.md` | §§2.1–2.3 and the instantiated-prompt completion/evidence rules | Prompt ownership and owner-result semantics |
| 4 | `docs/codex/OWNER_VERIFICATION_WORKFLOW.md` | §§2–8 | Required PowerShell package, optional Git behavior, generated log, cleanup, and owner evidence |
| 5 | `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md` | `IF-REQ-07`, `IF-REQ-08`, `IF-REQ-15`, `IF-REQ-16`, `IF-REQ-17`; §9 elapsed-time resolution | Deterministic shared rules, save integrity, storefront isolation, and trusted-time authority |
| 6 | `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md` | Global safeguards; online/offline behavior; save checkpoints; `P90-AC07` | Prototype idempotency and technical-integrity contract |
| 7 | `docs/codex/ARCHITECTURE.md` | §§5.2, 7, 9.4–9.8, 20.1–20.6, 23; M01 concrete implementation note | Runtime ownership, time state, schema/codec/storage separation, transaction order, and test seams |
| 8 | `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | §§9.1–9.3; §§12.1–12.6; §14; §17; M01 concrete runtime contracts | Exact envelope, current runtime mapping, integer wire rules, schema outline, and validation |
| 9 | `docs/codex/IMPLEMENTATION_RULES.md` | §§5–6; §10; §14; §§17–22; M01 concrete implementation notes | Junior-readable code, time boundaries, serialization, diagnostics, testing, security, and PR scope |
| 10 | `docs/codex/TESTING_AND_VALIDATION.md` | §§4, 6, 7.1, 9, 12.1, 15–19; M01 completion record; M02 validation package | Canonical commands, codec/storage matrices, owner filesystem gate, and evidence requirements |
| 11 | `docs/codex/DECISIONS.md` | `DEC-0007`, `DEC-0011`, `DEC-0017`, `DEC-0021`, `DEC-0022`, `DEC-0023`, `DEC-0025`, `DEC-0026`, `DEC-0027`, `DEC-0028` | Scene-independent state, codec boundary, trusted time, save threat model, verification, and numeric meaning |
| 12 | M01 implementation | PR #5; final head `e2b291e75dab5e3484da7dec1d4420a2fb9637be`; merge commit `a5b231682967e4cb71b4404af158e93ff8bbf261` | Verified runtime state and numeric/time baseline that M02 persists |

This prompt is the latest owner-approved task instruction only within M02. It does not supersede accepted decisions or protected design invariants. If applicable sources conflict and the documented hierarchy does not resolve the conflict, stop and report the conflict, practical consequence, and available options.

## Repository state

The expected baseline at task start is:

| Item | Expected state | Evidence or path to inspect |
|---|---|---|
| Required prior milestones | M00 and M01 merged; both verification states Passed | `docs/codex/MILESTONES.md`, PR #4, PR #5 |
| Test harness | Canonical Linux and Windows GUT wrappers pass | `.gutconfig.json`, `tools/test/run_gut.sh`, `tools/test/run_gut.ps1` |
| Owner workflow | Milestone-specific PowerShell/log contract is approved | `docs/codex/OWNER_VERIFICATION_WORKFLOW.md`, `DEC-0025` |
| Fixed point | `FixedPoint.SCALE = 1_000_000`; checked explicit-period accumulation and extraction implemented | `src/domain/fixed_point.gd`, `tests/unit/m01/test_fixed_point.gd` |
| Game state | Minimal scene-independent `GameState` with `simulation_time_msec` only | `src/domain/game_state.gd` |
| Time authority | Separate runtime state uses `trusted_anchor_utc_msec = -1` for no anchor, source ID, foreground credit, pending flag, and diagnostic | `src/domain/time_authority_state.gd` |
| Reconciliation | Non-mutating plan and explicit commit service exists | `src/simulation/time_reconciliation_service.gd`, M01 tests |
| Time providers | Monotonic/trusted contracts and fakes exist; no production Steam trusted-time adapter | `src/platform/time/` |
| Persistence | No schema mapper, save envelope, JSON codec, file storage, migrations, save service, or save fixtures | Repository inspection |
| Gameplay | No inventory, Threshold, Reaping, Hall, report, tutorial, or content-registry implementation | Repository inspection |
| Steam | GodotSteam 4.20 present; App ID `480`; automatic initialization disabled | `addons/godotsteam/`, `project.godot` |
| Owner logs | Generated logs ignored and not committed | `.gitignore`, `tools/test/owner/logs/` |
| Temporary scaffolding | Existing dry-run scene and assets remain unrelated | `test_main_scene.tscn`, `assets/` |
| Working tree | Clean except for task changes | `git status --short` |

Re-check these facts at task start. If the repository is materially ahead of, behind, or inconsistent with this table, report the mismatch. Do not overwrite newer work or recreate an existing persistence layer.

## Dependencies

| Dependency or gate | Required state | Required before | How to verify |
|---|---|---|---|
| M01 | Merged and Passed | Implementation | `MILESTONES.md`, PR #5, current source/tests |
| `GATE-FIXED-POINT` | Satisfied | Implementation | M01 completion record and tests |
| GUT harness | Passing on current branch | PR | `./tools/test/run_gut.sh` |
| Owner workflow | Git-optional script/log contract available | Implementation | `OWNER_VERIFICATION_WORKFLOW.md` |
| Windows filesystem environment | Owner can pull PR head and run Godot 4.7 console executable | Merge | Explicit owner log from `run_m02_owner_verification.ps1` |
| `GATE-SAVE-SCHEMA` | Schema v1 keys/fixtures frozen; Linux and Windows persistence gates pass | Merge | Tests, fixtures, docs, and owner log |

Do not weaken a dependency gate to make the task appear complete.

## Scope

Implement only the following:

1. Define a typed project-owned save envelope and a schema-version-1 mapper for the current minimal runtime state.
2. Freeze the exact schema-version-1 key spelling and representative valid/invalid fixtures described in this prompt.
3. Separate:
   - runtime state;
   - primitive snapshot mapping and validation;
   - byte codec;
   - storage abstraction;
   - file-storage implementation;
   - migration registry;
   - save/load orchestration.
4. Implement a `SaveCodec` boundary and a `JSON_V1` codec.
5. Implement one shared canonical signed-64-bit decimal-string parser/formatter with field-level negative-value policy.
6. Encode every authoritative integer field as a canonical decimal string; do not emit JSON numeric values for those fields.
7. Map the M01 no-anchor runtime sentinel to the explicit schema representation and reconstruct it exactly.
8. Implement deterministic encoding of a validated schema-v1 snapshot.
9. Implement a configurable `SaveFileSet` or equivalent path contract with production defaults under `user://saves/` and injectable paths for tests.
10. Implement primary, temporary, and backup file handling with write/flush/close/reopen/decode/full-validation before replacement.
11. Implement independent primary/backup validation and highest-valid-save-revision selection.
12. Preserve invalid or unsupported candidates during load; do not delete or rewrite them merely because another candidate is selected.
13. Implement a safe policy for saving when the existing primary is invalid: preserve or quarantine it before replacement, using a deterministic collision-safe diagnostic path rather than a wall-clock-derived gameplay value.
14. Implement a sequential primitive-dictionary migration registry and test it with a test-only migration step without falsely declaring an unshipped production schema as historical support.
15. Implement fault-injectable storage seams covering the documented atomic-write stages.
16. Implement a minimal transaction seam that applies an M01 reconciliation plan to a working copy/candidate, persists that candidate, and returns it as committed only after storage succeeds.
17. Add typed results and stable diagnostics for codec, schema, candidate-selection, migration, and storage failures.
18. Add unit, integration, fixture, and headless trace coverage.
19. Add `tools/test/owner/run_m02_owner_verification.ps1` under the approved owner workflow.
20. Update only the maintained documentation made inaccurate by the realized implementation.

Use the smallest clear architecture that satisfies these contracts. Do not build a general database, object graph serializer, cloud-sync engine, or release-scale slot manager.

## Non-goals

Do not implement or refactor:

1. Inventory, Forms, Thresholds, Reapings, Halls, Recollections, progression, story, tutorial, reports, or other future `GameState` substates.
2. M03 content definitions/catalog/revision compatibility beyond requiring a non-empty content-revision field in the envelope.
3. M04 production or offline simulation.
4. M06 GodotSteam trusted-time adapter or live Steam behavior.
5. Player-facing save/load menus, autosave scheduling, application startup integration, focus-loss saves, or replacement of the dry-run main scene.
6. Multiple player slots, profiles, final commercial filenames, Steam Cloud, conflict resolution, achievements, or cross-machine synchronization.
7. Encryption, obfuscation, compression, binary serialization, DRM, server authority, or a claim of tamper prevention.
8. A checksum, digest, HMAC, or signature unless implementation exposes a concrete corruption gap that cannot be addressed by schema and file validation; stop for approval before adding one.
9. Generic reflection-based serialization, Resource/scene saves for mutable state, or automatic dumping of arbitrary object properties.
10. Event sourcing or replay of the lifetime event history.
11. A production migration from a fictional schema 0. A test-only migration fixture may prove the registry seam.
12. Use of local wall-clock time or file modification timestamps for save selection, revisions, IDs, offline progress, or transaction correctness.
13. Changes to M01 fixed-point scale, rate semantics, trusted-time plan semantics, or accepted Decisions.
14. Broad file moves, dependency updates, engine/renderer changes, or unrelated cleanup.

## Required behavior

Every row is a binary requirement for this task.

| ID | Required behavior | Source trace |
|---|---|---|
| `RB-01` | Runtime state, primitive schema, codec, storage, migration, and orchestration are separate project-owned boundaries. | `DEC-0011`; `ARCHITECTURE.md` §20.1 |
| `RB-02` | Schema v1 uses exactly the keys and nesting defined under **Data and content**. | `GATE-SAVE-SCHEMA`; data contracts §14 |
| `RB-03` | `schema_version`, `save_revision`, simulation time, trusted epoch, foreground credit, and every future schema field typed as an authoritative integer cross JSON as canonical decimal strings. | `DEC-0011`; data contracts §12.5 |
| `RB-04` | The integer codec round-trips `0`, ordinary values, `2^53 - 1`, `2^53`, representative trusted epochs, representative fixed-point residual values, `INT64_MAX`, and `INT64_MIN` when the field policy allows signed values. M02 must test residual-shaped integers directly through the codec rather than inventing a production residual field before one exists. | `TESTING_AND_VALIDATION.md` §7.1/§9.1 |
| `RB-05` | Canonical output rejects leading plus signs, whitespace, decimal points, exponent notation, locale formatting, non-digits, non-canonical leading zeroes, `-0`, and out-of-range values. | Data contracts §12.5 |
| `RB-06` | A JSON number/float in an authoritative integer field is rejected rather than cast to `int`. | `DEC-0011`; M02 acceptance |
| `RB-07` | Unanchored M01 runtime state maps to `has_trusted_anchor = false`, empty source ID, wire anchor `"0"`, and zero foreground credit; decoding reconstructs the M01 `-1` runtime sentinel without exposing it as a wire value. | Data contracts §9.2; M01 implementation |
| `RB-08` | Anchored time state requires `has_trusted_anchor = true`, non-empty source ID, non-negative epoch, non-negative foreground credit, and a valid diagnostic string. Contradictory combinations are rejected. | `DEC-0021`; data contracts §9.2 |
| `RB-09` | `GameState.simulation_time_msec` is non-negative and round-trips exactly. | M01 `GameState`; data contracts §9.3 |
| `RB-10` | `codec_id` is exactly `JSON_V1`; an unknown codec is rejected before runtime construction and never overwrites valid files. | `DEC-0011`; M02 acceptance |
| `RB-11` | Schema version 1 is current. A supported older version migrates sequentially through explicit dictionary steps; a future unsupported version is rejected without file mutation. | Architecture §20.3/§20.5 |
| `RB-12` | `content_revision` is required and non-empty but M02 does not invent content compatibility rules before M03. | M02 scope; M03 dependency |
| `RB-13` | Encoding the same validated primitive snapshot twice produces identical UTF-8 JSON bytes apart from no permitted nondeterministic metadata. | Determinism and diagnosability |
| `RB-14` | Snapshot validation rejects Nodes, Objects, Resource references, Callables, non-finite values, unsupported Variant types, and absolute machine paths in authoritative fields. | Data contracts §14; implementation rules §14 |
| `RB-15` | The first save writes a validated temporary candidate and promotes it to primary only after reopen/decode/full-validation succeeds. | Architecture §20.2 |
| `RB-16` | A later save retains the previous valid primary as backup before promoting the validated temporary candidate. | `DEC-0011` |
| `RB-17` | Primary and backup are decoded and validated independently; load selects the valid snapshot with the highest `save_revision`, regardless of filename role. | M02 milestone acceptance |
| `RB-18` | A corrupt primary falls back to a valid backup with a stable diagnostic. Loading does not delete, rewrite, truncate, or hide the corrupt primary. | Architecture §20.3; owner demonstration |
| `RB-19` | If both primary and backup are invalid, load returns a recoverable typed failure and preserves both files. | Persistence resilience |
| `RB-20` | A valid temporary candidate or failed write is never presented as committed unless the documented replacement step succeeds. | Atomic transaction rule |
| `RB-21` | Injected failures before temporary write, during write, after write before validation, after backup rotation before primary replacement, and after primary replacement leave at least one valid committed snapshot loadable. | Testing §9.3 |
| `RB-22` | All file-operation return codes are checked; files are flushed and closed before reopen, validation, rename, or removal. | Implementation rules §14.7 |
| `RB-23` | File selection and transaction correctness use save revision and validation only; no device wall clock or file timestamp participates. | `DEC-0021`; `IF-REQ-17` |
| `RB-24` | Loading or migration is non-mutating until the complete candidate passes schema and runtime validation. | Transaction safety |
| `RB-25` | A reconciliation candidate is created from a working copy. If persistence fails, the caller's committed `GameState` and `TimeAuthorityState` remain unchanged; after successful persistence, the returned candidate contains the committed anchor/timeline update exactly once. | Architecture §20.4; M01 plan/commit seam |
| `RB-26` | Repeating load after a successful candidate commit does not repeat the same trusted-time credit. | `P90-AC07`; offline idempotency seam |
| `RB-27` | M02 fixtures use explicit small values plus boundary values and remain independent of JSON where testing runtime-to-primitive mapping. | Testing principles |
| `RB-28` | Production default paths live under `user://saves/`; tests and owner traces inject disposable paths and never touch the owner's normal save directory. | Architecture; owner workflow |
| `RB-29` | Invalid-primary preservation/quarantine, if needed for a later save, uses deterministic collision-safe naming or an injected diagnostic identity, not a gameplay-relevant wall-clock timestamp. | No local-time authority; suspect-file retention |
| `RB-30` | No file is described as tamper-proof. Documentation distinguishes exactness/recovery from edit deterrence and external authority. | `DEC-0022` |
| `RB-31` | The owner PowerShell script follows `OWNER_VERIFICATION_WORKFLOW.md`, accepts `-CommitSha`, keeps Git optional, uses a disposable directory, writes one UTF-8 log, cleans all temporary files, reruns the clean suite after corruption tests, and returns nonzero on any automated failure. | `DEC-0025` |
| `RB-32` | All non-trivial project-owned scripts document responsibility, owned/non-owned state, collaborators, units, schema assumptions, transaction order, and failure behavior for a junior reviewer. | `AGENTS.md`; implementation rules §5 |
| `RB-33` | M02 does not persist derived effective rates, ETAs, progress percentages, or future Threshold acquisition state before those runtime classes exist. | `DEC-0028`; scope discipline |

## State transitions

| ID | Initial state | Trigger or command | Required resulting state | Failure or recovery behavior | Persistence or diagnostic effect |
|---|---|---|---|---|---|
| `ST-01` | Minimal runtime state with no trusted anchor | Map runtime to schema v1 | Explicit no-anchor bool, source `""`, wire epoch `"0"`, foreground `"0"`, exact simulation timeline | Invalid runtime invariant returns typed failure | No bytes written |
| `ST-02` | Valid schema-v1 primitive snapshot | Reconstruct runtime | M01 `GameState` and no-anchor `TimeAuthorityState` reconstruct exactly | Invalid type/range/combination rejected before object exposure | No file mutation |
| `ST-03` | Anchored runtime with boundary integer values | Runtime → primitive → JSON bytes → primitive → runtime | Every field matches exactly | Any numeric coercion or range loss fails test | Codec-only round trip |
| `ST-04` | No primary, backup, or temp file | Save revision 1 | Validated temp promoted to primary; backup absent | Failure leaves no false committed primary | Stable save result diagnostic |
| `ST-05` | Valid primary revision 1 | Save revision 2 | Revision 1 retained as backup; validated revision 2 becomes primary | Failure before promotion leaves revision 1 loadable | At least one valid snapshot remains |
| `ST-06` | Primary revision 2 and backup revision 1 valid | Load | Revision 2 selected | None | Candidate-selection result names primary |
| `ST-07` | Primary bytes are corrupt; backup revision 1 valid | Load | Backup revision 1 selected; corrupt primary unchanged | Backup invalid too produces recoverable failure | Diagnostic identifies primary rejection and backup selection |
| `ST-08` | Primary revision 1 valid; backup revision 2 valid | Load | Backup revision 2 selected as highest valid revision | Invalid higher revision cannot defeat valid lower candidate | Selection based on validated revision, not filename |
| `ST-09` | Candidate has unknown codec or future schema | Load | Candidate rejected before runtime construction | Existing valid counterpart remains selectable | No file mutation |
| `ST-10` | Primitive fixture at test schema 0 with a registered test migration | Migrate to schema 1 | Exactly one ordered step runs and produces valid v1 primitive data | Missing step/cycle/future version rejected | Test-only migration seam; no production schema-0 promise |
| `ST-11` | Valid committed snapshot and planned trusted-time credit | Apply plan to working copy, then inject save failure | Original runtime and committed files remain authoritative | Candidate discarded/reported | No anchor/timeline duplication |
| `ST-12` | Same setup as `ST-11` without failure | Persist candidate successfully | New snapshot, anchor, foreground reset, and timeline become committed together | Repeated load/reconciliation grants zero duplicate credit | Transaction result returns committed candidate |
| `ST-13` | Valid primary and backup with an existing stale temp file | Begin new save | Stale temp is handled only by documented safe policy; valid primary/backup are not discarded | Cleanup failure blocks promotion | Stable diagnostic; at least one valid committed file remains |
| `ST-14` | Invalid primary selected for preservation before a new save | Preserve/quarantine then promote validated candidate | Invalid bytes remain available under documented diagnostic path; new primary valid | Preservation failure aborts replacement | No silent destruction of suspect data |

## Data and content

M02 introduces schema constants and test fixtures, not gameplay content.

### Schema version 1

The exact primitive shape is:

```text
SaveEnvelopeV1
├── schema_version
├── codec_id
├── content_revision
├── save_revision
├── time_authority
│   ├── trusted_source_id
│   ├── has_trusted_anchor
│   ├── trusted_anchor_utc_msec
│   ├── foreground_credited_since_anchor_msec
│   ├── pending_trusted_reconciliation
│   └── last_sample_diagnostic_code
├── last_offline_resolution_id
├── metadata
└── game_state
    └── simulation_time_msec
```

Exact key spelling:

```text
schema_version
codec_id
content_revision
save_revision
time_authority
trusted_source_id
has_trusted_anchor
trusted_anchor_utc_msec
foreground_credited_since_anchor_msec
pending_trusted_reconciliation
last_sample_diagnostic_code
last_offline_resolution_id
metadata
game_state
simulation_time_msec
```

Do not add empty future gameplay dictionaries merely to mimic the eventual full save shape. A later milestone that adds required authoritative fields must update the schema, migrations or explicit prototype-reset decision, fixtures, and tests.

### Wire types

| Field | Runtime meaning | JSON wire type and rule |
|---|---|---|
| `schema_version` | non-negative integer, current `1` | canonical decimal string |
| `codec_id` | byte-codec identity | string, exactly `JSON_V1` |
| `content_revision` | content compatibility placeholder | non-empty string; fixture value may be `foundation-m02` |
| `save_revision` | non-negative monotonically increasing snapshot revision | canonical decimal string |
| `trusted_source_id` | accepted trusted source or empty | string |
| `has_trusted_anchor` | explicit anchor presence | JSON boolean |
| `trusted_anchor_utc_msec` | non-negative epoch when anchored; `0` when not anchored | canonical decimal string |
| `foreground_credited_since_anchor_msec` | non-negative already-credited interval | canonical decimal string |
| `pending_trusted_reconciliation` | pending trust state | JSON boolean |
| `last_sample_diagnostic_code` | stable diagnostic | non-empty string |
| `last_offline_resolution_id` | idempotency/diagnostic identity, empty before use | string |
| `metadata` | non-authoritative diagnostics only | JSON object containing permitted save-safe primitives; empty object is valid |
| `simulation_time_msec` | non-negative authoritative timeline | canonical decimal string |

Rules:

- Snapshot fields typed as authoritative integers are strings even when their values are small.
- The M01 runtime no-anchor sentinel `-1` is not emitted. It maps to `has_trusted_anchor = false`, empty source, and wire anchor `"0"`.
- `has_trusted_anchor = false` requires empty source, anchor `"0"`, and foreground credit `"0"`.
- `has_trusted_anchor = true` requires non-empty source and non-negative anchor.
- Schema v1 does not contain device time, file timestamps, GodotSteam details, App ID, local paths, Nodes, Resources, Callables, effective rates, cached ETAs, or future gameplay state.
- M02 validates representative fixed-point residual integers through the shared integer codec; it must not add a production residual field solely to satisfy a test before a runtime owner exists.
- Set-like collection ordering rules are implemented by shared schema utilities when first needed; schema v1 has no set-like gameplay collection.

### Codec and path constants

| Constant or contract | Required value or behavior | Status |
|---|---|---|
| Current schema version | `1` | Confirmed |
| Codec ID | `JSON_V1` | Confirmed |
| Production save directory | `user://saves/` | Confirmed architecture |
| Save basename | One clearly labelled prototype default, configurable/injectable for tests | Prototype scaffold |
| File roles | primary, temporary, backup; optional invalid/quarantine diagnostic role | Confirmed responsibilities |
| Content revision fixture | `foundation-m02` or another documented non-empty test value | Test/prototype scaffold |

The chosen prototype basename and suffixes must be documented in `README.md` and `TESTING_AND_VALIDATION.md`. They are not the final commercial slot naming contract.

### Stable result and diagnostic categories

Use stable codes for at least:

```text
SAVE_OK
SAVE_CODEC_UNKNOWN
SAVE_SCHEMA_UNSUPPORTED
SAVE_SCHEMA_INVALID
SAVE_INTEGER_INVALID
SAVE_INTEGER_OUT_OF_RANGE
SAVE_RUNTIME_INVALID
SAVE_CONTENT_REVISION_MISSING
SAVE_NO_VALID_CANDIDATE
SAVE_PRIMARY_REJECTED
SAVE_BACKUP_SELECTED
SAVE_TEMP_WRITE_FAILED
SAVE_TEMP_REOPEN_FAILED
SAVE_TEMP_VALIDATION_FAILED
SAVE_BACKUP_ROTATION_FAILED
SAVE_PRIMARY_REPLACEMENT_FAILED
SAVE_MIGRATION_MISSING
SAVE_MIGRATION_FAILED
SAVE_STALE_TRANSACTION
SAVE_SUSPECT_PRESERVATION_FAILED
```

Codex may refine names while preserving these meanings. Record the final names in the data contract and tests.

## UI and presentation

No player-facing UI is required.

| Surface or state | Required presentation and interaction | Explicitly deferred |
|---|---|---|
| Headless persistence trace | Print revisions written, candidate selected, rejected-candidate diagnostic, retained corrupt-file proof, cleanup, and final pass/fail | Save menu, welcome-back UI, user-facing error dialog |
| Test diagnostics | Stable, junior-readable messages with file role, schema/codec/revision context, and failure stage | Localization and final player copy |
| README/testing docs | Exact prototype paths, reset procedure, test commands, and corruption-recovery demonstration | Production support documentation |

Do not expose absolute machine paths inside committed fixtures or documentation examples.

## Architecture constraints

- Runtime state does not call JSON or file APIs.
- Primitive schema mapping does not perform file I/O.
- `JSON_V1` does not know about primary/backup selection.
- Storage does not decide game rules, trusted-time credit, or schema meaning.
- Migrations operate on primitive dictionaries before runtime construction and advance exactly one version per step.
- Save/load orchestration validates a complete candidate before exposing it.
- M01 reconciliation planning remains non-mutating; a working candidate is committed only after persistence succeeds.
- Authoritative integers never traverse JSON as floats.
- No generic reflection dump, `ResourceSaver`, scene serialization, or live Object reference is permitted.
- No device wall clock, file timestamp, Steam API, network call, or user-entered time participates in correctness.
- File paths are injectable. Tests and owner traces use isolated disposable directories.
- No anti-tamper promise is introduced.
- Do not add a gameplay autoload, dependency, engine/renderer change, or future system.
- `DEC-0028` remains future simulation guidance: M02 must not serialize derived rate/ETA caches or invent Threshold progress state before M04.

## Expected files

This list is an informed expectation, not permission to edit every path. Codex may refine names after inspection, but must explain meaningful deviations in the pre-edit plan and final response.

| Path or area | Expected action | Purpose |
|---|---|---|
| `src/persistence/save_envelope.gd` or equivalent | Add | Typed envelope/current schema metadata |
| `src/persistence/save_schema_v1.gd` or equivalent | Add | Runtime ↔ primitive mapping and schema validation |
| `src/persistence/integer_string_codec.gd` or equivalent | Add | Canonical signed-64-bit string parser/formatter |
| `src/persistence/save_codec.gd` | Add | Project-owned byte-codec interface |
| `src/persistence/json_save_codec.gd` | Add | Deterministic `JSON_V1` implementation |
| `src/persistence/save_migration_registry.gd` | Add | Sequential primitive-dictionary migrations |
| `src/persistence/save_storage.gd` | Add | Injectable storage interface |
| `src/persistence/file_save_storage.gd` | Add | Godot file/rename implementation |
| `src/persistence/save_service.gd` | Add | Candidate selection and atomic save/load orchestration |
| `src/persistence/save_file_set.gd` or equivalent | Add | Primary/temp/backup/invalidation path contract |
| `tests/support/memory_save_storage.gd` | Add | Deterministic failure injection |
| `tests/unit/persistence/` | Add | Integer, schema, codec, migration, validation, storage tests |
| `tests/integration/save_load/` | Add | Candidate selection and reconciliation transaction tests |
| `tests/fixtures/saves/` | Add | Valid/invalid schema-v1 fixtures and test-only migration fixture |
| `tools/test/m02/m02_persistence_trace.gd` | Add | Headless real-file demonstration in injected directory |
| `tools/test/owner/run_m02_owner_verification.ps1` | Add | One-command Windows filesystem verification and log |
| `README.md` | Modify | Prototype save path/reset and validation commands |
| `docs/codex/ARCHITECTURE.md` | Modify | Realized class/path/transaction details only |
| `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | Modify | Exact v1 keys, result codes, and runtime mapping |
| `docs/codex/IMPLEMENTATION_RULES.md` | Modify if needed | Realized durable persistence conventions |
| `docs/codex/TESTING_AND_VALIDATION.md` | Modify | Exact commands, fixture matrix, trace, owner package |
| `docs/codex/MILESTONES.md` | Modify | Truthful M02 implementation/verification stage |

Do not create empty future gameplay directories or placeholder serializers for systems not yet implemented.

## Acceptance criteria

Each criterion is binary and observable.

| ID | Pass condition | Verification evidence | Merge gate? |
|---|---|---|---:|
| `AC-01` | Runtime, schema, codec, migration, storage, and orchestration boundaries are separate and documented. | Changed-code review and architecture tests | Yes |
| `AC-02` | The exact schema-v1 key set and fixture bytes are frozen and documented. | Fixture review, schema tests, `MILESTONES.md` gate | Yes |
| `AC-03` | Current M01 runtime state round-trips exactly through primitive schema mapping without JSON. | Focused runtime/schema tests | Yes |
| `AC-04` | Valid schema-v1 primitive data round-trips through `JSON_V1` bytes deterministically. | Codec tests comparing primitive values and repeated bytes | Yes |
| `AC-05` | Boundary integers, representative trusted epochs, and representative fixed-point residual integers round-trip exactly; authoritative JSON integer fields are strings and no speculative residual field is added. | Integer/codec matrix | Yes |
| `AC-06` | Malformed strings and JSON numeric values in integer fields are rejected without coercion. | Negative matrix | Yes |
| `AC-07` | No-anchor runtime `-1` maps to explicit false/zero wire state and reconstructs exactly. | Mapper tests | Yes |
| `AC-08` | Contradictory anchored/unanchored time-state combinations are rejected. | Schema validation tests | Yes |
| `AC-09` | Unknown codec and unsupported future schema candidates are rejected without overwriting files. | Unit/integration tests and trace | Yes |
| `AC-10` | The first atomic save creates a valid primary only after temporary-candidate validation. | Storage integration test | Yes |
| `AC-11` | The second save retains revision 1 as backup and commits revision 2 as primary. | Storage integration test and trace | Yes |
| `AC-12` | Load independently validates both roles and selects the highest valid save revision. | Candidate-selection tests | Yes |
| `AC-13` | A corrupt primary falls back to backup, emits a stable diagnostic, and remains byte-for-byte present after load. | Linux test plus Windows trace | Yes |
| `AC-14` | When both candidates are invalid, the service returns a recoverable failure and preserves both. | Integration test | Yes |
| `AC-15` | Every documented injected atomic-write failure leaves at least one valid committed snapshot loadable. | Fault-injection matrix | Yes |
| `AC-16` | The migration registry advances one version per step and fails clearly for missing, cyclic, failed, or future migrations. | Migration tests and test-only fixture | Yes |
| `AC-17` | Reconciliation candidate persistence leaves original runtime unchanged on save failure and exposes the candidate only after successful commit. | Integration tests with M01 service | Yes |
| `AC-18` | Repeated load/reconciliation after a successful transaction does not duplicate elapsed credit. | Integration test | Yes |
| `AC-19` | No authoritative persistence path uses device wall time, local UTC, timezone, file modification time, Steam, registry, or user-entered time. | Source-ownership test | Yes |
| `AC-20` | Tests and trace use injectable isolated storage and never write the owner's normal `user://` save. | Path assertions and owner log | Yes |
| `AC-21` | Invalid/suspect files are not silently deleted or overwritten during load; any preservation path is deterministic and collision-safe. | Storage tests and trace | Yes |
| `AC-22` | `run_m02_owner_verification.ps1` follows the approved Git-optional logging and cleanup contract. | Script review and explicit owner log | Yes |
| `AC-23` | Owner-run Windows full/focused suites and real-file corruption/recovery trace pass at the tested PR head. | Explicit owner log | Yes |
| `AC-24` | The owner script removes its isolated directory, verifies cleanup, and the clean full suite passes afterward. | Owner log | Yes |
| `AC-25` | Documentation accurately distinguishes recovery/exactness from tamper resistance and contains exact commands/paths. | Documentation review | Yes |
| `AC-26` | All changed non-trivial GDScript follows the junior-reviewer documentation rules. | Code review against `AGENTS.md` and implementation rules | Yes |
| `AC-27` | No new dependency, Steam behavior, gameplay system, player-facing save UI, private path, generated log, or unrelated refactor is introduced. | Diff review, repository search, `git diff --check` | Yes |
| `AC-28` | All maintained documents made inaccurate by M02 are updated in the same pull request; prompt/design files remain unchanged unless a real conflict is owner-approved. | Changed-file inventory and link validation | Yes |

Completion rules:

- A criterion is `Passed` only when its listed evidence was actually produced.
- Owner Windows criteria remain `Pending owner verification` until the owner supplies the generated log for the tested PR head.
- A pending owner merge gate keeps M02 verification `Partial` and prevents merge.
- A failed criterion returns to troubleshooting; do not weaken it or privately patch one machine.

## Automated verification

### Codex Cloud or Linux checks

Run in this order, adapting only exact focused filenames to the realized implementation and documenting the final commands:

| Order | Command | Purpose | Required result |
|---:|---|---|---|
| 1 | `git status --short` | Starting worktree | Clean before edits |
| 2 | `./tools/test/run_gut.sh -- -gdir=res://tests/unit/persistence -gdir=res://tests/integration/save_load` or exact focused-file equivalents | Focused M02 suite | All M02 tests pass; exit `0` |
| 3 | explicit headless import followed by `godot --headless --path . -s res://tools/test/m02/m02_persistence_trace.gd -- --save-root <DISPOSABLE_PATH>` | Real-file trace | Revisions, corruption fallback, retention, cleanup result pass; exit `0` |
| 4 | `./tools/test/run_gut.sh` | Full regression suite | Exit `0`; no parser/resource errors |
| 5 | source-ownership validator/test | Prohibit wall-clock/file-time authority and JSON leakage into runtime | Pass |
| 6 | fixture/link/schema validator added by M02 | Validate fixtures and documented keys | Pass |
| 7 | `git diff --check` | Patch sanity | Exit `0` |
| 8 | `git status --short` | Final inventory | Only intended task files |

The trace must use a disposable directory outside production `user://saves/` and remove it or leave cleanup to the invoking owner script according to the documented interface.

### Required focused matrices

At minimum, focused tests must cover:

- runtime ↔ primitive mapping for anchored and unanchored M01 states;
- canonical signed-64-bit strings, representative fixed-point residual integers, and malformed inputs;
- schema key/type/range/cross-field validation;
- deterministic JSON bytes;
- unknown codec and future schema rejection;
- migration ordering/missing-step behavior;
- first save, second save, primary/backup selection, highest-revision selection;
- corrupt/truncated/valid-but-invalid-schema candidates;
- every failure-injection stage;
- suspect-file preservation;
- candidate reconciliation commit success/failure and repeated-load idempotency;
- no device-wall-clock or file-timestamp authority.

### Negative and recovery checks

| Scenario | Method | Expected result |
|---|---|---|
| JSON number in integer field | Fixture or direct decode | Rejected; no cast |
| Malformed canonical integer | Matrix of strings | Stable error and field path |
| Unknown codec | Candidate fixture | Rejected; valid counterpart remains |
| Future schema | Candidate fixture | Rejected; no overwrite |
| Truncated primary | Real/memory storage | Backup selected; primary retained |
| Both candidates invalid | Real/memory storage | Recoverable failure; both retained |
| Temp write failure | Fault-injected storage | Prior committed snapshot remains |
| Temp validation failure | Fault-injected/corrupt temp | No promotion |
| Backup rotation failure | Fault-injected storage | Existing primary remains valid |
| Primary replacement failure | Fault-injected storage | Backup or prior primary remains valid |
| Save failure after reconciliation candidate | Working-copy integration test | Original runtime/anchor unchanged |
| Repeated successful load | Integration test | No duplicate trusted-time credit |

Do not leave generated saves, corrupt fixtures, owner logs, temporary directories, or test artifacts in the final diff except intentionally committed fixtures under `tests/fixtures/saves/`.

### Owner-run Windows automated checks

Codex must create:

```text
tools/test/owner/run_m02_owner_verification.ps1
```

Required script behavior:

1. Windows PowerShell 5.1 compatible.
2. Resolve repository root from script location.
3. Accept `-GodotBin`/`GODOT_BIN` and optional `-CommitSha`; Git CLI remains optional.
4. Log requested/detected revision, Windows/PowerShell/Godot versions, commands, exit codes, failed-step count, cleanup, and result.
5. Create a unique isolated directory under Windows temporary storage; do not use normal `user://saves/`.
6. Run the full Windows GUT suite.
7. Run the focused M02 suite.
8. Run an explicit import preflight.
9. Run the real-file M02 persistence trace against the isolated directory.
10. Verify revision-1/revision-2 writes, corrupted-primary fallback, diagnostic, and byte retention.
11. Exercise the documented Windows replacement/rename path and any safe negative cases included by the trace.
12. Verify unsupported codec/future schema cases did not overwrite valid files.
13. Remove the isolated directory and verify it is absent.
14. Rerun the clean full Windows GUT suite after corruption/recovery tests.
15. Return exit `0` only when every required automated step and cleanup passed.
16. Print the final generated log path.

No interactive checklist is required for M02 unless implementation unexpectedly introduces a player-visible or editor-only behavior. If that happens, stop and request scope approval rather than silently adding UI.

Expected owner invocation after Codex opens the PR:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
    -File .\tools\test\owner\run_m02_owner_verification.ps1 `
    -CommitSha "<PR_HEAD_SHA>"
```

## Manual verification

M02 has no player-facing manual flow. The owner-run PowerShell package is the Windows filesystem merge gate.

The generated log must demonstrate:

1. correct PR-head evidence handling without requiring Git CLI;
2. full and focused tests pass;
3. import preflight passes;
4. primary revision 1 and primary revision 2 are written through the real file implementation;
5. backup revision 1 exists after revision 2 commit;
6. corrupted primary is rejected;
7. backup revision 1 is selected;
8. corrupt primary bytes remain available after load;
9. isolated directory cleanup passes;
10. final clean suite passes;
11. automated result `PASS`, failed step count `0`, pending interactive checks `None for M02`, cleanup `PASS`.

## Save/load verification

M02 establishes the persistence contract, so save/load verification is the task rather than an auxiliary check.

| Scenario | Setup and save point | Reload, retry, or recovery action | Expected result |
|---|---|---|---|
| Minimal runtime round trip | M01 anchored and unanchored states | Map to primitive and reconstruct | Exact fields/invariants |
| JSON round trip | Valid schema-v1 primitive snapshot | Encode/decode | Exact values; deterministic bytes |
| First save | No files | Save revision 1, reload | Primary revision 1 selected |
| Backup rotation | Primary revision 1 | Save revision 2, reload | Primary revision 2; backup revision 1 |
| Corrupt primary | After revision 2 | Corrupt primary, load | Backup revision 1 selected; corrupt primary retained |
| Highest revision | Valid primary rev1, backup rev2 | Load | Rev2 selected |
| Both invalid | Corrupt both | Load | Recoverable failure; no mutation/deletion |
| Future schema | One candidate future, one current valid | Load | Future rejected; current selected |
| Atomic failure | Each documented injected stage | Save then load | At least one previous valid snapshot |
| Migration seam | Test-only old primitive fixture | Migrate sequentially | Valid v1 or stable missing-step failure |
| Reconciliation save failure | Plan and apply to candidate | Inject persistence failure | Original runtime/anchor unchanged |
| Reconciliation success/reload | Persist candidate | Reload/repeat sample | Candidate exact; zero duplicate credit |

The implementation must not use actual elapsed wall time in any test.

## Documentation updates

| Document | Required update |
|---|---|
| `docs/codex/MILESTONES.md` | Actual M02 implementation stage, verification state, realized paths, and `GATE-SAVE-SCHEMA` status |
| `docs/codex/ARCHITECTURE.md` | Realized mapper/codec/storage/transaction ownership and file sequence |
| `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | Exact schema-v1 keys, wire types, runtime mapping, result codes, and default path contract |
| `docs/codex/IMPLEMENTATION_RULES.md` | Only durable conventions exposed by the realized implementation |
| `docs/codex/TESTING_AND_VALIDATION.md` | Exact focused commands, fixtures, trace syntax, owner script, Windows matrix |
| `docs/codex/DECISIONS.md` | No new decision expected; stop if a real semantic/security choice is required |
| Design source-of-truth files | No change expected |
| `README.md` | Prototype save path/reset, focused tests, trace, and owner command |
| `docs/codex/OWNER_VERIFICATION_WORKFLOW.md` | No change expected unless a generic script/log defect is discovered |
| `docs/codex/PROMPT_TEMPLATE.md` | Do not modify |
| Current/future milestone prompts | Do not modify or create |

Do not mark M02 `Merged`, verification `Passed`, or `GATE-SAVE-SCHEMA` satisfied before those facts are true. A Codex implementation task may set `Pull request open` / `Partial` and leave owner Windows checks pending.

## Stop and ask conditions

Stop before implementing or expanding the affected part when any of the following occurs:

1. M01 is not merged/passed or its runtime fields materially differ from this prompt.
2. Current authoritative documents disagree on the schema-v1 key set or no-anchor mapping and the hierarchy does not resolve it.
3. Exact signed-64-bit parsing cannot be implemented safely in GDScript without a new dependency or a changed numeric contract.
4. Godot file APIs cannot provide the documented replacement/recovery behavior without a materially different transaction design.
5. Implementing safe Windows replacement requires native code, another GDExtension, administrator rights, or a new dependency.
6. A checksum, digest, encryption, compression, or binary container appears necessary.
7. The task would need a full gameplay schema, content catalog, application shell, autosave loop, save menu, Steam Cloud, or another later milestone.
8. A persistence design would overwrite or delete all valid/suspect candidates on a failure path.
9. A proposed solution would use device wall time or file timestamps for authoritative selection or progress.
10. A schema change requires a new Accepted decision or an explicit prototype reset policy not already approved.
11. Tests expose a pre-existing M01 failure that cannot be isolated safely.
12. The task is too large for one reviewable persistence pull request and needs an approved split.

Do not stop for ordinary class naming, file naming, internal result-object shapes, or test-helper choices that remain within the approved boundaries. Make the smallest clear choice, document it, and report it under assumptions.

Owner-run Windows checks being unavailable to Codex are not themselves a stop condition. Implement and verify the Linux scope, open the handoff for owner testing, and keep the merge gates pending.

## Deliverables

The completed M02 task must provide:

- schema-version-1 runtime/primitive mapping;
- exact canonical integer string codec;
- project-owned `SaveCodec` and `JSON_V1` implementation;
- validated envelope and stable result diagnostics;
- migration registry/seam and fixtures;
- storage abstraction plus real Godot file storage;
- primary/temp/backup atomic save and independent load-selection logic;
- suspect-file retention/preservation policy;
- reconciliation candidate transaction seam;
- focused unit and integration tests;
- representative valid/invalid fixtures;
- headless M02 persistence trace;
- `tools/test/owner/run_m02_owner_verification.ps1`;
- exact owner command and generated-log behavior;
- synchronized documentation;
- complete changed-file inventory;
- exact Linux verification evidence and disclosed pending Windows checks;
- no generated logs, disposable save directories, private paths, secrets, dependency changes, or unrelated work.

## Final response format

Use exactly these headings.

### Implementation completed

Summarize the persistence behavior and M02 developer outcome. Do not present owner-pending work as complete.

### Files changed

List every added, modified, renamed, or deleted file and its purpose. Identify inspected dependency/runtime files without implying they were modified.

### Verification

Report separately:

- Codex Cloud/Linux full and focused commands, Godot/GUT versions, test counts, exit codes, and results;
- integer/schema/codec negative matrices;
- migration and fault-injection checks;
- headless real-file trace and cleanup;
- source-ownership result;
- owner-run Windows script as `Pending owner verification`, `Passed`, or `Failed` based only on explicit owner evidence;
- acceptance criteria still unverified.

### Assumptions

List only assumptions not established by authoritative context. Distinguish safe implementation choices such as prototype basename or internal result-class naming from requirements.

### Known limitations and risks

State anything incomplete, provisional, environment-dependent, or not verified, including Windows rename behavior until owner evidence exists.

### Deferred work

List gameplay substates, application integration, UI, Steam Cloud, security deterrence, final filenames/slots, and other intentionally excluded later work.

### Suggested next task

Name M03 only after M02 is merged and `GATE-SAVE-SCHEMA` passes. Do not begin it.
