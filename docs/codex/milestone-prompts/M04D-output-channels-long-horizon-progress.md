# Implementation slice M04D: Output channels and long-horizon acquisition progress

**Prompt version:** v0.1  
**Prompt date:** 2026-07-17  
**Prompt status:** Draft  
**Work item type:** Implementation slice  
**Parent conceptual epic:** `M04 — Persistent Reaping simulation vertical slice`  
**Milestone definition:** `docs/codex/MILESTONES.md` — `### M04D — Output channels and long-horizon acquisition progress`  
**Recommended task size:** Medium; one Threshold-channel accumulation pull request  
**Scope-gate result:** Within guardrails at draft; mandatory stop if actual work needs another primary owner, more than two cross-layer seams, more than approximately 30 non-documentation source/test files, or more than approximately 1,500 non-documentation code/test lines  
**Expected base branch or ref:** current `main` after M04C merge commit `719592c85ca4e90ecd5df4593e37a81d36b2789e`  
**Planned prompt path:** `docs/codex/milestone-prompts/M04D-output-channels-long-horizon-progress.md`

> This prompt authorizes only non-Essence Threshold output-channel accumulation, exact long-horizon progress/carry, bounded channel-rate modifiers, compatible residual-preserving redispatch, derived time-to-next-unit, persistence proof, and verification evidence. It does not authorize discovery, Retinue/support, Recollection purchasing, progression effects, reports, forecasts, concurrent Reapings, UI, or platform time.

## Approval dependency

This draft includes proposed `DEC-0037`. Approval of this prompt also accepts that decision unless the owner requests revised channel, modifier, reconfiguration, event, or ETA semantics first.

Do not execute this prompt while `DEC-0037` remains Proposed.

## Execution protocol

Before editing:

1. Read `AGENTS.md` completely.
2. Read every source listed under **Authoritative context**.
3. Inspect current `main`, merged M04C source/tests/docs, and `git status --short`.
4. Verify PR #12 merged at `719592c85ca4e90ecd5df4593e37a81d36b2789e` from final head `acb48d0045e41a0f7d73f561e5c3756f8668dd46`.
5. Verify M04C is recorded Merged/Passed and schema version 2 remains current.
6. Inspect `SimulationEngine`, `CoreFlowKeys`, `GameState.ThresholdAcquisitionState`, `GameStateValidator`, `ReapingAssignmentService`, schema mapper/validator, all six channel records, and current M04C tests/trace/owner runner.
7. State the proposed channel resolver/rate-plan shape, eligible-channel rules, modifier-source order, assignment compatibility check, delta/event records, ETA algorithm, expected files, and verification plan before non-trivial edits.
8. Re-evaluate the scope assessment. Stop if the work requires discovery progression, Retinue/Recollection/Art state, multiple active Reapings, reports/forecasts, a schema bump, production-content changes, another primary owner, or material review-surface growth.

During implementation:

- Extend the existing transactional engine; do not create another simulation loop.
- Resolve all M04D work on the existing candidate and commit once.
- Keep Essence exclusively in M04C core state.
- Use normalized registry records and checked fixed-point helpers only.
- Iterate channels and equal-time events in canonical sorted order.
- Keep channel progress in `ThresholdState.channel_acquisition`, never `ReapingState`.
- Re-derive effective rates from baseline plus current modifiers for every segment.
- Resolve old elapsed state before assignment/modifier changes.
- Preserve compatible residuals; reject incompatible denominators without resetting them.
- Add junior-readable comments explaining ownership, exclusion of Essence, stable periods, modifier order, whole extraction, reconfiguration compatibility, and non-compounding behavior.
- Add the complete focused/integration matrix, trace, owner script, and synchronized documentation.
- Report exact commands, counts, markers, exits, and actual-versus-estimated scope.
- Leave owner Windows verification pending until the owner supplies a log for the tested PR head.
- Do not draft M04E.

## Objective

