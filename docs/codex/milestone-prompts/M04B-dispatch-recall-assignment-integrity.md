# Implementation slice M04B: Dispatch, recall, and assignment integrity

**Prompt version:** v0.1  
**Prompt date:** 2026-07-16  
**Prompt status:** Draft  
**Work item type:** Implementation slice  
**Parent conceptual epic:** `M04 — Persistent Reaping simulation vertical slice`  
**Milestone definition:** `docs/codex/MILESTONES.md` — `### M04B — Dispatch, recall, and assignment integrity`  
**Recommended task size:** Small-medium; one command/assignment pull request  
**Scope-gate result:** Within guardrails at draft; mandatory stop if actual work needs another primary owner, more than two cross-layer seams, more than approximately 30 non-documentation source/test files, or more than approximately 1,200 non-documentation code/test lines  
**Expected base branch or ref:** current `main` after M04A merge commit `673ad884357fc742a0a26dbb542d5b8d9fe557c9`  
**Planned prompt path:** `docs/codex/milestone-prompts/M04B-dispatch-recall-assignment-integrity.md`

> This prompt authorizes only M04B's scene-independent Reaping assignment commands and their schema-v2 persistence proof. It does not authorize elapsed production, active in-place rate-context reconfiguration, Retinue assignment, tutorial behavior, player-facing UI, or any later implementation slice.

## Approval dependency

This draft includes proposed `DEC-0035`. Approval of this prompt also accepts that decision unless the owner requests revised assignment semantics first.

Do not execute this prompt while `DEC-0035` remains Proposed.

## Execution protocol

Before editing:

1. Read `AGENTS.md` completely.
2. Read every document and section listed under **Authoritative context**.
3. Inspect the current merged M04A implementation, tests, fixtures, owner runner, and `git status --short`.
4. Verify that PR #8 is merged and M04A is recorded Merged/Passed.
5. Verify that schema version 2 is current, schema version 1 remains supported, and no M04B schema change is required.
6. Verify that `GameState.ReapingState` already contains `is_active`, Form/Writ IDs, revision, phase/carries, and timestamps.
7. Verify that the M03 registry exposes enabled Form, Threshold, and Writ records used by the fixture.
8. State the proposed command/service structure, candidate-validation/commit method, event/result types, exact error-code table, expected files, and verification plan before non-trivial edits.
9. Re-evaluate the scope assessment. Stop before implementation if the work requires elapsed production, Retinue behavior, a schema bump, another primary owner, or material review-surface growth.

During implementation:

- Limit changes to M04B and its binary criteria.
- Use one focused assignment service or equivalent owner; do not create a general command bus, DI framework, or full `GameSession`.
- Validate all command preconditions before mutating the supplied `GameState`.
- Build and validate a candidate record/state, then commit one Reaping-map insertion or replacement only after success.
- Keep expected player rejections as typed results rather than `push_error()` control flow.
- Use the current committed `GameState.simulation_time_msec`; read no clock and advance no production.
- Keep occupied tether count derived from active Reapings.
- Preserve Threshold-owned acquisition/discovery state and all state outside the assignment record.
- Do not reinterpret nonzero rate-dependent phase/carry under a changed Form or Writ.
- Do not call `SaveService` inside the domain assignment service. Return `save_checkpoint_requested = true`.
- Add junior-readable comments explaining record identity, revision guards, candidate validation, tether derivation, and the M04C/M04D handoff.
- Add or update every test needed to prove the contract.
- Create the M04B trace and Windows owner package.
- Report exact commands, counts, markers, exit codes, and actual-versus-estimated scope.
- Leave owner Windows verification pending until the owner supplies a generated log for the tested PR head.
- Do not draft M04C.

Do not describe M04B as complete while any merge-gate criterion is failed, blocked, or pending.

## Objective

Implement typed initial-dispatch, recall, and inactive-record redispatch commands for the existing schema-v2 `GameState`. Commands must preserve one stable Reaping record per Threshold, derive tether occupancy from active records, guard mutations by assignment revision, enforce valid Form/Threshold/Writ/capacity relationships, preserve frozen progress, and round-trip exactly without advancing elapsed production.

