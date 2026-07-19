# Implementation slice M04E1: Forecast clone and supplied-resolution adapters

**Prompt version:** v0.2  
**Prompt date:** 2026-07-19  
**Prompt status:** Approved  
**Work item type:** Implementation slice  
**Parent conceptual epic:** `M04 — Persistent Reaping simulation vertical slice` / M04E sub-epic  
**Milestone definition:** `docs/codex/MILESTONES.md` — `### M04E1 — Forecast clone and supplied-resolution adapters`  
**Recommended task size:** Small-medium; one projection/adapter pull request  
**Scope-gate result:** Within approved guardrails; stop if actual work needs another primary owner, more than two cross-layer seams, more than approximately 25 non-documentation source/test files, or more than approximately 1,200 non-documentation code/test lines  
**Expected base branch or ref:** current `main` after M04D3 merge commit `9fd8f98e3787f711f3d03c9de03d3615d531216a`; planning observed `main` at `de0824f1098cf974aa864d689a6139073b2a53a5`  
**Planned prompt path:** `docs/codex/milestone-prompts/M04E1-forecast-clone-resolution-adapters.md`

> This prompt authorizes one explicit-duration run adapter, detached current-state clone forecasts, exact forecast/commit equivalence, one-hour/eight-hour/Settlement demonstrations, and the M04E1 verification package. It does not authorize report state, report persistence, hypothetical command replay, clocks, trusted time, application lifecycle, UI, concurrency, Halls, progression, schema/content revisions, or M04E2.

## Approval record

The project owner accepted `DEC-0040`, approved the M04E1/M04E2 decomposition, and approved M04E1 prompt v0.2 on 2026-07-19 with these refinements:

- forecasting must preserve complete core-stream results, not only discrete item-channel output;
- the eight-hour fixture includes Returned Souls, Essence, Mastery, cycles, and every current initialized eligible output channel;
- `SimulationRunService` must be channel-kind agnostic and contain no whitelist of current Threshold/channel/item IDs or output kinds;
- a future Threshold channel kind becomes forecastable by extending normalized content/state and `SimulationEngine`, while the forecast adapter and result family remain unchanged;
- unsupported future mechanics fail visibly rather than being omitted or approximated.

Current status:

```text
DEC-0040: Accepted
M04E decomposition: Approved
M04E1 prompt: Approved v0.2
M04E1 implementation: Not started
GATE-FORECAST-CLONE: Satisfied
M04E2 definition: Approved
M04E2 prompt: Not drafted
```

Do not draft or implement M04E2 in this task.

## Execution protocol

Before editing:

1. Read `AGENTS.md` completely.
2. Read every source under **Authoritative context**.
3. Inspect current `main`, `git status --short`, merged M04D3 implementation/tests/docs, and the current three `.uid` companions added after the M04D3 merge.
4. Verify PR #15 merged from final head `5a5cafc6b640001fba86c7ea9531ae9daf43fcc3` at merge commit `9fd8f98e3787f711f3d03c9de03d3615d531216a`.
5. Verify schema version 3 and content revision `prototype-content-r2` remain current.
6. Inspect `GameState.deep_clone()`, `GameStateValidator`, `SimulationEngine`, `ReapingRateContextService`, `M04CDebugAdvance`, schema-v3 mapper/coordinator/storage, final M04D3 trace, and final owner runner.
7. State the proposed `SimulationRunService` API, mode/result types, clone-detachment method, complete canonical-comparison method, exact fixtures, expected files, cross-layer seams, and verification plan before non-trivial edits.
8. Reassess scope. Stop before implementation if report authority, a save migration, hypothetical command replay, clock sampling, trusted-time acquisition, application lifecycle, UI, concurrency, Halls, milestones, tutorial, progression, another primary owner, or another broad subsystem becomes necessary.

During implementation:

- Add one bounded `SimulationRunService`; do not create separate forecast/live/offline/debug formula owners.
- Keep all gameplay formulas and mutations in `SimulationEngine`.
- Treat run mode as non-persisted wrapper metadata only.
- Validate before clone or commit.
- Deep-clone through the existing authoritative state contract.
- Return a projected state only for successful forecasts.
- Prove that baseline and projection share no mutable nested gameplay object.
- Preserve exact engine result, segments, deltas, and events rather than reconstructing them.
- Keep current-state forecast only; do not implement command replay.
- Route `M04CDebugAdvance` through the shared run service without changing gameplay behavior.
- Do not write a save, append report state, request a checkpoint, or emit tutorial presentation from forecast.
- Keep schema v3/content r2 and production content unchanged.
- Add exact no-mutation tests for every failure.
- Add junior-readable comments explaining clone ownership, mode metadata, one-engine delegation, result detachment, and deferred report/trusted-time boundaries.
- Create the real-file trace and final-pattern Windows owner package.
- Report exact commands, counts, markers, exits, and actual-versus-estimated scope.
- Leave Windows owner verification pending until the owner supplies the generated log.
- Do not draft or implement M04E2.

