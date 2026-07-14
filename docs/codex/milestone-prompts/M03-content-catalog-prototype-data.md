# Milestone M03: Content catalog, canonical IDs, and configurable prototype data

**Prompt version:** v0.2  
**Prompt date:** 2026-07-14  
**Prompt status:** Approved  
**Milestone definition:** `docs/codex/MILESTONES.md` — `### M03 — Content catalog, canonical IDs, and configurable prototype data`  
**Recommended task size:** Medium-large but bounded to authored data, normalization, validation, compatibility, tests, and developer verification  
**Expected base branch or ref:** current `main` after M02 merge commit `480a9eae2fe0c3591503da56b07c272be74ec027`  
**Planned prompt path:** `docs/codex/milestone-prompts/M03-content-catalog-prototype-data.md`

> This prompt authorizes only the M03 content foundation. It does not authorize production simulation, inventory/runtime gameplay state, player-facing screens, tutorial orchestration, Steam behavior, final balance, or future milestone implementation.

Approval of this prompt accepts `DEC-0029` through `DEC-0032` and the listed M03 numeric values only as configurable prototype scaffold. Those values are not final balance and may change through later playtesting with an updated content revision.

## Execution protocol

Before editing:

1. Read `AGENTS.md` completely.
2. Read every source and exact section listed under **Authoritative context**.
3. Inspect the merged M00–M02 implementation, current tests, `.tres`/Resource usage, persistence APIs, owner-verification workflow, and `git status --short`.
4. Confirm PR #6 is merged at `480a9eae2fe0c3591503da56b07c272be74ec027`, M02 verification is Passed, and `GATE-SAVE-SCHEMA` is satisfied.
5. Confirm there is no existing production content registry or catalog that this prompt would overwrite.
6. Confirm `DEC-0029` through `DEC-0032` are Accepted in the committed planning package before implementing. If any remain Proposed, stop and report the mismatch.
7. Briefly state the planned Resource type structure, catalog groups, validation passes, normalization boundary, save-content-revision integration, trace, owner script/checklist, expected files, and test plan before making non-trivial edits.
8. Report any material mismatch between this prompt and the repository before implementing dependent behavior.

During implementation:

- Limit changes to M03 and its acceptance criteria.
- Preserve M01 fixed-point/time semantics and M02 schema/codec/storage semantics.
- Keep authored Resources, normalized runtime content, mutable player state, and persistence responsibilities separate.
- Keep canonical IDs independent from editable display names, descriptions, optional localization keys, and shared terminology.
- Use Essence, `RES_ESSENCE`, and the approved Essence channel IDs exclusively; reject deprecated alternate terminology.
- Keep every provisional cost, rate, coefficient, duration, floor, target, threshold, and reward in content data or a clearly labelled content-policy constant—not in UI, tutorial, persistence, or trace code.
- Add junior-readable comments that explain Resource ownership, revision compatibility, normalization, stable IDs, reference validation, all-or-nothing registry construction, and why arbitrary content execution is forbidden.
- Add or update every test needed to prove behavior.
- Create the required M03 owner-verification script and Inspector checklist.
- Run every Codex-executable check listed below and report exact commands, counts, and exit codes.
- Leave owner Windows and Inspector checks `Pending owner verification` until explicit owner evidence exists.
- Do not create, rewrite, or broaden this prompt or any future prompt.

Do not describe M03 as complete while any merge-gate criterion is failed, blocked, or pending.

## Objective

Implement Death Idle's first typed, explicit, deterministic authored-content layer. One root `ContentCatalog` must reference the complete current prototype definition set and centralized terminology; `ContentRegistry` must validate it, normalize all authoritative decimal values into exact runtime integers, expose deterministic lookup data independent of mutable source Resources, keep editable player-facing language separate from stable IDs, and enforce explicit content-revision compatibility with M02 saves.

## Player or developer outcome

A developer can open representative `.tres` files in Godot 4.7, edit prototype scaffold values and player-facing names without changing GDScript, load the complete catalog and centralized terminology headlessly, inspect deterministic normalized content for the two Forms and two Thresholds, validate an M02 save revision, and receive actionable aggregated diagnostics for deliberately invalid content.

The developer-visible demonstration must show:

- `prototype-content-r1` and its exact compatibility list;
- all required content groups and stable IDs;
- the `TERM_...` terminology entries and editable naming boundary;
- Essence as `RES_ESSENCE` plus the two approved Essence channel IDs;
- Man-at-Arms and Scribe differences derived from data;
- the six `CHANNEL_...` sources, including eight-hour and twenty-four-hour periods;
- a rename fixture for Unclosed Ledger, a Recollection, and `TERM_THRESHOLD` that preserves canonical IDs and mechanics;
- an invalid duplicate-ID failure;
- a provisional override changing normalized output without code changes;
- no production simulation or player-facing UI.

## Authoritative context

