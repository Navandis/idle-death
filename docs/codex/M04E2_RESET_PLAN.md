# M04E2A implementation reset plan — superseded historical record

**Status:** Superseded  
**Date:** 2026-07-23  
**Last updated:** 2026-08-03
**Superseded by:** Accepted `DEC-0043`, accepted `DEC-0044`, accepted `DEC-0045`, and [M04E2 transaction redesign plan](M04E2_TRANSACTION_REDESIGN_PLAN.md)
**Forensic implementations:** PR #17, PR #18, and PR #23, all closed unmerged

> **Current routing (2026-08-03):** `DEC-0045` makes M04E2A2/A3/A4 superseded and non-executable. M04E2R1 is the next planning boundary; no R1 implementation prompt is approved.

## Historical purpose

This document recorded the first reset after PR #17 failed to converge. It introduced M04E2A1 through M04E2A4 and correctly separated report state, ingestion, and read/snapshot/history concerns.

The original M04E2A1 prerequisite failed through PR #18 because it attempted to reconcile independently mutable candidate, result, and summary representations. Accepted `DEC-0043` replaced that prerequisite with M04E2T1 single-provenance transactions and M04E2T2 finalized typed run facts.

The historical former sequence was:

```text
M04E2T1 -> M04E2T2 -> M04E2A2 -> M04E2A3 -> M04E2A4 -> M04E2B
```

Completed replacements:

```text
M04E2T1: Merged/Passed through PR #21
M04E2T2: Merged/Passed through PR #22
```

The former M04E2A2 next boundary is superseded and non-executable. The current next planning boundary is M04E2R1.

Use:

- `docs/codex/M04E2_IMPLEMENTATION_POSTMORTEM.md` for failed-attempt and successful replacement outcomes;
- `docs/codex/M04E2_TRANSACTION_REDESIGN_PLAN.md` for the historical T1/T2 plan and current routing notice;
- the former M04E2A2 plan/prompt as historical non-executable evidence only;
- G3 planning for the future M04E2R1 boundary.

Do not execute the superseded M04E2A1 prompt, re-execute completed T1/T2 prompts, continue PR #17, PR #18, or PR #23, or reuse any of the three production implementations wholesale.
