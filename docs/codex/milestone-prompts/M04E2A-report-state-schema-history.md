# Implementation slice M04E2A: Report state, schema-v4 attributed ingestion, read-only peeks, snapshot, and bounded recent history

**Prompt version:** v0.2  
**Prompt date:** 2026-07-19  
**Prompt status:** Approved  
**Work item type:** Implementation slice  
**Parent conceptual epic:** `M04 — Persistent Reaping simulation vertical slice` / M04E / approved M04E2 sub-epic  
**Milestone definition:** `docs/codex/MILESTONES.md`  
**Expected base branch or ref:** current `main` after M04E1 merge commit `03f05a3d78609a993cecab8b0077e5f7d7d55900`  
**Planned prompt path:** `docs/codex/milestone-prompts/M04E2A-report-state-schema-history.md`

> This prompt authorizes typed report state, schema version 4, sequential v3-to-v4 migration, one `ReportService`, cursor-idempotent ingestion of already-applied committed simulation results, Threshold/assignment/lifecycle/channel attribution, generic gain rollups, pure live/history read models, offline-window classification support, bounded event/recent-history retention, global snapshotting, persistence proof, and the M04E2A verification package. It does not authorize atomic simulation-plus-report live commit, the final M04 harness, report UI, claim buttons, trusted-time acquisition, clocks, tutorial, progression, Halls, support, concurrency, long-term Codex analytics, arbitrary event-payload persistence, or M04E2B implementation.

## Approval record

The project owner approved this implementation package on 2026-07-19:

```text
DEC-0041: Accepted
M04E2 recalibration: Approved
M04E2A definition: Approved
M04E2A prompt: Approved v0.2
M04E2A implementation: Not started
GATE-REPORT-SCHEMA: Satisfied
GATE-SLICE-SCOPE: Satisfied
```

M04E1 is Merged/Passed at merge commit `03f05a3d78609a993cecab8b0077e5f7d7d55900`. This prompt is approved for execution against current `main` after confirming that baseline. Do not draft or implement M04E2B in this task.

## Required reading and pre-edit report

Before editing:

1. Read `AGENTS.md` and follow the source hierarchy.
2. Read `docs/codex/MILESTONES.md`, accepted `DEC-0041`, `ARCHITECTURE.md`, `DATA_AND_CONTENT_CONTRACTS.md`, `IMPLEMENTATION_RULES.md`, `TESTING_AND_VALIDATION.md`, and `OWNER_VERIFICATION_WORKFLOW.md`.
3. Read accepted `DEC-0011`, `DEC-0012`, `DEC-0016`, `DEC-0033`, `DEC-0034`, `DEC-0035`, `DEC-0039`, and `DEC-0040`.
4. Inspect current `main`, `git status --short`, merged M04E1 implementation/tests/docs, and the final M04E1 owner package.
5. Inspect `GameState`, `GameStateValidator`, `SaveEnvelope`, `SaveSchemaMapper`, every version-specific schema validator, `SaveMigrationRegistry`, `GameStatePersistenceCoordinator`, `SimulationEngine`, `SimulationRunService`, final M04E1 tests/trace/runner, and immutable v1/v2/v3 fixtures.
6. Inspect current assignment identity/revision and rate-context contracts. Do not infer Reaping identity from display names, loadout output, or rates.
7. Report before non-trivial edits:
   - proposed report runtime types and primitive v4 shape;
   - attribution key and canonical ordering;
   - pure query/read-model APIs;
   - offline-window classification rule;
   - migration transform;
   - public `ReportService` result shapes;
   - interval, retention, and snapshot matrices;
   - expected files;
   - exact fixtures and trace plan;
   - current/projected non-documentation file and line scope.

## Protected invariants

