# M04E2T2 finalized typed run-facts planning

**Status:** Approved  
**Date:** 2026-07-22  
**Planning inspection baseline:** `main` at `c2cb7c1b4013b5d7c257f2ab513a70117c9de0d3` after M04E2T1 closure documentation  
**Prerequisite:** M04E2T1 Merged/Passed through PR #21  
**Decision:** Accepted `DEC-0044`  
**Prompt:** `docs/codex/milestone-prompts/M04E2T2-finalized-typed-run-facts.md` Approved v0.1

## Purpose

M04E2T2 turns the trustworthy internal facts established by M04E2T1 into one final detached public result contract. It replaces the current raw public segment/channel dictionaries and generic event payload dictionaries, migrates every current consumer, and leaves candidate mutation and commit ownership untouched.

This is a representation/projection slice, not a simulation rewrite and not a report implementation.

## Baseline findings

Current merged behavior has:

- a private transaction candidate and immutable run context;
- a bounded journal with `TIMELINE`, `CORE_SEGMENT`, `CHANNEL_SEGMENT`, and `SETTLEMENT` facts;
- candidate validation before journal freeze;
- one final source `copy_from`;
- nested `SimulationEngine.SimulationResult` and `SimulationEvent` classes;
- raw segment dictionaries;
- raw channel-delta dictionaries;
- generic event payload dictionaries;
- a journal-derived simulation `change_summary`;
- `SimulationRunService` and `M04CDebugAdvance` typed against the nested result;
- no report state and schema version 3.

The current public representation is safe as a temporary journal projection, but it is not the durable typed fact boundary required by delayed report ingestion.

## Protected invariants

- Candidate mutation and fact provenance remain exactly as implemented in M04E2T1.
- `SimulationEngine` remains formula/segmentation owner.
- `SimulationTransaction` remains private-candidate/finalization/commit owner.
- Public facts never enter `commit_to()` and never authorize state.
- Online, offline-fixture, debug, and forecast paths continue to use one engine.
- Exact one-hour, eight-hour, Settlement, channel, chunking, rate-context, mode, and forecast outcomes remain unchanged.
- Historical identity is component-based and captured at run time.
- Schema remains version 3; content remains `prototype-content-r2`.
- No report state, migration, report service, UI, trusted time, or concurrency is added.

## Proposed class and file layout

The implementation may adjust exact file names during the required pre-edit inspection, but responsibilities remain separated:

```text
src/simulation/results/simulation_result.gd
src/simulation/results/simulation_segment_result.gd
src/simulation/results/simulation_channel_delta_result.gd
src/simulation/results/simulation_event.gd
src/simulation/results/simulation_channel_banked_event.gd
src/simulation/results/simulation_threshold_settled_event.gd
src/simulation/results/simulation_result_projector.gd
```

These are global typed `RefCounted` classes. The result classes own no gameplay state and expose no mutation API. The projector is pure.

`SimulationTransaction` calls the projector after candidate validation and journal freeze. `SimulationEngine` returns the global result. `SimulationRunService` and debug adapters pass the typed result through.

## Result-shape matrix

| Kind | Success | Requested | Committed | Segments | Events | Cursor rule |
|---|---:|---:|---:|---|---|---|
| `FAILURE` | false | may be negative or non-negative | 0 | empty | empty | baseline == result |
| `ZERO_DURATION` | true | 0 | 0 | empty | empty | baseline == result |
| `TIMELINE_ONLY` | true | positive | equals requested | empty | empty | result - baseline == committed |
| `ACTIVE_REAPING` | true | positive | equals requested | non-empty | closed union | full contiguous interval |

Positive success includes the validated content revision. Failure/zero shapes do not claim content validation when the current behavior returns before context creation.

## Journal-to-public matrix

| Internal evidence | Public projection |
|---|---|
| `SimulationRunContext` | result baseline/request/content and segment historical identity |
| `TIMELINE` | result cursor and committed interval |
| `CORE_SEGMENT` | one typed segment's timing, lifecycle, and core deltas |
| `CHANNEL_SEGMENT` | one typed channel delta and optional channel-banked event |
| `SETTLEMENT` | one typed Settlement event and lifecycle sequence validation |
| journal order | stable segment/event order |

Candidate `GameState` is intentionally absent from this matrix.

## Consumer-input matrix

