# Implementation slice M04E2T1: Single-provenance simulation transaction journal and commit boundary

**Prompt version:** v0.1  
**Prompt date:** 2026-07-22  
**Prompt status:** Approved  
**Work item type:** Implementation slice  
**Parent conceptual epics:** M04 / M04E / M04E2  
**Milestone definition:** `docs/codex/MILESTONES.md`  
**Architecture decision:** Accepted `DEC-0043`  
**Expected base:** current `main` after the planning-only DEC-0043 package is merged  
**Planned prompt path:** `docs/codex/milestone-prompts/M04E2T1-simulation-transaction-journal.md`

> This prompt authorizes a behavior-preserving internal simulation-transaction refactor. It does not authorize the final typed public result family, report state, schema version 4, report ingestion/reads/history, UI, trusted time, concurrency, or M04E2B.

## Approval gate

Do not begin implementation until the project owner changes the prompt status to Approved and confirms:

```text
DEC-0043: Accepted
M04E2T1 definition: Approved
M04E2T1 prompt: Approved v0.1 or later
GATE-SINGLE-PROVENANCE-TRANSACTION: Satisfied
GATE-SLICE-SCOPE: Satisfied
```

Start a new Codex desktop task, branch, and PR from current `main`.

Do not continue either abandoned task or branch. Do not cherry-pick or copy PR #17 or PR #18 production implementation wholesale. Those PRs may be inspected only for accepted review findings, expected black-box behavior, and regression scenarios.

## Objective

Refactor the current supplied-duration simulation so one internal transaction owns:

- the private working candidate;
- immutable run context;
- every authoritative mutation performed during the call;
- one ordered bounded fact journal;
- final candidate validation;
- derivation of the current compatibility result;
- the one final live-state commit.

The same operation that mutates the candidate must record the corresponding explanatory fact from the same before/after values.

M04E2T1 must preserve the current public `SimulationResult`, current raw segment/channel compatibility representation, typed `SimulationEvent`, `SimulationRunService`, formulas, balance, schema version 3, content revision `prototype-content-r2`, and all verified behavior.

## Developer outcome

After this slice, a developer can:

1. resolve the current one-active-Reaping simulation through a private transaction candidate;
2. inspect a bounded internal journal whose facts were recorded by the same methods that applied the mutations;
3. receive the existing public compatibility result derived from that finalized journal;
4. prove a failure after partial candidate work leaves live state canonically unchanged;
5. prove no arbitrary caller-supplied candidate/result pair can enter the commit path;
6. run all current M04C, M04D2, M04D3, and M04E1 consumers unchanged at the public boundary;
7. save/load ordinary gameplay under schema v3 with no transaction or journal artifacts.

## Required reading

Before editing, read completely:

- `AGENTS.md`;
- accepted `DEC-0043` and relevant carried decisions named there;
- `docs/codex/M04E2_IMPLEMENTATION_POSTMORTEM.md`;
- `docs/codex/M04E2_TRANSACTION_REDESIGN_PLAN.md`;
- `docs/codex/ARCHITECTURE.md` transaction section;
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` M04E2T1 contract;
- `docs/codex/IMPLEMENTATION_RULES.md`, especially single-provenance rules;
- `docs/codex/TESTING_AND_VALIDATION.md` M04E2T1 package;
- `docs/codex/OWNER_VERIFICATION_WORKFLOW.md`;
- current M04C/M04D2/M04D3/M04E1 milestone records and tests;
- current implementations of `SimulationEngine`, `SimulationRunService`, `M04CDebugAdvance`, `ReapingRateContextService`, `GameState`, and `GameStateValidator`.

Inspect PR #17/PR #18 only when necessary to enumerate a regression scenario. Do not use their production source as a template.

## Required pre-edit report

Before non-trivial edits, report:

1. the exact current `main` SHA and clean-tree status;
2. every authoritative `GameState` field currently written by `SimulationEngine`, grouped by operation;
3. every current segment/channel/event/summary fact produced by the engine;
4. the proposed mapping from each authoritative write to one transaction mutation method and one journal fact;
5. the proposed file/class layout and why transaction code will not accumulate inside `simulation_engine.gd`;
6. the exact public result contract that will remain unchanged;
7. the current direct consumers and how they remain compatible;
8. the failure points that can occur after partial candidate work and the tests that will prove live-state preservation;
9. the candidate/journal finalization state machine;
10. the exact focused/full/import/trace verification commands;
11. projected non-documentation file count and code/test line delta;
12. confirmation that M04E2T2, report/schema-v4 work, UI, trusted time, support, tutorial, Halls, progression, analytics, and concurrency are excluded.

Stop before editing if the refactor requires another authoritative aggregate, a schema change, public result semantic changes, a third cross-layer seam, or more than the approved scope guardrails.

## Protected invariants

- `SimulationEngine` remains the sole gameplay formula and segmentation owner.
- Online, offline-fixture, debug, and forecast paths continue to use the same engine.
- Exact one-hour, eight-hour, Settlement, channel, chunking, rate-context, forecast, and persistence outcomes remain unchanged.
- `GameState` remains the sole persisted gameplay authority.
- The transaction journal is non-persisted runtime evidence, not event sourcing.
- Source state changes only through one final `copy_from` after complete success.
- Schema remains version 3; content remains `prototype-content-r2`.
- Current one-active-Reaping behavior remains unchanged.
- No report state or `ReportService` exists after this slice.
- No clock, scene, file, platform, tutorial, progression, Hall, support, analytics, or UI ownership enters simulation.

## Scope assessment

| Assessment item | Approved estimate |
|---|---|
| Primary subsystem owner | `SimulationEngine` transaction/commit boundary |
| Principal transition | validated source -> private candidate/journal -> finalized compatibility result -> one commit |
| New authoritative aggregate | None |
| Save-schema change | None |
| Public result semantic change | None |
| Cross-layer seams | 2: engine -> transaction collaborator; finalized journal -> existing result builder |
| Risk dimensions | behavior-preserving refactor, mutation completeness, atomic failure, compatibility |
| Expected non-documentation source/test files | Approximately 8–20 |
| Expected non-documentation code/test delta | Approximately 600–1,100 lines |
| `simulation_engine.gd` net growth | Normally no more than approximately 150 lines; prefer moving mutation/finalization code to focused internal scripts |
| Mandatory stop | Above 24 files, approximately 1,300 code/test lines, another owner/schema/seam, or required public-result change |

Crossing a normal target requires an explicit report before further implementation. Do not treat the maximum as permission to fill it.

## Required architecture

### TX-01 — Immutable run context

Capture one immutable run context after complete source validation and before candidate mutation.

For the current one-active-Reaping engine, include as applicable:

```text
baseline_simulation_time_msec
requested_elapsed_msec
has_active_reaping
threshold_id
assignment_revision
form_id
writ_id
ordered_retinue_ids
initial_lifecycle_state
content revision / validated registry context
```

The context must not alias mutable Reaping arrays and must not be reconstructed from current state after the run.

### TX-02 — Private candidate ownership

The transaction creates exactly one deep-cloned candidate from the validated source.

- Do not accept a caller-supplied candidate.
- Do not expose the candidate for arbitrary mutation.
- Do not add a public/test-facing `commit_if_valid(live, candidate, result)` equivalent.
- Tests exercise the transaction through the engine or narrow read-only test seams, not arbitrary commit injection.

### TX-03 — Complete mutation inventory

Map every current authoritative write to a declared transaction operation.

At minimum inspect and account for:

```text
simulation cursor
Threshold persistent returns
Threshold remaining backlog
Threshold lifecycle
Essence inventory total
whole channel-output inventory totals
Form Mastery
Reaping core progress and flow carries
Reaping cycle phase and completed cycles
Threshold acquisition progress
Threshold acquisition carry
Threshold acquisition total banked history
```

Also inventory any additional field the current merged engine mutates. An unaccounted authoritative write blocks implementation completion.

### TX-04 — Checked mutation operations

The transaction provides narrow operations equivalent to:

```text
advance_timeline
apply_core_segment
apply_channel_segment
apply_settlement_transition
```

Exact names and grouping may change after inspection, but each operation must:

1. receive validated calculation inputs;
2. check overflow/ranges before mutation;
3. capture required before values;
4. update all related candidate fields;
5. append the corresponding journal fact from those same before/after values;
6. leave both candidate and journal unchanged on failure.

Do not move gameplay formulas into a second owner. Pure calculation helpers may remain in `SimulationEngine` or existing rate services.

### TX-05 — Bounded fact journal

The journal is ordered and bounded to the current elapsed call.

It records enough internal facts to derive the exact current compatibility result, including:

- timeline advance;
- lifecycle segment start/end/duration/context;
- core deltas;
- channel before/after endpoints;
- whole banking and inventory quantity;
- Settlement boundary values;
- current supported events.

The journal may record residual/cycle endpoints internally when needed for provenance even when the current public result does not expose them.

It must not be serialized, replayed, or retained as analytics/history.

### TX-06 — Boundary-time facts

Capture a boundary fact when the boundary is applied.

For Settlement, the event/fact uses the persistent-return total and other endpoint values at the exact Settlement boundary. A later Settled segment must not rewrite that payload to the final run total.

### TX-07 — Journal-derived compatibility output

Preserve the exact current public `SimulationResult` contract.

Generate from the finalized journal:

- current segment compatibility dictionaries;
- current channel-delta compatibility dictionaries;
- typed `SimulationEvent` instances;
- current `change_summary`.

Do not independently author `change_summary` by diffing candidate state in a separate path. Do not retain another parallel fact source.

### TX-08 — Candidate validation and finalization

Finalization is one-way and rejects repeated mutation/finalization.

Required order:

```text
complete all transaction operations
-> validate complete candidate GameState
-> validate journal structural order/bounds
-> freeze journal
-> build compatibility result from journal
-> expose finalized candidate/result to engine
-> one live copy_from
```

A failure at any stage returns a stable failure result and leaves live state unchanged.

### TX-09 — No arbitrary events

Events are created only from successful journal operations for current supported engine behavior.

No caller appends an arbitrary event into the transaction. Preserve current event ordering and flags exactly.

### TX-10 — Timeline-only behavior

A positive no-active-Reaping call uses the transaction boundary, advances only the simulation cursor, records one timeline fact, derives the current timeline-only result, validates, and commits once.

### TX-11 — Failure after partial candidate work

Add behavioral tests that cause failure after at least one candidate operation has succeeded, such as a later checked channel/inventory overflow or other legitimate current-engine failure boundary.

Prove canonical live-state equality before and after failure. Do not satisfy this solely by calling a fabricated internal commit method.

### TX-12 — Forecast and mode behavior

Forecast still deep-clones the caller baseline through `SimulationRunService` and runs the same engine. The engine's own transaction still owns its internal candidate relative to the supplied forecast clone.

Foreground, offline-fixture, debug, and forecast behavior remains mathematically equivalent for equal inputs.

### TX-13 — Persistence exclusion

Production snapshots and JSON remain schema v3 and contain no:

```text
SimulationRunContext
SimulationTransaction
SimulationFactJournal
transaction finalization record
compatibility result object
forecast projection
report fields
```

Frozen fixture bytes remain unchanged.

### TX-14 — No abandoned implementation reuse

State in the final response whether PR #17 or PR #18 was inspected and confirm no production commit/file was cherry-picked or copied wholesale.

## Required tests

Add focused tests under `tests/unit/m04e2t1/` and `tests/integration/m04e2t1/` as needed.

At minimum include named tests for:

### Context and ownership

- active context captures exact Threshold/revision/Form/Writ/Retinues/lifecycle/cursor;
- no-active context is explicit and contains no fabricated operation identity;
- context arrays are detached;
- transaction candidate is a deep clone and source remains unchanged before final commit;
- no arbitrary candidate/result commit seam exists.

### Mutation provenance

- timeline mutation and fact share one operation;
- returned Souls/backlog mutation and segment fact agree by construction;
- Essence mutation and segment fact agree by construction;
- Mastery, flow carries, cycle phase, and completed-cycle mutation are transaction-owned;
- channel progress/carry/history/inventory and channel fact share one operation;
- progress-only channel fact;
- multiple-whole channel banking fact;
- Settlement transition and boundary event share one operation;
- Settlement event stores boundary total, not final-run total.

### Finalization

- journal cannot mutate after finalization;
- transaction cannot finalize twice;
- candidate validation precedes live commit;
- compatibility segments/channels/events/summary derive from the same journal;
- nested compatibility data is detached as currently required;
- timeline-only compatibility shape remains exact.

### Atomic failure

- failure after partial core work before later channel completion preserves live state;
- checked inventory/channel overflow preserves live state;
- candidate validation failure preserves live state;
- result-projection/finalization failure, if any supported failure path exists, preserves live state;
- every failure preserves simulation, inventory, Forms, Thresholds, acquisitions, Reapings, progression, and reservations.

### Existing behavior

- exact one-hour values;
- exact eight-hour values;
- exact Settlement timing and same-time order;
- progress-only and multiple-whole channel behavior;
- regular and irregular chunk equality;
- rate-context change boundary equality;
- forecast versus committed clone equality;
- foreground/offline-fixture/debug equality;
- current M04C/M04D2/M04D3/M04E1 tests and traces remain green.

### Persistence and scope

- production save/load remains schema v3 and canonically equal;
- no transaction/journal/result artifacts serialize;
- no report/schema-v4/later-slice ownership;
- source audit confirms authoritative writes occur only through the transaction boundary after the refactor.

Source-text audits supplement behavior and do not replace it.

## Developer trace

Create:

```text
tools/test/m04e2t1/m04e2t1_transaction_trace.gd
```

It requires and uses an isolated `--work-root`, fails when the root is absent, performs real assertions, and emits exactly:

```text
TRACE M04E2T1 private_candidate_single_commit=PASS
TRACE M04E2T1 run_context_captured_once=PASS
TRACE M04E2T1 core_mutation_fact_shared_provenance=PASS
TRACE M04E2T1 channel_mutation_fact_shared_provenance=PASS
TRACE M04E2T1 settlement_boundary_fact_shared_provenance=PASS
TRACE M04E2T1 timeline_only_transaction=PASS
TRACE M04E2T1 partial_candidate_failure_preserves_live=PASS
TRACE M04E2T1 compatibility_summary_derived_from_journal=PASS
TRACE M04E2T1 events_derived_from_journal=PASS
TRACE M04E2T1 one_hour_eight_hour_settlement_unchanged=PASS
TRACE M04E2T1 forecast_commit_chunk_mode_equivalence=PASS
TRACE M04E2T1 schema_v3_no_later_slice_artifacts=PASS
```

No marker may be emitted from unconditional success or string search alone.

## Owner verification package

Create:

```text
tools/test/owner/run_m04e2t1_owner_verification.ps1
```

Follow the mature Windows pattern and require execution-policy bypass in documented commands.

Sequence:

1. environment, requested SHA, Git availability, resolved Godot;
2. full GUT before;
3. focused M04C/M04D2/M04D3/M04E1/M04E2T1 unit and integration directories;
4. explicit import;
5. real isolated-root M04E2T1 trace;
6. exact 12-marker verification;
7. missing-root trace must fail;
8. cleanup in `finally`;
9. cleanup absence proof;
10. artifact audit;
11. full GUT after;
12. UTF-8 log and zero-failure summary.

Do not run or claim the Windows package from Codex unless the owner explicitly asks and the exact reviewed head is checked out on the Windows machine.

## Verification before PR handoff

Run from repository root:

```sh
./tools/test/run_gut.sh -- \
  -gdir=res://tests/unit/m04c \
  -gdir=res://tests/unit/m04d2 \
  -gdir=res://tests/unit/m04d3 \
  -gdir=res://tests/unit/m04e1 \
  -gdir=res://tests/unit/m04e2t1 \
  -gdir=res://tests/integration/m04e1 \
  -gdir=res://tests/integration/m04e2t1