Do not describe M04E1 as complete while any merge-gate criterion is failed, blocked, or pending.

## Objective

Add one scene-independent adapter service that can commit an explicitly supplied duration through the existing simulation engine or forecast that same duration on a detached deep clone, preserving complete core-stream and generic Threshold-channel results with exact canonical equivalence and no report/save/time-source side effects.

## Player or developer outcome

From focused tests and one headless trace, a developer can:

- forecast one hour and eight hours from a canonical Gloamwood state, including Returned Souls, Essence, Mastery, cycles, and every initialized eligible channel;
- inspect the exact projected state, segments, generic stable-ID channel deltas, and events;
- prove a Broken Watch resource channel and Whole-Soul channel pass through without a forecast-service type branch;
- prove the live baseline and source save remain byte-for-byte unchanged;
- commit the same duration on another clone and obtain complete canonical equality;
- cross the Overdue-to-Settled boundary identically in forecast and commit;
- invoke foreground-supplied, offline-fixture, and debug modes and obtain the same committed result;
- prove one-shot and chunked runs match;
- prove invalid inputs and unsupported states leave the baseline unchanged;
- run one Windows PowerShell command and share a complete UTF-8 log.

## Authoritative context

| Priority | Source | Required sections or records | Why it applies |
|---:|---|---|---|
| 1 | `AGENTS.md` | Full file | Repository rules and source hierarchy |
| 2 | `docs/codex/MILESTONES.md` | M04, completed M04D3, approved M04E/M04E1/M04E2, gates, guardrails | Slice authority |
| 3 | `docs/codex/DECISIONS.md` | `DEC-0010`, `DEC-0012`, `DEC-0016`, `DEC-0026`–`DEC-0028`, `DEC-0033`, `DEC-0036`, `DEC-0038`–`DEC-0040` | One-engine, clone, reporting, and scope rules |
| 4 | `docs/codex/ARCHITECTURE.md` | M04C–M04D3 realized boundaries; approved M04E decomposition/M04E1 | Ownership and seams |
| 5 | `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | State cloning, schema v3, simulation results/events, M04D3 results, approved M04E1 contracts | Exact data rules |
| 6 | `docs/codex/IMPLEMENTATION_RULES.md` | §§4–6, 8, 10–11, 14, 17 | Typing, comments, determinism, forecast mode, serialization |
| 7 | `docs/codex/TESTING_AND_VALIDATION.md` | §§26–27 and owner workflow | Evidence |
| 8 | `docs/codex/OWNER_VERIFICATION_WORKFLOW.md` | Complete | Windows packaging |
| 9 | `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md` | IF-REQ-02, IF-REQ-03, IF-REQ-07, IF-REQ-08, reports/forecasts | Product invariants |
| 10 | `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md` | Required end state, P90-SAFE-06, P90-SAFE-11, P90-B12 | Prototype forecast/report boundary |
| 11 | Current implementation | `GameState`, `SimulationEngine`, `ReapingRateContextService`, `M04CDebugAdvance`, schema-v3 persistence, M04D3 tests/trace/runner | Actual baseline |

Report unresolved conflicts before implementing.

## Repository state

| Item | Expected state |
|---|---|
| Completed slices | M04A, M04B, M04C, M04D1, M04D2, M04D3 Merged/Passed |
| Save | Schema v3 with production v1→v2→v3 path; `JSON_V1` |
| Content | `prototype-content-r2`; r1/r2/m02 compatibility |
| State | Explicit deep-cloneable `GameState`; no report accumulator/history fields |
| Simulation | Transactional explicit-duration zero/one-active Reaping resolver |
| Rates | Shared M04D3 output-channel rate plan and exact current-context ETA |
| Debug | `M04CDebugAdvance` directly delegates to `SimulationEngine` |
| Forecast | No bounded clone-forecast service |
| Report | No authoritative report service/state |
| UI/application | No gameplay shell or player-facing forecast/report screen |
| Working tree | Clean except task changes |

## Dependencies and gates

| Dependency/gate | Required state | Verification |
|---|---|---|
| M04D3 | Merged and Passed | Merge/evidence record |
| `DEC-0040` | Accepted or replaced by owner-approved contract | Decision record |
| `GATE-FORECAST-CLONE` | Satisfied at prompt approval | Milestone map |
| `GATE-SLICE-SCOPE` | Remains within limits | Prompt/handoff |
| `SimulationEngine` | Sole formula/mutation owner | Source audit and equality tests |
| Schema/content | v3/r2 unchanged | Persistence/content tests |
| Windows environment | Godot 4.7 console executable | Owner package |

## Scope and review-surface assessment

| Assessment item | Approved estimate |
|---|---|
| Parent conceptual epic | M04 / M04E |
| Primary subsystem owner | New bounded `SimulationRunService` |
| Principal transition | Valid baseline + explicit elapsed + mode → committed engine result or detached projected result |
| New authoritative aggregate family | None |
| Save-schema change | None; schema v3 remains current |
| Content compatibility change | None; `prototype-content-r2` remains current |
| Deterministic algorithms | Clone detachment, canonical equality, mode delegation, generic stream/channel passthrough |
| Cross-layer seams | 2: run service → simulation; trace/integration → persistence fixture |
| Risk dimensions | Non-authoritative projection, execution-mode equivalence, detachment/evidence, channel extensibility |
| Expected non-documentation source/test files | Approximately 8–16 |
| Expected non-documentation code/test delta | Approximately 650–1,100 lines |
| Bulk authored content | None; copied state fixtures only |
| Platform/native work | None |
| Interactive owner checks | None |
| Automated owner checks | One generated PowerShell log |
| Mandatory split trigger | Not crossed at approval |

Stop for a revised prompt before adding another primary owner, report state, a migration, another broad integration seam, more than approximately 25 non-documentation source/test files, or more than approximately 1,200 non-documentation code/test lines.

## Required behavior

| ID | Requirement | Authority |
|---|---|---|
| `RB-01` | Add one scene-independent `SimulationRunService`; do not create parallel mode services. | `DEC-0040` |
| `RB-02` | `SimulationEngine` remains the sole production formula and authoritative mutation owner. | `DEC-0010` |
| `RB-03` | The run service reads no clock, frame, scene, file, platform, report, tutorial, or UI state. | Architecture |
| `RB-04` | Every run receives explicit integer `elapsed_msec`. | Time contract |
| `RB-05` | Supported modes are exactly `FOREGROUND_SUPPLIED`, `OFFLINE_FIXTURE`, `DEBUG`, and `FORECAST`. | `DEC-0040` |
| `RB-06` | Mode is metadata only and never changes formulas, channels, boundaries, ordering, or gains. | One-engine rule |
| `RB-07` | Committed modes invoke `SimulationEngine.resolve_elapsed()` on the supplied state. | Architecture |
| `RB-08` | Forecast validates then deep-clones the baseline and invokes the same engine on the clone. | `DEC-0016` |
| `RB-09` | Forecast never mutates the supplied baseline. | `DEC-0016` |
| `RB-10` | Forecast and baseline share no mutable nested gameplay object after return. | Clone contract |
| `RB-11` | Mutating the projection cannot change baseline; mutating baseline later cannot change projection. | Detachment contract |
| `RB-12` | A failed forecast returns no projected state and preserves baseline exactly. | Transaction contract |
| `RB-13` | A successful committed mode returns no projected state. | Result contract |
| `RB-14` | Return the exact engine result rather than reconstructing summaries, segments, deltas, or events. | One-engine rule |
| `RB-15` | Result mode and projection metadata never enter authoritative state or engine events. | Persistence boundary |
| `RB-16` | M04E1 forecasts current authoritative configuration only. | Slice boundary |
| `RB-17` | Do not implement hypothetical command replay or a generic command script. | Slice boundary |
| `RB-18` | Do not create, ingest, snapshot, clear, or persist report state. | M04E2 boundary |
| `RB-19` | Forecast never invokes save/checkpoint APIs. | `DEC-0016` |
| `RB-20` | Forecast never invokes tutorial, progression, guarantee, milestone, or resonance processing. | Slice boundary |
| `RB-21` | Foreground/offline/debug adapters do not acquire elapsed time. | M05/M06 boundary |
| `RB-22` | Run mode, run result, projection, and comparison data are non-persisted. | Data contract |
| `RB-23` | Schema version 3 and content revision r2 remain unchanged. | Compatibility |
| `RB-24` | Complete canonical equality uses schema-v3 mapping or an equivalent all-field comparison. | Evidence contract |
| `RB-25` | Forecast and separately committed clone are canonically equal for unchanged state/content. | M04E1 outcome |
| `RB-26` | One-hour copied fixture yields the exact approved core and channel values. | Test contract |
| `RB-27` | Eight-hour copied fixture yields 33,120 Returned Souls, 2,880 Essence, 480,000,000 Mastery subunits, 480 cycles, 96 Soldier Souls, and one Scribe Form Soul with zero remainder. | Prototype forecast |
| `RB-28` | A copied low-backlog fixture proves exact Settlement segmentation and event order. | `DEC-0036` |
| `RB-29` | Foreground-supplied, offline-fixture, and debug committed modes are canonically equal. | IF-REQ-07 |
| `RB-30` | `M04CDebugAdvance` delegates through the shared run service. | Adapter boundary |
| `RB-31` | One-shot and equivalent regular/irregular chunks are canonically equal. | Determinism |
| `RB-32` | Zero-duration forecast returns a detached unchanged projection. | Result contract |
| `RB-33` | Zero-duration committed mode retains existing engine semantics. | Regression |
| `RB-34` | Negative duration and invalid state fail without mutation. | Transaction contract |
| `RB-35` | Engine overflow/content/unsupported-flow/Retinue/concurrency errors pass through without partial mutation. | Regression |
| `RB-36` | Forecast preserves M04D1 access, M04D2 source, and M04D3 rate-plan semantics. | Prior slices |
| `RB-37` | Forecast events and deltas are detached projection evidence and are never ingested as committed reports. | `DEC-0040` |
| `RB-38` | A production-persistence fixture proves baseline save bytes are unchanged by forecast. | Integration evidence |
| `RB-39` | Trace negative-root cases never access normal `user://` save state. | Owner workflow |
| `RB-40` | Source audit proves no clock, scene, storage dependency, report service, platform API, or duplicate formula in the run service. | Architecture |
| `RB-41` | Add junior-readable documentation for clone ownership, mode metadata, delegation, and deferred boundaries. | Project rule |
| `RB-42` | Add focused unit/integration tests, real-file trace, Windows owner runner, and synchronized docs. | Merge gate |
| `RB-43` | Report actual source/test scope against the approved estimate. | `DEC-0033` |
| `RB-44` | Do not draft or implement M04E2. | Prompt boundary |
| `RB-45` | `SimulationRunService` must not hard-code current Threshold IDs, channel IDs, output item IDs, or output kinds. | Owner refinement |
| `RB-46` | Forecast preserves every core stream and every initialized, eligible engine-supported Threshold channel through complete projected state plus generic stable-ID deltas/events. | Owner refinement |
| `RB-47` | Future channel kinds extend normalized content/state and `SimulationEngine`; the run service and result family require no type-specific branch. Unsupported kinds fail visibly. | Extensibility contract |

