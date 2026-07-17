# Implementation slice M04C: Single-Reaping core resolver

**Prompt version:** v0.1  
**Prompt date:** 2026-07-17  
**Prompt status:** Approved  
**Work item type:** Implementation slice  
**Parent conceptual epic:** `M04 — Persistent Reaping simulation vertical slice`  
**Milestone definition:** `docs/codex/MILESTONES.md` — `### M04C — Single-Reaping core resolver`  
**Recommended task size:** Medium; one deterministic core-stream simulation pull request  
**Scope-gate result:** Approved within guardrails; mandatory stop if actual work needs another primary owner, more than two cross-layer seams, more than approximately 30 non-documentation source/test files, or more than approximately 1,500 non-documentation code/test lines  
**Expected base branch or ref:** current `main` after M04B merge commit `c641d74cebedf07c51ebb579cccee21db7aa2410`  
**Planned prompt path:** `docs/codex/milestone-prompts/M04C-single-reaping-core-resolver.md`

> This prompt authorizes only one transactional elapsed-time resolver for the core streams of zero or one active Reaping: returned souls/backlog, Essence, active Form Mastery, cycle state, and exact Overdue-to-Settled segmentation. It does not authorize discrete non-Essence output channels, Retinue/support behavior, progression effects, forecasts, reports, concurrent Reapings, UI, or platform integration.

## Approval record

The project owner approved M04C prompt v0.1 and accepted `DEC-0036` on 2026-07-17.

The approved core contract includes:

- one transactional `SimulationEngine` primary owner;
- zero or one active Reaping support in M04C;
- no-active timeline advancement without production;
- exact Overdue-to-Settled segmentation;
- separate returned-soul, Essence, Mastery, cycle, and Threshold-channel residual ownership;
- no schema-version bump;
- explicit failure for unsupported Retinue, concurrency, modifier, or nonzero unknown-carry state.

Do not execute an alternate rate, lifecycle, residual, concurrency, or mutation model without a new owner-approved decision.

## Execution protocol

Before editing:

1. Read `AGENTS.md` completely.
2. Read every source listed under **Authoritative context**.
3. Inspect current `main`, the merged M04B implementation/tests/docs, and `git status --short`.
4. Verify PR #9 merged at `c641d74cebedf07c51ebb579cccee21db7aa2410` from final head `5301c94bfd0fb837f9961fda624d7559042327e2`.
5. Verify M04B is recorded Merged/Passed.
6. Verify schema version 2 remains current and the existing `flow_carry_units`, cycle, inventory, Form, Threshold, and simulation-time fields can represent M04C without a schema bump.
7. Verify the normalized production values for Gloamwood, its Essence channel, Man-at-Arms, and Old Drill.
8. State the proposed `SimulationEngine` API, candidate-commit boundary, rate-plan shape, fixed-point helpers, residual-key constants, event/result types, boundary algorithm, expected files, and verification plan before non-trivial edits.
9. Re-evaluate the scope assessment. Stop before implementation if the work requires discrete output channels, Retinues, progression processing, reports, forecasts, concurrent active Reapings, a schema bump, application-shell wiring, or another primary owner.

During implementation:

- Limit changes to M04C and its binary criteria.
- Use one `SimulationEngine` primary owner; small rate-plan/result/debug helper types may support it without becoming independent rule engines.
- Resolve on a deep clone; commit the complete candidate once.
- Validate all arithmetic, rate, lifecycle, residual, content, and state conditions before live replacement.
- Use only normalized integer registry records.
- Use central checked fixed-point helpers; do not use floats in authoritative resolution.
- Read no clock, frame delta, scene tree, Steam, file metadata, or UI state.
- Keep returned souls, Essence, Mastery, cycles, and long-horizon acquisition progress under their approved owners.
- Segment exactly at Settlement and apply old rates through the boundary.
- Do not process deferred milestones, Writ transitions, guarantees, reports, tutorial, or discovery.
- Add junior-readable comments explaining the transaction, rate plan, boundary search, residual keys, whole extraction, Settlement order, and future extension seams.
- Add every test needed to prove exact state and no-mutation failures.
- Create the M04C trace and Windows owner package.
- Report exact commands, counts, markers, exit codes, and actual-versus-estimated scope.
- Leave owner Windows verification pending until the owner supplies a generated log for the tested PR head.
- Do not draft M04D.

