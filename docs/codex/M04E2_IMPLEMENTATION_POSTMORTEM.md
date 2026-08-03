# M04E2 implementation postmortem — PR #17, PR #18, and PR #23

**Status:** Approved historical and engineering record  
**Date:** 2026-08-03
**Authority:** Accepted `DEC-0043`, `DEC-0044`, and `DEC-0045`
**Scope:** Failed M04E2 implementation attempts only; no blame assignment and no production-code authority

## Purpose

This document records why three M04E2 implementation attempts were closed unmerged, which findings remain useful, and which architecture patterns are prohibited in the replacement work.

The report design is not being abandoned. Reports remain informational, gains remain automatically banked, historical attribution remains required, and schema-v4 report persistence remains a later P1 slice after runtime transitions are proven.

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

## Replacement validation outcome — M04E2T2

M04E2T2 completed the second successful replacement prerequisite.

PR #22 merged from final head `00bd7d1ce27817b508eb0aac1663d1de48353237` at merge commit `afd390e8338a198d76938eef5ddcf35718ec189c`. The implementation added one global detached typed result family, pure projection from frozen transaction evidence, complete historical segment/channel facts, and a closed event union. It removed the raw public result grammar and migrated every current consumer without changing candidate mutation, formulas, commit order, schema version 3, or content revision.

Targeted review findings identified real boundary defects in Settlement cardinality, selected Retinue order, active-context fact completeness, self-validation, and owner-trace construction. Each was corrected with named regressions. Final targeted and unrestricted reviews were clean.

The exact-head owner package passed `178/178` full tests and `2,832` assertions before and after, `74/74` focused tests and `1,291` assertions, import, all fifteen markers, missing-root failure behavior, cleanup, and artifact audit.

The owner approved a T2-only scope exception for a final 1,460 net non-documentation/non-`.uid` line delta, 10 lines above the approximate planning threshold. No new authority, schema transition, report subsystem, or formula owner entered the slice.

This outcome does not rehabilitate PR #17 or PR #18. At the time of T2 closure, M04E2A2 was the planned follow-on and would have started from merged `main`, using the successful typed facts only as a future ingestion prerequisite. DEC-0045 later superseded that route after PR #23; M04E2R1 is now the next planning boundary. The former package must not be used to copy the failed report-state or `ReportService` implementation wholesale.

## Historical PR #17/#18 review-process lesson (superseded by G0 convergence policy)

A review must audit the primary risk boundary, but repeated clean-up reviews are not an implementation strategy. At the time of PR #17 and PR #18, the branch used this historical threshold list:

```text
more than 2 targeted rounds produce new P1/P2 findings
more than the milestone-specific material-finding limit
approved file/line guardrail crossed
new owner/schema/seam required
full suite red at review request
```

When triggered, return to architecture planning rather than issuing another patch prompt.

These numeric thresholds remain historical planning signals and do not automatically terminate a current pull request. The current controlling rule from the merged G0 convergence policy is: after two substantial correction rounds, pause for an explicit convergence assessment. Continue another bounded correction when remaining findings are local, understood, testable, and within the existing design. Stop, split, or redesign only when affirmative evidence indicates a systemic architecture, ownership, scope, or oracle problem. Round count alone is never dispositive.

A new owner, schema, or seam; an untrustworthy oracle; repeated root-cause survival; uncontrolled scope growth; or a required red suite may independently justify a stop. PR #23 is the evidence-based architecture-stop example: its repeated transition, coverage, provenance, compaction, sequence-authority, and runtime/wire-parity failures demonstrated systemic ownership and sequencing problems.

## Attempt 3 — PR #23

```text
Title: M04E2A2: Add report state and schema-v4 persistence
Terminal head: f68e6eac3347cde1b5347ce2d70cc4ce12ac3610
State: Closed unmerged
Commits: 8
Changed files: 58
Additions: 2,012
Deletions: 69
```

PR #23 attempted a complete report-state graph, schema version 4, `v3 -> v4` migration, mapping, runtime and primitive validators, and persistence before production owners existed for committed-run ingestion, snapshotting, compaction, retention, and reads.

### Material findings and classification

| # | Finding | Classification | Why it matters |
|---:|---|---|---|
| 1 | Primitive validation called `.is_empty()` before proving report children were containers. | Local defect | Retained malformed-input regression; not architecture proof by itself. |
| 2 | Increasing event sequence did not require deterministic temporal/priority order. | Architecture/ownership signal | Sequence authority preceded the append/order transition. |
| 3 | Disabled content references were accepted. | Both | The local check was missing; parallel runtime/wire semantic correction amplified duplicated authority. |
| 4 | A getter cloned malformed private `_window` before validation and masked aliasing. | Local defect | Retained safe-access regression; not architecture proof by itself. |
| 5 | Retained/live windows could overlap. | Architecture/ownership signal | Snapshot/history interval transitions were predicted rather than implemented. |
| 6 | Omitted event count could exceed preserved event-type totals. | Architecture/ownership signal | Compaction counters existed before compaction behavior. |
| 7 | Event-type totals could exceed retained plus omitted detail. | Architecture/ownership signal | Redundant independently stored counts created hidden authority. |
| 8 | Non-empty windows could claim zero ingested runs and no mode provenance. | Architecture/ownership signal | Future ingestion provenance had no ingestion owner. |
| 9 | `next_event_sequence` ignored compacted events with no retained detail. | Architecture/ownership signal | Next-ID authority depended on unimplemented compaction semantics. |
| 10 | Retained/live windows could contain gaps while the report cursor claimed coverage. | Architecture/ownership signal | Cursor authority depended on unimplemented contiguous transitions. |

Nine review threads were resolved during the branch. The final gap finding exposed another independent temporal-continuity class. Closure followed the repeated transition, coverage, provenance, compaction, sequence-authority, and runtime/wire-parity failures, not a defect count or review-round count. Findings 1 and 4 alone would normally justify bounded corrections and are not architecture evidence by themselves.

### Retained evidence and prohibited reuse

PRs #17, #18, and #23 remain forensic/regression evidence for black-box scenarios, malformed-input categories, aliasing and failure-preservation lessons, exact expected values, and review findings. They are not production-code sources: do not copy or cherry-pick their report implementations, validators, persisted graphs, or stopped schema field sets wholesale.

### Replacement architecture

`DEC-0045` replaces the former A2/A3/A4 execution route with `M04E2R1 -> M04E2R2 -> M04E2P1 -> M04E2B`. R1/R2 operate on one explicitly caller-owned non-persisted ledger; no application, `GameSession`, service member, autoload, singleton, or hidden global retains canonical mutable ledger state before P1. P1 gives `GameState` sole durable ownership and permits only gameplay/report cursor-aligned exposed or persisted state. B alone may transiently hold a gameplay-ahead/report-behind private candidate between simulation and ingestion; it starts and finishes aligned before validation and one live commit.
