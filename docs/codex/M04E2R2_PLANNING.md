# Death Idle G5 - M04E2R2 Planning v0.3

**Date:** 2026-08-09\
**Status:** Owner-approved v0.3; independent assessment and bounded rereview complete; `DEC-0047`, retention capacity, concept/path authority, quantitative thresholds, packet authority, and separate implementation authorization approved on 2026-08-09\
**Planning owner:** Long-lived Death Idle planning architect\
**Repository:** `Navandis/idle-death`\
**Verified planning baseline:** remote `main` at `a2a5fab97f98a121495aa2c588d63b0ea5b7c6c1`\
**Parent sequence:** `M04E2T1 -> M04E2T2 -> M04E2R1 -> M04E2R2 -> M04E2P1 -> M04E2B`\
**Approved packet:** `docs/codex/milestone-prompts/M04E2R2-report-window-rollover-history-reads.md` v0.3

## 1. Current state and planning boundary

M04E2R1 is Merged/Passed through PR #34. The repository has one caller-owned, non-persisted `ReportLedger`, a stateless committed-run ingestor, one runtime validator, exact R1 continuity and transactionality tests, a deterministic trace, and an owner-verification package.

M04E2R2 is the next bounded slice. It now has owner-approved `DEC-0047`, this planning memo, the v0.3 slice packet, `MAX_RETAINED_RECORDS = 8`, the exact concept/path authority, the categorized thresholds, and separate implementation authorization. No implementation branch, pull request, implementation result, CI evidence, review, or owner verification exists yet.

Independent assessment v0.1 returned **APPROVE WITH BOUNDED CORRECTIONS** and found no architecture blocker. Candidate v0.2 incorporated all six bounded corrections. The same assessor then returned **APPROVE**, confirmed one coherent slice, supported the `3,600` governed-addition stop-and-reassess threshold, and recommended no initial exception.

On 2026-08-09, the owner approved `DEC-0047`, retention capacity eight, the complete concept and exact 37-path authority, the categorized forecasts and stops, the `3,600` aggregate threshold with no initial exception, this packet, and implementation by a separate fresh transactional actor. The planning architect remains outside implementation, routine PR-lifetime triage, independent review, and owner integration.

R2 must add snapshot/rollover, bounded in-memory history, retention, and detached reads to the same explicit ledger. It must not add `GameState` ownership, schema version 4, migration, persistence, application/session retention, trusted-time orchestration, report UI, claim behavior, or the B atomic coordinator.

## 2. Readiness disposition and authority reconciliation

Stage 0 concluded **READY FOR STAGE 1**.

The semantic authority is coherent:

```text
R1: caller-owned live ledger and committed-run ingestion
R2: snapshot/rollover, bounded history, retention, detached reads
P1: GameState ownership, schema v4, migration, persistence
B: atomic simulation/report coordination
```

Four current-looking status passages remain stale and must receive status-only correction in the eventual R2 documentation update:

- `docs/codex/DECISIONS.md` section 3;
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` section 1;
- the later current-report section of `docs/codex/ARCHITECTURE.md`;
- the header/current-status section of `docs/codex/TESTING_AND_VALIDATION.md`.

They describe R1 as in progress or partially verified. They do not override the current milestone map and merged PR #34 evidence establishing R1 as Merged/Passed.

## 3. Sole planning context manifest

Historical A2/A3/A4 bodies, concrete `DEC-0041`, failed PR production code, and architect transcripts were excluded. No unresolved question required them.

| Priority | Source | Exact authority used | Role |
|---:|---|---|---|
| 1 | Latest owner instruction | Approve `DEC-0047`, retention eight, concept/path authority, quantitative thresholds, packet v0.3, and separate implementation authorization | Current authority |
| 2 | `AGENTS.md` | Full file | Universal ownership, scope, validation, and stop router |
| 3 | `docs/codex/STANDARD_MILESTONE_SLICE_WORKFLOW.md` | Stages 0-3; packet, assessment, and actor-separation rules | Planning and approval lifecycle |
| 4 | `docs/codex/QUANTITATIVE_SCOPE_BUDGETS_AND_ANTI_BLOAT_GUARDRAILS.md` | Sections 4-11 and 13-16 | Concept budget, categorized forecast, threshold, evidence floor, and exception route |
| 5 | `docs/codex/ACTOR_PROMPT_STANDARD.md` | Sections 1-5 and 8 | Actor/model/effort/session routing |
| 6 | `docs/codex/DECISIONS.md` | `DEC-0045`, `DEC-0046`, section 3 | R1/R2/P1/B sequence and ownership |
| 7 | `docs/codex/MILESTONES.md` | Sections 3.1, 5, 6, 7.1, 8.3; R1 closure and R2 row | Current status and scope gate |
| 8 | `docs/codex/ARCHITECTURE.md` | Current M04E2 architecture; Reports row; sections 19.1-19.3 | Caller-owned/non-persisted R2 boundary |
| 9 | `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | Current R1 typed-fact contract and canonical-ID rules | Current data grammar |
| 10 | `docs/codex/TESTING_AND_VALIDATION.md` | Report/forecast section; current R1 oracle; R2/P1/B validation boundary | Evidence floor |
| 11 | `docs/codex/M04E2R1_PLANNING.md` | Sections 4-7 and 10-16 | Completed R1 fields, API, continuity, ownership, and exclusions |
| 12 | R1 packet | Sections 3-10 | Completed executable R1 contract; R2 exclusions |
| 13 | `src/reports/report_ledger.gd` | Full file | Current live-window root and clone/equality behavior |
| 14 | `src/reports/report_ledger_ingestor.gd` | Full file | Current committed-run transition and continuity checks |
| 15 | `src/reports/report_ledger_validator.gd` | Full file | Single runtime semantic authority |
| 16 | R1 child values | `report_ledger_slice.gd`, `report_ledger_channel.gd`, `report_settlement_event.gd` | Current stored facts |
| 17 | R1 tests and trace | Exact R1 unit/integration paths and trace | Realized oracle and fixture seams |
| 18 | `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md` | Reaping Report definition; `IF-REQ-02`, `IF-REQ-03`, `IF-REQ-20` | No claim, no pause, component identity |
| 19 | `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md` | `P90-SAFE-06`, `P90-SAFE-11`, `P90-B06` | Prototype report behavior |