Do not describe M04C as complete while any merge-gate criterion is failed, blocked, or pending.

## Objective

Implement a deterministic scene-independent `SimulationEngine` that advances the global simulation timeline and, when exactly one Reaping is active, resolves returned souls/backlog, Essence, active Form Mastery, cycle state, operation-owned residuals, and the exact Overdue-to-Settled boundary through one transactional candidate commit.

## Player or developer outcome

From focused tests and one headless trace, a developer can:

- resolve 60 seconds of Overdue Gloamwood production and obtain exactly 69 returned souls, 6 Essence, 1,000,000 Mastery subunits, and one cycle;
- resolve the same duration in several chunk patterns and obtain identical authoritative state;
- start with one backlog soul, resolve ten seconds, and prove Settlement occurs exactly at 870 milliseconds;
- prove gains at the boundary use Overdue rates and only the remaining interval uses Settled rates;
- inspect exact returned-soul, Essence, and Mastery residuals;
- resolve again after Settlement without another Settlement event;
- advance simulation time with no active Reaping while producing nothing;
- prove inactive or unsupported concurrent configurations commit no production;
- save and reload the exact boundary-crossing state;
- run the complete Windows proof through one PowerShell command and shareable UTF-8 log.

## Authoritative context

| Priority | Source | Required sections, labels, or records | Why it applies |
|---:|---|---|---|
| 1 | `AGENTS.md` | Full file, especially source hierarchy, simulation invariants, state ownership, comments, tests, save/time, and scope rules | Repository contract |
| 2 | `docs/codex/MILESTONES.md` | §§3–7; `GATE-SLICE-SCOPE`; `GATE-CORE-RESOLUTION`; `### M04C` | Approved slice/gates |
| 3 | `docs/codex/MILESTONE_RECALIBRATION_PROPOSAL.md` | §§2–8 | Review-surface policy |
| 4 | `docs/codex/PROMPT_TEMPLATE.md` | Scope assessment and completion rules | Prompt governance |
| 5 | `docs/codex/OWNER_VERIFICATION_WORKFLOW.md` | Complete script/log/cleanup rules | Windows package |
| 6 | `docs/codex/DECISIONS.md` | `DEC-0007`, `DEC-0010`–`DEC-0012`, `DEC-0014`, `DEC-0019`, `DEC-0020`, `DEC-0023`, `DEC-0025`, `DEC-0026`, `DEC-0033`–`DEC-0035`, accepted `DEC-0036` | Simulation, numeric, assignment, scope |
| 7 | `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | §§2, 7.2–7.5, 9.3–9.9, 10–13, 17–18; M03/M04A/M04B contracts; approved M04C contract | Rates, state, residuals, events |
| 8 | `docs/codex/ARCHITECTURE.md` | §§5–11, 14.2, 19–20, 22–23; realized M04B; approved M04C boundary | Transaction/segmentation |
| 9 | `docs/codex/IMPLEMENTATION_RULES.md` | Deterministic simulation, arithmetic, collections, diagnostics, persistence, junior comments | Engineering rules |
| 10 | `docs/codex/TESTING_AND_VALIDATION.md` | §§3–6, 9–12, 15–16, 19–23 | Exact test/evidence package |
| 11 | `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md` | design pillars; `IF-REQ-01`–`IF-REQ-09`, `IF-REQ-15`, `IF-REQ-18`; technical boundaries | Persistent deterministic idle loop |
| 12 | `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md` | `P90-SAFE-06`, `P90-SAFE-10`, `P90-SAFE-13`; `P90-B04`; first-session acceptance | Core production behavior |
| 13 | Current implementation | M04A state/persistence; M04B assignment service/validator/tests/trace | Actual baseline |

This prompt is authoritative only within M04C. Report unresolved conflicts before implementing.

## Repository state

Expected baseline:

| Item | Expected state |
|---|---|
| Completed slices | M04A and M04B Merged/Passed |
| State | Typed inventory, Forms, Thresholds/acquisition, Reapings, tether capacity, simulation cursor |
| Assignment | Revision-guarded dispatch/recall/redispatch, stable operation identity, global invariants |
| Numeric utility | `FixedPoint.SCALE = 1_000_000`, checked period accumulation |
| Content | Gloamwood backlog/multiplier; Essence channel; MAA rates/cycle/Old Drill |
| Persistence | Schema v2 round-trips `flow_carry_units`, cycle state, inventory, Forms, Thresholds |
| Simulation | No production engine |
| UI/application | No gameplay shell or production loop |
| Working tree | Clean except task changes |

## Dependencies

| Dependency or gate | Required state | Required before | Verification |
|---|---|---|---|
| M04B | Merged and Passed | Implementation | PR #9 merge/evidence |
| `GATE-CORE-RESOLUTION` | `DEC-0036` Accepted or revised owner-approved contract | Implementation | Decision record |
| `GATE-SLICE-SCOPE` | Assessment remains within limits | PR/merge | Prompt/handoff |
| M03 content | Registry ready and production records unchanged | Resolution | Content tests |
| Schema v2 | Current; no M04C bump | Merge | Diff/save tests |
| Owner Windows | Godot 4.7 console executable discoverable | Merge | Generated M04C log |

## Scope and review-surface assessment

| Assessment item | Approved estimate or result |
|---|---|
| Parent conceptual epic | M04 |
| Primary subsystem owner | Transactional `SimulationEngine` |
| Principal behavior/state transition | Explicit elapsed duration → committed core Reaping state, including exact Settlement |
| New authoritative state ownership | Stable keys inside existing `flow_carry_units`; no new aggregate family |
| Save-schema or migration change | None |
| Deterministic algorithm/boundary work | Checked rate stacking, accumulation, whole extraction, analytical Settlement boundary, cycle aggregation |
| New player-facing UI flow | None |
| Native/platform integration | None |
| Bulk authored content | None |
| Live/offline/forecast equivalence | Foundation only; explicit supplied-duration and debug calls share one resolver |
| Exactly-once/transactional progression | Settlement event/lifecycle transition only; progression processor deferred |
| Independently testable domain services | One engine plus bounded rate/result/debug helpers |
| Cross-layer integration seams | Two: engine ↔ normalized content/state validation; resolved state ↔ existing persistence in tests |
| Estimated non-documentation source/test files | Approximately 12–22, excluding generated `.uid` files |
| Estimated non-documentation code/test line delta | Approximately 900–1,400, excluding `.uid` and documentation |
| Owner verification package | `tools/test/owner/run_m04c_owner_verification.ps1`; automated log only |
| Mandatory split trigger crossed? | No at draft; near upper normal line target |
| Exception rationale/approval evidence | Not applicable |

Stop and request replanning before exceeding approximately 30 non-documentation source/test files, 1,500 code/test lines, two cross-layer seams, or one primary subsystem owner.

## Scope

Implement only:

1. one transactional `SimulationEngine`;
2. explicit supplied-duration resolution;
3. a minimal debug adapter that delegates to the same engine;
4. zero- or one-active-Reaping support;
5. normalized core rate derivation;
6. narrow active-Form Trait modifier execution for core metrics;
7. returned-soul/backlog accumulation and whole extraction;
8. Essence accumulation and immediate inventory banking;
9. active Form Mastery accumulation;
10. cycle phase/completed count aggregation;
11. stable operation-owned residual keys;
12. exact Overdue-to-Settled segmentation and event;
13. typed simulation result, change summary, segment summaries, and events;
14. schema-v2 round trips;
15. focused tests, deterministic trace, Windows owner package, and synchronized docs.

## Non-goals

Do not implement or refactor:

1. Soldier/Form Soul, Provisions, or other discrete non-Essence channels;
2. Threshold acquisition/discovery progression;
3. Retinue modifiers, reservations, Rations, support, or fallback;
4. Hall production;
5. milestones, guarantees, resonances, unlock effects, or Emergency-to-Standard transition;
6. changed-loadout resolve-and-reconfigure orchestration;
7. more than one active Reaping;
8. forecasts, reports, offline reconciliation, foreground clock loop, or application shell;
9. scenes, UI, tutorial, narrative, audio, or visual effects;
10. Steam or another platform API;
11. schema version 3, migration, codec, content revision, or `.tres` balance changes;
12. persisted effective rates, ETAs, segment history, or events;
13. dependencies, a general expression engine, or unrelated cleanup.

## Required behavior

| ID | Required behavior | Source trace |
|---|---|---|
| `RB-01` | One `SimulationEngine` owns M04C elapsed production. | `DEC-0010`; accepted `DEC-0036` |
| `RB-02` | Engine receives state, ready registry, and explicit integer elapsed milliseconds. | Time architecture |
| `RB-03` | It reads no clock, frame, scene, Steam, file-time, or UI source. | `DEC-0010`, `IF-REQ-07` |
| `RB-04` | It resolves a deep-cloned candidate and commits live state once after full validation. | `DEC-0012` |
| `RB-05` | Every failure leaves exact state equality. | Transaction contract |
| `RB-06` | Negative elapsed rejects; zero elapsed is a no-op. | Numeric contract |
| `RB-07` | Positive success advances `simulation_time_msec` exactly by elapsed. | Timeline contract |
| `RB-08` | No active Reaping advances only the timeline. | Accepted `DEC-0036` |
| `RB-09` | Inactive records produce nothing and remain unchanged except global timeline. | `DEC-0035` |
| `RB-10` | More than one active Reaping rejects without mutation. | M04C boundary |
| `RB-11` | Non-empty Retinue configuration rejects as unsupported. | M04C non-goal |
| `RB-12` | Unknown nonzero flow keys reject; unknown zero keys remain preserved. | Residual ownership |
| `RB-13` | Active state/content references validate before rate derivation. | M04B/M04A validators |
| `RB-14` | Returned-soul base rate comes from active Form normalized content. | M03 content |
| `RB-15` | Supported Form Trait returned-soul multipliers apply deterministically. | `DEC-0014` |
| `RB-16` | Gloamwood Old Drill applies because its tags satisfy the condition. | M03 contract |
| `RB-17` | Settled returned-soul rate applies Threshold multiplier exactly once. | `IF-REQ-04` |
| `RB-18` | Essence uses the owning enabled `RES_ESSENCE` channel. | M03 channel contract |
| `RB-19` | Supported Essence-yield Form Trait multipliers apply deterministically. | Modifier grammar |
| `RB-20` | Settled Essence applies channel multiplier exactly once, not Threshold plus channel. | Accepted `DEC-0036` |
| `RB-21` | Mastery uses active Form rate and supported Mastery modifiers. | Form contract |
| `RB-22` | Settlement does not reduce Mastery. | Accepted `DEC-0036` |
| `RB-23` | Cycle cadence uses Form cycle duration and is lifecycle-independent. | M03 content |
| `RB-24` | Relevant unsupported modifier operation/scope/condition fails explicitly. | `DEC-0014` |
| `RB-25` | All rate multiplication is checked fixed-point floor arithmetic. | `DEC-0026` |
| `RB-26` | Returned-soul accumulation uses explicit period and rate carry. | `FixedPoint` contract |
| `RB-27` | Returned progress extracts whole returns and retains `< SCALE` remainder. | Numeric contract |
| `RB-28` | Every whole return increments `persistent_returns_total`. | Counter contract |
| `RB-29` | Overdue whole returns reduce backlog no lower than zero. | Threshold contract |
| `RB-30` | Settled whole returns leave backlog zero and continue the counter. | Accepted `DEC-0036` |
| `RB-31` | Essence accumulation uses separate progress/rate carry. | Residual contract |
| `RB-32` | Whole Essence is banked immediately in `RES_ESSENCE` inventory. | `IF-REQ-02` |
| `RB-33` | Mastery subunits add directly to active Form with separate rate carry. | Mastery contract |
| `RB-34` | Cycle phase/count aggregate analytically and check overflow. | Cycle contract |
| `RB-35` | Stable core residual keys and ranges are enforced. | Accepted `DEC-0036` |
| `RB-36` | Long-horizon `ThresholdAcquisitionState` is untouched. | `DEC-0027` |
| `RB-37` | Settlement boundary is the minimum integer millisecond reaching backlog zero. | Accepted `DEC-0036` |
| `RB-38` | Old rates apply through the boundary; new rates begin afterward. | Same-time ordering |
| `RB-39` | Boundary gains commit before lifecycle changes. | Architecture §10.4 |
| `RB-40` | Settlement sets zero backlog/`SETTLED` and emits one event. | `IF-REQ-04` |
| `RB-41` | Already-Settled resolution never emits Settlement again. | Exactly-once rule |
| `RB-42` | Zero-duration repeating boundaries fail rather than loop. | Architecture §10.5 |
| `RB-43` | Resolution is analytical/bounded, never per-frame/per-second/per-cycle replay. | `IF-REQ-08` |
| `RB-44` | Result contains exact committed elapsed, change summary, ordered segments, and events. | Result contract |
| `RB-45` | Debug advance delegates to the same resolver and formulas. | Architecture one-engine rule |
| `RB-46` | Schema version 2 persists exact core state without new keys outside existing maps. | `DEC-0034` |
| `RB-47` | No milestone, Writ transition, report, forecast, discovery, or tutorial side effect occurs. | M04C non-goals |
| `RB-48` | Actual scope is reported against the approved estimate. | `DEC-0033` |

## State transitions

| ID | Initial state | Trigger | Required result | Failure behavior |
|---|---|---|---|---|
| `ST-01` | Valid state, no active Reaping | Resolve positive elapsed | Timeline advances only | — |
| `ST-02` | Valid inactive operation | Resolve positive elapsed | Timeline advances; operation/outputs unchanged | — |
| `ST-03` | Two active operations | Resolve | No mutation | Unsupported concurrency |
| `ST-04` | Active Gloamwood/MAA Standard, zero residuals | Resolve 60,000 ms | 69 returns, 6 Essence, 1,000,000 Mastery, 1 cycle | Any mismatch fails |
| `ST-05` | Same as ST-04 | Resolve equivalent chunks | Exact same end state | Any difference fails |
| `ST-06` | One backlog, zero residuals | Resolve 869 ms | Backlog remains 1/Overdue | — |
| `ST-07` | Same start | Resolve 870 ms | Backlog 0/Settled at cursor +870; one event | — |
| `ST-08` | One backlog | Resolve 10,000 ms | Exact mixed Overdue/Settled fixture | — |
| `ST-09` | Same as ST-08 | Resolve 869 + 1 + 9,130 | Exact same state/event facts | — |
| `ST-10` | Already Settled | Resolve positive elapsed | Settled returns/Essence/Mastery/cycles continue | No Settlement event |
| `ST-11` | Active unknown nonzero flow | Resolve | No mutation | Unsupported flow state |
| `ST-12` | Active with Retinue | Resolve | No mutation | Unsupported configuration |
| `ST-13` | Any valid state | Resolve 0 | Exact no-op | — |
| `ST-14` | Counter/inventory/Mastery/time/cycle near INT64_MAX | Resolve overflowing interval | No mutation | Stable overflow error |
| `ST-15` | Boundary calculator cannot make state progress | Resolve | No mutation | Zero-boundary-loop error |
| `ST-16` | Resolved Overdue or Settled state | Save/load | Exact reconstruction | Invalid snapshot rejects |

## Core residual keys

Use exactly:

```text
FLOW_CORE_RETURNS_PROGRESS_SUBUNITS
FLOW_CORE_RETURNS_RATE_CARRY_UNITS
FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS
FLOW_CORE_ESSENCE_RATE_CARRY_UNITS
FLOW_CORE_MASTERY_RATE_CARRY_UNITS
```

Do not rename an existing serialized key after merge without migration/compatibility handling.

## Required hand-calculable fixtures

### Overdue 60 seconds

```text
returns = 69
Essence = 6
Mastery delta = 1000000 subunits
cycles completed = 1
cycle phase = 0
```

### One backlog, ten seconds

```text
Settlement boundary = 870 ms
persistent returns = 3
backlog = 0
lifecycle = SETTLED
return progress = 625375
return rate carry = 0
Essence whole = 0
Essence progress = 315250
Essence rate carry = 0
Mastery delta = 166666
Mastery rate carry = 40000
cycle phase = 10000
Settlement events = 1
```

## Result and event contract

Use bounded typed M04C records. Minimum result fields:

```text
success
error_code
developer_details
requested_elapsed_msec
committed_elapsed_msec
change_summary
segments
events
```

A failed result has no committed deltas, segments, events, or state mutation.

The Settlement event follows the domain-event minimum contract:

```text
event_type = THRESHOLD_SETTLED
occurred_simulation_msec = exact boundary cursor
priority = documented lifecycle priority
subject_id = Threshold ID
source_id = active Reaping/engine source or documented empty value
payload = primitive backlog/lifecycle/return facts
reportable = true
tutorial_relevant = true
```

Events are not persisted.

## Data and content

Use current production records without modifying them:

| Record | Required values |
|---|---|
| `FORM_MAN_AT_ARMS` | returned rate 1.0/1,000 ms; Mastery 1.0/60,000 ms; cycle 60,000 ms |
| `TRAIT_OLD_DRILL` | returned-soul ×1.15 when Threshold has Settlement or Martial tag |
| `THR_GLOAMWOOD` | backlog 1,000,000; tags Forest/Settlement; settled ×0.25 |
| `CHANNEL_GLOAMWOOD_ESSENCE` | Essence 1.0/10,000 ms; settled ×0.25 |
| `WRIT_STANDARD` | enabled representative Writ; no M04C transition behavior |

No `.tres` change is expected.

## Architecture constraints

- One primary owner: `SimulationEngine`.
- State/content/duration in; typed result out.
- One deep-cloned candidate and one live commit.
- No clocks, Nodes, autoload, or application shell.
- No file I/O in the engine.
- No float arithmetic in authoritative resolution.
- Stable sorted iteration and event ordering.
- No cached effective rates/ETAs.
- No duplicate residual ownership.
- No unknown nonzero flow ignored.
- No second active Reaping partially resolved.
- No Retinue silently ignored.
- No schema/content change.
- No deferred subsystem side effects.

## Expected files

| Path or area | Expected action | Purpose |
|---|---|---|
| `src/simulation/simulation_engine.gd` | Add | Sole core resolver |
| `src/simulation/` bounded rate/result/event helpers | Add only as needed | Typed deterministic support |
| `src/debug/` minimal debug advance wrapper | Add | Same-engine developer adapter |
| `src/domain/game_state.gd` | Narrow modify if explicit replace/copy boundary is needed | Atomic candidate commit |
| `src/domain/game_state_validator.gd` | Modify | Core residual ranges/invariants |
| `src/domain/fixed_point.gd` | Narrow modify | Checked scaled multiply/boundary helper |
| `tests/unit/m04c/` | Add | Rate, boundary, residual, failure matrices |
| `tests/integration/m04c/` | Add | Schema-v2 round trips |
| `tools/test/m04c/m04c_core_reaping_trace.gd` | Add | Deterministic demonstration |
| `tools/test/owner/run_m04c_owner_verification.ps1` | Add | Windows evidence |
| Maintained docs | Modify | Realized contract/status/commands |

Do not add content Resources, UI scenes, or a new save-schema fixture unless an actual approved compatibility need is reported first.

## Acceptance criteria

| ID | Pass condition | Evidence | Merge gate? |
|---|---|---|---:|
| `AC-01` | One transactional engine owns M04C production. | Code review/tests | Yes |
| `AC-02` | Engine has no clock/scene/UI/platform/file-time dependency. | Source audit/tests | Yes |
| `AC-03` | Every failure preserves exact whole-state equality. | Failure matrix | Yes |
| `AC-04` | No-active and inactive behavior match the approved timeline contract. | Focused tests | Yes |
| `AC-05` | Multiple active Reapings reject without partial resolution. | Focused test | Yes |
| `AC-06` | Core rate plan uses exact normalized content and supported modifiers. | Rate-plan tests | Yes |
| `AC-07` | 60-second fixture produces 69 returns, 6 Essence, 1,000,000 Mastery, one cycle. | Test/trace | Yes |
| `AC-08` | Equivalent chunk patterns produce exact equal state. | Matrix | Yes |
| `AC-09` | Residual keys/ranges and sole ownership are enforced. | Validator/tests | Yes |
| `AC-10` | Whole returns and Essence bank immediately and exactly. | Tests | Yes |
| `AC-11` | Mastery/cycle arithmetic and carries are exact. | Tests | Yes |
| `AC-12` | 869 ms does not settle; 870 ms settles the one-backlog fixture. | Boundary tests | Yes |
| `AC-13` | Ten-second Settlement fixture matches every listed integer. | Test/trace | Yes |
| `AC-14` | One-shot and 869+1+9130 produce exact equal state. | Test/trace | Yes |
| `AC-15` | Boundary uses Overdue gains before the lifecycle transition. | Segment/event assertions | Yes |
| `AC-16` | Settled returns/Essence continue while Mastery/cycle remain unreduced. | Settled tests | Yes |
| `AC-17` | Settlement event occurs once at the exact cursor and never repeats. | Event tests | Yes |
| `AC-18` | Zero-duration loop guard and transition limit fail safely. | Negative test | Yes |
| `AC-19` | Invalid rate/modifier/Retinue/unknown-flow inputs fail visibly. | Negative matrix | Yes |
| `AC-20` | Every supported overflow fails without mutation. | Boundary matrix | Yes |
| `AC-21` | Schema v2 round-trips Overdue/Settled core state exactly. | Integration tests | Yes |
| `AC-22` | No M04D, M04E, progression, concurrency, application, UI, or Steam behavior enters the diff. | Diff review | Yes |
| `AC-23` | Linux focused/import/trace/full checks pass. | Commands/exits | Yes |
| `AC-24` | Windows owner package passes full/focused/import/11-marker trace/cleanup/audit/full. | Owner log | Yes |
| `AC-25` | Junior-readable comments explain all non-obvious numeric and ownership rules. | Review | Yes |
| `AC-26` | Maintained documents are synchronized. | Docs review | Yes |
| `AC-27` | Actual scope remains within assessment or work stopped for a revised prompt. | Handoff | Yes |

A pending owner result keeps M04C verification Partial and prevents merge.

## Automated verification

### Codex Cloud or Linux

Run:

```bash
git status --short

