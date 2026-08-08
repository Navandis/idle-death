# Death Idle G3 — M04E2R1 Planning v0.3

**Date:** 2026-08-05  
**Status:** Owner-approved v0.3; implementation-ready for a separate transactional Codex task  
**Planning owner:** Long-lived Death Idle planning architect  
**Repository:** `Navandis/idle-death`  
**Verified planning baseline:** `main` at `6d2e9247322798cb040659bc9c98b650d24ab69e`  
**Parent sequence:** `M04E2T1 -> M04E2T2 -> M04E2R1 -> M04E2R2 -> M04E2P1 -> M04E2B`

## 1. Current state and planning boundary

G2 is Merged/Passed. PR #33 merged final head `99963c8ae53e1585318973f77097989d028bfdd7` as merge commit `6d2e9247322798cb040659bc9c98b650d24ab69e`; the owner confirmed successful post-merge CI. Live `main` remains that merge commit and no pull request is open.

G3 owns the complete M04E2R1 definition deferred by accepted `DEC-0045`:

- exact runtime-ledger fields;
- exact ingestion API and stable result/error grammar;
- ownership and lifetime matrix;
- complete interval-decision table;
- normalized aggregation and source-continuity rules;
- complete disprovable test oracle;
- sole implementation context manifest;
- owner-approval packet.

Owner approval authorizes only a separate transactional Implementation Codex task to execute this packet. This planning-architect session remains outside implementation and routine PR-lifetime triage.

## 2. Independent assessment disposition

The fresh scope assessor's v0.1 audit returned **APPROVE WITH BOUNDED CORRECTIONS**. The principal transition, one-owner boundary, 32-path set, 13-script count, Terra/High lane, ownership sequence, and no-schema/no-persistence boundary were approved. Packet v0.2 incorporated its five corrections:

1. retain channel rate-period and arithmetic-carry endpoints;
2. validate source continuity before merge-versus-append;
3. make canonical shape, interval ordering, mode coverage, and Settlement ordering directly disprovable;
4. make API invocation, factory failure, validator grammar, wrapper parity, and ingest-result grammar exact;
5. make the implementation manifest literal, exact, and non-historical.

The same assessor's v0.2 rereview again returned **APPROVE WITH BOUNDED CORRECTIONS** with one residual blocker: rejection diagnostics were not mandatory in every normative and oracle location. V0.3 now requires every `REJECTED` result to carry exactly one listed non-empty `error_code`, non-empty `developer_details`, and no candidate. This tightens the existing result grammar only; it adds no field, error code, test, helper, path, owner, sequence, or schema change.

## 3. Sole G3 planning context manifest

Failed-branch production code, superseded prompt bodies, transcripts, and broad historical material were excluded.

