# Implementation slice M04D3: Compatible rate-context changes and acquisition queries

**Prompt version:** v0.1  
**Prompt date:** 2026-07-18  
**Prompt status:** Draft  
**Work item type:** Implementation slice  
**Parent conceptual epic:** `M04 — Persistent Reaping simulation vertical slice` / M04D sub-epic  
**Milestone definition:** `docs/codex/MILESTONES.md` — `### M04D3 — Compatible rate-context changes and acquisition queries`  
**Recommended task size:** Small-medium; one rate-context/reconfiguration/query pull request  
**Scope-gate result:** Within guardrails at draft; stop if actual work needs another primary owner, more than two cross-layer seams, more than approximately 30 non-documentation source/test files, or more than approximately 1,500 non-documentation code/test lines  
**Expected base branch or ref:** current `main` after M04D2 merge commit `24228a078199d9728eb57e4e26c27447aa6911a3`  
**Planned prompt path:** `docs/codex/milestone-prompts/M04D3-compatible-rate-context-and-acquisition-queries.md`

> This prompt authorizes one bounded rate-context owner, compatible inactive changed redispatch, prospective active-Form output-channel modifiers, non-compounding derivation, pure progress/current-context ETA queries, persistence proof, and verification. It does not authorize active in-place reconfiguration, cross-denominator carry conversion, authoritative Recollection/Art/Retinue/support/global modifier state, forecasts, reports, UI, concurrency, schema/content revisions, or platform integration.

## Approval dependency

Do not execute this prompt until the project owner:

1. reviews and accepts proposed `DEC-0039` or approves a revised replacement contract;
2. approves M04D3 prompt v0.1;
3. confirms M04D2 is recorded Merged/Passed at merge commit `24228a078199d9728eb57e4e26c27447aa6911a3`.

Until then:

```text
M04D3 prompt: Draft
M04D3 implementation: Not started
GATE-RATE-CONTEXT-CHANGE: Pending
```

Do not draft or implement M04E in this task.

## Execution protocol

Before editing:

1. Read `AGENTS.md` completely.
2. Read every source listed under **Authoritative context**.
3. Inspect current `main`, merged M04D2 implementation/tests/docs, and `git status --short`.
4. Verify PR #14 merged from final head `96f4db53b2513a8ab6182c074113efe72d5fd968` at merge commit `24228a078199d9728eb57e4e26c27447aa6911a3`.
5. Verify schema version 3 and content revision `prototype-content-r2` remain current.
6. Inspect `ReapingAssignmentService`, `SimulationEngine`, `OutputAccessService`, `FixedPoint`, `GameStateValidator`, Form/channel normalized records, schema-v3 mapper, current traces, and final M04D2 owner runner.
7. State the proposed rate-context service API, signature fields, compatibility/error contract, modifier order, query fields, ETA algorithm, expected files, exact fixtures, and verification plan before non-trivial edits.
8. Reassess scope. Stop before implementation if authoritative Recollection/Art/Retinue/support/global modifier state, active in-place loadout changes, denominator conversion, forecast clones, reports, UI, concurrency, schema version 4, content revision 3, another primary owner, or another broad subsystem becomes necessary.

During implementation:

- Add one bounded `ReapingRateContextService`; do not create separate compatibility, modifier, and query frameworks.
- Keep elapsed simulation in `SimulationEngine` and assignment mutation in `ReapingAssignmentService`.
- Require the caller to resolve old elapsed time before recall/redispatch.
- Use strict complete current-v3 validation for ordinary assignment/simulation commands; only M04D1 access reconciliation may use transitional validation.
- Compare every approved denominator before a changed redispatch.
- Preserve all compatible residuals and operation/source identity exactly.
- Reject incompatible contexts without reset, conversion, or partial mutation.
- Derive every output-channel rate from immutable normalized baseline content.
- Execute only active Form Trait output-channel modifiers in this slice.
- Use the same rate-plan builder in simulation and query paths.
- Calculate ETA with checked bounded arithmetic and persisted carry; do not replay milliseconds.
- Label ETA as `CURRENT_RATE_CONTEXT`, not a future-boundary forecast.
- Keep schema v3/content r2 and production content unchanged.
- Add junior-readable comments explaining denominator meaning, residual ownership, command ordering, modifier order, non-compounding, query purity, and M04E boundaries.
- Add exact no-mutation tests for every failure.
- Create the real-file trace and final-pattern Windows owner package.
- Report exact commands, counts, markers, exits, and actual-versus-estimated scope.
- Leave Windows owner verification pending until the owner supplies the generated log.
- Do not draft or implement M04E.

