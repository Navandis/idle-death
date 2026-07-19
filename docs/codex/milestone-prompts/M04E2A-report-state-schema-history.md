# Implementation slice M04E2A: Report state, schema-v4 migration, ingestion, snapshot, and bounded history

**Prompt version:** v0.1  
**Prompt date:** 2026-07-19  
**Prompt status:** Draft  
**Work item type:** Implementation slice  
**Parent conceptual epic:** `M04 — Persistent Reaping simulation vertical slice` / M04E / proposed M04E2 sub-epic  
**Milestone definition:** `docs/codex/MILESTONES.md` — `### M04E2A — Report state, schema-v4 migration, ingestion, snapshot, and bounded history`  
**Recommended task size:** Medium; one report-state/migration/service pull request  
**Scope-gate result:** Within proposed guardrails; stop if actual work needs another primary owner, more than two cross-layer seams, more than approximately 28 non-documentation source/test files, or more than approximately 1,500 non-documentation code/test lines  
**Expected base branch or ref:** current `main` after M04E1 merge commit `03f05a3d78609a993cecab8b0077e5f7d7d55900`  
**Planned prompt path:** `docs/codex/milestone-prompts/M04E2A-report-state-schema-history.md`

> This prompt authorizes typed report state, schema version 4, the sequential v3-to-v4 migration, one `ReportService`, cursor-idempotent ingestion of already-applied committed simulation results, bounded event/history retention, live snapshotting, persistence proof, and the M04E2A verification package. It does not authorize atomic simulation-plus-report live commit, the final M04 harness, report UI, claim buttons, trusted time, clocks, tutorial, progression, Halls, support, concurrency, arbitrary event-payload persistence, or M04E2B implementation.

## Approval dependency

Do not execute this prompt until the project owner:

1. reviews and accepts proposed `DEC-0041` or approves a replacement contract;
2. approves the M04E2 recalibration into M04E2A and M04E2B;
3. approves M04E2A prompt v0.1;
4. confirms M04E1 is Merged/Passed at merge commit `03f05a3d78609a993cecab8b0077e5f7d7d55900`.

Until then:

```text
DEC-0041: Proposed
M04E2A prompt: Draft
M04E2A implementation: Not started
GATE-REPORT-SCHEMA: Pending
```

Do not draft or implement M04E2B in this task.

## Execution protocol

Before editing:

1. Read `AGENTS.md` completely.
2. Read every source listed under **Authoritative context**.
3. Inspect current `main`, `git status --short`, merged M04E1 implementation/tests/docs, and the final M04E1 owner package.
4. Verify PR #16 merged from final head `738e89c606dd9f1f9f0396334ea9d8587ff389f3` at merge commit `03f05a3d78609a993cecab8b0077e5f7d7d55900`.
5. Verify schema version 3 and content revision `prototype-content-r2` are current at task start.
6. Inspect `GameState`, `GameStateValidator`, `SaveEnvelope`, `SaveSchemaMapper`, every version-specific schema validator, `SaveMigrationRegistry`, `GameStatePersistenceCoordinator`, `SimulationEngine`, `SimulationRunService`, final M04E1 tests/trace/runner, and immutable v1/v2/v3 fixtures.
7. State the proposed report runtime types, primitive schema shape, validation rules, migration transform, public `ReportService` APIs/results, interval matrix, retention algorithm, expected files, exact fixture, and verification plan before non-trivial edits.
8. Reassess scope. Stop before implementation if an atomic run/report coordinator, report UI, claim flow, command/progression/Hall/support report ingestion, generic variant-payload codec, trusted time, application lifecycle, concurrency, another primary owner, or another broad subsystem becomes necessary.

During implementation:

- Add one bounded `ReportService`; do not create separate accumulator, history, and dedupe frameworks.
- Keep every production formula in `SimulationEngine`.
- Add explicit report state to `GameState`, cloning, copying, validation, schema mapping, and persistence.
- Advance the writer to schema version 4 and retain frozen validators/fixtures for versions 1–3.
- Add only the sequential `v3 -> v4` production migration.
- Initialize migrated report cursors at the source simulation cursor and fabricate no history.
- Accept only successful committed M04E1 run results.
- Enforce exact cursor duplicate/gap/overlap rules before mutation.
- Aggregate exact result facts; do not inspect rates or recompute production.
- Bound report history and recent event detail deterministically.
- Persist typed report aggregates, not arbitrary engine-result objects or raw event payload dictionaries.
- Make every service failure transactionally no-mutation.
- Keep `GameStateValidator` permissive of a report cursor trailing simulation time; M04E2B owns application-level completeness.
- Add junior-readable comments explaining report authority, cursor identity, migration cursor choice, retention, no-claim semantics, and deferred coordinator ownership.
- Add the real-file trace and final-pattern Windows owner package.
- Report exact commands, counts, markers, exits, and actual-versus-estimated scope.
- Leave Windows owner verification pending until the owner supplies the generated log.
- Do not draft or implement M04E2B.

Do not describe M04E2A as complete while any merge-gate criterion is failed, blocked, or pending.

## Objective

Persist a bounded, save-safe explanation of already-applied simulation gains, aggregate each committed simulation interval exactly once, snapshot non-empty live reports into immutable ordered history without changing gameplay, and establish the schema-v4 foundation required by the later atomic coordinator.

## Player or developer outcome

From focused tests and one headless trace, a developer can:

- load or migrate a current game into schema version 4 with empty prospective report state;
- commit a one-hour M04E1 run on a candidate and ingest the exact already-applied result;
- inspect 4,140 returns, 360 Essence, 60,000,000 Mastery subunits, 60 cycles, 12 Soldier Souls, and 125,000 Scribe progress in typed report state;
- deliver the same result twice without double-counting;
- see gap, partial-overlap, forecast, failed, malformed, and cursor-mismatch inputs reject without mutation;
- archive live report sequence 1 and prove inventory/gameplay remain unchanged;
- exceed event/history bounds and see deterministic oldest-detail compaction with counters;
- save/load live and archived reports through production schema-v4 persistence;
- upgrade v1, v2, and v3 fixtures sequentially to v4 while current v4 loads without rewrite;
- run one Windows PowerShell command and share a complete UTF-8 log.

## Authoritative context