| Priority | Source | Exact authority used | Role |
|---:|---|---|---|
| 1 | Owner instruction | Start G3 after G2 merge and successful post-merge CI | Current authority |
| 2 | `AGENTS.md` | Full merged root router | Universal authority and context routing |
| 3 | `docs/codex/DECISIONS.md` | `DEC-0045`; current approval-state paragraph for superseded `DEC-0041` | R1/R2/P1/B ownership and historical boundary |
| 4 | `docs/codex/ARCHITECTURE.md` | `Current M04E2 report architecture (DEC-0045)` | Runtime-ledger architecture |
| 5 | `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | Current R1/R2/P1/B paragraph; realized M04E2T2 typed facts | Data and input grammar |
| 6 | `docs/codex/MILESTONES.md` | M04E2 status map; §7.1; M04E2R1 follow-on boundary | Sequence and status |
| 7 | `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md` | Reaping Report definition; `IF-REQ-02`, `IF-REQ-03`, `IF-REQ-20` | No-claim/no-pause/component identity |
| 8 | `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md` | `P90-SAFE-06`, `P90-SAFE-11`, `P90-B06` | Prototype report behavior |
| 9 | `src/simulation/simulation_run_service.gd` | Full file | Wrapper and committed-mode grammar |
| 10 | T2 result family | Exact seven paths below | Current finalized-fact grammar |
| 11 | Current tests | Exact named T2 tests and persistence-exclusion test below | Existing regressions and non-persistence proof |

Exact T2 result paths:

```text
src/simulation/results/simulation_result.gd
src/simulation/results/simulation_segment_result.gd
src/simulation/results/simulation_channel_delta_result.gd
src/simulation/results/simulation_event.gd
src/simulation/results/simulation_channel_banked_event.gd
src/simulation/results/simulation_threshold_settled_event.gd
src/simulation/results/simulation_result_projector.gd
```

Exact existing unit tests in `tests/unit/m04e2t2/test_simulation_result_facts.gd`, plus directly called local helpers:

```text
test_four_result_shapes_and_typed_child_arrays
test_detachment_and_value_equality_ignore_refcounted_identity
test_historical_identity_survives_same_timestamp_reconfiguration
test_channel_endpoints_period_and_progress_only_are_self_interpretable
test_closed_events_have_exact_fields_order_and_boundary_ownership
test_event_subtype_fields_and_settlement_cardinality_reject_mismatches
test_structural_validation_rejects_gap_duplicate_channel_and_endpoint_mismatch
test_event_order_ownership_priority_and_signed_cursor_boundary
```

Persistence exclusion baseline:

```text
tests/integration/m04e2t2/test_finalized_facts_persistence_exclusion.gd
```

The current `DEC-0045` approval paragraph is sufficient historical provenance: it states that concrete `DEC-0041` classifications are non-binding evidence. `DEC-0041` is not a direct implementation-context entry. No unresolved provenance question required PR #17, PR #18, PR #23 production files, or supporting-evidence material.

## 4. Principal result

### Objective

Create one typed, caller-owned, non-persisted live report ledger that consumes a valid committed `SimulationRunResult` exactly once and normalizes finalized T2 facts into a self-interpretable, chunk-invariant current reporting window.

### Principal transition

```text
validated caller-owned ReportLedger + finalized committed SimulationRunResult
-> private normalized candidate
-> complete runtime-ledger validation
-> APPLIED candidate or transactional no-op/rejection
```

### Developer demonstration

Starting from an empty ledger at cursor `0`:

1. ingest one successful committed run;
2. observe exact cursor, mode coverage, normalized slices, channel period/progress/carry/total endpoints, and Settlement fact;
3. redeliver the run and receive a duplicate no-op;
4. ingest an equivalent same-mode chunked sequence into another empty ledger;
5. prove value equality;
6. attempt identity, backlog, lifecycle, period, carry, progress, and total resets across both merge and split boundaries and prove rejection without source mutation;
7. prove schema version 3 and `GameState` remain unchanged.

## 5. Proposed decision: DEC-0046

### Title

`DEC-0046 — Caller-owned chunk-invariant report ledger and exact committed-run ingestion`

### Status

**Owner-approved on 2026-08-05.** The implementation slice adds this record to `DECISIONS.md` as Accepted; no implementation actor may broaden or reinterpret it.

### Decision

M04E2R1 introduces one typed `ReportLedger` aggregate that is created and retained by its caller, absent from `GameState`, passed explicitly to every operation, treated as read-only source input, cloned privately only for an applicable exact-new interval, and returned only after complete candidate validation.

R1 consumes `SimulationRunService.SimulationRunResult`, not a bare `SimulationResult`, because the wrapper owns the committed-mode and projected-state boundary. It accepts only successful current committed modes with no projected state and exact wrapper/inner parity.

The ledger stores only irreducible continuation and attribution facts: global cursor/mode coverage; maximal operational slices; full historical component identity; backlog/core endpoints and deltas; channel output, period, progress, arithmetic carry, and banked-total endpoints; and normalized Settlement evidence. Redundant elapsed values, backlog reduction, channel banked deltas, totals, counts, summaries, formatted views, report records, history, retention, snapshots, and read models remain derived or deferred.

Source continuity is validated before merge-versus-append. A slice split caused by mode, content revision, lifecycle, assignment revision, or a time gap does not permit identity, backlog, lifecycle, channel, or Settlement history to reset. Full component identity remains stable for one `(threshold_id, assignment_revision)` across modes and content revisions. A Threshold never regresses from `SETTLED` to `OVERDUE`; it settles at most once per ledger window. Previously seen channels must remain present and exactly continue output identity, period, progress, carry, and total endpoints whenever that Threshold next produces active facts.

R1 is chunk-invariant. Equivalent same-mode one-shot and chunked committed runs produce value-equal ledgers. Positive channel-bank events are validated and folded into endpoint aggregates because their count depends on simulation call chunking. Settlement remains one normalized event because its persistent-return boundary total is not otherwise present.

R1 adds no snapshots, history, retention, detached reads, schema version 4, migration, persistence, `GameState` ownership, application wiring, or atomic simulation/report coordination. Those remain R2, P1, and B in sequence.

## 6. Exact runtime type and field contract

All integers are signed 64-bit GDScript `int`. Simulation times are integer milliseconds. Canonical IDs are `StringName`; `content_revision` remains `String` to match T2.

### 6.1 `ReportLedger`

```text
window_start_simulation_msec: int
ingested_through_simulation_msec: int
foreground_elapsed_msec: int
offline_elapsed_msec: int
debug_elapsed_msec: int
next_event_sequence: int
slices: Array[ReportLedgerSlice]
settlement_events: Array[ReportSettlementEvent]
```

Invariants:

- cursors and mode durations are non-negative;
- `window_start <= ingested_through`;
- checked sum of mode durations equals the complete window span;
- `next_event_sequence >= 1`;
- empty ledger: equal start/cursor, zero durations, sequence `1`, empty arrays;
- public arrays/children are deeply owned;
- slices and channel intervals use half-open `[start, end)`;
- slices are strictly chronological and non-overlapping under the current one-active-Reaping grammar;
- no adjacent pair remains merge-compatible under the full normalization key and continuity rules;
- checked slice elapsed for each mode is no greater than that mode’s root coverage;
- Settlement events are sequence-contiguous, nondecreasing by occurrence time, and inside the event-time domain below.

### 6.2 `ReportLedgerSlice`

```text
run_mode: StringName
content_revision: String
threshold_id: StringName
assignment_revision: int
form_id: StringName
writ_id: StringName
ordered_retinue_ids: Array[StringName]
lifecycle_state: StringName
start_simulation_msec: int
end_simulation_msec: int
returned_souls_delta: int
remaining_backlog_before: int
remaining_backlog_after: int
essence_delta: int
mastery_delta_subunits: int
completed_cycles_delta: int
channels: Array[ReportLedgerChannel]
```

Derived:

```text
elapsed_msec = end - start
backlog_reduced = remaining_backlog_before - remaining_backlog_after
loadout keys, totals, counts, summaries
```

Local invariants:

- mode is one current committed mode;
- IDs/content are non-empty; assignment revision is positive;
- retinue IDs are duplicate-free and order-sensitive;
- lifecycle is `OVERDUE` or `SETTLED`;
- `0 <= start < end` and the interval lies in the ledger window;
- all deltas/endpoints are non-negative and checked;
- `remaining_backlog_after <= remaining_backlog_before`;
- `OVERDUE` begins with positive backlog; `SETTLED` has zero backlog endpoints;
- channels are unique and ordered by `channel_id`.

Ledger-wide identity and lifecycle invariants:

- all slices with the same `(threshold_id, assignment_revision)` have identical Form, Writ, and ordered Retinue identity, regardless of mode/content revision;
- the latest backlog-after for a Threshold equals its next backlog-before, including after timeline-only or other-Threshold intervals;
- once a Threshold is `SETTLED`, no later slice for it is `OVERDUE`;
- only the final compatible contiguous slice may be extended;
- mode/content/lifecycle/revision/time-gap changes create a new slice only after source continuity passes.

### 6.3 `ReportLedgerChannel`

```text
channel_id: StringName
output_item_id: StringName
start_simulation_msec: int
end_simulation_msec: int
progress_subunits_before: int
progress_subunits_after: int
rate_period_msec: int
rate_carry_units_before: int
rate_carry_units_after: int
total_banked_units_before: int
total_banked_units_after: int
```

Derived:

```text
elapsed_msec = end - start
banked_units_delta = total_banked_units_after - total_banked_units_before
```

Invariants:

- IDs are non-empty;
- `0 <= progress < FixedPoint.SCALE`;
- `rate_period_msec > 0`;
- each carry is in `[0, rate_period_msec)`;
- totals are non-negative/non-decreasing;
- `slice.start <= channel.start < channel.end <= slice.end`;
- first appearance of a genuinely new channel is allowed after slice/window start;
- after first appearance, the next active fact for that Threshold contains the channel;
- output ID and period never change for an existing Threshold/channel source;
- prior progress/carry/total-after exactly equals next progress/carry/total-before across both merged and split slices;
- merge normalization retains first before endpoints and final after endpoints;
- deep clone and value equality include every channel field, including period and both carry endpoints.

No effective numerator, applied modifier, rate plan, or simulation formula is stored.

### 6.4 `ReportSettlementEvent`

```text
event_sequence: int
content_revision: String
threshold_id: StringName
assignment_revision: int
occurred_simulation_msec: int
persistent_returns_total: int
```

Invariants:

- sequence is positive, unique, contiguous, and lower than `next_event_sequence`;
- identity/content is non-empty; assignment revision is positive;
- `window_start < occurred_simulation_msec <= ingested_through`;
- events are ordered by contiguous sequence and nondecreasing occurrence time;
- event time equals the end of exactly one owning `OVERDUE` slice with matching content/Threshold/revision and backlog-after `0`;
- the first `OVERDUE` zero endpoint for a Threshold has exactly one event;
- one Threshold has at most one Settlement event in the window, irrespective of revision/content;
- persistent-return total is non-negative.

Type, source, priority, reportable flag, lifecycle transition, and zero post-transition backlog remain implied by the typed input and owning slice.

### 6.5 `ReportLedgerIngestResult`

```text
success: bool
changed: bool
outcome: StringName
error_code: StringName
developer_details: String
candidate_ledger: ReportLedger or null
```

| Outcome | success | changed | candidate | error/details |
|---|---:|---:|---|---|
| `APPLIED` | true | true | validated detached candidate | empty |
| `DUPLICATE_NO_OP` | true | false | null | empty |
| `ZERO_DURATION_NO_OP` | true | false | null | empty |
| `REJECTED` | false | false | null | one listed non-empty `error_code`; non-empty `developer_details` |

## 7. Exact public API and error grammar

Class-level static operations:

```text
ReportLedger.create_empty(start_simulation_msec: int) -> ReportLedger
ReportLedgerValidator.validate(ledger: ReportLedger) -> Dictionary
ReportLedgerIngestor.ingest_committed_run(
    source_ledger: ReportLedger,
    run: SimulationRunService.SimulationRunResult
) -> ReportLedgerIngestResult
```

Instance operations:

```text
ReportLedger.deep_clone() -> ReportLedger
ReportLedger.value_equals(other: ReportLedger) -> bool
```

`create_empty(start < 0)` returns `null` and creates no ledger.

Validator grammar has exactly three keys:

```text
success: { "ok": true,  "code": &"", "details": "" }
failure: { "ok": false, "code": &"REPORT_LEDGER_VALIDATION_FAILED", "details": String }
```

Every `REJECTED` ingest result has:

```text
success == false
changed == false
error_code == exactly one listed non-empty REPORT_INGEST_* code
developer_details != ""
candidate_ledger == null
```

Stable ingestion errors:

```text
REPORT_INGEST_LEDGER_REQUIRED
REPORT_INGEST_LEDGER_INVALID
REPORT_INGEST_RUN_REQUIRED
REPORT_INGEST_MODE_REJECTED
REPORT_INGEST_RUN_FAILED
REPORT_INGEST_PROJECTED_STATE_REJECTED
REPORT_INGEST_WRAPPER_MISMATCH
REPORT_INGEST_RESULT_INVALID
REPORT_INGEST_FORWARD_GAP
REPORT_INGEST_PARTIAL_OVERLAP
REPORT_INGEST_IDENTITY_MISMATCH
REPORT_INGEST_SLICE_DISCONTINUITY
REPORT_INGEST_CHANNEL_DISCONTINUITY
REPORT_INGEST_OVERFLOW
REPORT_INGEST_CANDIDATE_INVALID
```

Validator and ingestor retain no state. The source ledger, run wrapper, inner result, and all children are read-only inputs. The caller replaces its ledger reference only on `APPLIED`.

## 8. Wrapper validation order and parity

Normative precedence:

1. source ledger required;
2. source ledger validates;
3. run wrapper required;
4. mode is one of `FOREGROUND_SUPPLIED`, `OFFLINE_FIXTURE`, `DEBUG`;
5. failed committed-mode wrapper rejects `RUN_FAILED`;
6. successful committed-mode wrapper with projected state rejects `PROJECTED_STATE_REJECTED`;
7. inner result is non-null and parity-correct, otherwise `WRAPPER_MISMATCH`;
8. `SimulationResultProjector.validate(inner)` passes, otherwise `RESULT_INVALID`;
9. only then classify the interval.

Thus a forecast/unknown mode rejects `MODE_REJECTED`; a failed committed wrapper retains `RUN_FAILED` precedence over projection/inner checks.

Successful parity:

```text
run.requested_elapsed_msec == inner.requested_elapsed_msec
inner.committed_elapsed_msec == run.requested_elapsed_msec
run.baseline_simulation_time_msec == inner.baseline_simulation_time_msec
run.result_simulation_time_msec == inner.result_simulation_time_msec
run.success == inner.success
run.result_simulation_time_msec - run.baseline_simulation_time_msec
    == inner.committed_elapsed_msec
