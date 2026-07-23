# M04E2T2 finalized typed run-facts planning — completed record

**Status:** Implemented, Merged, and Passed  
**Date:** 2026-07-23  
**Planning baseline:** `main` at `4e261a9b641e9bec92f091762209224cc371d60e` after M04E2T1 closure  
**Final implementation head:** `00bd7d1ce27817b508eb0aac1663d1de48353237`  
**Merge commit:** `afd390e8338a198d76938eef5ddcf35718ec189c`  
**Decision:** Accepted `DEC-0044`  
**Executed prompt:** `docs/codex/milestone-prompts/M04E2T2-finalized-typed-run-facts.md` v0.1

## Purpose and outcome

M04E2T2 converted the trustworthy internal facts established by M04E2T1 into one final detached public result contract. It removed the raw public segment/channel dictionaries, generic event payload dictionaries, nested engine result/event ownership, and simulation `change_summary`, while preserving the T1 candidate/journal/commit boundary.

The implemented public family is:

```text
SimulationResult
SimulationSegmentResult
SimulationChannelDeltaResult
SimulationEvent
SimulationChannelBankedEvent
SimulationThresholdSettledEvent
SimulationResultProjector
```

The pure projector consumes only detached run context and a frozen fact journal. It receives no live/candidate `GameState`, report state, clock, file, scene, platform service, or caller-authored commit authority.

## Realized contract

The four result kinds are:

```text
FAILURE
ZERO_DURATION
TIMELINE_ONLY
ACTIVE_REAPING
```

Typed segments retain complete historical Threshold, assignment revision, Form, Writ, ordered Retinue, lifecycle, timing, core, backlog-endpoint, and channel facts. Typed channel deltas retain channel/item identity, period, progress/carry endpoints, and total-banked endpoints. The closed event union contains only current channel-banked and Threshold-settled event subtypes.

Every current engine, transaction, run-service, debug, test, trace, source-audit, and persistence-exclusion consumer migrated directly. No parallel raw public grammar remains.

## Protected behavior

The implementation preserved:

- one-hour and eight-hour exact production values;
- Settlement segmentation, priority, and event ownership;
- progress-only and multiple-whole channel behavior;
- regular/irregular chunk gameplay equality;
- forecast/committed-clone typed equality;
- foreground/offline-fixture/debug equality;
- M04E2T1 failure atomicity;
- schema version 3 and content revision `prototype-content-r2`;
- non-persistence of simulation result/context/journal/projector artifacts.

It added no report state, schema version 4, ingestion, report reads, snapshot/history behavior, UI, trusted time, or concurrency.

## Review and correction record

Targeted review findings addressed malformed Settlement cardinality, selected Retinue order, active-context fact completeness, exact-boundary Settlement self-validation, spurious Settlement rejection, and owner-trace constructor correctness. Named regressions were added.

The final targeted and unrestricted current-head Codex reviews were clean. All applicable review threads were resolved.

## Final evidence

Exact-head Windows verification detected `00bd7d1ce27817b508eb0aac1663d1de48353237` and passed:

```text
Godot: 4.7.stable.official.5b4e0cb0f
full GUT before/after: 178/178 tests, 2,832 assertions
focused M04C-M04E2T2: 74/74 tests, 1,291 assertions
import: PASS
15 exact M04E2T2 trace markers: PASS
missing-root negative trace: PASS
cleanup and cleanup-absence proof: PASS
artifact audit: PASS
failed steps: 0
interactive checks: none
```

## Scope outcome

Final implementation scope was:

```text
25 non-documentation/non-UID files
1,742 additions
282 deletions
1,460 net additions
```

The net line delta exceeded the approximate 1,450 planning threshold by 10 lines while remaining below the file-count stop threshold. The owner approved a bounded exception for M04E2T2 only because the excess consisted of the approved typed family, edge-case regressions, trace evidence, owner runner, and removal/migration of the transitional grammar. No new authority, schema transition, report state, later subsystem, or gameplay formula owner entered the slice.

## Gate result

```text
GATE-FINALIZED-RUN-FACTS: Satisfied
M04E2T2 GATE-SLICE-SCOPE: Satisfied by recorded owner exception
Implementation: Merged
Verification: Passed
```

## Current action

M04E2T2 is closed. Do not re-execute its prompt or continue its implementation branch as a basis for report state.

The active next planning boundary is:

```text
M04E2A2 — Report runtime state and schema-v4 persistence
```

Use:

- `docs/codex/M04E2A2_PLANNING.md`;
- `docs/codex/milestone-prompts/M04E2A2-report-state-schema-v4-persistence.md` after explicit owner approval;
- `docs/codex/CODEX_DESKTOP_WORKFLOW.md`;
- `tools/codex/publish_milestone_pr.ps1`.