Extend `SimulationEngine` so one active Reaping resolves every eligible non-Essence Threshold item channel into whole inventory plus exact Threshold-owned normalized progress/carry, while preserving progress across recall, compatible loadout-rate changes, Settlement, chunking, and save/load without compounding modifiers or duplicating core Essence.

## Player or developer outcome

A developer can:

- run Gloamwood for two hours and see 24 Soldier Souls plus 25% Scribe Form Soul progress;
- run it for eight hours and bank one Scribe Form Soul;
- run Broken Watch for six hours and see 720 Provisions plus 25% Man-at-Arms Form Soul progress;
- run it for twenty-four hours and bank one Man-at-Arms Form Soul;
- prove hidden channels bank normally;
- recall and redispatch without losing progress;
- change to a compatible 20%-faster context while progress remains 50% and ETA changes prospectively;
- repeat redispatch without compounding;
- cross Settlement and save/load exact channel state;
- execute the complete Windows proof through one PowerShell command.

## Authoritative context

| Priority | Source | Required sections/records | Why it applies |
|---:|---|---|---|
| 1 | `AGENTS.md` | Full file | Repository contract and comment rules |
| 2 | `docs/codex/MILESTONES.md` | §§3–7; `GATE-SLICE-SCOPE`; `GATE-CHANNEL-ACQUISITION`; M04D | Slice and gates |
| 3 | `docs/codex/MILESTONE_RECALIBRATION_PROPOSAL.md` | Scope guardrails | Review surface |
| 4 | `docs/codex/PROMPT_TEMPLATE.md` | Scope assessment/final response | Prompt governance |
| 5 | `docs/codex/OWNER_VERIFICATION_WORKFLOW.md` | Complete | Windows package |
| 6 | `docs/codex/DECISIONS.md` | `DEC-0010`, `DEC-0012`, `DEC-0014`, `DEC-0019`, `DEC-0020`, `DEC-0026`–`DEC-0028`, `DEC-0030`, `DEC-0033`–`DEC-0036`, proposed `DEC-0037` | Numeric/channel/assignment rules |
| 7 | `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | Channel definitions; Threshold/acquisition/Reaping state; numeric rules; proposed M04D contract | Exact data/state contract |
| 8 | `docs/codex/ARCHITECTURE.md` | Simulation segmentation, output channels, M04B/M04C realized boundaries, proposed M04D boundary | Ownership and ordering |
| 9 | `docs/codex/IMPLEMENTATION_RULES.md` | Determinism, state, modifiers, comments, tests | Engineering conventions |
| 10 | `docs/codex/TESTING_AND_VALIDATION.md` | §§19–24 | Exact evidence |
| 11 | `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md` | Persistent assignments, parallel channels, offline-safe progress | Product direction |
| 12 | `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md` | Gloamwood/Broken Watch outputs and safeguards | Prototype behavior |
| 13 | Current implementation/content | M04C engine, assignment service, state/persistence, channel `.tres` files | Actual baseline |

Report unresolved conflicts before implementation.

## Repository state

Expected baseline:

| Item | Expected state |
|---|---|
| Completed slices | M04A–M04C Merged/Passed |
| Engine | Transactional explicit-duration zero/one-active `SimulationEngine` |
| Core flows | Returns/backlog, Essence, Mastery, cycle, exact Settlement |
| Acquisition state | `ThresholdAcquisitionState(progress_subunits, rate_carry_units, total_banked_units)` already schema-v2 persisted |
| Assignment | Stable Threshold operation and revision-guarded recall/redispatch; changed loadout currently guarded by unresolved state |
| Channels | Six first-class records; four eligible non-Essence channels |
| Discovery | No runtime discovery implementation; must not gate output |
| Reports/forecast | Not implemented |
| Working tree | Clean except task changes |

## Dependencies and gates

| Gate | Required state | Required before | Evidence |
|---|---|---|---|
| M04C | Merged/Passed | Implementation | PR #12 record |
| `GATE-CHANNEL-ACQUISITION` | `DEC-0037` Accepted or revised owner-approved contract | Implementation | Decision record |
| `GATE-SLICE-SCOPE` | Assessment within limits | PR/merge | Prompt/handoff |
| Schema v2 | No M04D bump | Merge | Mapper/schema review |
| M03 catalog | Six channel records unchanged | Resolution | Catalog tests |
| Owner Windows | Godot 4.7 console available | Merge | Generated log |

## Scope and review-surface assessment

| Assessment item | Estimate/result |
|---|---|
| Parent epic | M04 |
| Primary subsystem owner | Non-Essence output-channel extension of `SimulationEngine` |
| Principal transition | Active segment → whole item banking plus normalized Threshold/channel remainder |
| New aggregate family | None |
| Schema/migration | None |
| Deterministic work | Channel rate plan, accumulation, whole extraction, ETA search, compatibility check |
| UI flow | None |
| Platform work | None |
| Bulk content | None |
| Transaction/exactly-once | Candidate commit plus per-channel bank event |
| Cross-layer seams | Two: engine ↔ content/state; assignment compatibility ↔ existing assignment service |
| Estimated source/test files | Approximately 12–22, excluding `.uid` |
| Estimated code/test delta | Approximately 900–1,400 lines, excluding docs/`.uid` |
| Owner package | `tools/test/owner/run_m04d_owner_verification.ps1` |
| Mandatory split trigger | Not crossed at draft |

Stop before approximately 30 source/test files, 1,500 code/test lines, more than two seams, or another primary owner.

## Scope

Implement only:

1. eligible non-Essence channel selection;
2. Threshold-owned acquisition-record creation and validation;
3. bounded channel rate-plan derivation;
4. channel Settled multiplier;
5. checked accumulation/extraction/inventory/source-counter mutation;
6. deterministic channel deltas and bank events;
7. inactive freeze and resume;
8. compatible residual-preserving changed redispatch;
9. explicit incompatible-context rejection;
10. pure checked time-to-next-unit query;
11. schema-v2 round trips and malformed-state rejection;
12. focused tests, trace, Windows owner package, and docs.

## Non-goals

Do not implement:

- Essence as an acquisition record;
- discovery state/progress/disclosure;
- Retinue/support/Rations;
- Recollection purchase or global progression state;
- Form Arts;
- milestones, guarantees, resonances, Writ transition;
- forecasts, reports, offline trusted-time, application shell;
- UI/progress bars;
- multiple active Reapings;
- randomness;
- Halls;
- schema version 3 or content changes;
- arbitrary denominator conversion;
- dependencies or broad frameworks.

## Required behavior

| ID | Required behavior | Source |
|---|---|---|
| `RB-01` | Existing `SimulationEngine` remains the only elapsed resolver. | `DEC-0010`, `DEC-0036` |
| `RB-02` | Channel work resolves on the same deep-cloned candidate and one commit. | `DEC-0012` |
| `RB-03` | No clock, frame, scene, UI, Steam, file-time, report, or forecast source is read. | Time architecture |
| `RB-04` | Only enabled, owned, referenced, non-Essence channels are eligible. | `DEC-0030`, `DEC-0037` |
| `RB-05` | Channel IDs are sorted before resolution and event emission. | Determinism |
| `RB-06` | Missing acquisition state means zero and is created on positive active resolution. | M04A state contract |
| `RB-07` | Discovery state does not gate accumulation. | `DEC-0027` |
| `RB-08` | Essence remains exclusively in M04C core flow/inventory. | `DEC-0036`, `DEC-0037` |
| `RB-09` | Rate plan starts from immutable channel baseline and stable period. | `DEC-0028` |
| `RB-10` | M04D supports `OUTPUT_CHANNEL_RATE/MULTIPLY/OUTPUT_CHANNEL`. | Modifier grammar |
| `RB-11` | Supported conditions are evaluated exactly as `DEC-0037` defines. | `DEC-0037` |
| `RB-12` | Active Form Trait modifiers are the production source group in this slice. | Scope boundary |
| `RB-13` | Relevant unsupported modifiers fail; irrelevant metrics are ignored. | `DEC-0014` |
| `RB-14` | Modifiers apply in deterministic authored/source order with checked floor multiplication. | `DEC-0026` |
| `RB-15` | Channel Settled multiplier applies exactly once after ordinary modifiers. | Channel contract |
| `RB-16` | Effective rate and ETA are not persisted or reused as baseline. | `DEC-0028` |
| `RB-17` | Accumulation uses channel period and persisted carry. | `DEC-0026` |
| `RB-18` | Progress is checked, normalized, and extracts all whole units. | Numeric contract |
| `RB-19` | Whole units add immediately to inventory and channel banked total. | `DEC-0027` |
| `RB-20` | Parallel channels never subtract from one another. | Architecture §12 |
| `RB-21` | Progress/carry never appears in Reaping core-flow state. | Sole-owner rule |
| `RB-22` | Segment/result records include sorted exact channel deltas. | M04E seam |
| `RB-23` | Positive whole output emits one `OUTPUT_CHANNEL_BANKED` event per channel. | Event contract |
| `RB-24` | Bank event subject/source/payload/report/tutorial fields follow `DEC-0037`. | Event contract |
| `RB-25` | Recall and inactivity freeze channel state. | `DEC-0027` |
| `RB-26` | Same-loadout redispatch resumes unchanged state/rate. | `DEC-0028` |
| `RB-27` | Caller resolves old elapsed state before assignment/modifier change. | Boundary rule |
| `RB-28` | Compatible changed redispatch preserves core and channel residuals. | `DEC-0037` |
| `RB-29` | Compatibility compares returned period, Mastery period, and cycle duration. | `DEC-0037` |
| `RB-30` | Incompatible contexts return `REAPING_RATE_CONTEXT_INCOMPATIBLE` without mutation. | `DEC-0037` |
| `RB-31` | Assignment revision increments exactly once only after compatible validation. | `DEC-0035` |
| `RB-32` | Progress never changes solely because the future rate changes. | `DEC-0028` |
| `RB-33` | Repeated same context cannot compound rate or reduce ETA again. | `DEC-0028` |
| `RB-34` | Time-to-next-unit is a pure checked minimum-integer-ms query. | `DEC-0037` |
| `RB-35` | Four-hour 50%/1.20 fixture matches exact ETA values. | Approved fixture |
| `RB-36` | Settlement preserves acquisition state and segments channel rates exactly. | `DEC-0027`, `DEC-0036` |
| `RB-37` | Whole channel output at Settlement boundary banks before lifecycle change. | Same-time order |
| `RB-38` | One-shot and equivalent chunks produce exact equal state/deltas/events. | Determinism |
| `RB-39` | Every arithmetic/content/ownership/modifier failure preserves whole state. | Transaction contract |
| `RB-40` | Inventory, source counter, progress, carry, rate, ETA, and event arithmetic are checked. | `DEC-0026` |
| `RB-41` | Schema v2 persists exact acquisition/inventory/assignment/core state. | `DEC-0034` |
| `RB-42` | Persistence rejects Essence acquisition and malformed/misowned channel state. | Sole ownership |
| `RB-43` | Events, deltas, effective rates, and ETA are not save authority. | Persistence contract |
| `RB-44` | No M04E or later subsystem behavior enters the diff. | Slice boundary |
| `RB-45` | Actual scope is reported against estimate. | `DEC-0033` |

## State transitions

| ID | Initial state | Trigger | Required result | Failure behavior |
|---|---|---|---|---|
| `ST-01` | Active Overdue Gloamwood, zero channel state | Resolve 2h | 24 Soldier Souls; Scribe progress 250000 | — |
| `ST-02` | Same | Resolve 8h | 1 Scribe Form Soul banked | — |
| `ST-03` | Active Overdue Broken Watch | Resolve 6h | 720 Provisions; MAA progress 250000 | — |
| `ST-04` | Same | Resolve 24h | 1 MAA Form Soul banked | — |
| `ST-05` | Unknown channels | Resolve | Output banks; disclosure unchanged | — |
| `ST-06` | Partial active channel state | Recall then resolve idle | Channel state frozen; timeline advances | — |
| `ST-07` | Recalled same loadout | Redispatch then resolve | Resume exact state/rate | — |
| `ST-08` | Recalled, compatible changed Form with residuals | Redispatch | Same operation/residuals; revision +1 | Validation rejects atomically |
| `ST-09` | Recalled, incompatible period/duration | Redispatch | No change | Rate-context-incompatible |
| `ST-10` | Synthetic 4h source at 50% | Apply future x1.20 plan | Progress 500000; ETA 7200000→6000000 | — |
| `ST-11` | Same changed context | Repeat recall/redispatch | Same rate/ETA; no progress jump | — |
| `ST-12` | Partial channel crosses Settlement | Resolve | Boundary output first; retained progress; Settled remainder | — |
| `ST-13` | Any supported fixture | One-shot vs chunks | Exact state/delta/event equality | Any difference fails |
| `ST-14` | High-rate/long elapsed | Resolve | Multiple whole items extracted analytically | Overflow rejects atomically |
| `ST-15` | Resolved channel state | Save/load | Exact schema-v2 reconstruction | Malformed state rejects |
| `ST-16` | Acquisition state on Essence channel | Validate/load | No runtime exposure | Stable domain rejection |

## Rate-plan and condition contract

For an eligible channel, support:

```text
metric: OUTPUT_CHANNEL_RATE
operation: MULTIPLY
scope: OUTPUT_CHANNEL
conditions:
  ALWAYS
  OUTPUT_ITEM
  OUTPUT_KIND
  THRESHOLD_HAS_ANY_TAG
  THRESHOLD_LIFECYCLE
