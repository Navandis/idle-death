# Implementation slice M04E2A1: Typed committed simulation-result contract

**Prompt version:** v0.1  
**Prompt date:** 2026-07-20  
**Prompt status:** Approved  
**Work item type:** Implementation slice  
**Parent conceptual epics:** `M04 — Persistent Reaping simulation vertical slice` / M04E / M04E2 / M04E2A replacement sequence  
**Milestone definition:** `docs/codex/MILESTONES.md`  
**Expected base branch or ref:** current `main` after the planning-only `DEC-0042` reset package is merged  
**Gameplay baseline:** M04E1 merge commit `03f05a3d78609a993cecab8b0077e5f7d7d55900`; pre-reset planning head `d37d4af5a82804593c23f913c0b01b3da63e6953`  
**Planned prompt path:** `docs/codex/milestone-prompts/M04E2A1-typed-committed-simulation-result-contract.md`

> This prompt authorizes a typed, self-contained, non-persisted committed simulation-result boundary. It replaces raw public segment/channel dictionaries with validated typed records, carries historical assignment/loadout/lifecycle/source identity on each segment, validates the complete result before live candidate commit, updates current simulation/run/debug/test consumers, and adds focused verification. It does not authorize report state, schema version 4, report ingestion, report queries, snapshot/history behavior, UI, trusted time, concurrency, or M04E2B.

## Approval record

The project owner approved this replacement package on 2026-07-20:

```text
DEC-0042: Accepted
PR #17 direct M04E2A attempt: Closed unmerged / Abandoned
M04E2A replacement decomposition: Approved
M04E2A1 definition: Approved
M04E2A1 prompt: Approved v0.1
M04E2A1 implementation: Not started
GATE-TYPED-SIMULATION-RESULT: Satisfied
GATE-SLICE-SCOPE: Satisfied
```

Start a **new Codex task, branch, and pull request** from current `main`.

Do not continue the old PR #17 Codex task or branch. Do not copy or cherry-pick its production implementation wholesale. PR #17 may be inspected only for accepted review findings, black-box expected behavior, and regression scenarios.

## Required reading and pre-edit report

Before editing:

1. Read `AGENTS.md` completely and follow the source hierarchy.
2. Read:
   - accepted `DEC-0042` and the carried-forward report semantics from superseded `DEC-0041`;
   - `docs/codex/MILESTONES.md` M04E2A1 definition;
   - `docs/codex/ARCHITECTURE.md` typed-result boundary;
   - `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` M04E2A1 contract;
   - `docs/codex/IMPLEMENTATION_RULES.md`;
   - `docs/codex/TESTING_AND_VALIDATION.md` M04E2A1 package;
   - `docs/codex/OWNER_VERIFICATION_WORKFLOW.md`.
3. Read accepted `DEC-0010`, `DEC-0012`, `DEC-0033`, `DEC-0035`, `DEC-0036`, `DEC-0038`, `DEC-0039`, `DEC-0040`, and `DEC-0042`.
4. Inspect current `main`, `git status --short`, and the exact current implementations/tests of:
   - `SimulationEngine` and nested `SimulationResult`/`SimulationEvent`;
   - `SimulationRunService` and `SimulationRunResult`;
   - `M04CDebugAdvance`;
   - `ReapingAssignmentService` and assignment revision/loadout identity;
   - `ReapingRateContextService`;
   - M04C, M04D2, M04D3, and M04E1 unit/integration tests and traces;
   - current persistence exclusion tests and owner-runner pattern.
5. Inspect PR #17 only if needed to enumerate previously discovered regression scenarios. Do not use it as an implementation template.

Before non-trivial edits, report:

- proposed exact script/class locations for `SimulationSegmentResult` and `SimulationChannelDeltaResult`;
- whether they are global classes or documented nested classes and why;
- a field-domain table for every result field;
- a consumer-input matrix showing which current consumer needs each field;
- the complete run-level result-validation table;
- event ordering and interval-membership rules;
- result-validation and candidate-commit ordering;
- every current raw segment/channel consumer that will change;
- expected files and current/projected non-documentation line count;
- focused test grouping, trace plan, and owner-runner plan;
- explicit confirmation that report state, schema v4, ingestion, peeks, snapshots/history, PR #17 production code, and M04E2B are excluded.

