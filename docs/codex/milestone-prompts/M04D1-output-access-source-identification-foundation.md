# Implementation slice M04D1: Output access and source-identification foundation

**Prompt version:** v0.1  
**Prompt date:** 2026-07-17  
**Prompt status:** Approved  
**Work item type:** Implementation slice  
**Parent conceptual epic:** `M04 — Persistent Reaping simulation vertical slice` / M04D sub-epic  
**Milestone definition:** `docs/codex/MILESTONES.md` — `### M04D1 — Output access and source-identification foundation`  
**Recommended task size:** Medium; one output-access, schema-migration, and source-initialization pull request  
**Scope-gate result:** Approved within guardrails; stop if actual work needs another primary owner, more than two cross-layer seams, more than approximately 30 non-documentation source/test files, or more than approximately 1,500 non-documentation code/test lines  
**Expected base branch or ref:** current `main` after M04C merge commit `719592c85ca4e90ecd5df4593e37a81d36b2789e`  
**Planned prompt path:** `docs/codex/milestone-prompts/M04D1-output-access-source-identification-foundation.md`

> This prompt authorizes schema version 3, global output-item access, version-2 compatibility finalization, transactional unlock/source initialization, and availability reconciliation. It authorizes no elapsed discrete-channel production, item banking, channel-rate evaluation, reconfiguration, ETA, discovery UI, or later M04D behavior.

## Approval record

The project owner approved M04D1 prompt v0.1 on 2026-07-17.

Accepted `DEC-0037` remains authoritative. The approved slice introduces schema version 3, global prospective output-item access, content-aware preservation of valid legacy acquisition state, transactional available-source initialization, no retroactive production, and no disclosure of unavailable Thresholds.

Do not execute the superseded `M04D-output-channels-long-horizon-progress.md` prompt. Do not draft or implement M04D2 in this task.

## Execution protocol

Before editing:

1. Read `AGENTS.md` completely.
2. Read every source in **Authoritative context**.
3. Inspect current `main`, merged M04C source/tests/docs, and `git status --short`.
4. Verify M04C is Merged/Passed at merge commit `719592c85ca4e90ecd5df4593e37a81d36b2789e`.
5. Verify schema version 2 is the current executable baseline and v1/v2 historical validators/fixtures are intact.
6. Verify `ProgressionState` currently contains only tether capacity and no global output-access fact.
7. Verify current `ThresholdAcquisitionState`, channel content, `progression_required`, Threshold availability, mapper, migration registry, and coordinator behavior.
8. State the proposed schema-v3 shape, migration/finalization sequence, access service API, result/event types, validation invariants, expected files, and verification plan before non-trivial edits.
9. Reassess scope. Stop before implementation if elapsed production, discovery meters/UI, progression purchasing, M04D2 accumulation, M04D3 reconfiguration, another primary owner, or a broad persistence rewrite becomes necessary.

During implementation:

- Keep one focused `OutputAccessService` or equivalent primary owner.
- Keep schema migration and persistence finalization in the existing persistence architecture.
- Use working candidates and one final state replacement; no partial live mutation.
- Read no clock and advance no simulation time.
- Grant no inventory, progress, carry, or elapsed production.
- Never disclose unavailable Threshold names or channels.
- Use sorted canonical IDs and deterministic event ordering.
- Add junior-readable comments explaining global-vs-source ownership, migration finalization, no-backfill, idempotency, and later slice seams.
- Create focused tests, a real-file trace, and the Windows owner package.
- Report exact test counts, markers, exit codes, and actual-versus-estimated scope.
- Leave Windows owner verification pending until the owner supplies the generated log.
- Do not draft or implement M04D2.

## Objective

Implement schema version 3 and one scene-independent output-access service that persists global item-level access, transactionally initializes every currently available source at zero, identifies only available source relationships, reconciles later-available Thresholds, preserves historical version-2 acquisition progress, and proves no pre-unlock backfill.

## Player or developer outcome

A developer can:

- migrate a real schema-v2 save to v3 without losing any acquisition state;
- unlock one output item globally;
- see all currently available matching Threshold/channel sources initialized at zero and identified;
- prove a locked or unavailable source produced nothing earlier;
- make another Threshold available and reconcile its already-unlocked source from zero;
- repeat unlock/reconciliation without duplicates;
- save and reload exact access/source state;
- run one Windows PowerShell command and share a complete UTF-8 verification log.

## Authoritative context

| Priority | Source | Required sections or records | Why it applies |
|---:|---|---|---|
| 1 | `AGENTS.md` | Full file | Repository rules |
| 2 | `docs/codex/MILESTONES.md` | Gates, M04D/M04D1, scope guardrails | Slice boundary |
| 3 | `docs/codex/DECISIONS.md` | `DEC-0011`, `DEC-0012`, amended `DEC-0027`, `DEC-0028`, `DEC-0030`, `DEC-0033`, `DEC-0034`, `DEC-0037` | Access/migration authority |
| 4 | `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | v1/v2 schema, approved M04D access/schema-v3 contract | Exact state/wire rules |
| 5 | `docs/codex/ARCHITECTURE.md` | Persistence coordinator, M04A/M04C realized boundaries, approved M04D architecture | Ownership/transaction flow |
| 6 | `docs/codex/IMPLEMENTATION_RULES.md` | State, commands, persistence, comments, diagnostics | Engineering conventions |
| 7 | `docs/codex/TESTING_AND_VALIDATION.md` | M04D1 package and owner workflow | Evidence |
| 8 | `docs/codex/OWNER_VERIFICATION_WORKFLOW.md` | Complete | Windows runner/log |
| 9 | `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md` | IF-REQ-05, IF-REQ-09, amended IF-REQ-10, IF-REQ-18; access/knowledge/insight | Product intent |
| 10 | `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md` | Provisions unlock, no-backfill, no-softlock, source identification | Prototype behavior |
| 11 | Current implementation | `GameState`, validator, schema mapper/validator, migration registry, coordinator, fixtures, M04C | Actual baseline |

Stop and report unresolved conflicts.

## Repository state

Expected baseline:

| Item | Expected state |
|---|---|
| Completed slices | M04A, M04B, M04C Merged/Passed |
| Current writer | Schema version 2, codec `JSON_V1` |
| Historical support | Frozen v1 and v2 validators/fixtures; sequential migration architecture |
| Progression state | `command_tether_capacity` only |
| Channel source state | `ThresholdState.channel_acquisition` with progress/carry/banked totals |
| Content | Stable channel IDs, `progression_required`, source Threshold, output item, enabled flag |
| Access command | None |
| Discovery/UI | No M04D1 source-disclosure screen or insight state |
| Working tree | Clean except task changes |

## Dependencies

| Dependency | Required state | Verification |
|---|---|---|
| M04C | Merged/Passed | Merge/evidence record |
| `DEC-0037` | Accepted | Decision record |
| `GATE-OUTPUT-ACCESS-SCHEMA` | Decision contract satisfied | Milestone map |
| `GATE-SLICE-SCOPE` | Remains within prompt limits | Handoff |
| M03 content | Ready registry and current channel relationships | Content tests |
| M02/M04A persistence | Atomic upgrade and failure preservation | Migration tests |
| Windows environment | Godot 4.7 console available | Owner package |

## Scope and review-surface assessment

| Assessment item | Approved estimate |
|---|---|
| Primary subsystem owner | `OutputAccessService` |
| Principal transition | Global item unlock / source reconciliation |
| New authoritative state | One sorted global access array in `ProgressionState` |
| Save-schema change | Version 3 plus `v2 -> v3` migration/finalization |
| Deterministic algorithm | Sorted source matching and idempotent initialization |
| UI/platform work | None |
| Cross-layer seams | Two: access service ↔ state/content validation; migration finalizer ↔ coordinator/content |
| Estimated source/test files | Approximately 14–24, excluding `.uid` and docs |
| Estimated code/test lines | Approximately 850–1,350, excluding `.uid` and docs |
| Owner package | `run_m04d1_owner_verification.ps1` |
| Mandatory split trigger | Not crossed at approval |

Stop before approximately 30 non-documentation source/test files, 1,500 code/test lines, more than two seams, or another primary owner.

## Scope

Implement only:

1. `ProgressionState.unlocked_output_item_ids` with clone/equality/validation;
2. schema-v3 constants, validator, mapper, representative fixture, and current writer;
3. pure `v2 -> v3` migration;
4. content-aware legacy-access finalization inside the atomic upgrade path;
5. sequential `v1 -> v2 -> v3` proof;
6. one typed output-item unlock command;
7. one available-source reconciliation command;
8. pure effective-access/source-identification queries;
9. typed results, summaries, events, and checkpoint requests;
10. focused tests, real-file trace, Windows owner runner, and synchronized docs.

## Non-goals

Do not implement:

1. elapsed non-Essence production or inventory banking;
2. channel rate plans, modifiers, Settlement accumulation, or whole extraction;
3. compatible redispatch or ETA/progress queries;
4. Recollection purchase, milestone evaluation, Threshold unlock, or content effect execution;
5. discovery progress, charting, source-count UI, Codex pages, or forecast confidence;
6. Retinue/support/Hall behavior;
7. multiple-active-Reaping production;
8. Steam, trusted time, foreground/offline orchestration, scenes, or UI;
9. schema version 4, codec changes, encryption, compression, or content revision changes;
10. production `.tres` multiplier changes;
11. a general unlock framework or unrelated refactor.

## Required behavior

| ID | Required behavior | Source trace |
|---|---|---|
| `RB-01` | One focused service owns output-item access and source reconciliation. | `DEC-0012`, `DEC-0037` |
| `RB-02` | Access is global by canonical output item ID. | `DEC-0037` |
| `RB-03` | Knowledge/insight cannot mutate access. | Access model |
| `RB-04` | `unlocked_output_item_ids` is sorted, unique, typed, and deep-cloned. | Schema-v3 contract |
| `RB-05` | Invalid/disabled/non-item IDs reject without mutation. | Validation contract |
| `RB-06` | Unlock requires at least one valid authored non-Essence channel relationship. | Access contract |
| `RB-07` | Unlock reads the current simulation cursor but does not change it. | Command boundary |
| `RB-08` | Unlock grants no inventory, progress, carry, or banked units. | No-backfill rule |
| `RB-09` | Unlock adds the item once and initializes all currently available matching sources. | `DEC-0037` |
| `RB-10` | Source initialization is exactly zero/zero/zero. | Data contract |
| `RB-11` | Unavailable Thresholds are neither initialized nor named in results/events. | Availability-scoped disclosure |
| `RB-12` | Unlock may succeed even when no source is currently available. | Global access rule |
| `RB-13` | Reconciliation initializes sources that become available later. | Future-source rule |
| `RB-14` | Reconciliation never changes Threshold availability itself. | Ownership rule |
| `RB-15` | Non-progression-required non-Essence sources reconcile automatically when available. | Eligibility rule |
| `RB-16` | Essence channels are excluded from acquisition/access initialization. | M04C ownership |
| `RB-17` | Effective initialized-source knowledge is at least `IDENTIFIED`. | Identification-at-unlock |
| `RB-18` | Authored `CHARTED` remains Charted; unavailable sources are omitted. | Query contract |
| `RB-19` | No separate insight meter is persisted in M04D1. | Slice boundary |
| `RB-20` | Repeated unlock is idempotent with no duplicate event/checkpoint. | Command contract |
| `RB-21` | Repeated reconciliation is idempotent. | Command contract |
| `RB-22` | Success/failure uses typed result, summary, events, and checkpoint flag. | `DEC-0012` |
| `RB-23` | Events are deterministic and primitive/save-safe but not persisted. | Event contract |
| `RB-24` | The service performs no file I/O or clock reads. | Architecture |
| `RB-25` | Schema v1 and v2 validators/fixtures remain frozen. | `DEC-0034` |
| `RB-26` | Schema v3 retains the existing envelope/game-state keys. | Schema contract |
| `RB-27` | The only new wire field is progression access array. | Schema contract |
| `RB-28` | Pure v2 migration adds an empty array and preserves all existing fields/revision. | Migration contract |
| `RB-29` | Content-aware finalization derives access from every valid legacy acquisition entry. | `DEC-0037` |
| `RB-30` | Legacy acquisition progress/carry/banked totals remain exact. | Compatibility contract |
| `RB-31` | Finalization may initialize other currently available sources only at zero. | Compatibility contract |
| `RB-32` | Invalid legacy channel/content references fail and preserve the source save. | Transaction contract |
| `RB-33` | Sequential v1→v2→v3 increments save revision once for the complete persisted upgrade. | `DEC-0034`, `DEC-0037` |
| `RB-34` | Runtime is exposed only after atomic upgrade persistence succeeds. | Persistence boundary |
| `RB-35` | Already-current v3 loads do not rewrite, rotate, or increment revision. | Compatibility contract |
| `RB-36` | New ordinary saves write v3 and current content revision. | Writer contract |
| `RB-37` | Domain validation rejects access/acquisition/availability contradictions. | State contract |
| `RB-38` | Set/map iteration and event ordering are canonical. | Determinism |
| `RB-39` | Every failure preserves exact live state and original valid save candidates. | Transaction rule |
| `RB-40` | No M04D2/M04D3 or player-facing behavior enters the diff. | Scope gate |

## State transitions

| ID | Initial state | Trigger | Required result | Failure behavior |
|---|---|---|---|---|
| `ST-01` | Valid v2 with no acquisition | Load/upgrade | v3, empty access set, all authority preserved | Preserve v2 on failure |
| `ST-02` | Representative v2 Soldier-Soul acquisition | Load/upgrade | v3 access contains output item; progress exact | Preserve v2 on failure |
| `ST-03` | Valid v1 | Load/upgrade | Sequential v2 then v3, one persisted revision increment | Preserve source on failure |
| `ST-04` | Current valid v3 | Load | Exact runtime, no rewrite/rotation | Reject invalid without overwrite |
| `ST-05` | Item locked; one matching available source | Unlock item | Access added, source zero-initialized, two ordered event kinds | Atomic rejection |
| `ST-06` | Item locked; several matching available sources | Unlock item | All source records created in canonical order | Atomic rejection |
| `ST-07` | Item locked; source Threshold unavailable | Unlock item | Global access only; unavailable source omitted | — |
| `ST-08` | Item already unlocked | Repeat unlock | Idempotent no-op | No duplicate event/checkpoint |
| `ST-09` | Item unlocked; Threshold later AVAILABLE | Reconcile | Missing matching source initialized/identified at zero | Atomic rejection |
| `ST-10` | Reconciled state | Repeat reconcile | Idempotent no-op | No duplicate event/checkpoint |
| `ST-11` | Locked state with elapsed historical cursor | Unlock | No time/inventory/progress backfill | Any gain is failure |
| `ST-12` | Existing unrelated channel progress | Unlock another item | Existing values unchanged | Atomic rejection |
| `ST-13` | Invalid/disabled/misowned channel relationship | Unlock/reconcile | No mutation | Stable typed error |
| `ST-14` | Essence item/channel | Unlock/reconcile | No acquisition initialization | Stable exclusion/rejection |
| `ST-15` | Valid v3 access/source state | Save/load | Exact reconstruction | Invalid snapshot rejected |
| `ST-16` | Upgrade write failure at any atomic stage | Load/upgrade | No runtime exposure; original valid source retained | Stable transaction error |

## Error and event contract

Stable error categories should include:

```text
OUTPUT_ACCESS_STATE_INVALID
OUTPUT_ACCESS_ITEM_NOT_FOUND
OUTPUT_ACCESS_ITEM_DISABLED
OUTPUT_ACCESS_NO_AUTHORED_SOURCE
OUTPUT_ACCESS_CHANNEL_INVALID
OUTPUT_ACCESS_CHANNEL_OWNERSHIP_INVALID
OUTPUT_ACCESS_ESSENCE_EXCLUDED
OUTPUT_ACCESS_MIGRATION_FINALIZATION_FAILED
OUTPUT_ACCESS_PERSISTENCE_FAILED
```

Exact spelling may be refined before implementation only if docs/tests remain synchronized.

Events:

```text
OUTPUT_ITEM_UNLOCKED
OUTPUT_SOURCE_IDENTIFIED
```

No failure emits an event or requests a checkpoint.

## Expected files

| Path/area | Expected action |
|---|---|
| `src/domain/game_state.gd` | Add access array to progression clone/state |
| `src/domain/game_state_validator.gd` | Add access/source invariants |
| `src/domain/output_access_service.gd` or equivalent | Add primary command owner |
| `src/persistence/` schema validator/mapper/migration/coordinator | Add v3 and finalization |
| `tests/fixtures/saves/schema_v3_m04d1_access.json` | Add representative current fixture |
| `tests/unit/m04d1/` | Add access/state/migration tests |
| `tests/integration/m04d1/` | Add coordinator/file transaction tests |
| `tools/test/m04d1/m04d1_output_access_trace.gd` | Add deterministic real-file trace |
| `tools/test/owner/run_m04d1_owner_verification.ps1` | Add Windows package |
| Maintained docs | Update realized paths/status/evidence |

Do not add UI scenes, content balance changes, or a generic progression framework.

## Acceptance criteria

| ID | Pass condition | Evidence | Merge gate? |
|---|---|---|---:|
| `AC-01` | One focused service owns unlock/reconciliation. | Code review/tests | Yes |
| `AC-02` | Schema v3 adds only the canonical global access array. | Schema tests | Yes |
| `AC-03` | v1/v2 historical support remains intact. | Fixture tests | Yes |
| `AC-04` | Pure v2 migration preserves all existing values. | Deep comparison | Yes |
| `AC-05` | Legacy acquisition finalization derives access and preserves values. | Fixture/trace | Yes |
| `AC-06` | Upgrade failures preserve the original save and expose no runtime. | Failure matrix | Yes |
| `AC-07` | Current v3 load does not rewrite. | Storage assertions | Yes |
| `AC-08` | New save writes v3/current content revision. | Integration test | Yes |
| `AC-09` | Unlock initializes all and only currently available matching sources. | Unit/trace | Yes |
| `AC-10` | Every new source begins zero/zero/zero. | Exact assertions | Yes |
| `AC-11` | Unavailable Thresholds are not initialized or disclosed. | Unit/trace | Yes |
| `AC-12` | Later availability reconciliation initializes the source. | Unit/trace | Yes |
| `AC-13` | No pre-unlock time, inventory, progress, carry, or banked units appear. | Before/after proof | Yes |
| `AC-14` | Repeated unlock/reconciliation is idempotent. | Repeat matrix | Yes |
| `AC-15` | Essence remains outside channel acquisition. | Validation/tests | Yes |
| `AC-16` | Effective identification is reconstructible without a persisted insight meter. | Query tests | Yes |
| `AC-17` | Access set and source maps are canonical and deep-cloned. | State tests | Yes |
| `AC-18` | Invalid IDs/content/ownership/access contradictions reject. | Negative matrix | Yes |
| `AC-19` | Typed result/event/checkpoint contract is complete and deterministic. | Contract tests | Yes |
| `AC-20` | Every command/persistence failure leaves exact live state unchanged. | Canonical comparison | Yes |
| `AC-21` | Engine/core M04C state is untouched by access commands. | Regression assertions | Yes |
| `AC-22` | Real-file trace emits all twelve exact markers and exits nonzero on mismatch. | Trace | Yes |
| `AC-23` | Linux focused/import/trace/full checks pass. | Commands/exits | Yes |
| `AC-24` | Windows owner package passes full/focused/import/trace/cleanup/audit/full. | Owner log | Yes |
| `AC-25` | No clock, simulation, UI, insight, M04D2, M04D3, or platform ownership enters the diff. | Source/diff audit | Yes |
| `AC-26` | Junior-readable comments explain migration and access ownership. | Review | Yes |
| `AC-27` | Actual scope remains inside the approved assessment or work stops. | Handoff | Yes |

A pending owner result keeps verification Partial and prevents merge.

## Automated verification

Run:

```bash
git status --short