```

`WHOLE_SOUL` means Calling-Soul or Form-Soul output items. Runtime `OVERDUE` maps to condition token `STANDING`. Do not treat `REC_NAMES_KEPT` as purchased; it may be used only as a copied normalized modifier fixture until progression owns purchase state.

## Result and event extensions

Extend bounded M04C result records rather than replacing them.

Each segment and overall result expose deterministic channel deltas. A channel delta contains channel/item IDs, whole-unit delta, progress/carry before and after, and banked total before and after.

A whole-output event uses:

```text
event_type = OUTPUT_CHANNEL_BANKED
subject_id = Threshold ID
source_id = Channel ID
reportable = true
tutorial_relevant = channel.progression_required
```

The event occurs at the segment end and is ordered by channel ID before a same-time Settlement event.

## Required fixtures

```text
Gloamwood 2h:  Soldier=24, Scribe progress=250000
Gloamwood 8h:  Scribe whole=1
Broken Watch 6h: Provisions=720, MAA progress=250000
Broken Watch 24h: MAA whole=1
Synthetic 4h at 50%: ETA 7200000; x1.20 ETA 6000000; progress unchanged
```

## Architecture constraints

- One primary owner: M04D extension of `SimulationEngine`.
- One candidate transaction and one live commit.
- No second loop, timer, or clock.
- No floats in authoritative resolution.
- No content Resource mutation.
- No duplicate Essence path.
- No discovery gate.
- No cached rate/ETA authority.
- No carry transfer across incompatible denominators.
- No schema bump.
- No arbitrary UI-supplied modifiers.
- Canonical ordering for channels/modifiers/events.

## Expected files

| Area | Expected action |
|---|---|
| `src/simulation/simulation_engine.gd` | Extend segment resolution/results/events |
| `src/simulation/` bounded channel-rate/accumulator helper(s) | Add only as needed |
| `src/domain/reaping_assignment_service.gd` | Replace zero-residual guard with compatible-context check |
| `src/domain/game_state_validator.gd` | Strengthen acquisition/Essence ownership validation |
| `src/domain/fixed_point.gd` | Narrow ETA/boundary helper only if existing checked search cannot be reused |
| `tests/unit/m04d/` | Add channel/rate/reconfiguration/failure matrices |
| `tests/integration/m04d/` | Add persistence/load validation |
| `tools/test/m04d/m04d_output_channel_trace.gd` | Add deterministic trace |
| `tools/test/owner/run_m04d_owner_verification.ps1` | Add Windows package |
| Maintained docs | Synchronize realized contract/status |

Do not modify production `.tres` values.

## Acceptance criteria

| ID | Pass condition | Evidence | Gate? |
|---|---|---|---:|
| `AC-01` | Existing transactional engine owns all channel elapsed work. | Review/tests | Yes |
| `AC-02` | Eligible channels are exact, sorted, owned, and non-Essence. | Selection matrix | Yes |
| `AC-03` | Unknown channels produce without disclosure mutation. | Focused test/trace | Yes |
| `AC-04` | Gloamwood 2h/8h exact fixtures pass. | Test/trace | Yes |
| `AC-05` | Broken Watch 6h/24h exact fixtures pass. | Test/trace | Yes |
| `AC-06` | Multiple channels and multiple whole extraction are exact. | Focused tests | Yes |
| `AC-07` | Inventory is whole; progress/carry ranges and source counters are exact. | Tests/validator | Yes |
| `AC-08` | Supported modifiers/conditions and deterministic floor order pass. | Rate matrix | Yes |
| `AC-09` | Relevant unsupported modifiers fail; irrelevant metrics do not affect channels. | Negative matrix | Yes |
| `AC-10` | Channel Settled multiplier applies once and only after boundary. | Settlement tests | Yes |
| `AC-11` | Recall/inactivity freeze and same-loadout resume exactly. | Sequence test | Yes |
| `AC-12` | Compatible changed loadout preserves residuals and increments once. | Assignment integration | Yes |
| `AC-13` | Incompatible context rejects without mutation. | Negative integration | Yes |
| `AC-14` | Four-hour 50%/1.20 ETA fixture matches exactly. | Query test/trace | Yes |
| `AC-15` | Repeated redispatch does not compound or rebase. | Sequence test/trace | Yes |
| `AC-16` | Settlement retains channel state and same-time ordering. | Segment/event tests | Yes |
| `AC-17` | One-shot/chunk state, deltas, and events match exactly. | Chunk matrix | Yes |
| `AC-18` | Channel bank events have complete deterministic fields/order. | Event tests | Yes |
| `AC-19` | Every invalid/overflow case preserves exact state. | Failure matrix | Yes |
| `AC-20` | Schema-v2 coordinator round trips exact channel state. | Integration tests | Yes |
| `AC-21` | Load rejects Essence/misowned/malformed acquisition state. | Integration tests | Yes |
| `AC-22` | No duplicate progress in Reaping state or duplicate Essence grant exists. | Source/state audit | Yes |
| `AC-23` | Engine and helpers own no forbidden time/UI/platform/later-system source. | Source audit | Yes |
| `AC-24` | Linux focused/import/trace/full checks pass. | Commands/exits | Yes |
| `AC-25` | Windows owner package passes full/focused/import/13-marker/cleanup/audit/full. | Owner log | Yes |
| `AC-26` | Junior-readable comments explain non-obvious math/ownership. | Review | Yes |
| `AC-27` | Maintained docs are synchronized without duplicate sections. | Docs review | Yes |
| `AC-28` | Actual scope remains within assessment or work stops. | Handoff | Yes |

A pending owner result keeps M04D Partial and prevents merge.

## Automated verification

Run:

```bash
git status --short

