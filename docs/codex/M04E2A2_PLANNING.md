# M04E2A2 report-state and schema-v4 persistence planning

**Status:** Approved  
**Date:** 2026-07-23  
**Planning baseline:** `main` at `afd390e8338a198d76938eef5ddcf35718ec189c` after PR #22 merged  
**Prerequisite:** M04E2T2 Merged/Passed through PR #22  
**Authority:** Accepted `DEC-0043`, accepted `DEC-0044`, and the report semantics carried forward from superseded `DEC-0041`/`DEC-0042`  
**Prompt:** `docs/codex/milestone-prompts/M04E2A2-report-state-schema-v4-persistence.md` Approved v0.1

## Purpose

M04E2A2 introduces the authoritative, save-owned report state required by later report ingestion. It advances the production writer from schema version 3 to schema version 4, implements exact runtime and primitive contracts, and proves sequential migration and persistence without adding a report mutator or read API.

This is a state/schema/migration slice. It is not report ingestion, report presentation, snapshotting, history pruning, trusted offline orchestration, or atomic simulation/report coordination.

No new architecture decision is proposed. The exact report-state semantics are already approved and maintained in `DATA_AND_CONTENT_CONTRACTS.md`. Implementation must stop for a new decision if inspection shows that those semantics must change.

## Completed prerequisite

M04E2T2 merged through PR #22 from final head `00bd7d1ce27817b508eb0aac1663d1de48353237` at merge commit `afd390e8338a198d76938eef5ddcf35718ec189c`.

Final exact-head evidence passed:

```text
full suite before/after: 178/178 tests, 2,832 assertions
focused M04C-M04E2T2: 74/74 tests, 1,291 assertions
Godot import: PASS
15 exact M04E2T2 markers: PASS
missing-root negative trace: PASS
cleanup and artifact audit: PASS
failed steps: 0
interactive checks: none
```

The final targeted and unrestricted reviews were clean. The owner approved the M04E2T2 scope exception for that slice only.

## Baseline findings

Current merged `main` has:

- schema version 3 as the current writer;
- frozen version-1, version-2, and version-3 validation/migration fixtures;
- explicit canonical signed-64-bit decimal-string encoding;
- `GameState` with simulation, inventory, Form, Threshold, Reaping, and progression state but no report state;
- `GameState.deep_clone()` and `copy_from()` with explicit substate cloning;
- `SaveSchemaMapper`, `SaveSchemaValidator`, `SaveMigrationRegistry`, and `GameStatePersistenceCoordinator` as the existing persistence architecture;
- M04E2T2 detached typed run facts, which remain runtime-only and are not persisted;
- no `ReportService`, ingestion cursor mutation, report query, snapshot command, or history pruning behavior.

## Principal transition

```text
schema-v3 or new runtime gameplay state
  -> canonical typed ReportState at a simulation cursor
  -> exact schema-v4 primitive mapping
  -> pure v3-to-v4 migration
  -> validated atomic persistence and load
```

## Ownership

### Primary authoritative owner

One report-state aggregate family rooted at `ReportState` owns saved explanatory report facts. It remains part of `GameState` and never owns gameplay rewards, simulation formulas, or clocks.

### Existing persistence seam

The existing mapper, validator, migration registry, and persistence coordinator serialize and reconstruct the new aggregate. They remain persistence infrastructure rather than a second report authority.

### Explicit exclusions

M04E2A2 creates no public report mutation or query service. No service may ingest a `SimulationResult`, advance the report cursor, append an event, create a report record, snapshot live state, or prune history in production during this slice.

## Runtime family

Prefer focused global `RefCounted` classes in a clear report-state directory. Exact paths may be adjusted after inspection, but responsibilities remain separate and junior-readable.

```text
ReportState
ReportAccumulatorState
ReportRecord
ReportLoadoutIdentity
ReportAttributionSlice
ReportChannelSummary
ReportEventRecord
ReportStateValidator
```

`GameState` gains one authoritative `report_state: ReportState` field. New game/runtime construction creates canonical empty report state at the supplied simulation cursor. `deep_clone()` and `copy_from()` deep-copy the complete family.

## Exact runtime contracts

### ReportState