Do not describe M04D3 as complete while any merge-gate criterion is failed, blocked, or pending.

## Objective

Permit compatible changed Form/Writ redispatch without losing or reinterpreting core/channel residuals, use one baseline-derived active-Form output-channel rate plan for both simulation and pure queries, prevent repeated rate compounding, and expose exact normalized progress plus current-context ETA without adding save authority.

## Player or developer outcome

From focused tests and one headless trace, a developer can:

- resolve production under Man-at-Arms, recall, and redispatch Scribe on the same Threshold while preserving every compatible residual;
- see incompatible return/Mastery/cycle denominator fixtures reject without mutation;
- prove the old setup is resolved before the new rate applies;
- inspect a copied `×1.20` output-channel Form modifier;
- keep a progress bar at exactly `50.0%` while ETA changes from two hours to one hour forty minutes;
- repeat the modified loadout without producing `×1.44`;
- return to the prior loadout and recover its baseline-derived rate;
- execute a `1 -> 3 -> 2 -> 1` loadout/Threshold sequence without moving source progress between operations;
- compare equivalent chunking around the rate-change boundary;
- save/load the resulting authoritative state while proving rate plans and ETAs are absent;
- run one Windows PowerShell command and share a complete UTF-8 log.

## Authoritative context

| Priority | Source | Required sections or records | Why it applies |
|---:|---|---|---|
| 1 | `AGENTS.md` | Full file | Repository rules and final response |
| 2 | `docs/codex/MILESTONES.md` | Gates, M04D2 completion, M04D3, scope guardrails | Slice authority |
| 3 | `docs/codex/DECISIONS.md` | `DEC-0010`, `DEC-0012`, `DEC-0014`, `DEC-0026`–`DEC-0028`, `DEC-0033`, `DEC-0035`–`DEC-0039` | Numeric/reconfiguration/query authority |
| 4 | `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | Reaping, acquisition, modifier, result, proposed M04D3 contracts | Exact data rules |
| 5 | `docs/codex/ARCHITECTURE.md` | M04B–M04D2 realized boundaries and proposed M04D3 boundary | Ownership and seams |
| 6 | `docs/codex/IMPLEMENTATION_RULES.md` | Determinism, arithmetic, state, comments, diagnostics | Engineering rules |
| 7 | `docs/codex/TESTING_AND_VALIDATION.md` | §§23–26; owner workflow | Evidence |
| 8 | `docs/codex/OWNER_VERIFICATION_WORKFLOW.md` | Complete | Windows runner/log |
| 9 | `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md` | Long-horizon progress, reconfiguration, insight | Product intent |
| 10 | `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md` | Threshold sources, Settlement, access, prototype Forms | Prototype behavior |
| 11 | Current implementation | Assignment service, simulation engine, access service, fixed point, schema v3, content registry, M04D2 tests/trace | Actual baseline |

Report unresolved conflicts before implementing.

## Repository state

Expected baseline:

| Item | Expected state |
|---|---|
| Completed slices | M04A, M04B, M04C, M04D1, M04D2 Merged/Passed |
| Save | Schema v3; frozen v1/v2 support; `JSON_V1` |
| Content | `prototype-content-r2`; r1/r2/m02 compatibility |
| Access | Global prospective item access and complete available-source reconciliation |
| Simulation | Transactional zero/one-active core + initialized non-Essence channel resolver |
| Assignment | Recall and inactive redispatch; changed nonzero context still conservatively rejected |
| Channel authority | Threshold-owned progress/carry/history; whole inventory banking |
| Current modifiers | Core Form Trait modifiers work; output-channel Form modifiers not yet executed |
| Query | No authoritative acquisition rate/ETA query |
| UI/application | No gameplay shell, report, forecast, or player-facing progress UI |
| Working tree | Clean except task changes |

## Dependencies and gates

| Dependency/gate | Required state | Verification |
|---|---|---|
| M04D2 | Merged and Passed | Merge/evidence record |
| `DEC-0039` | Accepted or replaced by owner-approved contract | Decision record |
| `GATE-RATE-CONTEXT-CHANGE` | Satisfied at prompt approval | Milestone map |
| `GATE-SLICE-SCOPE` | Remains within limits | Prompt/handoff |
| M04B | Assignment identity/revisions preserved | Regression tests |
| M04C | Core residual ownership and exact segmentation unchanged | Regression tests |
| M04D1 | Access/source completeness unchanged | Validation tests |
| M04D2 | Channel ownership/banking/event/persistence unchanged | Regression tests |
| Schema/content | v3/r2 unchanged | Persistence/content tests |
| Windows environment | Godot 4.7 console executable | Owner package |

## Scope and review-surface assessment

| Assessment item | Draft estimate |
|---|---|
| Parent conceptual epic | M04 / M04D |
| Primary subsystem owner | New bounded `ReapingRateContextService` |
| Principal transition | Recalled Threshold operation + requested loadout → compatible redispatch or typed rejection; shared prospective channel-rate/query derivation |
| New authoritative aggregate family | None |
| Save-schema change | None; schema v3 remains current |
| Content compatibility change | None; `prototype-content-r2` remains current |
| Deterministic algorithms | Signature comparison, ordered fixed-point modifier plan, carry-aware minimal ETA |
| Cross-layer seams | 2: assignment → rate context; simulation → rate context |
| Risk dimensions | Residual compatibility, non-compounding modifier math, query/ETA correctness |
| Expected non-documentation source/test files | Approximately 10–20 |
| Expected non-documentation code/test delta | Approximately 800–1,300 lines |
| Bulk authored content | None; copied test fixtures only |
| Platform/native work | None |
| Interactive owner checks | None |
| Automated owner checks | One generated PowerShell log |
| Mandatory split trigger | Not crossed at draft |

Stop for a revised prompt before adding another primary owner, another authoritative state family, more than two cross-layer seams, more than approximately 30 non-documentation source/test files, or more than approximately 1,500 non-documentation code/test lines.

## Required behavior

| ID | Requirement | Authority |
|---|---|---|
| `RB-01` | Add one scene-independent `ReapingRateContextService`; do not create parallel compatibility/modifier/query owners. | Proposed `DEC-0039` |
| `RB-02` | The rate-context service reads no clock, frame, scene, file, platform, report, forecast, or UI state and mutates no `GameState`. | Architecture |
| `RB-03` | Elapsed production remains solely in `SimulationEngine`; assignment mutation remains solely in `ReapingAssignmentService`. | `DEC-0036` |
| `RB-04` | Caller order is resolve old elapsed, recall, compatibility check, compatible redispatch, then future resolution. | `DEC-0028` |
| `RB-05` | No active in-place loadout mutation is added. | Slice boundary |
| `RB-06` | Ordinary assignment/simulation entry and commit use complete current-v3 validation; only access reconciliation retains transitional validation. | M04D1/M04D2 |
| `RB-07` | Every failure preserves complete canonical state. | Transaction contract |
| `RB-08` | Signature contains returned period, Mastery period, cycle duration, Essence period, and initialized non-Essence channel periods. | Proposed `DEC-0039` |
| `RB-09` | Signature maps and mismatch fields are canonical and sorted. | Determinism |
| `RB-10` | Form/Writ IDs are diagnostic identity, not automatic denominator mismatch. | Compatibility semantics |
| `RB-11` | Exact signature equality permits inactive changed redispatch. | Proposed `DEC-0039` |
| `RB-12` | Any denominator mismatch returns `REAPING_RATE_CONTEXT_INCOMPATIBLE`. | Proposed `DEC-0039` |
| `RB-13` | M04D3 performs no denominator conversion, residual reset, proportional scaling, or progress rebasing. | `DEC-0027`, `DEC-0028` |
| `RB-14` | Compatible redispatch preserves every core flow progress/carry entry. | Residual ownership |
| `RB-15` | Compatible redispatch preserves cycle phase and completed-cycle count. | Residual ownership |
| `RB-16` | Compatible redispatch preserves every Threshold acquisition progress/carry/history record. | `DEC-0027` |
| `RB-17` | Compatible redispatch preserves inventory, reservations, Threshold facts, first-start time, and operation identity. | M04B/M04D2 |
| `RB-18` | Existing assignment revision/event semantics remain authoritative. | `DEC-0035` |
| `RB-19` | Every output-channel rate plan begins from normalized authored baseline content. | `DEC-0028` |
| `RB-20` | M04D3 executes active Form Trait metric `OUTPUT_CHANNEL_RATE` only. | Slice contract |
| `RB-21` | Relevant operation is `MULTIPLY`; relevant scope is `OUTPUT_CHANNEL`. | Modifier grammar |
| `RB-22` | Supported conditions are `ALWAYS`, `OUTPUT_ITEM`, `OUTPUT_KIND`, `THRESHOLD_HAS_ANY_TAG`, and `THRESHOLD_LIFECYCLE`. | Proposed `DEC-0039` |
| `RB-23` | Form Trait evaluation order is authored Trait order then modifier order. | Determinism |
| `RB-24` | Each modifier floors once through checked fixed-point multiplication. | `DEC-0026` |
| `RB-25` | Channel lifecycle multiplier applies after Form modifiers and exactly once. | M04D2 boundary |
| `RB-26` | Irrelevant Form modifiers are ignored. | Bounded semantics |
| `RB-27` | Relevant malformed or unsupported operation/scope/condition data fails visibly. | Diagnostics |
| `RB-28` | Writ/Retinue/Art/Recollection/support/global modifier execution is deferred; no fake state is introduced. | Slice boundary |
| `RB-29` | Repeated redispatch derives from baseline and cannot compound. | `DEC-0028` |
| `RB-30` | Returning to a prior loadout derives that loadout's current baseline-based rate, not a historical snapshot. | `DEC-0028` |
| `RB-31` | Simulation and queries consume the same output-channel rate-plan builder. | Architecture |
| `RB-32` | Acquisition query is pure and non-persisted. | Query contract |
| `RB-33` | Query exposes access/disclosure/activity/lifecycle, stored progress, tenths percentage, rate plan, applied modifiers, and current-context ETA availability. | Data contract |
| `RB-34` | Percentage is floored to integer tenths and remains at most `999` while progress is stored. | `DEC-0027` |
| `RB-35` | Active eligible ETA is the minimum integer milliseconds to the next whole unit using current progress, rate, period, and carry. | Numeric contract |
| `RB-36` | ETA uses bounded checked arithmetic and no per-millisecond loop. | `DEC-0026` |
| `RB-37` | Locked, unavailable, invalid, Essence, or inactive source has no active ETA. | Access/query boundary |
| `RB-38` | ETA basis is explicitly `CURRENT_RATE_CONTEXT`; M04D3 does not forecast future transitions. | M04E boundary |
| `RB-39` | The `500000 / 7200000 / 6000000 / ×1.20` fixture is exact. | `DEC-0028` |
| `RB-40` | The full `1 -> 3 -> 2 -> 1` sequence preserves separate Threshold operation and acquisition identity. | Owner scenario |
| `RB-41` | Equivalent chunking around the rate-change boundary yields canonical equality. | Determinism |
| `RB-42` | Schema v3/content r2 remain current; signatures/rates/traces/percentages/ETAs never serialize. | Persistence |
| `RB-43` | Add junior-readable comments for compatibility, residuals, modifier order, non-compounding, ETA basis, and deferred sources. | Project rule |
| `RB-44` | Add focused tests, real-file trace, final-pattern Windows runner, synchronized docs, and actual scope evidence. | Merge gate |

## Required state transitions

| ID | Transition | Required result |
|---|---|---|
| `ST-01` | Active old loadout + explicit elapsed | `SimulationEngine` commits old-context production to exact cursor |
| `ST-02` | Active operation + recall | Existing assignment service freezes operation and increments revision |
| `ST-03` | Inactive operation + same loadout | Redispatch succeeds with unchanged rate context |
| `ST-04` | Inactive operation + compatible changed Form/Writ | Redispatch succeeds and preserves all residuals |
| `ST-05` | Inactive operation + incompatible returned period | Typed rejection; no mutation |
| `ST-06` | Inactive operation + incompatible Mastery period | Typed rejection; no mutation |
| `ST-07` | Inactive operation + incompatible cycle duration | Typed rejection; no mutation |
| `ST-08` | Active eligible channel + baseline Form | Baseline-derived rate plan and ETA |
| `ST-09` | Active eligible channel + matching copied Form modifier | Baseline × ordered multiplier; unchanged stored progress |
| `ST-10` | Modified loadout repeated | Same effective rate; no compounding |
| `ST-11` | Return to prior loadout | Prior baseline-derived rate restored |
| `ST-12` | Inactive initialized source query | Stored progress exposed; no active ETA |
| `ST-13` | Locked/unavailable/Essence query | No active rate/ETA and no authority mutation |
| `ST-14` | Equivalent chunks around change boundary | Canonical equal authoritative state |
| `ST-15` | Compatible changed state save/load | Exact authoritative schema-v3 reconstruction |
| `ST-16` | Query/rate-plan artifacts inspected in snapshot | None are persisted |

## Implementation requirements

### 1. ReapingRateContextService

Create one bounded service, expected under:

```text
src/simulation/reaping_rate_context_service.gd
```

The final path may differ if repository conventions require it, but there must be one primary owner.

It must provide typed or equivalently bounded results for:

```text
build_signature(...)
compare_compatibility(...)
build_output_channel_rate_plan(...)
query_acquisition(...)
```

Do not return ambiguous free-form success dictionaries for public service APIs.

### 2. Signature construction

Build signatures only from ready normalized content and current authoritative state.

Validate:

- requested Threshold/Reaping/Form/Writ records;
- exact enabled Essence channel ownership;
- initialized eligible non-Essence channel ownership;
- positive periods and cycle duration;
- canonical channel ordering.

Comparison must identify every mismatch rather than stopping at the first, unless a prior structural/content error prevents meaningful comparison.

### 3. Assignment-service integration

Refine changed inactive `redispatch()`:

```text
loadout unchanged
    -> existing path
