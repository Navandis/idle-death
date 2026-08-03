> **Status: Superseded by DEC-0045**
> **Execution: Do not execute**
> **Historical outcome: PR #23 closed unmerged at f68e6eac3347cde1b5347ce2d70cc4ce12ac3610**
> **Replacement sequence: M04E2R1 -> M04E2R2 -> M04E2P1 -> M04E2B**

# Implementation slice M04E2A2: Report runtime state and schema-v4 persistence (historical, non-executable)

**Prompt version:** v0.1  
**Prompt date:** 2026-07-23  
**Prompt status:** Approved  
**Work item type:** Implementation slice  
**Parent conceptual epics:** M04 / M04E / M04E2 / M04E2A  
**Milestone definition:** `docs/codex/MILESTONES.md`  
**Architecture authority:** Accepted `DEC-0043`, accepted `DEC-0044`, and carried-forward report semantics from superseded `DEC-0041`/`DEC-0042`  
**Planning document:** `docs/codex/M04E2A2_PLANNING.md`  
**Expected base:** current `main` after PR #22 merge commit `afd390e8338a198d76938eef5ddcf35718ec189c`  
**Feature branch:** `codex/implement-m04e2a2`  
**Pull-request target:** `main`  
**Approved PR title after prompt approval:** `M04E2A2: Add report state and schema-v4 persistence`  
**Repository prompt path:** `docs/codex/milestone-prompts/M04E2A2-report-state-schema-v4-persistence.md`

> This prompt authorizes one authoritative report-state family, schema version 4, pure sequential migration, exact mapping/validation, and persistence proof. It does not authorize report ingestion, report reads, snapshot commands, offline classification, history pruning, UI, trusted time, or atomic simulation/report coordination.

## Approval gate

Do not begin implementation until the project owner explicitly confirms:

```text
M04E2T2: Merged/Passed
M04E2A2 definition: Approved
M04E2A2 prompt: Approved v0.1 or later
GATE-REPORT-SCHEMA: Satisfied
GATE-SLICE-SCOPE: Satisfied
Codex desktop workflow: Approved
```

No new decision entry is required to execute the maintained contract. Stop and request a decision before implementation if inspection shows that report semantics, state ownership, schema meaning, or migration behavior must change.

## Repository delivery contract

Work in a new Codex desktop task created from updated `main`.

Before editing:

1. fetch and fast-forward local `main` from `origin/main`;
2. verify `main` contains merge commit `afd390e8338a198d76938eef5ddcf35718ec189c` or a later explicitly owner-approved planning baseline;
3. create and switch to `codex/implement-m04e2a2` before modifying files;
4. verify the current branch is not `main`;
5. report the starting SHA and clean tracked state.

After implementation and local verification:

1. commit all intended changes on `codex/implement-m04e2a2`;
2. prepare the PR body in a temporary file outside the repository;
3. run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
    -File .\tools\codex\publish_milestone_pr.ps1 `
    -RepoRoot '<repository root>' `
    -ExpectedBranch 'codex/implement-m04e2a2' `
    -BaseBranch 'main' `
    -Title 'M04E2A2: Add report state and schema-v4 persistence' `
    -BodyFile '<temporary PR description file>'
```

4. report the PR number, URL, branch, and exact head SHA;
5. stop.

Do not commit or push directly to `main`. Do not merge, auto-merge, close, approve, delete the branch, force-push, rewrite published history, or create a replacement PR. Corrections update the same branch and PR. Only the owner may merge or close.

## Completed prerequisite

M04E2T2 merged through PR #22 from final head `00bd7d1ce27817b508eb0aac1663d1de48353237` at merge commit `afd390e8338a198d76938eef5ddcf35718ec189c`.

Final exact-head owner evidence passed:

```text
full GUT before/after: 178/178 tests, 2,832 assertions
focused M04C-M04E2T2: 74/74 tests, 1,291 assertions
import: PASS
15 exact M04E2T2 markers: PASS
missing-root negative trace: PASS
cleanup and artifact audit: PASS
failed steps: 0
interactive checks: none
```

The final targeted and unrestricted reviews were clean. The M04E2T2 scope exception applies only to that completed slice.

## Required reading

Read completely before editing:

