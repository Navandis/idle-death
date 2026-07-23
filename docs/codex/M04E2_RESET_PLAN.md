# M04E2A implementation reset plan — superseded historical record

**Status:** Superseded  
**Date:** 2026-07-23  
**Superseded by:** Accepted `DEC-0043`, accepted `DEC-0044`, and [M04E2 transaction redesign plan](M04E2_TRANSACTION_REDESIGN_PLAN.md)  
**Abandoned implementations:** PR #17 and PR #18, both closed unmerged

## Historical purpose

This document recorded the first reset after PR #17 failed to converge. It introduced M04E2A1 through M04E2A4 and correctly separated report state, ingestion, and read/snapshot/history concerns.

The original M04E2A1 prerequisite failed through PR #18 because it attempted to reconcile independently mutable candidate, result, and summary representations. Accepted `DEC-0043` replaced that prerequisite with M04E2T1 single-provenance transactions and M04E2T2 finalized typed run facts.

The active sequence remains:

```text
M04E2T1 -> M04E2T2 -> M04E2A2 -> M04E2A3 -> M04E2A4 -> M04E2B
```

Completed replacements:

```text
M04E2T1: Merged/Passed through PR #21
M04E2T2: Merged/Passed through PR #22
```

The active next boundary is M04E2A2 report runtime state and schema-v4 persistence.

Use:

- `docs/codex/M04E2_IMPLEMENTATION_POSTMORTEM.md` for failed-attempt and successful replacement outcomes;
- `docs/codex/M04E2_TRANSACTION_REDESIGN_PLAN.md` for the active sequence and workflow;
- `docs/codex/M04E2A2_PLANNING.md` for the current planning boundary;
- `docs/codex/milestone-prompts/M04E2A2-report-state-schema-v4-persistence.md` after explicit owner approval.

Do not execute the superseded M04E2A1 prompt, re-execute completed T1/T2 prompts, continue PR #17/PR #18, or reuse their production implementation wholesale.