- Gameplay gains are already applied before report ingestion.
- A report never grants, removes, claims, or delays output.
- `SimulationEngine` remains the only production formula owner.
- `ReportService` never recomputes rates or production.
- Forecasts never enter report authority.
- The stable current Reaping operation identity is `threshold_id`.
- Assignment/loadout episode identity includes positive `assignment_revision`.
- Loadout identity is the canonical component tuple, not numeric output.
- Equal output never merges identities.
- A -> B -> A remains three assignment episodes.
- Lifecycle and channel attribution remain visible.
- Live inspection never snapshots or clears state.
- The backend stores no “last clicked” timestamp.
- Overall totals are derived from canonical attributed slices rather than maintained as a second independent authority.
- Offline-only reports cannot silently include foreground/debug intervals.
- Recent report history is not permanent Codex Mortis analytics.
- Current v3 saves migrate prospectively without fabricated history.
- All state transitions are transactional and checked.
- Content remains `prototype-content-r2`.

## Objective

Persist a bounded, save-safe explanation of already-applied simulation gains. Aggregate every committed simulation interval exactly once into canonical Threshold/assignment/lifecycle/channel slices. Expose detached global and filtered live/history views. Archive complete live windows into recent history without changing gameplay. Establish schema-v4 foundations required by the later atomic coordinator and UI.

## Developer demonstration

The completed slice must demonstrate all of the following without UI:

1. migrate a nonzero-cursor v3 state to v4 with empty report state at the existing cursor;
2. commit and ingest the exact M04E1 one-hour Gloamwood result;
3. derive matching overall, Threshold, assignment, lifecycle, and channel views;
4. ingest Gloamwood and Broken Watch intervals and prove exact global rollup plus separate operation groups;
5. execute A -> B and A -> B -> A report attribution without merging episodes;
6. prove two different equal-output loadouts remain separate;
7. cross Settlement and preserve Overdue/Settled slices;
8. inspect live global/Threshold/assignment views repeatedly with no mutation;
9. archive a foreground window, then create an isolated offline-mode window and archive it as `OFFLINE_RETURN`;
10. reject `OFFLINE_RETURN` on a mixed-mode window;
11. snapshot sequence 1 and prove gameplay is unchanged;
12. exceed event/history bounds and prove deterministic compaction;
13. round-trip live and archived report state through production persistence;
14. run one final Windows owner package.

## Baseline

| Area | Required baseline |
|---|---|
| Completed slices | M04A–M04D3 and M04E1 Merged/Passed |
| Save | Schema v3 current; sequential v1→v2→v3; `JSON_V1` |
| Content | `prototype-content-r2` |
| State | No report state in `GameState` |
| Simulation | Transactional explicit-duration one-active-Reaping engine |
| Run adapter | M04E1 committed modes and detached forecast |
| Report | No accumulator, history, ingestion cursor, queries, or service |
| UI/application | No report screen, claim flow, or GameSession composition |
| Working tree | Clean except task changes |

## Scope assessment

| Assessment item | Draft estimate |
|---|---|
| Primary subsystem owner | `ReportService` plus report-state types |
| Principal transition | Already-applied committed interval → attributed live report; live report → archived record |
| New authoritative aggregate | One: report state/live/recent history |
| Save-schema change | One: v3 → v4 |
| Cross-layer seams | 2: M04E1 result → report service; report state → persistence |
| Risk dimensions | Migration, idempotency, attribution/order, bounded retention |
| Expected non-documentation source/test files | Approximately 16–24 |
| Expected non-documentation code/test delta | Approximately 1,000–1,450 lines |
| Platform/native work | None |
| Interactive owner checks | None |

Stop for a revised prompt before exceeding approximately 28 non-documentation source/test files or 1,500 non-documentation code/test lines, or before adding another primary owner or third cross-layer seam.

## Required behavior

