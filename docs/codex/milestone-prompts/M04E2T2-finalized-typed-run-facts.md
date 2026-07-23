# Implementation slice M04E2T2: Finalized typed simulation run facts and current-consumer migration

**Prompt version:** v0.1  
**Prompt date:** 2026-07-22  
**Prompt status:** Approved 
**Work item type:** Implementation slice  
**Parent conceptual epics:** M04 / M04E / M04E2  
**Milestone definition:** `docs/codex/MILESTONES.md`  
**Architecture decisions:** Accepted `DEC-0043`; Accepted `DEC-0044`  
**Expected base:** current `main` after the combined M04E2T1-closure/M04E2T2-planning package is committed  
**Feature branch:** `codex/implement-m04e2t2`  
**Pull-request target:** `main`  
**Approved PR title:** `M04E2T2: Add finalized typed simulation run facts`  
**Repository prompt path:** `docs/codex/milestone-prompts/M04E2T2-finalized-typed-run-facts.md`

> This prompt authorizes a public-result representation and current-consumer migration only. It does not authorize candidate mutation or commit redesign, report state, schema version 4, report ingestion/reads/history, UI, trusted time, concurrency, or M04E2B.

## Approval gate

Do not begin implementation until the project owner changes the prompt status to Approved and confirms:

```text
DEC-0044: Accepted
M04E2T2 definition: Approved
M04E2T2 prompt: Approved v0.1 or later
GATE-FINALIZED-RUN-FACTS: Satisfied
GATE-SLICE-SCOPE: Satisfied
Codex desktop workflow: Approved
```

Start a new Codex desktop task from updated `main`. Do not continue the M04E2T1 implementation task or either abandoned PR #17/PR #18 task.

## Repository delivery contract

Before editing:

1. fast-forward local `main` from `origin/main`;
2. create and switch to `codex/implement-m04e2t2`;
3. verify the current branch is not `main`;
4. report the starting `main` SHA and clean tracked state.

After implementation and verification:

1. commit all intended changes on `codex/implement-m04e2t2`;
2. create a temporary PR description file outside the repository;
3. run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
    -File .\tools\codex\publish_milestone_pr.ps1 `
    -RepoRoot '<repository root>' `
    -ExpectedBranch 'codex/implement-m04e2t2' `
    -BaseBranch 'main' `
    -Title 'M04E2T2: Add finalized typed simulation run facts' `
    -BodyFile '<temporary PR description file>'
```

4. report the PR number, URL, branch, and exact head SHA;
5. stop.

Do not commit or push directly to `main`. Do not merge, auto-merge, close, approve, delete a branch, force-push, rewrite history, or create a replacement PR. Later corrections in this task update the same branch and PR. Only the owner may merge or close.

## Required reading

Read completely before editing:

- `AGENTS.md`, including the Codex desktop workflow;
- accepted `DEC-0043` and, after approval, `DEC-0044`;
- `docs/codex/CODEX_DESKTOP_WORKFLOW.md`;
- `docs/codex/M04E2_IMPLEMENTATION_POSTMORTEM.md`;
- `docs/codex/M04E2_TRANSACTION_REDESIGN_PLAN.md`;
- `docs/codex/M04E2T2_PLANNING.md`;
- `docs/codex/ARCHITECTURE.md` M04E2T1/T2 sections;
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` M04E2T1/T2 contracts;
- `docs/codex/IMPLEMENTATION_RULES.md` single-provenance and finalized-fact rules;
- `docs/codex/TESTING_AND_VALIDATION.md` M04E2T1 completion and M04E2T2 package;
- `docs/codex/OWNER_VERIFICATION_WORKFLOW.md`;
- current M04C, M04D2, M04D3, M04E1, and M04E2T1 milestone records, tests, and traces.

Inspect current implementations of:

- `SimulationEngine`, including nested `SimulationResult` and `SimulationEvent`;
- `SimulationRunContext`;
- `SimulationFactJournal`;
- `SimulationTransaction`, especially finalization, `_build_result_from_journal`, and `commit_to`;
- `SimulationRunService` and `SimulationRunResult`;
- `M04CDebugAdvance`;
- assignment identity and rate-context services;
- persistence mappers/validators and current result-artifact exclusion tests.

PR #17 and PR #18 may be inspected only for accepted defect categories, black-box expected values, and regression descriptions. Do not copy or cherry-pick their production implementation, typed class layout, or post-hoc validator.

## Objective

Replace the transitional public simulation-result grammar with one final detached typed fact family projected only from finalized M04E2T1 evidence.

The implementation must:

- move result/event ownership out of nested `SimulationEngine` classes into focused global types;
- replace raw public segment dictionaries with typed `SimulationSegmentResult` values;
- replace raw public channel dictionaries with typed `SimulationChannelDeltaResult` values;
- replace generic public event payload dictionaries with a closed typed event union;
- remove simulation `change_summary` from the public result;
- migrate every current production/debug/test/trace consumer directly;
- preserve the M04E2T1 candidate/journal/commit boundary exactly.

## Protected invariants

- `SimulationEngine` remains the sole gameplay formula and segmentation owner.
- `SimulationTransaction` remains the private candidate, mutation, finalization, and commit owner.
- `SimulationResultProjector` or equivalent is pure and receives no live or candidate `GameState`.
- Public facts are never commit inputs.
- Existing one-hour, eight-hour, Settlement, channel, chunking, rate-context, forecast, debug, and mode outcomes remain exact.
- Historical identity is captured from immutable run context/facts and is never reconstructed from current mutable state.
- Different equal-output loadouts remain distinct.
- Schema remains version 3; content remains `prototype-content-r2`.
- No report state, schema v4, report service, report ingestion/read/history, UI, trusted time, tutorial, progression, Hall, support, analytics, or concurrency enters the diff.
- Every failure leaves source state canonically unchanged under the existing T1 transaction boundary.

## Required pre-edit report

Before non-trivial edits, report:

1. exact current `main` SHA, feature branch, and clean tracked state;
2. every current public result consumer and the fields it reads;
3. every current raw segment/channel/event-payload/summary field;
4. a journal/context-to-public-field matrix;
5. the proposed exact class/file layout and why no responsibility returns to `simulation_engine.gd`;
6. the four result-shape table;
7. the exact segment and channel field-domain tables;
8. the closed event subtype, field, order, ownership, and cardinality table;
9. the pure structural-validation boundary and explicit confirmation that it receives no candidate state;
10. the consumer migration matrix, including tests and traces;
11. every raw public grammar/API to be removed and every internal diagnostic dictionary intentionally retained;
12. persistence-exclusion and frozen-fixture plan;
13. expected changed files, additions/deletions/net lines, and cross-layer seams;
14. focused/full/import/trace/owner-runner verification plan;
15. confirmation that PR #17/PR #18 production code, report work, schema v4, and later systems are excluded.

Stop before editing if the typed family cannot be completed without changing candidate mutation/commit semantics, adding another authoritative aggregate, introducing schema v4, keeping raw and typed public grammars in parallel, adding a second projection owner, or crossing the approved scope guardrail.

## Proposed file responsibilities

Prefer focused global types under `src/simulation/results/` or an equally clear inspected location:

```text
SimulationResult
SimulationSegmentResult
SimulationChannelDeltaResult
SimulationEvent
SimulationChannelBankedEvent
SimulationThresholdSettledEvent
SimulationResultProjector
```

Exact filenames may be adjusted after inspection, but do not nest the final public fact family inside `SimulationEngine` or combine all types/projector logic into one large script.

Every non-trivial type begins with junior-readable `##` documentation covering responsibility, ownership exclusions, units, detachment, determinism, and persistence exclusion.

Public facts should expose read-only properties backed by private state where practical in Godot 4.7. Provide explicit detached-copy and value-equality behavior. Do not use JSON/reflection cloning or compare `RefCounted` identity.

## Required result contract

### Result kinds

Use stable `StringName` constants or an equally explicit closed type:

```text
FAILURE
ZERO_DURATION
TIMELINE_ONLY
ACTIVE_REAPING
```

### Result fields

```text
result_kind: StringName
success: bool
error_code: StringName
developer_details: String
requested_elapsed_msec: int
committed_elapsed_msec: int
baseline_simulation_time_msec: int
result_simulation_time_msec: int
content_revision: String
segments: Array[SimulationSegmentResult]
events: Array[SimulationEvent]
```

### Failure shape

```text
result_kind == FAILURE
success == false
error_code non-empty
committed_elapsed_msec == 0
segments empty
events empty
baseline_simulation_time_msec == result_simulation_time_msec
```

A negative requested duration is allowed when it caused failure. Failure carries no committed fact authority. Preserve current diagnostic behavior and no live mutation.

### Zero-duration shape

```text
result_kind == ZERO_DURATION
success == true
requested_elapsed_msec == 0
committed_elapsed_msec == 0
segments empty
events empty
baseline == result cursor
no gameplay mutation
```