./tools/test/run_gut.sh -- \
  -gdir=res://tests/unit/m04c \
  -gdir=res://tests/integration/m04c

godot --headless --path . --import

trace_root="$(mktemp -d)"
godot --headless --path . \
  -s res://tools/test/m04c/m04c_core_reaping_trace.gd \
  -- --save-root "$trace_root"
trace_exit=$?
rm -rf "$trace_root"
test ! -e "$trace_root"
test "$trace_exit" -eq 0

./tools/test/run_gut.sh

git diff --check
git status --short
```

At minimum cover:

- exact rate plans and modifier matching;
- 60-second and one-backlog fixtures;
- multiple chunk patterns;
- no-active/inactive/concurrency;
- Retinue and unknown-flow rejection;
- negative/zero elapsed;
- fixed-point multiplier/accumulator/boundary helper failures;
- inventory/counter/Mastery/cycle/time/residual overflow;
- Settlement event contract and repetition;
- Overdue/Settled save round trips;
- whole-state no-mutation comparison for every failure;
- source audit for forbidden clocks/platform/UI;
- missing `--save-root` negative trace;
- no generated log/temp artifact.

## Owner-run Windows automated checks

Codex must add:

```text
tools/test/owner/run_m04c_owner_verification.ps1
```

Expected invocation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
    -File .\tools\test\owner\run_m04c_owner_verification.ps1 `
    -CommitSha "<PR_HEAD_SHA>"