| ID | Requirement | Authority |
|---|---|---|
| `RB-01` | Add one scene-independent `ReportService` as sole accumulation/query/snapshot/history owner. | DEC-0041 |
| `RB-02` | ReportService reads no clock, file, platform, UI, tutorial, progression, Hall, support, or analytics state. | Architecture |
| `RB-03` | ReportService never invokes SimulationEngine or derives production formulas. | DEC-0016 |
| `RB-04` | Add `GameState.report_state` with explicit deep clone/copy support. | Schema |
| `RB-05` | Add typed ReportState, accumulator, record, attribution slice, loadout identity, channel summary, and event detail. | Data contract |
| `RB-06` | No live/history/query object aliases another object after clone, snapshot, or query. | Clone contract |
| `RB-07` | Add complete report domain/content validation. | State contract |
| `RB-08` | Permit `0 <= report cursor <= simulation time`; snapshot requires equality. | M04E2B boundary |
| `RB-09` | Advance current writer to schema version 4; retain JSON_V1. | Persistence |
| `RB-10` | Retain frozen v1/v2/v3 validators and immutable fixtures. | DEC-0034 |
| `RB-11` | Register only sequential production `v3 -> v4`. | Migration |
| `RB-12` | Validate complete v3 source before migration. | Migration |
| `RB-13` | Migration deep-copies and preserves every prior envelope/gameplay value. | Migration |
| `RB-14` | Migration initializes report/live cursors to source simulation time. | DEC-0041 |
| `RB-15` | Migration creates no history and no retroactive report. | No fabrication |
| `RB-16` | Pure migration preserves save revision; persisted upgrade increments once. | Persistence |
| `RB-17` | Current v4 loads without rewrite/rotation. | Persistence |
| `RB-18` | Every report integer uses canonical decimal-string wire encoding. | JSON integer contract |
| `RB-19` | Public service results expose stable success/error/details/changed/duplicate/checkpoint/cursor fields. | Result contract |
| `RB-20` | Accept only successful committed FOREGROUND_SUPPLIED/OFFLINE_FIXTURE/DEBUG results. | M04E1 |
| `RB-21` | Reject FORECAST before duplicate handling. | Report authority |
| `RB-22` | Require projected_state null and exact successful simulation_result. | M04E1 |
| `RB-23` | Require candidate cursor to equal result cursor for a newly ingestible interval. | Interval |
| `RB-24` | Require requested and committed elapsed to equal result minus baseline. | Interval |
| `RB-25` | Zero duration is unchanged success. | Idempotency |
| `RB-26` | Wholly covered interval is duplicate unchanged success. | Idempotency |
| `RB-27` | Partial overlap rejects with stable typed error. | Idempotency |
| `RB-28` | Forward gap rejects with stable typed error. | Idempotency |
| `RB-29` | New interval begins exactly at report cursor. | Idempotency |
| `RB-30` | Positive no-gain interval advances cursor/window/run count once. | Retry safety |
| `RB-31` | Persist attribution slices keyed by threshold ID, assignment revision, lifecycle. | Attribution |
| `RB-32` | Store canonical Form/Writ/ordered-Retinue loadout identity in every slice. | Identity |
| `RB-33` | Store exact slice start/end/elapsed and core deltas. | Attribution |
| `RB-34` | Store generic inventory gains by item ID. | Extensibility |
| `RB-35` | Store Mastery gains by Form ID. | Report contract |
| `RB-36` | Store generic channel summaries by channel ID with exact endpoints. | Channel contract |
| `RB-37` | Distinct revisions/loadouts remain separate even with equal numeric output. | DEC-0039 |
| `RB-38` | Returning to an earlier loadout creates a new report episode. | DEC-0035 |
| `RB-39` | Split exact engine segments by lifecycle without recomputation. | Simulation contract |
| `RB-40` | Derive overall/Threshold/assignment/lifecycle/channel views from slices. | Read model |
| `RB-41` | Add pure detached global, Threshold, assignment, and archived-record queries. | Read contract |
| `RB-42` | Peeks mutate nothing, increment nothing, and request no checkpoint. | Read contract |
| `RB-43` | Persist no last-click timestamp; live current-assignment view uses report/revision boundaries. | Presentation boundary |
| `RB-44` | Derive is_empty/whole_gain/progress_change/meaningful_event flags. | Read model |
| `RB-45` | Persist committed mode counts and validate their sum. | Offline classification |
| `RB-46` | Persist snapshot reason MANUAL_REVIEW/OFFLINE_RETURN/SYSTEM_BOUNDARY. | Record contract |
| `RB-47` | OFFLINE_RETURN requires a non-empty offline-only live window. | Offline isolation |
| `RB-48` | Mixed foreground/debug/offline window rejects OFFLINE_RETURN without mutation. | Offline isolation |
| `RB-49` | Support foreground archive then isolated offline archive sequence. | Future M06 fit |
| `RB-50` | Treat history as bounded recent records, not permanent Codex analytics. | Analytics boundary |
| `RB-51` | Ingest only events with reportable true. | Event contract |
| `RB-52` | Assign persistent monotonic report-event sequences with checked overflow. | Ordering |
| `RB-53` | Count reportable events by type exactly. | Report contract |
| `RB-54` | Retain newest 64 event details and count omitted oldest details. | Retention |
| `RB-55` | Do not persist arbitrary raw SimulationEvent payload dictionaries. | Bounded schema |
| `RB-56` | Canonically order slices, maps, events, and history. | Determinism |
| `RB-57` | Checked-add every aggregate and counter. | Numeric safety |
| `RB-58` | Snapshot validates complete cursor, expected sequence, and reason. | Snapshot |
| `RB-59` | Empty snapshot is unchanged success. | Idempotency |
| `RB-60` | Non-empty snapshot deep-copies live into immutable record. | DEC-0016 |
| `RB-61` | Snapshot increments sequence once, resets live, and preserves cursor. | Snapshot |
| `RB-62` | Retain newest 20 records and count pruned oldest records. | Retention |
| `RB-63` | Snapshot requests checkpoint; ReportService performs no file I/O. | Persistence boundary |
| `RB-64` | Ingestion, queries, and snapshot never change gameplay authority. | No-claim invariant |
| `RB-65` | Every failure leaves complete gameplay/report state unchanged. | Transaction |
| `RB-66` | Add no destructive clear, history delete, or partial Threshold clear. | Slice boundary |
| `RB-67` | Content revision remains prototype-content-r2. | Compatibility |
| `RB-68` | Add no M04E2B coordinator, final harness, UI, trusted time, or Codex analytics. | Scope |

