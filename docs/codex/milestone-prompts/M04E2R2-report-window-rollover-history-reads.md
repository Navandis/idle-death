# Slice M04E2R2: Report-window rollover, bounded history, and detached reads

## 1. Use and provenance

**Packet version/date:** v0.3 - 2026-08-09\
**Status:** Owner-approved v0.3; assessed and rereviewed; separately authorized for implementation\
**Planning authority:** Accepted `DEC-0047`; owner-approved `M04E2R2_PLANNING.md` v0.3; owner decisions of 2026-08-09\
**Repository path when committed:** `docs/codex/milestone-prompts/M04E2R2-report-window-rollover-history-reads.md`

Owner approval covers `DEC-0047`, retention eight, the complete concept/path authority, category stops, the `3,600` aggregate stop, this packet, and separate implementation. No initial exception exists.

## 2. Identity and delivery metadata

```text
Parent sequence: M04E2T1 -> M04E2T2 -> M04E2R1 -> M04E2R2 -> M04E2P1 -> M04E2B
Expected verified baseline: main at a2a5fab97f98a121495aa2c588d63b0ea5b7c6c1; reverify before implementation
Feature branch: codex/m04e2r2-report-rollover-history-reads
PR target/title: main / Implement M04E2R2 report rollover, history, and detached reads
Primary subsystem owner: existing caller-owned ReportLedger aggregate family
Risk dimensions: transactional rollover/aliasing; cross-window continuity after compaction; bounded-history/read ordering
Integration seams: 2 - R1 ingestor/validator to compact continuation; ledger lifecycle to snapshotter/reader
Implementation actor: Transactional Implementation Codex
Recommended model: Codex Terra
Effort: High
Session: FRESH
Session rationale: architecture-sensitive runtime-state extension with a finite exact oracle; no implementation continuity is required
Output ceiling: exact 37 paths; 18 governed paths; 13 new scripts; approved 3,600-addition stop; no initial exception
Hard stop: publish one draft PR and report exact-head evidence; do not merge or perform owner administration
```

## 3. Objective, outcome, and principal transition

Extend the existing non-persisted `ReportLedger` with one deterministic rollover transition, compact Threshold/channel continuation state, an eight-record retained-history suffix, and pure detached live/history reads.

Developer outcome: ingest, snapshot, read, prune, and continue report facts without mutating sources, losing the R1 continuity oracle, adding persistence, or claim-gating gains.

```text
validated caller-owned ledger + expected report cursor
-> private candidate
-> exact detached, deeply owned window record
-> bounded retained suffix
-> empty next live window at unchanged cursor
-> preserved compact continuation
-> complete validation
-> APPLIED candidate, EMPTY_NO_OP, or REJECTED
```

## 4. Sole authoritative context manifest

| Priority | Source/path | Exact section or artifact | Why | Status |
|---:|---|---|---|---|
| 1 | Latest owner instruction | Approve `DEC-0047`, retention eight, packet v0.3, scoped thresholds, and separate implementation | Current authority | Inspect only |
| 2 | `AGENTS.md` | Full file | Universal router and stop rules | Inspect only |
| 3 | Quantitative policy | Sections 4-11 and 13-16 | Concepts, forecast, threshold, evidence floor | Inspect only |
| 4 | This packet | Full file | Executable authority after approval | Add unchanged |
| 5 | `M04E2R2_PLANNING.md` | Owner-approved v0.3 sections 4-17 | Design, rationale, oracle | Add unchanged |
| 6 | `DECISIONS.md` | `DEC-0045`, `DEC-0046`; add approved `DEC-0047`; correct stale section 3 status | Sequence and ownership | Modify |
| 7 | `MILESTONES.md` | M04E2 table, section 7.1, R1/R2 boundary | Status and dependency | Modify |
| 8 | `ARCHITECTURE.md` | Current report architecture; Reports row; sections 19.1-19.3 | Caller-owned R2/P1/B separation | Modify |
| 9 | `DATA_AND_CONTENT_CONTRACTS.md` | Current R1 contract; canonical IDs; add R2 values | State grammar | Modify |
| 10 | `TESTING_AND_VALIDATION.md` | Current R1 oracle; report section; R2 boundary | Evidence | Modify |
| 11 | `src/reports/report_ledger.gd` | Full file | Existing root, clone, equality | Modify |
| 12 | `src/reports/report_ledger_ingestor.gd` | Full file | Existing public transition/error grammar | Modify |
| 13 | `src/reports/report_ledger_validator.gd` | Full file | Single runtime semantic authority | Modify |
| 14 | R1 child types | Slice, channel, Settlement files | Reused record children | Inspect only |
| 15 | R1 tests | Exact two modified files plus remaining R1 suites | Regression floor | Modify/inspect |
| 16 | Design sources | `IF-REQ-02`, `IF-REQ-03`, `IF-REQ-20`; `P90-SAFE-06`, `P90-SAFE-11`, `P90-B06` | No claim/pause; identity; first report | Inspect only |