## Required state transitions

| ID | Transition | Required result |
|---|---|---|
| `ST-01` | Valid baseline + one-hour `FORECAST` | Detached exact projection; baseline unchanged |
| `ST-02` | Same baseline clone + one-hour committed mode | Canonically equal to forecast projection |
| `ST-03` | Valid baseline + eight-hour `FORECAST` | Exact complete core + 96 Soldier / 1 Scribe result |
| `ST-04` | Low-backlog baseline + boundary-crossing forecast | Exact Overdue/Settled segmentation |
| `ST-05` | Same state/duration under three committed modes | Equal state, result, segments, deltas, events |
| `ST-06` | Debug adapter + explicit duration | Same nested engine result as direct run service |
| `ST-07` | One-shot versus regular chunks | Canonical equality |
| `ST-08` | One-shot versus irregular chunks | Canonical equality |
| `ST-09` | Zero-duration forecast | Detached unchanged projection |
| `ST-10` | Zero-duration committed mode | Existing engine zero-duration result; no mutation |
| `ST-11` | Negative duration | Typed failure; no mutation |
| `ST-12` | Invalid/unsupported engine state | Exact error passthrough; no mutation |
| `ST-13` | Mutate projection after return | Baseline unchanged |
| `ST-14` | Mutate baseline after forecast | Projection unchanged |
| `ST-15` | Load real schema-v3 fixture then forecast | Projection succeeds; source save bytes unchanged |
| `ST-16` | Inspect snapshot after all runs | No run/projection/result/report artifacts |
| `ST-17` | Broken Watch with initialized Provisions and Whole-Soul channels + forecast | Both channel kinds appear through generic projected state/deltas and equal committed results |
| `ST-18` | Source audit of run service | No current channel/item/output-kind whitelist or type-specific forecast branch |