Preserve current zero-duration behavior, including any existing pre-validation ordering. Do not broaden this slice by redesigning zero-request state validation.

### Positive timeline-only shape

```text
result_kind == TIMELINE_ONLY
success == true
requested_elapsed_msec > 0
committed_elapsed_msec == requested_elapsed_msec
result cursor - baseline cursor == committed elapsed
content_revision exact and non-empty
segments empty
events empty
```

### Positive active-Reaping shape

```text
result_kind == ACTIVE_REAPING
success == true
requested elapsed > 0
committed elapsed == requested elapsed
result cursor - baseline cursor == committed elapsed
content_revision exact and non-empty
segments non-empty
typed closed events only
```

Under the current one-active-Reaping resolver, allow only one `OVERDUE` segment, one `SETTLED` segment, or two segments `OVERDUE` then `SETTLED`. Segments cover the complete interval.

Use checked signed-64-bit arithmetic for cursor differences, segment elapsed, and aggregate/cardinality validation.

## Required segment contract

```text
segment_index: int
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

- zero-based indexes match array order;
- IDs are non-empty and assignment revision is positive;
- Retinue IDs are detached, unique, and preserve canonical selected order;
- lifecycle is `OVERDUE` or `SETTLED`;
- start/end/elapsed are non-negative, ordered, and exact;
- core deltas are non-negative;
- `backlog_reduced` is the non-negative amount, not an ambiguous signed `backlog_delta`;
- channel IDs are unique and canonically ordered;
- exact Threshold/revision/Form/Writ/Retinue identity remains stable across the run;
- first segment starts at the result baseline;
- final segment ends at the result cursor;
- adjacent segments are contiguous;
- total segment elapsed equals committed elapsed using checked arithmetic.

A retained segment must remain unchanged after same-timestamp recall or redispatch.

## Required channel contract

```text
channel_id: StringName
output_item_id: StringName
banked_units_delta: int
progress_subunits_before: int
progress_subunits_after: int
rate_period_msec: int
rate_carry_units_before: int
rate_carry_units_after: int
total_banked_units_before: int
total_banked_units_after: int
```

Rules:

- IDs are non-empty;
- period is positive;
- progress endpoints are in `[0, FixedPoint.SCALE)`;
- carry endpoints are in `[0, rate_period_msec)`;
- totals are non-negative and monotonic;
- banked delta equals total after minus total before using checked arithmetic;
- progress-only changes with zero banking remain representable;
- records are detached and value-comparable;
- no fractional inventory is implied.

Do not expose candidate inventory endpoints as another public authority. They remain internal T1 journal provenance.

## Required closed event contract

### Common base

```text
event_type: StringName
occurred_simulation_msec: int
priority: int
segment_index: int
subject_id: StringName
source_id: StringName
reportable: bool
tutorial_relevant: bool
```

Stable order:

```text
occurred_simulation_msec
priority
subject_id
source_id
```

Every event references one valid owning segment. Time ownership remains:

```text
segment.start_simulation_msec < event.occurred_simulation_msec
    <= segment.end_simulation_msec