```

The script follows the final M04B pattern:

1. resolve repository and Godot 4.7 console executable;
2. keep Git optional and compare when available;
3. write one UTF-8 PR-head log;
4. run Godot version;
5. run full GUT before;
6. run focused M04C through in-process named `-GutArgs`;
7. run explicit import;
8. run the trace in a unique Windows temp directory;
9. capture trace output before marker verification;
10. verify all 11 exact markers;
11. clean in `finally` and prove absence;
12. tolerate prior ignored logs and audit real artifacts;
13. run full GUT after;
14. print the standardized summary.

Expected summary:

```text
Automated result: PASS
Failed step count: 0
Pending interactive checks: None for M04C
Cleanup result: PASS
```

No interactive checklist is required.

## Trace markers

```text
TRACE M04C overdue_60s_returns=69_essence=6_mastery=1000000_cycles=1
TRACE M04C one_shot_equals_chunks=PASS
TRACE M04C settlement_boundary_msec=870
TRACE M04C settlement_end_returns=3_backlog=0_lifecycle=SETTLED
TRACE M04C settlement_event_once=PASS
TRACE M04C settled_mastery_and_cycle_continue=PASS
TRACE M04C core_residuals_return=625375_essence=315250_mastery_carry=40000
TRACE M04C inactive_produces_nothing=PASS
TRACE M04C idle_timeline_advances=PASS
TRACE M04C save_round_trip=PASS
TRACE M04C no_clock_sources=PASS
```

## Save/load verification

| Scenario | Setup | Expected after reload |
|---|---|---|
| Overdue partial | Nonzero core residuals/cycle phase | Exact residuals, counters, inventory, Mastery, cursor |
| Boundary-crossed | One-backlog ten-second result | Settled, exact remainders, event not persisted/repeated |
| Already Settled | Further resolution | Backlog zero; continued counters/Essence/Mastery/cycle |
| No active | Timeline-only advancement | Exact new cursor; no output changes |
| Invalid residual | Out-of-range known key | Load or resolution rejects before commit |
| Schema audit | Compare constants/keys | Still v2; no migration/content revision change |

## Documentation updates

Update:

- `docs/codex/MILESTONES.md`;
- `docs/codex/ARCHITECTURE.md`;
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`;
- `docs/codex/TESTING_AND_VALIDATION.md`;
- `docs/codex/DECISIONS.md` only if implementation uncovers a genuine conflict requiring a new owner-approved decision; do not weaken accepted `DEC-0036` through implementation shortcuts;
- `README.md` if the developer trace command is useful.