## Player or developer outcome

From focused tests and one headless trace, a developer can:

- construct an available Gloamwood and awakened Man-at-Arms at a known simulation cursor;
- dispatch Man-at-Arms with Standard Writ;
- observe revision 1 and one derived occupied tether;
- prove duplicate and stale commands change nothing;
- save and reload the active assignment;
- recall it into the same inactive record at revision 2;
- prove the tether is free while Threshold and operation progress remain intact;
- save and reload the inactive record;
- redispatch it at revision 3;
- prove the original start time persists, the configuration timestamp is current, and simulation time/output did not advance;
- execute the complete Windows proof through one PowerShell command and shareable UTF-8 log.

## Authoritative context

| Priority | Source | Required sections, labels, or records | Why it applies |
|---:|---|---|---|
| 1 | `AGENTS.md` | Full file, especially domain ownership, comments, tests, save/time, and scope rules | Repository operating contract |
| 2 | `docs/codex/MILESTONES.md` | §§3–7; `GATE-SLICE-SCOPE`; `GATE-REAPING-ASSIGNMENT`; `### M04B` | Approved slice and merge gates |
| 3 | `docs/codex/MILESTONE_RECALIBRATION_PROPOSAL.md` | §§2–8 | Review-surface policy |
| 4 | `docs/codex/PROMPT_TEMPLATE.md` | §§2.1–2.4; scope assessment; completion rules | Prompt ownership and split gate |
| 5 | `docs/codex/OWNER_VERIFICATION_WORKFLOW.md` | Complete script/log/cleanup/evidence rules | Required Windows package |
| 6 | `docs/codex/DECISIONS.md` | `DEC-0007`, `DEC-0012`, `DEC-0018`–`DEC-0020`, `DEC-0023`, `DEC-0025`, `DEC-0027`, `DEC-0028`, `DEC-0033`, `DEC-0034`, proposed `DEC-0035` | State, commands, capacity, progress, scope |
| 7 | `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | §§2–3, 9.3–9.9, 10–12; M04A schema contract; proposed M04B assignment contract | Exact state/result/event/command rules |
| 8 | `docs/codex/ARCHITECTURE.md` | §§5–8, 9.1, 11.2–11.3, 20; M04A realized state; proposed M04B command boundary | Ownership and transaction flow |
| 9 | `docs/codex/IMPLEMENTATION_RULES.md` | State classes, commands/services, deterministic collections, diagnostics, persistence, junior-readable comments | Engineering conventions |
| 10 | `docs/codex/TESTING_AND_VALIDATION.md` | §§3–6, 7.5, 9.1, 12, 15–22 | Commands, save round trips, owner evidence |
| 11 | `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md` | `IF-REQ-01`, `IF-REQ-12`, `IF-REQ-15`, `IF-REQ-18`; persistent assignment model | Persistent, recoverable assignments |
| 12 | `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md` | `P90-SAFE-09`; `P90-B04`; `P90-B08` assignment/save safeguards | First dispatch and later reassignment context |
| 13 | M04A implementation | `src/domain/game_state.gd`, validator, schema-v2 mapper/coordinator, fixtures, tests, trace, owner runner | Actual baseline |

This prompt is authoritative only within M04B. Stop and report unresolved source conflicts.

## Repository state

Expected baseline:

| Item | Expected state | Evidence |
|---|---|---|
| Completed slices | M04A Merged/Passed | `MILESTONES.md`; PR #8 merge |
| Runtime aggregate | Typed inventory, Forms, Thresholds/acquisition, Reapings, progression | `src/domain/game_state.gd` |
| Reaping fields | `threshold_id`, `is_active`, Form/Writ, Retinues, revision, phase/count/carries, start/config timestamps | `GameState.ReapingState` |
| State validation | Content-aware structural validation and derived active-count capacity check | `game_state_validator.gd` |
| Persistence | Current schema v2 with active/inactive Reaping round-trip support; v1 migration retained | `src/persistence/` |
| Content | Exact M03 catalog; `FORM_MAN_AT_ARMS`, `THR_GLOAMWOOD`, `WRIT_STANDARD`, `WRIT_EMERGENCY_FIRST_RETURN` | `content/`, `ContentRegistry` |
| Commands | No dispatch/recall/redispatch service or typed assignment result/events | Repository inspection |
| Simulation | No M04C resolver; no elapsed production | Repository inspection |
| UI | No gameplay assignment screen | Repository inspection |
| Working tree | Clean except task changes | `git status --short` |

If the repository materially differs, report it before dependent work.

## Dependencies

| Dependency or gate | Required state | Required before | Verification |
|---|---|---|---|
| M04A | Merged and Passed | Implementation | Merge record and full regression |
| `GATE-REAPING-ASSIGNMENT` | `DEC-0035` Accepted or revised owner-approved contract | Implementation | Decision record |
| `GATE-SLICE-SCOPE` | Assessment remains within guardrails | PR and merge | This prompt and handoff |
| M03 content | Registry ready; representative definitions enabled | Implementation | Content tests |
| Schema v2 | Current; no M04B bump | Merge | Save tests and diff review |
| Owner Windows environment | Godot 4.7 console executable discoverable | Merge | Generated M04B log |

## Scope and review-surface assessment

| Assessment item | Approved estimate or result |
|---|---|
| Parent conceptual epic | M04 |
| Primary subsystem owner | Reaping assignment command service |
| Principal behavior/state transition | Initial dispatch → recall → redispatch of one stable Reaping record |
| New authoritative state ownership | None; use M04A fields |
| Save-schema or migration change | None |
| Deterministic algorithm/boundary work | Revision/capacity/candidate validation only; no elapsed resolution |
| New player-facing UI flow | None |
| Native/platform integration | None |
| Bulk authored content | None |
| Live/offline/forecast equivalence | None |
| Exactly-once/transactional progression | Atomic command commit and revision/event duplication prevention |
| Independently testable domain services | One service plus small typed command/result/event records |
| Cross-layer integration seams | Two: assignment service ↔ content/state validation; committed state ↔ existing persistence coordinator in integration tests |
| Estimated non-documentation source/test files | Approximately 12–22, excluding generated `.uid` files |
| Estimated non-documentation code/test line delta | Approximately 600–1,100, excluding `.uid` and documentation |
| Owner verification package | `tools/test/owner/run_m04b_owner_verification.ps1`; automated log only |
| Mandatory split trigger crossed? | No at draft estimate |
| Exception rationale/approval evidence | Not applicable |

Stop and request replanning before exceeding approximately 30 non-documentation source/test files, 1,200 code/test lines, two seams, or one primary owner.

## Scope

Implement only:

1. one focused Reaping assignment service or equivalent owner;
2. explicit initial dispatch, recall, and inactive-record redispatch;
3. typed command inputs or typed command DTOs;
4. typed action results and ordered assignment events;
5. exact expected-revision and checked-overflow behavior;
6. derived occupied tether count;
7. one-active-Reaping-per-Threshold and one-active-Reaping-per-Form validation;
8. preservation of stable Reaping/Threshold state;
9. safe rejection of changed configuration with unresolved rate-dependent phase/carry;
10. schema-v2 active/inactive round trips using the existing mapper/coordinator;
11. focused tests, deterministic real-file trace, Windows owner script/log, and required documentation updates.

Use the smallest architecture satisfying the contract. Do not build a general command framework.

## Non-goals

Do not implement or refactor:

1. elapsed simulation or command-time advancement;
2. backlog, Essence, Mastery, discovery, channel, cycle, or support production;
3. active in-place Form/Writ reconfiguration after elapsed time;
4. Retinue assignment, reservations, compatibility, or support;
5. Writ milestone transitions;
6. second tether grants, Broken Watch progression, or concurrent production;
7. new-game/story/tutorial bootstrap or first-dispatch UI;
8. reports, forecasts, read models, application shell, scenes, or player-facing presentation;
9. Steam, trusted-time, offline reconciliation, Hall, or Recollection behavior;
10. save-schema version 3, migration changes, speculative fields, or another codec;
11. dependencies, autoloads, broad cleanup, or unrelated moves.

## Required behavior

| ID | Required behavior | Source trace |
|---|---|---|
| `RB-01` | One service owns M04B assignment mutations. | `DEC-0012`; proposed `DEC-0035` |
| `RB-02` | Commands operate on typed scene-independent `GameState` and validated `ContentRegistry`. | `DEC-0007`, `DEC-0009` |
| `RB-03` | Commands read the existing simulation cursor and do not advance it or read a clock. | Architecture §9.1; M04B non-goal |
| `RB-04` | Initial dispatch requires no Reaping record at the Threshold. | Proposed `DEC-0035` |
| `RB-05` | Initial dispatch validates state/registry, available Threshold, awakened Form, enabled Writ, Form exclusivity, and tether capacity before mutation. | `DEC-0012`, `DEC-0020` |
| `RB-06` | Initial dispatch creates an active record at revision 1 with start/config timestamps equal to the current simulation cursor and canonical empty operation fields. | Proposed `DEC-0035` |
| `RB-07` | Occupied tether count is derived from active records and is never persisted independently. | `DEC-0020`; data contract |
| `RB-08` | A Form may lead at most one active Reaping. | Proposed `DEC-0035`; `P90-SAFE-09` |
| `RB-09` | Recall requires an existing active record and exact expected revision. | Proposed `DEC-0035` |
| `RB-10` | Recall sets inactive, increments once, updates the configuration timestamp, and leaves the stable record in the map. | Proposed `DEC-0035` |
| `RB-11` | Recall preserves Form/Writ IDs, original start time, Retinue list, cycle phase, completed count, flow carries, Threshold discovery/acquisition, inventory, and progression capacity. | `IF-REQ-01`, `IF-REQ-18` |
| `RB-12` | Redispatch requires an existing inactive record and exact expected revision. | Proposed `DEC-0035` |
| `RB-13` | Redispatch revalidates Form, Writ, Threshold, exclusivity, and capacity. | `DEC-0012`, `DEC-0020` |
| `RB-14` | Redispatch increments once, reactivates the same record, preserves original start time, and updates the configuration timestamp. | Proposed `DEC-0035` |
| `RB-15` | Same-configuration redispatch preserves frozen phase/carry. | Proposed `DEC-0035` |
| `RB-16` | Changed Form/Writ with nonzero rate-dependent phase/carry returns `REAPING_RESOLUTION_REQUIRED` without mutation. | `DEC-0028`; M04C/M04D handoff |
| `RB-17` | Changed Form/Writ with canonical zero rate-dependent phase/carry may commit after all ordinary validation. | Proposed `DEC-0035` |
| `RB-18` | Duplicate dispatch, repeated recall/redispatch, stale revision, no-op, and overflow cases leave state unchanged. | `DEC-0012`; proposed `DEC-0035` |
| `RB-19` | Assignment revision uses checked signed-64-bit increment behavior. | `DEC-0026` |
| `RB-20` | Baseline state is validated before command handling; malformed runtime objects return typed rejection rather than property-access crashes. | M04A validator contract |
| `RB-21` | Candidate state/record is validated before one final map insertion/replacement commits. | `DEC-0012` |
| `RB-22` | Success returns a typed result with empty error, change summary, one ordered event, and save-checkpoint request. | Data contract §§10–11 |
| `RB-23` | Failure returns a stable error code, diagnostic text, no event, no checkpoint request, and no mutation. | Data contract §11 |
| `RB-24` | Events use the current simulation cursor and stable types `REAPING_DISPATCHED`, `REAPING_RECALLED`, or `REAPING_REDISPATCHED`. | Domain event contract |
| `RB-25` | The assignment service performs no file I/O. | Persistence boundary |
| `RB-26` | Active and inactive records round-trip exactly through schema v2. | `DEC-0034` |
| `RB-27` | No schema key, version, migration, codec, or content revision changes. | M04B definition |
| `RB-28` | No production field changes merely because a command commits. | M04B definition |
| `RB-29` | Canonical IDs, runtime map keys, event payloads, and serialized data remain deterministic. | `DEC-0009`, `DEC-0011` |
| `RB-30` | The trace and owner runner use supplied isolated paths and leave no artifact. | `DEC-0025` |
| `RB-31` | The owner runner uses the corrected in-process PowerShell wrapper and stable trace-output capture pattern. | M04A completion |
| `RB-32` | Actual scope is reported against the approved estimate. | `DEC-0033` |

## State transitions

| ID | Initial state | Trigger | Required result | Failure behavior | Persistence/event effect |
|---|---|---|---|---|---|
| `ST-01` | No Reaping at available Gloamwood; awakened Man-at-Arms; capacity 1 | Dispatch Standard at cursor `T` | Active record, revision 1, start/config `T`, one tether derived | Reject fully if any precondition fails | `REAPING_DISPATCHED`; checkpoint requested |
| `ST-02` | Active revision 1 | Repeat initial dispatch | No change | `REAPING_RECORD_EXISTS` | No event/checkpoint |
| `ST-03` | Active revision `N` | Recall expected `N` | Inactive revision `N+1`; one tether freed; state preserved | Overflow/invalid state rejects | `REAPING_RECALLED`; checkpoint requested |
| `ST-04` | Inactive revision `N+1` | Repeat recall expected old `N` | No change | stale revision | No event/checkpoint |
| `ST-05` | Inactive revision `N` | Redispatch same Form/Writ expected `N` | Active revision `N+1`; frozen operation state preserved | capacity/exclusivity/stale rejects | `REAPING_REDISPATCHED`; checkpoint requested |
| `ST-06` | Inactive, zero rate-dependent phase/carry | Redispatch changed valid Form/Writ | Active changed config, one revision increment | ordinary validation rejects atomically | Redispatch event/checkpoint |
| `ST-07` | Inactive, nonzero rate-dependent phase/carry | Redispatch changed Form/Writ | No change | `REAPING_RESOLUTION_REQUIRED` | No event/checkpoint |
| `ST-08` | Another active Reaping already uses requested Form | Dispatch/redispatch | No change | Form-already-assigned | No event/checkpoint |
| `ST-09` | Capacity already full | Dispatch/redispatch | No change | capacity exceeded | No event/checkpoint |
| `ST-10` | Active or inactive valid state | Save/load | Exact assignment reconstruction | invalid snapshot rejected | No duplicate event/revision |
| `ST-11` | Any valid assignment state | Command success/failure | `simulation_time_msec` unchanged | Any change is failure | Event time equals existing cursor |
| `ST-12` | Assignment revision at `INT64_MAX` | Recall/redispatch | No change | overflow code | No event/checkpoint |

## Command, result, and error contract

Implement explicit typed commands or equivalent strongly typed inputs. Do not use unvalidated free-form dictionaries.

Required stable error categories:

```text
REAPING_STATE_INVALID
REAPING_THRESHOLD_NOT_FOUND
REAPING_THRESHOLD_UNAVAILABLE
REAPING_FORM_NOT_FOUND
REAPING_FORM_NOT_AWAKENED
REAPING_FORM_ALREADY_ASSIGNED
REAPING_WRIT_NOT_FOUND
REAPING_RECORD_EXISTS
REAPING_RECORD_NOT_FOUND
REAPING_ALREADY_ACTIVE
REAPING_ALREADY_INACTIVE
REAPING_TETHER_CAPACITY_EXCEEDED
REAPING_STALE_ASSIGNMENT_REVISION
REAPING_ASSIGNMENT_REVISION_OVERFLOW
REAPING_RESOLUTION_REQUIRED
```

Codex may refine exact constant spelling only before implementation and must update all docs/tests consistently. It may not collapse expected failures into one generic code.

Success result minimum:

```text
success
error_code
player_message or localization-ready fallback
developer_details
change_summary
events
save_checkpoint_requested
```

`change_summary` includes Threshold, Form, Writ, active state, assignment revision, and derived occupied tether count.

## Data and content

| ID or setting | Type | Required use | Status |
|---|---|---|---|
| `THR_GLOAMWOOD` | Threshold | Available representative destination | Existing |
| `FORM_MAN_AT_ARMS` | Form | Awakened representative leader | Existing |
| `FORM_SCRIBE` | Form | Optional exclusivity/change fixture | Existing |
| `WRIT_STANDARD` | Writ | Main trace Writ | Existing |
| `WRIT_EMERGENCY_FIRST_RETURN` | Writ | Valid content/reference test only; no transition behavior | Existing |
| Schema version 2 | Save schema | Exact existing assignment persistence | Existing |
| `REAPING_DISPATCHED` | Event type | Initial dispatch fact | New M04B internal contract |
| `REAPING_RECALLED` | Event type | Recall fact | New M04B internal contract |
| `REAPING_REDISPATCHED` | Event type | Redispatch fact | New M04B internal contract |

No content `.tres` change is expected.

## UI and presentation

Not applicable — M04B has no gameplay screen. The trace and command results are developer-facing. M08/M12 later present player dispatch and reassignment.

## Architecture constraints

- One primary owner: Reaping assignment service.
- No gameplay autoload or `GameSession`.
- No clock or simulation read beyond `GameState.simulation_time_msec`.
- No file I/O in the domain service.
- No persisted tether occupancy.
- No deletion of recalled records.
- No active in-place nonzero-rate reconfiguration.
- No Retinue mutation.
- No direct content-Resource mutation.
- No schema bump.
- Expected invalid actions are typed results.
- Candidate validation precedes one final mutation.
- Sorted IDs and deterministic event ordering.

## Expected files

This is an informed expectation, not permission to edit all paths.

| Path or area | Expected action | Purpose |
|---|---|---|
| `src/domain/reaping_assignment_service.gd` or equivalent | Add | Sole command owner |
| `src/domain/action_result.gd`, event/command records, or equivalent bounded types | Add | Typed results/events/inputs |
| `src/domain/game_state_validator.gd` | Modify | Form exclusivity and M04B assignment invariants |
| `src/domain/game_state.gd` | Modify only if a narrow helper is needed | Derived active/tether helpers; no new persisted family |
| `tests/unit/m04b/` | Add | Command and negative matrix |
| `tests/integration/m04b/` | Add | Schema-v2 active/inactive round trips |
| `tools/test/m04b/m04b_assignment_trace.gd` | Add | Deterministic assignment/save demonstration |
| `tools/test/owner/run_m04b_owner_verification.ps1` | Add | One-command Windows evidence |
| Maintained docs | Modify as required | Realized contract/status/commands |

Do not add content Resources, UI scenes, empty directories, or a new schema fixture solely for M04B.

## Acceptance criteria

| ID | Pass condition | Evidence | Merge gate? |
|---|---|---|---:|
| `AC-01` | One focused service owns initial dispatch, recall, and redispatch. | Code review and unit tests | Yes |
| `AC-02` | Valid dispatch creates revision 1 at the current simulation cursor and one derived tether. | Focused test and trace | Yes |
| `AC-03` | Form, Threshold, Writ, availability, awakening, exclusivity, and capacity are fully validated before mutation. | Negative matrix | Yes |
| `AC-04` | Recall retains the stable inactive record and preserves all non-owned state. | Mutation comparison | Yes |
| `AC-05` | Redispatch reactivates the same record, increments once, and preserves original start time. | Focused test and trace | Yes |
| `AC-06` | Exact expected revisions reject stale/replayed commands without mutation. | Revision matrix | Yes |
| `AC-07` | Revision overflow rejects without mutation. | Boundary test | Yes |
| `AC-08` | One Form cannot lead two active Reapings. | Multi-Threshold fixture test | Yes |
| `AC-09` | Occupied tether count is derived and never serialized separately. | State/schema review and tests | Yes |
| `AC-10` | Same-config redispatch preserves frozen phase/carry; changed config with nonzero rate state requires later resolution. | Focused tests | Yes |
| `AC-11` | Every failed command leaves exact state equality and returns no event/checkpoint. | Failure matrix | Yes |
| `AC-12` | Success returns typed summary/event/checkpoint data with deterministic ordering. | Result/event tests | Yes |
| `AC-13` | Assignment commands do not change simulation time or production values. | Before/after assertions | Yes |
| `AC-14` | Active and inactive assignments round-trip exactly through existing schema v2. | Integration tests | Yes |
| `AC-15` | M04B adds no schema version, migration, codec, or content revision change. | Diff/schema review | Yes |
| `AC-16` | Trace proves dispatch, duplicate/stale rejection, active round trip, recall preservation, inactive round trip, redispatch, and zero production. | Trace markers, exit 0 | Yes |
| `AC-17` | Linux focused/import/trace/full checks pass. | Exact commands/exits | Yes |
| `AC-18` | Windows owner package passes full/focused/import/trace/cleanup/audit/full and writes one complete log. | Owner log | Yes |
| `AC-19` | No M04C production, M04D accumulation, Retinue, UI, tutorial, Steam, or dependency work enters the diff. | Changed-file review | Yes |
| `AC-20` | Non-trivial GDScript follows junior-reader comment rules. | Code review | Yes |
| `AC-21` | Maintained documents made inaccurate are synchronized. | Documentation/link review | Yes |
| `AC-22` | Actual scope remains within the approved assessment or work stopped for a revised prompt. | Actual-versus-estimated handoff | Yes |

A pending owner result keeps M04B verification Partial and prevents merge.

## Automated verification

### Codex Cloud or Linux

Run in this order:

```bash
git status --short