```

### `SimulationChannelBankedEvent`

Required typed fields:

```text
output_item_id
quantity
lifecycle_state
total_banked_units_after
progress_subunits_after
```

Require:

- event type `OUTPUT_CHANNEL_BANKED`;
- canonical channel priority and flags;
- subject is the segment Threshold;
- source is the channel ID;
- time is segment end;
- quantity is positive;
- typed fields equal the owning channel delta/lifecycle;
- exactly one event for each positive-banking segment/channel delta;
- no event for a progress-only delta.

### `SimulationThresholdSettledEvent`

Required typed fields:

```text
persistent_returns_total
remaining_backlog_before
remaining_backlog_after
lifecycle_before
lifecycle_after
```

Require:

- event type `THRESHOLD_SETTLED`;
- canonical lifecycle priority and flags;
- subject is the Threshold;
- source is `SIMULATION_ENGINE`;
- time is the end of the Overdue segment;
- remaining backlog after is zero;
- lifecycle is exactly `OVERDUE -> SETTLED`;
- exactly one event iff the run crosses Settlement;
- no event for already-Settled or uncompleted Overdue runs.

Do not retain a generic public payload dictionary. Reject base/unknown event instances in structural validation.

## Projector and validation boundary

Create one pure `SimulationResultProjector` or equivalent.

It may receive only:

- finalized/detached `SimulationRunContext` data;
- frozen `SimulationFactJournal` evidence;
- constants/helpers required to map existing event types without gameplay calculation.

It must not receive:

- live `GameState`;
- candidate `GameState`;
- a caller-authored result;
- report state;
- mode metadata;
- clocks, files, scenes, or platform services.

Projection maps facts; it does not derive rates or mutate anything.

Add pure local/run-level structural validation for result kinds, field domains, timing, identity continuity, channel ordering, event order/ownership/cardinality, and detached child types. Do not compare result facts with candidate state or duplicate simulation formulas.

`SimulationTransaction.finalize()` preserves this order:

```text
candidate validation
-> journal validation and freeze
-> typed projection and structural validation
-> finalized state
```

`commit_to()` preserves one candidate `copy_from` and returns the already projected typed result. The typed result is never an argument to commit.

## Remove transitional public compatibility

Remove from the public simulation result:

- raw Dictionary segment entries;
- raw Dictionary channel-delta entries;
- generic event payload Dictionary;
- simulation `change_summary`;
- nested `SimulationEngine.SimulationResult` and `SimulationEvent` ownership.

Do not add `to_legacy_dictionary()`, a raw fallback array, or parallel public compatibility result.

Internal `SimulationFactJournal.facts_snapshot()` and transaction diagnostic trace dictionaries may remain because they are bounded internal evidence and not the public contract.

Do not modify unrelated domain-service `change_summary` contracts.

## Current consumer migration

Update every direct consumer, including:

- `SimulationEngine.resolve_elapsed` and `resolve_elapsed_with_trace` result typing;
- `SimulationTransaction` finalized result and projector call;
- `SimulationRunService.SimulationRunResult.simulation_result`;
- `M04CDebugAdvance`;
- M04C/M04D2/M04D3/M04E1/M04E2T1 unit tests that inspect public results;
- M04C/M04D2/M04D3/M04E1/M04E2T1 traces that inspect public results;
- source-ownership checks;
- persistence-exclusion tests.

Forecast and committed modes return value-equal typed engine facts. No consumer converts the typed result back to the former public dictionaries.

## Behavior preservation

Preserve all existing exact values and boundaries. At minimum:

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

Preserve channel eligibility, rate plans, Settlement boundary/order, carry, inventory, source history, regular/irregular chunk state equality, forecast/commit equality, committed-mode equality, and all current failure/no-mutation behavior.

## Persistence exclusion

Keep:

```text
SaveEnvelope.CURRENT_SCHEMA_VERSION = 3
content revision = prototype-content-r2
```

Production snapshots and saved bytes must not contain result, segment, channel, event, projector, context, transaction, journal, validation, run-wrapper, or forecast-projection artifacts.

Do not modify migrations or frozen v1/v2/v3 fixture bytes.

## Required tests

Add `tests/unit/m04e2t2/` and `tests/integration/m04e2t2/` as needed. Migrate useful existing tests instead of duplicating every fixture.

At minimum add named tests for:

### Result shapes and detachment

- valid failure, zero, timeline-only, and active result shapes;
- wrong kind/success/code/duration/cursor combinations;
- retained result/segment/channel/event objects are detached;
- value equality ignores object identity;
- result arrays contain only typed expected classes;
- positive active results cannot be segmentless;
- active segments cover the complete interval.

### Segment and channel fields

- exact historical identity and Retinue order;
- invalid/duplicate identity and invalid lifecycle;
- segment timing/gap/overlap/index errors;
- checked elapsed aggregation overflow;
- negative core deltas;
- channel progress/carry/period bounds;
- total reversal and banked mismatch;
- duplicate/unsorted channels;
- progress-only and multiple-whole cases.

### Closed events

- stable ordering;
- explicit valid segment ownership;
- start-exclusive/end-inclusive boundary behavior;
- positive bank requires exactly one typed channel event;
- progress-only delta has no bank event;
- typed channel event field mismatch rejection;
- Settlement requires exactly one typed Settlement event;
- early, duplicate, missing, or spurious Settlement rejection;
- base/unknown event instance rejection;
- no generic payload dictionary.

### Historical attribution and behavior

- exact one-hour fixture;
- exact eight-hour fixture;
- Settlement segmentation and event order;
- same-timestamp recall preserves original typed identity;
- same-timestamp redispatch preserves original typed identity;
- equal-output component identities remain distinct;
- regular and irregular chunk gameplay equality;
- forecast/committed-clone typed fact equality;
- foreground/offline-fixture/debug typed fact equality;
- source state remains unchanged on all existing transaction failures.

### Consumer and persistence migration

- run-service typed passthrough;
- debug typed delegation;
- current traces consume typed values;
- no public raw segment/channel dictionaries;
- no generic public event payload dictionary;
- no simulation `change_summary`;
- schema-v3 production round trip unchanged;
- no result artifact in mapped snapshot or JSON;
- no report or later-slice source ownership.

Source-string audits supplement but do not replace behavioral tests.

## Developer trace

Create:

```text
tools/test/m04e2t2/m04e2t2_finalized_facts_trace.gd
```

It requires an existing isolated `--work-root`, fails when absent, performs real assertions, and emits exactly:

```text
TRACE M04E2T2 typed_result_envelope=PASS
TRACE M04E2T2 segment_historical_identity=PASS
TRACE M04E2T2 channel_endpoint_contract=PASS
TRACE M04E2T2 channel_event_closed_union=PASS
TRACE M04E2T2 settlement_event_closed_union=PASS
TRACE M04E2T2 timeline_only_positive=PASS
TRACE M04E2T2 zero_and_failure_no_authority=PASS
TRACE M04E2T2 one_hour_values_unchanged=PASS
TRACE M04E2T2 eight_hour_values_unchanged=PASS
TRACE M04E2T2 settlement_segments_and_order=PASS
TRACE M04E2T2 same_timestamp_attribution=PASS
TRACE M04E2T2 equal_output_identity_distinct=PASS
TRACE M04E2T2 forecast_commit_mode_equivalence=PASS
TRACE M04E2T2 raw_public_grammar_removed=PASS
TRACE M04E2T2 schema_v3_no_result_artifacts=PASS
```

No marker may be emitted from unconditional success or marker-text search alone.

## Owner verification package

Create:

```text
tools/test/owner/run_m04e2t2_owner_verification.ps1
```

Follow `OWNER_VERIFICATION_WORKFLOW.md` and the corrected M04E2T1 runner pattern.

When `-CommitSha` is supplied, Git head detection and exact equality are mandatory. Do not record “unavailable” and continue.

Required sequence:

1. environment, requested SHA, detected exact Git head, resolved Godot;
2. full GUT before;
3. focused M04C/M04D2/M04D3/M04E1/M04E2T1/M04E2T2 unit/integration directories;
4. explicit import;
5. real isolated-root M04E2T2 trace;
6. exact 15-marker verification;
7. missing-root trace must fail and expected-nonzero handling must distinguish native exit from assertion exceptions;
8. cleanup in `finally`;
9. cleanup absence proof;
10. artifact audit;
11. full GUT after;
12. UTF-8 log and zero-failure summary.

No interactive checklist is required.

Do not run or claim the final owner package before the final GitHub review is clean on the exact head.

## Verification before PR handoff

Run from repository root:

```sh
./tools/test/run_gut.sh -- \
  -gdir=res://tests/unit/m04c \
  -gdir=res://tests/unit/m04d2 \
  -gdir=res://tests/unit/m04d3 \
  -gdir=res://tests/unit/m04e1 \
  -gdir=res://tests/unit/m04e2t1 \
  -gdir=res://tests/unit/m04e2t2 \
  -gdir=res://tests/integration/m04e1 \
  -gdir=res://tests/integration/m04e2t1 \
  -gdir=res://tests/integration/m04e2t2