## 4. Principal result

### Objective

Extend the existing caller-owned, non-persisted `ReportLedger` with one deterministic report-window rollover transition, compact cross-window continuation state, a bounded retained-record suffix, and pure detached reads.

### Principal transition

```text
validated caller-owned ReportLedger + exact expected report cursor
-> private candidate
-> detached, deeply owned record of the complete live window
-> bounded retained-history suffix
-> empty next live window at the same cursor
-> unchanged compact continuation endpoints
-> complete runtime-ledger validation
-> APPLIED candidate, EMPTY_NO_OP, or transactional REJECTED
```

### Developer demonstration

Starting from an empty ledger at cursor `0`:

1. ingest a committed active interval;
2. roll the non-empty live window into record sequence `1`;
3. observe an empty live window at the unchanged cursor;
4. read the live window, complete retained history, and record `1` as detached values;
5. ingest a later same-revision interval and prove exact endpoint continuity through compact continuation state;
6. ingest a higher assignment revision and prove new component identity is accepted;
7. attempt a lower revision, backlog reset, lifecycle regression, missing channel, period/progress/carry/total reset, or duplicate Settlement and prove exact rejection without mutation;
8. create more than eight records, prove whole-oldest pruning and non-reused record sequence;
9. prove continuity still rejects bad facts after the relevant detailed record was pruned;
10. prove schema version 3 and `GameState` remain unchanged.

## 5. Accepted decision: `DEC-0047`

### Title

`DEC-0047 - Caller-owned report-window rollover, compact continuation state, bounded history, and detached reads`

### Status

**Accepted by the owner on 2026-08-09.** The implementation slice adds this record to `DECISIONS.md` as Accepted and may not broaden or reinterpret it.

### Decision

#### 5.1 Same primary owner

R2 extends the existing caller-owned `ReportLedger` family. The caller owns source and applied ledger references. Snapshot and ingestion operations treat the source as read-only, clone privately, and return a candidate only after complete validation.

No `GameSession`, application object, service member, autoload, singleton, hidden global, persistence component, scene, or platform adapter owns or retains canonical mutable report state before P1.

#### 5.2 Live window remains the R1 window

The current live window continues to store:

```text
window_start_simulation_msec
ingested_through_simulation_msec
foreground_elapsed_msec
offline_elapsed_msec
debug_elapsed_msec
next_event_sequence
slices
settlement_events
```

R2 does not change the semantic meaning of those fields or the R1 slice, channel, and Settlement contracts.

#### 5.3 New ledger-owned child state

`ReportLedger` adds:

```text
const MAX_RETAINED_RECORDS: int = 8
next_record_sequence: int = 1
retained_records: Array[ReportWindowRecord]
threshold_continuations: Array[ReportThresholdContinuation]
```

The capacity of `8` is the **owner-approved prototype runtime constant**, not a player-facing sufficiency promise or persistence commitment. Its ingestion correctness is independently assessed; player-facing usefulness may be revisited before P1 without changing R2 continuity semantics.

#### 5.4 Report-window records

Each applied rollover creates one `ReportWindowRecord` through this exact live-to-record projection:

```text
live.window_start_simulation_msec       -> record.window_start_simulation_msec
live.ingested_through_simulation_msec   -> record.window_end_simulation_msec
live.foreground_elapsed_msec            -> record.foreground_elapsed_msec
live.offline_elapsed_msec               -> record.offline_elapsed_msec
live.debug_elapsed_msec                 -> record.debug_elapsed_msec
live.slices                             -> deep-copied record.slices
live.settlement_events                  -> deep-copied record.settlement_events
candidate.next_record_sequence          -> positive record.record_sequence
live.next_event_sequence                -> omitted from storage
live retained history/continuations     -> absent from the record
```