## Required state transitions

| ID | Transition | Required result |
|---|---|---|
| `ST-01` | v3 source at cursor T → pure migration | v4 empty report state at T; no history/gameplay change |
| `ST-02` | v1/v2 source → sequential migration | valid v4 through every step |
| `ST-03` | current v4 load | no rewrite |
| `ST-04` | positive contiguous committed interval | aggregate once; cursor advances |
| `ST-05` | zero committed interval | unchanged success |
| `ST-06` | wholly covered interval | duplicate unchanged success |
| `ST-07` | partial overlap | typed rejection/no mutation |
| `ST-08` | forward gap | typed rejection/no mutation |
| `ST-09` | forecast/projected/failed/malformed result | typed rejection/no mutation |
| `ST-10` | contiguous no-gain interval | cursor/window/run count advance; no gain fabricated |
| `ST-11` | repeated same revision/lifecycle runs | merge exact earliest/latest/elapsed/totals |
| `ST-12` | same Threshold A -> B | two assignment-revision groups |
| `ST-13` | equal-output A/B | equal totals but distinct identities/groups |
| `ST-14` | A -> B -> A | three revision groups; no merging |
| `ST-15` | Gloamwood then Broken Watch | two operations plus exact global rollup |
| `ST-16` | Settlement crossing | separate Overdue and Settled slices |
| `ST-17` | progress-only/generic channel | exact endpoints and ID passthrough |
| `ST-18` | repeated live peeks | complete canonical no mutation |
| `ST-19` | foreground snapshot then offline run/snapshot | two separate records; offline reason valid |
| `ST-20` | mixed-mode live + OFFLINE_RETURN | typed rejection/no mutation |
| `ST-21` | more than 64 events | newest detail retained; exact counts/omission count |
| `ST-22` | non-empty live + expected sequence/reason | archive/increment/reset/checkpoint |
| `ST-23` | empty live or stale sequence | exact no-op or typed rejection |
| `ST-24` | 21st report | oldest pruned; dropped count increments |
| `ST-25` | save/load live/history | exact schema-v4 reconstruction |
| `ST-26` | overflow/invalid content/state | complete no mutation/source-byte preservation |