./tools/test/run_gut.sh -- \
  -gdir=res://tests/unit/m04d1 \
  -gdir=res://tests/integration/m04d1

godot --headless --path . --import

trace_root="$(mktemp -d)"
godot --headless --path . \
  -s res://tools/test/m04d1/m04d1_output_access_trace.gd \
  -- --save-root "$trace_root"
trace_exit=$?
rm -rf "$trace_root"
test ! -e "$trace_root"
test "$trace_exit" -eq 0

./tools/test/run_gut.sh

git diff --check
git status --short
```

Also prove missing/blank/`user://` trace roots fail, removal of one marker fails verification, no generated artifact is committed, and no prohibited source ownership appears.

## Owner-run Windows checks

Codex must add:

```text
tools/test/owner/run_m04d1_owner_verification.ps1
```

Expected invocation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
    -File .\tools\test\owner\run_m04d1_owner_verification.ps1 `
    -CommitSha "<PR_HEAD_SHA>"
```

Follow the final M04C runner pattern and verify all twelve exact trace markers.

Expected summary:

```text
Automated result: PASS
Failed step count: 0
Pending interactive checks: None for M04D1
Cleanup result: PASS
```

No interactive checklist is required.

## Trace markers

```text
TRACE M04D1 schema_v2_to_v3_empty_unlocks=PASS
TRACE M04D1 legacy_acquisition_preserved_and_item_unlocked=PASS
TRACE M04D1 item_unlock_global=SOUL_FORM_SCRIBE
TRACE M04D1 available_sources_initialized=1
TRACE M04D1 unavailable_threshold_not_disclosed=PASS
TRACE M04D1 future_available_source_reconciled=PASS
TRACE M04D1 unlock_starts_from_zero=PASS
TRACE M04D1 no_retroactive_inventory_or_progress=PASS
TRACE M04D1 repeated_unlock_idempotent=PASS
TRACE M04D1 access_knowledge_insight_separated=PASS
TRACE M04D1 schema_v3_round_trip=PASS
TRACE M04D1 no_clock_or_production_sources=PASS
```

## Documentation updates

Update canonical sections in:

- `docs/codex/MILESTONES.md`;
- `docs/codex/ARCHITECTURE.md`;
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`;
- `docs/codex/TESTING_AND_VALIDATION.md`;
- `README.md` only if the trace command is useful.

Do not add duplicate M04D1 sections or alter accepted `DEC-0037` without reporting a genuine conflict.

## Stop conditions

Stop and report if:

1. schema v3 requires another new aggregate family;
2. historical acquisition state cannot be preserved without loss;
3. unlock semantics require elapsed production or a progression-purchase subsystem;
4. per-source insight must be persisted now;
5. production content must be changed;
6. M04D2 accumulation or M04D3 reconfiguration becomes necessary;
7. another primary owner or more than two seams is required;
8. files exceed approximately 30 or code/test lines exceed approximately 1,500;
9. any required verification fails.

## Final response format

Use exactly:

### Implementation completed
### Files changed
### Verification
### Assumptions
### Known limitations and risks
### Deferred work
### Suggested next task

Under **Files changed**, include actual-versus-estimated scope.  
Under **Verification**, leave Windows owner verification pending.  
Under **Suggested next task**, state only that the owner should run the M04D1 Windows package. Do not draft M04D2.
