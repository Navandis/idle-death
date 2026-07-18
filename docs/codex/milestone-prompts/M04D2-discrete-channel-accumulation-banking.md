# Implementation slice M04D2: Discrete channel accumulation and long-horizon banking

**Prompt version:** v0.1  
**Prompt date:** 2026-07-18  
**Prompt status:** Approved  
**Work item type:** Implementation slice  
**Parent conceptual epic:** `M04 — Persistent Reaping simulation vertical slice` / M04D sub-epic  
**Milestone definition:** `docs/codex/MILESTONES.md` — `### M04D2 — Discrete channel accumulation and long-horizon banking`  
**Recommended task size:** Medium; one eligible-channel simulation pull request  
**Scope-gate result:** Approved within guardrails; stop if actual work needs another primary owner, more than two cross-layer seams, more than approximately 30 non-documentation source/test files, or more than approximately 1,500 non-documentation code/test lines  
**Expected base branch or ref:** current `main` after M04D1 merge commit `4569fbfb968deb73f54ba453834dd7af0b04d545`  
**Planned prompt path:** `docs/codex/milestone-prompts/M04D2-discrete-channel-accumulation-banking.md`

> This prompt authorizes only exact elapsed production for already-initialized eligible non-Essence Threshold channels, immediate whole banking, channel deltas/events, channel-specific Settlement segmentation, content revision 2, persistence, and verification. It does not authorize output-channel loadout/progression modifiers, changed-loadout compatibility, ETA queries, M04D3, progression effects, reports, forecasts, concurrency, UI, or platform integration.

## Approval record

The project owner approved M04D2 prompt v0.1 and accepted `DEC-0038` on 2026-07-18.

The approved slice includes:

- strict production only for already-initialized eligible non-Essence sources;
- content revision `prototype-content-r2`;
- current non-Essence prototype Settled multipliers of `1.0`;
- exact progress/carry accumulation and immediate whole banking;
- channel-specific lifecycle segmentation through the existing M04C boundary;
- bounded ordered `OUTPUT_CHANNEL_BANKED` events;
- schema-version-3 persistence without a new migration;
- no access mutation, backfill, output-channel modifiers, changed-loadout handling, ETA queries, reports, forecasts, concurrency, UI, or platform integration.

Do not execute a different eligibility, content-compatibility, lifecycle, banking, result, or event model without a new owner-approved decision. Do not draft or implement M04D3 in this task.

## Execution protocol

Before editing:

1. Read `AGENTS.md` completely.
2. Read every source listed under **Authoritative context**.
3. Inspect current `main`, merged M04D1 implementation/tests/docs, and `git status --short`.
4. Verify M04D1 merged from final head `1171785562c4107921437339187a1e782fe0143b` at merge commit `4569fbfb968deb73f54ba453834dd7af0b04d545` and is recorded Merged/Passed.
5. Verify schema version 3 is current, v1/v2 remain supported, and `ThresholdAcquisitionState` plus ordinary inventory already represent every M04D2 authoritative field.
6. Verify the four production channel rates/periods and current `0.25` non-Essence multipliers.
7. Verify M04C exact Settlement segmentation and M04D1 strict/transitional access-source validation.
8. State the proposed engine changes, complete-validation boundary, channel-delta/event shape, content revision update, expected files, exact fixtures, and verification plan before non-trivial edits.
9. Reassess scope. Stop before implementation if output-channel modifiers, changed-loadout behavior, ETA/query work, progression effects, concurrency, another schema version, another primary owner, or another broad subsystem becomes necessary.

During implementation:

- Extend the existing `SimulationEngine`; do not add a second elapsed resolver.
- Resolve on the existing deep-cloned candidate and commit once.
- Require complete current-v3 access/source validation before and after resolution.
- Never call access unlock/reconciliation or create an acquisition record from elapsed simulation.
- Process only the active Threshold's initialized eligible non-Essence channels in sorted channel-ID order.
- Use only normalized integer content and checked fixed-point arithmetic.
- Apply the channel's own Settled multiplier exactly once within the existing M04C lifecycle segments.
- Bank every complete unit immediately into inventory and source history; preserve reservations.
- Keep output-channel modifiers, changed loadouts, denominator compatibility, and ETA out of this slice.
- Add junior-readable comments explaining eligibility, no auto-initialization, residual ownership, whole extraction, lifecycle ordering, content revision 2, bounded events, and M04D3 seams.
- Add exact no-mutation tests for every failure.
- Create the real-file trace and final-pattern Windows owner package.
- Report exact commands, counts, markers, exits, and actual-versus-estimated scope.
- Leave Windows owner verification pending until the owner supplies the generated log.
- Do not draft or implement M04D3.