A valid projected record must satisfy the derived event-next witness:

```text
pre-rollover live.next_event_sequence
    == record.settlement_events.size() + 1
```

The record stores no nested ledger, history, continuation state, summary totals, display text, `GameState`, save metadata, or simulation object. It is **value-exact under this declared projection**, not field-identical to the ledger root.

`ReportWindowRecord` supplies complete deep clone and value equality. Stored records require `record_sequence > 0`. Production code exposes no mutator and does not alter a record after insertion; readers return deep-detached copies so callers cannot alias retained state. A detached live-window read uses the same value shape with `record_sequence == 0`; that sentinel is never stored in history.

#### 5.5 Compact Threshold continuation

`ReportThresholdContinuation` stores the latest accepted cross-window baseline for one Threshold:

```text
threshold_id: StringName
latest_assignment_revision: int
form_id: StringName
writ_id: StringName
ordered_retinue_ids: Array[StringName]
lifecycle_state: StringName
remaining_backlog: int
has_settled: bool
channels: Array[ReportChannelContinuation]
```

`ReportChannelContinuation` stores:

```text
channel_id: StringName
output_item_id: StringName
rate_period_msec: int
progress_subunits: int
rate_carry_units: int
total_banked_units: int
```

Threshold continuations are ordered by Threshold ID. Channel continuations are ordered by channel ID. They store no totals, report record identity, content definition, effective rate, formatted value, per-bank event, persistence key, or presentation state.

The continuation entry is the sole compact cross-window endpoint authority. Retained records and live-window facts remain explanatory evidence; they do not create another mutable endpoint owner.

#### 5.6 Assignment-revision rule

For a Threshold, a later active segment must use either:

- the same latest assignment revision and exactly the same Form, Writ, and ordered Retinue identity; or
- a greater assignment revision, which may have different component identity.

A lower revision is rejected as `REPORT_INGEST_IDENTITY_MISMATCH`.

A greater revision need not be numerically contiguous because recall and redispatch may advance revision without producing an active report segment between them.

#### 5.7 Continuity rule

Across live windows, retained-record pruning, mode/content splits, timeline-only intervals, other-Threshold activity, and assignment changes:

- next backlog-before equals the compact latest backlog endpoint;
- `SETTLED` never regresses to `OVERDUE`;
- once `has_settled` is true, no later Settlement transition is accepted;
- every previously seen channel is present in the next active fact for that Threshold;
- output identity and rate period do not change;
- progress, carry, and total-before equal the compact prior endpoints;
- genuinely new channels may appear and then become required continuation.

The ingestor updates live-window facts and continuation state in the same private candidate.

#### 5.8 Rollover eligibility and result

A rollover request supplies the exact expected report cursor.

- A valid non-empty live window ending at the expected cursor creates one record and returns `APPLIED`.
- A positive-duration timeline-only window is non-empty and creates a record.
- A canonical zero-duration empty live window returns `EMPTY_NO_OP` with no candidate.
- Redelivery after an applied rollover therefore returns the same no-op and creates no duplicate record.
- A negative expected cursor, cursor mismatch, invalid source, sequence overflow, or invalid candidate rejects without mutation.

On `APPLIED`, the candidate:

1. appends the exact record;
2. checked-increments `next_record_sequence`;
3. prunes complete oldest records until size is at most eight;
4. resets only the live window to canonical empty state at the same report cursor;
5. preserves threshold continuations unchanged;
6. passes complete validation.

#### 5.9 Record sequence and retention

Record sequences begin at `1`, increase once per applied rollover, are never reused, and remain stable after pruning.

Retained records form one ascending contiguous suffix ending at `next_record_sequence - 1`. The number of pruned records is derived from sequence and retained size; no second counter is stored.

Retention removes whole oldest records only. It does not merge, edit, partially clear, re-sequence, or produce a synthetic aggregate. Pruning never changes continuation state or gameplay state.

#### 5.10 Detached reads

R2 adds pure data-level reads:

```text
ReportLedgerReader.read_live_window(source_ledger) -> Dictionary
ReportLedgerReader.read_history(source_ledger) -> Dictionary
ReportLedgerReader.read_record(source_ledger, record_sequence) -> Dictionary
```

Reads validate the source, return deep-detached records/children, preserve canonical oldest-to-newest history order, mutate nothing, cache nothing, and read no `GameState`, content definitions, clocks, files, scenes, platform APIs, or application objects.

The three reader payloads are the complete R2 read surface. `window`, `records`, and `record` contain only the stored `ReportWindowRecord` facts declared in section 5.4. R2 adds no public elapsed, event-next, pruned-count, core-total, channel-total, summary, label, filtering, formatting, or continuation fields unless a later candidate explicitly enumerates, counts, and reassesses them.