| Consumer | Required T2 input |
|---|---|
| `SimulationEngine` caller | global typed result envelope |
| `SimulationRunService` | exact typed result passthrough plus existing mode/projection metadata |
| `M04CDebugAdvance` | global typed result |
| M04C tests/trace | typed segment/core facts and events |
| M04D2 tests/trace | typed channel endpoints and channel events |
| M04D3 tests/trace | historical component identity and unchanged outcomes |
| M04E1 tests/trace | typed forecast/commit/mode equality |
| M04E2T1 tests/trace | projector remains downstream of frozen journal and candidate commit seam remains absent |
| persistence tests | absence of all result/fact artifacts |
| future M04E2A3 | self-contained interval, attribution, core, channel, and closed event facts |

No current consumer requires simulation `change_summary` after direct migration.

## Closed event grammar

### Channel banked

One `SimulationChannelBankedEvent` exists for each segment/channel delta with positive `banked_units_delta`. It is absent for progress-only deltas. Its typed fields agree with the owning channel delta and segment lifecycle. Its time is the owning segment end.

### Threshold settled

One `SimulationThresholdSettledEvent` exists if and only if the run transitions `OVERDUE -> SETTLED`. It belongs to the ending Overdue segment and retains boundary persistent-return and backlog/lifecycle endpoints.

### Common order and ownership

```text
occurred_simulation_msec
priority
subject_id
source_id
```

Every event has an explicit zero-based `segment_index`. Time membership remains:

```text
segment.start_simulation_msec < event.occurred_simulation_msec
    <= segment.end_simulation_msec
```

## Structural validation boundary

Public facts support pure validation so later consumers can reject malformed detached objects. The validator checks only:

- closed result shape;
- numeric and ID domains;
- segment index/timing/contiguity;
- stable historical identity;
- lifecycle sequence;
- channel uniqueness/order/endpoints;
- event subtype/order/ownership/cardinality;
- deep detachment and typed child classes.

It does not receive candidate state, compare candidate fields, reproduce rates, or decide whether live state may commit.

## Compatibility removal

The implementation removes the transitional public API in one slice:

- no raw public segment dictionaries;
- no raw public channel-delta dictionaries;
- no generic public event payload dictionary;
- no simulation `change_summary`;
- no nested `SimulationEngine.SimulationResult`/`SimulationEvent` ownership.

Internal journal trace snapshots may remain dictionaries. Unrelated domain-service summaries remain untouched.

## Test and evidence plan

Add:

```text
tests/unit/m04e2t2/
tests/integration/m04e2t2/
tools/test/m04e2t2/m04e2t2_finalized_facts_trace.gd
tools/test/owner/run_m04e2t2_owner_verification.ps1
```

Migrate applicable M04C/M04D2/M04D3/M04E1/M04E2T1 tests and traces directly. Do not keep raw compatibility assertions as a second API.

The trace emits the 15 exact markers defined in `TESTING_AND_VALIDATION.md` and the prompt. The Windows package requires detected Git head equality when `-CommitSha` is supplied.

## Scope assessment

| Item | Draft assessment |
|---|---|
| Primary owner | One typed-fact projector/family |
| Principal transition | Frozen context+journal -> detached typed public facts |
| Authoritative state | None |
| Schema/content change | None |
| Cross-layer seams | 2 |
| Risk dimensions | 3 |
| Expected non-doc files | 14–26 |
| Expected code/test delta | 700–1,250 lines |
| Stop threshold | 30 files or approximately 1,450 lines |
| Platform/native behavior | None |
| Interactive checks | None |

Stop before editing if inspection shows another authoritative owner, schema transition, candidate mutation change, third seam, or an unavoidable parallel public grammar.

## Review plan

Targeted review focuses on:

1. typed field completeness and detachment;
2. frozen-journal-only projection with no candidate input;
3. exact result shapes and full interval coverage;
4. closed event subtype/cardinality/segment ownership;
5. historical attribution and equal-output distinction;
6. removal of raw public grammar and simulation summary;
7. current consumer migration and equality;
8. persistence exclusion and later-slice scope.

After a clean targeted audit, run one unrestricted review. Stop under the project rule if more than two targeted rounds produce new P1/P2 findings or more than six material findings.

## Codex desktop delivery

The approved prompt will require:

```text
base: main
feature branch: codex/implement-m04e2t2
PR target: main
PR title: M04E2T2: Add finalized typed simulation run facts
```

After commit and local verification, Codex uses `tools/codex/publish_milestone_pr.ps1`, reports the PR URL/head, and stops. It never merges, auto-merges, closes, deletes, force-pushes, or pushes to main.

## Approval checklist

Before implementation, the owner must confirm:

```text
DEC-0044: Accepted
M04E2T2 definition: Approved
M04E2T2 prompt: Approved v0.1 or later
GATE-FINALIZED-RUN-FACTS: Satisfied
GATE-SLICE-SCOPE: Satisfied
Codex desktop workflow: Approved
```