./tools/test/run_gut.sh -- \
  -gdir=res://tests/unit/m04b \
  -gdir=res://tests/integration/m04b

godot --headless --path . --import

trace_root="$(mktemp -d)"
godot --headless --path . \
  -s res://tools/test/m04b/m04b_assignment_trace.gd \
  -- --save-root "$trace_root"
trace_exit=$?
rm -rf "$trace_root"
test ! -e "$trace_root"
test "$trace_exit" -eq 0

./tools/test/run_gut.sh

git diff --check
git status --short
```

### Required negative and recovery matrix

At minimum cover:

- null/malformed state or unready registry;
- missing/wrong-type Threshold, Form, Writ;
- locked Threshold;
- unrevealed/unawakened Form;
- Form active elsewhere;
- zero/full tether capacity;
- duplicate Threshold record;
- missing record;
- already-active/already-inactive;
- stale negative/future/previous revision;
- revision overflow;
- invalid baseline state;
- candidate state invalid after proposed change;
- changed config with nonzero cycle phase or rate carry;
- unsorted/duplicate existing Retinue IDs;
- timestamps outside the simulation cursor;
- save/load of active and inactive records;
- no-mutation equality for each failure;
- no local-time, Steam, file-time, production, or UI source ownership.

No deliberately failing fixture, generated log, or trace directory remains.

## Owner-run Windows automated checks

Codex must add:

```text
tools/test/owner/run_m04b_owner_verification.ps1
```

Expected invocation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
    -File .\tools\test\owner\run_m04b_owner_verification.ps1 `
    -CommitSha "<PR_HEAD_SHA>"