loadout changed
    -> compare old/requested signatures
    -> incompatible: REAPING_RATE_CONTEXT_INCOMPATIBLE
    -> compatible: preserve residuals and commit existing assignment mutation
```

Remove the obsolete blanket `REAPING_RESOLUTION_REQUIRED` rejection for compatible changed contexts. Retain it only if another still-valid command path requires it; document that path.

Do not let the assignment service call `SimulationEngine` internally or read elapsed time.

### 4. Shared output-channel rate plan

Replace M04D2's baseline-only channel-rate helper with the shared service plan.

Order:

```text
baseline
Form Trait modifiers in authored order
channel lifecycle multiplier when Settled
```

The plan's effective rate is the only rate passed to M04D2 accumulation.

Production Forms currently have no output-channel modifier. Use copied catalog fixtures to add exact modifiers without changing production `.tres` files or content revision.

### 5. Modifier grammar

Support only:

```text
metric = OUTPUT_CHANNEL_RATE
operation = MULTIPLY
scope = OUTPUT_CHANNEL
condition = ALWAYS | OUTPUT_ITEM | OUTPUT_KIND | THRESHOLD_HAS_ANY_TAG | THRESHOLD_LIFECYCLE
```

Condition operands:

- `ALWAYS`: none;
- `OUTPUT_ITEM`: canonical item IDs;
- `OUTPUT_KIND`: canonical channel kinds;
- `THRESHOLD_HAS_ANY_TAG`: canonical Threshold tags;
- `THRESHOLD_LIFECYCLE`: `OVERDUE` or `SETTLED`.

Use any-match semantics for multiple values. Reject empty/malformed required operands.

### 6. Exact ETA helper

Add or reuse one central checked helper for the smallest elapsed milliseconds needed to reach a target subunit boundary.

The helper must:

- accept positive rate and period;
- include current progress and carry;
- prove minimality;
- detect overflow;
- terminate in bounded logarithmic work;
- avoid per-millisecond and per-item replay.

Do not broaden into a general forecast engine.

### 7. Acquisition query

The query must return a bounded result matching the approved contract. It must not:

- mutate state;
- initialize access/source records;
- advance simulation;
- inspect wall time;
- persist query data;
- forecast future lifecycle changes.

Use the existing access/source facts and same rate-plan builder.

### 8. Identity sequence

Test the owner scenario as distinct operations/loadouts:

```text
1. Gloamwood, loadout A
3. Gloamwood, compatible loadout B
2. Broken Watch, loadout A on its separate operation
1. return to Gloamwood, loadout A
```

Prove:

- each Threshold keeps its own immutable first-start and acquisition state;
- assignment revisions are monotonic within each operation;
- Form exclusivity is respected;
- no channel progress transfers;
- final A rate is baseline-derived, not compounded from B.

### 9. Persistence

No schema or content revision change.

Use production mapper/coordinator/storage tests for:

- compatible changed loadout with nonzero core/channel residuals;
- assignment revision and loadout after redispatch;
- save/load then return to prior loadout;
- no query/rate/signature/trace fields in snapshot;
- current v3 no migration.

## Required test matrix

At minimum cover all 28 groups in `TESTING_AND_VALIDATION.md` §26.

Use copied fixtures for:

- Form returned period mismatch;
- Form Mastery period mismatch;
- Form cycle mismatch;
- `×1.20` `ALWAYS` modifier;
- each supported condition;
- multiple modifiers and floor order;
- relevant unsupported operation/scope/condition;
- carry-aware ETA;
- overflow.

For every failure, compare complete canonical schema-v3 state before and after and assert no assignment revision, event, segment, inventory, residual, progress, or timeline mutation.

## Trace contract

Create:

```text
tools/test/m04d3/m04d3_rate_context_trace.gd
```

It must:

1. require explicit nonblank `--save-root`;
2. reject `user://`;
3. use only the supplied root for real persistence;
4. leave root deletion to the owner runner;
5. check every result before reading it;
6. earn each marker only after its complete assertions pass;
7. exit nonzero on any mismatch;
8. perform a real schema-v3 save/load;
9. audit source ownership;
10. emit exactly:

```text
TRACE M04D3 compatible_swap_preserves_core_and_channel_residuals=PASS
TRACE M04D3 incompatible_return_period_rejected=PASS
TRACE M04D3 incompatible_mastery_period_rejected=PASS
TRACE M04D3 incompatible_cycle_duration_rejected=PASS
TRACE M04D3 output_modifier_rate_before=1000000_after=1200000
TRACE M04D3 progress=500000_eta_before=7200000_eta_after=6000000
TRACE M04D3 old_context_then_new_context_banks_one=PASS
TRACE M04D3 repeated_redispatch_non_compounding=PASS
TRACE M04D3 return_to_prior_loadout_restores_baseline=PASS
TRACE M04D3 sequence_1_3_2_1_identity=PASS
TRACE M04D3 inactive_query_has_progress_no_eta=PASS
TRACE M04D3 rate_change_chunk_equivalence=PASS
TRACE M04D3 schema_v3_round_trip_no_rate_eta=PASS
TRACE M04D3 no_clock_or_later_slice_sources=PASS
```

## Owner-run Windows automated checks

Codex must add:

```text
tools/test/owner/run_m04d3_owner_verification.ps1
```

Expected invocation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
    -File .\tools\test\owner\run_m04d3_owner_verification.ps1 `
    -CommitSha "<PR_HEAD_SHA>"
```