Exclude concrete `DEC-0041`, A2/A3/A4 plans/prompts, PR #17/#18/#23 production code, failed implementations, broad transcripts, P1/B material, and historical accumulator/snapshot examples.

### Exact changed-path/status set

```text
M  docs/codex/DECISIONS.md
M  docs/codex/MILESTONES.md
M  docs/codex/ARCHITECTURE.md
M  docs/codex/DATA_AND_CONTENT_CONTRACTS.md
M  docs/codex/TESTING_AND_VALIDATION.md
A  docs/codex/M04E2R2_PLANNING.md
A  docs/codex/milestone-prompts/M04E2R2-report-window-rollover-history-reads.md
M  src/reports/report_ledger.gd
M  src/reports/report_ledger_ingestor.gd
M  src/reports/report_ledger_validator.gd
A  src/reports/report_window_record.gd
A  src/reports/report_window_record.gd.uid
A  src/reports/report_threshold_continuation.gd
A  src/reports/report_threshold_continuation.gd.uid
A  src/reports/report_channel_continuation.gd
A  src/reports/report_channel_continuation.gd.uid
A  src/reports/report_ledger_snapshot_result.gd
A  src/reports/report_ledger_snapshot_result.gd.uid
A  src/reports/report_ledger_snapshotter.gd
A  src/reports/report_ledger_snapshotter.gd.uid
A  src/reports/report_ledger_reader.gd
A  src/reports/report_ledger_reader.gd.uid
M  tests/unit/m04e2r1/test_report_ledger.gd
M  tests/unit/m04e2r1/test_report_ledger_ingestion.gd
A  tests/unit/m04e2r2/test_report_ledger_r2_state.gd
A  tests/unit/m04e2r2/test_report_ledger_r2_state.gd.uid
A  tests/unit/m04e2r2/test_report_ledger_snapshot.gd
A  tests/unit/m04e2r2/test_report_ledger_snapshot.gd.uid
A  tests/unit/m04e2r2/test_report_ledger_reads.gd
A  tests/unit/m04e2r2/test_report_ledger_reads.gd.uid
A  tests/integration/m04e2r2/test_report_ledger_rollover_ingestion.gd
A  tests/integration/m04e2r2/test_report_ledger_rollover_ingestion.gd.uid
A  tests/integration/m04e2r2/test_report_ledger_persistence_exclusion.gd
A  tests/integration/m04e2r2/test_report_ledger_persistence_exclusion.gd.uid
A  tools/test/m04e2r2/m04e2r2_report_history_trace.gd
A  tools/test/m04e2r2/m04e2r2_report_history_trace.gd.uid
A  tools/test/owner/run_m04e2r2_owner_verification.ps1
```

## 5. Included scope and ownership

### Authoritative runtime additions

`ReportLedger` adds:

```text
MAX_RETAINED_RECORDS = 8
next_record_sequence: int
retained_records: Array[ReportWindowRecord]
threshold_continuations: Array[ReportThresholdContinuation]
```

`ReportWindowRecord` stores sequence, window cursors, three mode durations, detached R1 slices, and detached Settlement events.

`ReportThresholdContinuation` stores latest revision/component identity, lifecycle, backlog endpoint, settled knowledge, and ordered channel continuations. Each channel continuation stores ID/output/period and latest progress/carry/banked endpoints.

Source and applied ledgers remain caller-owned and non-persisted. Ingestor/snapshotter mutate only private candidates. Reader returns detached values and retains nothing. `ReportLedgerValidator` remains the sole semantic validator.

