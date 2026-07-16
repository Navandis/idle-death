# Implementation slice M04B: Dispatch, recall, and assignment integrity

**Prompt version:** v0.2  
**Prompt date:** 2026-07-16  
**Prompt status:** Approved  
**Work item type:** Implementation slice  
**Parent conceptual epic:** `M04 — Persistent Reaping simulation vertical slice`  
**Milestone definition:** `docs/codex/MILESTONES.md` — `### M04B — Dispatch, recall, and assignment integrity`  
**Recommended task size:** Small-medium; one command/assignment pull request  
**Scope-gate result:** Approved within guardrails; mandatory stop if actual work needs another primary owner, more than two cross-layer seams, more than approximately 30 non-documentation source/test files, or more than approximately 1,200 non-documentation code/test lines  
**Expected base branch or ref:** current `main` after M04A merge commit `673ad884357fc742a0a26dbb542d5b8d9fe557c9`  
**Planned prompt path:** `docs/codex/milestone-prompts/M04B-dispatch-recall-assignment-integrity.md`

> This prompt authorizes only M04B's scene-independent Reaping assignment commands and their schema-v2 persistence proof. It does not authorize elapsed production, active in-place rate-context reconfiguration, Retinue assignment, tutorial behavior, player-facing UI, or any later implementation slice.

## Approval record

The owner approved M04B prompt v0.2 and accepted `DEC-0035` on 2026-07-16.

The approved identity model is:

- operation = canonical Threshold ID;
- loadout = canonical configuration value tuple;
- assignment state = Threshold ID plus revision;
- activation episode = revision produced by dispatch/redispatch;
- `started_simulation_msec` = immutable first successful dispatch timestamp, with zero valid.

Do not execute an alternate identity or record-deletion model without a new owner-approved decision.

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
- Add junior-readable comments explaining the four identity layers, immutable first-start timestamp, revision guards, candidate validation, tether derivation, and the M04C/M04D handoff.
- Add or update every test needed to prove the contract.
- Create the M04B trace and Windows owner package.
- Report exact commands, counts, markers, exit codes, and actual-versus-estimated scope.
- Leave owner Windows verification pending until the owner supplies a generated log for the tested PR head.
- Do not draft M04C.

Do not describe M04B as complete while any merge-gate criterion is failed, blocked, or pending.

## Objective

Implement typed initial-dispatch, recall, and inactive-record redispatch commands for the existing schema-v2 `GameState`. Commands must preserve one Threshold-scoped operation record, distinguish loadout/assignment/episode identity, preserve the immutable first-start timestamp, derive tether occupancy from active records, guard mutations by assignment revision, enforce valid Form/Threshold/Writ/capacity relationships, preserve frozen progress, and round-trip exactly without advancing elapsed production.

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
- distinguish the same operation/same loadout/new episode from the same loadout on another Threshold;
- return to an earlier loadout without restoring an old revision, episode, progress snapshot, or historical effective rate;
- prove `started_simulation_msec` is set once, may equal zero, and never changes under ordinary assignment commands;
- execute the complete Windows proof through one PowerShell command and shareable UTF-8 log.

## Authoritative context