Do not describe M04D2 as complete while any merge-gate criterion is failed, blocked, or pending.

## Objective

Extend the transactional single-Reaping `SimulationEngine` so every already-initialized eligible non-Essence channel accumulates exact Threshold-owned progress/carry, banks whole units immediately into inventory and source history, follows the existing exact Settlement boundary using its own channel multiplier, and persists through schema version 3 without auto-unlocking, backfilling, or duplicating Essence.

## Player or developer outcome

From focused tests and one headless trace, a developer can:

- resolve Gloamwood for two hours and obtain 24 Soldier Souls plus 25% Scribe progress;
- resolve Gloamwood for eight hours and obtain 96 Soldier Souls plus one Scribe Form Soul;
- resolve Broken Watch for six hours and obtain 720 Provisions plus 25% Man-at-Arms Form-Soul progress;
- resolve Broken Watch for twenty-four hours and obtain 2,880 Provisions plus one Man-at-Arms Form Soul;
- compare one-shot and irregular chunks with exact canonical equality;
- prove locked elapsed time creates no progress and is never backfilled after unlock;
- recall, advance inactive time, redispatch the same loadout, and resume from preserved source progress;
- cross Settlement under the correct per-channel lifecycle rate without resetting work;
- inspect deterministic channel deltas and bounded whole-banking events;
- save/load exact inventory and acquisition state under schema v3/content revision 2;
- run one Windows PowerShell command and share a complete UTF-8 log.

## Authoritative context