- `AGENTS.md`;
- `docs/codex/CODEX_DESKTOP_WORKFLOW.md`;
- accepted `DEC-0033`, `DEC-0034`, `DEC-0043`, and `DEC-0044`;
- the report semantics carried forward from `DEC-0041` and `DEC-0042`;
- `docs/codex/M04E2A2_PLANNING.md`;
- `docs/codex/M04E2_TRANSACTION_REDESIGN_PLAN.md`;
- `docs/codex/M04E2_IMPLEMENTATION_POSTMORTEM.md`;
- `docs/codex/ARCHITECTURE.md`, especially `GameState`, reports, and persistence;
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`, especially the deferred M04E2A2 contract;
- `docs/codex/IMPLEMENTATION_RULES.md`;
- `docs/codex/TESTING_AND_VALIDATION.md` M04E2T2 completion and M04E2A2 validation package;
- `docs/codex/OWNER_VERIFICATION_WORKFLOW.md`;
- current `GameState`, `GameStateValidator`, `SaveEnvelope`, `SaveSchemaMapper`, `SaveSchemaValidator`, `SaveMigrationRegistry`, `GameStatePersistenceCoordinator`, `SaveService`, and frozen fixtures/tests;
- current M04A, M04D1, M04E2T1, and M04E2T2 persistence and migration tests.

PR #17 and PR #18 may be inspected only for accepted malformed-save categories, black-box report-state scenarios, and failure-preservation lessons. Do not copy or cherry-pick their report-state, `ReportService`, validator, schema, trace, or test implementation wholesale.

## Objective

Add one authoritative report-state aggregate family to `GameState`, advance the current writer to schema version 4, implement exact runtime and primitive validation, add a pure `v3 -> v4` migration, and prove atomic persistence and round-trip behavior.

After this slice, a developer can:

1. create canonical empty report state at any valid simulation cursor;
2. construct a valid fixture-populated report state without using a production mutator;
3. deep-clone and copy the complete report state with no shared mutable children;
4. map a valid runtime state to exact schema-v4 primitives and back;
5. load a frozen schema-v3 save and migrate prospectively to empty report state at its existing simulation cursor;
6. load a current schema-v4 save without rewriting it;
7. reject malformed runtime and saved report state without exposing partial runtime or overwriting a valid save;
8. prove no report service or ingestion/read/snapshot behavior exists yet.

## Principal transition and owner

```text
validated GameState/report state
  -> exact schema-v4 primitive snapshot
  -> validated codec bytes
  -> exact runtime reconstruction
```

For historical input:

```text
frozen v3 primitive snapshot
  -> pure v3-to-v4 migration
  -> complete v4 validation
  -> atomic persisted upgrade
  -> runtime exposure
```

The primary new authoritative owner is one `ReportState` family inside `GameState`. Existing persistence components map and validate it but do not become report behavior owners.

## Required pre-edit report

Before non-trivial edits, report:

1. exact starting `main` SHA, feature branch, and tracked working-tree status;
2. current schema constants, current writer, historical validators, migration registry steps, fixtures, and coordinator sequence;
3. every current `GameState` field and every place `deep_clone()`/`copy_from()`/validation/mapping enumerates them;
4. proposed class/file layout and why it remains one report-state aggregate family;
5. exact runtime field/domain table for all seven report types;
6. exact schema-v4 key/type table at every nesting level;
7. runtime-to-wire-to-runtime propagation matrix for every authoritative report field;
8. `v3 -> v4` migration preservation matrix for every existing envelope/gameplay field;
9. malformed runtime and primitive mutation matrices;
10. content-reference validation matrix;
11. all existing tests whose “current schema” expectation must move from v3 to v4 without changing frozen historical fixtures;
12. proposed test, trace, and owner-runner files;
13. expected non-documentation file count and code/test line delta;
14. primary-owner, risk-dimension, and cross-layer-seam assessment;
15. confirmation that A3/A4/B, report service, ingestion, read models, snapshots, pruning, UI, clocks, and platform behavior are excluded.

Stop before editing if the exact maintained contract cannot be implemented inside the approved scope.

## Protected invariants

- Reports explain already-applied gameplay; they never grant, remove, delay, or claim rewards.
- `GameState` remains the authoritative aggregate root.
- M04E2T1 transaction provenance and M04E2T2 public typed facts remain unchanged.
- `SimulationEngine`, `SimulationTransaction`, and `SimulationResultProjector` do not depend on report state.
- Schema v1/v2/v3 validators and fixture bytes remain frozen historical inputs.
- Codec remains `JSON_V1`.
- Content revision remains `prototype-content-r2`.
- All authoritative integers use canonical decimal-string encoding.
- Migration fabricates no historical report, event, gain, or run.
- A valid report cursor may trail current gameplay simulation time until A3.
- No production service mutates report state in A2.
- All failures preserve exact live state and source files.
- No clock, scene, UI, Steam, or platform service enters the implementation.

## Proposed file responsibilities

Prefer focused global types under a clear report-state directory, for example:

```text
src/domain/reports/report_state.gd
src/domain/reports/report_accumulator_state.gd
src/domain/reports/report_record.gd
src/domain/reports/report_loadout_identity.gd
src/domain/reports/report_attribution_slice.gd
src/domain/reports/report_channel_summary.gd
src/domain/reports/report_event_record.gd
src/domain/reports/report_state_validator.gd
```

Exact paths may change after inspection. Do not place all types and validation inside `game_state.gd`, `save_schema_validator.gd`, or one monolithic report script.

Every non-trivial type begins with junior-readable `##` documentation covering ownership, units, mutability, detachment, validation, persistence, and exclusions.

