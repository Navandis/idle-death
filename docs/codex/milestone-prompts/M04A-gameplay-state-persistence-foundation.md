# Implementation slice M04A: Gameplay state and persistence foundation

**Prompt version:** v0.1  
**Prompt date:** 2026-07-15  
**Prompt status:** Approved  
**Work item type:** Implementation slice  
**Parent conceptual epic:** `M04 — Persistent Reaping simulation vertical slice`  
**Milestone definition:** `docs/codex/MILESTONES.md` — `### M04A — Gameplay state and persistence foundation`  
**Recommended task size:** Small-medium; one authoritative-state and schema-migration pull request  
**Scope-gate result:** Within guardrails at prompt draft; mandatory stop if actual work needs another primary owner, more than two cross-layer seams, more than approximately 35 non-documentation source/test files, or more than approximately 1,500 non-documentation code/test lines  
**Expected base branch or ref:** current `main` after the M03 completion, recalibration, and schema-version-2 governance package is committed  
**Planned prompt path:** `docs/codex/milestone-prompts/M04A-gameplay-state-persistence-foundation.md`

> This prompt authorizes only M04A's typed gameplay-state and persistence foundation. It does not authorize dispatch commands, elapsed production, output accumulation, reports, forecasts, new-game story behavior, player-facing UI, Steam integration, or any later implementation slice.

## Execution protocol

Before editing:

1. Read `AGENTS.md` completely.
2. Read every document and section listed under **Authoritative context**.
3. Inspect the current repository, persistence code, content registry, tests, fixtures, owner scripts, and `git status --short`.
4. Verify that M00–M03 are Merged and Passed and that `DEC-0033` and `DEC-0034` are Accepted.
5. Verify that schema version 1 is still the current executable schema and contains only the M01 timeline/time-authority state.
6. Verify that `SaveMigrationRegistry` has only a test seam and no production migration.
7. Verify that the M03 catalog builds successfully and exposes the exact IDs used by the representative fixture.
8. State the proposed state-class structure, versioned validator/mapper design, production migration registration, runtime persistence coordinator, failure-injection strategy, expected changed files, and verification plan before making non-trivial edits.
9. Re-evaluate the scope assessment against the actual repository. Stop and report before implementation if another primary subsystem owner, another major risk dimension, or material review-surface growth is required.

During implementation:

- Limit changes to M04A and its binary criteria.
- Keep domain state, schema primitives, byte codec, migration, storage, content compatibility, and runtime orchestration as explicit boundaries.
- Keep `SaveService` and the byte/storage layer independent of production content Resources. The higher-level runtime coordinator may receive a validated `ContentRegistry` or a narrow compatibility/lookup boundary.
- Preserve M01 fixed-point/time semantics, M02 atomic storage semantics, and M03 canonical content semantics.
- Do not use reflection, `var_to_str`/`str_to_var`, Resource duplication, scene duplication, or generic object dumping as the authoritative clone/serialization mechanism for mutable gameplay state.
- All authoritative integers use runtime `int` and canonical decimal strings at the primitive/JSON boundary.
- Validate historical schema before migration and current schema after migration.
- Perform migration and runtime construction on working candidates. Never expose or mutate live state before all validation and any required upgrade write succeeds.
- Never derive data from local date/time, timezone, file timestamps, registry values, or Steam.
- Add junior-readable comments that explain responsibility, ownership, units, version dispatch, migration order, content-boundary validation, transaction order, and failure preservation.
- Add or update every test needed to prove the behavior.
- Create the required M04A trace and Windows owner-verification script.
- Run every Codex-executable check and report exact commands, counts, and exit codes.
- Leave owner Windows verification `Pending owner verification` until the owner supplies a log for the tested PR head.
- Do not create, rewrite, broaden, or approve this prompt or a future prompt.

Do not describe M04A as complete while a merge-gate criterion is failed, blocked, or pending.

## Objective

Implement the first typed gameplay-state aggregate and make save schema version 2 the current writer through a real sequential migration from frozen schema version 1. The result must support exact construction, validation, deep cloning, schema-version-2 round trips, content-aware runtime validation, and transactional historical-save upgrade without dispatching or advancing a Reaping.

## Player or developer outcome

From focused tests and one headless trace, a developer can:

- construct a hand-calculable Gloamwood/Man-at-Arms state using canonical M03 IDs;
- validate every nested invariant without a scene tree;
- deep-clone it and prove nested mutations do not affect the source;
- save and reload schema version 2 exactly;
- load a canonical schema-version-1 foundation save;
- validate and migrate it to version 2 without inventing gameplay progress;
- preserve simulation time, time authority, content revision, metadata, and offline-resolution identity;
- atomically persist the upgrade with one save-revision increment;
- retain a recoverable version-1 source under the M02 backup policy;
- fail migration or persistence without exposing migrated runtime state or losing the original valid bytes;
- rerun an already-current version-2 load without rewriting it;
- execute the complete Windows proof through one PowerShell command and shareable UTF-8 log.

## Authoritative context

| Priority | Source | Required sections, labels, or records | Why it applies |
|---:|---|---|---|
| 1 | `AGENTS.md` | Full file, especially architecture, save/time, comments, testing, and scope rules | Repository-wide operating contract |
| 2 | `docs/codex/MILESTONES.md` | §§3–7; `GATE-SLICE-SCOPE`; `GATE-GAMEPLAY-SCHEMA`; `### M04A` | Approved slice, dependencies, and merge gates |
| 3 | `docs/codex/MILESTONE_RECALIBRATION_PROPOSAL.md` | §§2–8 | Lettered-slice and review-surface policy |
| 4 | `docs/codex/PROMPT_TEMPLATE.md` | §§2.1–2.4; scope assessment; completion rules | Prompt ownership and split gate |
| 5 | `docs/codex/OWNER_VERIFICATION_WORKFLOW.md` | Complete script/log/cleanup/evidence rules | Required Windows package |
| 6 | `docs/codex/DECISIONS.md` | `DEC-0007`, `DEC-0011`–`DEC-0013`, `DEC-0019`–`DEC-0023`, `DEC-0025`, `DEC-0029`, `DEC-0030`, `DEC-0033`, `DEC-0034` | State ownership, schema, inventory, time, migration, content, scope |
| 7 | `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | §§2, 5–9, 12, 14, 17; M01/M02 contracts; **Approved M04A schema-version-2 and migration contract** | Exact runtime and wire shapes |
| 8 | `docs/codex/ARCHITECTURE.md` | Runtime state, commands/queries, persistence layers, migration, content registry, clone/forecast boundaries | Existing ownership and transaction flow |
| 9 | `docs/codex/IMPLEMENTATION_RULES.md` | Junior-readable comments, state classes, deterministic collections, persistence, validation, diagnostics, tests | Engineering conventions |
| 10 | `docs/codex/TESTING_AND_VALIDATION.md` | §§3–6, 7.1, 9, 12, 15–21 | Canonical commands, migration matrices, slice evidence |
| 11 | `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md` | persistent authoritative state, deterministic/offline equivalence, save integrity | Broader invariant context |
| 12 | `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md` | global safeguards, save checkpoints, canonical Gloamwood/Man-at-Arms state | Prototype context without implementing beats |
| 13 | Current implementation | files listed under **Repository state** | Real baseline and seams to preserve |

This prompt is authoritative only within M04A. It does not weaken accepted decisions or authorize later-slice behavior. Stop and report unresolved source conflicts.

## Repository state

The expected baseline at task start is:

| Item | Expected state | Evidence or path |
|---|---|---|
| Completed milestones | M00–M03 Merged and Passed | `docs/codex/MILESTONES.md` |
| Current runtime state | `GameState` owns only `simulation_time_msec`; `TimeAuthorityState` is separate | `src/domain/game_state.gd`, `src/domain/time_authority_state.gd` |
| Fixed point | One scale of `1_000_000`, exact explicit-period accumulation and carry | `src/domain/fixed_point.gd` |
| Current schema | `SaveEnvelope.CURRENT_SCHEMA_VERSION = 1`; v1 `game_state` contains only `simulation_time_msec` | `src/persistence/save_envelope.gd` |
| Current mapper/validator | One v1 mapper and `validate_v1`; v1 currently compares against current-version constant | `save_schema_mapper.gd`, `save_schema_validator.gd` |
| Migration seam | Sequential registry exists; only test-only step coverage exists | `save_migration_registry.gd`, `test_migration_registry.gd` |
| Storage | Deterministic JSON codec and primary/temporary/backup/suspect transaction pass | `src/persistence/`, M02 tests/trace |
| Runtime persistence | `SaveService` maps minimal state and reads/migrates candidates; it has no production content compatibility orchestration | `src/persistence/save_service.gd` |
| Content | Validated explicit catalog with current revision `prototype-content-r1` and compatible `prototype-m02` | `content/prototype_content_catalog.tres`, `ContentRegistry` |
| Missing state | No Inventory/Form/Threshold/Reaping/Progression runtime classes or schema-v2 fixtures | Repository inspection |
| Missing behavior | No dispatch, production, report, forecast, Hall, tutorial, or application shell | Repository inspection |
| Working tree | Clean except for M04A task changes | `git status --short` |

If the repository differs materially, report it before implementing dependent behavior.

## Dependencies

| Dependency or gate | Required state | Required before | Verification |
|---|---|---|---|
| M03 / `GATE-CONTENT-CATALOG` | Merged, Passed, satisfied | Implementation | Milestone record and full content tests |
| `DEC-0034` / `GATE-GAMEPLAY-SCHEMA` | Accepted / satisfied for prompt drafting | Implementation | Decision record |
| `GATE-SLICE-SCOPE` | Assessment remains within guardrails | PR and merge | This prompt and actual-versus-estimated handoff |
| M02 persistence | Full codec/storage/migration-seam regression remains passing | Merge | Focused and full tests |
| Owner Windows environment | Godot 4.7 console executable discoverable | Merge | Generated M04A owner log |

## Scope and review-surface assessment

| Assessment item | Approved estimate or result |
|---|---|
| Parent conceptual epic | M04 |
| Primary subsystem owner | Typed gameplay-state persistence boundary |
| Principal behavior/state transition | Construct/validate/clone schema-v2 state and transactionally upgrade v1 to v2 |
| New authoritative state ownership | Yes — six bounded state families under `GameState` |
| Save-schema or migration change | Yes — one current-version advance and one production `v1 -> v2` step |
| Deterministic algorithm/boundary work | Bounded migration/clone/validation only; no production simulation |
| New player-facing UI flow | None |
| Native/platform integration | None |
| Bulk authored content | None; existing M03 content only |
| Live/offline/forecast equivalence | None |
| Exactly-once/transactional progression | Atomic migration persistence and one revision increment; no gameplay rewards |
| Independently testable domain services | Two expected: state validator/clone boundary and runtime persistence coordinator |
| Cross-layer integration seams | Two: domain ↔ primitive persistence; domain/content validation ↔ catalog lookup |
| Estimated non-documentation source/test files | Approximately 20–32, excluding generated `.uid` files |
| Estimated non-documentation code/test line delta | Approximately 900–1,400, excluding `.uid` and documentation |
| Owner verification package | `tools/test/owner/run_m04a_owner_verification.ps1`; automated log only |
| Mandatory split trigger crossed? | No at draft estimate |
| Exception rationale/approval evidence | Not applicable |

If implementation requires dispatch behavior, production resolution, a new player-facing flow, more than two seams, more than approximately 35 source/test files, or more than approximately 1,500 code/test lines, stop and request a revised split/prompt.

## Scope

Implement only:

1. the M04A typed gameplay-state subset and explicit deep cloning;
2. structural and content-aware domain validation;
3. schema version 2 and version-aware schema dispatch;
4. explicit current runtime mapping;
5. the production sequential `v1 -> v2` migration;
6. a working-candidate runtime persistence coordinator that validates and atomically persists required upgrades before exposing runtime;
7. immutable v1 and representative v2 fixtures;
8. focused unit/integration tests, deterministic trace, Windows owner script/log, and required documentation updates.

Use the smallest architecture that satisfies these contracts. Reuse M02's codec/storage transaction rather than replacing it.

## Non-goals

Do not implement or refactor:

1. dispatch, recall, redispatch, assignment commands, tether grants, or assignment UI;
2. elapsed production, backlog/Essence/Mastery changes, channel accumulation, discovery, forecasts, reports, milestones, guarantees, or progression effects;
3. new-game creation, opening-four behavior, Brand, tutorial, story, Archive, Halls, Recollections, or Soulweave;
4. a gameplay autoload, application shell, navigation, scenes, or player-facing save/reset UI;
5. Steam initialization, trusted-time-provider behavior, closed-session resolution, Steam Cloud, or release packaging;
6. multiple slots, account sync, compression, binary codec, encryption, signatures, DRM, or tamper-proof claims;
7. schema fields for later state solely to avoid future migrations;
8. content-ID changes or balance changes;
9. generic reflection serialization, arbitrary object graphs, or mutable state stored in `.tres` Resources;
10. broad cleanup, dependency updates, engine changes, or unrelated moves.

## Required behavior

| ID | Required behavior | Source trace |
|---|---|---|
| `RB-01` | `GameState` explicitly owns the approved M04A typed state families in addition to `simulation_time_msec`. | M04A definition; data contract |
| `RB-02` | Runtime state classes are scene-tree independent `RefCounted`/plain GDScript objects with documented units and ownership. | `DEC-0007`; implementation rules |
| `RB-03` | Inventory entries store non-negative whole totals and reservation maps; reserved sum cannot exceed total. | `DEC-0013` |
| `RB-04` | Form state stores reveal/awakening/Mastery/source fields and validates cross-field consistency. | Data contract §9.5 |
| `RB-05` | Threshold state stores knowledge, availability, lifecycle, backlog, persistent returns, familiarity, and acquisition maps; zero backlog and lifecycle remain consistent. | `DEC-0019`; data contract |
| `RB-06` | Acquisition state stores normalized progress below `FixedPoint.SCALE`, carry, and optional banked diagnostic count; it performs no accumulation in M04A. | `DEC-0027`, `DEC-0028` |
| `RB-07` | Reaping records use Threshold keys and store only structural assignment/continuity fields; M04A does not issue commands or advance them. | M04A/M04B boundary |
| `RB-08` | Tether capacity is a non-negative unscaled integer; active Reaping count may not exceed it. | `DEC-0020` |
| `RB-09` | Canonical IDs resolve to the correct M03 definition types; invalid or display-name keys fail. | `DEC-0009`, `DEC-0031` |
| `RB-10` | Empty gameplay maps plus zero tether capacity form a valid pre-game state for historical migration. | `DEC-0034` |
| `RB-11` | One representative fixture uses canonical Gloamwood/Man-at-Arms/Writ/Essence/channel IDs and hand-checkable values. | M04A demonstration |
| `RB-12` | Deep clone copies every nested object, array, and dictionary. Mutating the clone cannot change the source. | Forecast-ready ownership boundary |
| `RB-13` | Clone and mapper code are explicit; no reflection, generic property dump, text serialization, or Resource duplication is used as authority. | `DEC-0011`; implementation rules |
| `RB-14` | `SaveEnvelope` keeps explicit v1/v2 constants and `CURRENT_SCHEMA_VERSION = 2`; codec remains `JSON_V1`. | `DEC-0034` |
| `RB-15` | Frozen v1 key sets, validator, and fixture remain unchanged in meaning after v2 becomes current. | `DEC-0034` |
| `RB-16` | Version dispatch validates a source with its own validator before migration. | `DEC-0034` |
| `RB-17` | Version-2 snapshot uses exactly the approved nested key sets and canonical integer strings. | Data contract M04A section |
| `RB-18` | Runtime-to-snapshot writes only v2 and requires an explicit current content revision from the validated caller. | `DEC-0029`, `DEC-0034` |
| `RB-19` | Snapshot-to-runtime constructs a working candidate and runs complete structural/domain validation before return. | Transaction safety |
| `RB-20` | Production migration registration contains an explicit pure `v1 -> v2` step and no fictional versions. | `DEC-0034` |
| `RB-21` | The pure migration deep-copies, sets version 2, preserves all v1 authority, and adds only canonical empty gameplay state. | `DEC-0034` |
| `RB-22` | Pure migration preserves source `save_revision` and `content_revision`; it grants/unlocks nothing. | `DEC-0034` |
| `RB-23` | Content compatibility is evaluated through the caller-supplied validated registry/policy before a migrated upgrade is persisted or exposed. | `DEC-0029`; `DEC-0034` |
| `RB-24` | A required persisted upgrade increments save revision exactly once with overflow checking. | `DEC-0034` |
| `RB-25` | Migration upgrade uses the existing temporary/validate/backup/promote transaction and returns runtime only after write success. | M02 transaction; `DEC-0034` |
| `RB-26` | Any source-validation, migration, target-validation, domain/content-validation, revision-overflow, or write failure preserves the original valid candidate and exposes no migrated live state. | `DEC-0034` |
| `RB-27` | Already-current v2 loads do not rewrite, rotate files, or increment save revision. | `DEC-0034` |
| `RB-28` | Unknown future schema or unknown content revision fails without overwrite. | M02/M03 compatibility |
| `RB-29` | Candidate selection still uses highest valid save revision and preserves invalid-primary suspect bytes. | M02 |
| `RB-30` | New v2 save/load and migrated v1 load preserve `TimeAuthorityState` exactly and do not change trusted-time semantics. | `DEC-0021` |
| `RB-31` | No migration, validation, selection, ID, or diagnostic depends on local time or file timestamps. | `DEC-0021`, `IF-REQ-17` |
| `RB-32` | Historical v1 and representative v2 fixtures are committed; generated test saves/logs are not. | Testing §9.4 |
| `RB-33` | A reset helper, if added, is explicit, preserves/archive the old file, and is not invoked by supported load. | `DEC-0034` |
| `RB-34` | M04A trace and owner script prove real-file upgrade/backup/cleanup and full regression. | Testing §21; `DEC-0025` |
| `RB-35` | All changed non-trivial scripts contain junior-readable responsibility, state, unit, version, and failure-order comments. | `AGENTS.md`; implementation rules |
| `RB-36` | Actual implementation remains inside the approved scope assessment or stops for a revised owner-approved prompt. | `DEC-0033` |

## State transitions

| ID | Initial state | Trigger | Required resulting state | Failure/recovery | Persistence/diagnostic effect |
|---|---|---|---|---|---|
| `ST-01` | No gameplay state | Construct canonical empty state | Valid empty maps, zero tether capacity, existing simulation time | Invalid input returns typed failure; no partial object | None |
| `ST-02` | Valid representative state | Deep clone | Exact independent clone | Clone failure returns no partial clone | None |
| `ST-03` | Valid state and registry | Validate | Success with no mutation | Aggregated/actionable failure paths | None |
| `ST-04` | Valid runtime state | Save new snapshot | Schema v2 primary through atomic transaction | Failure leaves previous valid save | Revision supplied/incremented by caller policy |
| `ST-05` | Valid v2 primary | Load | Exact typed runtime; no rewrite | Invalid candidate falls back per M02 | Selected role/diagnostics only |
| `ST-06` | Valid v1 candidate | Load candidate | Source validated, pure v2 candidate created | Source/migration failure preserves v1 | Migration-required diagnostic |
| `ST-07` | Valid migrated candidate and compatible content | Commit upgrade | V2 persisted with revision +1; runtime exposed | Atomic failure exposes no runtime and preserves v1 | Prior valid source retained under backup policy |
| `ST-08` | Valid migrated schema but invalid domain/content | Validate candidate | No live state and no persisted upgrade | Preserve source and report field/code | No file replacement |
| `ST-09` | Valid v2 candidate | Repeated load | Same runtime and revision; no write | Ordinary fallback on corruption | No rotation/revision change |
| `ST-10` | Future schema candidate | Load | Rejected | Preserve all files | `SAVE_MIGRATION_FUTURE_SCHEMA` or equivalent |
| `ST-11` | V1 save revision at signed-64 max | Persist upgrade | Rejected before mutation | Preserve source | Stable overflow diagnostic |
| `ST-12` | Corrupt primary plus valid historical backup | Load/upgrade | Select valid backup; preserve corrupt primary; persist valid v2 primary only after validation | Failure preserves valid backup and suspect bytes | Role and rejection diagnostics retained |

## Data and content

### Schema constants

```text
SCHEMA_VERSION_V1 = 1
SCHEMA_VERSION_V2 = 2
CURRENT_SCHEMA_VERSION = 2
CODEC_JSON_V1 = JSON_V1
```

### Version-2 `game_state` keys

```text
simulation_time_msec
inventory
forms
thresholds
reapings
progression
```

Use the exact nested shapes in `DATA_AND_CONTENT_CONTRACTS.md` under **Approved M04A schema-version-2 and migration contract**. Do not add `story`, `tutorial`, `halls`, `recollections`, `report_history`, forecast data, effective rates, ETAs, or presentation fields.

### Representative fixture

The committed test fixture should be small and hand-calculable while using production IDs. It may directly contain:

- one revealed/awakened `FORM_MAN_AT_ARMS` state with zero or representative Mastery;
- one `THR_GLOAMWOOD` state bounded by the authored backlog;
- one structurally valid `WRIT_STANDARD` Reaping record without invoking dispatch;
- `RES_ESSENCE` and representative whole inventory counts;
- one or more zero/representative Gloamwood acquisition records;
- tether capacity one.

This is test support, not the production new-game bootstrap.

### Migration default

`v1 -> v2` adds only:

```json
{
  "inventory": {"entries": {}},
  "forms": {},
  "thresholds": {},
  "reapings": {},
  "progression": {"command_tether_capacity": "0"}
}
```

It preserves source `content_revision` and all M01 authority.

## UI and presentation

Not applicable — M04A adds no player-facing scene, screen, Inspector-authored Resource type, or interaction. The required developer presentation is the deterministic headless trace and owner log.

## Architecture constraints

- `GameState` owns mutable gameplay state; content Resources remain immutable definitions.
- `TimeAuthorityState` remains separate from `GameState` and from platform providers.
- Schema primitives are not the runtime object model.
- Codec and storage remain schema/content agnostic.
- The runtime persistence coordinator owns the cross-boundary sequence without becoming a gameplay service.
- Content compatibility and canonical-ID/type lookup come from the validated M03 registry/policy supplied by the caller.
- No scene, Node, autoload, UI, Steam, wall clock, or filesystem timestamp is authoritative.
- All collection iteration affecting validation/output is deterministic.
- No future slice is implemented merely because its fields are visible in the broader architecture documents.

## Expected files

This is an informed estimate, not permission for unrelated edits.

| Path or area | Expected action | Purpose |
|---|---|---|
| `src/domain/game_state.gd` | Modify | Own typed M04A state and explicit clone/validation entry points |
| `src/domain/state/` or equivalent bounded files | Add | Inventory, Form, Threshold/acquisition, Reaping, Progression state |
| `src/domain/game_state_validator.gd` or equivalent | Add | Content-aware domain invariants |
| `src/persistence/save_envelope.gd` | Modify | Explicit v1/v2/current constants and key sets |
| `src/persistence/save_schema_validator.gd` | Modify | Version-specific validation and dispatch |
| `src/persistence/save_schema_mapper.gd` | Modify | V2 runtime mapping |
| `src/persistence/save_migration_registry.gd` and step file | Modify/Add | Production `v1 -> v2` registration and pure step |
| `src/persistence/save_service.gd` | Modify narrowly | Version-aware candidate selection/upgrade support |
| `src/persistence/game_state_persistence_coordinator.gd` or equivalent | Add | Domain/content validation and atomic upgrade-before-exposure |
| `tests/unit/m04a/` | Add | State, validator, clone, schema, mapper, migration matrices |
| `tests/integration/m04a/` | Add | Storage upgrade/failure/content compatibility/round trip |
| `tests/fixtures/saves/` | Add/Modify | Immutable v1 and representative v2 fixtures |
| `tools/test/m04a/m04a_state_persistence_trace.gd` | Add | Deterministic real-file demonstration |
| `tools/test/owner/run_m04a_owner_verification.ps1` | Add | One-command Windows evidence/log |
| Maintained docs | Modify as required | Realized schema/classes/commands/status |

Do not create empty directories. Explain any material deviation or file-count growth before implementation continues.

## Acceptance criteria

| ID | Pass condition | Verification evidence | Merge gate? |
|---|---|---|---:|
| `AC-01` | Typed M04A state constructs and validates independently of scene/UI/platform. | Focused state tests and trace | Yes |
| `AC-02` | The representative fixture uses exact M03 IDs and authored bounds. | Fixture/registry tests | Yes |
| `AC-03` | Explicit deep clone is independent at every nested level. | Mutation-isolation matrix | Yes |
| `AC-04` | Invalid state cases return stable field-level failures without partial mutation. | Negative domain matrix | Yes |
| `AC-05` | Frozen v1 constants, key set, validator, and immutable fixture remain supported. | Historical-schema tests | Yes |
| `AC-06` | V2 exact key/type/integer-string contract passes; malformed variants fail. | Schema matrix | Yes |
| `AC-07` | Runtime v2 primitive/JSON round trip is exact for ordinary and boundary integers. | Mapper/codec tests | Yes |
| `AC-08` | Production `v1 -> v2` validates source, deep-copies, preserves all v1 authority, and adds only canonical empty gameplay state. | Migration unit tests and trace | Yes |
| `AC-09` | Pure migration preserves save/content revisions; persisted upgrade increments save revision exactly once. | Migration/transaction tests | Yes |
| `AC-10` | Domain/content compatibility is proven before upgrade persistence or live-state exposure. | Coordinator integration tests | Yes |
| `AC-11` | Every migration/validation/write failure preserves the original valid candidate and exposes no migrated runtime. | Failure-injection matrix | Yes |
| `AC-12` | Successful upgrade retains a recoverable prior valid snapshot under M02 roles. | Memory and real-file trace | Yes |
| `AC-13` | Already-current v2 load causes no write, rotation, or revision change. | Storage spy/test | Yes |
| `AC-14` | Unknown future schema and incompatible content revision reject without overwrite. | Negative integration tests | Yes |
| `AC-15` | New runtime saves write v2 with explicit current content revision. | Save integration test | Yes |
| `AC-16` | TimeAuthorityState and no-anchor mapping remain exact through v2 and migration. | Regression and migration tests | Yes |
| `AC-17` | No local-time/file-time/platform source is introduced. | Source-ownership test/review | Yes |
| `AC-18` | Trace proves clone, v2 round trip, real-file v1 upgrade, backup, no-repeat rewrite, and cleanup. | Trace output, exit 0 | Yes |
| `AC-19` | Linux focused/import/trace/full suite pass. | Exact commands and exit codes | Yes |
| `AC-20` | Windows owner script passes full/focused/import/trace/cleanup/full and produces one complete log. | Explicit owner log for PR head | Yes |
| `AC-21` | No gameplay action, simulation, UI, Steam behavior, content change, dependency, private path, or generated log enters the diff. | Diff/status review | Yes |
| `AC-22` | Changed non-trivial GDScript follows junior-reader comment rules. | Code review | Yes |
| `AC-23` | Maintained documents made inaccurate are synchronized. | Documentation/link review | Yes |
| `AC-24` | Actual scope remains within the approved assessment or implementation stopped for an owner-approved prompt revision. | Actual-versus-estimated handoff | Yes |

A pending Windows owner result keeps M04A verification `Partial` and prevents merge.

## Automated verification

### Codex Cloud or Linux

Run in this order and report exact counts/exit codes:

```bash
git status --short