| Priority | Source | Required sections or records | Why it applies |
|---:|---|---|---|
| 1 | `AGENTS.md` | Full file | Repository rules and source hierarchy |
| 2 | `docs/codex/MILESTONES.md` | M04E1 completion, proposed M04E2/E2A/E2B, gates, guardrails | Slice authority |
| 3 | `docs/codex/DECISIONS.md` | `DEC-0011`, `DEC-0012`, `DEC-0016`, `DEC-0033`, `DEC-0034`, `DEC-0040`, proposed `DEC-0041` | State/report/migration authority |
| 4 | `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | Save schemas, events/results, M04E1, proposed M04E2A contracts | Exact fields and rules |
| 5 | `docs/codex/ARCHITECTURE.md` | Reports/forecasts, M04E1 realized boundary, proposed M04E2A boundary | Ownership and seams |
| 6 | `docs/codex/IMPLEMENTATION_RULES.md` | Typing, deterministic ordering, persistence, comments, source ownership | Engineering rules |
| 7 | `docs/codex/TESTING_AND_VALIDATION.md` | §§27–28 and owner workflow | Evidence |
| 8 | `docs/codex/OWNER_VERIFICATION_WORKFLOW.md` | Complete | Windows runner/log |
| 9 | `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md` | IF-REQ-02, IF-REQ-03, IF-REQ-15, report section | Product invariants |
| 10 | `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md` | P90-SAFE-06, P90-SAFE-11, P90-B06 | Prototype report behavior |
| 11 | Current implementation | GameState, persistence stack, SimulationEngine, SimulationRunService, M04E1 evidence | Actual baseline |

Report unresolved conflicts before implementing.

## Repository state

Expected baseline:

| Item | Expected state |
|---|---|
| Completed slices | M04A–M04D3 and M04E1 Merged/Passed |
| Save | Schema v3 current; sequential v1→v2→v3 support; `JSON_V1` |
| Content | `prototype-content-r2`; compatible historical revisions unchanged |
| State | No report state in `GameState` |
| Simulation | Transactional explicit-duration one-active-Reaping engine |
| Run adapter | M04E1 committed modes and detached forecast |
| Report | No accumulator, history, ingestion cursor, or service |
| UI/application | No report screen, claim flow, or GameSession composition |
| Working tree | Clean except task changes |

## Dependencies and gates

| Dependency/gate | Required state | Verification |
|---|---|---|
| M04E1 | Merged and Passed | Merge/evidence record |
| `DEC-0041` | Accepted or owner-approved replacement | Decision record |
| `GATE-REPORT-SCHEMA` | Satisfied at prompt approval | Milestone map |
| `GATE-SLICE-SCOPE` | Remains within approved limit | Handoff |
| M04E1 result contract | Exact committed interval/result fields remain stable | Regression tests |
| Persistence | Sequential historical migration and atomic upgrade retained | Integration tests |
| Schema/content | v4/r2 after implementation | Schema/content tests |
| Windows | Godot 4.7 console executable | Owner package |

## Scope and review-surface assessment

| Assessment item | Draft estimate |
|---|---|
| Parent conceptual epic | M04 / M04E / proposed M04E2 |
| Primary subsystem owner | `ReportService` plus report-state types |
| Principal transition | Already-applied committed interval → idempotently aggregated report state; live report → archived record |
| New authoritative aggregate family | One: report state/live/history |
| Save-schema change | One: v3 → v4 |
| Content compatibility change | None; r2 remains current |
| Deterministic algorithms | Interval relation, stable upsert/order, retention/compaction, sequence guards |
| Cross-layer seams | 2: report service → M04E1 result; report state → persistence |
| Risk dimensions | Migration, idempotency, retention/order |
| Expected non-documentation source/test files | Approximately 14–22 |
| Expected non-documentation code/test delta | Approximately 850–1,300 lines |
| Platform/native work | None |
| Interactive owner checks | None |
| Automated owner checks | One generated PowerShell log |
| Mandatory split trigger | Not crossed at draft |

Stop for a revised prompt before exceeding approximately 28 non-documentation source/test files or 1,500 non-documentation code/test lines, or before adding another primary owner or third cross-layer seam.

## Required behavior

| ID | Requirement | Authority |
|---|---|---|
| `RB-01` | Add one `ReportService` as the sole accumulator/history owner. | Proposed `DEC-0041` |
| `RB-02` | `ReportService` is scene-independent and reads no clock, file, platform, UI, tutorial, progression, Hall, or support state. | Architecture |
| `RB-03` | `ReportService` never invokes SimulationEngine or derives production formulas. | `DEC-0016` |
| `RB-04` | Add `GameState.report_state` with explicit deep clone/copy support. | Schema contract |
| `RB-05` | Add typed live, history, threshold, channel, and event records. | Data contract |
| `RB-06` | No report runtime object aliases another state/record after cloning or snapshot. | Clone contract |
| `RB-07` | Add complete content-aware report validation. | State contract |
| `RB-08` | Allow report cursor `<= simulation_time`; do not require equality globally. | M04E2B boundary |
| `RB-09` | Advance current writer to schema version 4 and retain codec JSON_V1. | Persistence |
| `RB-10` | Retain frozen validators and immutable fixtures for v1, v2, and v3. | `DEC-0034` |
| `RB-11` | Register only the sequential production v3→v4 step. | Migration policy |
| `RB-12` | Validate the complete v3 source before migration. | Migration policy |
| `RB-13` | Migration deep-copies and preserves every existing envelope/gameplay value. | Migration policy |
| `RB-14` | Migration initializes report/live cursors to source simulation time. | Proposed `DEC-0041` |
| `RB-15` | Migration creates no report history and no retroactive report. | No fabrication |
| `RB-16` | Pure migration preserves save revision; persisted upgrade increments once. | Existing persistence |
| `RB-17` | Already-current v4 loads without rewrite or rotation. | Existing persistence |
| `RB-18` | Every report integer uses canonical decimal-string wire encoding. | JSON integer contract |
| `RB-19` | Public service results have stable success/error/details/changed/checkpoint/duplicate fields. | Result contract |
| `RB-20` | Accept only successful committed FOREGROUND_SUPPLIED/OFFLINE_FIXTURE/DEBUG results. | M04E1/DEC-0040 |
| `RB-21` | Reject FORECAST before duplicate handling. | Report authority |
| `RB-22` | Require projected_state null and exact successful simulation_result. | M04E1 result contract |
| `RB-23` | Require state cursor to equal result cursor for a newly ingestible interval; covered historical duplicates may arrive after later state advancement. | Interval contract |
| `RB-24` | Require requested and committed elapsed to equal result minus baseline. | Interval contract |
| `RB-25` | Zero duration is an unchanged success. | Idempotency |
| `RB-26` | Wholly covered interval is a duplicate unchanged success. | Idempotency |
| `RB-27` | Partial overlap rejects with REPORT_INTERVAL_OVERLAP. | Idempotency |
| `RB-28` | Forward gap rejects with REPORT_INTERVAL_GAP. | Idempotency |
| `RB-29` | New interval must begin exactly at ingested cursor. | Idempotency |
| `RB-30` | Positive newly ingested interval advances cursor once even with no gains. | Retry safety |
| `RB-31` | Aggregate returned Souls/backlog/cycles/lifecycle by Threshold. | Report contract |
| `RB-32` | Aggregate Essence globally and Mastery by Form. | Report contract |
| `RB-33` | Aggregate generic channel banking/progress/carry/history by Threshold/channel. | Generic channel contract |
| `RB-34` | Determine current Form identity only through validated current operation state; do not infer from display names. | Stable identity |
| `RB-35` | Ingest only events with reportable true. | Event contract |
| `RB-36` | Assign persistent monotonic report-event sequences with checked overflow. | Ordering |
| `RB-37` | Count every reportable event by type exactly. | Report contract |
| `RB-38` | Retain newest 64 event details and count omitted oldest details. | Retention |
| `RB-39` | Do not persist arbitrary raw SimulationEvent.payload dictionaries. | Bounded schema |
| `RB-40` | Canonically order threshold/channel summaries and history. | Determinism |
| `RB-41` | Checked-add every numeric aggregate and counter. | Numeric safety |
| `RB-42` | Snapshot requires report cursor equal gameplay cursor plus the exact expected next report sequence. | Completeness/stale-state safety |
| `RB-43` | Empty live snapshot is an unchanged success. | Idempotency |
| `RB-44` | Non-empty snapshot deep-copies live into an immutable record. | `DEC-0016` |
| `RB-45` | Snapshot increments report sequence once and resets live at report cursor. | Snapshot contract |
| `RB-46` | Retain newest 20 records and count pruned oldest records. | Retention |
| `RB-47` | Snapshot requests a save checkpoint; service performs no file I/O. | Persistence boundary |
| `RB-48` | Ingestion/snapshot never change gameplay authority. | No-claim invariant |
| `RB-49` | Every failure leaves complete gameplay and report state unchanged. | Transaction contract |
| `RB-50` | No standalone destructive clear/history-delete command is added. | Slice contract |
| `RB-51` | Content revision remains prototype-content-r2. | Compatibility |
| `RB-52` | No M04E2B coordinator or final harness enters the diff. | Slice boundary |

## Required state transitions

| ID | Transition | Required result |
|---|---|---|
| `ST-01` | v3 source at cursor T → pure migration | v4 empty report state at T; no history/gameplay change |
| `ST-02` | v1/v2 source → sequential migration | valid v4 through every registered step |
| `ST-03` | current v4 load | no migration/rewrite |
| `ST-04` | positive contiguous committed interval | aggregate once; cursor advances |
| `ST-05` | zero committed interval | unchanged success |
| `ST-06` | wholly covered interval | duplicate unchanged success |
| `ST-07` | partial overlap | typed rejection; no mutation |
| `ST-08` | forward gap | typed rejection; no mutation |
| `ST-09` | forecast/projection/failed/malformed result | typed rejection; no mutation |
| `ST-10` | contiguous interval with no gains | cursor/run-window advance; no fabricated gain |
| `ST-11` | multiple contiguous runs | deterministic merged starts/ends/totals |
| `ST-12` | more than 64 events | newest detail retained; exact counts/omission count |
| `ST-13` | non-empty live + expected sequence | archive, increment, reset, checkpoint |
| `ST-14` | empty live + expected sequence | unchanged success/no record |
| `ST-15` | stale snapshot sequence | typed rejection/no mutation |
| `ST-16` | 21st report record | oldest pruned; dropped count incremented |
| `ST-17` | save/load live/history | exact schema-v4 reconstruction |
| `ST-18` | overflow/invalid content/state | complete no mutation/source-byte preservation |

## Implementation requirements

### 1. Runtime report types

Add report state under the existing domain state owner. Prefer clear nested classes or bounded companion files consistent with current repository conventions.

Implement explicit `deep_clone()` for every mutable nested family. Add `GameState.copy_from()` support.

Do not use Resources, Nodes, reflection cloning, JSON cloning, or arbitrary dictionaries as the primary runtime model.

### 2. Domain validation

Validate:

- report cursor/window ranges and relation to simulation time;
- positive next sequences;
- non-negative counts/totals;
- maximum history/recent-event lengths;
- ascending unique report/event sequences;
- stable Threshold/Form/channel/item references;
- lifecycle tokens;
- fixed-point progress/carry ranges using content periods;
- history/live non-overlap and sequence continuity among retained records;
- deep runtime object types.

The report cursor may trail simulation time. E2A must not make direct M04E1 committed runs invalid solely because they are not yet reported.

### 3. Schema version 4

Update:

```text
SaveEnvelope
SaveSchemaMapper
SaveSchemaValidator
SaveMigrationRegistry
fixtures and migration tests
```

Keep version-specific key sets and validators. Do not mutate historical fixture files.

All report arrays/maps must serialize in canonical order. Use explicit mapping, not runtime object serialization.

### 4. ReportService

Expected APIs:

```text
ingest_committed_run(state, run_result)
snapshot_live(state, expected_next_report_sequence)
```

Private helpers may upsert typed summaries and compact arrays, but do not create a generic event/report framework.

Use a deep-cloned candidate for every service transaction and commit only after complete validation.

### 5. Event detail

Persist only:

```text
event_sequence
event_type
occurred_simulation_msec
priority
subject_id
source_id
```

Do not copy raw payload. The typed Threshold/channel summaries retain current quantities. Add tests proving unsupported arbitrary payload objects never enter report state or the snapshot.

### 6. Exact fixture

Use the existing M04E1 one-hour fixture and actual `SimulationRunService` to produce a committed result on a candidate. Then call `ReportService`.

Do not hand-author a fake result for the main success demonstration. Synthetic results are acceptable only for negative boundary/overflow matrices where constructing the state through production would be impractical.

### 7. Persistence integration

Use production coordinator/storage to cover:

- current v3 migrated to v4 and persisted once;
- current v4 no rewrite;
- live report round trip;
- archived history round trip;
- duplicate after reload;
- migration/upgrade-write failure preservation;
- corrupt primary/fallback behavior where applicable;
- absence of service/result/projection/raw-payload artifacts.

### 8. Documentation

Update canonical sections rather than appending duplicates:

- `docs/codex/MILESTONES.md`;
- `docs/codex/ARCHITECTURE.md`;
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`;
- `docs/codex/TESTING_AND_VALIDATION.md`;
- `docs/codex/DECISIONS.md` only if implementation exposes a genuine semantic conflict; do not weaken accepted `DEC-0041`.