./tools/test/run_gut.sh

godot --headless --path . --import

trace_root="$(mktemp -d)"
godot --headless --path . \
  -s res://tools/test/m04e2t1/m04e2t1_transaction_trace.gd \
  -- --work-root "$trace_root"
trace_exit=$?
rm -rf "$trace_root"
test ! -e "$trace_root"
test "$trace_exit" -eq 0

godot --headless --path . \
  -s res://tools/test/m04e2t1/m04e2t1_transaction_trace.gd
test "$?" -ne 0

git diff --check
git status --short
```

Also run the current M04C, M04D2, M04D3, and M04E1 behavioral traces that the refactor touches. Report exact commands and markers.

The complete repository suite must be green before review.

## Documentation updates

Update only documents made inaccurate by the realized implementation:

- `docs/codex/ARCHITECTURE.md`;
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`;
- `docs/codex/IMPLEMENTATION_RULES.md` only if a durable rule changes;
- `docs/codex/TESTING_AND_VALIDATION.md`;
- `docs/codex/MILESTONES.md` status and evidence;
- historical M04C/M04D2/M04D3/M04E1 wording only where it falsely states the mutation/result construction path.

Keep while the PR is open:

```text
Implementation: Pull request open
Verification: Partial
```

Do not draft M04E2T2 in this implementation task.