## Runtime contracts

### `ReportState`

```text
ingested_through_simulation_msec: int
next_report_sequence: int
next_event_sequence: int
dropped_history_count: int
live: ReportAccumulatorState
history: Array[ReportRecord]
```

Required behavior:

- provide a canonical empty-at-cursor constructor/factory;
- report cursor is non-negative and no greater than owning gameplay cursor;
- next sequences are positive;
- counters are non-negative checked signed-64-bit values;
- history sequences strictly increase and are unique;
- history length is at most `REPORT_HISTORY_LIMIT = 20`;
- live end equals report cursor;
- deep clone/copy/map/load produces no shared child reference.

Do not require report cursor to equal gameplay cursor for every valid state. A2 introduces no ingestion, so an ordinary simulation call may advance gameplay while report state remains behind.

### `ReportAccumulatorState`

```text
window_started_simulation_msec: int
window_ended_simulation_msec: int
ingested_run_count: int
committed_mode_counts: Dictionary[StringName, int]
attribution_slices: Dictionary[String, ReportAttributionSlice]
event_type_counts: Dictionary[StringName, int]
recent_events: Array[ReportEventRecord]
omitted_event_count: int
```

Required behavior:

- ordered non-negative endpoints;
- end equals owning report cursor;
- empty state means start=end=cursor, zero runs, empty maps/arrays, zero omitted;
- mode keys are approved committed M04E1 modes only;
- mode counts are non-negative and checked-sum exactly to run count;
- slice map key exactly matches the canonical nested identity;
- the same nested slice identity cannot appear under multiple keys;
- recent event sequences strictly increase and are unique;
- recent detail count is at most `REPORT_RECENT_EVENT_LIMIT = 64`;
- event type counts include compacted detail and cannot be less than retained detail counts;
- each event time is start-exclusive/end-inclusive within the window.

A2 validates populated fixtures but does not add code that appends, compacts, or clears this state.

### `ReportRecord`

```text
report_sequence: int
snapshot_reason: StringName
snapshot_simulation_msec: int
window: ReportAccumulatorState
```

Allowed reasons are `MANUAL_REVIEW`, `OFFLINE_RETURN`, and `SYSTEM_BOUNDARY`.

The record exposes detached/read-only data after construction. Sequence is positive. Snapshot time equals window end and does not exceed the owning report cursor. A2 does not create records through a production snapshot command.

### `ReportLoadoutIdentity`

```text
form_id: StringName
writ_id: StringName
ordered_retinue_ids: Array[StringName]
```

Require valid component IDs, detached Retinue arrays, unique Retinue IDs, and preserved selected order. Do not sort historical selected order. Display names, rates, ETAs, and output values are not identity.

### `ReportAttributionSlice`

```text
threshold_id: StringName
assignment_revision: int
lifecycle_state: StringName
loadout_identity: ReportLoadoutIdentity
window_started_simulation_msec: int
window_ended_simulation_msec: int
elapsed_msec: int
returned_souls_delta: int
backlog_reduced: int
completed_cycles_delta: int
inventory_gains_by_item_id: Dictionary[StringName, int]
mastery_gains_subunits_by_form_id: Dictionary[StringName, int]
channel_summaries_by_channel_id: Dictionary[StringName, ReportChannelSummary]
```

Require:

- canonical unique key `(threshold_id, assignment_revision, lifecycle_state)`;
- positive assignment revision;
- lifecycle `OVERDUE` or `SETTLED`;
- non-negative ordered endpoints and exact checked elapsed difference;
- non-negative checked quantities;
- valid canonical item/Form/channel map keys;
- no duplicate semantic key under another string key;
- overall totals are not persisted independently.

### `ReportChannelSummary`

```text
threshold_id: StringName
channel_id: StringName
output_item_id: StringName
elapsed_msec: int
banked_units_delta: int
progress_subunits_start: int
progress_subunits_end: int
rate_carry_units_start: int
rate_carry_units_end: int
total_banked_units_start: int
total_banked_units_end: int
```

Require:

- the exact enabled Threshold/channel/output relationship in `ContentRegistry`;
- non-negative elapsed and banked delta;
- progress endpoints in `[0, FixedPoint.SCALE)`;
- carry endpoints in `[0, channel.period_msec)` using current content;
- non-negative monotonic total endpoints;
- checked `total_end - total_start == banked_units_delta`;
- nested `threshold_id` and `channel_id` agree with owning slice/map key;
- no fractional inventory meaning.

### `ReportEventRecord`

```text
event_sequence: int
event_type: StringName
occurred_simulation_msec: int
priority: int
subject_id: StringName
source_id: StringName
```

Require positive strictly increasing sequence, valid non-negative simulation time, approved current reportable event type, canonical priority/domain values, non-empty subject/source identity, and window membership. Persist no raw event payload dictionary or typed runtime event object.

## GameState integration

Add `report_state: ReportState` to `GameState`.

- `GameState.new(cursor)` creates canonical empty report state at `cursor`.
- `deep_clone()` deep-copies every report child.
- `copy_from()` replaces report state with a deep copy.
- `GameStateValidator` delegates report validation with the owning gameplay cursor and content registry.
- Existing simulation mutation code does not write report state.
- A report cursor behind gameplay cursor remains valid.
- Invalid/missing/wrong-class report state returns a typed validation failure rather than dereferencing or silently replacing it.

Do not add a second gameplay/report aggregate or a report singleton.

## Schema-v4 contract

### Constants

Add:

```text
SCHEMA_VERSION_V4 = 4
CURRENT_SCHEMA_VERSION = SCHEMA_VERSION_V4
GAME_KEYS_V4 = GAME_KEYS_V3 + ["report_state"]
```

Keep explicit frozen version constants and key sets for v1/v2/v3. Update stale comments that describe v2 or v3 as current.

### Exact primitive mapping

Every object has an exact allowlist of keys. Unknown and missing keys reject. Every authoritative integer is a canonical decimal string. Runtime `StringName` values map to strings. Dictionaries use canonical string keys and arrays preserve semantic order.

The report wire tree is:

```text
report_state
  ingested_through_simulation_msec
  next_report_sequence
  next_event_sequence
  dropped_history_count
  live
    window_started_simulation_msec
    window_ended_simulation_msec
    ingested_run_count
    committed_mode_counts
    attribution_slices
    event_type_counts
    recent_events
    omitted_event_count
  history
    report_sequence
    snapshot_reason
    snapshot_simulation_msec
    window
```

Nested loadout, slice, channel, and event dictionaries use the exact runtime field names. Do not serialize derived totals, read models, display strings, rates, ETAs, `SimulationResult`, transaction context, journal facts, validators, or wrapper modes.

### Deterministic ordering

- mapper iterates map keys in canonical order;
- history and recent events retain validated sequence order;
- ordered Retinue IDs preserve selected order;
- snapshot JSON remains deterministic through the existing codec contract.

## Migration contract

Add one pure `v3 -> v4` step.

It must:

1. validate the complete frozen v3 input through the v3 validator;
2. deep-copy the primitive snapshot;
3. set schema version to 4;
4. add canonical empty report state;
5. set report cursor and live start/end to the source gameplay `simulation_time_msec`;
6. set next report and event sequences to 1;
7. set counters to zero and maps/arrays/history empty;
8. preserve codec ID, content revision, save revision, metadata, time authority, offline identity, and all existing gameplay fields exactly;
9. create no report record, attribution slice, event, gain, or historical interval;
10. avoid content- or wall-clock-derived reconstruction.

Prove sequential `v1 -> v2 -> v3 -> v4` operation. Persisting a historical upgrade increments save revision once for the complete transaction, not once per pure step.

A valid current-v4 save must load without rewrite, backup rotation, or revision increment.

## Runtime and schema validation