Do not draft M04E2B.

## Trace contract

Create:

```text
tools/test/m04e2a/m04e2a_report_state_trace.gd
```

It must:

1. require explicit nonblank `--save-root`;
2. reject `user://`;
3. use production persistence only inside the supplied root;
4. leave root deletion to the owner runner;
5. check every result before reading it;
6. emit each marker only after complete assertions;
7. exit nonzero on any mismatch;
8. perform real v3→v4 upgrade and current-v4 round trip;
9. audit source ownership;
10. emit exactly:

```text
TRACE M04E2A schema_v4_migration_cursor_initialized=PASS
TRACE M04E2A report_1h_returns=4140_essence=360_mastery=60000000_cycles=60_soldier=12_scribe_progress=125000
TRACE M04E2A progress_only_channel_summary=PASS
TRACE M04E2A duplicate_interval_ingestion_idempotent=PASS
TRACE M04E2A gap_overlap_and_forecast_rejected=PASS
TRACE M04E2A snapshot_sequence=1_live_cleared_history=1
TRACE M04E2A snapshot_preserves_gameplay_authority=PASS
TRACE M04E2A history_retention_bounded_ordered=PASS
TRACE M04E2A event_compaction_bounded_counted=PASS
TRACE M04E2A schema_v4_report_round_trip=PASS
TRACE M04E2A v1_v2_v3_v4_upgrade_and_v4_no_rewrite=PASS
TRACE M04E2A failures_preserve_report_and_gameplay=PASS
TRACE M04E2A no_claim_gate_or_raw_result_authority=PASS
TRACE M04E2A no_ui_clock_platform_or_m04e2b_sources=PASS
```

