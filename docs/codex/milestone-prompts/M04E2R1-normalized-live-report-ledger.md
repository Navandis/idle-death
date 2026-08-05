# Slice M04E2R1: Normalized live report ledger and committed-run ingestion

## 1. Use and provenance

**Packet version/date:** v0.3 — 2026-08-05  
**Status:** Owner-approved v0.3; executable by a separate Implementation Codex task  
**Planning authority:** G3 planning memo v0.3 and owner-approved `DEC-0046`  
**Compatibility path when committed:** `docs/codex/milestone-prompts/M04E2R1-normalized-live-report-ledger.md`

The implementer reads root `AGENTS.md`, this packet, and only the manifest below. Semantic completeness outranks brevity and ceilings.

## 2. Identity and delivery metadata

```text
Parent sequence: M04E2T1 -> M04E2T2 -> M04E2R1 -> M04E2R2 -> M04E2P1 -> M04E2B
Expected verified baseline: main at 6d2e9247322798cb040659bc9c98b650d24ab69e
Feature branch: codex/m04e2r1-normalized-live-report-ledger
PR target/title: main / Implement M04E2R1 normalized live report ledger
Primary subsystem owner: caller-owned ReportLedger aggregate and stateless ingestion boundary
Risk dimensions: temporal idempotency; checked normalization/continuity; alias/no-mutation/chunk invariance
Runtime integration seams: one — finalized T2 run facts into the caller-owned ledger
Schema/content effect: none; schema version 3 and current content revision remain
Implementation model/effort: GPT-5.6 Terra / High
Output ceiling: exact 32-path set; 13 non-documentation scripts; 1,450 non-documentation lines excluding .uid is a stop-and-reassess threshold
Hard stop: publish one PR and report exact-head evidence; do not merge or perform owner administration
```

## 3. Objective and principal transition

Implement one typed, caller-owned, non-persisted `ReportLedger` that consumes a valid committed `SimulationRunResult` exactly once and returns a completely validated, chunk-invariant candidate without mutating the source ledger.

```text
caller-owned validated ledger + finalized committed run
-> private normalized candidate
-> complete ledger validation
-> APPLIED candidate or transactional no-op/rejection
```

Demonstration: same-mode one-shot/chunked runs yield value-equal ledgers; duplicates no-op; malformed, temporal-gap/overlap, forecast/projected, identity, backlog, and channel resets reject; schema v3 is unchanged.

## 4. Sole authoritative context manifest