Prefer one focused `ReportStateValidator` or equivalent pure owner and delegate to it rather than growing unrelated validators into monoliths.

Validation returns stable path-rich diagnostics and never mutates input.

### Required runtime malformed matrix

Cover at minimum:

- null/wrong-class root and children;
- negative, maximum, and overflow-adjacent counters/times/sequences;
- report cursor beyond gameplay cursor;
- live end mismatch;
- empty-state contradiction;
- mode key/count/sum errors;
- slice map-key mismatch and duplicate semantic identity;
- invalid Threshold/Form/Writ/Retinue/lifecycle/item/channel references;
- duplicate Retinues without reordering valid selected order;
- invalid slice endpoints/elapsed/quantities;
- channel period/progress/carry/total/delta contradictions;
- event sequence/order/type/priority/window errors;
- history order/duplicate/limit errors;
- snapshot reason/time/window contradictions;
- aliases between live/history/records/slices/channels/events.

### Required primitive mutation matrix

Starting with one valid populated v4 snapshot, mutate one field/path at a time:

- missing key;
- extra key;
- wrong primitive type;
- JSON number instead of canonical integer string;
- whitespace, plus sign, exponent, decimal, leading-zero, non-digit, and int64 overflow strings;
- unknown/empty IDs and enum values;
- map key/nested identity mismatch;
- duplicate semantic identity;
- unsorted/duplicate sequences;
- each cross-field contradiction above.

Each failure must preserve the original valid save candidates and expose no partial runtime.

## Fixture and propagation requirements

### Frozen historical fixtures

Do not modify bytes of existing v1, v2, or v3 fixtures. Test their hashes or exact bytes where the repository pattern supports it.

### New v4 fixtures

Add:

1. canonical empty v4 fixture at a nonzero simulation cursor;
2. representative populated v4 fixture containing:
   - at least one live slice;
   - distinct Form/Writ/ordered-Retinue identity;
   - inventory and Mastery maps;
   - one channel summary;
   - event counts and recent detail;
   - at least one immutable history record with a different sequence/window.

Fixture data is validation evidence only. No production report mutator is introduced.

### Field-propagation matrix

For every field prove:

```text
construct
-> validate
-> deep clone
-> GameState copy_from
-> map to primitives
-> schema validate
-> JSON encode/decode
-> map to runtime
-> canonical value equality
```

Do not use generic reflection serialization or JSON round-trip cloning for runtime objects.

## Persistence behavior

Use the existing coordinator and atomic storage behavior.

Prove:

- new ordinary save writes schema v4 and `prototype-content-r2`;
- v3 load migrates and persists v4 before runtime exposure;
- write/validation/rename failure preserves the prior valid source and exposes no upgraded runtime;
- primary/backup selection still chooses the highest valid revision;
- unsupported future schema/content/codec does not overwrite valid data;
- current v4 does not rewrite;
- report mapping round-trips through real file storage in an isolated root;
- no test touches the owner's normal `user://` save.

## Required behavior inventory