| Priority | Source | Required sections, labels, or records | Why it applies |
|---:|---|---|---|
| 1 | `AGENTS.md` | Full file, especially domain ownership, comments, tests, save/time, and scope rules | Repository operating contract |
| 2 | `docs/codex/MILESTONES.md` | §§3–7; `GATE-SLICE-SCOPE`; `GATE-REAPING-ASSIGNMENT`; `### M04B` | Approved slice and merge gates |
| 3 | `docs/codex/MILESTONE_RECALIBRATION_PROPOSAL.md` | §§2–8 | Review-surface policy |
| 4 | `docs/codex/PROMPT_TEMPLATE.md` | §§2.1–2.4; scope assessment; completion rules | Prompt ownership and split gate |
| 5 | `docs/codex/OWNER_VERIFICATION_WORKFLOW.md` | Complete script/log/cleanup/evidence rules | Required Windows package |
| 6 | `docs/codex/DECISIONS.md` | `DEC-0007`, `DEC-0012`, `DEC-0018`–`DEC-0020`, `DEC-0023`, `DEC-0025`, `DEC-0027`, `DEC-0028`, `DEC-0033`, `DEC-0034`, accepted `DEC-0035` | State, commands, capacity, progress, scope |
| 7 | `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | §§2–3, 9.3–9.9, 10–12; M04A schema contract; approved M04B assignment contract | Exact state/result/event/command rules |
| 8 | `docs/codex/ARCHITECTURE.md` | §§5–8, 9.1, 11.2–11.3, 20; M04A realized state; approved M04B command boundary | Ownership and transaction flow |
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
2. Threshold-scoped operation identity with no redundant UUID;
3. canonical loadout tuple, assignment-state identity, and activation-episode identity;
4. immutable first-start timestamp semantics, including valid zero;
5. explicit initial dispatch, recall, and inactive-record redispatch;
6. typed command inputs or typed command DTOs;
7. typed action results and ordered assignment events;
8. exact expected-revision and checked-overflow behavior;
9. derived occupied tether count;
10. one-active-Reaping-per-Threshold and one-active-Reaping-per-Form validation;
11. preservation of stable Reaping/Threshold state;
12. safe rejection of changed configuration with unresolved rate-dependent phase/carry;
13. same/different Threshold and loadout identity scenario tests;
14. schema-v2 active/inactive round trips using the existing mapper/coordinator;
15. focused tests, deterministic real-file trace, Windows owner script/log, and required documentation updates.

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
11. a redundant Reaping UUID, persisted loadout ID, persisted assignment-state string, or current-episode timestamp field;
12. dependencies, autoloads, broad cleanup, or unrelated moves.

## Required behavior

| ID | Required behavior | Source trace |
|---|---|---|
| `RB-01` | One service owns M04B assignment mutations. | `DEC-0012`; `DEC-0035` |
| `RB-02` | Commands operate on typed scene-independent `GameState` and validated `ContentRegistry`. | `DEC-0007`, `DEC-0009` |
| `RB-03` | Commands read the existing simulation cursor and do not advance it or read a clock. | Architecture §9.1 |
| `RB-04` | Operation identity is the canonical Threshold ID and map key; no separate Reaping UUID is added. | `DEC-0035` |
| `RB-05` | Loadout identity is the canonical Form/Writ/ordered-Retinue value tuple, not an entity ID. | `DEC-0035` |
| `RB-06` | Assignment-state identity is Threshold ID plus assignment revision. | `DEC-0035` |
| `RB-07` | A dispatch/redispatch activation episode is identified by its resulting revision. | `DEC-0035` |
| `RB-08` | Initial dispatch requires no operation record at the Threshold. | `DEC-0035` |
| `RB-09` | Initial dispatch validates state/registry, available Threshold, awakened Form, enabled Writ, Form exclusivity, and tether capacity before mutation. | `DEC-0012`, `DEC-0020` |
| `RB-10` | Initial dispatch creates an active record at revision 1 with canonical empty operation fields. | `DEC-0035` |
| `RB-11` | Initial dispatch sets immutable `started_simulation_msec` and current configuration timestamp from the existing simulation cursor. | `DEC-0035` |
| `RB-12` | `started_simulation_msec = 0` is valid; record existence proves initialization. | `DEC-0035` |
| `RB-13` | Occupied tether count is derived from active records and never persisted independently. | `DEC-0020` |
| `RB-14` | A Form may lead at most one active Reaping. | `DEC-0035`; `P90-SAFE-09` |
| `RB-15` | Recall requires an existing active record and exact expected revision. | `DEC-0035` |
| `RB-16` | Recall sets inactive, increments once, and updates only the configuration timestamp/active facts. | `DEC-0035` |
| `RB-17` | Recall preserves immutable first-start time, loadout, phase/count/carry, Threshold progress, inventory, and capacity. | `IF-REQ-01`, `IF-REQ-18` |
| `RB-18` | Redispatch requires an existing inactive record and exact expected revision. | `DEC-0035` |
| `RB-19` | Redispatch revalidates Form, Writ, Threshold, exclusivity, and capacity. | `DEC-0012`, `DEC-0020` |
| `RB-20` | Redispatch increments once, reactivates the same operation, preserves first-start time, and updates configuration time. | `DEC-0035` |
| `RB-21` | Same-loadout redispatch preserves frozen phase/carry and creates a new episode. | `DEC-0035` |
| `RB-22` | Changed Form/Writ with nonzero rate-dependent phase/carry returns `REAPING_RESOLUTION_REQUIRED`. | `DEC-0028`; M04C/M04D handoff |
| `RB-23` | Changed Form/Writ with canonical zero rate-dependent state may commit after validation. | `DEC-0035` |
| `RB-24` | Same loadout at another Threshold creates/resumes that other operation and never transfers Threshold-owned progress. | `DEC-0035` |
| `RB-25` | Different loadout at the same Threshold modifies the same operation and preserves first-start time. | `DEC-0035` |
| `RB-26` | Returning to an earlier loadout creates a new revision/episode and does not restore historical state or rate. | `DEC-0035`, `DEC-0028` |
| `RB-27` | Ordinary assignment commands never delete an operation record. | `DEC-0035` |
| `RB-28` | Duplicate, repeated, stale, no-op, and overflow cases leave state unchanged. | `DEC-0012`, `DEC-0035` |
| `RB-29` | Assignment revision uses checked signed-64-bit increment behavior. | `DEC-0026` |
| `RB-30` | Baseline state validates before command handling; malformed objects return typed rejection rather than property-access crashes. | M04A validator contract |
| `RB-31` | Candidate state/record validates before one final map insertion/replacement commits. | `DEC-0012` |
| `RB-32` | Success returns typed result with operation ID, revision/state ID, loadout summary, event, and checkpoint request. | Data contract §§10–11 |
| `RB-33` | Failure returns stable code, diagnostics, no event/checkpoint, and no mutation. | Data contract §11 |
| `RB-34` | Events use current simulation cursor and stable assignment event types. | Domain event contract |
| `RB-35` | Timestamps are context, not identity; equal timestamps cannot conflate operations or episodes. | `DEC-0035` |
| `RB-36` | The service performs no file I/O. | Persistence boundary |
| `RB-37` | Active/inactive operations round-trip exactly through schema v2. | `DEC-0034` |
| `RB-38` | No schema, migration, codec, content revision, or identity-field change is introduced. | M04B definition |
| `RB-39` | No production field changes merely because a command commits. | M04B definition |
| `RB-40` | Trace/owner runner use supplied isolated paths, stable trace-output capture, and leave no artifact. | `DEC-0025`; M04A completion |

## State transitions

| ID | Initial state | Trigger | Required result | Failure behavior | Persistence/event effect |
|---|---|---|---|---|---|
| `ST-01` | No record at available Gloamwood; awakened Man-at-Arms; capacity 1 | Dispatch Standard at cursor `T` | Gloamwood operation created, active revision 1, first-start/config `T`, one tether | Reject fully if any precondition fails | Dispatch event; checkpoint |
| `ST-02` | First dispatch at `T = 0` | Dispatch | `started_simulation_msec = 0` is valid | Must not treat zero as uninitialized | Dispatch event; checkpoint |
| `ST-03` | Active revision 1 | Repeat initial dispatch | No change | Record-exists rejection | No event/checkpoint |
| `ST-04` | Active revision `N` | Recall expected `N` | Inactive `N+1`, tether freed, first-start/state preserved | Overflow/invalid rejects | Recall event; checkpoint |
| `ST-05` | Inactive revision `N+1` | Repeat recall or submit old revision | No change | already-inactive or stale | No event/checkpoint |
| `ST-06` | Inactive revision `N` | Redispatch same loadout | Active `N+1`, new episode, first-start and phase/carry preserved | Capacity/exclusivity/stale rejects | Redispatch event; checkpoint |
| `ST-07` | Inactive, zero rate state | Redispatch changed Form/Writ | Same operation, changed loadout, new revision/episode | Ordinary validation rejects atomically | Redispatch event; checkpoint |
| `ST-08` | Inactive, nonzero rate state | Redispatch changed Form/Writ | No change | resolution-required | No event/checkpoint |
| `ST-09` | Another active operation uses requested Form | Dispatch/redispatch | No change | Form-already-assigned | No event/checkpoint |
| `ST-10` | Capacity already full | Dispatch/redispatch | No change | capacity exceeded | No event/checkpoint |
| `ST-11` | Recalled Gloamwood operation | Redispatch same loadout to Gloamwood | Same operation/loadout value; new revision/episode | — | Redispatch event |
| `ST-12` | Recalled Gloamwood; Broken Watch has no record | Dispatch same loadout to Broken Watch | Independent Broken Watch operation at revision 1 | Form/capacity must be free | Dispatch event |
| `ST-13` | Recalled Gloamwood | Redispatch different zero-carry loadout | Same Gloamwood operation; first-start unchanged | resolution-required if carry nonzero | Redispatch event |
| `ST-14` | Gloamwood previously used loadout 1, then another loadout | Redispatch loadout 1 again | Equal loadout value, new revision/episode; no historical restore | — | Redispatch event |
| `ST-15` | Active or inactive valid operation | Save/load | Exact operation, loadout, revision, timestamps, and frozen state | Invalid snapshot rejects | No duplicate event/revision |
| `ST-16` | Assignment revision at `INT64_MAX` | Recall/redispatch | No change | overflow code | No event/checkpoint |

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

`change_summary` includes operation ID (`threshold_id`), Form, Writ, canonical loadout summary, active state, assignment revision, derived assignment-state ID, activation-episode revision when applicable, and occupied tether count.

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
- No redundant Reaping UUID or timestamp-based identity.
- `started_simulation_msec` is immutable and zero-valid.
- No current-episode timestamp field in M04B.
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
| `AC-01` | One focused service owns initial dispatch, recall, and redispatch. | Code review/tests | Yes |
| `AC-02` | Threshold ID is the sole operation identity; no redundant UUID exists. | State/schema/diff review | Yes |
| `AC-03` | Loadout equality is independent from operation identity. | Identity scenario tests | Yes |
| `AC-04` | Assignment state and activation episode are identified by Threshold plus revision. | Result/event tests | Yes |
| `AC-05` | Valid first dispatch creates revision 1, one tether, and immutable first-start time at the current cursor. | Focused test/trace | Yes |
| `AC-06` | First dispatch at cursor zero is valid and record existence proves initialization. | Boundary test | Yes |
| `AC-07` | Form, Threshold, Writ, availability, awakening, exclusivity, and capacity validate before mutation. | Negative matrix | Yes |
| `AC-08` | Recall retains the stable inactive record and all preserved state. | Mutation comparison | Yes |
| `AC-09` | Redispatch reactivates the same operation, increments once, and preserves first-start time. | Focused test/trace | Yes |
| `AC-10` | Exact expected revisions reject stale/replayed commands without mutation. | Revision matrix | Yes |
| `AC-11` | Revision overflow rejects without mutation. | Boundary test | Yes |
| `AC-12` | One Form cannot lead two active Reapings. | Multi-Threshold test | Yes |
| `AC-13` | Occupied tether count is derived and never serialized separately. | Schema/tests | Yes |
| `AC-14` | Same-loadout/same-Threshold redispatch creates a new episode, not a new operation. | Scenario test | Yes |
| `AC-15` | Same loadout at a different Threshold uses an independent operation/revision/start sequence. | Scenario test | Yes |
| `AC-16` | Different loadout at the same Threshold preserves operation identity and first-start time. | Scenario test | Yes |
| `AC-17` | Returning to a prior loadout creates a new episode and does not restore historical state/rate. | Sequence test | Yes |
| `AC-18` | Same-config redispatch preserves frozen phase/carry; changed config with nonzero rate state requires resolution. | Focused tests | Yes |
| `AC-19` | Every failed command leaves exact state equality and returns no event/checkpoint. | Failure matrix | Yes |
| `AC-20` | Success returns deterministic typed summary/event/checkpoint data. | Result/event tests | Yes |
| `AC-21` | Commands do not change simulation time or production values. | Before/after assertions | Yes |
| `AC-22` | Active and inactive operations round-trip exactly through schema v2. | Integration tests | Yes |
| `AC-23` | M04B adds no schema, migration, codec, content revision, UUID, loadout ID, or episode field. | Diff review | Yes |
| `AC-24` | Trace proves the full identity/dispatch/recall/redispatch scenario matrix and timestamp invariants. | Exact markers, exit 0 | Yes |
| `AC-25` | Linux focused/import/trace/full checks pass. | Commands/exits | Yes |
| `AC-26` | Windows owner package passes full/focused/import/trace/cleanup/audit/full. | Owner log | Yes |
| `AC-27` | Scope, comments, docs, and non-goals remain compliant. | Handoff/diff review | Yes |

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
- operation/loadout/assignment/episode identity distinctions;
- immutable first-start timestamp, including zero;
- scenario sequence same Threshold/same loadout, same loadout/different Threshold, different loadout/same Threshold, and return to prior loadout;
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
8. run the M04B identity/assignment trace in a unique Windows temp directory;
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
| Active round trip | Dispatch revision 1 and save | Reload | Exact operation key, loadout, revision, immutable first-start/config timestamps, phase/carries |
| Inactive round trip | Recall revision 2 and save | Reload | Exact inactive record; zero derived occupancy |
| Redispatch round trip | Redispatch later revision and save | Reload | Exact active operation; immutable first-start preserved; new episode revision retained |
| Stale command after reload | Reload latest state, submit older revision | Execute command | Stable rejection, no mutation |
| Invalid snapshot | Contradictory activity/capacity/IDs | Load | Reject through existing validators |
| Identity matrix | Use equal loadout on two Thresholds and return to prior Gloamwood loadout | Save/reload | Separate operations; correct revisions; no progress transfer; prior loadout is a new episode |
| No schema change | Compare envelope/constants/fixtures | Review/tests | Still schema v2; no migration, UUID, loadout-ID, episode-ID, or key change |

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
3. Threshold-scoped identity, immutable first-start semantics, or Form exclusivity needs a different owner decision;
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

Summarize only M04B operation/loadout/assignment/episode identity, immutable first-start semantics, command behavior, revision/tether rules, results/events, and owner package.

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