| Priority | Source/path | Exact section/artifact | Why | Status |
|---:|---|---|---|---|
| 1 | Latest owner instruction | Approve v0.3 and proposed `DEC-0046` for the named branch and exact boundaries | Current authority | Inspect only |
| 2 | `AGENTS.md` | Full file | Universal router and stop rules | Inspect only |
| 3 | This packet | Full file | Executable scope and oracle | Add unchanged |
| 4 | G3 planning memo v0.3 | §§5–17 | Fields, API, continuity, ownership, rationale | Add as `M04E2R1_PLANNING.md` |
| 5 | `docs/codex/DECISIONS.md` | `DEC-0045`; current approval-state paragraph for superseded `DEC-0041`; add approved `DEC-0046` | Current sequence, historical boundary, R1 decision | Modify |
| 6 | `docs/codex/ARCHITECTURE.md` | §4 overview; §5.2 runtime examples; §7 `GameState`; §8.1 commands; `Current M04E2 report architecture (DEC-0045)` | Remove stale preapproval; state R1/R2/P1/B ownership | Modify |
| 7 | `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | §2.2 runtime examples; current R1/R2/P1/B paragraph; realized M04E2T2 typed-fact contract | Field and input grammar | Modify |
| 8 | `docs/codex/MILESTONES.md` | M04E2 status map; §7.1; M04E2R1 boundary | Sequence/status/completion | Modify |
| 9 | `docs/codex/TESTING_AND_VALIDATION.md` | §§3–4; current M04E2 status; add R1 oracle/evidence | Canonical commands and evidence | Modify |
| 10 | `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md` | Reaping Report definition; `IF-REQ-02`, `IF-REQ-03`, `IF-REQ-20` | No claim, no pause, component identity | Inspect only |
| 11 | `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md` | `P90-SAFE-06`, `P90-SAFE-11`, `P90-B06` | Prototype report behavior | Inspect only |
| 12 | `src/simulation/simulation_run_service.gd` | Full file | Wrapper/mode grammar | Inspect only |
| 13 | T2 result family | Exact paths below; projector `validate` and called helpers | Input facts/validation | Inspect only |
| 14 | `tests/unit/m04e2t2/test_simulation_result_facts.gd` | Exact tests below and called local helpers | Existing regressions | Inspect only |
| 15 | `tests/integration/m04e2t2/test_finalized_facts_persistence_exclusion.gd` | Full test | Schema-v3 exclusion | Inspect only |

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

Exact existing tests:

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

The `DEC-0045` approval paragraph is the only historical route; do not load `DEC-0041` directly. Exclude PR #17/#18/#23 production files, superseded A2/A3/A4 prompts/graphs, broad documents, transcripts, and unstated R2/P1/B detail.

### Exact changed-path/status set

```text
M  docs/codex/DECISIONS.md
M  docs/codex/MILESTONES.md
M  docs/codex/ARCHITECTURE.md
M  docs/codex/DATA_AND_CONTENT_CONTRACTS.md
M  docs/codex/TESTING_AND_VALIDATION.md
A  docs/codex/M04E2R1_PLANNING.md
A  docs/codex/milestone-prompts/M04E2R1-normalized-live-report-ledger.md
A  src/reports/report_ledger.gd
A  src/reports/report_ledger.gd.uid
A  src/reports/report_ledger_slice.gd
A  src/reports/report_ledger_slice.gd.uid
A  src/reports/report_ledger_channel.gd
A  src/reports/report_ledger_channel.gd.uid
A  src/reports/report_settlement_event.gd
A  src/reports/report_settlement_event.gd.uid
A  src/reports/report_ledger_ingest_result.gd
A  src/reports/report_ledger_ingest_result.gd.uid
A  src/reports/report_ledger_validator.gd
A  src/reports/report_ledger_validator.gd.uid
A  src/reports/report_ledger_ingestor.gd
A  src/reports/report_ledger_ingestor.gd.uid
A  tests/unit/m04e2r1/test_report_ledger.gd
A  tests/unit/m04e2r1/test_report_ledger.gd.uid
A  tests/unit/m04e2r1/test_report_ledger_interval_matrix.gd
A  tests/unit/m04e2r1/test_report_ledger_interval_matrix.gd.uid
A  tests/unit/m04e2r1/test_report_ledger_ingestion.gd
A  tests/unit/m04e2r1/test_report_ledger_ingestion.gd.uid
A  tests/integration/m04e2r1/test_report_ledger_persistence_exclusion.gd
A  tests/integration/m04e2r1/test_report_ledger_persistence_exclusion.gd.uid
A  tools/test/m04e2r1/m04e2r1_report_ledger_trace.gd
A  tools/test/m04e2r1/m04e2r1_report_ledger_trace.gd.uid
A  tools/test/owner/run_m04e2r1_owner_verification.ps1
```

No rename, substitution, or extra path is authorized.

## 5. Included scope, fields, and ownership

### Stored fields

`ReportLedger`:

```text
window_start_simulation_msec
ingested_through_simulation_msec
foreground_elapsed_msec
offline_elapsed_msec
debug_elapsed_msec
next_event_sequence
slices: Array[ReportLedgerSlice]
settlement_events: Array[ReportSettlementEvent]
```

`ReportLedgerSlice`:

```text
run_mode, content_revision, threshold_id, assignment_revision
form_id, writ_id, ordered_retinue_ids, lifecycle_state
start_simulation_msec, end_simulation_msec
returned_souls_delta, remaining_backlog_before, remaining_backlog_after
essence_delta, mastery_delta_subunits, completed_cycles_delta
channels: Array[ReportLedgerChannel]
```

`ReportLedgerChannel`:

```text
channel_id, output_item_id
start_simulation_msec, end_simulation_msec
progress_subunits_before, progress_subunits_after
rate_period_msec
rate_carry_units_before, rate_carry_units_after
total_banked_units_before, total_banked_units_after
```

`ReportSettlementEvent`:

```text
event_sequence, content_revision, threshold_id, assignment_revision
occurred_simulation_msec, persistent_returns_total
```

`ReportLedgerIngestResult`:

```text
success, changed, outcome, error_code, developer_details
candidate_ledger: ReportLedger or null
```

### Stored versus derived

| Value | Treatment | Reason |
|---|---|---|
| Cursor, mode coverage, identity, slice/core endpoints | Stored | Exactly-once continuity and attribution |
| Channel progress, rate period, carry, and total endpoints | Stored | Self-interpretable arithmetic continuity across runs |
| Settlement persistent-return total | Stored event | Not present elsewhere in normalized state |
| Elapsed, backlog reduction, channel banked delta, totals/counts/summaries | Derived | Exact from stored fields |
| Per-bank event detail | Validated then folded | Event count depends on call chunking |
| Snapshot/history/reads/retention | R2 | Separate transition |
| Schema/migration/persistence | P1 | Separate owner |
| Atomic gameplay/report candidate | B | Separate coordinator |

All stored channel fields participate in deep clone and value equality. The caller owns source/applied ledgers. Validator/ingestor retain nothing; exact-new work uses one private clone. Before P1, no `GameState`, app/session/service/global, mapper, or save owner retains it.

## 6. Exact public API and result grammar

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

Validator result grammar is exact:

```text
success: { "ok": true,  "code": &"", "details": "" }
failure: { "ok": false, "code": &"REPORT_LEDGER_VALIDATION_FAILED", "details": String }
```

Outcomes: `APPLIED`, `DUPLICATE_NO_OP`, `ZERO_DURATION_NO_OP`, `REJECTED`. Only `APPLIED` returns a candidate. Success/no-op has empty `error_code` and `developer_details`. `REJECTED` has `success == false`, `changed == false`, exactly one listed non-empty `error_code`, non-empty `developer_details`, and `candidate_ledger == null`.

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

Precedence: ledger required/valid; run required; committed mode; failed wrapper; projected state; inner presence/parity; T2 validation; interval. Forecast/unknown mode gets `MODE_REJECTED`; failed committed mode gets `RUN_FAILED`; successful committed mode with projection gets `PROJECTED_STATE_REJECTED`.

Successful wrapper parity is exactly:

```text
run.requested_elapsed_msec == inner.requested_elapsed_msec
inner.committed_elapsed_msec == run.requested_elapsed_msec
run.baseline_simulation_time_msec == inner.baseline_simulation_time_msec
run.result_simulation_time_msec == inner.result_simulation_time_msec
run.success == inner.success
run.result_simulation_time_msec - run.baseline_simulation_time_msec
    == inner.committed_elapsed_msec