## Implementation requirements

### 1. SimulationRunService

Create one bounded service, expected under:

```text
src/simulation/simulation_run_service.gd
```

The final path may differ only to follow repository conventions.

Expected public methods:

```text
run_committed(state, elapsed_msec, mode) -> SimulationRunResult
forecast(state, elapsed_msec) -> SimulationRunResult
```

`run_committed()` accepts only committed modes. `forecast()` assigns the `FORECAST` mode internally. Invalid mode/method combinations return typed failures without mutation.

### 2. Result contract

Use a named result class or equivalently strict bounded record containing the approved fields. Do not expose an ambiguous dictionary whose success and failure shapes differ unpredictably.

The result must not retain the baseline state reference. `projected_state` is present only for successful forecast.

### 3. Complete clone detachment

Use `GameState.deep_clone()` and verify every current nested family:

```text
inventory / entries / reservations
forms
thresholds / channel acquisition
reapings / residual dictionaries / Retinue arrays
progression / unlocked item array
```

Do not add reflection cloning or JSON encode/decode cloning.

### 4. Canonical comparison

Tests and trace compare complete current gameplay state through `SaveSchemaMapper.runtime_to_snapshot()` or the repository's complete canonical helper. Comparing only inventory, return totals, or selected fields is insufficient.

### 5. Generic stream and channel coverage