R2 returns canonical IDs and complete stored internal report facts. Player disclosure, discovery filtering, naming, localization, formatting, report selection, and UI belong to later presentation work.

#### 5.11 One semantic validator

`ReportLedgerValidator` remains the single runtime semantic authority. It validates:

- R1 live-window invariants;
- continuation shape and ordering;
- record shape and local event ordering;
- history suffix sequence and capacity;
- contiguous retained record windows and the final record-to-live boundary;
- continuity across the retained suffix and live window;
- agreement between latest available detailed facts and compact continuation state;
- Settlement uniqueness represented by detailed facts and continuation state;
- checked arithmetic and deep ownership.

For a Threshold whose old detailed records have all been pruned and which is absent from the retained suffix/live window, a locally valid continuation entry remains sufficient authority. Future ingestion still validates against it.

Snapshotter, ingestor, and reader operations may classify inputs and route stable errors but do not introduce competing semantic validators.

#### 5.12 Later-slice boundaries

R2 adds no `GameState` field, schema version, mapper, wire validator, migration, fixture, codec, save transaction, save checkpoint, application wiring, trusted-time classification, simulation formula, coordinator, report UI, claim, acknowledgement, delete, clear, or progression behavior.

P1 alone may later persist the proven complete ledger. B alone may coordinate simulation and report ingestion atomically.

### Consequences

- The current window can roll forward without retaining unbounded operational slices.
- Future ingestion remains safe after rollover and history pruning.
- Report history is finite, deterministic, and sequence-stable.
- Old explanatory detail may be pruned without changing gameplay or future-ingestion safety.
- No lifetime aggregate or second validator is introduced.
- P1 receives an exercised runtime lifecycle instead of inventing schema semantics for an unproven graph.
- Reports remain informational observations of already-applied gains.

### Alternatives rejected

- Keep all live slices indefinitely: unbounded and contrary to R2 retention.
- Clear the live window without continuation state: loses the R1 continuity oracle.
- Reconstruct continuity from current `GameState` or content: historically unsafe and outside R2 ownership.
- Retain every assignment revision forever: unnecessary because revisions are monotonic; latest revision plus regression rejection is sufficient.
- Merge pruned records into a synthetic aggregate: creates another report representation and semantic parity burden.
- Let report opening/acknowledgement trigger rollover: presentation and application behavior are not R2 authority.
- Persist in R2: belongs to P1.
- Restore `ReportAccumulatorState`, `DEC-0041`, A2/A3/A4, or failed PR code: superseded and non-executable.

## 6. Exact runtime type and API contract

### 6.1 `ReportLedger` additions

```text
MAX_RETAINED_RECORDS = 8
next_record_sequence
retained_records
threshold_continuations
```

Existing factory, clone, equality, validator, and ingestion APIs remain. Clone and equality expand to every new root and child field.

### 6.2 `ReportLedgerSnapshotResult`

```text
success: bool
changed: bool
outcome: StringName
error_code: StringName
developer_details: String
created_record_sequence: int
candidate_ledger: ReportLedger or null
```

| Outcome | success | changed | candidate | sequence | error/details |
|---|---:|---:|---|---:|---|
| `APPLIED` | true | true | validated detached candidate | positive | empty |
| `EMPTY_NO_OP` | true | false | null | 0 | empty |
| `REJECTED` | false | false | null | 0 | listed non-empty code and non-empty details |

Stable snapshot errors:

```text
REPORT_SNAPSHOT_LEDGER_REQUIRED
REPORT_SNAPSHOT_LEDGER_INVALID
REPORT_SNAPSHOT_CURSOR_INVALID
REPORT_SNAPSHOT_CURSOR_MISMATCH
REPORT_SNAPSHOT_SEQUENCE_OVERFLOW
REPORT_SNAPSHOT_CANDIDATE_INVALID
```

### 6.3 Snapshot API

```text
ReportLedgerSnapshotter.rollover(
    source_ledger: ReportLedger,
    expected_cursor_msec: int
) -> ReportLedgerSnapshotResult
```

Input precedence:

1. source required;
2. source valid;
3. expected cursor non-negative;
4. expected cursor equals source ingested-through cursor;
5. empty/non-empty classification;
6. sequence and candidate construction;
7. complete candidate validation.

### 6.4 Reader result grammars

`read_live_window` has exactly:

```text
{ "ok", "code", "details", "window" }
```

`read_history` has exactly:

```text
{ "ok", "code", "details", "records" }
```

`read_record` has exactly:

```text
{ "ok", "found", "code", "details", "record" }
```

Stable read errors:

```text
REPORT_READ_LEDGER_REQUIRED
REPORT_READ_LEDGER_INVALID
REPORT_READ_SEQUENCE_INVALID
```