## Implementation requirements

### 1. Runtime types

Add typed report state under the domain state owner or bounded companion files consistent with repository conventions. Implement explicit `deep_clone()` for every mutable nested family and update `GameState.copy_from()`.

Do not use Resources, Nodes, reflection cloning, JSON cloning, or arbitrary dictionaries as the primary runtime model.

### 2. Validation

Validate:

- report cursor/window ranges and relation to simulation time;
- positive next sequences and non-negative counters;
- history/event bounds and strict sequence order;
- unique attribution keys;
- stable Threshold/Form/Writ/Retinue/channel/item references;
- assignment revision and current loadout identity consistency;
- lifecycle tokens;
- start/end/elapsed consistency;
- progress/carry/history ranges;
- mode-count totals;
- map canonicality and non-negative values;
- record reason and OFFLINE_RETURN purity;
- no object aliasing where testable.

The report cursor may trail simulation time. Do not make low-level M04E1 committed candidates invalid solely because they are not yet reported.

### 3. Persistence and migration

Advance `SaveEnvelope` to v4, add exact v4 key sets and validators, add explicit mapper support, register the sequential v3→v4 step, and preserve frozen v1/v2/v3 fixtures/validators.

The pure migration must preserve all source facts exactly and add only canonical empty report state at the source simulation cursor.

All maps/arrays serialize canonically. Do not mutate historical fixture files.

### 4. `ReportService`

Expected public APIs are equivalent to:

```text
ingest_committed_run(state, run_result)
peek_live_global(state)
peek_live_threshold(state, threshold_id)
peek_live_assignment(state, threshold_id, assignment_revision)
get_report_record(state, report_sequence)
snapshot_live(state, expected_next_report_sequence, snapshot_reason)
```

Use a deep-cloned candidate for each mutating transaction and commit only after complete validation. Queries are pure and detached.

Do not create a generic event/report framework or separate accumulator/history/query services.

### 5. Attribution

For each accepted run:

1. validate the candidate Reaping and read `threshold_id`, `assignment_revision`, and canonical loadout identity;
2. iterate exact engine segments in order;
3. upsert the `(threshold_id, assignment_revision, lifecycle_state)` slice;
4. checked-add duration and core deltas;
5. checked-add generic inventory and Mastery gains;
6. upsert generic channel summaries using exact first/latest endpoints;
7. ingest reportable events in exact order;
8. advance cursor once.

Do not infer identity from names, rates, ETA, or output.

### 6. Read models

Derive overall totals and filtered groups from canonical slices. Do not persist a duplicate global-total authority.

Read models may include convenience flags but no player-facing formatting. They must retain stable IDs and exact values.

### 7. Offline isolation

Persist mode counts. `OFFLINE_RETURN` snapshot requires only offline committed modes. Add tests for:

```text
foreground live -> MANUAL_REVIEW snapshot
OFFLINE_FIXTURE run -> OFFLINE_RETURN snapshot
```

and a mixed-mode rejection.

Do not implement trusted-time sampling or M06 orchestration.

### 8. Event detail

Persist only:

```text
event_sequence
event_type
occurred_simulation_msec
priority
subject_id
source_id
```

Do not copy raw payload. Typed slices/channel summaries retain report quantities.

### 9. Exact fixtures

Use actual `SimulationRunService` and production/copy fixtures for positive demonstrations. Do not hand-author the primary one-hour result.

