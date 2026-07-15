# Death Idle — Remaining Milestone Recalibration Proposal

**Document role:** Approved decomposition policy and revised implementation slicing after M03  
**Repository path:** `docs/codex/MILESTONE_RECALIBRATION_PROPOSAL.md`  
**Status:** Approved and adopted by the project governance package  
**Approval date:** 2026-07-15  
**Applies to:** Unstarted implementation work from M04 onward  
**Adoption:** Implemented by `DEC-0033`, `MILESTONES.md` revision 12, `PROMPT_TEMPLATE.md` revision 4, and `TESTING_AND_VALIDATION.md` revision 10

## 1. Why recalibration is necessary

M03 ultimately passed, but its review surface was too large for one implementation task:

- 131 changed files;
- 3,347 additions and 33 deletions;
- typed Resource-family design;
- sixty production definitions;
- twenty terminology entries;
- normalization and validation;
- persistence-revision integration;
- tests, trace, Windows automation, Inspector verification, and documentation.

The difficulty was not only algorithmic complexity. Several defects were simple but consequential authored-data mistakes: wrong canonical IDs, wrong backlogs, wrong milestone-to-guarantee mappings, missing condition operands, incomplete resonance effects, and ambiguous discovery metadata.

The existing milestone rules already require one focused, reviewable pull request and permit splitting. The current M04 definition does not meet that practical standard: it combines authoritative state, persistence, dispatch, simulation, independent output channels, long-horizon progress, rate-change boundaries, forecast cloning, report accumulation, multiple resolution modes, and a developer harness.

No unsplit M04 implementation prompt may be drafted. The canonical milestone map now treats M04 as a conceptual epic and defines M04A–M04E as the approved implementation slices.

## 2. Planning conclusion

Raw line count is not the only useful predictor. The higher-risk variable is the number of independent correctness domains changed at once.

A future task should normally have:

1. one primary subsystem owner;
2. one principal behavior or state transition;
3. no more than two cross-layer integration seams;
4. one developer- or player-visible demonstration;
5. one focused owner-verification package;
6. no unrelated production-content bulk added alongside a new framework.

A task should be split before prompt approval when it combines four or more of these risk dimensions:

- new authoritative state ownership;
- save-schema or migration changes;
- deterministic simulation or boundary algorithms;
- a new player-facing UI flow;
- native/platform integration;
- bulk authored content;
- live/offline/forecast equivalence;
- exactly-once progression or transactional guarantees;
- multiple independently testable domain services.

## 3. Review-surface guardrails

These are planning triggers, not mechanical merge quotas.

| Guardrail | Normal target | Mandatory split review |
|---|---:|---:|
| Primary subsystem owners | 1 | More than 1 |
| New authoritative aggregate families | 0–1 | More than 2 |
| Save-schema transitions | 0–1 | More than 1 |
| New player-facing flows/screens | 0–1 | More than 1 |
| New platform/native integrations | 0–1 | Any platform work mixed with unrelated gameplay |
| Non-documentation source/test files | Approximately 10–25 | More than 35 |
| Non-documentation code/test line delta, excluding `.uid` and repetitive authored data | Approximately 500–1,200 | Forecast above approximately 1,500 |
| Bulk `.tres` content | Small fixture set | Production catalog bulk mixed with new framework code |

A prompt exceeding a trigger must either:

- be split;
- justify why the review surface is still coherent; or
- stop for owner approval.

The prompt author should estimate the likely changed areas and risk dimensions before approval. Codex must report material scope growth before continuing.

## 4. Milestone-ID strategy

Preserve the existing conceptual M04–M17 numbering and add lettered implementation slices.

Examples:

```text
M04A
M04B
M04C
```

This avoids renaming accepted decisions and design references that already discuss M06 trusted time, M16 offline-return UX, and M17 final acceptance.

The unsplit M04–M17 entries become conceptual epics. They are not directly executable after recalibration. Only an approved lettered slice receives a Codex implementation prompt.

## 5. Immediate M04 decomposition

### M04A — Gameplay state and persistence foundation

**Primary owner:** authoritative state and schema mapping.

**Outcome:** one valid Gloamwood/Man-at-Arms fixture can be constructed, validated, cloned, saved, loaded, and compared exactly without dispatching or advancing production.

