# M04E2 single-provenance transaction redesign plan

**Status:** Approved architecture; M04E2T1 prompt remains Draft pending owner approval  
**Date:** 2026-07-22  
**Authority:** Accepted `DEC-0043`  
**Current merged baseline:** M04E1 on schema version 3 / `prototype-content-r2`  
**Abandoned references:** PR #17 and PR #18, both closed unmerged

## Purpose

This plan replaces the failed M04E2A1 result-validation approach with a single-provenance simulation transaction before report state is introduced.

The central rule is:

> The same internal operation that changes the private candidate records the explanatory fact. Public results are projections of finalized journal facts, never independent commit inputs.

## Active dependency sequence

```text
M04E1
  -> M04E2T1 single-provenance simulation transaction
  -> M04E2T2 finalized typed run facts
  -> M04E2A2 report state + schema v4
  -> M04E2A3 live report ingestion
  -> M04E2A4 reads + snapshot + bounded history + evidence
  -> M04E2B atomic simulation/report coordinator + final M04 harness
```

## Branch and reuse rules

Every active slice starts from current `main` in a new Codex desktop task, branch, and PR.

PR #17 and PR #18 may be inspected only for:

- review findings;
- exact black-box values;
- boundary cases;
- regression scenario descriptions;
- evidence that an implementation pattern is unsafe.

No production commit or file is cherry-picked or copied wholesale.

## M04E2T1 boundary

### Principal transition

```text
validated source + elapsed request
  -> private transaction candidate + journal
  -> finalized candidate + compatibility result
  -> one live commit
```

### Primary owner

`SimulationEngine` remains the formula/segmentation owner. A focused transaction collaborator owns candidate mutation provenance and finalization.

### Required internal roles

- immutable run context;
- private candidate;
- checked mutation methods;
- bounded fact journal;
- finalization state;
- compatibility result builder from journal;
- one commit path.

### External compatibility

M04E2T1 does not change:

- current formulas or content;
- public result fields or raw segment/channel compatibility representation;
- typed `SimulationEvent` envelope;
- `SimulationRunService` modes;
- forecast semantics;
- debug behavior;
- save schema or content revision;
- one-active-Reaping limitation.

### Demonstrable result

A trace and tests prove that core, channel, Settlement, and timeline mutations share provenance with their compatibility facts and that a failure after partial candidate work leaves live state unchanged.

## M04E2T2 boundary

M04E2T2 adds final public typed facts after the transaction journal is stable. It removes raw public segment/channel dictionaries and migrates current consumers. It does not change candidate mutation.

The final field matrix is drafted from:

- finalized journal facts;
- current consumers;
- later report-ingestion needs;
- accepted historical-attribution and event-boundary contracts.

## Report boundaries

M04E2A2, A3, A4, and B retain the report semantics carried from prior decisions. They remain blocked until M04E2T2 is Merged/Passed.

## Review workflow

For each slice:

1. Codex desktop implementation-completeness pass and local Godot/GUT verification;
2. targeted GitHub `@codex review` for the slice's primary risk;
3. bounded correction with named regressions;
4. repeat the same targeted category only when needed and within the stop rule;
5. one final unrestricted current-head GitHub review;
6. exact-head Windows owner package once;
7. evidence validation and merge;
8. documentation closure to Merged/Passed.

## M04E2T1 stop conditions

Return to planning when any occurs:

```text
more than 2 targeted review rounds produce new P1/P2 findings
more than 6 material findings
more than 24 non-documentation source/test files
more than approximately 1,300 non-documentation code/test lines
SimulationEngine grows into the transaction/journal implementation rather than delegating it
another authoritative aggregate, schema transition, or third cross-layer seam is required
public result semantics must change before M04E2T2
```

## Current action

Review and approve:

```text
docs/codex/milestone-prompts/M04E2T1-simulation-transaction-journal.md
```

Do not execute the prompt while its status is Draft.