### Stored versus derived

| Value/fact | Treatment | Owner | Persisted in R2 | Reason |
|---|---|---|---|---|
| Live R1 window | Stored | ledger | No | Current report facts |
| Record sequence and retained records | Stored | ledger | No | Stable bounded history |
| Latest Threshold/channel continuation | Stored | ledger | No | Safe later ingestion after pruning |
| Record elapsed/event-next/pruned count | Derivable but not exposed by R2 readers | no stored authority | No | Exact mathematics only; later exposure requires new counted authority |
| Core/channel totals and reductions | Derivable but not exposed by R2 readers | no stored authority | No | Avoid duplicate authority and presentation-scope expansion |
| Player disclosure/formatting | Deferred | presentation | No | Later UI authority |
| Schema/save form | Deferred to P1 | persistence | No | Separate owner |

Schema/content revision effect: none. Schema remains 3; content unchanged.

Verification: focused R1+R2 tests, full GUT, import, smoke, deterministic trace, exact-head CI, and exact-head Windows owner package. No checklist.

## 6. Explicit exclusions

No `GameState` report field, schema v4, mapper, wire validator, migration, save fixture, codec/storage/checkpoint, application/session/service/global retention, trusted-time classification, simulation formula/fact change, atomic coordinator, report UI, disclosure/localization/formatting, claim, acknowledgement, delete, partial clear, permanent analytics, second validator, generic report framework, or historical-route reuse.

## 7. Behavioral and transition requirements

### R2-01 - Canonical extended ledger

Capacity is exactly eight. `next_record_sequence >= 1`. Retained records are an ascending contiguous suffix ending at `next_record_sequence - 1`, size at most eight. Threshold/channel continuations are canonical-ID ordered and duplicate-free. Clone/equality include every new field and child.

### R2-02 - Window-record contract

Stored records have positive sequence. Window cursors/durations are nonnegative and checked; mode sum equals span. Slices/events satisfy the R1 window grammar. Projection copies live start, cursor-as-end, three mode durations, slices, and Settlement events; adds positive `record_sequence`; omits stored `next_event_sequence`; requires derived event-next equality; and excludes history/continuation. A record contains no nested ledger or summary. Production does not mutate it after insertion; detached live reads use sequence zero only.

### R2-03 - Compact continuation

Every accepted active Threshold has one continuation. Same revision requires exact component identity; greater revision may change identity; lower revision rejects as `REPORT_INGEST_IDENTITY_MISMATCH`. Backlog/lifecycle/channel/Settlement continuity follows the approved planning memo. New channels may appear once and then become required.

### R2-04 - Ingestion transaction

R1 wrapper/result/interval precedence remains unchanged. Exact-new ingestion updates live facts and continuation in one private candidate. No-op/rejection preserves ledger, records, continuations, wrapper, inner facts, and children. Candidate returns only after complete validation.

### R2-05 - Rollover API and grammar

```text
ReportLedgerSnapshotter.rollover(source_ledger, expected_cursor_msec)
    -> ReportLedgerSnapshotResult
```

Outcomes: `APPLIED`, `EMPTY_NO_OP`, `REJECTED`. Only `APPLIED` returns a candidate and positive created sequence. Stable errors:

```text
REPORT_SNAPSHOT_LEDGER_REQUIRED
REPORT_SNAPSHOT_LEDGER_INVALID
REPORT_SNAPSHOT_CURSOR_INVALID
REPORT_SNAPSHOT_CURSOR_MISMATCH
REPORT_SNAPSHOT_SEQUENCE_OVERFLOW
REPORT_SNAPSHOT_CANDIDATE_INVALID
```

Precedence is source required/valid, cursor nonnegative/equal, empty classification, sequence/candidate, complete validation.

### R2-06 - Applied rollover

Copy the complete live window into one record; increment sequence; append; prune whole oldest records to eight; reset only the live window to canonical empty at unchanged cursor; preserve continuation value-equal; validate; return candidate. Positive timeline-only windows apply. Empty windows no-op idempotently. No slicing, partial clear, rebase, or recovery.

### R2-07 - Retention

Sequences never reset or reuse. Pruning edits no retained record, live fact, or continuation. Pruned count is derived. Safe future ingestion must not depend on retained old detail.