The run service returns the exact engine result and full projected state. It must not create a reduced forecast DTO that enumerates only the current Gloamwood channels.

Tests and trace must verify:

- core summary coverage for Returned Souls/backlog, Essence, Mastery, completed cycles, and lifecycle;
- complete `ThresholdState.channel_acquisition` projection for every initialized channel;
- generic segment and summary `channel_deltas` keyed by stable `channel_id`;
- a Broken Watch fixture containing both a `RESOURCE` channel and a Whole-Soul channel;
- no current Threshold/channel/item ID or output-kind whitelist in `SimulationRunService`.

A new channel kind may require deterministic arithmetic support in `SimulationEngine`, but once supported it must flow through forecast without modifying `SimulationRunService` or inventing another result family. Unsupported kinds pass through the engine's typed failure.

### 6. Debug adapter

Refactor `M04CDebugAdvance` to delegate to `SimulationRunService` in `DEBUG` mode. Preserve the existing `advance_msec()` return behavior where practical so later debug callers are not broken solely for wrapper aesthetics.

Do not add a Node, autoload, editor plugin, or UI control.

### 7. Persistence evidence

Use production `SaveService`, storage, and `GameStatePersistenceCoordinator` in integration/trace setup to create or load an isolated schema-v3 fixture. Record the primary bytes before forecast and compare them after forecast.

The run service itself must have no persistence dependency and must not know the trace root.

### 8. Exact fixture construction

Use copied state fixtures and current production content. Do not change `.tres` balance or content revision.

The one-hour and eight-hour fixtures must remain Overdue throughout. The eight-hour assertions cover Returned Souls, Essence, Mastery, cycles, Soldier Souls, Scribe Form Souls, and the exact Scribe remainder. Use a separate Broken Watch fixture for generic resource/Whole-Soul channel passthrough and a separate low-backlog fixture for Settlement.

### 9. Event and result equality

Compare:

- success/error fields;
- requested/committed elapsed;
- complete change summary;
- every segment field and channel delta;
- every event field and payload;
- canonical resulting state.

Wrapper mode metadata is the only expected difference among equivalent committed modes.

## Required test matrix

Cover all twenty groups in `TESTING_AND_VALIDATION.md` §27. Prefer compact table-driven cases and one clear fixture builder.

For every failure, compare complete canonical baseline state before/after and prove no projected state was returned.

## Trace contract

Create:

```text
tools/test/m04e1/m04e1_forecast_trace.gd
```

It must:

1. require explicit nonblank `--save-root`;
2. reject `user://`;
3. use the supplied root only for isolated fixture persistence;
4. leave root deletion to the owner runner;
5. check every result before reading it;
6. print each marker only after its complete assertions pass;
7. exit nonzero on any mismatch;
8. use production persistence for the save-byte proof;
9. audit source ownership;
10. emit exactly:

```text
TRACE M04E1 forecast_1h_returns=4140_essence=360_mastery=60000000_cycles=60_soldier=12_scribe_progress=125000
TRACE M04E1 forecast_8h_returns=33120_essence=2880_mastery=480000000_cycles=480_soldier=96_scribe_banked=1
TRACE M04E1 generic_channel_passthrough=PASS
TRACE M04E1 baseline_unchanged_and_projection_detached=PASS
TRACE M04E1 forecast_equals_committed_clone=PASS
TRACE M04E1 settlement_boundary_equivalence=PASS
TRACE M04E1 foreground_offline_fixture_debug_equivalent=PASS
TRACE M04E1 debug_adapter_uses_shared_runner=PASS
TRACE M04E1 one_shot_equals_chunks=PASS
TRACE M04E1 zero_and_failure_no_mutation=PASS
TRACE M04E1 events_and_deltas_match_engine=PASS
TRACE M04E1 schema_v3_content_r2_unchanged=PASS
TRACE M04E1 isolated_save_bytes_unchanged=PASS
TRACE M04E1 no_report_tutorial_or_checkpoint_side_effects=PASS
TRACE M04E1 no_clock_scene_platform_or_duplicate_rules=PASS
```

## Owner-run Windows automated checks

Codex must add:

```text
tools/test/owner/run_m04e1_owner_verification.ps1
```

Expected invocation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
    -File .\tools\test\owner\run_m04e1_owner_verification.ps1 `
    -CommitSha "<PR_HEAD_SHA>"
```

Adapt the final M04D3 runner. Preserve:

1. explicit `-GodotBin`, then `GODOT_BIN`, then PATH discovery;
2. Git-optional SHA evidence;
3. one complete UTF-8 PR-head log;
4. Godot 4.7 version validation;
5. full suite before;
6. focused unit + integration directories;
7. explicit import;
8. isolated real-file trace;
9. stable copied trace output and all fifteen markers;
10. `finally` cleanup and absence proof;
11. prior ignored-log tolerance and artifact audit;
12. full suite after;
13. standardized summary and nonzero failure exit.

Expected summary:

```text
Automated result: PASS
Failed step count: 0
Pending interactive checks: None for M04E1
Cleanup result: PASS
Log path: <generated path>
```

No interactive checklist is required.

## Acceptance criteria

| ID | Criterion | Evidence | Merge gate |
|---|---|---|---|
| `AC-01` | M04D3 is Merged/Passed and `DEC-0040` is Accepted. | Docs/merge | Yes |
| `AC-02` | One bounded run-service owner serves committed and forecast modes. | Review/tests | Yes |
| `AC-03` | `SimulationEngine` remains the only formula/mutation owner. | Source audit | Yes |
| `AC-04` | Run service has no clock, frame, scene, storage, report, tutorial, UI, or platform dependency. | Source audit | Yes |
| `AC-05` | Mode metadata cannot change arithmetic or ordering. | Mode matrix | Yes |
| `AC-06` | Forecast leaves complete baseline state unchanged. | Canonical comparison | Yes |
| `AC-07` | Projection shares no mutable nested state with baseline. | Bidirectional mutation tests | Yes |
| `AC-08` | Failed forecast returns no projection and no mutation. | Failure matrix | Yes |
| `AC-09` | Forecast equals separately committed clone for the same interval. | Canonical comparison | Yes |
| `AC-10` | One-hour exact fixture matches all approved values. | Focused test/trace | Yes |
| `AC-11` | Eight-hour exact fixture matches all approved core values plus 96 Soldier Souls and one Scribe Form Soul. | Focused test/trace | Yes |
| `AC-12` | Settlement-boundary state, segments, and events match. | Copied fixture | Yes |
| `AC-13` | Foreground/offline-fixture/debug committed modes are equal. | Mode matrix/trace | Yes |
| `AC-14` | Debug adapter delegates through the shared run service. | Review/test | Yes |
| `AC-15` | Regular and irregular chunk equivalence pass. | Canonical comparison | Yes |
| `AC-16` | Zero-duration forecast returns a detached unchanged projection. | Unit test | Yes |
| `AC-17` | Negative/invalid/overflow/unsupported failures preserve baseline. | Failure matrix | Yes |
| `AC-18` | Engine summary, segments, deltas, and events are preserved exactly. | Equality tests | Yes |
| `AC-19` | M04D1–M04D3 access/rate semantics remain unchanged. | Regression tests | Yes |
| `AC-20` | Forecast produces no report, tutorial, progression, save, or checkpoint side effect. | Tests/source audit | Yes |
| `AC-21` | Production save bytes remain unchanged by forecast. | Integration/trace | Yes |
| `AC-22` | Schema v3/content r2 remain current. | Persistence/content tests | Yes |
| `AC-23` | No run/projection/result/comparison artifact serializes. | Snapshot audit | Yes |
| `AC-24` | Linux focused/import/trace/full commands pass. | Commands/exits | Yes |
| `AC-25` | All fifteen trace markers are earned and verified. | Trace/runner | Yes |
| `AC-26` | Windows package passes full/focused/import/trace/cleanup/audit/full. | Owner log | Yes |
| `AC-27` | Documentation and actual-versus-estimated scope evidence are complete. | Review/handoff | Yes |
| `AC-28` | No M04E2 or later-slice work enters the diff. | Diff/source audit | Yes |
| `AC-29` | Core-stream and generic channel coverage includes every initialized eligible engine-supported channel; the Broken Watch resource/Whole-Soul fixture passes. | Focused test/trace | Yes |
| `AC-30` | Source audit proves the run service has no current channel/item/output-kind whitelist and future engine-supported kinds need no adapter branch. | Source audit | Yes |