```

The script follows `OWNER_VERIFICATION_WORKFLOW.md` and the corrected final M04A implementation:

1. resolve repository and Godot console executable;
2. keep Git optional and compare when available;
3. write one UTF-8 PR-head log;
4. run Godot version;
5. run full GUT before;
6. run focused M04B via in-process named `-GutArgs`;
7. run explicit import;
8. run the M04B trace in a unique Windows temp directory;
9. capture the completed trace output before starting marker verification;
10. verify all exact markers;
11. clean in `finally` and prove absence;
12. tolerate prior ignored logs and audit real artifacts;
13. run full GUT after;
14. print the standardized summary.

Expected summary:

```text
Automated result: PASS
Failed step count: 0
Pending interactive checks: None for M04B
Cleanup result: PASS
Log path: <generated path>
```

No interactive checklist is required.

## Manual verification

| Step | Actor/environment | Action | Expected result | Merge gate? |
|---:|---|---|---|---:|
| 1 | Owner Windows | Pull and confirm exact M04B PR head in GitHub Desktop | Branch/head matches `-CommitSha` | Yes |
| 2 | Owner Windows | Run M04B owner script | PASS, zero failed steps, cleanup PASS | Yes |
| 3 | Owner | Upload/quote generated log | Evidence identifies head, commands, markers, and results | Yes |

There is no editor, visual, gameplay, audio, A/B, or Steam observation in M04B.

## Save/load verification

M04B changes authoritative assignment state but does not change the schema.

| Scenario | Setup | Reload/action | Expected result |
|---|---|---|---|
| Active round trip | Dispatch revision 1 and save | Reload | Exact active state, IDs, revision, timestamps, phase/carries |
| Inactive round trip | Recall revision 2 and save | Reload | Exact inactive record; zero derived occupancy |
| Redispatch round trip | Redispatch revision 3 and save | Reload | Exact active record; original start preserved |
| Stale command after reload | Reload latest state, submit older revision | Execute command | Stable rejection, no mutation |
| Invalid snapshot | Contradictory activity/capacity/IDs | Load | Reject through existing validators |
| No schema change | Compare envelope/constants/fixtures | Review/tests | Still schema v2; no migration or key change |

## Documentation updates

| Document | Required update |
|---|---|
| `docs/codex/MILESTONES.md` | M04B status, realized paths/counts, verification |
| `docs/codex/ARCHITECTURE.md` | Realized command owner and commit boundary |
| `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | Final command/result/error/event contract if it differs |
| `docs/codex/IMPLEMENTATION_RULES.md` | Only if a reusable command rule emerges |
| `docs/codex/TESTING_AND_VALIDATION.md` | Exact tests, trace, owner package |
| `docs/codex/OWNER_VERIFICATION_WORKFLOW.md` | No change expected unless generic defect found |
| `docs/codex/DECISIONS.md` | Mark `DEC-0035` Accepted on prompt approval; no new implementation shortcut decision |
| Design source of truth | No change expected |
| `README.md` | Developer trace command if useful |