Stop before editing if the required typed result cannot be introduced without changing production arithmetic, save meaning, another authoritative aggregate, or more than the approved cross-layer seams.

## Protected invariants

- `SimulationEngine` remains the only owner of production formulas and authoritative elapsed mutation.
- Online, offline-fixture, debug, and forecast paths continue to use the same engine.
- Existing one-hour, eight-hour, Settlement, channel banking, chunking, and forecast-equivalence outcomes remain exact.
- Historical identity is captured when production occurs and is not reconstructed later from mutable state.
- Loadout identity is component-based, not output-based.
- Different equal-output loadouts remain distinct.
- Result records are detached evidence, not save authority.
- Schema remains version 3; content remains `prototype-content-r2`.
- No report state or `ReportService` is introduced.
- No clock, scene, platform, file, tutorial, Hall, support, analytics, or concurrency ownership enters simulation results.
- Every failure preserves source `GameState` exactly.

## Objective

Replace the current implicit public grammar of raw `Dictionary` segments and channel deltas with typed, self-contained committed-result records that can safely support later report ingestion.

A successful positive active-Reaping result must describe exactly what happened, under which historical assignment/loadout/lifecycle, over which contiguous interval, with which core and channel endpoints. The complete result contract must be validated before the candidate state replaces live state.

## Developer outcome

After this slice, a developer can:

1. run one-hour and eight-hour committed/forecast fixtures and inspect typed segments/channel deltas;
2. cross Settlement and see distinct typed Overdue/Settled segments plus correctly owned events;
3. commit a run, recall or redispatch at the same simulation timestamp, and prove the earlier result retains its original assignment/loadout identity;
4. pass typed results through forecast, committed-mode, debug, trace, and test consumers without conversion back to raw segment/channel dictionaries;
5. reject malformed result construction before live mutation;
6. save/load ordinary gameplay under schema v3 and prove result objects never serialize.

## Baseline

| Area | Required baseline |
|---|---|
| Completed slices | M04A through M04E1 Merged/Passed |
| Save | Schema v3 current; sequential v1 -> v2 -> v3; `JSON_V1` |
| Content | `prototype-content-r2` |
| Simulation | Transactional one-active-Reaping resolver with exact Settlement segmentation |
| Result shape | Typed `SimulationResult` envelope, typed events, raw segment/channel dictionaries |
| Run adapter | Typed `SimulationRunResult` with baseline/result cursors and forecast projection |
| Reports | None on `main` |
| Working tree | Clean except this task's changes |

## Scope assessment

| Assessment item | Approved estimate |
|---|---|
| Primary subsystem owner | `SimulationEngine` result contract |
| Principal transition | Resolved candidate facts -> validated typed result -> one live commit |
| New authoritative aggregate | None |
| Save-schema change | None |
| Cross-layer seams | 2: engine result -> run adapter/debug; typed result -> future consumers/tests |
| Risk dimensions | Representation compatibility, historical attribution, validation/transaction, event boundaries |
| Expected non-documentation source/test files | Approximately 10–22 |
| Expected non-documentation code/test delta | Approximately 700–1,200 lines |
| Platform/native work | None |
| Interactive owner checks | None |

Stop for a revised prompt before exceeding 24 non-documentation source/test files or approximately 1,300 non-documentation code/test lines, or before adding another primary owner, another authoritative aggregate, or a third cross-layer seam.

## Required behavior

### RB-01 — Typed records

Add typed non-persisted records equivalent to:

```text
SimulationSegmentResult
SimulationChannelDeltaResult
```

Use static typing for public fields and methods. Each type begins with junior-readable `##` documentation covering responsibility, ownership exclusions, units, mutability, and determinism.

The types must provide explicit deep-clone or detached-copy behavior where current consumers can retain them after a run. Do not use reflection, JSON cloning, Resources, or Nodes.

### RB-02 — Segment field contract

Each positive active-Reaping segment contains:

```text
threshold_id: StringName
assignment_revision: int
form_id: StringName
writ_id: StringName
ordered_retinue_ids: Array[StringName]
lifecycle_state: StringName
start_simulation_msec: int
end_simulation_msec: int
elapsed_msec: int
returned_souls_delta: int
backlog_reduced: int
essence_delta: int
mastery_delta_subunits: int
completed_cycles_delta: int
channel_deltas: Array[SimulationChannelDeltaResult]
```