Synthetic bounded results are allowed only for negative overflow/interval matrices that would be impractical to construct through production.

### 10. Persistence integration

Use production coordinator/storage to cover:

- current v3 migrated to v4 and persisted once;
- current v4 no rewrite;
- live attributed report round trip;
- archived record with reason round trip;
- duplicate after reload;
- migration/upgrade-write failure preservation;
- absence of service/result/projection/read-model/raw-payload/UI/analytics artifacts.

### 11. Documentation

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

It must require an explicit nonblank isolated `--save-root`, reject `user://`, use production persistence only inside that root, leave deletion to the owner runner, check every result before reading it, print each marker only after complete assertions, exit nonzero on any mismatch, perform a real v3→v4 upgrade/current-v4 round trip, audit source ownership, and emit exactly:

```text
TRACE M04E2A schema_v4_migration_cursor_initialized=PASS
TRACE M04E2A report_1h_returns=4140_essence=360_mastery=60000000_cycles=60_soldier=12_scribe_progress=125000
TRACE M04E2A multi_threshold_global_rollup=PASS
TRACE M04E2A assignment_revision_loadout_attribution=PASS
TRACE M04E2A equal_output_loadouts_remain_separate=PASS
TRACE M04E2A return_to_prior_loadout_new_episode=PASS
TRACE M04E2A overdue_settled_lifecycle_attribution=PASS
TRACE M04E2A generic_channel_item_passthrough=PASS
TRACE M04E2A progress_only_channel_summary=PASS
TRACE M04E2A live_peeks_read_only=PASS
TRACE M04E2A offline_return_window_isolated=PASS
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
TRACE M04E2A no_ui_clock_platform_codex_analytics_or_m04e2b_sources=PASS
```

## Owner-run Windows checks

Create:

```text
tools/test/owner/run_m04e2a_owner_verification.ps1
```

Adapt the final M04E1 runner and preserve:

1. explicit `-GodotBin`, then `GODOT_BIN`, then PATH;
2. optional Git SHA evidence;
3. complete UTF-8 PR-head log;
4. Godot 4.7 validation;
5. full suite before;
6. focused unit + integration directories;
7. explicit import;
8. isolated trace;
9. stable copied trace output and all twenty-two markers;
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