./tools/test/run_gut.sh -- \
  -gdir=res://tests/unit/m04d \
  -gdir=res://tests/integration/m04d

godot --headless --path . --import

trace_root="$(mktemp -d)"
godot --headless --path . \
  -s res://tools/test/m04d/m04d_output_channel_trace.gd \
  -- --save-root "$trace_root"
trace_exit=$?
rm -rf "$trace_root"
test ! -e "$trace_root"
test "$trace_exit" -eq 0

./tools/test/run_gut.sh

git diff --check
git status --short
```

Negative trace root handling must fail nonzero. Add source audits and no-mutation comparisons for every failure.

## Owner-run Windows automated checks

Codex adds:

```text
tools/test/owner/run_m04d_owner_verification.ps1
```

Expected invocation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
    -File .\tools\test\owner\run_m04d_owner_verification.ps1 `
    -CommitSha "<PR_HEAD_SHA>"
```

Follow the final M04C workflow and verify all 13 exact markers.

Expected summary:

```text
Automated result: PASS
Failed step count: 0
Pending interactive checks: None for M04D
Cleanup result: PASS
```

No interactive checklist is required.

## Trace markers

```text
TRACE M04D gloamwood_2h_soldier=24_scribe_progress=250000
TRACE M04D gloamwood_8h_scribe_banked=1
TRACE M04D broken_watch_6h_provisions=720_maa_progress=250000
TRACE M04D broken_watch_24h_maa_banked=1
TRACE M04D hidden_channels_bank=PASS
TRACE M04D recall_freezes_redispatch_resumes=PASS
TRACE M04D compatible_loadout_change_preserves_progress=PASS
TRACE M04D rate_change_progress=500000_eta_before=7200000_eta_after=6000000
TRACE M04D repeated_redispatch_non_compounding=PASS
TRACE M04D settlement_preserves_channel_progress=PASS
TRACE M04D one_shot_equals_chunks=PASS
TRACE M04D save_round_trip=PASS
TRACE M04D no_duplicate_essence_or_reaping_progress=PASS
```

## Save/load verification

| Scenario | Expected |
|---|---|
| Partial 8h/24h sources | Exact progress/carry/source total |
| Whole extraction | Inventory and source total exact; remainder normalized |
| Recall/inactive | State frozen while timeline advances |
| Compatible changed loadout | All residuals preserved; new revision/rate future-only |
| Settlement | Same record retained; channel multiplier after boundary |
| Invalid Essence acquisition | Load rejected |
| Misowned/unknown/malformed record | Load rejected |
| Schema audit | Schema 2, codec/content revision/migrations unchanged |

## Documentation updates

Update canonical sections in:

- `docs/codex/MILESTONES.md`;
- `docs/codex/ARCHITECTURE.md`;
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`;
- `docs/codex/TESTING_AND_VALIDATION.md`;
- `docs/codex/DECISIONS.md` only to mark `DEC-0037` Accepted on prompt approval, not to weaken it;
- `README.md` only if the developer trace command is useful.

## Stop conditions

Stop and report if:

1. M04C is not merged/passed;
2. channel progress requires another aggregate or schema version;
3. Essence cannot remain single-owned;
4. current Forms are not denominator-compatible;
5. a compatible change would still lose or reinterpret residuals;
6. Retinue/Recollection/discovery/progression state is required;
7. multiple active Reapings must be supported;
8. production content must change;
9. another primary owner or more than two seams are needed;
10. source/test files exceed approximately 30 or code/test lines exceed approximately 1,500;
11. any required verification fails.

## Final response format

Use exactly:

### Implementation completed
### Files changed
### Verification
### Assumptions
### Known limitations and risks
### Deferred work
### Suggested next task

Under **Verification**, leave Windows owner verification pending. Under **Suggested next task**, state only that the owner runs the M04D Windows package. Do not draft M04E.
