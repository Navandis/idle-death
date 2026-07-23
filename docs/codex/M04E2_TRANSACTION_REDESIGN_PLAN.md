# M04E2 single-provenance transaction redesign plan

**Status:** Approved architecture; M04E2T1 Merged/Passed; M04E2T2 implementation pull request open; verification partial
**Date:** 2026-07-22  
**Authority:** Accepted `DEC-0043`; Accepted `DEC-0044` for M04E2T2  
**Current merged baseline:** M04E2T1 through PR #21 on schema version 3 / `prototype-content-r2`  
**Abandoned references:** PR #17 and PR #18, both closed unmerged

## Purpose

This plan replaced the failed M04E2A1 result-validation approach with a single-provenance simulation transaction before report state. M04E2T1 has now realized and verified that prerequisite. The next planning boundary is M04E2T2: project final detached typed public run facts from the frozen transaction evidence and migrate current consumers without reopening candidate commit semantics.

The central rule remains:

> The same internal operation that changes the private candidate records the explanatory fact. Public results are projections of finalized journal facts, never independent commit inputs.

## Active dependency sequence

```text
M04E1
  -> M04E2T1 single-provenance simulation transaction       [Merged/Passed]
  -> M04E2T2 finalized typed run facts                      [Approved]
  -> M04E2A2 report state + schema v4
  -> M04E2A3 live report ingestion
  -> M04E2A4 reads + snapshot + bounded history + evidence
  -> M04E2B atomic simulation/report coordinator + final M04 harness
```

## Branch, task, and pull-request workflow

Every active slice starts from current `main` in a new Codex desktop task and milestone-specific feature branch.

The approved task flow is:

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

Use [Codex desktop workflow](CODEX_DESKTOP_WORKFLOW.md) and `tools/codex/publish_milestone_pr.ps1`. Only the owner may merge, close, delete the branch, force-push, or replace the PR. Later corrections in the same Codex task update the same branch and PR.

Formal review remains a GitHub `@codex review` action. Corrections remain in the Codex desktop implementation task.

PR #17 and PR #18 may be inspected only for accepted review findings, black-box values, boundary cases, regression descriptions, and evidence of unsafe patterns. No production commit or file is cherry-picked or copied wholesale.

## M04E2T1 realized boundary

### Principal transition

```text
validated source + elapsed request
  -> private transaction candidate + journal
  -> candidate validation + journal freeze
  -> journal-derived compatibility result
  -> one live commit
```

### Primary owners

- `SimulationEngine`: formulas, rate plans, segmentation, and bounded calculation inputs.
- `SimulationTransaction`: private candidate, checked mutations, finalization, and one commit.
- `SimulationFactJournal`: ordered bounded non-persisted facts.
- `SimulationRunContext`: immutable historical operation/loadout context.

### Completion record

M04E2T1 merged through PR #21 from final head `a4d8056cb8771e84e1948fc5e59939c46a13003c` at merge commit `68364e0b417a6e7ebc63b50a386ac5d9f2c506bf`.

Final exact-head owner evidence:

```text
full suite before/after: 165/165 tests, 2,641 assertions
focused M04C-M04E2T1: 61/61 tests, 1,136 assertions
import: PASS
12 exact trace markers: PASS
missing-root negative trace: PASS
cleanup and artifact audit: PASS
failed steps: 0
interactive checks: none
```

The owner approved the slice-specific line-count exception. `SimulationEngine` decreased by 39 net lines while focused transaction, trace, and owner evidence accounted for most additions.

`GATE-SINGLE-PROVENANCE-TRANSACTION` is satisfied.

## M04E2T2 realized boundary in the open implementation PR

### Principal transition

```text
finalized run context + frozen fact journal
  -> pure typed-fact projector
  -> detached typed result/segments/channels/events
  -> current consumer passthrough
```

### Primary owner

One `SimulationResultProjector` or equivalent is the public-fact projection owner. It receives no candidate or live `GameState`. `SimulationTransaction` remains the commit owner and calls the projector only after candidate validation and journal freeze.

### Public fact family

Accepted `DEC-0044` defines and the open implementation PR realizes:

- one global typed `SimulationResult` with explicit result kind and run cursors;
- typed `SimulationSegmentResult` historical facts;
- typed `SimulationChannelDeltaResult` endpoints including rate period;
- a closed event union for channel banking and Settlement;
- pure structural validation and detached value equality;
- removal of raw public result dictionaries, generic event payloads, and simulation `change_summary`.

Internal journal trace snapshots may remain primitive diagnostics. No raw public compatibility grammar remains after T2.

### Consumer migration

The slice migrates `SimulationEngine`, `SimulationTransaction`, `SimulationRunService`, `M04CDebugAdvance`, current unit/integration tests, affected traces, source audits, and persistence-exclusion checks.

### Protected exclusions

M04E2T2 does not change:

- candidate mutation or commit order;
- formulas, rates, segmentation, event timing, or exact values;
- schema version 3 or `prototype-content-r2`;
- report state, schema v4, ingestion, reads, snapshot, or history;
- UI, trusted time, tutorial, progression, Halls, support, analytics, or concurrency.

## Report boundaries

M04E2A2, A3, A4, and B retain the report semantics carried from prior decisions. They remain blocked until M04E2T2 is Merged/Passed.

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

## M04E2T2 stop conditions

Return to planning when any occurs:

```text
more than 2 targeted review rounds produce new P1/P2 findings
more than 6 material findings
more than 30 non-documentation source/test files
more than approximately 1,450 non-documentation code/test lines
another authoritative aggregate or schema transition is required
a third cross-layer seam or second primary projection owner is required
candidate mutation or commit semantics must change
raw and typed public grammars cannot be removed in one bounded migration
full suite is red at review request
```

## Current action

Review the open M04E2T2 implementation pull request and run the exact-head owner package after final GitHub review:

```text
accepted DEC-0044
docs/codex/M04E2T2_PLANNING.md
docs/codex/milestone-prompts/M04E2T2-finalized-typed-run-facts.md
docs/codex/CODEX_DESKTOP_WORKFLOW.md
tools/test/owner/run_m04e2t2_owner_verification.ps1
```

Do not mark M04E2T2 Merged/Passed until final review and exact-head owner verification are complete.