| ID | Requirement |
|---|---|
| RS-01 | One report-state aggregate family is the only new authoritative owner. |
| RS-02 | `GameState` owns one non-null report state. |
| RS-03 | New state creates canonical empty report state at its initial cursor. |
| RS-04 | Report cursor may trail but never exceed gameplay cursor. |
| RS-05 | Deep clone and copy have no mutable aliases. |
| RS-06 | All report counters and quantities use checked signed-64-bit domains. |
| RS-07 | History limit is 20 and recent event detail limit is 64. |
| RS-08 | Report and event next sequences are positive. |
| RS-09 | History/report-event sequences are strict and unique. |
| RS-10 | Empty live state has exact canonical shape. |
| RS-11 | Committed mode counts are canonical and sum to run count. |
| RS-12 | Slice storage keys exactly match nested identity. |
| RS-13 | Equal-output component loadouts remain distinct. |
| RS-14 | Ordered Retinue identity is preserved, unique, and detached. |
| RS-15 | Overdue and Settled slice identities remain distinct. |
| RS-16 | Generic inventory and Mastery maps validate without current-output whitelists beyond content identity. |
| RS-17 | Channel relationships and endpoint domains validate from content. |
| RS-18 | Event records persist bounded common detail only, never raw payloads. |
| RS-19 | Report records are detached and immutable after construction. |
| RS-20 | Schema v4 adds exactly report state to v3 game-state fields. |
| RS-21 | Current writer becomes v4 while codec/content remain unchanged. |
| RS-22 | All authoritative report integers use canonical decimal strings. |
| RS-23 | Mapping is explicit, deterministic, and reflection-free. |
| RS-24 | Frozen v1/v2/v3 validators and fixtures remain unchanged. |
| RS-25 | Pure v3-to-v4 migration initializes empty state at source cursor. |
| RS-26 | Migration creates no retroactive history, event, gain, or run. |
| RS-27 | Sequential v1-to-v4 migration preserves all historical gameplay/envelope data. |
| RS-28 | Persisted upgrade increments save revision once. |
| RS-29 | Current valid v4 loads without rewrite or rotation. |
| RS-30 | Populated v4 state round-trips exactly through JSON and real storage. |
| RS-31 | Runtime malformed matrix rejects without mutation. |
| RS-32 | Primitive malformed matrix rejects without runtime exposure or overwrite. |
| RS-33 | Content-reference contradictions reject. |
| RS-34 | Every authoritative field has end-to-end propagation proof. |
| RS-35 | Simulation, result, context, transaction, journal, and projector artifacts remain non-persisted. |
| RS-36 | No report service or production mutation method exists. |
| RS-37 | No ingestion, peeks, snapshotting, pruning, or offline classification exists. |
| RS-38 | No UI, trusted time, Hall, support, tutorial, progression, analytics, or concurrency work enters the diff. |
| RS-39 | No production code from PR #17/#18 is copied or cherry-picked wholesale. |
| RS-40 | Full/focused/import/trace/negative-root/cleanup/artifact checks pass. |
| RS-41 | Targeted and unrestricted reviews are clean. |
| RS-42 | Exact-head Windows owner verification passes before merge. |
| RS-43 | Codex updates one PR and stops without merging. |

## Required tests

Add `tests/unit/m04e2a2/` and `tests/integration/m04e2a2/`. Reuse existing fixture helpers where appropriate, but do not hide report validation behind broad source-string checks.

### Runtime construction and cloning

- canonical empty state at zero and nonzero cursors;
- populated family validation;
- deep clone of every nested map/array/object;
- `GameState.copy_from()` report replacement isolation;
- valid cursor lag after simulation advancement;
- null/wrong-class report state rejection;
- mutable accumulator versus immutable record behavior.

### Field-domain and content validation

- sequence/counter/time lower and upper boundaries;
- history/event limits;
- mode count keys and checked sum;
- slice key/identity and A-to-B-to-A distinction;
- selected Retinue order and duplicate rejection;
- item/Form/Threshold/Writ/Retinue/channel references;
- lifecycle and window rules;
- channel progress/carry/total/delta domains;
- event ordering/type/priority/window rules;
- record snapshot reason/time/window rules.

### Schema and primitive validation

- exact v4 keys at every level;
- missing/extra/wrong-type keys;
- canonical integer-string matrix;
- deterministic map ordering;
- populated v4 mapper parity;
- runtime-to-wire-to-runtime field propagation;
- no runtime-only simulation/result artifacts.

### Migration and persistence

- pure v3-to-v4 deep-copy preservation;
- nonzero source cursor initializes empty report state at that cursor;
- no retroactive history/events/gains;
- sequential v1-to-v4;
- frozen v1/v2/v3 fixture bytes unchanged;
- new v4 empty and populated fixtures;
- persisted v3 upgrade increments revision once;
- current v4 no rewrite;
- failure injection preserves valid source and exposes no partial runtime;
- real-file primary/backup round trip in isolated storage;
- future schema/content/codec rejection.

### Scope/source audits

- no `ReportService`, ingestion, read, snapshot, clear, prune, or offline-classification production entry point;
- no clock, scene, platform, Steam, or UI ownership;
- no simulation/result contract changes;
- no wholesale PR #17/#18 implementation reuse.

Source audits supplement but do not replace behavior.

## Developer trace

Create:

```text
tools/test/m04e2a2/m04e2a2_report_schema_trace.gd
```

It requires an existing isolated `--work-root`, uses real mapper/codec/storage/migration paths, performs assertions, removes temporary artifacts, and emits exactly:

```text
TRACE M04E2A2 empty_report_state_at_cursor=PASS
TRACE M04E2A2 populated_report_state_contract=PASS
TRACE M04E2A2 deep_clone_copy_isolation=PASS
TRACE M04E2A2 schema_v4_exact_keys=PASS
TRACE M04E2A2 canonical_int64_wire=PASS
TRACE M04E2A2 v3_to_v4_prospective_cursor=PASS
TRACE M04E2A2 sequential_v1_v2_v3_v4=PASS
TRACE M04E2A2 frozen_v1_v2_v3_unchanged=PASS
TRACE M04E2A2 populated_v4_round_trip=PASS
TRACE M04E2A2 current_v4_no_rewrite=PASS
TRACE M04E2A2 malformed_report_matrix_rejected=PASS
TRACE M04E2A2 content_relationship_validation=PASS
TRACE M04E2A2 upgrade_failure_preserves_source=PASS
TRACE M04E2A2 no_report_ingestion_or_reads=PASS
TRACE M04E2A2 schema_v4_content_r2=PASS
```

No marker may be emitted unconditionally or from marker-text search alone. The trace must fail with a nonzero exit when `--work-root` is absent or invalid.

## Owner verification package

Create:

```text
tools/test/owner/run_m04e2a2_owner_verification.ps1
```

Follow the mature exact-head Windows pattern. When `-CommitSha` is supplied, Git detection and exact equality are mandatory.

Required order:

```text
environment + requested SHA + detected exact Git head
full GUT before
focused persistence/M04A/M04D1/M04E2T1/M04E2T2/M04E2A2 suites
explicit import
real isolated M04E2A2 trace
exact 15-marker verification
missing-root trace must fail
cleanup in finally
cleanup absence proof
artifact audit
full GUT after
zero-failure summary
```

Run with execution-policy bypass. No interactive checklist is required. Do not run or claim the final owner package until targeted and unrestricted GitHub reviews are clean on the exact head.

## Verification before PR handoff

Run from repository root with the local Godot 4.7 console executable and canonical wrappers.

Focused suite:

```sh
./tools/test/run_gut.sh -- \
  -gdir=res://tests/unit/m04a \
  -gdir=res://tests/unit/m04d1 \
  -gdir=res://tests/unit/m04e2t1 \
  -gdir=res://tests/unit/m04e2t2 \
  -gdir=res://tests/unit/m04e2a2 \
  -gdir=res://tests/unit/persistence \
  -gdir=res://tests/integration/m04a \
  -gdir=res://tests/integration/m04d1 \
  -gdir=res://tests/integration/m04e2t1 \
  -gdir=res://tests/integration/m04e2t2 \
  -gdir=res://tests/integration/m04e2a2 \
  -gdir=res://tests/integration/save_load
```

Then:

```sh
./tools/test/run_gut.sh

godot --headless --path . --import

trace_root="$(mktemp -d)"
godot --headless --path . \
  -s res://tools/test/m04e2a2/m04e2a2_report_schema_trace.gd \
  -- --work-root "$trace_root"
trace_exit=$?
rm -rf "$trace_root"
test ! -e "$trace_root"
test "$trace_exit" -eq 0

godot --headless --path . \
  -s res://tools/test/m04e2a2/m04e2a2_report_schema_trace.gd
test "$?" -ne 0

git diff --check
git status --short
```

Also run affected historical schema/migration traces, particularly M02, M04A, M04D1, and any current persistence trace whose current-writer expectation changes. Report exact commands and markers.

The complete suite must be green before review.

## Review workflow

### Pre-review readiness pass

Before `@codex review`, produce:

- RS-01 through RS-43 requirement-to-evidence matrix;
- exact file/addition/deletion/net counts;
- runtime and wire field tables;
- propagation, migration-preservation, malformed, and content-reference matrices;
- focused/full/import/trace evidence;
- fixture-byte audit;
- confirmation that no report mutator/read/snapshot/pruning behavior exists;
- complete PR body.

### Targeted review

The first targeted GitHub review audits only material P1/P2 correctness in:

- report-state field completeness and deep isolation;
- cursor/window/sequence/counter invariants;
- exact v4 primitive grammar and canonical integer encoding;
- content-aware nested validation;
- frozen historical validators/fixtures;
- pure prospective v3-to-v4 migration;
- atomic upgrade/no-rewrite/failure preservation;
- absence of A3/A4/B and service mutation.

Apply bounded fixes in the same Codex desktop task and PR branch with named regressions. Repeat the same targeted review only when needed.

### Stop rule

Stop and return to planning when:

- more than two targeted rounds produce new P1/P2 findings;
- more than six material findings are discovered;
- more than 34 non-documentation source/test files or approximately 1,650 code/test lines are required;
- another authoritative aggregate or schema transition appears;
- a third cross-layer seam appears;
- report service mutation/read/snapshot behavior is required;
- frozen historical fixture bytes must change;
- the full suite is red at review request.

After a clean targeted audit, submit one unrestricted current-head review. Then run exact-head owner verification once.

## Documentation updates

Update only maintained documents made inaccurate by the realized implementation:

- `docs/codex/ARCHITECTURE.md`;
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`;
- `docs/codex/DECISIONS.md` current approval state only, unless a semantic change required a new owner-approved decision;
- `docs/codex/IMPLEMENTATION_RULES.md` only if a durable rule changes;
- `docs/codex/MILESTONES.md` status/evidence;
- `docs/codex/TESTING_AND_VALIDATION.md`;
- `docs/codex/M04E2A2_PLANNING.md`;
- this prompt's completion status after merge.

Keep while the PR is open:

```text
Implementation: Pull request open
Verification: Partial
```

Do not draft or implement M04E2A3 in this task.

## Acceptance criteria

M04E2A2 is complete only when:

1. all seven report runtime types and one focused validator family exist;
2. `GameState` owns canonical non-null report state;
3. new state initializes empty report state at its cursor;
4. report cursor lag is valid and cursor overflow/ordering is checked;
5. every child is deep-cloned/copied with no aliases;
6. populated fixture state satisfies all field/content/cross-field invariants;
7. records are detached and immutable after construction;
8. history/event bounds and sequence rules are exact;
9. loadout identity preserves selected ordered components;
10. slice/channel map keys and content relationships are exact;
11. schema v4 adds exactly the approved report tree;
12. current writer is v4 with JSON_V1 and content r2 unchanged;
13. every report integer uses canonical decimal strings;
14. explicit mapper parity covers every field;
15. v1/v2/v3 validators and fixture bytes remain frozen;
16. pure v3-to-v4 migration initializes empty state at source cursor;
17. migration fabricates no historical facts;
18. sequential v1-to-v4 migration passes;
19. persisted upgrade increments revision once and exposes runtime only after success;
20. valid current v4 load causes no rewrite or rotation;
21. populated v4 state round-trips through mapper, codec, and real file storage;
22. runtime malformed matrix rejects without mutation;
23. primitive mutation matrix rejects without partial runtime or overwrite;
24. every report field has construction/clone/copy/map/load propagation proof;
25. simulation/result/transaction/journal artifacts remain non-persisted;
26. no report service, ingestion, reads, snapshot, pruning, or offline classification exists;
27. no later-system/UI/platform behavior enters the diff;
28. no PR #17/#18 production implementation is copied wholesale;
29. actual scope remains inside the approved boundary or has an explicit owner-approved revision;
30. focused/full/import/trace/negative-root/cleanup/artifact checks pass;
31. targeted and unrestricted GitHub reviews are clean;
32. exact-head Windows owner verification passes;
33. Codex publishes or updates one PR and stops without merging.

## PR description requirements

The PR body includes:

- authoritative owner and class layout;
- exact runtime and wire field tables;
- clone/copy and propagation matrix;
- migration preservation matrix;
- malformed runtime/primitive/content matrices;
- fixture inventory and byte-preservation result;
- exact changed files and scope counts;
- focused/full tests and assertion counts;
- import and trace results;
- real-file migration/no-rewrite/failure preservation;
- explicit A3/A4/B exclusions;
- PR #17/#18 reuse statement;
- deferred work;
- exact head SHA;
- owner verification marked Pending until actually run.

## Final response format

Report:

### Implementation completed

Report state family, GameState integration, schema v4, migration, and persistence boundary.

### Runtime and wire matrices

Every type/field/domain/key and canonical integer treatment.

### Migration and propagation

Preserved fields, empty prospective initialization, and field-by-field round trip.

### Files changed

Every file and purpose.

### Regression tests

Named tests for runtime, schema, migration, failure, content, isolation, and persistence.

### Verification

Every command, test/assertion count, markers, negative trace, cleanup, and status.

### Scope

Final non-documentation counts, owner/seams, and any approved exception.

### Abandoned-branch reuse statement

Whether PR #17/#18 were inspected and confirmation that no production implementation was copied/cherry-picked wholesale.

### Deferred work

M04E2A3, M04E2A4, M04E2B, and later systems.

### Pull request

PR number, URL, branch, exact head SHA, and confirmation that no merge/close/auto-merge action occurred.