## Owner-run Windows checks

Create:

```text
tools/test/owner/run_m04e2a_owner_verification.ps1
```

Adapt the final M04E1 runner. Preserve:

1. explicit `-GodotBin`, then `GODOT_BIN`, then PATH;
2. optional Git SHA evidence;
3. complete UTF-8 PR-head log;
4. Godot 4.7 validation;
5. full suite before;
6. focused unit + integration directories;
7. explicit import;
8. isolated trace;
9. stable copied trace output and all fourteen markers;
10. `finally` cleanup and absence proof;
11. prior-log-tolerant artifact audit;
12. full suite after;
13. standardized summary and nonzero failure exit.

Expected invocation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
    -File .\tools\test\owner\run_m04e2a_owner_verification.ps1 `
    -CommitSha "<PR_HEAD_SHA>"
```

No interactive checklist is required.

## Acceptance criteria

| ID | Criterion | Evidence | Merge gate |
|---|---|---|---|
| `AC-01` | M04E1 is Merged/Passed and DEC-0041 is Accepted. | Docs/merge | Yes |
| `AC-02` | One ReportService owns accumulation/history. | Review/tests | Yes |
| `AC-03` | ReportService owns no formulas, clocks, files, scenes, platform, UI, or later systems. | Source audit | Yes |
| `AC-04` | Complete typed report state deep-clones/copies without aliasing. | Unit tests | Yes |
| `AC-05` | Report validation covers ranges, order, IDs, bounds, and object types. | Matrix | Yes |
| `AC-06` | Schema v4 is current; JSON_V1/content r2 unchanged. | Schema tests | Yes |
| `AC-07` | Frozen v1/v2/v3 fixtures and validators remain. | Review/tests | Yes |
| `AC-08` | Pure v3→v4 migration initializes cursor/windows at source simulation time. | Fixture/trace | Yes |
| `AC-09` | Migration creates no history or gameplay change. | Canonical comparison | Yes |
| `AC-10` | Sequential v1→v2→v3→v4 passes. | Migration tests | Yes |
| `AC-11` | Current v4 loads without rewrite. | Byte test | Yes |
| `AC-12` | Positive contiguous interval aggregates exact one-hour values. | Unit/trace | Yes |
| `AC-13` | Progress-only channel state is reported. | Unit/trace | Yes |
| `AC-14` | Zero and covered duplicates, including historical delivery after later advancement, are idempotent no-ops. | Unit/trace | Yes |
| `AC-15` | Gap and overlap reject without mutation. | Matrix/trace | Yes |
| `AC-16` | Forecast/projected/failed/malformed/mismatched results reject. | Matrix | Yes |
| `AC-17` | Positive no-gain interval advances cursor exactly once. | Unit tests | Yes |
| `AC-18` | Multiple runs merge deterministic first/latest endpoints. | Unit tests | Yes |
| `AC-19` | Reportable-event counts and sequences are exact. | Unit tests | Yes |
| `AC-20` | Event detail bound/omission counter are exact. | Unit/trace | Yes |
| `AC-21` | Complete-cursor non-empty snapshot archives, increments, resets, and requests checkpoint; a cursor gap rejects. | Unit/trace | Yes |
| `AC-22` | Empty snapshot and stale sequence behavior are exact. | Unit tests | Yes |
| `AC-23` | History bound/pruning/dropped counter are exact. | Unit/trace | Yes |
| `AC-24` | Ingestion/snapshot/failures preserve complete gameplay authority. | Canonical comparisons | Yes |
| `AC-25` | Live/history round-trip through production persistence. | Integration/trace | Yes |
| `AC-26` | No raw engine/result/projection/payload/service artifacts serialize. | Snapshot audit | Yes |
| `AC-27` | Every failure and overflow leaves state/source bytes unchanged. | Negative matrices | Yes |
| `AC-28` | Linux focused/import/trace/full checks pass. | Commands/exits | Yes |
| `AC-29` | Windows package passes full/focused/import/14-marker/cleanup/audit/full. | Owner log | Yes |
| `AC-30` | Scope/docs/comments are complete and no M04E2B work enters the diff. | Handoff/review | Yes |

