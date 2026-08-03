# M04E2 single-provenance transaction redesign plan

**Status:** Historical T1/T2 architecture; M04E2A2/A3/A4 superseded by `DEC-0045`; M04E2R1 is the next planning boundary
**Date:** 2026-07-23  
**Authority:** Accepted `DEC-0043`; accepted `DEC-0044`; carried-forward report semantics from superseded `DEC-0041`/`DEC-0042`  
**Current merged baseline:** PR #22 merge commit `afd390e8338a198d76938eef5ddcf35718ec189c`, schema version 3 / `prototype-content-r2`  
**Abandoned references:** PR #17 and PR #18, both closed unmerged

## Purpose

This plan replaced the failed post-hoc candidate/result reconciliation approach with one single-provenance simulation transaction, then finalized its public typed fact projection. Both replacement prerequisites are now merged and verified. The former M04E2A2 boundary is superseded and non-executable; M04E2R1 is the current next planning boundary and has no approved implementation prompt.

The central rule remains:

> The same internal operation that changes the private candidate records the explanatory fact. Public results are projections of finalized journal facts, never independent commit inputs.

A second rule now applies to report work:

> M04E2A2 stores validated explanatory state only. It introduces no service that ingests, reads, snapshots, clears, or prunes that state.

## Historical former dependency sequence (superseded by `DEC-0045`; non-executable)

```text
M04E1
  -> M04E2T1 single-provenance simulation transaction       [Merged/Passed]
  -> M04E2T2 finalized typed run facts                      [Merged/Passed]
  -> M04E2A2 report state + schema v4                       [Approved]
  -> M04E2A3 live report ingestion
  -> M04E2A4 reads + snapshot + bounded history + evidence
  -> M04E2B atomic simulation/report coordinator + final M04 harness
```

## Branch, task, and pull-request workflow

Every active slice starts from current `main` in a new Codex desktop task and milestone-specific feature branch.

```text
synchronize main
-> create feature branch before edits
-> implement and verify locally
-> commit on the feature branch
-> push the branch
-> create or update one PR targeting main
-> report PR URL and exact head
-> stop without merge
```

Use [Codex desktop workflow](CODEX_DESKTOP_WORKFLOW.md) and `tools/codex/publish_milestone_pr.ps1`. Only the owner may merge, close, delete the branch, force-push, or replace the PR. Corrections update the same branch and PR.

Formal review remains a GitHub `@codex review` action. Corrections remain in the Codex desktop implementation task.

PR #17 and PR #18 may be inspected only for accepted review findings, black-box values, malformed-save categories, boundary cases, and evidence of unsafe patterns. No production commit or file is cherry-picked or copied wholesale.

## M04E2T1 realized boundary

```text
validated source + elapsed request
  -> private transaction candidate + journal
  -> candidate validation + journal freeze
  -> journal-derived result
  -> one live commit
```

Primary responsibilities:

- `SimulationEngine`: formulas, rate plans, segmentation, and bounded calculation inputs;
- `SimulationTransaction`: private candidate, checked mutations, finalization, and one commit;
- `SimulationFactJournal`: ordered bounded non-persisted facts;
- `SimulationRunContext`: immutable historical operation/loadout context.

M04E2T1 merged through PR #21 from final head `a4d8056cb8771e84e1948fc5e59939c46a13003c` at merge commit `68364e0b417a6e7ebc63b50a386ac5d9f2c506bf`.

Final exact-head evidence passed 165 full tests, 61 focused tests, all 12 markers, import, negative-root behavior, cleanup, and artifact audit. `GATE-SINGLE-PROVENANCE-TRANSACTION` is satisfied.

## M04E2T2 realized boundary

```text
finalized run context + frozen fact journal
  -> pure typed-fact projector
  -> detached typed result/segments/channels/events
  -> direct current-consumer passthrough
```

`SimulationResultProjector` is the public-fact projection owner. It receives no candidate/live `GameState` and cannot authorize commit. `SimulationTransaction` calls it only after candidate validation and journal freeze.

The merged public fact family provides:

- one global `SimulationResult` with four closed result kinds and exact run cursors;
- typed `SimulationSegmentResult` historical facts;
- typed `SimulationChannelDeltaResult` endpoints including period and backlog endpoints;
- a closed event union for channel banking and Settlement;
- pure self-validation, deep detachment, and value equality;
- no raw public segment/channel dictionaries, generic payloads, nested engine result/event ownership, or simulation `change_summary`.