Adapt the final M04D2 runner rather than creating a shortcut. Preserve:

1. explicit `-GodotBin`, then `GODOT_BIN`, then PATH discovery;
2. Git-optional SHA evidence;
3. one complete UTF-8 PR-head log;
4. Godot 4.7 version validation;
5. full suite before;
6. focused M04D3 through an in-process `-GutArgs` array;
7. explicit import;
8. isolated real-file trace;
9. stable copied trace output and all 14 exact markers;
10. `finally` cleanup and absence proof;
11. prior ignored-log tolerance and artifact audit;
12. full suite after;
13. standardized summary and nonzero failure exit.

Expected summary:

```text
Automated result: PASS
Failed step count: 0
Pending interactive checks: None for M04D3
Cleanup result: PASS
Log path: <generated path>
```

No interactive checklist is required.

## Acceptance criteria

| ID | Criterion | Evidence | Merge gate |
|---|---|---|---|
| `AC-01` | M04D2 is Merged/Passed and `DEC-0039` is Accepted. | Docs/merge | Yes |
| `AC-02` | One bounded rate-context owner serves assignment, simulation, and query paths. | Review/tests | Yes |
| `AC-03` | Service and commands have no prohibited clock/scene/file/platform ownership. | Source audit | Yes |
| `AC-04` | Old elapsed is resolved before assignment change in every integrated fixture. | Sequence tests/trace | Yes |
| `AC-05` | Compatible Man-at-Arms/Scribe changed redispatch succeeds. | Focused tests | Yes |
| `AC-06` | Compatible core residuals and cycle state remain exact. | Canonical comparison | Yes |
| `AC-07` | Compatible Threshold channel residuals/history remain exact. | Canonical comparison | Yes |
| `AC-08` | First-start and operation identity remain exact; revision semantics remain monotonic. | Assignment tests | Yes |
| `AC-09` | Returned-period mismatch rejects without mutation. | Copied fixture | Yes |
| `AC-10` | Mastery-period mismatch rejects without mutation. | Copied fixture | Yes |
| `AC-11` | Cycle-duration mismatch rejects without mutation. | Copied fixture | Yes |
| `AC-12` | Signature/mismatch ordering is canonical. | Unit tests | Yes |
| `AC-13` | Output-channel rate plans derive from baseline and share one implementation. | Simulation/query comparison | Yes |
| `AC-14` | Supported modifier condition matrix and deterministic floor order pass. | Copied fixtures | Yes |
| `AC-15` | Relevant malformed/unsupported modifiers reject; irrelevant modifiers are ignored. | Negative matrix | Yes |
| `AC-16` | Lifecycle multiplier applies last and once. | Copied Settled fixture | Yes |
| `AC-17` | Repeated redispatch does not compound. | Sequence tests/trace | Yes |
| `AC-18` | Returning to prior loadout restores its baseline-derived rate. | Sequence tests/trace | Yes |
| `AC-19` | Progress remains `500000` while ETA changes `7200000 -> 6000000`. | Exact query fixture | Yes |
| `AC-20` | ETA includes carry, is minimal, checked, and bounded. | Fixed-point/query tests | Yes |
| `AC-21` | Progress percentage is floored to tenths and never prematurely reaches 100.0%. | Query tests | Yes |
| `AC-22` | Locked/inactive/unavailable/Essence query behavior is exact. | Query matrix | Yes |
| `AC-23` | `1 -> 3 -> 2 -> 1` preserves operation/source isolation and Form exclusivity. | Integrated matrix | Yes |
| `AC-24` | Equivalent chunking around the boundary is canonical equal. | Matrix/trace | Yes |
| `AC-25` | Schema v3/content r2 round-trip exact authority and exclude derived artifacts. | Integration tests | Yes |
| `AC-26` | Linux focused/import/trace/full checks pass. | Commands/exits | Yes |
| `AC-27` | Windows package passes full/focused/import/14-marker/cleanup/audit/full. | Owner log | Yes |
| `AC-28` | Junior-readable comments/docs and actual scope evidence are complete. | Review/handoff | Yes |