## Automated verification

Run:

```bash
git status --short

./tools/test/run_gut.sh -- \
  -gdir=res://tests/unit/m04e2a \
  -gdir=res://tests/integration/m04e2a

godot --headless --path . --import

trace_root="$(mktemp -d)"
godot --headless --path . \
  -s res://tools/test/m04e2a/m04e2a_report_state_trace.gd \
  -- --save-root "$trace_root"
trace_exit=$?
rm -rf "$trace_root"
test ! -e "$trace_root"
test "$trace_exit" -eq 0

godot --headless --path . \
  -s res://tools/test/m04e2a/m04e2a_report_state_trace.gd
test "$?" -ne 0

./tools/test/run_gut.sh
git diff --check
git status --short
```

Report exact focused/full counts, all fourteen markers, negative-root result, commands/exits, and actual scope. Leave Windows owner verification pending.

## Save/load verification

| Scenario | Setup | Expected result |
|---|---|---|
| v3 migration | Nonzero simulation cursor and gameplay | Empty v4 report state at existing cursor; no fabricated history |
| sequential history | Frozen v1/v2/v3 fixtures | Each reaches valid v4 through registered steps |
| current v4 | Load valid v4 | No rewrite/rotation |
| live state | Ingest one-hour result | Exact live aggregate after reload |
| archived state | Snapshot sequence 1 | Exact immutable record and empty live after reload |
| duplicate after reload | Redeliver covered interval | No totals/sequence change |
| failure | Inject migration/save/validation failure | Original bytes/state preserved |
| artifact audit | Inspect snapshot | No run result, projection, service result, raw payload, UI, or coordinator object |

## Stop conditions

Stop and report if:

1. M04E1 is not actually Merged/Passed;
2. DEC-0041 or replacement contract is not approved;
3. report aggregation requires recomputing production;
4. partial-overlap results must be sliced;
5. arbitrary event payload serialization becomes necessary;
6. atomic coordinator/final harness becomes necessary now;
7. another primary owner or more than two cross-layer seams is needed;
8. source/test files exceed approximately 28 or code/test lines exceed approximately 1,500;
9. schema version 5, content revision 3, production content changes, UI, clocks, trusted time, platform, concurrency, Halls, progression, or tutorial work becomes necessary;
10. any exact fixture, no-mutation, migration, trace, persistence, or regression check fails.

## Final response format

Use exactly:

### Implementation completed
### Files changed
### Verification
### Assumptions
### Known limitations and risks
### Deferred work
### Suggested next task

Under **Files changed**, report actual-versus-estimated source/test file count and code/test line delta.  
Under **Verification**, leave Windows owner verification pending.  
Under **Suggested next task**, state only that the owner should run the M04E2A Windows package against the final PR head. Do not draft M04E2B.