## Stop conditions

Stop and report if:

1. M04B is not actually merged/passed;
2. M04C requires another authoritative state family or schema version;
3. exact Settlement semantics conflict with accepted design;
4. core rates require Retinue, progression, report, or discovery behavior;
5. multiple active Reapings must be supported now;
6. Emergency Writ transition must be implemented to make the tested scope correct;
7. a cached rate plan or effective rate must be persisted;
8. another primary owner or more than two seams are needed;
9. source/test files exceed approximately 30 or code/test lines exceed approximately 1,500;
10. a dependency or broad framework is required;
11. any required verification fails.

## Final response format

Use exactly:

### Implementation completed

Summarize only core rate derivation, transactional resolution, residuals, cycles, Settlement, result/events, and owner package.

### Files changed

List every file and actual source/test file count plus code/test line delta versus estimate.

### Verification

Separate Linux/Codex evidence from `Pending owner verification`. Include exact fixture values, markers, commands, and exits.

### Assumptions

State only narrow assumptions that do not alter accepted semantics.

### Known limitations and risks

State the temporary single-active limit, unsupported Retinues/deferred boundaries, and pending owner evidence.

### Deferred work

Name M04D channels/rate changes, M04E forecasts/reports, progression/Writ transitions, concurrency, UI, and platform time.

### Suggested next task

Normally: owner runs the M04C Windows package. Do not draft M04D.