A missing positive record sequence is not an error:

```text
ok = true
found = false
code = empty
details = empty
record = null
```

Failure returns `ok = false`, one listed code, non-empty details, and null/empty data. Success returns empty code/details.


### 6.5 Public contract inventory

```text
Stateless public operation boundaries: 2
    ReportLedgerSnapshotter
    ReportLedgerReader

Public entry points: 4
    rollover
    read_live_window
    read_history
    read_record

New result grammars: 4
    one typed ReportLedgerSnapshotResult
    three distinct exact reader dictionaries
```

These counts describe contract and review complexity; they do not create another state owner or path.

## 7. Rollover algorithm

For `APPLIED`:

1. validate source ledger;
2. require exact expected cursor;
3. classify canonical empty window;
4. deep-clone source;
5. construct a `ReportWindowRecord` by deep-copying every live-window value;
6. assign `candidate.next_record_sequence` to the record;
7. checked-increment candidate sequence;
8. append the record;
9. remove complete oldest records while size exceeds eight;
10. set live-window start to the unchanged ingested-through cursor;
11. zero all three live mode durations;
12. clear live slices and Settlement events;
13. reset live `next_event_sequence` to `1`;
14. leave continuation entries value-equal;
15. validate the complete candidate;
16. return the candidate and created sequence only on success.

No step mutates the source or any record already owned by it.

## 8. Ingestor and validator evolution

### 8.1 Ingestor

The R1 wrapper, result, interval, no-op, and error precedence remain unchanged.

Before merge/append, continuity is checked against the candidate Threshold continuation. After each accepted segment, the same private candidate updates the continuation. The existing live-window normalization still merges or appends slices according to R1 rules.

A first observation creates one continuation. Same revision requires exact component identity. Greater revision replaces only the stored latest component identity and revision while preserving Threshold/channel endpoints. Lower revision rejects.

A first observed `SETTLED` segment sets `has_settled = true` even if its transition event predates the current ledger window. An `OVERDUE` zero endpoint requires the existing normalized Settlement event, which then sets `has_settled = true`. No later Settlement is accepted.

### 8.2 Validator

The validator performs two continuity passes:

1. validate detailed continuity within the retained record suffix and current live window, beginning with the earliest retained detail available;
2. compare the final available detailed endpoint for each represented Threshold with its compact continuation.

It does not require pruned detail to reconstruct a standalone continuation entry.

Every non-empty live or retained active fact has a corresponding continuation. No continuation may conflict with later detailed evidence.

## 9. Stored-versus-derived decision

| Fact/value | Treatment | Owner | Persistence in R2 | Reason |
|---|---|---|---|---|
| Live R1 cursor/mode/slices/events | Stored | `ReportLedger` | No | Existing current-window authority |
| `next_record_sequence` | Stored | `ReportLedger` | No | Stable identity after pruning |
| Retained records | Stored | `ReportLedger` | No | Bounded explanatory history |
| Latest Threshold continuation | Stored | `ReportLedger` | No | Future-ingestion safety after rollover/pruning |
| Latest channel endpoints | Stored in continuation | Threshold continuation | No | Exact progress/carry/total continuity |
| Record elapsed | Mathematically derivable; not an R2 public output | None as stored authority | No | End minus start; later readers may add it only through new counted authority |
| Record next event sequence | Validation derivation only | Validator | No | Event count plus one; omitted from record storage and reader payloads |
| Pruned record count | Mathematically derivable; not an R2 public output | None as stored authority | No | Sequence minus retained suffix size |
| Core totals/backlog reduction | Mathematically derivable; not an R2 public output | None as stored authority | No | Checked sums and endpoint differences |
| Channel banked deltas/totals | Mathematically derivable; not an R2 public output | None as stored authority | No | Total endpoint differences and checked sums |
| Player disclosure/labels/formatting | Deferred | presentation | No | Later UI/discovery authority |
| Save representation | P1 | persistence | Not in R2 | Separate owner and schema transition |
| Atomic gameplay/report candidate | B | coordinator | Not in R2 | Separate transaction seam |

## 10. Ownership and lifetime matrix

| Object | Creator | Owner | Mutation authority | Lifetime | Explicit non-owners |
|---|---|---|---|---|---|
| Source ledger | caller/factory/prior candidate | caller/test | read-only during operation | caller-defined runtime | app/session/global/persistence before P1 |
| Ingestion candidate | ingestor | ingestor until validated, then caller | ingestor only before return | one call then caller-defined | snapshotter/reader/app/global |
| Snapshot candidate | snapshotter | snapshotter until validated, then caller | snapshotter only before return | one call then caller-defined | reader/app/global/persistence |
| Window record | snapshot candidate | ledger/caller | no production mutator after insertion; readers return detached copies only | retained until pruned | UI, persistence, simulation |
| Continuation entry | ingestion candidate | ledger/caller | ingestor through private candidate | ledger lifetime | record/read/UI/current GameState |
| Detached read record | reader result recipient | caller | caller may mutate detached copy only | caller-defined | source ledger |
| Validator | class-level static operation | none | no retained state | call-scoped | application/session/global state |
| P1 durable ledger | not created | - | - | deferred | R2 |
| B combined candidate | not created | - | - | deferred | R2 |