```text
ingested_through_simulation_msec: int
next_report_sequence: int
next_event_sequence: int
dropped_history_count: int
live: ReportAccumulatorState
history: Array[ReportRecord]
```

Rules:

- `0 <= ingested_through_simulation_msec <= GameState.simulation_time_msec`;
- positive next sequences;
- non-negative signed-64-bit counters;
- retained report sequences strictly increasing and unique;
- history length at most 20;
- live end equals the report cursor;
- no aliasing after clone, copy, mapping, or load.

A report cursor may legitimately trail gameplay simulation time until M04E2A3 ingests committed intervals. A2 must not require cursor equality with gameplay time except when constructing a canonical new/migrated empty state.

### ReportAccumulatorState

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

Rules:

- non-negative ordered window endpoints;
- end equals the owning report cursor;
- canonical empty state has start=end=cursor, zero runs, empty maps/arrays, and zero omitted count;
- mode counts use approved committed M04E1 mode tokens, are non-negative, and sum exactly to run count;
- slice storage key equals the canonical threshold/revision/lifecycle key;
- no duplicate slice identity under another key;
- event sequences strictly increase and recent detail length is at most 64;
- event-type counts retain compacted detail counts;
- every event satisfies `window_start < event_time <= window_end`.

### ReportRecord

```text
report_sequence: int
snapshot_reason: StringName
snapshot_simulation_msec: int
window: ReportAccumulatorState
```

Allowed reasons:

```text
MANUAL_REVIEW
OFFLINE_RETURN
SYSTEM_BOUNDARY
```

A record is detached and immutable after construction. Its sequence is positive, snapshot time equals the archived window end, and snapshot time does not exceed the owning report cursor.

### ReportLoadoutIdentity

```text
form_id: StringName
writ_id: StringName
ordered_retinue_ids: Array[StringName]
```

Identity is component-based. Display text, rates, ETAs, and output vectors are excluded. Ordered Retinue identity is detached, unique, and preserves selected order rather than lexicographic order.

### ReportAttributionSlice

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

The unique identity is `(threshold_id, assignment_revision, lifecycle_state)`. Quantities are non-negative, elapsed and endpoints agree through checked arithmetic, map keys are canonical, and content references are valid. Overall totals are not persisted separately.

### ReportChannelSummary

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

The Threshold/channel/output relationship must match content. Progress and carry endpoints are within their validated domains, totals are non-negative and monotonic, and banked delta equals total-end minus total-start through checked arithmetic.

### ReportEventRecord

```text
event_sequence: int
event_type: StringName
occurred_simulation_msec: int
priority: int
subject_id: StringName
source_id: StringName
```

Only the currently approved reportable typed simulation event kinds may appear in persisted fixture state. Raw event payload dictionaries never serialize. Sequence and time ordering are strict and deterministic.

## Schema version 4

### Envelope and game-state keys

Add explicit `SCHEMA_VERSION_V4 = 4`, make it the current writer, retain codec `JSON_V1`, and keep content revision `prototype-content-r2`.

The version-4 game-state key set is the version-3 set plus exactly:

```text
report_state
```

Frozen version-1, version-2, and version-3 validators and fixtures remain immutable historical inputs.

### Primitive wire shape

Every authoritative integer is a canonical decimal string. IDs and enum tokens are strings. Maps use canonical string keys. Arrays preserve explicit semantic order.

```text
game_state.report_state
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
```

Nested slice, loadout, channel, event, and record keys exactly mirror the runtime contracts above. No derived read model, display text, rate, ETA, simulation result, journal fact, projector, or arbitrary payload is serialized.

### Pure v3-to-v4 migration

The migration:

1. validates the complete frozen v3 source;
2. deep-copies primitive source data;
3. changes only the schema version and adds canonical empty report state;
4. sets report cursor and live start/end to the source simulation cursor;
5. initializes next report/event sequences to 1;
6. initializes zero counters, empty maps, and empty history;
7. creates no event detail and no retroactive report;
8. preserves every existing envelope and gameplay field exactly.

The production migration path becomes:

```text
v1 -> v2 -> v3 -> v4
```

The existing persistence coordinator persists the complete upgrade once, increments save revision once, and exposes runtime only after persistence succeeds. An already-current valid v4 save does not rewrite, rotate, or increment revision on load.

