# Implementation slice M04D3: Compatible rate-context changes and acquisition queries

**Prompt version:** v0.2  
**Prompt date:** 2026-07-18  
**Prompt status:** Approved  
**Work item type:** Implementation slice  
**Parent conceptual epic:** `M04 — Persistent Reaping simulation vertical slice` / M04D sub-epic  
**Milestone definition:** `docs/codex/MILESTONES.md` — `### M04D3 — Compatible rate-context changes and acquisition queries`  
**Recommended task size:** Small-medium; one rate-context/reconfiguration/query pull request  
**Scope-gate result:** Approved within guardrails; stop if actual work needs another primary owner, more than two cross-layer seams, more than approximately 30 non-documentation source/test files, or more than approximately 1,500 non-documentation code/test lines  
**Expected base branch or ref:** current `main` after M04D2 merge commit `24228a078199d9728eb57e4e26c27447aa6911a3`  
**Planned prompt path:** `docs/codex/milestone-prompts/M04D3-compatible-rate-context-and-acquisition-queries.md`

> This prompt authorizes one bounded rate-context owner, assembly-time loadout validation, component-based loadout identity, supported inactive changed redispatch, prospective active-Form output-channel modifiers, non-compounding derivation, exact progress/current-context ETA queries, readable ETA display values, persistence proof, and verification. It does not authorize active in-place reconfiguration, cross-denominator carry conversion, full Retinue/Art/Recollection/support/global modifier state, forecasts, reports, gameplay UI, concurrency, schema/content revisions, or platform integration.

## Approval record

The project owner accepted `DEC-0039` and approved M04D3 prompt v0.2 on 2026-07-18 with these refinements:

- a faster or slower loadout is valid; rate differences are not denominator incompatibility;
- every loadout presented as valid must remain swappable after old-context resolution;
- loadout validity is available while assembling the loadout and is revalidated immediately before commit;
- different component tuples remain distinct even when their rates, ETAs, modifier totals, or complete outputs are identical;
- backend ETA remains integer milliseconds;
- player-facing ETA uses exactly the approved three-component day/hour/minute or hour/minute/second template and never aggregate milliseconds.

M04D2 is Merged/Passed at merge commit `24228a078199d9728eb57e4e26c27447aa6911a3` from final head `96f4db53b2513a8ab6182c074113efe72d5fd968`.

Do not draft or implement M04E in this task.

## Execution protocol

Before editing:

1. Read `AGENTS.md` completely.
2. Read every source under **Authoritative context**.
3. Inspect current `main`, merged M04D2 implementation/tests/docs, and `git status --short`.
4. Verify PR #14 and the M04D2 evidence record.
5. Verify schema version 3 and content revision `prototype-content-r2` remain current.
6. Inspect `ReapingAssignmentService`, `SimulationEngine`, `OutputAccessService`, `FixedPoint`, `GameStateValidator`, normalized Form/channel records, schema-v3 mapper, current traces, and final M04D2 owner runner.
7. State the proposed service API, loadout-validation API, component identity, residual signature, normalization-required error contract, modifier order, query/display fields, ETA algorithm, expected files, exact fixtures, and verification plan before non-trivial edits.
8. Reassess scope. Stop before implementation if full Retinue slot assembly, authoritative Art/Recollection/support/global state, active in-place mutation, denominator conversion, forecast clones, reports, gameplay UI, concurrency, schema version 4, content revision 3, another primary owner, or another broad subsystem becomes necessary.

During implementation:

- Add one bounded `ReapingRateContextService`; do not create separate compatibility, modifier, and query frameworks.
- Add one pure loadout-candidate validator in the assignment domain and reuse it at command commit.
- Keep elapsed simulation in `SimulationEngine` and assignment mutation in `ReapingAssignmentService`.
- Require the caller to resolve old elapsed time before recall/redispatch.
- Use strict complete current-v3 validation for ordinary assignment/simulation commands; only M04D1 access reconciliation may use transitional validation.
- Preserve component identity independently from derived performance.
- Do not merge, deduplicate, or alias different loadouts because output is equal.
- Treat numerator/multiplier changes as supported performance changes.
- Treat copied denominator/cycle changes as content requiring future normalization, not as ordinary player-rate differences.
- Preserve all supported residuals and operation/source identity exactly.
- Reject normalization-required content without reset, conversion, or partial mutation.
- Derive every output-channel rate from immutable normalized baseline content.
- Execute only active Form Trait output-channel modifiers in this slice.
- Use the same rate-plan builder in simulation and query paths.
- Calculate exact ETA with checked bounded arithmetic and persisted carry; do not replay milliseconds.
- Return localization-ready ETA display components and English fallback text using the approved format.
- Label ETA as `CURRENT_RATE_CONTEXT`, not a future-boundary forecast.
- Keep schema v3/content r2 and production content unchanged.
- Add junior-readable comments explaining validity, identity, denominator meaning, residual ownership, command ordering, modifier order, non-compounding, ETA math/presentation, and M04E boundaries.
- Add exact no-mutation tests for every failure.
- Create the real-file trace and final-pattern Windows owner package.
- Report exact commands, counts, markers, exits, and actual-versus-estimated scope.
- Leave Windows owner verification pending until the owner supplies the generated log.
- Do not draft or implement M04E.

Do not describe M04D3 as complete while any merge-gate criterion is failed, blocked, or pending.

## Objective

Permit every currently valid supported changed Form/Writ loadout to redispatch without losing or reinterpreting core/channel residuals, preserve distinct loadout identity even when outputs converge, use one baseline-derived active-Form output-channel rate plan for simulation and pure queries, prevent repeated rate compounding, and expose exact plus readable current-context ETA without adding save authority.

## Player or developer outcome

From focused tests and one headless trace, a developer can:

- validate a candidate during assembly and prove dispatch/redispatch reuse the same rules;
- resolve production under Man-at-Arms, recall, and redispatch Scribe while preserving every supported residual;
- prove a `x1.20` numerator change is supported rather than rejected;
- see copied return/Mastery/cycle denominator changes require normalization without mutation;
- inspect two different loadouts that produce identical output and remain separately identified;
- prove old setup resolution completes before the new rate applies;
- keep progress at exactly `50.0%` while exact ETA changes from `7,200,000` to `6,000,000` ms;
- render `03 hours, 52 minutes, 15 seconds` and `02 days, 03 hours, 04 minutes` for player-facing ETA;
- repeat the modified loadout without producing `x1.44`;
- return to the prior loadout and recover its baseline-derived rate;
- execute a `1 -> 3 -> 2 -> 1` loadout/Threshold sequence without moving source progress between operations;
- compare equivalent chunking around the rate-change boundary;
- save/load authoritative state while proving validation/rate/ETA/display artifacts are absent;
- run one Windows PowerShell command and share a complete UTF-8 log.

## Authoritative context