### R2-08 - Detached reader

```text
read_live_window -> {ok, code, details, window}
read_history -> {ok, code, details, records}
read_record -> {ok, found, code, details, record}
```

Errors: `REPORT_READ_LEDGER_REQUIRED`, `REPORT_READ_LEDGER_INVALID`, `REPORT_READ_SEQUENCE_INVALID`. Missing positive sequence is successful `found=false`. Reads validate source, return deep copies in canonical order, mutate/cache nothing, and expose no continuation state. The three exact payloads contain stored record facts only: no elapsed, event-next, pruned count, total, summary, label, filtering, formatting, or presentation field.

### R2-09 - One validator

The current validator owns live, record, history, continuation, detailed-suffix continuity, and latest-detail-to-continuation agreement. Operations do not add parallel semantic validators.

### R2-10 - R2/P1/B boundary

No persistence, `GameState`, application owner, coordinator, or UI. Serialized snapshots exclude every R2 symbol. P1/B remain deferred.

## 8. Acceptance and test oracle

| AC | Observable pass condition | Evidence | Executor |
|---|---|---|---|
| AC-01 | Every new root/child field has isolated clone/equality and validator coverage | R2 state unit test | Implementer/CI |
| AC-02 | Same-revision mismatch and lower revision reject; non-contiguous greater revision applies with literal identity and preserved endpoints | R1 ingestion regression + rollover integration | Implementer/CI |
| AC-03 | The complete literal continuity matrix below passes after rollover and again after pruning the introducing record; every reject proves complete no-mutation | Integration matrix | Implementer/CI |
| AC-04 | Operational and timeline-only rollover satisfy the exact live-to-record projection, derived event-next, absent history/continuation, and canonical empty next window | Snapshot unit test | Implementer/CI |
| AC-05 | Empty redelivery no-ops; invalid/mismatched cursor and sequence overflow reject with exact grammar | Snapshot unit test | Implementer/CI |
| AC-06 | Capacity eight prunes only whole oldest records; retained suffix and sequences remain exact | Snapshot/retention matrix | Implementer/CI |
| AC-07 | Continuation-only baselines preserve every R1 rejection and both positive cases after introducing detail is pruned | Integration matrix | Implementer/CI |
| AC-08 | Live/history/record reads return stored facts only, are exact, ordered, detached, pure, and use exact not-found grammar | Reader unit test | Implementer/CI |
| AC-09 | Settlement uniqueness and already-Settled behavior survive rollover and pruning | Integration test | Implementer/CI |
| AC-10 | Equivalent one-shot/chunked runs project to value-equal records | Integration test | Implementer/CI |
| AC-11 | Every no-op/reject preserves all source and input roots/children/references; no alias escapes | All focused suites | Implementer/CI |
| AC-12 | Schema 3, `GameState`, mapper/migrations/fixtures/serialization exclude R2 | Persistence-exclusion test | Implementer/CI |
| AC-13 | Exact 37-path set and forbidden dependency/symbol audit pass | Path/ownership audit | Implementer/CI |
| AC-14 | Deterministic trace earns exact markers for apply, no-op, retention, reads, continuity, pruning, Settlement, equivalence, overflow, exclusion | R2 trace | Implementer/CI/Owner |
| AC-15 | Focused R1+R2 and full GUT, import, smoke, cleanup, artifact and diff checks pass | Canonical wrappers/runner | Implementer/CI/Owner |
| AC-16 | Stale R1 status is corrected and current R2/P1/B authority is consistent | Documentation audit/link check | Implementer/reviewer |
| AC-17 | CI passes at exact PR head; owner Windows package passes same head with retained ignored log | GitHub Actions + owner result | CI/Owner |

### Required literal continuity matrix

Run every row from (a) a post-rollover baseline with the introducing record retained and (b) a post-pruning continuation-only baseline. Use literal source/input/expected witnesses, not production-algorithm mirroring.