**Included:**

- minimal `InventoryState`;
- minimal `FormState`;
- minimal `ThresholdState`;
- minimal `ReapingState`;
- the smallest aggregate/counter state required by later slices;
- explicit validation and deep cloning;
- schema transition, migration or owner-approved reset policy;
- representative fixtures and round-trip tests.

**Excluded:**

- dispatch commands;
- elapsed production;
- output-channel accumulation;
- reports;
- forecast;
- UI.

**Decision gate:** M02 froze schema version 1. M04A must not silently add gameplay keys to schema v1. Before implementation, approve either a real next schema version and migration or an explicit prototype reset policy.

### M04B — Dispatch, recall, and assignment integrity

**Primary owner:** assignment commands and capacity validation.

**Outcome:** a valid Form can be dispatched to Gloamwood, recalled, and redispatched through explicit commands while assignment revision and tether occupancy remain exact.

**Included:**

- one command tether;
- one active Reaping per Threshold;
- awakened/available/Form/Writ validation;
- dispatch, recall, and redispatch;
- assignment revision;
- invalid-action no-mutation behavior;
- save round trip of assignment state.

**Excluded:**

- elapsed production;
- forecast;
- reports;
- output progress;
- UI beyond a headless trace.

### M04C — Single-Reaping core resolver

**Primary owner:** deterministic elapsed-time simulation for backlog, Essence, and Mastery.

**Outcome:** one active Gloamwood Reaping advances by supplied elapsed milliseconds with exact chunking equivalence.

**Included:**

- pure scene-independent resolver;
- backlog reduction;
- Essence banking;
- Mastery accumulation;
- fixed-point residuals;
- stable boundary ordering;
- zero-duration-loop protection;
- supplied-duration and debug-advance adapters using one rule path;
- save/load of core residuals and counters.

**Excluded:**

- rare/item output channels;
- recall-time rate changes beyond M04B assignment boundaries;
- forecast cloning;
- report accumulation;
- UI.

### M04D — Output channels and long-horizon acquisition progress

**Primary owner:** Threshold-owned item-channel progress.

**Outcome:** configured whole-item channels bank complete items while preserving normalized partial work and exact carry across recall, redispatch, rate changes, settlement, and save/load.

**Included:**

- generic channel accumulation from M03 definitions;
- whole-unit extraction and residual carry;
- stable `Threshold ID + Channel ID` ownership;
- one-item-per-8-hour and one-item-per-24-hour cases;
- prospective non-compounding modifier changes;
- recall/redispatch preservation;
- settlement preservation;
- repeated redispatch with unchanged configuration producing no repeated bonus.

**Excluded:**

- player-facing progress bars;
- discovery disclosure;
- forecast UI;
- reports.

### M04E — Forecast clone, report accumulator, and simulation harness

**Primary owner:** non-authoritative projections and already-applied reporting.

**Outcome:** a developer can forecast one hour on a deep clone, commit the same duration separately, compare exact results, and inspect report deltas that never gate inventory.

**Included:**

- forecast clone service;
- live/supplied-duration/offline-fixture/debug equivalence at the simulation boundary;
- report accumulator for already-applied deltas;
- report clear/snapshot semantics needed by later UI;
- deterministic developer trace;
- save/load for report state if introduced.

**Excluded:**

- player-facing report screen;
- application shell;
- trusted Steam time;
- tutorial and narrative.

## 6. Preliminary decomposition of later conceptual milestones

Exact slice definitions should be finalized immediately before prompt drafting, using the then-current repository. The default expectation is:

| Conceptual epic | Preliminary slices | Rationale |
|---|---|---|
| M05 application shell | `M05A` GameApp/GameSession lifetime and startup persistence; `M05B` navigation, read models, resizing, and debug access | Separates lifecycle authority from presentation/tooling |
| M06 Steam trusted time | `M06A` GodotSteam bridge/provider and fake-bridge tests; `M06B` transactional offline lifecycle, reconnect, and live Windows proof | Separates native API risk from save/simulation integration |
| M07 dialogue/tutorial framework | `M07A` dialogue presentation and persisted sequence cursor; `M07B` tutorial coordinator, skip/help, and pending reconstruction | Avoids one framework task owning two distinct orchestration systems |
| M08 opening slice | `M08A` Beats 1–3 through Brand; `M08B` first player-facing dispatch | Keeps one-time story transactions separate from Reaping UI integration |
| M09 Archive/Soulweave | `M09A` Archive restoration and Recollection purchase; `M09B` Soulweave topology and Form detail | Separates domain transactions from a thirty-position UI |
| M10 report/Soldier Company | `M10A` 1,000 boundary, Emergency transition, and first report; `M10B` Muster, reservation ledger, and Soldier Company | Separates boundary/report correctness from inventory reservations |
| M11 Scribe | May remain one slice if prompt review stays within guardrails | Current scope is relatively cohesive |
| M12 Broken Watch/concurrency | `M12A` resonance, Threshold unlock, and tether grant; `M12B` second Reaping, reassignment, and map integration | Separates exactly-once progression from concurrent simulation |
| M13 discovery | `M13A` discovery state and hidden banking; `M13B` forecast confidence, disclosure UI, and acquisition-progress presentation | Separates authoritative discovery from presentation |
| M14 Larder/support | `M14A` Hall/recipe simulation and onboarding guarantee; `M14B` Ration consumption, reduced effect, recovery, and UI | Separates producer from consumer/degradation logic |
| M15 regional resonance | May remain one slice if prompt review stays within guardrails | Current scope is smaller, but must be re-estimated |
| M16 offline-return UX | `M16A` forecast/report-history presentation; `M16B` trusted welcome-back, pending state, and tutorial completion | Separates projection UI from live trusted-return flow |
| M17 acceptance | `M17A` functional/softlock/end-to-end acceptance; `M17B` pacing, telemetry, responsive layout, accessibility, and performance | Separates correctness repair from tuning/quality measurements |

This preliminary plan produces approximately twenty-nine implementation slices from M04 onward if every suggested split is retained. That is intentionally a planning maximum, not a requirement to create all prompts now.

## 7. Rolling-wave planning rule

Do not fully specify every future slice today.

Before each conceptual epic:

1. inspect the merged repository;
2. confirm the preceding slice's actual state and tests;
3. enumerate the new risk dimensions;
4. decide whether the preliminary split remains appropriate;
5. draft only the next slice prompt;
6. require owner approval before Codex execution.

This limits speculative architecture while preventing oversized tasks.

## 8. Verification changes

Every lettered slice must select one owner-verification mode:

- automated PowerShell log only;
- automated PowerShell log plus Inspector checklist;
- automated PowerShell log plus gameplay/visual checklist;
- checklist-only when automation adds no value.

A later slice may reuse and extend a prior script, but it must not silently turn one validation package into a full-epic test that hides which slice failed.

Each slice's log must identify:

- slice ID;
- PR head;
- focused tests for that slice;
- full regression result;
- trace or demonstration result;
- pending manual checks;
- cleanup;
- final PASS/FAIL.

## 9. Adopted governance changes

The approved governance package:

1. records M03 as merged and passed at final head `971cdaa0fd46f641ec7409148e259d54f953d8c7` and merge commit `5e2b9b23878c9280f75b987cc9ad567d8980030d`;
2. adds an accepted decision for rolling milestone decomposition and review-surface guardrails;
3. changes M04–M17 from directly executable milestones to conceptual epics;
4. adds M04A–M04E as the next approved definitions;
5. marks M04A prompt `Not drafted`;
6. updates the dependency map and gate language;
7. updates `PROMPT_TEMPLATE.md` with mandatory risk-dimension and scope-estimate fields;
8. updates `TESTING_AND_VALIDATION.md` with per-slice owner evidence rules.

No M04A implementation prompt is included in this governance package. After these files are committed, the next planning step is to resolve `GATE-GAMEPLAY-SCHEMA` and then draft M04A through the ordinary prompt-approval workflow.

## 10. Approval record

The project owner approved the following on 2026-07-15:

```text
Approve the rolling-wave model, the review-surface guardrails, the lettered ID strategy, and the M04A–M04E decomposition. Treat later decompositions as preliminary until each conceptual epic is reached.
```

This approval authorizes the governance changes only. Each implementation-slice prompt still requires separate drafting, review, and owner approval.