| Priority | Source | Required sections or records | Why it applies |
|---:|---|---|---|
| 1 | `AGENTS.md` | Full file | Repository rules and final response |
| 2 | `docs/codex/MILESTONES.md` | Gates, M04D2 completion, M04D3, scope guardrails | Slice authority |
| 3 | `docs/codex/DECISIONS.md` | `DEC-0010`, `DEC-0012`, `DEC-0014`, `DEC-0026`–`DEC-0028`, `DEC-0033`, `DEC-0035`–`DEC-0039` | Numeric/reconfiguration/query authority |
| 4 | `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | Reaping, acquisition, modifier, loadout, rate-plan, query/display contracts | Exact data rules |
| 5 | `docs/codex/ARCHITECTURE.md` | M04B–M04D2 realized boundaries and approved M04D3 boundary | Ownership and seams |
| 6 | `docs/codex/IMPLEMENTATION_RULES.md` | Determinism, arithmetic, state, comments, diagnostics | Engineering rules |
| 7 | `docs/codex/TESTING_AND_VALIDATION.md` | §§23–26; owner workflow | Evidence |
| 8 | `docs/codex/OWNER_VERIFICATION_WORKFLOW.md` | Complete | Windows runner/log |
| 9 | `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md` | Loadout, long-horizon progress, reconfiguration, ETA | Product intent |
| 10 | `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md` | Threshold sources, Settlement, access, prototype Forms | Prototype behavior |
| 11 | Current implementation | Assignment service, simulation engine, access service, fixed point, schema v3, content registry, M04D2 tests/trace | Actual baseline |

Report unresolved conflicts before implementing.

## Repository state

| Item | Expected state |
|---|---|
| Completed slices | M04A, M04B, M04C, M04D1, M04D2 Merged/Passed |
| Save | Schema v3; frozen v1/v2 support; `JSON_V1` |
| Content | `prototype-content-r2`; r1/r2/m02 compatibility |
| Access | Global prospective item access and complete available-source reconciliation |
| Simulation | Transactional zero/one-active core plus initialized non-Essence channel resolver |
| Assignment | Recall and inactive redispatch; changed nonzero context still conservatively rejected |
| Channel authority | Threshold-owned progress/carry/history; whole inventory banking |
| Current modifiers | Core Form Trait modifiers work; output-channel Form modifiers not yet executed |
| Query | No authoritative acquisition rate/ETA/display query |
| UI/application | No gameplay shell, report, forecast, loadout-builder UI, or player-facing progress UI |
| Working tree | Clean except task changes |

## Dependencies and gates

| Dependency/gate | Required state | Verification |
|---|---|---|
| M04D2 | Merged and Passed | Merge/evidence record |
| `DEC-0039` | Accepted | Decision record |
| `GATE-RATE-CONTEXT-CHANGE` | Satisfied | Milestone map |
| `GATE-SLICE-SCOPE` | Satisfied and remains within limits | Prompt/handoff |
| M04B | Assignment identity/revisions preserved | Regression tests |
| M04C | Core residual ownership and exact segmentation unchanged | Regression tests |
| M04D1 | Access/source completeness unchanged | Validation tests |
| M04D2 | Channel ownership/banking/event/persistence unchanged | Regression tests |
| Schema/content | v3/r2 unchanged | Persistence/content tests |
| Windows environment | Godot 4.7 console executable | Owner package |

## Scope and review-surface assessment

| Assessment item | Approved estimate |
|---|---|
| Parent conceptual epic | M04 / M04D |
| Primary subsystem owner | New bounded `ReapingRateContextService` |
| Principal transition | Valid recalled operation + requested loadout → supported residual-preserving redispatch or normalization-required guard; shared rate/query derivation |
| New authoritative aggregate family | None |
| Save-schema change | None; schema v3 remains current |
| Content compatibility change | None; `prototype-content-r2` remains current |
| Deterministic algorithms | Candidate validation, component identity, signature comparison, ordered fixed-point modifier plan, carry-aware minimal ETA, display decomposition |
| Cross-layer seams | 2: assignment → rate context; simulation/query → rate context |
| Risk dimensions | Loadout correctness/identity, non-compounding rate math, exact ETA/presentation |
| Expected non-documentation source/test files | Approximately 10–22 |
| Expected non-documentation code/test delta | Approximately 900–1,400 lines |
| Bulk authored content | None; copied test fixtures only |
| Platform/native work | None |
| Interactive owner checks | None |
| Automated owner checks | One generated PowerShell log |
| Mandatory split trigger | Not crossed at approval |

Stop for a revised prompt before adding another primary owner, another authoritative state family, more than two cross-layer seams, more than approximately 30 non-documentation source/test files, or more than approximately 1,500 non-documentation code/test lines.

## Required behavior

| ID | Requirement | Authority |
|---|---|---|
| `RB-01` | Add one scene-independent `ReapingRateContextService`; do not create parallel compatibility/modifier/query owners. | `DEC-0039` |
| `RB-02` | The service reads no clock, frame, scene, file, platform, report, forecast, or UI state and mutates no `GameState`. | Architecture |
| `RB-03` | Elapsed production remains solely in `SimulationEngine`; assignment mutation remains solely in `ReapingAssignmentService`. | `DEC-0036` |
| `RB-04` | Loadout validity, loadout identity, and derived performance are separate contracts. | `DEC-0039` |
| `RB-05` | Expose one pure loadout-candidate validation path for assembly-time use. | `DEC-0039` |
| `RB-06` | Dispatch and redispatch revalidate the same candidate rules immediately before commit. | Transaction safety |
| `RB-07` | Current M04D3 candidate validation covers authoritative Form/Writ rules and retains an extension seam for later Retinue/Art/support constraints. | Slice boundary |
| `RB-08` | Caller order is validate, resolve old elapsed, recall, revalidate, compare residual context, redispatch, then future resolution. | `DEC-0028`, `DEC-0039` |
| `RB-09` | No active in-place loadout mutation is added. | Slice boundary |
| `RB-10` | Ordinary assignment/simulation entry and commit use complete current-v3 validation; only access reconciliation retains transitional validation. | M04D1/M04D2 |
| `RB-11` | Every failure preserves complete canonical state. | Transaction contract |
| `RB-12` | `LoadoutIdentity` is the canonical component tuple: Form, Writ, ordered Retinues, and later selected component IDs. | `DEC-0039` |
| `RB-13` | Derived rate, ETA, modifier totals, and output vectors are never loadout identity. | `DEC-0039` |
| `RB-14` | Different component tuples remain distinct even when every derived output is equal. | Owner clarification |
| `RB-15` | Caches may share calculations but results, comparison rows, events, histories, and later presets retain the requesting loadout identity. | Architecture |
| `RB-16` | Signature contains returned period, Mastery period, cycle duration, Essence period, and initialized non-Essence channel periods. | `DEC-0039` |
| `RB-17` | Signature maps and normalization-required fields are canonical and sorted. | Determinism |
| `RB-18` | Form/Writ IDs are identity, not automatic residual-context mismatch. | Compatibility semantics |
| `RB-19` | Numerator/multiplier performance differences are supported when residual denominators remain stable. | Owner clarification |
| `RB-20` | Every loadout exposed as valid in this implementation must use supported stable denominators. | Full-game guardrail |
| `RB-21` | Unsupported denominator/cycle changes return `REAPING_RATE_CONTEXT_NORMALIZATION_REQUIRED`. | `DEC-0039` |
| `RB-22` | M04D3 performs no denominator conversion, residual reset, proportional scaling, or progress rebasing. | `DEC-0027`, `DEC-0028` |
| `RB-23` | Supported redispatch preserves every core flow progress/carry entry. | Residual ownership |
| `RB-24` | Supported redispatch preserves cycle phase and completed-cycle count. | Residual ownership |
| `RB-25` | Supported redispatch preserves every Threshold acquisition progress/carry/history record. | `DEC-0027` |
| `RB-26` | Supported redispatch preserves inventory, reservations, Threshold facts, first-start time, and operation identity. | M04B/M04D2 |
| `RB-27` | Existing assignment revision/event semantics remain authoritative. | `DEC-0035` |
| `RB-28` | Every output-channel rate plan begins from normalized authored baseline content. | `DEC-0028` |
| `RB-29` | M04D3 executes active Form Trait metric `OUTPUT_CHANNEL_RATE` only. | Slice contract |
| `RB-30` | Relevant operation is `MULTIPLY`; relevant scope is `OUTPUT_CHANNEL`. | Modifier grammar |
| `RB-31` | Supported conditions are `ALWAYS`, `OUTPUT_ITEM`, `OUTPUT_KIND`, `THRESHOLD_HAS_ANY_TAG`, and `THRESHOLD_LIFECYCLE`. | `DEC-0039` |
| `RB-32` | Form Trait evaluation order is authored Trait order then modifier order. | Determinism |
| `RB-33` | Each modifier floors once through checked fixed-point multiplication. | `DEC-0026` |
| `RB-34` | Channel lifecycle multiplier applies after Form modifiers and exactly once. | M04D2 boundary |
| `RB-35` | Irrelevant Form modifiers are ignored. | Bounded semantics |
| `RB-36` | Relevant malformed or unsupported operation/scope/condition data fails visibly. | Diagnostics |
| `RB-37` | Writ/Retinue/Art/Recollection/support/global modifier execution is deferred; no fake state is introduced. | Slice boundary |
| `RB-38` | Repeated redispatch derives from baseline and cannot compound. | `DEC-0028` |
| `RB-39` | Returning to a prior loadout derives its current baseline rate, not a historical snapshot. | `DEC-0028` |
| `RB-40` | Simulation and queries consume the same output-channel rate-plan builder. | Architecture |
| `RB-41` | Acquisition query is pure and non-persisted. | Query contract |
| `RB-42` | Query exposes loadout identity, access/disclosure/activity/lifecycle, stored progress, tenths percentage, rate plan, modifier trace, exact ETA, ETA basis, and display value. | Data contract |
| `RB-43` | Percentage is floored to integer tenths and remains at most `999` while progress is stored. | `DEC-0027` |
| `RB-44` | Active eligible ETA is the minimum integer milliseconds to the next whole unit using current progress, rate, period, and carry. | Numeric contract |
| `RB-45` | ETA uses bounded checked arithmetic and no per-millisecond loop. | `DEC-0026` |
| `RB-46` | Locked, unavailable, invalid, Essence, or inactive source has no active ETA. | Access/query boundary |
| `RB-47` | ETA basis is explicitly `CURRENT_RATE_CONTEXT`; M04D3 does not forecast future transitions. | M04E boundary |
| `RB-48` | Player-facing ETA uses only DAY/HOUR/MINUTE/SECOND and exactly the approved three-component templates. | Owner clarification |
| `RB-49` | ETA display values use minimum two-digit width, correct English singular/plural, structured localization components, and at least one displayed second for positive sub-second ETA. | Presentation contract |
| `RB-50` | Player-facing ETA never exposes aggregate milliseconds; traces/logs may continue using exact ms unless validating display. | Owner clarification |
| `RB-51` | The `500000 / 7200000 / 6000000 / x1.20` fixture and both readable ETA fixtures are exact. | `DEC-0028`, owner clarification |
| `RB-52` | The full `1 -> 3 -> 2 -> 1` sequence preserves separate Threshold operation, assignment, loadout, and acquisition identity. | Owner scenario |
| `RB-53` | Equivalent chunking around the rate-change boundary yields canonical equality. | Determinism |
| `RB-54` | Schema v3/content r2 remain current; validation/identity/signature/rate/trace/percentage/ETA/display artifacts never serialize. | Persistence |
| `RB-55` | Add junior-readable comments for validity, identity, residual context, modifier order, non-compounding, ETA math/presentation, and deferred sources. | Project rule |
| `RB-56` | Add focused tests, sixteen-marker real-file trace, final-pattern Windows runner, synchronized docs, and actual scope evidence. | Merge gate |

## Required state transitions

| ID | Transition | Required result |
|---|---|---|
| `ST-01` | Candidate components selected during assembly | Pure validity result and canonical loadout identity; no mutation |
| `ST-02` | Candidate becomes stale before dispatch | Commit-time revalidation rejects; no mutation |
| `ST-03` | Active old loadout + explicit elapsed | `SimulationEngine` commits old-context production to exact cursor |
| `ST-04` | Active operation + recall | Existing assignment service freezes operation and increments revision |
| `ST-05` | Inactive operation + same loadout | Redispatch succeeds with unchanged rate context |
| `ST-06` | Inactive operation + valid faster/slower numerator-only loadout | Redispatch succeeds and preserves residuals |
| `ST-07` | Inactive operation + supported changed Form/Writ | Redispatch succeeds and preserves all residuals |
| `ST-08` | Copied loadout changes returned-soul period | Normalization-required rejection; no mutation |
| `ST-09` | Copied loadout changes Mastery period | Normalization-required rejection; no mutation |
| `ST-10` | Copied loadout changes cycle duration | Normalization-required rejection; no mutation |
| `ST-11` | Two different loadouts derive equal output | Both identities and results remain distinct |
| `ST-12` | Active eligible channel + baseline Form | Baseline-derived rate plan and exact ETA |
| `ST-13` | Active eligible channel + matching copied Form modifier | Baseline times ordered modifier; unchanged stored progress |
| `ST-14` | Modified loadout repeated | Same effective rate; no compounding |
| `ST-15` | Return to prior loadout | Prior baseline-derived rate restored |
| `ST-16` | Inactive initialized source query | Stored progress exposed; no active ETA |
| `ST-17` | ETA below one day | Hours/minutes/seconds display with three components |
| `ST-18` | ETA at least one day | Days/hours/minutes display with three components |
| `ST-19` | `1 -> 3 -> 2 -> 1` sequence | Separate operation/loadout/source identity preserved |
| `ST-20` | Equivalent chunks around change boundary | Canonical equal authoritative state |
| `ST-21` | Supported changed state save/load | Exact authoritative schema-v3 reconstruction; no derived artifacts |

## Implementation requirements

### 1. ReapingRateContextService

Create one bounded service, expected under:

```text
src/simulation/reaping_rate_context_service.gd
```

It must provide typed or equivalently bounded APIs for:

```text
build_loadout_identity(...)
build_signature(...)
compare_continuity(...)
build_output_channel_rate_plan(...)
query_acquisition(...)
format_eta_display(...)
```

A small pure formatter helper is acceptable, but it does not become a second subsystem owner.

### 2. Loadout validation and identity

Add a public pure validation seam to `ReapingAssignmentService`, expected shape:

```text
validate_loadout_candidate(state, threshold_id, form_id, writ_id, retinue_ids)
```

Current M04D3 validates authoritative Form/Writ rules and requires the still-unsupported Retinue list to remain empty. Later milestones extend the same seam.

Dispatch and redispatch must call the same validator immediately before candidate mutation.

Create a typed `LoadoutIdentity` from canonical components. Do not derive identity from rate or output. Add tests proving two copied different loadouts with equal numeric plans/results remain distinct and separately addressable.

### 3. Residual-context construction

Build signatures only from ready normalized content and current authoritative state.

Validate:

- requested Threshold/Reaping/Form/Writ records;
- exact enabled Essence channel ownership;
- initialized eligible non-Essence channel ownership;
- positive periods and cycle duration;
- canonical channel ordering.

Comparison identifies every normalization-required field unless a prior structural/content error prevents meaningful comparison.

### 4. Assignment integration

Refine changed inactive `redispatch()`:

```text
loadout unchanged
    -> existing path
