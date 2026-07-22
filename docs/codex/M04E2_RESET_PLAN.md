# M04E2A implementation reset plan — superseded historical record

**Status:** Superseded  
**Date:** 2026-07-20  
**Superseded by:** Accepted `DEC-0043` and [M04E2 transaction redesign plan](M04E2_TRANSACTION_REDESIGN_PLAN.md) on 2026-07-22  
**Abandoned implementations:** PR #17 and PR #18, both closed unmerged

## Historical purpose

This document recorded the first reset after PR #17 failed to converge. It introduced M04E2A1 through M04E2A4 and correctly separated report state, ingestion, and read/snapshot/history concerns.

The M04E2A1 prerequisite subsequently failed through PR #18 because it attempted to reconcile an independently mutable candidate, typed result, and compatibility summary through a growing post-hoc validator.

The active implementation sequence is now defined by `DEC-0043`:

```text
M04E2T1 -> M04E2T2 -> M04E2A2 -> M04E2A3 -> M04E2A4 -> M04E2B
```

Use:

- `docs/codex/M04E2_IMPLEMENTATION_POSTMORTEM.md` for the failure record;
- `docs/codex/M04E2_TRANSACTION_REDESIGN_PLAN.md` for the active architecture and workflow;
- `docs/codex/milestone-prompts/M04E2T1-simulation-transaction-journal.md` for the next implementation prompt after approval.

Do not execute the superseded M04E2A1 prompt or reuse PR #17/PR #18 production implementation wholesale.