M04E2T2 merged through PR #22 from final head `00bd7d1ce27817b508eb0aac1663d1de48353237` at merge commit `afd390e8338a198d76938eef5ddcf35718ec189c`.

Final exact-head evidence passed:

```text
full suite before/after: 178/178 tests, 2,832 assertions
focused M04C-M04E2T2: 74/74 tests, 1,291 assertions
import: PASS
15 exact trace markers: PASS
missing-root negative trace: PASS
cleanup and artifact audit: PASS
failed steps: 0
interactive checks: none
```

Targeted and unrestricted reviews were clean after bounded corrections. The owner-approved scope exception applies only to M04E2T2. `GATE-FINALIZED-RUN-FACTS` is satisfied.

## Historical former M04E2A2 planned boundary (superseded by `DEC-0045`; non-executable)

### Principal transition

```text
canonical runtime ReportState
  -> schema-v4 primitive mapping
  -> pure v3-to-v4 migration
  -> atomic persistence and exact reconstruction
```

### Primary owner

One report-state aggregate family rooted at `ReportState` becomes authoritative saved explanation inside `GameState`. The existing mapper/validator/migration/coordinator architecture persists it but does not own report behavior.

### Included state

- report cursor and next report/event sequences;
- dropped-history count;
- canonical live accumulator;
- immutable report records;
- component-based loadout identity;
- Threshold/revision/lifecycle attribution slices;
- generic inventory/Mastery maps;
- channel endpoint summaries;
- bounded common event detail.

### Schema boundary

M04E2A2 alone advances the writer from schema v3 to v4. It preserves codec `JSON_V1`, content `prototype-content-r2`, frozen v1/v2/v3 inputs, and all existing gameplay/envelope fields.

The pure v3-to-v4 migration creates canonical empty report state at the source simulation cursor and fabricates no historical report facts.

### Protected exclusions

M04E2A2 adds no:

- `ReportService` or report mutator;
- committed-result ingestion or interval classification;
- public report read model;
- snapshot/clear/archive command;
- history/event pruning mutation;
- offline classification;
- simulation/report atomic coordinator;
- UI, trusted-time, tutorial, Hall, support, analytics, or concurrency behavior.

## Report follow-on boundaries

### M04E2A3

Consumes finalized committed typed facts into live report state with an explicit cursor-idempotent interval table and checked aggregation. It adds no public reads, snapshots, or retention mutation.

### M04E2A4

Adds detached report reads, snapshot semantics, offline-only classification, bounded event/history pruning, and final report evidence.

### M04E2B

Coordinates committed simulation and report ingestion on one candidate and commits live state once, then supplies the final M04 harness.

## Review workflow

For each slice:

1. Codex desktop implementation-completeness pass and local Godot/GUT verification;
2. targeted GitHub `@codex review` for the slice's primary risk;
3. bounded correction with named regressions on the same PR branch;
4. repeat the same targeted category only when needed and within the stop rule;
5. one final unrestricted current-head GitHub review;
6. exact-head Windows owner package once;
7. evidence validation and owner-controlled merge;
8. documentation closure to Merged/Passed.

## Historical former M04E2A2 stop conditions (superseded by `DEC-0045`; non-executable)

Return to planning when any occurs:

```text
more than 2 targeted review rounds produce new P1/P2 findings
more than 6 material findings
more than 34 non-documentation source/test files
more than approximately 1,650 non-documentation code/test lines
another authoritative aggregate or schema transition is required
a third cross-layer seam is required
report ingestion/read/snapshot/pruning behavior becomes necessary
frozen v1/v2/v3 fixture bytes must change
simulation/result behavior must change
full suite is red at review request
```

## Current action

Do not review or execute the former M04E2A2 planning package or prompt. They are historical evidence only; G3 must plan M04E2R1.

```text
docs/codex/M04E2A2_PLANNING.md
docs/codex/milestone-prompts/M04E2A2-report-state-schema-v4-persistence.md
docs/codex/CODEX_DESKTOP_WORKFLOW.md
```

Historically, execution required owner approval and `GATE-REPORT-SCHEMA`; `DEC-0045` now supersedes that route and prohibits execution.