loadout changed
    -> validate candidate
    -> compare old/requested residual signatures
    -> normalization required: REAPING_RATE_CONTEXT_NORMALIZATION_REQUIRED
    -> supported: preserve residuals and commit existing assignment mutation
```

Remove the obsolete blanket `REAPING_RESOLUTION_REQUIRED` rejection for supported changed contexts. Retain it only if another valid command path still requires it and document that path.

Do not let assignment call `SimulationEngine` internally or read elapsed time.

### 5. Shared output-channel rate plan

Replace M04D2's baseline-only channel-rate helper with the shared plan.

Order:

```text
baseline
Form Trait modifiers in authored order
channel lifecycle multiplier when Settled
```

The plan's effective rate is the only rate passed to M04D2 accumulation.

Production Forms currently have no output-channel modifier. Use copied catalog fixtures without changing production `.tres` files or content revision.

### 6. Modifier grammar

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

### 7. Exact ETA helper

Add or reuse one central checked helper for the smallest elapsed milliseconds needed to reach a target subunit boundary.

It must:

- accept positive rate and period;
- include current progress and carry;
- prove minimality;
- detect overflow;
- terminate in bounded logarithmic work;
- avoid per-millisecond and per-item replay.

Do not broaden into a forecast engine.

### 8. ETA display value

Return structured localization-ready components and English fallback text.

```text
eta < 86,400,000 ms:
    HOUR, MINUTE, SECOND