## Stop conditions

Stop and report if:

1. M04A is not actually merged/passed;
2. stable recalled records conflict with current schema or accepted design;
3. Form exclusivity needs a different owner decision;
4. assignment commands require elapsed production;
5. a nonzero carry cannot be rejected safely without M04C/M04D work;
6. Retinue behavior or reservations become necessary;
7. schema version 3 or a migration appears necessary;
8. `GameSession`, UI, tutorial, reports, forecasts, or Steam become necessary;
9. another primary owner or more than two seams are required;
10. non-documentation source/test files exceed approximately 30 or code/test lines exceed approximately 1,200;
11. a dependency or broad framework appears necessary;
12. any required verification fails.

## Final response format

Use exactly:

### Implementation completed

Summarize only M04B command behavior, record/revision/tether semantics, results/events, and owner package.

### Files changed

List every changed file and actual source/test file count plus code/test line delta versus estimate.

### Verification

Separate Linux/Codex evidence from `Pending owner verification`. Include exact test counts, trace markers, and exit codes.

### Assumptions

State narrow assumptions that did not change accepted semantics.

### Known limitations and risks

State pending Windows evidence and the deliberate deferral of active in-place reconfiguration with nonzero rate state.

### Deferred work

Name M04C simulation, M04D output/rate-change resolution, M04E forecast/report, Retinue assignment, UI, and later epics.

### Suggested next task

Normally: owner runs the M04B Windows package. Do not draft M04C.