./tools/test/run_gut.sh -- \
  -gdir=res://tests/unit/m04a \
  -gdir=res://tests/integration/m04a

godot --headless --path . --import

godot --headless --path . \
  -s res://tools/test/m04a/m04a_state_persistence_trace.gd \
  -- --save-root "$(mktemp -d)"

./tools/test/run_gut.sh

git diff --check
git status --short
```

The trace invocation may use a repository-owned helper that creates and cleans its disposable directory; do not leave the example `mktemp` directory behind. Report the exact realized safe command.

### Required negative/recovery matrix

At minimum cover:

- negative/out-of-range integers and malformed canonical strings;
- duplicate/unsorted set-like arrays;
- reservation sum above total;
- unresolved and wrong-type item/Form/Threshold/Writ/channel IDs;
- invalid backlog/lifecycle combinations;
- acquisition progress at or above scale and carry outside channel period;
- active Reaping with unawakened Form, wrong Threshold key, or tether over-capacity;
- shallow-clone mutation leaks;
- v1 source invalid before migration;
- migration missing step/failure;
- v2 target invalid after migration;
- content revision incompatible;
- save-revision overflow;
- each atomic-write failure point during upgrade;
- corrupt primary with valid historical backup;
- both candidates invalid;
- future schema;
- already-current no-rewrite;
- no local-time source ownership violation.

No deliberately failing fixture or generated save/log remains in the final diff.

### Owner-run Windows automated checks

Codex must add:

```text
tools/test/owner/run_m04a_owner_verification.ps1
```

Expected owner invocation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
    -File .\tools\test\owner\run_m04a_owner_verification.ps1 `
    -CommitSha "<PR_HEAD_SHA>"