eta >= 86,400,000 ms:
    DAY, HOUR, MINUTE
```

Rules:

- exactly three components;
- only DAY/HOUR/MINUTE/SECOND;
- minimum two-digit width;
- correct singular/plural;
- days may exceed 99;
- positive sub-second ETA displays as one second;
- no weeks/months/years;
- no player-facing milliseconds.

Backend query retains exact `current_context_eta_msec`.

### 9. Acquisition query

The query returns a bounded result matching the approved contract. It must not:

- mutate state;
- initialize access/source records;
- advance simulation;
- inspect wall time;
- persist query data;
- forecast future lifecycle changes.

Use existing access/source facts and the shared rate-plan builder.

### 10. Identity sequence

Test the owner scenario:

```text
1. Gloamwood, loadout A
3. Gloamwood, supported loadout B
2. Broken Watch, loadout A on its separate operation
1. return to Gloamwood, loadout A
```

Prove:

- each Threshold keeps its own immutable first-start and acquisition state;
- assignment revisions are monotonic within each operation;
- Form exclusivity is respected;
- no channel progress transfers;
- final A rate is baseline-derived, not compounded from B;
- equal numeric output anywhere in the sequence does not merge loadout identity.

### 11. Persistence

No schema or content revision change.

Use production mapper/coordinator/storage tests for:

- supported changed loadout with nonzero core/channel residuals;
- assignment revision and selected components after redispatch;
- save/load then return to prior loadout;
- separate two-Threshold identities;
- no validation, derived identity key, signature, rate, trace, percentage, exact ETA, or display value in snapshot;
- current v3 no migration.

## Required test matrix

At minimum cover all 39 groups in `TESTING_AND_VALIDATION.md` §26.

Use copied fixtures for:

- Form returned-period change;
- Form Mastery-period change;
- Form cycle change;
- `x1.20` `ALWAYS` modifier;
- each supported condition;
- multiple modifiers and floor order;
- relevant unsupported operation/scope/condition;
- equal-output/different-loadout identity;
- carry-aware ETA;
- ETA display formats and edge cases;
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
6. earn each marker only after complete assertions pass;
7. exit nonzero on any mismatch;
8. perform a real schema-v3 save/load;
9. audit source ownership;
10. emit exactly:

```text
TRACE M04D3 supported_swap_preserves_core_and_channel_residuals=PASS
TRACE M04D3 return_period_change_requires_normalization=PASS
TRACE M04D3 mastery_period_change_requires_normalization=PASS
TRACE M04D3 cycle_duration_change_requires_normalization=PASS
TRACE M04D3 output_modifier_rate_before=1000000_after=1200000
TRACE M04D3 equal_output_loadouts_remain_distinct=PASS
TRACE M04D3 progress=500000_eta_before=7200000_eta_after=6000000
TRACE M04D3 eta_display_short=03_hours_52_minutes_15_seconds_long=02_days_03_hours_04_minutes
TRACE M04D3 old_context_then_new_context_banks_one=PASS
TRACE M04D3 repeated_redispatch_non_compounding=PASS
TRACE M04D3 return_to_prior_loadout_restores_baseline=PASS
TRACE M04D3 sequence_1_3_2_1_identity=PASS
TRACE M04D3 inactive_query_has_progress_no_eta=PASS
TRACE M04D3 rate_change_chunk_equivalence=PASS
TRACE M04D3 schema_v3_round_trip_no_derived_rate_eta=PASS
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