| Priority | Source | Required sections, labels, or records | Why it applies |
|---:|---|---|---|
| 1 | `AGENTS.md` | Full file; especially source hierarchy, data-driven content, comments, save/load, and scope | Repository-wide rules |
| 2 | `docs/codex/MILESTONES.md` | §5 `GATE-CONTENT-CATALOG`; M02 completion; `### M03` | Approved scope, dependency, and merge gate |
| 3 | `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md` | `P90-SAFE-07`–`P90-SAFE-12`; §§6–9; canonical IDs; Form, Retinue, Threshold, Hall, Recollection, Writ, and tutorial tables | Prototype content and guarantees |
| 4 | `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md` | `IF-REQ-05`, `IF-REQ-07`–`IF-REQ-13`, `IF-REQ-15`; §§7–11 and provisional/open values | Broader content and system invariants |
| 5 | `docs/codex/ARCHITECTURE.md` | §§4–5, 7.1, 10.6, 12, 14, 17, 20, 23 | Authored/runtime separation, normalized content, fixed point, persistence, and seams |
| 6 | `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | §§2–8, 12, 14–19; M01/M02 contracts; approved M03 contract | IDs, fields, grammar, revision, values, and save boundary |
| 7 | `docs/codex/IMPLEMENTATION_RULES.md` | §§5–6, 10, 13–14, 17–22; M01/M02 concrete notes | GDScript, Resources, determinism, validation, and docs |
| 8 | `docs/codex/TESTING_AND_VALIDATION.md` | §§4, 6–7, 9.1, 12, 15–19; M02 completion; M03 planned package | Test/evidence contract |
| 9 | `docs/codex/OWNER_VERIFICATION_WORKFLOW.md` | §§2–8 | Windows script/log and Inspector checklist |
| 10 | `docs/codex/DECISIONS.md` | `DEC-0009`, `DEC-0011`, `DEC-0014`, `DEC-0017`, `DEC-0025`–`DEC-0032` | Content, persistence, grammar, tests, numeric/source identity, and compatibility |
| 11 | M02 implementation | PR #6; final head `0dd0c1d5c799db45aa4a8387d93750e02b2e485f`; merge `480a9eae2fe0c3591503da56b07c272be74ec027` | Persisted schema and content-revision boundary that M03 integrates |

When sources conflict, follow `AGENTS.md`. Stop and report unresolved conflicts rather than choosing an easy implementation.

## Repository state

| Item | Expected state | Evidence |
|---|---|---|
| Prior milestones | M00, M01, M02 Merged and Passed | `MILESTONES.md`, PRs #4–#6 |
| Test harness | Linux/Windows GUT wrappers and owner-log workflow pass | `tools/test/`, `.gutconfig.json` |
| Numeric foundation | `FixedPoint.SCALE = 1_000_000`; explicit-period accumulation exists | `src/domain/fixed_point.gd` |
| Runtime state | Minimal `GameState` and separate `TimeAuthorityState` | `src/domain/` |
| Persistence | Frozen schema v1, `JSON_V1`, canonical int64, migrations, atomic storage, content-revision string | `src/persistence/` |
| Current content revision | M02 foundation saves use `prototype-m02` | `SaveEnvelope`, fixtures |
| Content implementation | No production catalog, registry, typed game-content Resources, or `content/` definitions | Repository inspection |
| Gameplay implementation | No inventory, Threshold/Reaping runtime, simulation engine, Halls, tutorial, reports, or UI | Repository inspection |
| Addons | GUT 9.7.1 and GodotSteam 4.20 pinned; Steam auto-init disabled | `addons/`, `project.godot` |
| Dry-run scene | Existing temporary scene/assets preserved | `test_main_scene.tscn`, `assets/` |
| Working tree | Clean except for task changes | `git status --short` |

If this baseline is materially wrong, stop before overwriting newer work.

## Dependencies

| Dependency or gate | Required state | Required before | Verification |
|---|---|---|---|
| M02 | Merged and Passed | Implementation | `MILESTONES.md`, PR #6, current persistence tests |
| `GATE-SAVE-SCHEMA` | Satisfied | Implementation | M02 completion record |
| `DEC-0029`–`DEC-0032` | Accepted | Implementation | `DECISIONS.md` |
| Godot 4.7 / GUT 9.7.1 | Pinned and passing | PR | canonical wrappers |
| Windows owner environment | Can run Godot console and inspect `.tres` files | Merge | owner log plus checklist |
| `GATE-CONTENT-CATALOG` | All catalog, revision, Linux, Windows, and Inspector criteria passed | Merge | tests, trace, owner evidence |

## Scope

Implement only the following:

1. Add typed custom `Resource` classes for the current prototype definitions and bounded supporting subresources.
2. Add one explicit root `ContentCatalog` at `content/prototype_content_catalog.tres`.
3. Add a first-class `output_channels` catalog group and the six approved `CHANNEL_...` definitions.
4. Add one `CoreTerminologyDefinition` with the twenty required `TERM_...` entries.
5. Add editable fallback names/descriptions and optional localization keys; preserve stable inline Trait IDs for Old Drill and Unclosed Ledger.
6. Add `ContentRegistry` with structural validation, production-completeness validation, deterministic normalization, canonical lookup, and content-revision compatibility.
7. Keep source Resources immutable during play by copying normalized values into private runtime records; do not expose source Resources as mutable authority.
8. Aggregate useful validation errors in one pass where safe. A catalog with any error must not become ready or partially queryable.
9. Normalize editor-authored finite decimals through one centralized FixedPoint conversion path into signed-64-bit integer subunits: finite/range validation, multiply by `SCALE`, deterministic nearest-subunit integer rounding, and no retained authoritative float.
10. Normalize all rates as integer `rate_subunits_per_period` plus positive `period_msec`; keep periods stable within a content revision.
11. Implement the finite modifier/condition/target-scope grammar in this prompt as data contracts and validators only.
12. Implement the finite progression-effect grammar needed to express current grants, top-ups, unlocks, Writ transitions, tether changes, resonances, and presentation/world flags. Do not execute gameplay effects in M03.
13. Author all required production definitions and exact canonical IDs listed below.
14. Author current prototype scaffold values listed below as editable `.tres` data.
15. Implement exact content-revision compatibility under `DEC-0029`.
16. Remove silent content-revision defaults from normal save creation: callers must pass a non-empty revision explicitly. Persistence remains content-agnostic.
17. Add a content-layer compatibility check for loaded save revisions. Do not make `SaveService` import content code.
18. Add tests for valid catalog, invalid matrices, deterministic ordering, source isolation, normalized values, content revision, and save compatibility.
19. Add a headless M03 trace.
20. Add the M03 owner PowerShell package and Inspector checklist.
21. Update only maintained docs made inaccurate by the implementation.

Use the smallest clear Resource/class split. Do not build a general-purpose data language.

## Non-goals

Do not implement or refactor:

1. Production modifier evaluation or progression-effect application.
2. Inventory, Forms runtime, Threshold runtime, Reapings, dispatch, output accumulation, acquisition progress, reports, forecasts, Halls, tutorial control, or narrative playback.
3. Schema-v2, new gameplay save keys, migrations for gameplay state, or serialization of catalog definitions/effective rates/ETAs.
4. Player-facing content browsers, Soulweave, map, Threshold cards, save UI, or application shell.
5. Functional Forms beyond Man-at-Arms and Scribe, any Form Art behavior, Denizen Souls, future Calling Souls, extra regions, Retinues, Writs, Halls, recipes, or Recollections.
6. Final costs, rates, coefficients, narrative text, art, translation pipeline/content, audio, or accessibility implementation. Optional localization keys and fallback text are in scope.
7. Arbitrary expression strings, script callbacks, Callables, dynamically loaded behavior scripts, or recursive directory discovery.
8. Steam initialization, network access, dependencies, plugin upgrades, autoloads, renderer/engine changes, GitHub Actions, or broad cleanup.

## Required behavior

| ID | Required behavior | Source trace |
|---|---|---|
| `RB-01` | Every production definition is a typed custom Godot `Resource` saved as text `.tres`. | `DEC-0009`; data contract §2 |
| `RB-02` | One explicit `ContentCatalog` references every production definition; no authoritative recursive scanning occurs. | `DEC-0009` |
| `RB-03` | The catalog declares `content_revision = "prototype-content-r1"` and exact compatible revisions `prototype-content-r1`, `prototype-m02`. | `DEC-0029` |
| `RB-04` | Current revision is non-empty, included once in the compatibility list, and the list is canonical/duplicate-free. | `DEC-0029` |
| `RB-05` | Registry construction is all-or-nothing; invalid content exposes diagnostics but no ready normalized registry. | Architecture/data validation |
| `RB-06` | Every top-level ID is globally unique, uppercase ASCII, correctly prefixed, stable, and independent of filename/display name. | Data contract §3 |
| `RB-07` | All references resolve to the correct definition type; errors identify path, ID, field, expected type, and reason. | Data contract §16 |
| `RB-08` | Catalog groups and registry iteration are deterministic by canonical ID, never filesystem or dictionary insertion order. | `DEC-0009`, `DEC-0010` |
| `RB-09` | Registry runtime records are independent of source Resource mutation after load. | Architecture §5 |
| `RB-10` | Finite authored floats normalize once to `FixedPoint.SCALE` using one documented rule; normalized authority contains no floats. | `DEC-0026` |
| `RB-11` | Negative, non-finite, or overflowing authored values fail without a partial registry; sub-subunit authored precision follows the single documented rounding rule. | Fixed-point/content validation |
| `RB-12` | Every rate has a positive explicit period; normalized rate is integer subunits per period. | `DEC-0026` |
| `RB-13` | Ordinary modifiers do not alter a channel's normalized period within one revision. | `DEC-0028` |
| `RB-14` | Output channels are first-class `CHANNEL_...` definitions with source Threshold and output item references. | `DEC-0030` |
| `RB-15` | Threshold-to-channel ownership is bidirectionally validated; backlog and Mastery are not item channels. | `DEC-0030` |
| `RB-16` | Acquisition-progress display metadata is valid only for positive-rate whole-item channels; Unknown state may hide it until identification. | `DEC-0027`; data contract §7.5 |
| `RB-17` | Modifier data accepts only approved metrics, operations, scopes, and conditions. | `DEC-0014` |
| `RB-18` | Progression effects accept only approved finite effect kinds and required typed operands. | `DEC-0014` |
| `RB-19` | Content contains no arbitrary executable expression, Callable, or script path. | `DEC-0014` |
| `RB-20` | Man-at-Arms and Scribe are distinguishable from data without display-name checks. | Prototype §7.2 |
| `RB-21` | Man-at-Arms has Old Drill modifiers and Martial / Martial-or-Logistics slots. | Prototype §7.2 |
| `RB-22` | Scribe has Unclosed Ledger modifiers and Specialist / Logistics-or-Extraction slots. | Prototype §7.2 |
| `RB-23` | Soldier Company requires exactly twelve Soldier Souls and contains only provisional centralized modifiers/support fields. | Prototype §7.3 |
| `RB-24` | Gloamwood and Broken Watch use the approved tags, backlogs, and channel references. | Prototype §§7.4–7.5 |
| `RB-25` | Emergency Writ references the 1,000 milestone and Standard transition; Standard has no automatic transition. | Prototype §7.7; `DEC-0002` |
| `RB-26` | Archive, Larder, and the single recipe use configurable costs/target/rate and valid references. | Prototype §§7.6; P90-B10 |
| `RB-27` | Five Recollections are present; first two unlock features, three optional nodes contain provisional data. | Prototype §7.6 |
| `RB-28` | Six milestones use exact IDs/triggers/prerequisites/references and distinguish 5,000/10,000 resonances. | Data contract §5.2; `DEC-0003`, `DEC-0005` |
| `RB-29` | Six guarantees express fixed/derived floors without executing them. | Data contract §5.3; P90-G02–G05 |
| `RB-30` | Two resonance definitions exist with distinct IDs and effect metadata. | `DEC-0003` |
| `RB-31` | All fourteen tutorial-state definitions exist exactly once and own presentation metadata only. | Prototype §9; `DEC-0015` |
| `RB-32` | Five narrative identity definitions exist without final dialogue implementation. | Data contract §5.5 |
| `RB-33` | All provisional values are exported content fields or bounded subresources, never literals in UI/tutorial/persistence. | Project brief; `AGENTS.md` |
| `RB-34` | Registry missing-ID lookups return typed errors/empty option semantics rather than crashes or mutable placeholders. | Architecture/query safety |
| `RB-35` | New saves receive current revision explicitly; no normal persistence API silently defaults it. | `DEC-0029` |
| `RB-36` | `prototype-m02` validates as compatible and an unknown revision is rejected before simulation. | `DEC-0029` |
| `RB-37` | Save schema version/key set remain unchanged and no immutable definition data is serialized. | `DEC-0011`, M02 contract |
| `RB-38` | `SaveService` and codec do not import or own content compatibility. | Architecture dependency rule |
| `RB-39` | Authoritative definition changes require a new content revision; presentation-only asset swaps do not by themselves. | `DEC-0029` |
| `RB-40` | Trace, Windows script, and Inspector checklist expose the required developer-visible demonstration. | M03 milestone / owner workflow |
| `RB-41` | All named content uses stable IDs plus editable fallback names/descriptions and optional localization keys; display text is never a logic/save key. | `DEC-0031` |
| `RB-42` | `TRAIT_OLD_DRILL` and `TRAIT_UNCLOSED_LEDGER` remain stable when their displayed names change; modifiers remain keyed by identity/data. | `DEC-0031` |
| `RB-43` | One terminology catalog contains all twenty required `TERM_...` entries and registry term lookup is deterministic/immutable. | `DEC-0031` |
| `RB-44` | Changing `TERM_THRESHOLD` changes resolved player-facing text without renaming `THR_...`, changing mechanics, or invalidating a compatible save. | `DEC-0031` |
| `RB-45` | Production content uses `RES_ESSENCE`, `CHANNEL_GLOAMWOOD_ESSENCE`, `CHANNEL_BROKEN_WATCH_ESSENCE`, and `TERM_ESSENCE`; deprecated identities/text are rejected. | `DEC-0032` |

## State transitions

| ID | Initial state | Trigger | Required resulting state | Failure/recovery | Persistence/effect |
|---|---|---|---|---|---|
| `ST-01` | Unloaded valid production catalog | Build registry | Ready registry with deterministic normalized records | Any error prevents Ready | No player state mutation |
| `ST-02` | Valid catalog copy | Duplicate one ID | Build fails with `CONTENT_ID_DUPLICATE` and both paths | Source remains unchanged | None |
| `ST-03` | Valid catalog copy | Replace reference with missing/wrong-type ID | Build fails with field-level reference error | No placeholder record | None |
| `ST-04` | Ready registry | Mutate original Resource value | Registry value remains unchanged | Rebuild required to adopt edit | None |
| `ST-05` | Finite authored decimal | Normalize | Exact fixed-point integer and source trace | Invalid/overflow fails | None |
| `ST-06` | Valid long-horizon channel | Normalize | Positive rate subunits, stable period, valid display metadata | Invalid combination rejected | Future M04 state uses ID |
| `ST-07` | M02 save with `prototype-m02` | Compatibility check | Accepted | Schema/runtime unchanged | Load may continue |
| `ST-08` | Save with current revision | Compatibility check | Accepted | — | Load may continue |
| `ST-09` | Save with unknown revision | Compatibility check | Rejected with stable diagnostic | File preserved; no simulation | No rewrite |
| `ST-10` | New M01 runtime snapshot request | Supply registry current revision | Snapshot stores `prototype-content-r1` | Missing revision fails | Schema remains v1 |
| `ST-11` | Baseline fixture catalog | Change one provisional rate in Resource | Rebuild yields changed normalized rate | Old registry unchanged | Revision-policy warning/test applies |
| `ST-12` | Catalog missing required production ID | Production completeness validation | Build fails listing missing ID | Structural fixture validation may still be tested separately | None |
| `ST-13` | Same valid catalog loaded twice | Build twice | Same ordered IDs and normalized values | Difference fails test | None |
| `ST-14` | Owner branch at PR head | Run script/checklist | Complete log plus explicit Inspector result | Any failed/pending merge gate keeps Partial | No gameplay save created |
| `ST-15` | Valid Form/Recollection fixture | Change fallback display name and rebuild registry | New text appears; canonical IDs and normalized mechanics are unchanged | Empty/invalid text rejected | No save migration |
| `ST-16` | Valid terminology fixture | Change `TERM_THRESHOLD` fallback to another term and rebuild | Term lookup changes; `THR_...` IDs, revision compatibility, and references remain unchanged | Missing/duplicate term rejected | No save rewrite |

## Data and content

### Catalog and count contract

Production root:

```text
content/prototype_content_catalog.tres
```

Current revision and compatibility:

```text
content_revision: prototype-content-r1
compatible_save_revisions:
  - prototype-content-r1
  - prototype-m02