```

Here `inner = run.simulation_result`; a successful wrapper with null inner is `WRAPPER_MISMATCH`.

## 7. Behavioral and transition requirements

### R1-01 — Canonical ledger shape

Root cursors/durations are nonnegative; checked mode-duration sum equals the window span; `next_event_sequence >= 1`. Slice/channel intervals are half-open. Slices are chronological, non-overlapping, and maximal: no adjacent pair is merge-compatible. Per-mode slice elapsed does not exceed root coverage. Channels are unique, ordered, and contained by their slice. Settlement events use `window_start < occurred <= ingested_through`, equal an owning Overdue slice end, have contiguous sequence/nondecreasing time, and remain below `next_event_sequence`.

### R1-02 — Interval decision table

After input validation, classify `[baseline, result)`:

- zero at cursor: `ZERO_DURATION_NO_OP`;
- zero/positive wholly behind cursor: `DUPLICATE_NO_OP`;
- zero/positive ahead: `FORWARD_GAP` rejection;
- partial overlap: rejection;
- positive exact baseline at cursor: candidate application;
- no slicing, rebasing, recovery, or interval-ID set.

Positive timeline-only and active zero-gain intervals still advance cursor and exact mode coverage. Every rejection has one listed non-empty `error_code`, non-empty `developer_details`, and null candidate.

### R1-03 — Source continuity before merge/append

Before merge/append, compare new active facts with the latest prior source facts:

- identity is stable for `(threshold_id, assignment_revision)` across modes/content revisions;
- Threshold backlog-after equals the next backlog-before, including after inactive/other-Threshold intervals;
- `SETTLED` never regresses to `OVERDUE`;
- the first Overdue zero endpoint has exactly one matching Settlement event;
- each Threshold settles at most once per window, irrespective of revision/content;
- every seen Threshold/channel appears in its next active fact and continues output, period, progress, carry, and totals;
- a genuinely new channel may first appear later with its own start endpoint.

Use `IDENTITY_MISMATCH`, `SLICE_DISCONTINUITY`, or `CHANNEL_DISCONTINUITY`.

### R1-04 — Chunk-invariant normalization

Store maximal slices by mode, content, Threshold, revision, component identity, and lifecycle. Retain first-before/final-after endpoints, checked-add core deltas, unchanged channel period, folded bank events, and one Settlement event. Same-mode one-shot/chunked results must be value-equal.

### R1-05 — Transactionality and validation

No-op/rejection preserves every input. Use checked arithmetic; return only a completely valid candidate.

### R1-06 — Persistence and ownership exclusion

Schema remains v3. `GameState`, persistence code/fixtures/snapshots remain unchanged and ledger-free. `src/reports/` has no app/global owner or I/O/clock/scene/platform dependency.

### R1-07 — Durable documentation alignment

Add accepted `DEC-0046`, planning/packet, milestone, contracts, and oracle. Qualify current-looking `ReportService`, `ReportAccumulatorState`, `GameState` report, or R2 archive examples. Preserve historical A2/A3/A4 and `DEC-0041` only as non-executable evidence.

## 8. Explicit exclusions

Do not add or modify:

- `GameState` report fields, schema v4, mapping, wire validation, migration, fixtures, save/load, checkpoints, or storage;
- snapshots, archive/clear, records/history/retention/pruning, detached reads/view models/UI;
- trusted-time/offline orchestration, application/session wiring, coordinator, singleton/autoload, hidden global, or `ReportService`;
- simulation formula/result/mode/content/assignment/concurrency behavior;
- tutorial, progression, Halls, support, analytics, or platform behavior;
- partial-overlap slicing, rebasing, gap recovery, failed-branch production reuse, or R2/P1/B work.

## 9. Acceptance and test oracle

| AC | Observable pass condition | Evidence |
|---|---|---|
| AC-01 | Static factory accepts nonnegative cursor; negative returns null; canonical ledgers validate; clone/equality are deep | ledger unit tests |
| AC-02 | Exact validator grammar; malformed cursor/duration/order/overlap/maximality/mode-coverage/channel/event/overflow shapes reject | ledger unit tests |
| AC-03 | Wrapper parity is exact; all rejects have one listed non-empty `error_code`, non-empty `developer_details`, null candidate, unchanged inputs; empty details fails | interval tests |
| AC-04 | Every zero/duplicate/partial/gap/exact-new row matches R1-02 | table-driven interval tests |
| AC-05 | Timeline-only and active no-gain intervals advance exact cursor/mode coverage | interval/ingestion tests |
| AC-06 | Identity, backlog, lifecycle, and Settlement continuity hold across mode/content/revision/lifecycle splits, inactive/timeline gaps, and other-Threshold intervals | ingestion tests |
| AC-07 | Retinue order and component identity remain distinct, including equal-output and A -> B -> A episodes | ingestion tests |
| AC-08 | Channel first appearance works; later absence, output/period/progress/carry/total reset or mismatch rejects; one-shot/chunk carry endpoints agree | ingestion tests |
| AC-09 | Settlement retained exactly once per Threshold, including other revision/content, with stable sequence/time; bank events folded | ingestion tests/trace |
| AC-10 | One-shot equals same-mode chunks for active, Settlement-crossing, timeline-only, and channel progress/banking | equality tests/trace |
| AC-11 | Every no-op/reject/alias and checked-overflow case preserves all inputs | unit tests |
| AC-12 | `GameState`, schema v3, mapping, migrations, fixtures, and serialized snapshots remain unchanged and exclude ledger names | integration test |
| AC-13 | Actual name/status set equals the exact 32-path oracle; no rename/substitution/extra path; planning and packet match exact v0.3 artifacts | diff/artifact audit |
| AC-14 | Focused R1 tests, full `tools/test/run_gut.sh`, import, and smoke pass | implementer/CI |
| AC-15 | Trace proves apply/no-op/reject/source continuity/chunk equality/persistence exclusion/overflow | trace |
| AC-16 | Exact-head Windows runner passes full/focused/trace/import/cleanup; no interactive checklist | owner evidence |
| AC-17 | Durable docs contain accepted `DEC-0046` and no current-looking ReportService/GameState/R2 preapproval | occurrence/link audit |
| AC-18 | Primary review, triage/fix/rereview, convergence, final review, owner evidence, and integration follow the packet flow | PR record |

## 10. Scope, convergence, delivery, and owner interface

```text
Primary owners: 1
Authoritative aggregates: 1 caller-owned non-persisted family
Schema transitions: 0
Risk dimensions: 3
Runtime seams: 1
New non-documentation scripts: 13 plus required .uid companions
Expected non-documentation delta: 1,000–1,450 lines excluding .uid
Interactive owner surface: none
```

Stop before path expansion, >13 scripts, >1,450 lines, another owner/seam/risk/schema/application/persistence/read-history surface, or oracle weakening. The line ceiling triggers reassessment; never compress continuity/malformed coverage.

```text
planning architect
-> fresh scope assessor
-> explicit owner approval
-> separate transactional implementer
-> PR + exact-head CI
-> owner/architect exact-head primary-review request
-> independent reviewer
-> persisted findings -> fresh PR-lifetime triage
-> bounded fresh fixer when required
-> new-head CI/rereview -> triage/convergence
-> final unrestricted review
-> material-thread reconciliation
-> exact-head Windows owner runner
-> owner merge and post-merge CI
```

Use non-force publication. Relevant commits invalidate review; any commit invalidates owner evidence. Merge/close/delete/force/replace/rewrite are owner-only. After two substantial correction rounds, assess convergence.

Owner verification:

```text
Purpose: verify exact R1 head on Windows
Run: tools/test/owner/run_m04e2r1_owner_verification.ps1 with expected SHA and Godot console path
Return: PASS/FAIL, exact SHA, generated log path, failed-step count
Stop only if: SHA mismatch, dirty tree, missing dependency, command failure, or artifact remains
```

## 11. Final response contract

Report result; exact path statuses; commands actually run; focused/full/trace/import/smoke results; branch/PR/head; CI; assumptions; pending owner evidence; deferred R2/P1/B work; clean tree/staged state; and the hard stop without merge.