```text
same-revision Form/Writ/Retinue mismatch -> IDENTITY_MISMATCH
lower revision -> IDENTITY_MISMATCH
non-contiguous greater revision -> APPLIED; exact new identity/revision, unchanged backlog/channel endpoints
backlog mismatch -> SLICE_DISCONTINUITY
SETTLED to OVERDUE -> SLICE_DISCONTINUITY
missing prior channel -> CHANNEL_DISCONTINUITY
output mismatch -> CHANNEL_DISCONTINUITY
period mismatch -> CHANNEL_DISCONTINUITY
progress mismatch -> CHANNEL_DISCONTINUITY
carry mismatch -> CHANNEL_DISCONTINUITY
total mismatch -> CHANNEL_DISCONTINUITY
duplicate Settlement -> SLICE_DISCONTINUITY
new channel first appearance -> APPLIED with every supplied endpoint
newly introduced channel missing next time -> CHANNEL_DISCONTINUITY
```

Final test/assertion counts are frozen only after the focused oracle is complete.

## 9. Scope, convergence, and escalation guards

### 9.1 Concept declaration

```text
Hard boundaries: no another owner/aggregate family/schema/dependency/P1/B/UI or path outside set
Primary owners: 1 existing ReportLedger family
Authoritative aggregate families: 1 total; 0 new
Authoritative child concepts: 3 - record, Threshold continuation, channel continuation
Public operation boundaries: 2 - snapshotter and reader
Public entry points: 4 - rollover plus three reads
New result grammars: 4 - one typed snapshot result plus three exact reader dictionaries
Schema transitions: 0
Dependencies/platform bridges: 0
Production abstraction layers: 0
Test-only helper concepts: 0
Verification-tool concepts: 1
```

### 9.2 Forecast

| Category | Adds | Deletes | Paths | Threshold | Concepts |
|---|---:|---:|---:|---:|---|
| Production runtime | 700-1,000 | 0-120 | 9 | 1,050 | child values, snapshot, reads |
| Tests/evidence | 1,250-1,750 | 0-150 | 7 | 1,850 | literal projection and full rollover/pruning matrix |
| Verification tooling | 500-650 | 0-80 | 2 | 700 | trace/owner package; R1 baseline is approximately 489 lines |
| Documentation | 1,200-1,500 | 100-250 | 7 | 1,600 | owner-approved memo and packet total approximately 1,135 lines before maintained edits |
| Data | 0 | 0 | 0 | 0 | none |
| **Governed non-doc total** | **2,450-3,400** | **0-350** | **18** | **3,600** | - |

Review-zone status: reassessment complete; same-assessor **APPROVE**; one coherent slice; credible `2,450-3,400` range.\
Mandatory-reassessment status: resolved; owner-approved `3,600` packet stop.\
Delegated variance: none.\
Approved exception: none; any category, aggregate, path, or concept crossing uses the policy route before publication.\
Acceptance floor: complete rollover, continuity-after-pruning, detachment, malformed/no-mutation, equivalence, exclusion, trace, CI, and owner evidence may not be weakened.

Stop before publication if any concept/path/category threshold is crossed. Retain the complete policy exception report and request only the smallest exact variance. Any owner/schema/public-contract/dependency/trust-boundary crossing returns to planning rather than a numeric exception.

Same-assessor rereview completed with **APPROVE**. A fresh assessment and owner decision are required if paths, ownership, aggregates, public contracts, schema, oracle model, or decomposition change. First PR triage uses `FRESH THEN PR-LIFETIME`. After two substantial correction rounds, retained triage performs convergence assessment. One branch and one PR remain throughout.

## 10. Delivery, review, verification, and owner interface

```text
owner-approved v0.3 packet
-> fresh Terra/High implementer
-> draft PR
-> exact-head CI
-> primary GitHub Codex review
-> fresh PR-lifetime Sol Pro/High triage
-> bounded fixer/rereview as needed
-> final unrestricted review and thread reconciliation
-> exact-head Windows owner verification
-> owner integration
```

PR body states objective, paths, categorized measurements, checks run, exclusions, head, and pending owner evidence. Any code/contract commit invalidates final review and owner verification.

Owner-only: approval/authorization, integration, destructive or force/history operations, credentials, governance, and spending.

Hard stop: publish; do not merge.

## 11. Final response contract

```text
Result
Paths
Categorized measurements and concepts
Verification actually run
Branch / PR / exact head
Assumptions
Pending evidence
Limitations and deferred work
Hard stop reached
```