Adapt the final M04D2 runner. Preserve:

1. explicit `-GodotBin`, then `GODOT_BIN`, then PATH discovery;
2. Git-optional SHA evidence;
3. one complete UTF-8 PR-head log;
4. Godot 4.7 version validation;
5. full suite before;
6. focused M04D3 through an in-process `-GutArgs` array;
7. explicit import;
8. isolated real-file trace;
9. stable copied trace output and all 16 exact markers;
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
| `AC-01` | M04D2 is Merged/Passed and accepted `DEC-0039` remains authoritative. | Docs/merge | Yes |
| `AC-02` | One bounded rate-context owner serves assignment, simulation, and query paths. | Review/tests | Yes |
| `AC-03` | Service and commands have no prohibited clock/scene/file/platform ownership. | Source audit | Yes |
| `AC-04` | Pure assembly-time candidate validation returns canonical component identity without mutation. | Unit tests | Yes |
| `AC-05` | Dispatch/redispatch revalidate the same rules and stale candidates reject without mutation. | Command tests | Yes |
| `AC-06` | Valid faster/slower numerator-only loadouts remain swappable. | Copied fixtures | Yes |
| `AC-07` | Different equal-output loadouts remain distinct and separately addressable. | Identity matrix/trace | Yes |
| `AC-08` | Old elapsed is resolved before assignment change in every integrated fixture. | Sequence tests/trace | Yes |
| `AC-09` | Current Man-at-Arms/Scribe changed redispatch succeeds. | Focused tests | Yes |
| `AC-10` | Supported core residuals and cycle state remain exact. | Canonical comparison | Yes |
| `AC-11` | Supported Threshold channel residuals/history remain exact. | Canonical comparison | Yes |
| `AC-12` | First-start and operation identity remain exact; revision semantics remain monotonic. | Assignment tests | Yes |
| `AC-13` | Returned-period change returns normalization-required without mutation. | Copied fixture | Yes |
| `AC-14` | Mastery-period change returns normalization-required without mutation. | Copied fixture | Yes |
| `AC-15` | Cycle-duration change returns normalization-required without mutation. | Copied fixture | Yes |
| `AC-16` | Signature/diagnostic ordering is canonical. | Unit tests | Yes |
| `AC-17` | Output-channel rate plans derive from baseline and share one implementation. | Simulation/query comparison | Yes |
| `AC-18` | Supported modifier condition matrix and deterministic floor order pass. | Copied fixtures | Yes |
| `AC-19` | Relevant malformed/unsupported modifiers reject; irrelevant modifiers are ignored. | Negative matrix | Yes |
| `AC-20` | Lifecycle multiplier applies last and once. | Copied Settled fixture | Yes |
| `AC-21` | Repeated redispatch does not compound. | Sequence tests/trace | Yes |
| `AC-22` | Returning to prior loadout restores its baseline-derived rate. | Sequence tests/trace | Yes |
| `AC-23` | Progress remains `500000` while ETA changes `7200000 -> 6000000`. | Exact query fixture | Yes |
| `AC-24` | ETA includes carry, is minimal, checked, and bounded. | Fixed-point/query tests | Yes |
| `AC-25` | Progress percentage is floored to tenths and never prematurely reaches 100.0%. | Query tests | Yes |
| `AC-26` | Locked/inactive/unavailable/Essence query behavior is exact. | Query matrix | Yes |
| `AC-27` | Short ETA uses hours/minutes/seconds and long ETA uses days/hours/minutes, each with exactly three components. | Formatter tests/trace | Yes |
| `AC-28` | ETA display is localization-ready, handles width/plurals/subseconds/large days, and never exposes aggregate milliseconds. | Formatter tests | Yes |
| `AC-29` | `1 -> 3 -> 2 -> 1` preserves operation/source/loadout isolation and Form exclusivity. | Integrated matrix | Yes |
| `AC-30` | Equivalent chunking around the boundary is canonical equal. | Matrix/trace | Yes |
| `AC-31` | Schema v3/content r2 round-trip authority and exclude all derived validation/rate/ETA/display artifacts. | Integration tests | Yes |
| `AC-32` | Linux focused/import/trace/full checks pass. | Commands/exits | Yes |
| `AC-33` | Windows package passes full/focused/import/16-marker/cleanup/audit/full. | Owner log | Yes |
| `AC-34` | Junior-readable comments/docs and actual scope evidence are complete. | Review/handoff | Yes |

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