## Validation matrices

### Runtime field matrix

Test every scalar at valid lower/upper boundaries and invalid negative/overflow values. Test missing/null/wrong-class children, duplicate aliases, invalid enum/ID tokens, ordering, map-key identity, content relationships, and cross-field contradictions.

### Primitive mutation matrix

Starting from a valid populated v4 fixture, mutate one path at a time:

- missing and extra keys at every object level;
- wrong primitive type;
- JSON number where an integer string is required;
- non-canonical or overflow integer strings;
- unknown IDs or enum tokens;
- unsorted/duplicate sequence arrays;
- mismatched map key and nested identity;
- duplicate slice identity under another key;
- invalid cursor/window/history relations;
- mode-count sum mismatch;
- event count/detail contradictions;
- channel relationship/endpoints/delta mismatch;
- report/history/event retention overflow;
- record snapshot/sequence contradictions.

Every rejection must identify the failing path or stable category and must not partially expose runtime or overwrite valid source files.

### Propagation matrix

Every authoritative report field must be proven through:

```text
runtime construction
-> deep clone
-> GameState copy_from
-> runtime validator
-> runtime_to_snapshot
-> schema validator
-> JSON encode/decode
-> snapshot_to_runtime
-> canonical equality
```

A fixture-populated state is required even though no production service mutates report state yet.

## Test and evidence plan

Add bounded tests and evidence under:

```text
tests/unit/m04e2a2/
tests/integration/m04e2a2/
tools/test/m04e2a2/m04e2a2_report_schema_trace.gd
tools/test/owner/run_m04e2a2_owner_verification.ps1
```

The trace requires an existing isolated `--work-root`, performs real file migration/round-trip checks, emits the exact markers in `TESTING_AND_VALIDATION.md`, and fails without the root.

No visual, editor, audio, gameplay, A/B, or Steam checklist is required.

## Scope assessment

| Item | Draft assessment |
|---|---|
| Primary owner | One report-state aggregate/validator family |
| Principal transition | Runtime report state -> schema-v4 mapped/migrated persistence |
| New authoritative aggregate | One `ReportState` family inside `GameState` |
| Save transition | One: v3 -> v4 |
| Cross-layer seams | 2: GameState/validator; report state/persistence architecture |
| Risk dimensions | State/alias validation; wire/migration compatibility; atomic upgrade persistence |
| Expected non-documentation files | Approximately 18–30, excluding `.uid` |
| Expected code/test delta | Approximately 900–1,400 lines, excluding `.uid` |
| Mandatory stop | Before 34 files or approximately 1,650 lines, a third seam, another authoritative owner, or service mutation |
| Platform/native behavior | None |
| Interactive checks | None |

The threshold is deliberately above the ordinary target because seven explicit state types, exact mapping, malformed matrices, a real-file trace, and a Windows runner are required. It is still a stop boundary, not an allowance to add A3/A4 behavior.

## Stop conditions

Stop and return to planning before broadening when:

- the approved report fields or semantics must change;
- a content revision or codec change is required;
- a report mutator/query/snapshot/retention service is required;
- simulation or typed-result behavior must change;
- more than one new authoritative aggregate family appears;
- a third cross-layer seam appears;
- projected or actual scope crosses the stated stop threshold;
- frozen v1/v2/v3 fixtures would need modification;
- the full suite is red at review request.

During review, stop when more than two targeted rounds produce new P1/P2 findings or more than six material findings are discovered.

## Codex desktop delivery

```text
base: main
feature branch: codex/implement-m04e2a2
PR target: main
PR title: M04E2A2: Add report state and schema-v4 persistence
```

Codex uses `tools/codex/publish_milestone_pr.ps1`, updates one PR, reports its URL and exact head, and stops without merging. Only the owner may merge or close.

## Approval checklist

Implementation remains blocked until the owner confirms:

```text
M04E2T2: Merged/Passed
M04E2A2 definition: Approved
M04E2A2 prompt: Approved v0.1 or later
GATE-REPORT-SCHEMA: Satisfied
GATE-SLICE-SCOPE: Satisfied
Codex desktop workflow: Approved
```