```

The script follows `OWNER_VERIFICATION_WORKFLOW.md`, uses the canonical Godot console discovery contract, keeps Git optional, uses a unique isolated Windows temporary directory, captures complete output, tolerates prior ignored logs, and runs:

1. Godot version validation;
2. full GUT before;
3. focused M04A suite;
4. explicit import;
5. M04A real-file state/migration trace;
6. cleanup and proof the isolated directory is absent;
7. full GUT after;
8. artifact audit and final summary.

Expected summary:

```text
Automated result: PASS
Failed step count: 0
Pending interactive checks: None for M04A
Cleanup result: PASS
Log path: <generated path>
```

No interactive checklist is required.

## Manual verification

| Step | Actor/environment | Action | Expected result | Merge gate? |
|---:|---|---|---|---:|
| 1 | Owner Windows | Pull and confirm the exact M04A PR head in GitHub Desktop | Branch/head matches supplied `-CommitSha` | Yes |
| 2 | Owner Windows | Run the generated M04A PowerShell script | Automated PASS, zero failed steps, cleanup PASS | Yes |
| 3 | Owner | Upload or quote the generated log | Evidence identifies PR head, versions, commands, trace, and results | Yes |

There is no editor, visual, audio, gameplay, A/B, or Steam observation in M04A.

## Save/load verification

M04A changes authoritative state and advances the schema.

| Scenario | Setup/save point | Reload/recovery action | Expected result |
|---|---|---|---|
| V2 round trip | Save representative typed fixture | Load current snapshot | Exact state/time/content equality |
| V1 upgrade | Canonical v1 primary | Load through coordinator | Valid v2 primary, revision +1, prior v1 recoverable, canonical empty gameplay state |
| Upgrade write failure | Valid v1 source plus injected failure at each transaction stage | Retry load | Original/fallback remains valid; no migrated runtime exposed |
| Invalid content | Structurally valid historical/current snapshot with incompatible revision | Load | Reject without persisted upgrade or overwrite |
| Future schema | Version above current | Load | Typed future-version failure; bytes preserved |
| Already current | Valid v2 primary | Load repeatedly | No rewrite, rotation, or revision increment |
| Corrupt primary | Corrupt primary plus valid v1/v2 backup | Load | Select highest valid candidate, retain corrupt bytes, migrate only when required |

## Documentation updates

| Document | Required update |
|---|---|
| `docs/codex/MILESTONES.md` | M04A implementation/verification status and realized paths/counts |
| `docs/codex/ARCHITECTURE.md` | Realized typed state, version-dispatch, and upgrade-before-exposure flow |
| `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | Final exact v2 classes/keys/diagnostics if implementation differs from approved target |
| `docs/codex/IMPLEMENTATION_RULES.md` | Versioned validation/migration conventions if new general rules emerge |
| `docs/codex/TESTING_AND_VALIDATION.md` | Exact focused commands, fixtures, trace, and owner package |
| `docs/codex/OWNER_VERIFICATION_WORKFLOW.md` | No change expected unless a generic script defect is found |
| `docs/codex/DECISIONS.md` | No new decision expected; do not rewrite `DEC-0034` to fit an implementation shortcut |
| Design source of truth | No change expected |
| `README.md` | Developer save-version/migration/trace commands where useful |