Report exact focused/full counts, all sixteen markers, negative-root result, commands, exit codes, and actual scope.

Leave actual Windows owner verification pending.

## Save/load verification

| Scenario | Setup | Expected after reload |
|---|---|---|
| Supported changed loadout | Nonzero core/channel residuals, recalled then redispatched | Exact residuals, new Form/Writ IDs, incremented revision |
| Equal-output loadouts | Different components with equal derived plan | Component identities remain distinct before/after query; no output-based alias |
| Return to prior loadout | A -> B -> A | A baseline-derived rate after reload; no compounded rate |
| Two Threshold operations | `1 -> 3 -> 2 -> 1` | Separate first-start/revision/acquisition state |
| Inactive source | Stored progress/carry | Exact progress; no persisted ETA |
| Current v3 | Save/load current state | No migration or rewrite |
| Artifact audit | Inspect snapshot | No validation result, derived identity key, signature, continuity result, rate plan, modifier trace, percentage, exact ETA, or ETA display |

## Documentation updates

Update canonical sections in:

- `docs/codex/MILESTONES.md`;
- `docs/codex/ARCHITECTURE.md`;
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`;
- `docs/codex/TESTING_AND_VALIDATION.md`;
- `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md` only if implementation reveals a genuine contradiction; do not weaken the approved rule;
- `docs/codex/DECISIONS.md` only if implementation reveals a genuine conflict requiring a new owner decision; do not weaken accepted `DEC-0039`;
- `README.md` only if the developer trace/query command is useful.

Do not add duplicate M04D3 sections.

## Stop conditions

Stop and report if:

1. M04D2 is not actually merged/passed;
2. accepted `DEC-0039` cannot be implemented without semantic changes;
3. ordinary faster/slower performance would be rejected solely because rate differs;
4. different equal-output loadouts would need to be merged or deduplicated;
5. supported behavior requires resetting or converting residuals;
6. output modifiers require authoritative Retinue/Art/Recollection/support/global state now;
7. a boundary-aware forecast or gameplay UI is required now;
8. schema version 4, content revision 3, or production content changes become necessary;
9. another primary owner or more than two cross-layer seams is needed;
10. source/test files exceed approximately 30 or code/test lines exceed approximately 1,500;
11. per-millisecond replay or a new dependency/framework is required;
12. any exact fixture, no-mutation check, trace, persistence check, or regression fails.

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