## 11. Complete test oracle

### A. New state, clone, equality, and validator grammar

- exact field inventories for ledger additions, record, Threshold continuation, and channel continuation;
- isolated clone/equality mutation for every new root/child field;
- source isolation for arrays and children;
- continuation and history canonical ordering;
- record sequence, window, mode-sum, slice, channel, and event shape;
- retained suffix capacity and sequence ending at `next_record_sequence - 1`;
- last retained record end equals live-window start;
- detailed latest facts agree with continuation;
- standalone continuation remains valid after its detailed records are pruned;
- null/wrong-class children and signed-64-bit overflow reject.

### B. Complete post-rollover and post-pruning continuity matrix

Every row below runs against two independently constructed valid baselines:

1. after at least one applied rollover while the introducing record remains retained;
2. after enough additional rollovers to prune the introducing record, leaving compact continuation as the only prior endpoint authority.

Each row uses literal source, input, and expected-candidate witnesses rather than reproducing production algorithms. Every rejection proves complete value and reference preservation for the source ledger, retained records, continuation children, run wrapper, inner result, segments, channels, and events.

| Case | Required outcome |
|---|---|
| Same revision with different Form, Writ, or Retinue order | `REPORT_INGEST_IDENTITY_MISMATCH` |
| Lower assignment revision | `REPORT_INGEST_IDENTITY_MISMATCH` |
| Non-contiguous greater revision with different identity | `APPLIED`; new revision/identity stored; backlog and every prior channel endpoint continue exactly |
| Backlog-before differs from compact endpoint | `REPORT_INGEST_SLICE_DISCONTINUITY` |
| Prior `SETTLED` followed by `OVERDUE` | `REPORT_INGEST_SLICE_DISCONTINUITY` |
| Previously seen channel omitted | `REPORT_INGEST_CHANNEL_DISCONTINUITY` |
| Existing channel output identity changes | `REPORT_INGEST_CHANNEL_DISCONTINUITY` |
| Existing channel period changes | `REPORT_INGEST_CHANNEL_DISCONTINUITY` |
| Existing channel progress-before resets | `REPORT_INGEST_CHANNEL_DISCONTINUITY` |
| Existing channel carry-before resets | `REPORT_INGEST_CHANNEL_DISCONTINUITY` |
| Existing channel total-before resets | `REPORT_INGEST_CHANNEL_DISCONTINUITY` |
| Duplicate Settlement after `has_settled` | `REPORT_INGEST_SLICE_DISCONTINUITY` |
| Genuinely new channel appears | `APPLIED` with every literal supplied endpoint stored |
| Previously new channel is absent from the next active fact | `REPORT_INGEST_CHANNEL_DISCONTINUITY` |

### C. Snapshot/rollover and live-to-record projection

- operational and positive timeline-only windows create one positive-sequence record;
- the record is value-exact under the section 5.4 projection: each listed live fact copies to the named record field, `record_sequence` is added, `next_event_sequence` is omitted, derived event-next agrees, and history/continuation are absent;
- candidate live window is canonical empty at the unchanged cursor;
- continuation is value-equal before and after rollover;
- canonical empty window is idempotent `EMPTY_NO_OP`;
- negative/mismatched cursor, invalid source, sequence overflow, and candidate invalidity reject with exact grammar and no mutation;
- only `APPLIED` returns one candidate and the exact created sequence.

### D. Retention and record sequence

- capacity is exactly eight;
- ninth and later rollovers prune complete oldest records only;
- retained records form a contiguous ascending suffix ending at `next_record_sequence - 1`;
- sequence never resets or reuses after pruning;
- pruning changes no retained record, live fact, or continuation;
- detailed validation begins at the earliest retained detail available and does not claim reconstruction across the discarded boundary;
- the final retained/live detailed endpoint agrees with compact continuation for every represented Threshold.

### E. Detached reads

- live read uses sequence `0` and contains only exact stored window-record facts;
- history read is oldest-to-newest and contains only exact stored record facts;
- exact-sequence read returns one detached record;
- missing positive sequence returns successful not-found grammar;
- invalid source and non-positive sequence return exact errors;
- mutating a returned record, slice, channel, event, or array cannot affect source or another read;
- reads expose no continuation, derived total, summary, label, filter, format, or cache and create no record.

### F. Settlement, transactionality, and chunk equivalence