A pending owner result keeps M04D3 verification Partial and prevents merge.

## Automated verification

### Codex Cloud or Linux

Run:

```bash
git status --short

./tools/test/run_gut.sh -- \
  -gdir=res://tests/unit/m04d3 \
  -gdir=res://tests/integration/m04d3

godot --headless --path . --import

trace_root="$(mktemp -d)"
godot --headless --path . \
  -s res://tools/test/m04d3/m04d3_rate_context_trace.gd \
  -- --save-root "$trace_root"
trace_exit=$?
rm -rf "$trace_root"
test ! -e "$trace_root"
test "$trace_exit" -eq 0

# Missing root must fail.
godot --headless --path . \
  -s res://tools/test/m04d3/m04d3_rate_context_trace.gd
test "$?" -ne 0

./tools/test/run_gut.sh

git diff --check
git status --short
```

Report exact focused/full counts, all fourteen markers, negative-root result, commands, exit codes, and actual scope.

Leave actual Windows owner verification pending.

## Save/load verification

| Scenario | Setup | Expected after reload |
|---|---|---|
| Compatible changed loadout | Nonzero core/channel residuals, recalled then redispatched | Exact residuals, new Form/Writ IDs, incremented revision |
| Return to prior loadout | A → B → A | A baseline-derived rate after reload; no compounded rate |
| Two Threshold operations | `1 -> 3 -> 2 -> 1` | Separate first-start/revision/acquisition state |
| Inactive source | Stored progress/carry | Exact progress; no persisted ETA |
| Current v3 | Save/load current state | No migration or rewrite |
| Artifact audit | Inspect snapshot | No signature, compatibility result, rate plan, modifier trace, percentage, or ETA |

## Documentation updates

Update canonical sections in:

- `docs/codex/MILESTONES.md`;
- `docs/codex/ARCHITECTURE.md`;
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`;
- `docs/codex/TESTING_AND_VALIDATION.md`;
- `docs/codex/DECISIONS.md` only if implementation uncovers a genuine conflict requiring a new owner-approved decision; do not weaken accepted `DEC-0039`;
- `README.md` only if the developer trace/query command is useful.

Do not add duplicate M04D3 sections.

## Stop conditions

Stop and report if:

1. M04D2 is not actually merged/passed;
2. `DEC-0039` or a replacement contract is not approved;
3. compatible behavior requires resetting or converting residuals;
4. output modifiers require authoritative Recollection/Art/Retinue/support/global state now;
5. a boundary-aware forecast is required now;
6. schema version 4, content revision 3, or production content changes become necessary;
7. another primary owner or more than two cross-layer seams is needed;
8. source/test files exceed approximately 30 or code/test lines exceed approximately 1,500;
9. per-millisecond replay or a new dependency/framework is required;
10. any exact fixture, no-mutation check, trace, persistence check, or regression fails.

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
Under **Suggested next task**, state only that the owner should run the M04D3 Windows package. Do not draft M04E.
