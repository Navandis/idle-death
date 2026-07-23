# M04E2 implementation postmortem — PR #17 and PR #18

**Status:** Approved historical and engineering record  
**Date:** 2026-07-22  
**Authority:** Accepted `DEC-0043`  
**Scope:** Failed M04E2 implementation attempts only; no blame assignment and no production-code authority

## Purpose

This document records why two M04E2 implementation attempts were closed unmerged, which findings remain useful, and which architecture patterns are prohibited in the replacement work.

The report design is not being abandoned. Reports remain informational, gains remain automatically banked, historical attribution remains required, and schema-v4 report persistence remains a later approved slice.

## Attempt 1 — PR #17

```text
Title: Add schema-v4 report state and ReportService (M04E2A)
Terminal head: 5c87118045faa6f48f8ce50977a9bcdcfa967e57
State: Closed unmerged
Commits: 21
Changed files: 34
Additions: 2,333
Deletions: 32
```

### Intended scope

PR #17 combined:

- report runtime state;
- schema version 4;
- `v3 -> v4` migration;
- mapping and malformed-save validation;
- cursor-idempotent ingestion;
- historical attribution;
- checked aggregation;
- public read models;
- snapshotting and offline classification;
- bounded history and event retention;
- trace, owner runner, and documentation.

### Failure mode

`ReportService` became the validation, temporal-classification, attribution, aggregation, projection, snapshot, and retention owner. Each review pass exposed another interaction between those domains.

The branch crossed mandatory stop thresholds for review rounds, finding count, implementation growth, and approved scope.

### Durable lessons

- New authoritative state and schema migration require a separate slice from service mutation.
- Temporal/idempotent classification requires an explicit decision table.
- Historical attribution cannot be reconstructed from current mutable Reaping state.
- Public reads, snapshot policy, and retention should not be mixed into initial ingestion work.
- Focused tests and trace markers do not compensate for an oversized ownership boundary.

## Attempt 2 — PR #18

```text
Title: M04E2A1 typed SimulationResult contract
Terminal head: 602dec077f44338cdb4a2eabbd30d3989c877902
State: Closed unmerged
Commits: 8
Changed files: 15
Additions: 1,973
Deletions: 53
```

### Intended scope

PR #18 attempted to add typed segment/channel result records before report persistence so later consumers would receive historical assignment/loadout/lifecycle/source facts.

### Failure mode

The branch retained three separately mutable representations:

```text
candidate GameState
result segments/events
change_summary
```

A growing validator attempted to prove their equivalence before commit. Review findings repeatedly identified authoritative candidate fields not represented or compared by the result grammar, including:

- channel output-item/content identity;
- event ordering, identity, payload, and cardinality;
- overlapping summary fields;
- active versus timeline-only result shapes;
- content identity and Threshold/channel ownership;
- failed/zero result authority;
- unknown event types;
- Settlement boundary totals;
- malformed candidate dereferences before candidate validation;
- inventory totals not backed by banked channel facts;
- active-Reaping carries and cycle phase not authorized by result evidence.

The production engine grew by hundreds of lines while the malformed-result matrix also grew substantially. New P1/P2 findings continued after the terminal audit.

### Root cause

The candidate and result did not share structural provenance. A validator can compare only fields it knows to compare. Every newly considered authoritative state field creates another duplicate semantic contract.

The unsafe seam was equivalent to:

```text
commit_if_valid(live, arbitrary_candidate, arbitrary_result)
```

No amount of local result validation makes that seam intrinsically safe.

## Replacement principle

One internal transaction owns:

- the private candidate;
- immutable run context;
- checked mutations;
- one bounded fact journal;
- final candidate validation;
- public result projection;
- one final commit.

Mutation and fact recording occur together. Public results are generated from finalized journal facts and are never commit inputs.

## Retained evidence

The following may be reused as black-box requirements or re-authored regression scenarios:

- one-hour and eight-hour exact values;
- exact Settlement segmentation and same-time priority;
- progress-only and multi-whole channel behavior;
- same-timestamp recall/redispatch attribution;
- equal-output component identity;
- start-exclusive/end-inclusive event ownership;
- schema-v3 result exclusion;
- malformed-save mutation categories;
- owner-runner cleanup, negative-root, and failure-propagation lessons;
- review findings from both PRs.

## Prohibited reuse

Do not reuse wholesale:

- PR #17 `ReportService` or report-state implementation;
- PR #18 post-hoc result validator;
- a commit method accepting independently mutable candidate and result;
- independently authored `change_summary` authority;
- nested typed-result architecture solely because it already exists on the abandoned branch;
- branch-specific tests whose main purpose is to validate the failed internal decomposition.

## Replacement validation outcome — M04E2T1

The replacement principle was validated by M04E2T1 rather than remaining a planning hypothesis.

PR #21 merged from final head `a4d8056cb8771e84e1948fc5e59939c46a13003c` at merge commit `68364e0b417a6e7ebc63b50a386ac5d9f2c506bf`. The implementation introduced one immutable run context, one transaction-owned private candidate, one bounded journal, checked mutation-plus-fact operations, one-way finalization, and one live commit. `SimulationEngine` became smaller while focused collaborators owned transaction and journal behavior.

The final exact-head owner package passed `165/165` full tests and `2,641` assertions before and after, `61/61` focused tests and `1,136` assertions, import, all twelve markers, missing-root failure behavior, cleanup, and artifact audit. Final unrestricted review was clean.

This successful replacement does not rehabilitate PR #17 or PR #18 production code. Their defect findings remain useful, but their implementations remain prohibited reuse. M04E2T2 now projects typed public facts from the successful T1 journal rather than validating a separately mutated candidate.

## Review-process lesson

A review must audit the primary risk boundary, but repeated clean-up reviews are not an implementation strategy. The stop rule remains mandatory:

```text
more than 2 targeted rounds produce new P1/P2 findings
more than the milestone-specific material-finding limit
approved file/line guardrail crossed
new owner/schema/seam required
full suite red at review request
```

When triggered, return to architecture planning rather than issuing another patch prompt.