./tools/test/run_gut.sh

godot --headless --path . --import

trace_root="$(mktemp -d)"
godot --headless --path . \
  -s res://tools/test/m04e2t2/m04e2t2_finalized_facts_trace.gd \
  -- --work-root "$trace_root"
trace_exit=$?
rm -rf "$trace_root"
test ! -e "$trace_root"
test "$trace_exit" -eq 0

godot --headless --path . \
  -s res://tools/test/m04e2t2/m04e2t2_finalized_facts_trace.gd
test "$?" -ne 0

git diff --check
git status --short
```

Also run every affected existing behavioral trace and report exact marker results. The complete suite must be green before review.

## Review workflow

### Pre-review readiness pass

Before `@codex review`, produce:

- requirement-to-evidence matrix;
- exact changed-file and line counts;
- class/field/event/consumer mapping;
- focused/full/import/trace evidence;
- confirmation that raw public grammar is removed;
- confirmation that no candidate/commit/report/schema behavior changed;
- complete PR title/body handoff.

### Targeted GitHub review

The targeted review audits only P1/P2 correctness in:

- typed field completeness and detachment;
- frozen-journal-only projector provenance;
- four result shapes and full interval coverage;
- historical identity;
- channel endpoint domains;
- closed event union, ordering, ownership, and cardinality;
- raw compatibility removal;
- consumer migration and typed equality;
- persistence exclusion and scope.

Apply bounded fixes in the same Codex desktop task/branch and add named regressions. Repeat the same targeted review only when needed.

### Stop rule

Stop and return to planning when:

- more than two targeted rounds produce new P1/P2 findings;
- more than six material findings are discovered;
- more than 30 non-documentation source/test files or approximately 1,450 code/test lines are required;
- another primary owner, authoritative aggregate, schema transition, or third seam appears;
- candidate mutation/commit behavior must change;
- raw and typed public grammars cannot be removed in one migration;
- the full suite is red at review request.

After a clean targeted audit, submit one unrestricted current-head review. Then run exact-head owner verification once.

## Documentation updates

Update only maintained documents made inaccurate by the realized implementation:

- `docs/codex/ARCHITECTURE.md`;
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`;
- `docs/codex/IMPLEMENTATION_RULES.md` only if a durable rule changes;
- `docs/codex/TESTING_AND_VALIDATION.md`;
- `docs/codex/MILESTONES.md` status/evidence;
- `docs/codex/M04E2_TRANSACTION_REDESIGN_PLAN.md`;
- this prompt's completion status after merge.