- Settlement uniqueness survives rollover and pruning under both detailed and continuation-only baselines;
- first observed already-Settled state cannot later accept Overdue or another Settlement;
- same-mode one-shot and chunked runs produce value-equal live ledgers before rollover and value-equal projected records afterward;
- equivalent timeline-only chunks project to equal records;
- folded bank events remain endpoint-derived and do not reappear as retained event history;
- every no-op or rejection preserves all source and input roots, children, values, and references without aliasing.

### G. Persistence and ownership exclusion

- schema version remains 3;
- `GameState` exposes no ledger field;
- save mapper, validators, migrations, fixtures, codec, and storage remain unchanged;
- serialized output excludes all R2 type and API symbols;
- `src/reports/` contains no scene, clock, file, storage, platform, application, session, autoload, or singleton access;
- no report opening, acknowledgement, claim, delete, clear, or UI path is added.

### H. Evidence

- exact 37-path status set;
- focused R1 regression plus complete R2 suites;
- full canonical GUT suite;
- clean import and main-scene smoke;
- deterministic R2 trace with exact earned markers;
- exact-head CI;
- exact-head Windows owner runner with generated ignored UTF-8 log, cleanup, cleanup-absence proof, artifact audit, and `git diff --check`;
- no interactive checklist.

## 12. Approved implementation surface

### Documentation

```text
docs/codex/DECISIONS.md
docs/codex/MILESTONES.md
docs/codex/ARCHITECTURE.md
docs/codex/DATA_AND_CONTENT_CONTRACTS.md
docs/codex/TESTING_AND_VALIDATION.md
docs/codex/M04E2R2_PLANNING.md
docs/codex/milestone-prompts/M04E2R2-report-window-rollover-history-reads.md
```

### Existing runtime files modified

```text
src/reports/report_ledger.gd
src/reports/report_ledger_ingestor.gd
src/reports/report_ledger_validator.gd
```

### New runtime files

```text
src/reports/report_window_record.gd
src/reports/report_window_record.gd.uid
src/reports/report_threshold_continuation.gd
src/reports/report_threshold_continuation.gd.uid
src/reports/report_channel_continuation.gd
src/reports/report_channel_continuation.gd.uid
src/reports/report_ledger_snapshot_result.gd
src/reports/report_ledger_snapshot_result.gd.uid
src/reports/report_ledger_snapshotter.gd
src/reports/report_ledger_snapshotter.gd.uid
src/reports/report_ledger_reader.gd
src/reports/report_ledger_reader.gd.uid
```

### Existing R1 tests modified

```text
tests/unit/m04e2r1/test_report_ledger.gd
tests/unit/m04e2r1/test_report_ledger_ingestion.gd
```

### New R2 tests

```text
tests/unit/m04e2r2/test_report_ledger_r2_state.gd
tests/unit/m04e2r2/test_report_ledger_r2_state.gd.uid
tests/unit/m04e2r2/test_report_ledger_snapshot.gd
tests/unit/m04e2r2/test_report_ledger_snapshot.gd.uid
tests/unit/m04e2r2/test_report_ledger_reads.gd
tests/unit/m04e2r2/test_report_ledger_reads.gd.uid
tests/integration/m04e2r2/test_report_ledger_rollover_ingestion.gd
tests/integration/m04e2r2/test_report_ledger_rollover_ingestion.gd.uid
tests/integration/m04e2r2/test_report_ledger_persistence_exclusion.gd
tests/integration/m04e2r2/test_report_ledger_persistence_exclusion.gd.uid
```

### Evidence tooling

```text
tools/test/m04e2r2/m04e2r2_report_history_trace.gd
tools/test/m04e2r2/m04e2r2_report_history_trace.gd.uid
tools/test/owner/run_m04e2r2_owner_verification.ps1
```

This is the exact owner-approved 37-path set: 7 documentation paths, 18 non-documentation/non-`.uid` paths, and 12 `.uid` companions. No substitution or additional path is authorized without reassessment and owner approval.

## 13. Concept budget and quantitative forecast

### 13.1 Hard authority and concept declaration

```text
Primary subsystem owners: 1 total - existing caller-owned ReportLedger family
New authoritative aggregate families: 0 - extend the existing family
New authoritative child value concepts: 3 - window record, Threshold continuation, channel continuation
Stateless public operation boundaries: 2 - snapshotter and reader
Public entry points: 4 - rollover plus three reads
New result grammars: 4 - one typed snapshot result plus three exact reader dictionaries
Schema transitions: 0
Dependencies/platform bridges: 0
Production abstraction layers: 0
Test-only helper concepts: 0 - local fixture/witness functions only
Verification-tool concepts: 1 - one R2 trace/owner-runner package
```

`ReportLedgerSnapshotResult` is the result envelope for the approved rollover API, not another state owner. `ReportLedgerReader` is a stateless query boundary, not a service or retained owner.

### 13.2 Categorized forecast