Rules:

- all IDs are non-empty;
- `assignment_revision > 0`;
- Retinue IDs preserve canonical selected order and contain no duplicates;
- lifecycle is `OVERDUE` or `SETTLED`;
- `0 <= start < end`;
- `elapsed == end - start`;
- every gain/count is non-negative and within signed 64-bit range;
- `backlog_reduced = backlog_before - backlog_after`, never an ambiguous negative value;
- channel deltas are unique and canonically ordered by channel ID;
- no nested array or child record aliases mutable storage from another result or live state.

### RB-03 — Channel-delta field contract

Each typed channel delta contains:

```text
channel_id: StringName
output_item_id: StringName
banked_units_delta: int
progress_subunits_before: int
progress_subunits_after: int
rate_carry_units_before: int
rate_carry_units_after: int
total_banked_units_before: int
total_banked_units_after: int
```

Rules:

- IDs are non-empty;
- all numeric values are non-negative;
- progress endpoints satisfy `0 <= value < FixedPoint.SCALE`;
- carry endpoints satisfy `0 <= value < the validated channel period`;
- `total_after >= total_before`;
- `banked_units_delta == total_after - total_before`;
- progress-only changes with zero whole banking remain representable;
- no fractional inventory is created or implied.

The validator may receive `ContentRegistry` or a validated period map where needed to prove carry bounds. Do not duplicate channel-rate formulas.

### RB-04 — Self-contained historical identity

When the engine creates a segment, capture the exact current:

```text
Threshold ID
assignment revision
Form ID
Writ ID
ordered Retinue IDs
lifecycle state
```

These are immutable facts of the result.

After a successful run, changing the live Reaping at the same simulation cursor must not change the retained segment's identity.

Do not require a delayed consumer to read current `GameState.reapings` to explain the run.

### RB-05 — Typed arrays only

`SimulationResult.segments` becomes a typed array of `SimulationSegmentResult` where Godot supports that form. `SimulationSegmentResult.channel_deltas` becomes a typed array of `SimulationChannelDeltaResult`.

Do not preserve a parallel raw-dictionary segment or channel-delta public contract. Update all current production/test/trace consumers directly.

`change_summary` may remain a diagnostic primitive dictionary for compatibility, but it cannot be the only owner of historical attribution or channel endpoint facts.

### RB-06 — Run-level validator

Add one pure validator for a complete `SimulationResult` in the context of:

```text
baseline_simulation_time_msec
result_simulation_time_msec
requested_elapsed_msec
committed mode or forecast mode where relevant
validated content registry
```

For a successful positive active-Reaping result, validate:

1. segments are non-empty;
2. every segment and child delta passes local validation;
3. first segment start equals baseline;
4. final segment end equals result cursor;
5. segments are ordered and contiguous;
6. sum of segment elapsed equals committed elapsed;
7. committed elapsed equals requested elapsed;
8. Threshold ID, assignment revision, Form ID, Writ ID, and ordered Retinue IDs are stable across the current one-Reaping run;
9. lifecycle may differ only through exact Overdue/Settled segmentation;
10. events are typed, well formed, and stably ordered;
11. each reportable segment-owned event matches exactly one segment under the approved boundary rule;
12. diagnostic summary values are consistent with the typed records where current fields overlap.

Use checked arithmetic for elapsed and aggregate comparisons.

### RB-07 — Timeline-only positive result

A successful positive run with no active Reaping:

```text
committed elapsed == requested elapsed
segments empty
events empty
change_summary contains only the exact simulation-time delta
```

A positive active-Reaping run may not have zero segments.

### RB-08 — Zero and failure result shapes

Zero-duration success:

```text
requested elapsed = 0
committed elapsed = 0
no segments
no events
no gameplay mutation
```

Failed result:

- does not represent committed segment/event authority;
- exposes a stable error code and diagnostic;
- causes no live mutation;
- forecast failure returns no projection.

### RB-09 — Event ownership

Keep `SimulationEvent` as a typed fixed envelope. Validate non-negative time and priority plus non-empty type/subject/source IDs for reportable events.