Keep while the PR is open:

```text
Implementation: Pull request open
Verification: Partial
```

Do not draft or implement M04E2A2 in this task.

## Acceptance criteria

M04E2T2 is complete only when:

1. the four result kinds and exact shape rules are implemented;
2. the global typed result contains exact request/commit and baseline/result timing;
3. active segments carry complete historical identity and exact core facts;
4. channel deltas carry typed self-interpretable endpoints including period;
5. public event types form the closed current union;
6. event order, owning segment, boundary time, and cardinality are exact;
7. result/segment/channel/event objects are detached and value-comparable;
8. projection consumes finalized context/frozen journal only;
9. projection and structural validation receive no candidate `GameState`;
10. typed facts are never a commit input;
11. raw public segment/channel dictionaries are removed;
12. generic public event payload dictionaries are removed;
13. simulation `change_summary` is removed;
14. no parallel legacy public result API remains;
15. every current production/debug/test/trace consumer is migrated directly;
16. historical facts survive same-timestamp assignment changes;
17. equal-output component identities remain distinct;
18. exact one-hour, eight-hour, Settlement, channel, chunk, mode, and forecast behavior remains unchanged;
19. all M04C through M04E2T1 tests/traces remain green;
20. schema remains v3 and content remains r2;
21. frozen fixture bytes remain unchanged and no fact artifacts serialize;
22. no report/schema-v4/later-system ownership enters the diff;
23. actual scope remains inside approved guardrails;
24. focused/full/import/trace/negative-root/cleanup/artifact checks pass;
25. targeted and unrestricted GitHub reviews are clean;
26. exact-head Windows owner verification passes;
27. Codex publishes/updates the PR and stops without merging.

## PR description requirements

The PR description includes:

- architecture and projector boundary;
- exact typed field/event tables;
- consumer migration list;
- raw grammar removal list;
- exact changed files and scope counts;
- focused/full test and assertion counts;
- import and all trace results;
- persistence exclusion;
- PR #17/#18 reuse statement;
- deferred work;
- exact head SHA;
- owner verification status as Pending until actually run.

## Final response format

Report:

### Implementation completed

Typed family, projector, result shapes, event union, and compatibility removal.

### Journal-to-public matrix

Every public field and its context/journal source.

### Consumer migration

Every production/debug/test/trace consumer changed.

### Files changed

Every file and purpose.

### Regression tests

Named tests for shapes, detachment, event cardinality, attribution, behavior, and persistence.

### Verification

Every command, exact test/assertion count, markers, negative trace, cleanup, and status.

### Scope

Final non-documentation file/addition/deletion/net counts and primary-owner/seam assessment.

### Abandoned-branch reuse statement

Whether PR #17/#18 were inspected and confirmation that no production code was copied/cherry-picked.

### Deferred work

M04E2A2, M04E2A3, M04E2A4, M04E2B, and all later systems.

### Pull request

PR number, URL, branch, and exact head SHA. Confirm no merge/close/auto-merge action was taken.