## Stop conditions

Stop and report before continuing if:

1. the current repository does not match the stated baseline;
2. schema v1 cannot be retained unchanged as a supported input;
3. the proposed v2 shape conflicts with an accepted state/content decision;
4. content compatibility cannot remain outside `SaveService` without a new architecture decision;
5. migration cannot preserve original valid bytes under the current storage transaction;
6. dispatch, production, new-game bootstrap, report, forecast, or UI behavior becomes necessary;
7. another primary subsystem owner or more than two cross-layer seams are required;
8. the estimated non-documentation source/test file count exceeds approximately 35 or code/test delta exceeds approximately 1,500 lines;
9. implementation suggests a reset-only policy or removal of v1 support;
10. a new dependency, codec, security claim, platform feature, or local-time source appears necessary;
11. a listed merge-gate check cannot be executed or produces a failure.

## Final response format

Use exactly these headings from `AGENTS.md`:

### Implementation completed

Summarize only implemented M04A behavior, including schema versions, migration order, candidate validation, clone/state ownership, and owner package.

### Files changed

List every changed file and purpose. Include actual non-documentation source/test file count and code/test line delta versus the approved estimate.

### Verification

Separate Codex/Linux evidence from `Pending owner verification`. List exact commands, test counts, trace markers, failure-injection coverage, and exit codes.

### Assumptions

State any narrow assumption that did not change accepted semantics.

### Known limitations and risks

State pending Windows evidence, unsupported versions, deferred reset UI, and any measured scope risk.

### Deferred work

Name M04B dispatch/recall, M04C simulation, M04D accumulation, M04E forecast/report, and all later epics explicitly.

### Suggested next task

Normally: owner-run M04A Windows verification. Do not draft M04B.