Stable ordering remains:

```text
occurred_simulation_msec
priority
subject_id
source_id
```

A segment owns an event when:

```text
segment.start_simulation_msec < event.occurred_simulation_msec
    <= segment.end_simulation_msec
```

A reportable event in a segmented active run must match exactly one segment. An event at the end of assignment/lifecycle interval A must not also belong to interval B beginning at the same cursor.

Do not persist arbitrary event payloads or expand the event grammar in this slice.

### RB-10 — Validation before live commit

The production order is:

```text
validate request and source state
-> clone GameState
-> resolve candidate and build typed result
-> validate complete typed result
-> validate complete candidate GameState
-> copy candidate to live once
-> return result
```

A malformed result is a simulation transaction failure. Do not copy live state first and rely on downstream tests or reports to catch it.

Every failure path must preserve canonical source state, including simulation cursor, inventory, Forms, Thresholds, acquisition, Reapings, progression, and reservations.

### RB-11 — Existing behavior unchanged

Do not change formulas or provisional values. Preserve exact verified outcomes, including:

```text
Gloamwood 1h:
  returned Souls = 4,140
  Essence = 360
  Mastery = 60,000,000 subunits
  completed cycles = 60
  Soldier Souls banked = 12
  Scribe progress = 125,000

Gloamwood 8h:
  returned Souls = 33,120
  Essence = 2,880
  Mastery = 480,000,000 subunits
  completed cycles = 480
  Soldier Souls banked = 96
  Scribe Form Souls banked = 1
```

Preserve channel eligibility, rate plans, Settlement rate ordering, event priority, carry, inventory, and source-history behavior.

### RB-12 — Current consumers

Update every current consumer to use typed records directly, including as applicable:

- `SimulationRunService`;
- `M04CDebugAdvance`;
- M04C/M04D2/M04D3/M04E1 tests;
- M04D2/M04E1 traces;
- source-ownership and persistence-exclusion checks.

Do not add a report consumer.

### RB-13 — Forecast and mode equivalence

Forecast and committed modes continue to return the exact typed engine records produced by the shared resolver.

Prove:

- forecast baseline remains unchanged;
- projection is detached;
- separately committed equivalent clone has equal gameplay state and typed result facts;
- foreground, offline-fixture, and debug committed modes have equal typed engine results;
- regular and irregular chunks preserve canonical gameplay outcomes and correctly aggregate to the one-shot typed result facts tested by existing contracts.

Do not add a forecast-specific result formula.

### RB-14 — Persistence exclusion

Keep:

```text
SaveEnvelope.CURRENT_SCHEMA_VERSION = 3
content revision = prototype-content-r2
```

Production snapshots and saved bytes must not contain:

```text
SimulationRunResult
SimulationResult
SimulationSegmentResult
SimulationChannelDeltaResult
SimulationEvent
validation results
change-summary objects as authority
forecast projections
report fields
```

Do not modify migrations or frozen v1/v2/v3 fixture bytes except when an existing test's source-level expectation must be updated solely for a non-persisted type name. Report any such need before changing fixture bytes; the expected answer is no fixture-byte change.

### RB-15 — No PR #17 implementation reuse

Do not cherry-pick or wholesale copy production source from PR #17.

You may reuse:

- accepted black-box expected values;
- defect categories;
- test scenario descriptions;
- field-domain and boundary lessons.

The final response must state whether any PR #17 file was consulted and confirm that no production commit was cherry-picked.

### RB-16 — No later-slice ownership

Do not add:

- `ReportState` or `GameState.report_state`;
- schema version 4;
- `ReportService`;
- report cursor, ingestion, peeks, snapshot, history, or retention;
- `SimulationReportCoordinator`;
- report UI, claim flow, trusted time, tutorial, progression, Halls, support, service outcomes, concurrent Reapings, or Codex analytics.

## Required tests

Add `tests/unit/m04e2a1/` and `tests/integration/m04e2a1/` as needed. Keep useful existing tests and update them to the typed contract.

At minimum add named behavior tests for:

### Typed local records