```

A successful wrapper with a null inner result is `WRAPPER_MISMATCH`.

## 9. Exact interval-decision table

The represented committed interval is half-open:

```text
[run.baseline_simulation_time_msec, run.result_simulation_time_msec)
```

| Validated condition | Outcome | Mutation |
|---|---|---|
| zero at ledger cursor | `ZERO_DURATION_NO_OP` | none |
| zero behind cursor | `DUPLICATE_NO_OP` | none |
| zero ahead of cursor | `REJECTED / FORWARD_GAP` | none |
| positive interval ends at/before cursor | `DUPLICATE_NO_OP` | none |
| positive interval starts before and ends after cursor | `REJECTED / PARTIAL_OVERLAP` | none |
| positive interval starts after cursor | `REJECTED / FORWARD_GAP` | none |
| positive interval starts exactly at cursor | candidate normalization and `APPLIED` if valid | private candidate only |

Additional rules:

- malformed covered inputs are rejected before duplicate classification;
- no partial slicing, rebasing, missing-fact recovery, or interval-ID set;
- positive `TIMELINE_ONLY` advances cursor and one mode-duration field without slices/events;
- positive active intervals normalize every segment, including zero-gain segments;
- checked arithmetic failure rejects without mutation.

## 10. Source continuity and normalization algorithm

For an exact-new interval:

1. Deep-clone the source ledger.
2. Checked-add committed elapsed to exactly one root mode-duration field.
3. Process T2 segments in canonical order.
4. Before merge/append, scan the candidate’s latest prior facts for the segment’s sources:
   - enforce component identity for `(threshold_id, assignment_revision)` across modes/content revisions;
   - enforce Threshold backlog endpoint continuity and no `SETTLED -> OVERDUE` regression;
   - require every previously seen Threshold/channel to be present in the next active fact for that Threshold;
   - enforce output, period, progress, carry, and total continuity;
   - allow a genuinely new channel to begin with its supplied start endpoint.
5. Merge only the final compatible contiguous slice; otherwise append a new ordered slice after continuity succeeds.
6. On merge, retain first before endpoints, checked-add core deltas, and retain final after endpoints. For channels, retain first progress/carry/total-before, unchanged period, and final progress/carry/total-after.
7. Validate bank events against T2 endpoints and fold them; store no per-bank event.
8. Map each Settlement event to one normalized event, require Threshold-wide uniqueness, and checked-increment sequence.
9. Set the root cursor to the run end.
10. Validate the complete candidate, including canonical maximality, mode coverage, source continuity, and event shape.
11. Return the detached candidate only on complete success.

Source continuity is independent of slice merge eligibility. Mode, content, lifecycle, revision, and timeline boundaries may split presentation/attribution slices but cannot reset the underlying historical source endpoints.

## 11. Stored-versus-derived decision

| Fact/value | Treatment | Reason |
|---|---|---|
| Ledger start/cursor and mode coverage | Stored | Exactly-once continuity; timeline-only representation |
| Full loadout identity and assignment revision | Stored | Historical attribution cannot use current `GameState` |
| Slice time/backlog/core deltas/endpoints | Stored | Irreducible current-window facts |
| Channel output, period, progress, carry, and total endpoints | Stored | Self-interpretable continuation and discontinuity proof |
| Settlement persistent-return total | Stored event | Not elsewhere in normalized ledger |
| Slice elapsed/backlog reduction | Derived | Endpoint subtraction |
| Channel banked delta | Derived | Total endpoint subtraction |
| Per-bank event detail | Validated/folded | Chunk-dependent cardinality |
| Totals, counts, summaries, formatting | Derived | Redundant views |
| Classification, snapshot/history/retention/read models | R2 | Separate transition |
| Schema/migration/save data | P1 | Separate durable owner |
| Combined gameplay/report candidate | B | Separate coordinator |

## 12. Ownership and lifetime matrix

| Object | Creator | Owner | Mutation authority | Lifetime | Non-owners |
|---|---|---|---|---|---|
| Source ledger | caller via static factory/prior candidate | caller/test | source read-only during ingestion | caller-defined runtime | `GameState`, app/session/services/globals, persistence |
| Private candidate | static ingestor | ingestor until validation | ingestor only | one call | caller until returned; global/application owners |
| Applied candidate | ingestor after validation | caller | future explicit ledger operation through another candidate | caller-defined runtime | `GameState` before P1; persistence before P1 |
| Run wrapper/T2 facts | simulation/run path | input caller | none in R1 | call/retained evidence | ledger as authority; persistence |
| Validator/ingestor | class-level static operation | none | no retained state | call-scoped | application/session/global state |
| R2 snapshot/history | not created | — | — | deferred | R1 |
| P1 durable ledger | not created | — | — | deferred | R1/R2 wiring |
| B combined candidate | not created | — | — | deferred | R1 |

## 13. Complete test oracle

### A. Factory, API, clone, validator

- nonnegative static factory, negative returns null;
- exact three-key validator success/failure grammar and fixed failure code;
- canonical empty ledgers at zero/nonzero cursors;
- deep clone/value equality without aliasing;
- malformed root cursors, mode sums, next sequence, slice order/overlap/maximality, per-mode slice coverage, channel containment/order, event sequence/time, and overflow.

### B. Wrapper and result grammar

- all committed modes apply and increment only their mode coverage;
- forecast/unknown mode, failed committed wrapper, projected state, null inner, parity mismatch, malformed T2 result, and null inputs receive the exact precedence/code;
- every success/no-op has empty error/details; every rejection has one listed non-empty `error_code`, non-empty `developer_details`, and null candidate;
- an otherwise valid `REJECTED` shape with empty `developer_details` fails the result-grammar test;
- malformed covered results reject before duplicate classification.

### C. Interval matrix

Cover every row in §9: zero at/behind/ahead, covered positive duplicate, partial overlap, forward gap, and exact-new.

### D. Canonical shape and source continuity

- half-open root/slice/channel intervals;
- chronological non-overlapping slices and rejection of adjacent merge-compatible slices;
- per-mode slice elapsed no greater than root mode coverage;
- identity stable for same Threshold/revision across mode/content splits;
- exact backlog continuity across mode, lifecycle, revision, content, inactive/timeline-only, and other-Threshold gaps;
- `SETTLED -> OVERDUE` rejection;
- one Settlement per Threshold and exact first zero-endpoint match;
- duplicate Settlement under another revision/content rejects;
- A -> B -> A episodes remain distinct while source endpoints continue;
- equal-output but component-distinct identities remain distinct;
- retinue order is identity.

### E. Channel continuity

- first appearance of a genuinely new channel;
- required later presence for every seen source;
- unchanged output/period;
- exact progress, carry, and total continuity across merge and split boundaries;
- independent regressions for period change, carry reset, progress reset, total reset, missing channel, and output mismatch;
- one-shot/chunked channel endpoints preserve first-before/final-after and equal ledger values.

### F. Settlement and event normalization

- bank events validate against endpoints and are not retained;
- Settlement event time may equal ledger end cursor, equals owning Overdue slice end, has contiguous sequence/nondecreasing time, and is unique per Threshold;
- malformed, unmatched, duplicate, out-of-order, or repeated Settlement rejects.

### G. Chunk invariance

Starting from equal empty ledgers, prove value equality for:

- active one-shot versus same-mode chunks;
- Settlement crossing versus chunks split at the boundary;
- timeline-only one-shot versus chunks;
- channel progress, rate carry, and whole banking one-shot versus chunks.

### H. Transactionality, ownership, and persistence exclusion

- every reject/no-op preserves source and all input facts without aliasing;
- failed candidate validation returns no candidate;
- checked overflow for mode duration, core deltas, channel totals, and event sequence;
- no `GameState` report field; schema writer remains v3;
- mapping/validators/migrations/fixtures/snapshots unchanged and serialized output excludes ledger symbols;
- no app/session/service/global retention or clock/file/scene/platform/storage access in `src/reports/`.

### I. Evidence

- focused R1 suites;
- full canonical GUT suite;
- import and main-scene smoke;
- deterministic trace covering apply/no-op/reject, source continuity, chunk equality, Settlement, folded bank events, overflow, and persistence exclusion;
- exact-head CI;
- exact-head Windows runner; no interactive checklist;
- cleanup/artifact audit and exact 32-path name/status set.

## 14. Proposed implementation surface

### Runtime

```text
src/reports/report_ledger.gd
src/reports/report_ledger_slice.gd
src/reports/report_ledger_channel.gd
src/reports/report_settlement_event.gd
src/reports/report_ledger_ingest_result.gd
src/reports/report_ledger_validator.gd
src/reports/report_ledger_ingestor.gd
```

Each `.gd` has one committed `.uid` companion.

### Tests and evidence

```text
tests/unit/m04e2r1/test_report_ledger.gd
tests/unit/m04e2r1/test_report_ledger_interval_matrix.gd
tests/unit/m04e2r1/test_report_ledger_ingestion.gd
tests/integration/m04e2r1/test_report_ledger_persistence_exclusion.gd
tools/test/m04e2r1/m04e2r1_report_ledger_trace.gd
tools/test/owner/run_m04e2r1_owner_verification.ps1
```

Each new test/trace `.gd` has one `.uid` companion.

### Documentation

```text
docs/codex/DECISIONS.md
docs/codex/MILESTONES.md
docs/codex/ARCHITECTURE.md
docs/codex/DATA_AND_CONTENT_CONTRACTS.md
docs/codex/TESTING_AND_VALIDATION.md
docs/codex/M04E2R1_PLANNING.md
docs/codex/milestone-prompts/M04E2R1-normalized-live-report-ledger.md
```

Documentation must remove or qualify current-looking examples that preapprove `ReportService`, `ReportAccumulatorState`, current `GameState` report ownership, or R2 archive commands. Explicitly historical A2/A3/A4 material remains historical.

The implementation packet contains the exact 32-path add/modify oracle. No other path is authorized without reassessment.

## 15. Scope assessment

| Dimension | Approved candidate boundary |
|---|---|
| Primary owner | One caller-owned report-ledger/ingestion family |
| Principal transition | ledger + committed run -> validated normalized candidate |
| New aggregate | One non-persisted `ReportLedger` family |
| Schema/content revision | None |
| Runtime seams | One: T2 facts -> ledger |
| Risk dimensions | temporal idempotency; checked normalization/continuity; alias/no-mutation/chunk invariance |
| New scripts | 13 plus `.uid` companions |
| Expected code/test delta | 1,000–1,450 lines excluding `.uid` |
| Player UI | None |
| Interactive owner checks | None |
| Implementation lane | GPT-5.6 Terra / High |

The 1,450-line figure is a mandatory stop-and-reassess threshold, not a completion quota. Do not compress continuity, malformed-input, or ownership proof to fit it.

## 16. Explicit exclusions and stop rules

R1 must not add or modify:

- `GameState` report ownership or application/session/service-retained ledger;
- schema v4, mapping, wire validation, migration, fixtures, save/load, checkpoints, storage;
- snapshots, archive/clear, records/history/retention/pruning, detached reads/view models/UI;
- offline-return classification or trusted-time orchestration;
- simulation formulas, transaction commit, T2 fields, modes, content, assignment behavior, concurrency, Halls, support, tutorial, progression, platform code;
- `ReportService`, singleton, autoload, hidden global, coordinator, production wiring;
- failed-branch production code or superseded A2/A3/A4 graphs.

Stop before implementation/publication when:

- live baseline materially differs;
- the exact 32-path set, 13 scripts, 1,450 lines, one owner/seam, or three risks would be exceeded;
- another schema/application/persistence/read-history surface is needed;
- chunk invariance or source continuity requires call-cadence-dependent detail beyond the approved endpoints;
- current mutable `GameState` would be needed to reconstruct history;
- source mutation, overlap slicing, rebasing, gap recovery, or application wiring becomes necessary;
- complete semantic/oracle content cannot fit the packet ceiling;
- required focused/full checks remain red;
- two substantial correction rounds fail to show local convergence.

## 17. Final assessment and owner-approval disposition

The same independent assessor returned **APPROVE** for G3 v0.3. It confirmed the exact rejection grammar, rechecked B1-B5, and found no remaining architecture, ownership, sequence, schema, API-signature, path-set, oracle, or implementation-lane blocker. No further scope-assessor pass was required.

On 2026-08-05, the owner explicitly approved proposed `DEC-0046` and M04E2R1 Slice Packet v0.3 for implementation on `codex/m04e2r1-normalized-live-report-ledger`, subject to the exact 32-path set, 13-script boundary, 1,450-line reassessment threshold, complete oracle, and exclusions.

The approved technical boundary remains unchanged: one principal transition, one caller-owned non-persisted ledger family, one runtime seam, schema version 3, and the exact scope ceilings. The packet is executable only by a separate transactional Implementation Codex task.

Required implementation sequence:

```text
explicit owner approval
-> separate transactional Implementation Codex task
-> exact branch and one PR
-> deterministic validation and CI
-> primary independent review
-> fresh PR-lifetime triage and bounded fixer contexts as needed
-> final review and exact-head owner evidence
-> owner integration
```

The planning architect will not implement this packet or serve as routine PR-lifetime triage for it.