## Stop and ask conditions

Stop before broadening when:

- a public result field or behavior must change;
- a save-schema or content-revision change is required;
- another authoritative aggregate or primary owner is required;
- a third cross-layer seam is introduced;
- the engine cannot delegate transaction/journal behavior without becoming materially larger;
- projected or actual scope exceeds 24 non-documentation source/test files or approximately 1,300 code/test lines;
- another generic framework is proposed;
- requirements conflict with merged M04 behavior.

During review, stop and return to planning when more than two targeted rounds produce new P1/P2 findings or more than six material findings are discovered.

## Acceptance criteria

M04E2T1 is complete only when:

1. one immutable run context is captured before mutation;
2. one private transaction candidate is created from the validated source;
3. no arbitrary candidate/result commit seam exists;
4. every current authoritative simulation write is assigned to one transaction operation;
5. mutation and fact recording are atomic per operation;
6. the journal is ordered, bounded, detached, and non-persisted;
7. boundary facts retain boundary values;
8. current compatibility segments/channel deltas/events/summary derive only from the finalized journal;
9. the journal and candidate cannot mutate after finalization;
10. complete candidate validation precedes the live commit;
11. source state changes through one final copy only;
12. failure after partial candidate work preserves exact source state;
13. exact one-hour, eight-hour, Settlement, channel, chunk, mode, rate-context, and forecast behavior remains unchanged;
14. all current upstream tests and traces remain green;
15. schema remains v3 and content remains r2;
16. no transaction/journal/result artifact serializes;
17. no final typed public result, report state, schema v4, report service, UI, trusted time, tutorial, Hall, support, analytics, or concurrency enters the diff;
18. no PR #17 or PR #18 production implementation is cherry-picked or copied wholesale;
19. focused and full suites pass;
20. import, real trace, missing-root failure, cleanup, and artifact checks pass;
21. actual scope remains inside the approved guardrails;
22. targeted and final GitHub reviews are clean;
23. owner Windows verification passes against the exact final reviewed head before merge.

## Final response format

Report:

### Implementation completed

The final transaction/context/journal ownership and commit order.

### Mutation ownership matrix

Every authoritative field, its transaction operation, and its journal fact.

### Files changed

Every file and purpose.

### Regression tests

Map each acceptance group and failure-provenance case to named tests.

### Verification

Every command, exact test/assertion counts, trace markers, negative trace, cleanup, and exit status.

### Scope

Final non-documentation file/line counts and `simulation_engine.gd` net change.

### Abandoned-branch reuse statement

Whether PR #17/PR #18 were inspected and confirmation that no production implementation was copied/cherry-picked wholesale.

### Assumptions and risks

Only unresolved or environment-dependent points.

### Deferred work

M04E2T2, M04E2A2, M04E2A3, M04E2A4, M04E2B, and all later systems.

### Updated PR head

Exact SHA.