- valid segment and channel record construction;
- deep detachment of Retinue arrays and channel records;
- empty/wrong identity rejection;
- zero assignment revision rejection;
- invalid lifecycle rejection;
- negative gain/count rejection;
- segment timing/elapsed mismatch rejection;
- duplicate/unsorted Retinue rejection when applicable;
- duplicate/unsorted channel rejection;
- progress and carry lower/upper bounds;
- total-banked reversal;
- banked-delta/endpoints mismatch.

### Complete result shapes

- valid active segmented result;
- missing active segments;
- first-start mismatch;
- final-end mismatch;
- gap and overlap between segments;
- elapsed-sum mismatch;
- changed Threshold/revision/Form/Writ/Retinue identity inside one run;
- valid Overdue -> Settled lifecycle change;
- valid positive timeline-only result;
- malformed timeline-only summary;
- valid zero result;
- failed result without authority.

### Events

- stable event ordering;
- event at or before run/segment start rejection;
- event inside segment acceptance;
- event exactly at segment end acceptance;
- event after segment end rejection;
- exact assignment-boundary ownership;
- exact Settlement-boundary ownership;
- reportable event matching zero or two segments rejection;
- non-reportable diagnostic event behavior remains bounded and documented.

### Existing behavior and historical attribution

- exact one-hour fixture;
- exact eight-hour fixture;
- progress-only channel;
- multiple whole banking;
- Settlement segmentation and event order;
- same-timestamp recall retains original typed identity;
- same-timestamp redispatch retains original typed identity;
- distinct equal-output component identities remain distinct;
- source state unchanged on every malformed-result failure.

### Consumers and persistence

- `SimulationRunService` typed passthrough;
- forecast/commit equality;
- committed-mode equality;
- debug adapter typed delegation;
- one-shot/chunk canonical gameplay equivalence;
- current v3 production save/load unchanged;
- no result artifact in JSON or mapped snapshots;
- no report/later-slice source ownership.

Use hand-calculable fixtures and table-driven malformed matrices where practical. Do not satisfy behavior requirements only through source-string searches.

## Developer trace

Create:

```text
tools/test/m04e2a1/m04e2a1_typed_result_trace.gd
```

It must require and use an isolated work root, fail when the root is missing, perform real behavioral assertions, and emit exactly these markers only after their named behavior passes:

```text
TRACE M04E2A1 typed_segment_identity_and_timing=PASS
TRACE M04E2A1 typed_channel_endpoint_contract=PASS
TRACE M04E2A1 one_hour_values_unchanged=PASS
TRACE M04E2A1 eight_hour_values_unchanged=PASS
TRACE M04E2A1 settlement_segments_and_events=PASS
TRACE M04E2A1 timeline_only_positive_run=PASS
TRACE M04E2A1 zero_and_failure_shapes=PASS
TRACE M04E2A1 same_timestamp_recall_attribution=PASS
TRACE M04E2A1 same_timestamp_redispatch_attribution=PASS
TRACE M04E2A1 equal_output_component_identity_distinct=PASS
TRACE M04E2A1 malformed_result_rejects_before_commit=PASS
TRACE M04E2A1 forecast_commit_and_mode_equivalence=PASS
TRACE M04E2A1 schema_v3_no_result_artifacts=PASS
TRACE M04E2A1 no_report_or_later_slice_sources=PASS
```

No marker may be printed from unconditional `true`, marker-text search, or unexercised helper output.

## Owner verification package

Create:

```text
tools/test/owner/run_m04e2a1_owner_verification.ps1
```

Follow the final M04D3/M04E1 pattern and `OWNER_VERIFICATION_WORKFLOW.md`:

1. record UTC start, repository root, Windows/PowerShell/Godot details, requested SHA, Git availability, and resolved executable;
2. run the full GUT suite before;
3. run focused M04C, M04D2, M04E1, and M04E2A1 unit/integration directories;
4. run explicit import;
5. run the real trace against an isolated root;
6. verify all fourteen exact markers;
7. clean in `finally`;
8. prove the isolated root is absent;
9. audit tracked/generated artifacts and ignored owner logs;
10. run the full GUT suite after;
11. write one complete UTF-8 log named with UTC timestamp and requested head;
12. report `PASS` only when every required step passed.

Do not require Git CLI. Do not claim the Windows package passed unless the owner actually runs it.

No interactive checklist is required.

## Verification before PR handoff

Run from repository root:

```sh
./tools/test/run_gut.sh -- \
  -gdir=res://tests/unit/m04c \
  -gdir=res://tests/unit/m04d2 \
  -gdir=res://tests/unit/m04e1 \
  -gdir=res://tests/unit/m04e2a1 \
  -gdir=res://tests/integration/m04e1 \
  -gdir=res://tests/integration/m04e2a1

./tools/test/run_gut.sh

godot --headless --path . --import

trace_root="$(mktemp -d)"
godot --headless --path . \
  -s res://tools/test/m04e2a1/m04e2a1_typed_result_trace.gd \
  -- --work-root "$trace_root"
trace_exit=$?
rm -rf "$trace_root"
test ! -e "$trace_root"
test "$trace_exit" -eq 0

godot --headless --path . \
  -s res://tools/test/m04e2a1/m04e2a1_typed_result_trace.gd
test "$?" -ne 0

git diff --check
git status --short
```

The complete repository suite must be green. A focused pass with a red full suite is not review-ready.

## Documentation updates

Update only files made inaccurate by the realized contract:

- `docs/codex/ARCHITECTURE.md`;
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`;
- `docs/codex/IMPLEMENTATION_RULES.md` for durable typed-result/validation conventions actually realized;
- `docs/codex/TESTING_AND_VALIDATION.md`;
- `docs/codex/MILESTONES.md` status and completion evidence;
- historical M04C/M04D2/M04E1 documentation only where a current statement falsely says raw dictionaries remain the public result contract.

Keep status while PR is open:

```text
Implementation: Pull request open
Verification: Partial
```

Do not draft M04E2A2 or M04E2B in this task.

## Acceptance criteria

M04E2A1 is complete only when:

1. every public segment is a typed `SimulationSegmentResult`;
2. every public channel delta is a typed `SimulationChannelDeltaResult`;
3. segments contain complete historical Threshold/revision/Form/Writ/Retinue/lifecycle identity;
4. channel records contain complete exact endpoints;
5. raw segment/channel dictionaries are not retained as a parallel public contract;
6. the complete result validates before live candidate commit;
7. malformed result construction fails transactionally without source-state mutation;
8. positive active, positive timeline-only, zero, and failure shapes are distinct and tested;
9. event ordering and exact boundary ownership are tested;
10. same-timestamp recall/redispatch cannot rewrite earlier result identity;
11. equal-output component identities remain distinct;
12. exact one-hour/eight-hour/Settlement/channel outcomes remain unchanged;
13. forecast and committed modes use the same typed engine records;
14. debug and current test/trace consumers use typed records directly;
15. schema remains v3 and content remains r2;
16. no result artifact serializes;
17. no report state, report service, schema v4, ingestion, reads, snapshot/history, coordinator, UI, trusted-time, or concurrency work enters the diff;
18. no PR #17 production commit is cherry-picked;
19. focused tests pass;
20. the complete repository suite passes;
21. import and real trace pass;
22. negative missing-root trace fails;
23. cleanup and artifact checks pass in Codex/Linux where applicable;
24. actual scope remains within approved guardrails;
25. owner Windows verification passes against the exact final reviewed head before merge.

## Final response format

Report:

### Implementation completed

The exact typed result family, validation/commit ordering, historical attribution rule, and unchanged behaviors.

### Files changed

Every added, modified, renamed, or deleted file and its purpose.

### Contract matrices

The final field-domain table, consumer-input matrix, and run-shape/validation table.

### Regression tests added

Map each acceptance group to named tests.

### Verification

Every command actually run, exact test/assertion counts, trace markers, missing-root result, cleanup result, and exit status.

### PR #17 reuse statement

State whether the abandoned branch was inspected and confirm no production commit was cherry-picked or copied wholesale.

### Assumptions

Only interpretations not directly established by authoritative context.

### Known limitations and risks

Anything incomplete, environment-dependent, provisional, or not verified.

### Deferred work

Explicitly list M04E2A2 report state/schema v4, M04E2A3 ingestion, M04E2A4 reads/snapshot/history/evidence, M04E2B, UI, trusted time, tutorial/progression/Hall/support/service sources, and concurrency.

### Suggested next task

M04E2A2 planning only after M04E2A1 is Merged/Passed.

### Updated PR head

Provide the exact commit SHA.