```

The production catalog contains sixty first-class gameplay/content definitions: fifty-four non-channel definitions plus six output channels. It also references one core terminology Resource containing twenty `TERM_...` entries. The two prototype Trait IDs are stable inline Form identities and do not add top-level definition files.

### Required IDs

#### Forms

```text
FORM_MAN_AT_ARMS
FORM_SCRIBE
```

#### Items

```text
RES_ESSENCE
RES_PROVISIONS
STORE_RATIONS
SOUL_CALLING_SOLDIER
SOUL_FORM_SCRIBE
SOUL_FORM_MAN_AT_ARMS
```

#### Thresholds and channels

```text
THR_GLOAMWOOD
THR_BROKEN_WATCH
CHANNEL_GLOAMWOOD_ESSENCE
CHANNEL_GLOAMWOOD_SOLDIER_SOULS
CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS
CHANNEL_BROKEN_WATCH_ESSENCE
CHANNEL_BROKEN_WATCH_PROVISIONS
CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS
```

#### Writ, Retinue, Halls, recipe

```text
WRIT_EMERGENCY_FIRST_RETURN
WRIT_STANDARD
RET_SOLDIER_COMPANY
HALL_ARCHIVE
HALL_LARDER
RECIPE_LARDER_PROVISIONS_TO_RATIONS
```

#### Recollections

```text
REC_WEAVE_REMEMBERED
REC_MUSTER_REMEMBERED
REC_QUICKER_RECKONING
REC_NAMES_KEPT
REC_OPEN_LEDGERS
```

#### Milestones

```text
MS_GLOAMWOOD_REAPING_1000
MS_GLOAMWOOD_REAPING_2500
MS_GLOAMWOOD_REAPING_5000
MS_REGION_REAPING_10000
MS_REGION_REAPING_25000
MS_THRESHOLD_FIRST_SETTLEMENT
```

#### Guarantees

```text
GUA_ARCHIVE_WEAVE_COST_FLOOR
GUA_SOLDIER_SOULS_12
GUA_MUSTER_COST_FLOOR
GUA_SCRIBE_SOUL_1
GUA_SCRIBE_AWAKENING_COST_FLOOR
GUA_PROVISIONS_ONBOARDING_FLOOR
```

#### Resonances

```text
RESONANCE_GLOAMWOOD_5000_MINOR
RESONANCE_REGION_10000
```

#### Tutorial states

```text
TUT_00_BOOT
TUT_01_WINDOW
TUT_02_DIRECT_REAP
TUT_03_SOULS_RETURN
TUT_04_FIRST_DISPATCH
TUT_05_ARCHIVE
TUT_06_SOULWEAVE
TUT_07_RETINUE
TUT_08_SCRIBE
TUT_09_SECOND_THRESHOLD
TUT_10_DISCOVERY
TUT_11_LARDER
TUT_12_SEAL_CHOICE
TUT_13_COMPLETE
```

#### Narrative identities

```text
CHAR_DEATH
CHAR_EUSTACE
CHAR_MAN_AT_ARMS
DIALOGUE_OPENING_AWAKENING
DIALOGUE_FOUR_RETURNS_AND_SEALS
```

Do not create separate top-level Trait definitions in M03. Use inline stable identities:

```text
TRAIT_OLD_DRILL
TRAIT_UNCLOSED_LEDGER
```

Their fallback names and optional localization keys are editable Form content. Do not invent a canonical ID for the one-time Reach Through action.

#### Core terminology

```text
TERM_ESSENCE
TERM_FORM
TERM_TRAIT
TERM_ART
TERM_THRESHOLD
TERM_REAPING
TERM_WRIT
TERM_RETINUE
TERM_RECOLLECTION
TERM_HALL
TERM_SOULWEAVE
TERM_MASTERY
TERM_COMMAND_TETHER
TERM_WHOLE_SOUL
TERM_FORM_SOUL
TERM_CALLING_SOUL
TERM_DENIZEN_SOUL
TERM_STORE
TERM_SEAL
TERM_REAPING_REPORT
```

Use current fallback text from `DATA_AND_CONTENT_CONTRACTS.md`. These strings are editable presentation data; `TERM_...` keys are stable.

### Approved grammar tokens

Metrics:

```text
SOULS_RETURNED_RATE
ESSENCE_YIELD
MASTERY_RATE
DISCOVERY_RATE
FORECAST_UNCERTAINTY
RETINUE_CONTRIBUTION
SUPPORT_CONSUMPTION
SETTLED_OUTPUT
OUTPUT_CHANNEL_RATE
```

Operations:

```text
ADD
MULTIPLY
OVERRIDE
```

Target scopes:

```text
REAPING_TOTAL
RETINUE_OWN_CONTRIBUTION
OUTPUT_CHANNEL
FORECAST_ONLY
```

Conditions:

```text
ALWAYS
THRESHOLD_HAS_ANY_TAG
RETINUE_CATEGORY
OUTPUT_ITEM
OUTPUT_KIND
SUPPORT_STATE
THRESHOLD_LIFECYCLE
```

Tags/categories used now:

```text
TAG_FOREST
TAG_SETTLEMENT
TAG_ROAD
TAG_MARTIAL
MARTIAL
LOGISTICS
SPECIALIST
EXTRACTION
```

Progression-effect kinds must be finite and sufficient for:

```text
GRANT_ITEMS
TOP_UP_ITEM
TOP_UP_DERIVED_COST_FLOOR
UNLOCK_FEATURE
UNLOCK_THRESHOLD
ADD_COMMAND_TETHERS
RECORD_RESONANCE
TRANSITION_WRIT
EXPOSE_RECOLLECTIONS
SET_WORLD_FLAG
QUEUE_PRESENTATION_EVENT
```

Do not execute these effects in M03.

### Approved M03 scaffold values

Implement the exact configurable values in the approved M03 contract of `DATA_AND_CONTENT_CONTRACTS.md`, including:

- base one returned soul/second and one Mastery/minute;
- sixty-second prototype cycle;
- `0.25` Settled multiplier;
- Essence one/10 seconds;
- Soldier Soul one/5 minutes;
- Scribe Form Soul one/8 hours;
- Provisions one/30 seconds;
- Man-at-Arms Form Soul one/24 hours;
- current discovery thresholds, awakening/restoration/recollection costs, Ration recipe/support values, optional effects, resonance reward, and onboarding buffer;
- Man-at-Arms, Scribe, and Soldier Company modifiers from the prototype source.

Every value is prototype scaffold. Tests must locate it through registry data, not duplicate it as an unrelated hard-coded gameplay formula.

## UI and presentation

No player-facing UI is required.

| Surface | Required developer presentation | Deferred |
|---|---|---|
| Godot Inspector | Typed exported fields, clear categories/tooltips where practical, Resource references, editable provisional values, editable entity names, optional localization keys, and core terminology entries | Final content-authoring plugin, translation pipeline/content, custom Inspector |
| Headless trace | Revision, compatibility, counts, canonical IDs, representative normalized values, invalid diagnostic, override result | Gameplay presentation |
| Owner checklist | Exact representative `.tres` paths and expected Inspector fields | Visual polish or in-game screens |

Do not make editor-only presentation authoritative.

## Architecture constraints

- Authored Resources are immutable definition sources; runtime registry data is normalized and isolated.
- Mutable player state is not stored in Resources.
- Registry validation and normalization require no scene tree.
- Persistence receives a revision string but does not import content or serialize definitions.
- Schema version remains 1; no new gameplay save fields are authorized.
- One centralized conversion path produces FixedPoint integers. No subsystem creates another scale.
- Channel period is stable within a content revision; live modifiers are future runtime numerator/multiplier inputs.
- Validation never executes content-provided code.
- Display names, descriptions, and terminology are presentation data; canonical IDs remain the only mechanical/save references.
- Shared labels resolve through `TERM_...`; internal prefixes do not change when displayed terminology changes.
- Essence uses only the accepted item/channel/term identities.
- Missing or invalid content prevents gameplay startup; it is not silently replaced.
- Do not add autoloads, dependencies, arbitrary reflection serializers, recursive content scanning, Steam, or network access.

## Expected files

This is an informed expectation, not permission for unrelated edits.

| Path or area | Expected action | Purpose |
|---|---|---|
| `src/content/definitions/*.gd` | Add | Typed definition and bounded subresource classes |
| `src/content/content_catalog.gd` | Add | Explicit production catalog Resource |
| `src/content/content_registry.gd` | Add | Validation, normalization, lookup, compatibility |
| `src/content/content_validation_result.gd` or equivalent | Add | Aggregated typed diagnostics |
| `src/content/normalized/` or equivalent | Add as needed | Source-isolated runtime records |
| `content/prototype_content_catalog.tres` | Add | Root production catalog |
| `content/forms/`, `items/`, `thresholds/`, `channels/`, `terminology/`, `writs/`, `retinues/`, `halls/`, `recollections/`, `progression/`, `tutorial/`, `narrative/` | Add first real files only | Authored definitions |
| `tests/unit/content/` | Add | Validation and normalization matrices |
| `tests/integration/content/` | Add | Production catalog/save compatibility/import tests |
| `tests/fixtures/content/` | Add only useful fixtures | Invalid/override examples |
| `tools/test/m03/m03_content_catalog_trace.gd` | Add | Developer demonstration |
| `tools/test/owner/run_m03_owner_verification.ps1` | Add | One-command Windows automated evidence |
| `docs/codex/owner-checklists/M03-owner-verification.md` | Add | Inspector evidence |
| `src/persistence/save_schema_mapper.gd`, `save_service.gd`, constants/tests | Modify narrowly | Require explicit revision and prove compatibility boundary |
| `README.md` and maintained docs | Modify as required | Content authoring, commands, status, contracts |

Do not create empty directories.

## Acceptance criteria

| ID | Pass condition | Verification evidence | Merge gate? |
|---|---|---|---:|
| `AC-01` | All production definitions are typed text Resources referenced by one explicit root catalog. | Resource/import tests and Inspector checklist | Yes |
| `AC-02` | Production catalog contains all sixty required gameplay/content definitions exactly once plus one terminology Resource containing twenty required term entries. | Completeness test and trace counts | Yes |
| `AC-03` | No authoritative directory scanning, filename ID inference, or display-name keying exists. | Source-ownership test/review | Yes |
| `AC-04` | Global ID uniqueness, prefix, uppercase format, and type ownership pass. | ID matrix | Yes |
| `AC-05` | Missing and wrong-type references report actionable field-level diagnostics. | Negative matrix | Yes |
| `AC-06` | Registry ordering is canonical and identical across repeated builds. | Stable-order tests/trace | Yes |
| `AC-07` | A source Resource mutation after build does not change normalized registry data. | Mutation-isolation test | Yes |
| `AC-08` | Authored decimal normalization produces expected fixed-point integers and rejects invalid/overflow values. | Normalization matrix | Yes |
| `AC-09` | Normalized authoritative values contain no floats. | Recursive normalized-data assertion | Yes |
| `AC-10` | Every channel uses positive explicit period and valid fixed-point rate; periods remain baseline content. | Channel validation tests | Yes |
| `AC-11` | Six exact `CHANNEL_...` IDs have correct Threshold/item ownership. | Production catalog test | Yes |
| `AC-12` | Progress-display flags reject non-whole, zero-rate, or otherwise invalid combinations. | Negative tests | Yes |
| `AC-13` | Modifier metric/operation/scope/condition tokens reject unsupported values. | Grammar matrix | Yes |
| `AC-14` | Progression effects reject unsupported kinds and missing/wrong-type operands. | Effect matrix | Yes |
| `AC-15` | No content Resource contains arbitrary expression, Callable, or executable script-path fields. | Source/definition audit test | Yes |
| `AC-16` | Man-at-Arms and Scribe normalized data reflects required distinct Traits, slots, and effects without name branches. | Form data tests | Yes |
| `AC-17` | Soldier Company requires exactly twelve Soldier Souls and has valid support/effect data. | Retinue tests | Yes |
| `AC-18` | Gloamwood/Broken Watch definitions, tags, backlogs, channels, and disclosure data match the approved contract. | Threshold tests | Yes |
| `AC-19` | Writ, Hall, recipe, Recollection, milestone, guarantee, resonance, tutorial, and narrative groups match required IDs/references. | Group tests | Yes |
| `AC-20` | All fourteen tutorial states exist once and contain presentation metadata only. | Tutorial content audit | Yes |
| `AC-21` | Current/compatible revision list is exact, canonical, duplicate-free, and includes current. | Revision-policy tests | Yes |
| `AC-22` | M02 save revision `prototype-m02` is accepted; unknown revision is rejected before simulation. | Integration test and trace | Yes |
| `AC-23` | New save snapshot receives `prototype-content-r1` explicitly; no silent persistence default remains. | Persistence API/test review | Yes |
| `AC-24` | Schema version/key set remains v1 and no immutable definition/effective-rate data enters saves. | Fixture/diff test | Yes |
| `AC-25` | Provisional values are stored in content Resources and the override fixture changes normalized output without code edits. | Trace and Inspector checklist | Yes |
| `AC-26` | Invalid catalogs never expose a partially ready registry; diagnostics aggregate safely. | Multi-error test | Yes |
| `AC-27` | Headless trace prints every required demonstration and exits `0`. | Trace output | Yes |
| `AC-28` | Linux focused and full suites pass with no parser/resource errors. | Codex commands | Yes |
| `AC-29` | Owner Windows script passes full/focused/import/trace/full and produces one complete log. | Explicit owner log | Yes |
| `AC-30` | Owner Inspector checklist passes on the tested PR head. | Explicit owner checklist result | Yes |
| `AC-31` | Changed non-trivial GDScript follows junior-reader documentation rules. | Code review | Yes |
| `AC-32` | No gameplay implementation, new dependency, private path, generated log, or unrelated refactor is introduced; maintained docs are synchronized. | Diff/status review | Yes |
| `AC-33` | Renaming Unclosed Ledger and a Recollection in a fixture changes only resolved text; IDs, modifiers, references, and compatibility remain unchanged. | Naming-isolation tests and trace | Yes |
| `AC-34` | All twenty `TERM_...` entries load once; changing `TERM_THRESHOLD` changes resolved text without changing `THR_...` IDs or save compatibility. | Terminology tests, trace, Inspector checklist | Yes |
| `AC-35` | `RES_ESSENCE`, both approved Essence channels, and `TERM_ESSENCE` are present; deprecated item/channel IDs and alternate production display term are absent/rejected. | Catalog completeness and negative tests | Yes |

Completion rules:

- A criterion is Passed only when its evidence was produced.
- Owner automation and Inspector criteria remain Pending until explicit owner results exist.
- A pending merge gate keeps M03 verification Partial and prevents merge.
- Do not weaken criteria after implementation begins without an owner-approved prompt revision.

## Automated verification

### Codex Cloud or Linux checks

Run in this order:

| Order | Command | Purpose | Required result |
|---:|---|---|---|
| 1 | `git status --short` | Starting worktree | Clean |
| 2 | `./tools/test/run_gut.sh -- -gdir=res://tests/unit/content -gdir=res://tests/integration/content` | Focused M03 suite | All content tests pass; exit `0` |
| 3 | `godot --headless --path . --import` | Import/global classes/Resources | Exit `0`; no errors |
| 4 | `godot --headless --path . -s res://tools/test/m03/m03_content_catalog_trace.gd` | Catalog demonstration | All trace assertions; exit `0` |
| 5 | `./tools/test/run_gut.sh` | Full regression | Exit `0` |
| 6 | source/content-execution ownership test | No scan/name/callback/runtime mutation violations | Pass |
| 7 | fixture/catalog reference validator | Paths and required IDs | Pass |
| 8 | `git diff --check` | Patch sanity | Exit `0` |
| 9 | `git status --short` | Final inventory | Intended files only |

Adapt focused file names only when directory selection cannot express the realized layout. Report the final exact command.

### Negative matrix

At minimum test:

- duplicate global ID;
- empty display name, duplicate/missing `TERM_...` entry, and logic/reference attempts using display text;
- deprecated Essence item/channel identities or alternate production display term;
- lowercase/invalid/wrong-prefix ID;
- missing required production ID;
- missing and wrong-type reference;
- unsupported metric, operation, scope, condition, and effect;
- non-finite, negative, and overflowing authored values plus deterministic sub-subunit rounding;
- zero/negative rate period;
- progress display on invalid output;
- Soldier Company requirement not equal to twelve;
- recipe missing item/Hall or invalid quantities/duration;
- duplicate/missing tutorial state;
- current revision absent from compatibility list;
- duplicate/unknown content revision;
- source mutation after build;
- unknown lookup;
- arbitrary content execution field/source token.

Do not leave temporary modified production Resources in the final diff.

### Owner-run Windows automated checks

Codex must create:

```text
tools/test/owner/run_m03_owner_verification.ps1
```

The script must be Windows PowerShell 5.1 compatible, Git-optional, and follow the standardized complete-log contract. It runs:

1. Godot version validation;
2. full GUT suite before;
3. focused M03 content suite;
4. explicit import;
5. M03 trace;
6. full GUT suite after;
7. artifact/temporary-file check;
8. final summary.

It returns `0` only when all automated checks pass. It lists the Inspector checklist as Pending until the owner supplies the result.

Expected invocation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
    -File .\tools\test\owner\run_m03_owner_verification.ps1 `
    -CommitSha "<PR_HEAD_SHA>"
```

## Manual verification

Codex must create:

```text
docs/codex/owner-checklists/M03-owner-verification.md
```

The checklist must include exact paths and expected fields for:

1. root catalog revision, compatibility, and explicit groups;
2. Man-at-Arms and Scribe, including stable inline Trait IDs, editable Trait names, and optional localization keys;
3. Gloamwood and Broken Watch;
4. one common and both long-horizon channels;
5. Soldier Company;
6. Archive, Larder, and recipe;
7. one early and one optional Recollection, including editable display names independent of `REC_...` IDs;
8. core terminology, including `TERM_THRESHOLD`, `TERM_RECOLLECTION`, and `TERM_ESSENCE`;
9. milestone/guarantee/resonance definitions;
10. tutorial and narrative identity definitions;
11. provisional value/name/term override fixtures;
12. Output/Debugger free of new import/parser/resource errors.

The result block is:

```text
Owner verification: PASS|FAIL — PR head <sha> — M03 Windows automation and Godot Inspector content review — YYYY-MM-DD.
Log: <filename>
Checklist: PASS|FAIL
Observed warnings or failures: <none or concise description>
```

## Save/load verification

M03 changes content compatibility but not schema key spelling.

| Scenario | Setup | Action | Expected result |
|---|---|---|---|
| Legacy foundation revision | Valid M02 v1 snapshot with `prototype-m02` | Schema load then registry compatibility | Accepted |
| Current revision | New snapshot supplied `prototype-content-r1` | Save/load plus compatibility | Accepted exactly |
| Unknown revision | Valid v1 snapshot with unknown content revision | Compatibility check | Rejected; file preserved; no simulation |
| Missing revision input | New save API called without explicit revision | Call/validation | Clear failure; no stale default |
| Immutable definitions | Save current minimal runtime | Inspect snapshot | No definitions, Resource paths, effective rates, ETAs, or catalog blobs |
| Schema stability | Compare fixtures/key set | M03 save round trip | Schema version and key spelling remain v1 |

Do not add gameplay ID fields merely to test future validation. Provide a bounded content-ID lookup/validation seam for M04.

## Documentation updates

| Document | Required update |
|---|---|
| `docs/codex/MILESTONES.md` | Actual M03 implementation/verification state and realized paths |
| `docs/codex/ARCHITECTURE.md` | Realized catalog/registry/normalization/compatibility ownership |
| `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | Exact classes, groups, grammar, IDs, revisions, and scaffold values |
| `docs/codex/IMPLEMENTATION_RULES.md` | Durable Resource-authoring and normalization conventions |
| `docs/codex/TESTING_AND_VALIDATION.md` | Exact focused commands, trace, owner package, checklist |
| `docs/codex/DECISIONS.md` | Ensure `DEC-0029` through `DEC-0032` are Accepted |
| `README.md` | Catalog path, authoring note, commands |
| Design sources | Record Essence terminology and the mutable player-facing naming rule |
| Prompt template / milestone prompts | Do not modify or create future prompts |

Do not mark M03 Merged, Passed, or `GATE-CONTENT-CATALOG` satisfied before those facts are true.

## Stop and ask conditions

Stop before affected work when:

1. M02 is not merged/passed or current persistence differs materially from the baseline.
2. any of `DEC-0029` through `DEC-0032` is not Accepted.
3. Required IDs or prototype rules conflict across authoritative sources.
4. Godot typed Resources cannot express the bounded fields without a new dependency, editor plugin, or arbitrary execution.
5. Exact decimal normalization cannot satisfy `DEC-0026` without changing fixed-point semantics.
6. The sixty-definition production catalog plus terminology Resource cannot fit one reviewable PR without splitting M03.
7. A real final balance value is required rather than an approved scaffold value.
8. Save compatibility would require schema-v2, a migration, or changing M02 transaction semantics.
9. A solution requires recursive scanning, reflection dumping, autoloads, Steam, network access, another language, or dependency changes.
10. Tests expose a pre-existing failure that cannot be isolated within M03.

Do not stop for ordinary class/file organization choices bounded by this prompt. Choose the smallest clear structure and document it.

## Deliverables

- typed Resource classes and supporting finite grammar Resources;
- complete production catalog, sixty gameplay/content definitions, and one twenty-entry terminology Resource;
- stable inline Trait identities with editable names and optional localization keys;
- sole Essence item/channel/term identities with deprecated forms rejected;
- validated normalized `ContentRegistry`;
- explicit revision compatibility and persistence-call integration;
- focused unit/integration tests and fixtures;
- deterministic M03 trace;
- Windows owner script and Inspector checklist;
- synchronized documentation;
- complete changed-file inventory;
- no temporary artifacts, generated logs, private paths, or future milestone behavior.

## Final response format

Use exactly:

### Implementation completed
### Files changed
### Verification
### Assumptions
### Known limitations and risks
### Deferred work
### Suggested next task

Under Verification, separate Linux/Codex results, owner Windows automation, Inspector checklist, and any pending acceptance criteria.