| Priority | Source | Required sections or records | Why it applies |
|---:|---|---|---|
| 1 | `AGENTS.md` | Full file | Repository rules |
| 2 | `docs/codex/MILESTONES.md` | Gates, M04D2, scope guardrails | Slice authority |
| 3 | `docs/codex/DECISIONS.md` | `DEC-0010`, `DEC-0012`, `DEC-0014`, `DEC-0026`–`DEC-0030`, `DEC-0033`–`DEC-0038` | Numeric/access/lifecycle/content authority |
| 4 | `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | M04C, M04D1, approved M04D2 contracts; inventory/acquisition/event schemas | Exact data rules |
| 5 | `docs/codex/ARCHITECTURE.md` | M04C transaction; realized M04D1; approved M04D2 boundary | Ownership/segmentation |
| 6 | `docs/codex/IMPLEMENTATION_RULES.md` | Determinism, arithmetic, state, comments, diagnostics | Engineering rules |
| 7 | `docs/codex/TESTING_AND_VALIDATION.md` | §§23–25; owner workflow | Evidence |
| 8 | `docs/codex/OWNER_VERIFICATION_WORKFLOW.md` | Complete | Windows runner/log |
| 9 | `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md` | IF-REQ-05, IF-REQ-09, IF-REQ-10, IF-REQ-18; Threshold channels | Product intent |
| 10 | `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md` | Gloamwood/Broken Watch data; access; Settlement; acceptance | Prototype behavior |
| 11 | Current implementation | `SimulationEngine`, `GameStateValidator`, `OutputAccessService`, schema v3, content registry, fixtures/tests | Actual baseline |

Report unresolved conflicts before implementing.

## Repository state

Expected baseline:

| Item | Expected state |
|---|---|
| Completed slices | M04A, M04B, M04C, M04D1 Merged/Passed |
| Schema | Current writer v3; frozen v1/v2 support; codec `JSON_V1` |
| Access | Global item access, available-source initialization/reconciliation, strict current-state validation |
| Core simulation | Transactional zero/one-active M04C resolver with exact Settlement |
| Channel state | `ThresholdAcquisitionState(progress, carry, total_banked)` persisted but not yet accumulated |
| Current content | `prototype-content-r1`; non-Essence channel Settled multipliers `0.25` |
| UI/application | No gameplay shell, channel UI, report, or forecast |
| Working tree | Clean except task changes |

## Dependencies

| Dependency/gate | Required state | Verification |
|---|---|---|
| M04D1 | Merged and Passed | Merge/evidence record |
| `DEC-0038` | Accepted or revised owner-approved contract | Decision record |
| `GATE-CHANNEL-ACCUMULATION` | Satisfied at prompt approval | Milestone map |
| `GATE-SLICE-SCOPE` | Remains within limits | Prompt/handoff |
| M04C | Existing transaction/segmentation unchanged | Regression tests |
| Schema v3 | Current; no M04D2 bump | Save tests |
| M03/M04D1 content | Valid relationships/access initialization | Registry/domain tests |
| Windows environment | Godot 4.7 console executable | Owner package |

## Scope and review-surface assessment

| Assessment item | Approved estimate |
|---|---|
| Parent conceptual epic | M04 / M04D |
| Primary subsystem owner | Existing `SimulationEngine` |
| Principal transition | Active lifecycle segment → committed eligible channel progress and whole banking |
| New authoritative aggregate family | None |
| Save-schema change | None; schema v3 remains current |
| Content compatibility change | `prototype-content-r1 -> prototype-content-r2`; prior revisions explicitly compatible |
| Deterministic algorithm | Sorted channel selection, fixed-point accumulation, whole extraction, lifecycle segmentation |
| UI/platform work | None |
| Cross-layer seams | Two: engine ↔ content/access validation; resolved state ↔ existing persistence in tests |
| Estimated non-documentation source/test files | Approximately 12–22, excluding `.uid` and docs |
| Estimated non-documentation code/test line delta | Approximately 850–1,350, excluding `.uid` and docs |
| Owner package | `run_m04d2_owner_verification.ps1` |
| Mandatory split trigger | Not crossed at approval |

Stop before approximately 30 non-documentation source/test files, 1,500 code/test lines, more than two seams, or another primary owner.

## Scope

Implement only:

1. strict complete-source validation at M04D2 resolver boundaries;
2. sorted eligible non-Essence channel selection for the one active Reaping;
3. content revision 2 plus exact compatibility list;
4. four current non-Essence Settled multipliers changed to `1.0`;
5. authored baseline / channel-Settled rate derivation;
6. exact channel progress/carry accumulation;
7. immediate whole inventory and source-history banking;
8. reservation preservation;
9. channel deltas in result summary and lifecycle segments;
10. aggregate ordered `OUTPUT_CHANNEL_BANKED` events;
11. inactivity, recall, same-loadout resume, and no-backfill proofs;
12. schema-v3/content-r1/r2 persistence coverage;
13. focused tests, real-file trace, Windows owner runner, and synchronized docs.

## Non-goals

Do not implement or refactor:

1. Form/Writ/Retinue/Art/Recollection/support/global output-channel modifiers;
2. changed-loadout redispatch, rate-context compatibility, carry conversion, or non-compounding;
3. progress percentage/ETA/modifier-trace query;
4. access grants, source initialization, Threshold availability mutation, Recollection purchase, milestones, guarantees, discovery/insight progression, or tutorial effects;
5. recipes, Halls, Rations, Retinue support, concurrency, forecasts, reports, application shell, scenes, or UI;
6. Steam, trusted time, foreground/offline orchestration, or file-time sources;
7. schema version 4, migration, codec change, new IDs, channel periods, or core M04C balance changes;
8. per-unit replay/events, cached effective rates/ETAs, or persisted results;
9. a second simulation engine or unrelated cleanup.

## Required behavior

| ID | Required behavior | Source trace |
|---|---|---|
| `RB-01` | Existing `SimulationEngine` remains the sole elapsed-production owner. | `DEC-0010`, `DEC-0036` |
| `RB-02` | Resolver reads explicit integer elapsed time and no clock/frame/platform/UI state. | Time architecture |
| `RB-03` | Complete candidate resolves on a deep clone and commits once. | `DEC-0012` |
| `RB-04` | Entry and commit use strict current-v3 access/source validation. | `DEC-0037`, `DEC-0038` |
| `RB-05` | Every failure leaves exact whole-state equality. | Transaction contract |
| `RB-06` | Simulation never adds access IDs or acquisition records. | Access boundary |
| `RB-07` | One active Reaping remains the only supported production case. | M04C boundary |
| `RB-08` | No active Reaping advances only timeline; inactive records produce nothing. | M04C/M04D2 contract |
| `RB-09` | Retinues and multiple active Reapings retain current explicit rejection. | Slice boundary |
| `RB-10` | Only active Threshold initialized eligible channels are processed. | `DEC-0038` |
| `RB-11` | Channel processing order is canonical channel ID. | Determinism |
| `RB-12` | Locked gated channels produce nothing and remain absent. | `DEC-0037` |
| `RB-13` | Eligible missing source rejects rather than auto-initializing. | Complete-state invariant |
| `RB-14` | Essence channels are never processed through acquisition state. | M04C ownership |
| `RB-15` | Discovery/frequency/progress-display metadata does not gate eligible production. | Access/knowledge separation |
| `RB-16` | Overdue channel rate is the normalized authored baseline. | Content contract |
| `RB-17` | Settled channel rate applies its own multiplier exactly once. | `DEC-0038` |
| `RB-18` | Threshold core multiplier never applies to a discrete channel. | Channel-specific Settlement |
| `RB-19` | M04D2 applies no loadout/progression output-channel modifier. | M04D3 boundary |
| `RB-20` | Content revision advances to `prototype-content-r2`. | `DEC-0029` |
| `RB-21` | Compatibility list is exact, sorted r1/r2/m02 membership. | Content compatibility |
| `RB-22` | Four non-Essence multipliers become `1.0`; core/Essence values remain unchanged. | `DEC-0037`, `DEC-0038` |
| `RB-23` | Each channel uses its persisted rate carry and stable period. | `DEC-0026`, `DEC-0028` |
| `RB-24` | Produced subunits checked-add to normalized progress. | Numeric contract |
| `RB-25` | Every complete whole unit is extracted in the same segment. | Whole banking |
| `RB-26` | Whole units bank immediately into ordinary inventory. | `IF-REQ-09` |
| `RB-27` | Existing reservations are preserved exactly. | Inventory contract |
| `RB-28` | The same quantity increments `total_banked_units`. | Source-history contract |
| `RB-29` | Progress/carry/history ranges validate after every segment. | Domain contract |
| `RB-30` | Channel work executes inside each existing M04C lifecycle segment. | Exact boundary architecture |
| `RB-31` | Boundary gains use Overdue rate before Settlement. | Same-time ordering |
| `RB-32` | Settlement never clears or rebases channel residuals. | `DEC-0027` |
| `RB-33` | Segment and overall summaries contain sorted channel deltas. | Result contract |
| `RB-34` | A progress-only channel produces a delta but no banking event. | Event contract |
| `RB-35` | Each banked channel emits at most one aggregate event per segment. | Bounded events |
| `RB-36` | Banking events contain complete primitive fields and deterministic order. | Domain-event contract |
| `RB-37` | Banking-event priority precedes lifecycle transition at equal time. | Same-time ordering |
| `RB-38` | Four exact long-duration production fixtures pass. | Prototype data |
| `RB-39` | One-shot and equivalent chunks produce canonical equal state. | Determinism |
| `RB-40` | Late unlock receives no earlier elapsed progress. | `DEC-0037` |
| `RB-41` | Recall/inactivity freezes; same-loadout redispatch resumes source state. | `DEC-0027`, `DEC-0035` |
| `RB-42` | All overflow/content/residual failures preserve state and return stable errors. | Numeric/transaction contract |
| `RB-43` | Schema v3 round-trips exact inventory and acquisition state; result artifacts do not persist. | Persistence contract |
| `RB-44` | No duplicate Essence or Reaping residual authority is introduced. | Ownership contract |
| `RB-45` | Actual review surface is reported against the approved estimate. | `DEC-0033` |

## State transitions

| ID | Initial state | Trigger | Required result | Failure behavior |
|---|---|---|---|---|
| `ST-01` | Valid state, no active Reaping | Resolve positive elapsed | Timeline only | — |
| `ST-02` | Valid inactive Reaping with acquisition progress | Resolve positive elapsed | Timeline advances; acquisition/inventory unchanged | — |
| `ST-03` | Active Gloamwood; gated Scribe locked/absent | Resolve elapsed | No Scribe progress/record/inventory | — |
| `ST-04` | Active available Threshold missing eligible source | Resolve | No mutation | State-invalid rejection |
| `ST-05` | Gloamwood eligible zero state | Resolve 2h | Soldier 24; Scribe progress 250000 | — |
| `ST-06` | Gloamwood eligible zero state | Resolve 8h | Soldier 96; Scribe 1 | — |
| `ST-07` | Broken Watch eligible zero state | Resolve 6h | Provisions 720; MAA progress 250000 | — |
| `ST-08` | Broken Watch eligible zero state | Resolve 24h | Provisions 2880; MAA 1 | — |
| `ST-09` | Partial active source | Recall then resolve inactive | Source/inventory freeze | — |
| `ST-10` | Recalled source | Redispatch same loadout and resolve | Resume from preserved state | Existing command errors reject |
| `ST-11` | Scribe locked for 6h | Unlock then resolve 2h | Progress 250000 only | Any backfill fails |
| `ST-12` | Production channel crosses Settlement with multiplier 1.0 | Resolve | Continuous channel rate, no reset | — |
| `ST-13` | Copied channel multiplier 0.5, backlog 1 | Resolve 2000 ms | 870-ms boundary, exact segmented channel result | Any end-rounded rate fails |
| `ST-14` | Same valid start | Resolve one-shot vs chunks | Exact canonical equality | Any difference fails |
| `ST-15` | Inventory/history/rate/residual near boundary | Resolve overflowing interval | No mutation | Stable overflow/content error |
| `ST-16` | Overdue/Settled/inactive produced state | Save/load | Exact schema-v3 reconstruction | Invalid snapshot rejects |

## Content revision and exact authored changes

Update together:

```text
ContentRegistry.CURRENT_REVISION = "prototype-content-r2"
ContentRegistry.COMPATIBLE_REVISIONS = [
    "prototype-content-r1",
    "prototype-content-r2",
    "prototype-m02"
]
```

and the matching root catalog fields.

Set `settled_multiplier = 1.0` in exactly:

```text
content/channels/CHANNEL_GLOAMWOOD_SOLDIER_SOULS.tres
content/channels/CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS.tres
content/channels/CHANNEL_BROKEN_WATCH_PROVISIONS.tres
content/channels/CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS.tres
```

Do not edit the two Essence channels, Threshold multipliers, channel periods, IDs, access flags, or frozen save fixtures. Add a new revision-2 fixture only when integration evidence benefits from it.

Also correct the stale `OutputChannelDefinition` comment that says Unknown channels always produce: Access/source initialization gates production; discovery metadata governs information.

## Channel delta and event contract

Minimum changed-channel delta:

```text
channel_id
output_item_id
banked_units_delta
progress_subunits_before
progress_subunits_after
rate_carry_units_before
rate_carry_units_after
total_banked_units_before
total_banked_units_after
```

Minimum event:

```text
event_type = OUTPUT_CHANNEL_BANKED
occurred_simulation_msec = segment end
priority = documented channel-gain priority before lifecycle
subject_id = Threshold ID
source_id = channel ID
payload.output_item_id
payload.quantity
payload.lifecycle_state
payload.total_banked_units
payload.progress_subunits_after
reportable = true
tutorial_relevant = true
```

Events are aggregate per channel per lifecycle segment and are not persisted.

## Expected files

| Path/area | Expected action | Purpose |
|---|---|---|
| `src/simulation/simulation_engine.gd` | Modify | Channel accumulation/deltas/events in existing resolver |
| `src/domain/game_state_validator.gd` | Narrow modify only if complete channel invariants need refinement | Strict resolver boundary |
| `src/content/content_registry.gd` | Modify | Revision 2 and compatibility |
| `src/content/definitions/output_channel_definition.gd` | Comment correction | Access-vs-disclosure clarity |
| `content/prototype_content_catalog.tres` | Modify | Revision 2 metadata |
| Four non-Essence channel `.tres` files | Modify | Settled multiplier 1.0 |
| `tests/unit/m04d2/` | Add | Eligibility/arithmetic/events/failures |
| `tests/integration/m04d2/` | Add | Persistence/content compatibility |
| Optional `tests/fixtures/saves/schema_v3_m04d2_channels.json` | Add if useful | Revision-2 produced state |
| `tools/test/m04d2/m04d2_channel_accumulation_trace.gd` | Add | Deterministic real-file proof |
| `tools/test/owner/run_m04d2_owner_verification.ps1` | Add | Windows evidence |
| Maintained docs | Modify | Realized boundary/status/evidence |

Do not add scenes, UI, progression content, modifier infrastructure, or another simulation owner.

## Acceptance criteria

| ID | Pass condition | Evidence | Merge gate? |
|---|---|---|---:|
| `AC-01` | Existing transactional engine solely owns channel production. | Code review/tests | Yes |
| `AC-02` | No clock, frame, scene, UI, file-time, or platform dependency. | Source audit | Yes |
| `AC-03` | Complete access/source validation precedes and follows resolution. | Tests | Yes |
| `AC-04` | Locked channels produce nothing; eligible missing sources reject without auto-creation. | Negative matrix | Yes |
| `AC-05` | Content revision 2 and exact compatibility list are implemented. | Content tests | Yes |
| `AC-06` | Four non-Essence multipliers are 1.0 and core/Essence values remain unchanged. | Catalog tests | Yes |
| `AC-07` | Gloamwood 2h fixture is exact. | Test/trace | Yes |
| `AC-08` | Gloamwood 8h fixture is exact. | Test/trace | Yes |
| `AC-09` | Broken Watch 6h fixture is exact. | Test/trace | Yes |
| `AC-10` | Broken Watch 24h fixture is exact. | Test/trace | Yes |
| `AC-11` | Whole banking updates inventory/history and preserves reservations. | Focused tests | Yes |
| `AC-12` | Progress/carry remain normalized and source-owned. | Tests/validator | Yes |
| `AC-13` | Recall/inactivity freeze and same-loadout resume are exact. | Command/simulation tests | Yes |
| `AC-14` | Late unlock receives no backfill. | Integrated fixture/trace | Yes |
| `AC-15` | One-shot and regular/irregular chunks are canonical equal. | Matrix | Yes |
| `AC-16` | Settlement segmentation uses old/new channel rates at the exact boundary. | Copied fixture | Yes |
| `AC-17` | Settlement never resets/rebases channel state. | Tests | Yes |
| `AC-18` | Channel deltas are complete and sorted. | Result tests | Yes |
| `AC-19` | Banking events are bounded, complete, and correctly ordered. | Event tests/trace | Yes |
| `AC-20` | Progress-only segments emit no banking event. | Focused test | Yes |
| `AC-21` | Every supported overflow/content failure preserves exact state. | Failure matrix | Yes |
| `AC-22` | Revision-1 saves load and new saves use revision 2. | Integration tests | Yes |
| `AC-23` | Schema v3 round-trips exact produced state and excludes result artifacts. | Integration tests | Yes |
| `AC-24` | Essence and M04C core residual authority are not duplicated or changed. | Ownership tests | Yes |
| `AC-25` | Linux focused/import/trace/full checks pass. | Commands/exits | Yes |
| `AC-26` | Windows package passes full/focused/import/14-marker/cleanup/audit/full. | Owner log | Yes |
| `AC-27` | Junior-readable comments and maintained docs are synchronized. | Review | Yes |
| `AC-28` | Actual scope remains within assessment or work stopped for revised approval. | Handoff | Yes |

A pending owner result keeps M04D2 verification Partial and prevents merge.

## Automated verification

### Codex Cloud or Linux

Run:

```bash
git status --short

