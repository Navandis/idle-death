# M04E2 implementation reset plan

**Status:** Approved  
**Date:** 2026-07-20  
**Authority:** Accepted `DEC-0042`  
**Abandoned implementation:** PR #17, closed unmerged at `5c87118045faa6f48f8ce50977a9bcdcfa967e57`

## Purpose

This document records the operational reset after the direct M04E2A implementation failed to converge under review. It does not change the underlying Reaping Report design. It changes the implementation order, review boundaries, and prerequisite result contract.

Reports remain informational and never claim-gate already-applied gameplay gains. Attribution, cursor idempotency, offline-window isolation, bounded recent history, and schema-v4 migration remain required. They are now delivered in smaller pull requests.

## Branch rule

PR #17 is retained only as forensic history. Do not reopen it, continue its Codex task, or cherry-pick its production implementation wholesale.

Every replacement slice starts from current `main` in a new Codex task, new branch, and new pull request.

The abandoned branch may be inspected only for:

- accepted review findings;
- black-box expected outcomes;
- regression scenarios;
- evidence of why a particular implementation pattern was unsafe.

## Replacement sequence

```text
M04E2A1 typed committed simulation-result contract
  -> M04E2A2 report runtime state and schema-v4 persistence
    -> M04E2A3 cursor-idempotent live report ingestion
      -> M04E2A4 reads, snapshot, bounded history, and final evidence
        -> M04E2B atomic reported-run coordinator and final M04 harness
```

No later prompt is drafted or executed until the preceding slice is Merged/Passed and a fresh scope review is approved.

## Slice boundaries

### M04E2A1

Changes non-persisted result representation only:

- typed segment and channel-delta records;
- complete historical assignment/loadout/lifecycle/source identity;
- result validation before live commit;
- compatibility updates to current simulation/run/debug/test consumers.

It adds no report state and no schema change.

### M04E2A2

Changes authoritative report state and persistence only:

- report runtime types;
- clone/copy and validation;
- schema version 4;
- exact mapping;
- frozen historical fixtures;
- sequential `v3 -> v4` migration;
- persistence proof.

It adds no report service or report operations.

### M04E2A3

Changes live report ingestion only:

- interval decision table;
- cursor idempotency;
- checked aggregation;
- historical attribution from typed results;
- positive no-gain advancement;
- exact event boundaries;
- transactional failure behavior.

It adds no public reads, snapshot, offline classification, or history pruning.

### M04E2A4

Completes report operations and evidence:

- detached global and filtered read models;
- snapshot semantics;
- offline-only classification;
- bounded event details and recent history;
- real-file trace;
- owner runner;
- documentation and PR evidence.

### M04E2B

Coordinates one supplied-duration simulation and report ingestion as one candidate transaction and closes M04 through the final non-UI harness. It adds no report schema fields.

## Review and verification

Each replacement slice uses:

1. Codex pre-edit contract and scope report;
2. focused implementation and regression tests;
3. complete Linux/Codex suite and import;
4. one targeted review appropriate to the slice;
5. one unrestricted final review against the current head;
6. owner Windows verification once against the exact reviewed head;
7. merge and `Merged / Passed` documentation closure.

Do not run the owner Windows package after every intermediate correction.

## Mandatory stop conditions

Stop and return to planning when any occurs:

```text
more than 2 review rounds produce new P1/P2 findings
more than 8 material findings are discovered
implementation grows more than 50% beyond the approved estimate
full suite is red when review is requested
a downstream consumer lacks immutable upstream facts
another authoritative aggregate or schema transition becomes necessary
the approved file or line guardrail is crossed
```

## Current action

Submit the approved prompt:

```text
docs/codex/milestone-prompts/M04E2A1-typed-committed-simulation-result-contract.md
```

to a new Codex task after this planning-only reset package is merged to `main`.