| ID | Criterion | Evidence |
|---|---|---|
| `AC-01` | M04E1 Merged/Passed and DEC-0041 Accepted. | Docs/merge |
| `AC-02` | One ReportService owns report mutations and queries. | Review/tests |
| `AC-03` | No formulas, clocks, files, scenes, platform, UI, analytics, or later systems enter ReportService. | Source audit |
| `AC-04` | Complete typed state deep-clones/copies without aliasing. | Unit tests |
| `AC-05` | Validation covers ranges, IDs, relations, order, bounds, modes, reasons, and object types. | Matrix |
| `AC-06` | Schema v4 current; JSON_V1/content r2 unchanged. | Schema tests |
| `AC-07` | Frozen v1/v2/v3 fixtures and validators remain. | Review/tests |
| `AC-08` | Pure v3→v4 migration initializes report/live cursors at source time. | Fixture/trace |
| `AC-09` | Migration creates no history or gameplay change. | Canonical comparison |
| `AC-10` | Sequential v1→v2→v3→v4 passes. | Migration tests |
| `AC-11` | Current v4 loads without rewrite. | Byte test |
| `AC-12` | One-hour result aggregates exact attributed values. | Unit/trace |
| `AC-13` | Generic inventory and Mastery maps are exact. | Unit/trace |
| `AC-14` | Progress-only channel state is exact. | Unit/trace |
| `AC-15` | Two Thresholds produce exact global rollup and separate operation groups. | Unit/trace |
| `AC-16` | A→B creates separate revision/loadout groups. | Unit/trace |
| `AC-17` | Equal-output loadouts remain separate. | Unit/trace |
| `AC-18` | A→B→A remains three episodes. | Unit/trace |
| `AC-19` | Settlement crossing creates separate lifecycle slices. | Unit/trace |
| `AC-20` | Generic copied item/channel passes without whitelist. | Unit/trace |
| `AC-21` | Zero and covered duplicates are idempotent. | Unit/trace |
| `AC-22` | Gap and overlap reject without mutation. | Matrix/trace |
| `AC-23` | Forecast/projected/failed/malformed/mismatched results reject. | Matrix |
| `AC-24` | Positive no-gain interval advances cursor/window once. | Unit tests |
| `AC-25` | Live/global/Threshold/assignment/history queries are detached and read-only. | Unit/trace |
| `AC-26` | Current-assignment window semantics use report/revision boundaries, not last click. | Unit tests |
| `AC-27` | Foreground and offline-only records can be isolated exactly. | Unit/trace |
| `AC-28` | Mixed-mode OFFLINE_RETURN rejects without mutation. | Unit tests |
| `AC-29` | Reportable-event counts/sequences are exact. | Unit tests |
| `AC-30` | Event detail bound/omission counter are exact. | Unit/trace |
| `AC-31` | Complete-cursor non-empty snapshot archives, increments, resets, and requests checkpoint. | Unit/trace |
| `AC-32` | Empty snapshot, stale sequence, bad reason, and offline-purity behavior are exact. | Unit tests |
| `AC-33` | History bound/pruning/dropped counter are exact. | Unit/trace |
| `AC-34` | Ingestion/query/snapshot/failures preserve complete gameplay authority. | Canonical comparisons |
| `AC-35` | Live/history round-trip through production persistence. | Integration/trace |
| `AC-36` | No raw result/projection/read-model/payload/UI/analytics/service artifacts serialize. | Snapshot audit |
| `AC-37` | Linux and Windows focused/import/22-marker/cleanup/audit/full gates pass. | Logs |
| `AC-38` | Scope/docs/comments complete; no M04E2B work enters diff. | Handoff/review |

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

Report exact focused/full counts, all twenty-two markers, negative-root result, commands/exits, and actual scope. Leave Windows owner verification pending.

## Save/load verification

| Scenario | Setup | Expected result |
|---|---|---|
| v3 migration | Nonzero simulation cursor/gameplay | Empty v4 report state at existing cursor; no fabricated history |
| sequential history | Frozen v1/v2/v3 fixtures | Each reaches valid v4 through registered steps |
| current v4 | Load valid v4 | No rewrite/rotation |
| live attribution | Ingest one-hour result | Exact slice and derived views after reload |
| multi-operation | Ingest Gloamwood and Broken Watch | Exact global and filtered views after reload |
| archived record | Snapshot with reason | Exact immutable record and empty live after reload |
| offline isolation | Foreground record then offline record | Separate reasons/modes/gains after reload |
| duplicate after reload | Redeliver covered interval | No totals/sequence change |
| failure | Inject migration/save/validation failure | Original bytes/state preserved |
| artifact audit | Inspect snapshot | No raw result/projection/read model/payload/UI/analytics/coordinator object |

## Stop conditions

Stop and report if:

1. M04E1 is not actually Merged/Passed;
2. DEC-0041 or replacement contract is not approved;
3. report aggregation requires recomputing production;
4. current engine results lack enough stable assignment/lifecycle/channel facts to implement attribution without changing SimulationEngine materially;
5. partial-overlap results must be sliced;
6. arbitrary event-payload serialization becomes necessary;
7. atomic coordinator/final harness becomes necessary now;
8. long-term Codex analytics state becomes necessary now;
9. another primary owner or more than two cross-layer seams is needed;
10. source/test files exceed approximately 28 or code/test lines exceed approximately 1,500;
11. schema version 5, content revision 3, production content changes, UI, last-click state, clocks, trusted time, platform, concurrency, Halls, progression, tutorial, or support work becomes necessary;
12. any exact fixture, no-mutation, migration, trace, persistence, or regression check fails.

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