./tools/test/run_gut.sh -- \
  -gdir=res://tests/unit/m04d2 \
  -gdir=res://tests/integration/m04d2

godot --headless --path . --import

trace_root="$(mktemp -d)"
godot --headless --path . \
  -s res://tools/test/m04d2/m04d2_channel_accumulation_trace.gd \
  -- --save-root "$trace_root"
trace_exit=$?
rm -rf "$trace_root"
test ! -e "$trace_root"
test "$trace_exit" -eq 0

# Missing root must fail.
godot --headless --path . \
  -s res://tools/test/m04d2/m04d2_channel_accumulation_trace.gd
test "$?" -ne 0

./tools/test/run_gut.sh

git diff --check
git status --short
```

At minimum cover every group in `TESTING_AND_VALIDATION.md` §25, all exact fixtures, all fourteen markers, negative root handling, complete no-mutation failures, and forbidden-source ownership.

## Owner-run Windows automated checks

Codex must add:

```text
tools/test/owner/run_m04d2_owner_verification.ps1
```

Expected invocation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
    -File .\tools\test\owner\run_m04d2_owner_verification.ps1 `
    -CommitSha "<PR_HEAD_SHA>"
```

Adapt the final M04D1 runner rather than creating a new shortcut. Preserve:

1. explicit `-GodotBin`, then `GODOT_BIN`, then PATH discovery;
2. Git-optional SHA evidence;
3. one complete UTF-8 PR-head log;
4. full suite before;
5. focused M04D2 via in-process `-GutArgs` array;
6. explicit import;
7. isolated real-file trace;
8. stable copied output and all 14 exact markers;
9. `finally` cleanup plus absence proof;
10. prior ignored-log tolerance and artifact audit;
11. full suite after;
12. standardized summary and nonzero failure exit.

Expected summary:

```text
Automated result: PASS
Failed step count: 0
Pending interactive checks: None for M04D2
Cleanup result: PASS
```

No interactive checklist is required.

## Trace markers

```text
TRACE M04D2 content_revision=prototype-content-r2_non_essence_settled=1000000
TRACE M04D2 gloamwood_2h_soldier=24_scribe_progress=250000
TRACE M04D2 gloamwood_8h_soldier=96_scribe_banked=1
TRACE M04D2 broken_watch_6h_provisions=720_maa_progress=250000
TRACE M04D2 broken_watch_24h_provisions=2880_maa_banked=1
TRACE M04D2 locked_channel_no_production_or_creation=PASS
TRACE M04D2 late_unlock_no_backfill=PASS
TRACE M04D2 recall_freezes_redispatch_resumes=PASS
TRACE M04D2 settlement_channel_segmentation=PASS
TRACE M04D2 one_shot_equals_chunks=PASS
TRACE M04D2 banking_events_ordered=PASS
TRACE M04D2 schema_v3_round_trip=PASS
TRACE M04D2 no_duplicate_essence_or_reaping_progress=PASS
TRACE M04D2 no_clock_or_later_slice_sources=PASS
```

## Save/load verification

| Scenario | Setup | Expected after reload |
|---|---|---|
| Gloamwood partial | 2h produced state | Soldier inventory/history 24; Scribe progress 250000 |
| Gloamwood whole | 8h produced state | Soldier 96; Scribe 1; normalized residuals |
| Broken Watch partial | 6h produced state | Provisions 720; MAA progress 250000 |
| Broken Watch whole | 24h produced state | Provisions 2880; MAA 1 |
| Settled | Boundary-crossed channel state | Exact lifecycle, inventory, history, progress/carry; no repeated event |
| Inactive | Recalled partial source | Exact frozen channel state plus advanced timeline |
| Historical revision | v3/r1 fixture | Loads under r2 compatibility without schema rewrite |
| New save | Produced runtime | Schema 3 and content revision r2 |
| Artifact audit | Inspect snapshot | No events, deltas, effective rates, ETAs, or Essence acquisition |

## Documentation updates

Update canonical sections in:

- `docs/codex/MILESTONES.md`;
- `docs/codex/ARCHITECTURE.md`;
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`;
- `docs/codex/TESTING_AND_VALIDATION.md`;
- `docs/codex/DECISIONS.md` only if implementation uncovers a genuine conflict requiring a new owner-approved decision; do not weaken accepted `DEC-0038` through implementation shortcuts;
- `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md` only if implementation reveals a wording conflict;
- `README.md` only if the developer trace command is useful.

Do not add duplicate M04D2 sections.

## Stop conditions

Stop and report if:

1. M04D1 is not actually merged/passed;
2. simulation must auto-create access/source state;
3. channel accumulation requires schema version 4;
4. exact content revision 2 compatibility cannot be preserved;
5. output-channel modifiers or changed-loadout behavior are required now;
6. another primary owner or more than two cross-layer seams is needed;
7. source/test files exceed approximately 30 or code/test lines exceed approximately 1,500;
8. per-unit replay/events or a dependency/framework is required;
9. any exact fixture, no-mutation check, trace, or regression fails.

## Final response format

Use exactly:

### Implementation completed
### Files changed
### Verification
### Assumptions
### Known limitations and risks
### Deferred work
### Suggested next task

Under **Files changed**, include actual-versus-estimated source/test file count and code/test line delta.  
Under **Verification**, leave Windows owner verification pending.  
Under **Suggested next task**, state only that the owner should run the M04D2 Windows package. Do not draft M04D3.