A pending owner result keeps M04E1 verification Partial and prevents merge.

## Automated verification

### Codex Cloud or Linux

Run:

```bash
git status --short

./tools/test/run_gut.sh -- \
  -gdir=res://tests/unit/m04e1 \
  -gdir=res://tests/integration/m04e1

godot --headless --path . --import

trace_root="$(mktemp -d)"
godot --headless --path . \
  -s res://tools/test/m04e1/m04e1_forecast_trace.gd \
  -- --save-root "$trace_root"
trace_exit=$?
rm -rf "$trace_root"
test ! -e "$trace_root"
test "$trace_exit" -eq 0

godot --headless --path . \
  -s res://tools/test/m04e1/m04e1_forecast_trace.gd
test "$?" -ne 0

./tools/test/run_gut.sh

git diff --check
git status --short
```

Report exact focused/full counts, all fifteen markers, negative-root result, commands, exit codes, and actual scope.

Leave actual Windows owner verification pending.

## Save/load verification

| Scenario | Setup | Expected result |
|---|---|---|
| Loaded forecast | Production coordinator loads current v3 fixture | Forecast succeeds; loaded baseline remains canonical-equal |
| Save-byte proof | Record primary bytes before forecast | Bytes identical after forecast |
| Projection audit | Map projected state only for comparison | Valid v3 snapshot, but never written by forecast service |
| Snapshot exclusion | Inspect baseline/current save | No mode, run result, projection, event, report, or comparison fields |
| Current v3 | Load current state | No migration or rewrite |

## Documentation updates

Update canonical sections in:

- `docs/codex/MILESTONES.md`;
- `docs/codex/ARCHITECTURE.md`;
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`;
- `docs/codex/TESTING_AND_VALIDATION.md`;
- `docs/codex/DECISIONS.md` only if implementation exposes a genuine conflict requiring owner approval; do not weaken accepted `DEC-0040`;
- `README.md` only if the developer forecast command is broadly useful.

Do not add duplicate M04E1 sections or draft M04E2.

## Stop conditions

Stop and report if:

1. M04D3 is not actually merged/passed;
2. `DEC-0040` or a replacement contract is not approved;
3. complete detachment cannot be achieved through the existing explicit clone contract;
4. forecast requires report state, a save migration, or trusted-time acquisition;
5. current-state forecast requires hypothetical command replay;
6. schema version 4, content revision 3, or production content changes become necessary;
7. another primary owner or more than two cross-layer seams is needed;
8. source/test files exceed approximately 25 or code/test lines exceed approximately 1,200;
9. a second gameplay formula or mode-specific balance branch is proposed;
10. any exact fixture, no-mutation check, trace, persistence proof, or regression fails.

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
Under **Suggested next task**, state only that the owner should run the M04E1 Windows package. Do not draft M04E2.