| Category | Forecast additions | Forecast deletions | Expected paths | Owner-approved reassessment threshold | Concepts added/replaced |
|---|---:|---:|---:|---:|---|
| Production runtime | 700-1,000 | 0-120 | 9 | 1,050 additions | Three child values; snapshot boundary; reader boundary |
| Tests/evidence | 1,250-1,750 | 0-150 | 7 | 1,850 additions | Literal projection, rollover/pruning matrix, reads, R1 regressions |
| Verification tooling | 500-650 | 0-80 | 2 | 700 additions | R2 trace and Windows owner package; measured against the approximately 489-line R1 baseline |
| Documentation | 1,200-1,500 | 100-250 | 7 | 1,600 additions | The owner-approved memo and packet total approximately 1,135 lines before maintained-source edits |
| Authored/generated data | 0 | 0 | 0 | 0 | None |
| **Governed non-documentation total** | **2,450-3,400** | **0-350** | **18** | **3,600 additions** | - |

### 13.3 Threshold disposition

The independent assessment measured a credible governed range of `2,450-3,400` additions and concluded that one slice is semantically coherent. The bounded rereview returned **APPROVE** and supported `3,600` as the packet-specific stop-and-reassess threshold: 200 lines above the measured upper range, not a completion target or entitlement.

The mandatory pre-implementation reassessment is complete. The owner approved the category stops and `3,600` aggregate threshold. No initial exception or delegated variance exists. Crossing a category stop, the aggregate threshold, the exact path set, or the concept budget requires the policy exception/reassessment route before publication.

Acceptance and evidence may not be compressed, mirrored from production logic, or omitted to fit the number.

## 14. Explicit exclusions and stop rules

R2 must not add or modify:

- `GameState` report ownership;
- schema v4, mapping, wire validation, migration, fixtures, save/load, checkpoints, codec, or storage;
- application/session/service/global retention;
- simulation formulas, result facts, run modes, content, assignments, concurrency, Halls, support, tutorial, progression, platform code, or trusted-time behavior;
- atomic simulation/report coordination;
- report UI, player disclosure, localization, formatting, opening, acknowledgement, claim, delete, partial clear, or permanent analytics;
- another semantic validator, cache, index, event log, lifetime aggregate, or generic report framework;
- failed-branch production code, concrete `DEC-0041`, former A2/A3/A4 graphs, or historical `ReportAccumulatorState` examples.

Stop before drafting publication authority when:

- current `main` differs materially;
- another owner, aggregate family, public API, schema, dependency, seam, risk dimension, or path is required;
- safe rollover requires current mutable `GameState` or content reconstruction;
- compact continuation cannot preserve the complete R1 continuity oracle;
- history pruning requires a second aggregate or validator;
- complete readable implementation/evidence cannot fit the approved threshold;
- the exact 37-path set, 18 non-documentation paths, 13 new scripts, or 3,600 governed additions would be exceeded;
- tests would need to mirror production continuity logic rather than use independent literal witnesses;
- required focused/full checks remain red;
- two substantial correction rounds do not show local convergence.

## 15. Documentation reconciliation

The eventual implementation branch must:

- add accepted `DEC-0047` only after owner approval;
- correct stale R1 operational status in Decisions, Architecture, Data Contracts, and Testing;
- mark R2 as in progress/Partial while the PR is open without claiming merge or owner verification;
- define current R2 state and APIs without copying superseded A4 semantics;
- retain P1/B as deferred;
- preserve historical A2/A3/A4 material as explicitly non-executable;
- update final milestone closure only after owner integration evidence exists.

## 16. Planning and approval route

```text
planning candidate v0.1
-> fresh independent scope assessor: APPROVE WITH BOUNDED CORRECTIONS
-> bounded candidate v0.2
-> same-assessor bounded rereview: APPROVE
-> explicit owner approval of DEC-0047, retention eight, concept/path authority, quantitative thresholds, packet, and implementation
-> owner-approved v0.3 packet
-> fresh transactional implementation task (Codex Terra / High / FRESH)
```

The planning architect does not assess its own packet, implement it, perform routine PR-lifetime triage, independently review the PR, or integrate it.

## 17. Approved disposition

This v0.3 memo and packet preserve one principal transition, the existing caller-owned `ReportLedger` family, zero new aggregate families, three authoritative child concepts, two operation boundaries, four public entry points, four result grammars, two seams, three runtime risk dimensions, schema version 3, and the exact 37-path set.

Independent assessment and same-assessor rereview are complete. The owner approved:

1. accepted `DEC-0047`;
2. `MAX_RETAINED_RECORDS = 8`;
3. the complete concept inventory and exact path set;
4. the categorized forecasts and stops;
5. the `3,600` governed non-documentation stop-and-reassess threshold with no initial exception;
6. packet v0.3;
7. implementation by a separate fresh transactional Codex Terra / High actor.

The packet is directly executable only by that separate implementation actor. The implementer must reverify the baseline, use the exact branch and one draft PR, preserve the acceptance/evidence floor, stop before any threshold or authority crossing, and stop after publication without merge.
