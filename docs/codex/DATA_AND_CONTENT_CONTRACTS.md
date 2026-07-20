# Death Idle — Data and Content Contracts

**Document role:** Canonical prototype data, runtime-state, ID, and serialization contracts  
**Repository path:** `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`  
**Document status:** Approved architecture contract  
**Revision:** 22  
**Last updated:** 2026-07-19

## 1. Purpose

This document defines the boundary between immutable authored content and mutable authoritative state. It also defines canonical identifier rules, minimum entity fields, save-schema ownership, numeric units, reservations, report events, and validation requirements.

Read it with:

- [Prototype 0–90 Minute Source of Truth](../design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md)
- [Idle Fork Source of Truth](../design/IDLE_FORK_SOURCE_OF_TRUTH.md)
- [Architecture](ARCHITECTURE.md)
- [Implementation Rules](IMPLEMENTATION_RULES.md)
- [Testing and Validation](TESTING_AND_VALIDATION.md)
- [Decision Record](DECISIONS.md)

Where a value is provisional in the design sources, this document specifies where the value belongs; it does not convert it into final balance.

## 2. Core distinction: definition versus state

### 2.1 Content definitions

Content definitions are authored, version-controlled, immutable at runtime, and shared by all saves.

Examples:

- a Form's display name, Trait, slot profile, and base modifiers;
- a Threshold's tags, initial backlog, channels, and Settled Passage multipliers;
- a Retinue's category, anchor Soul, cohort requirement, and support pressure;
- a Hall recipe and target-policy options;
- a milestone trigger and reward bundle;
- a tutorial step's presentation metadata.

Definitions are custom Godot `Resource` types saved as text `.tres` files.

### 2.2 Runtime state

Runtime state is mutable, player-specific, serialized in the save, and never stored back into content Resources.

Examples:

- remaining backlog;
- owned and reserved inventory;
- awakened Forms and Mastery;
- active Reaping assignments;
- Hall activity and production carry;
- discovery progress;
- completed milestones and guarantees;
- tutorial state;
- pending reports.

Runtime state uses typed `RefCounted` GDScript classes and explicit dictionary serialization.

### 2.3 Projection data

Projection data is derived for presentation and is not authoritative.

Examples:

- settlement estimate;
- Stable Runtime;
- an Unknown/Identified/Charted output row;
- before/after forecast comparison;
- available inventory;
- occupied tether count;
- current objective wording.

Projection data is rebuilt from definitions and authoritative state.

## 3. Canonical ID rules

### 3.1 General format

Canonical IDs:

- are uppercase ASCII;
- use underscore separators;
- begin with a type prefix;
- never contain display punctuation or localized text;
- remain stable after a save can reference them;
- are serialized as strings;
- may be held as `StringName` at runtime;
- are never inferred from filenames or display names.

Changing a canonical ID after it appears in a committed save requires a migration.

### 3.2 Approved prefixes

| Prefix | Entity |
|---|---|
| `FORM_` | Form / Soulform |
| `TRAIT_` | Named Trait or inline Trait identity |
| `ART_` | Form Art identity when Arts are introduced |
| `THR_` | Threshold |
| `WRIT_` | Writ |
| `RET_` | Retinue |
| `SOUL_CALLING_` | Calling Soul type |
| `SOUL_FORM_` | Form Soul type |
| `SOUL_DENIZEN_` | Denizen Soul type, deferred |
| `RES_` | General resource or material |
| `STORE_` | Logistics Store |
| `HALL_` | Hall |
| `RECIPE_` | Hall recipe |
| `REC_` | Recollection |
| `MS_` | Runtime milestone definition |
| `GUA_` | Tutorial/progression guarantee |
| `RESONANCE_` | Distinct resonance event |
| `TUT_` | Tutorial state |
| `DIALOGUE_` | Dialogue sequence |
| `CHAR_` | Narrative character record |
| `REPORT_EVENT_` | Reportable event type, when a canonical ID is required |
| `CHANNEL_` | Stable Threshold output-channel/source identity |
| `TERM_` | Shared player-facing system terminology entry |

Requirement labels such as `P90-B04`, `P90-G02`, `P90-AC07`, and `IF-REQ-08` are documentation traceability labels, not runtime IDs.

### 3.3 Stable IDs and editable player-facing language

Canonical IDs are not display strings. Every named definition uses its stable ID for references and saves while exposing editable fallback text. A rename of a Form, Trait, future Art, Denizen, Recollection, or other entity does not change its mechanical identity.

Base naming fields are:

| Field | Type | Rule |
|---|---|---|
| `display_name` | `String` | Required fallback/player-facing text; never a key |
| `localization_key` | `StringName` | Optional until localization is implemented; stable when populated |
| `description` | `String` | Optional fallback descriptive text; never executable logic |
| `description_localization_key` | `StringName` | Optional localized description key |

Shared system nouns use `TERM_...` entries in one `CoreTerminologyDefinition`. Each entry supplies singular and plural fallback text plus optional localization keys. UI labels, glossary headings, and Help surfaces later resolve those keys rather than hard-coding core terms. A player-facing rename does not require renaming persisted prefixes such as `THR_`; changing a canonical ID still requires migration or an approved reset.

Free-form narrative and descriptive prose is not mechanically rewritten from terminology entries. A core-term change requires a reviewed copy pass so grammar and context remain correct. Display-only renames do not by themselves invalidate saves.

## 4. Existing prototype content IDs

The following IDs are fixed by the approved prototype source of truth.

| Type | ID | Display name |
|---|---|---|
| Form | `FORM_MAN_AT_ARMS` | Man-at-Arms |
| Form | `FORM_SCRIBE` | Scribe |
| Retinue | `RET_SOLDIER_COMPANY` | Soldier Company |
| Calling Soul | `SOUL_CALLING_SOLDIER` | Soldier Soul |
| Form Soul | `SOUL_FORM_SCRIBE` | Scribe Form Soul |
| Form Soul | `SOUL_FORM_MAN_AT_ARMS` | Man-at-Arms Form Soul |
| Threshold | `THR_GLOAMWOOD` | Gloamwood Hamlet |
| Threshold | `THR_BROKEN_WATCH` | Broken Watch |
| Hall | `HALL_ARCHIVE` | Archive |
| Hall | `HALL_LARDER` | Larder |
| Resource | `RES_ESSENCE` | Essence |
| Resource | `RES_PROVISIONS` | Provisions |
| Store | `STORE_RATIONS` | Rations |
| Recollection | `REC_WEAVE_REMEMBERED` | The Weave Remembered |
| Recollection | `REC_MUSTER_REMEMBERED` | The Muster Remembered |
| Recollection | `REC_QUICKER_RECKONING` | Quicker Reckoning |
| Recollection | `REC_NAMES_KEPT` | Names Kept |
| Recollection | `REC_OPEN_LEDGERS` | Open Ledgers |
| Writ | `WRIT_EMERGENCY_FIRST_RETURN` | Emergency Writ |
| Writ | `WRIT_STANDARD` | Standard Writ |

## 5. Architecture-introduced prototype IDs

Approval of Phase 6 approves the following internal IDs. They do not create new player-facing content; they give existing source requirements stable runtime identities.

### 5.1 Recipe

| ID | Meaning |
|---|---|
| `RECIPE_LARDER_PROVISIONS_TO_RATIONS` | The prototype Larder conversion from Provisions to Rations |

### 5.2 Milestones

| ID | Trigger |
|---|---|
| `MS_GLOAMWOOD_REAPING_1000` | First 1,000 returns produced by the active Gloamwood Reaping after dispatch |
| `MS_GLOAMWOOD_REAPING_2500` | First 2,500 persistent Gloamwood Reaping returns |
| `MS_GLOAMWOOD_REAPING_5000` | First 5,000 persistent Gloamwood Reaping returns, with Scribe awakened for the resonance transition |
| `MS_REGION_REAPING_10000` | First 10,000 persistent Reaping returns summed across the prototype region |
| `MS_REGION_REAPING_25000` | First 25,000 persistent Reaping returns summed across the prototype region |
| `MS_THRESHOLD_FIRST_SETTLEMENT` | First Standing Threshold backlog reaches zero |

The scripted opening four are excluded from every `*_REAPING_*` counter.

### 5.3 Guarantees

| ID | Contract |
|---|---|
| `GUA_ARCHIVE_WEAVE_COST_FLOOR` | Ensure available Essence covers the remaining mandatory Archive restoration and The Weave Remembered costs when that guided step becomes actionable; derive the amount from configured content and current completion state |
| `GUA_SOLDIER_SOULS_12` | Ensure at least twelve owned Soldier Souls at the 1,000-return milestone, granting only the missing amount |
| `GUA_MUSTER_COST_FLOOR` | Ensure available Essence covers the remaining mandatory The Muster Remembered cost before Retinue assignment is required |
| `GUA_SCRIBE_SOUL_1` | Ensure at least one Scribe Form Soul at the 2,500-return milestone, granting nothing if already satisfied |
| `GUA_SCRIBE_AWAKENING_COST_FLOOR` | Ensure available Essence covers the configured Scribe awakening cost while leaving the Awaken command to the player |
| `GUA_PROVISIONS_ONBOARDING_FLOOR` | Ensure the derived Provisions floor after identification: Larder restoration + one Ration batch + configured buffer |

The four-soul opening is a one-time scripted transaction, not an inventory-floor guarantee.

### 5.4 Resonances

| ID | Contract |
|---|---|
| `RESONANCE_GLOAMWOOD_5000_MINOR` | Minor first resonance; reveal/enable Broken Watch and grant command tether 2 exactly once |
| `RESONANCE_REGION_10000` | Separate regional resonance; grant the configured Essence bundle and expose the optional Recollection choice exactly once |

### 5.5 Narrative identities

The following IDs are recommended when narrative data first requires them:

| ID | Meaning |
|---|---|
| `CHAR_DEATH` | Death |
| `CHAR_EUSTACE` | Eustace |
| `CHAR_MAN_AT_ARMS` | The first branded Man-at-Arms character |
| `DIALOGUE_OPENING_AWAKENING` | Opening monologue sequence |
| `DIALOGUE_FOUR_RETURNS_AND_SEALS` | Eustace, chains, seals, and Brand sequence |

They need not be created until their first implementation milestone.

### 5.6 Inline prototype Trait identities

The prototype Forms use stable inline Trait identities with editable names:

| ID | Current display name | Owner |
|---|---|---|
| `TRAIT_OLD_DRILL` | The Old Drill | `FORM_MAN_AT_ARMS` |
| `TRAIT_UNCLOSED_LEDGER` | Unclosed Ledger | `FORM_SCRIBE` |

These are not separate top-level definitions in M03. The Form definition owns the Trait identity, editable fallback name, optional localization key, description, and modifiers. Logic never checks the displayed Trait name.

### 5.7 M03 output-channel identities

Accepted `DEC-0030` promotes Threshold output sources to first-class catalog definitions:

| ID | Threshold | Output |
|---|---|---|
| `CHANNEL_GLOAMWOOD_ESSENCE` | `THR_GLOAMWOOD` | `RES_ESSENCE` |
| `CHANNEL_GLOAMWOOD_SOLDIER_SOULS` | `THR_GLOAMWOOD` | `SOUL_CALLING_SOLDIER` |
| `CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS` | `THR_GLOAMWOOD` | `SOUL_FORM_SCRIBE` |
| `CHANNEL_BROKEN_WATCH_ESSENCE` | `THR_BROKEN_WATCH` | `RES_ESSENCE` |
| `CHANNEL_BROKEN_WATCH_PROVISIONS` | `THR_BROKEN_WATCH` | `RES_PROVISIONS` |
| `CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS` | `THR_BROKEN_WATCH` | `SOUL_FORM_MAN_AT_ARMS` |

Backlog returns and active Form Mastery are core Reaping streams, not inventory-output channels.

### 5.8 Core terminology identities

M03 adds one terminology catalog containing these stable keys and current fallback terms:

| ID | Singular fallback | Plural fallback |
|---|---|---|
| `TERM_ESSENCE` | Essence | Essence |
| `TERM_FORM` | Form | Forms |
| `TERM_TRAIT` | Trait | Traits |
| `TERM_ART` | Art | Arts |
| `TERM_THRESHOLD` | Threshold | Thresholds |
| `TERM_REAPING` | Reaping | Reapings |
| `TERM_WRIT` | Writ | Writs |
| `TERM_RETINUE` | Retinue | Retinues |
| `TERM_RECOLLECTION` | Recollection | Recollections |
| `TERM_HALL` | Hall | Halls |
| `TERM_SOULWEAVE` | Soulweave | Soulweave |
| `TERM_MASTERY` | Mastery | Mastery |
| `TERM_COMMAND_TETHER` | Command Tether | Command Tethers |
| `TERM_WHOLE_SOUL` | Whole Soul | Whole Souls |
| `TERM_FORM_SOUL` | Form Soul | Form Souls |
| `TERM_CALLING_SOUL` | Calling Soul | Calling Souls |
| `TERM_DENIZEN_SOUL` | Denizen Soul | Denizen Souls |
| `TERM_STORE` | Store | Stores |
| `TERM_SEAL` | Seal | Seals |
| `TERM_REAPING_REPORT` | Reaping Report | Reaping Reports |

The current fallback strings are content, not IDs. `TERM_THRESHOLD` may later display a different word without renaming `THR_...` identifiers or saved references.

## 6. Content catalog contract

The content registry loads one explicit root `ContentCatalog` Resource:

```text
content/prototype_content_catalog.tres
```

The catalog contains a required `content_revision` string, an explicit duplicate-free `compatible_save_revisions` list, and ordered references to the prototype definitions required by the current build. Accepted `DEC-0029` sets the first current revision to `prototype-content-r1` and explicitly permits `prototype-m02` plus the current revision. Compatibility is exact string membership; it is never inferred from revision naming. The revision changes whenever an authoritative definition, normalized value, source ID, or rule reference changes in a way that can affect a save, forecast, test fixture, or simulation result. Presentation-only asset replacement does not require a revision change unless code or content behavior also changes.

Minimum catalog groups:

- Forms;
- Thresholds;
- output channels;
- Writs;
- Retinues;
- Soul/resource/store items;
- Halls;
- recipes;
- Recollections;
- milestones;
- guarantees;
- resonances;
- tutorial presentation definitions;
- narrative identity and dialogue definitions required by the current build;
- one core terminology catalog containing `TERM_...` entries.

The registry does not discover authoritative content by recursively scanning directories. Explicit references make missing content, load order, and test fixtures deterministic.

The catalog validates before a new game or save load proceeds.

## 7. Definition contracts

Definition types may be split into more files as implementation grows. The fields below are the minimum contract, not a requirement to create every class in M00.

### 7.1 Base content definition

Every top-level definition contains:

| Field | Type | Rule |
|---|---|---|
| `id` | `StringName` | Required, unique, correctly prefixed |
| `display_name` | `String` | Editable fallback/player-facing text; never used as a key |
| `localization_key` | `StringName` | Optional localization key; empty until needed |
| `description` | `String` | Optional fallback descriptive text |
| `description_localization_key` | `StringName` | Optional localization key for description |
| `enabled` | `bool` | Allows a definition to be present but intentionally unavailable; default true |
| `notes` | `String` | Optional editor-facing context, not runtime logic |

Optional presentation assets are resource references or `res://` paths validated by the appropriate definition.

#### CoreTerminologyDefinition and TermEntry

One `CoreTerminologyDefinition` contains explicit `TermEntry` subresources. A term entry has:

| Field | Type | Rule |
|---|---|---|
| `id` | `StringName` | Required unique `TERM_...` key |
| `singular_display_name` | `String` | Required fallback singular/current form |
| `plural_display_name` | `String` | Required fallback plural form |
| `singular_localization_key` | `StringName` | Optional |
| `plural_localization_key` | `StringName` | Optional |
| `notes` | `String` | Editor-only guidance |

Term entries are presentation vocabulary, not game-rule switches. The registry exposes immutable term lookups, while free-form prose remains separately authored and reviewed.

### 7.2 FormDefinition

| Field | Type | Prototype rule |
|---|---|---|
| `id` | `StringName` | `FORM_...` |
| `display_name` | `String` | Required |
| `circle` | `int` | Man-at-Arms and Scribe are First Circle |
| `role_summary` | `String` | Concise player-facing identity |
| `trait_id` | `StringName` | Stable inline `TRAIT_...` identity |
| `trait_display_name` | `String` | Editable fallback name; not used by logic |
| `trait_localization_key` | `StringName` | Optional localized Trait-name key |
| `trait_description` | `String` | Editable fallback description |
| `modifiers` | `Array[ModifierDefinition]` | Data-driven Trait effects |
| `retinue_slot_profiles` | array | Ordered slot compatibility definitions |
| `base_values` | typed Resource or fields | Prototype production/discovery inputs |
| `weakness_summary` | `String` | Player-facing trade-off |
| `soul_item_id` | `StringName` | Form Soul used by normal awakening, if applicable |
| `awakening_cost` | cost bundle | Configurable; Man-at-Arms has narrative exception |
| `presentation` | Resource refs | Art/icon/placeholders as available |

Required prototype distinctions:

- `FORM_MAN_AT_ARMS` affects throughput and Martial Retinue synergy.
- `FORM_SCRIBE` affects discovery rate and forecast uncertainty.
- Tutorial UI does not implement these effects itself.

### 7.3 ModifierDefinition

The prototype uses a small shared modifier grammar.

| Field | Type | Rule |
|---|---|---|
| `stat` | enum or `StringName` | One approved target statistic |
| `operation` | enum | Add, multiply, or override; override is exceptional |
| `value` | `float` | Finite editor-authored value; registry normalizes it to central fixed-point units |
| `condition` | condition Resource | Optional tag, category, support, or state condition |
| `source_label` | `String` | Explanation shown in forecast breakdowns |
| `priority` | `int` | Stable ordering inside the central resolver |

Initial statistic targets may include:

- Souls Returned rate;
- Essence yield;
- Mastery rate;
- discovery rate;
- forecast uncertainty;
- Retinue contribution;
- support consumption;
- Settled Passage output.

Do not add a new stat name in one feature script without updating the resolver, validator, tests, and this contract.

The final Soldier Company stacking model remains provisional. The data representation may exist before coefficients are approved, but one central resolver owns the order.

### 7.4 ThresholdDefinition

| Field | Type | Prototype rule |
|---|---|---|
| `id` | `StringName` | `THR_...` |
| `display_name` | `String` | Required |
| `tags` | `Array[StringName]` | Stable tag IDs or approved simple names |
| `initial_backlog` | `int` | Non-negative; Gloamwood 1,000,000, Broken Watch provisional 250,000 |
| `base_production` | typed values | Configurable rate/yield inputs |
| `channel_ids` | `Array[StringName]` | Stable first-class `CHANNEL_...` references owned by this Threshold |
| `settled_channel_ids` | `Array[StringName]` or the same `channel_ids` plus per-channel multiplier | Renewable essential outputs |
| `settlement_multiplier` | `float` | Provisional, positive; normalized by the registry |
| `initial_disclosure` | fields | Which rows are known at unlock |
| `milestone_ids` | array | Ordered relevant milestones |
| `region_id` | `StringName` | Stable grouping when region data is introduced |
| `presentation` | Resource refs | POI, map, icon, placeholder |

A Threshold definition does not contain current backlog, active Form, or discovery progress.

### 7.5 OutputChannelDefinition

| Field | Type | Rule |
|---|---|---|
| `id` | `StringName` | Global canonical `CHANNEL_...` identity; stable once saves may reference it |
| `source_threshold_id` | `StringName` | Owning `THR_...`; must agree with the Threshold reference |
| `output_item_id` | `StringName` | Resource/Soul/Store produced |
| `channel_kind` | enum | Essence, Form Soul, Calling Soul, material, or later Denizen |
| `base_rate_per_period` | `float` | Non-negative authored amount for the declared period; normalized once by the registry |
| `rate_period_msec` | `int` | Positive explicit period; avoids forcing rare rates into integer subunits per second |
| `initial_discovery_state` | enum | Unknown, Identified, or Charted |
| `identified_frequency_label` | `String` | Prototype qualitative label |
| `show_acquisition_progress` | `bool` | True only when a known long-horizon whole-unit source benefits from a Threshold-level progress bar |
| `settled_multiplier` | `float` | Essential channels remain above zero; normalized by the registry |
| `required_for_progression` | `bool` | Enables validation against accidental removal |

Parallel channels do not subtract from one another unless a future approved rule explicitly defines that coupling. Runtime normalization may choose an equivalent internal rate shape, but it must preserve the authored period semantics and `DEC-0026` precision. Within a content revision, the normalized `rate_period_msec` is stable for the channel; ordinary Form, Writ, Retinue, Art, Recollection, support, and lifecycle modifiers alter the effective numerator/multiplier rather than replacing the denominator.

### 7.6 ItemDefinition

Inventory IDs for resources, Stores, Calling Souls, and Form Souls use one small item-definition contract.

| Field | Type | Prototype rule |
|---|---|---|
| `id` | `StringName` | Uses `RES_`, `STORE_`, `SOUL_CALLING_`, or `SOUL_FORM_` |
| `display_name` | `String` | Required player-facing name |
| `item_kind` | enum | Resource/material, Store, Calling Soul, or Form Soul |
| `whole_units_only` | `bool` | True for all prototype inventory items; fractional carries remain in producer state |
| `category_tags` | `Array[StringName]` | Optional classification for UI and validation, not arbitrary behavior |
| `presentation` | fields/resource refs | Icon, description, and ordering metadata as available |

An item definition does not contain the player's owned, reserved, or available amount.

### 7.7 WritDefinition

| Field | Type | Prototype rule |
|---|---|---|
| `id` | `StringName` | `WRIT_...` |
| `display_name` | `String` | Required |
| `modifiers` | array | Centralized production/support modifiers |
| `support_policy` | typed fields | Prototype supports only simple Ration maintenance behavior |
| `fallback_writ_id` | `StringName` | Empty for prototype unless explicitly introduced |
| `objective_milestone_id` | `StringName` | Emergency Writ references `MS_GLOAMWOOD_REAPING_1000` |
| `auto_transition_writ_id` | `StringName` | Emergency transitions to `WRIT_STANDARD` |

### 7.8 RetinueDefinition

| Field | Type | Prototype rule |
|---|---|---|
| `id` | `StringName` | `RET_...` |
| `category` | enum | Soldier Company is Martial |
| `anchor_soul_id` | `StringName` | `SOUL_CALLING_SOLDIER` |
| `required_count` | `int` | Twelve |
| `slot_compatibility` | array | Match Form slot profiles |
| `modifiers` | array | Provisional, central stacking |
| `support_item_id` | `StringName` | `STORE_RATIONS` |
| `support_consumption` | authored `float` | Provisional; normalized by `ContentRegistry` |
| `reduced_effect_floor` | authored `float` | Configurable and normalized; base Reaping still continues |
| `unique` | `bool` | Prototype value as approved by content |

No attrition or service-turnover fields are active in the first-session prototype.

### 7.9 HallDefinition

| Field | Type | Prototype rule |
|---|---|---|
| `id` | `StringName` | `HALL_...` |
| `display_name` | `String` | Required |
| `restore_cost` | cost bundle | Configurable |
| `recipe_ids` | array | Archive may have no production recipe; Larder has one |
| `default_recipe_id` | `StringName` | Larder recipe |
| `default_target` | `int` | Larder target provisional 50 Rations |
| `keeper_policy` | fields | Eustace narrative role only; no optimization system |
| `presentation` | Resource refs | Art/icon/placeholder |

### 7.10 RecipeDefinition

| Field | Type | Prototype rule |
|---|---|---|
| `id` | `StringName` | `RECIPE_...` |
| `input_costs` | item-to-amount map | Provisions cost |
| `output_grants` | item-to-amount map | Rations output |
| `cycle_duration_msec` or authored rate | numeric | Configurable; registry produces one normalized authoritative representation |
| `target_item_id` | `StringName` | Rations for Maintain 50 policy |
| `enabled_hall_ids` | array | Larder |

### 7.11 RecollectionDefinition

| Field | Type | Prototype rule |
|---|---|---|
| `id` | `StringName` | `REC_...` |
| `cost` | cost bundle | Configurable |
| `prerequisite_ids` | array | Explicit |
| `unlock_ids` | array | Screens/systems/content unlocked |
| `modifiers` | array | Optional global effects |
| `repeatable` | `bool` | False for prototype |
| `presentation` | fields | Description/icon/position |

A Recollection rename changes only display/localization fields. `REC_...` remains the rule/save identity.

### 7.12 MilestoneDefinition

| Field | Type | Rule |
|---|---|---|
| `id` | `StringName` | `MS_...` |
| `counter_kind` | enum | Threshold persistent returns, regional persistent returns, settlement, or explicit predicate |
| `subject_ids` | `Array[StringName]` | One Threshold or an explicit set of Thresholds for aggregate counters |
| `target_value` | `int` | Non-negative |
| `prerequisite_ids` | array | Scribe awakening prerequisite at 5,000 is explicit |
| `priority` | `int` | Same-timestamp ordering |
| `reward_bundle` | Resource | Exactly-once grants/unlocks |
| `guarantee_ids` | array | Guarantees evaluated on completion |
| `resonance_id` | `StringName` | Optional |
| `report_metadata` | fields | Presentation description |

### 7.13 GuaranteeDefinition

| Field | Type | Rule |
|---|---|---|
| `id` | `StringName` | `GUA_...` |
| `kind` | enum | Ensure fixed minimum or ensure derived minimum |
| `item_id` | `StringName` | Fixed-minimum target where applicable |
| `minimum_amount` | `int` | Fixed floor where applicable |
| `derived_policy_id` | `StringName` | Used for Provisions floor |
| `completion_policy` | enum | Record once after successful evaluation |
| `source_label` | `String` | Report/debug explanation |

A guarantee grants `max(0, required - current_total)` and never resets inventory.

### 7.14 TutorialStepDefinition

Tutorial definitions own presentation metadata, not core domain rules.

| Field | Type | Rule |
|---|---|---|
| `state_id` | `StringName` | One approved `TUT_...` ID |
| `title` | `String` | Help/presentation text |
| `target_screen_id` | `StringName` | Optional UI destination |
| `highlight_id` | `StringName` | Optional presentation target |
| `help_entry` | text/reference | Concise replayable guidance |
| `blocking` | `bool` | Only one blocking step active |
| `skip_mode` | enum | Narrative-state completion or presentation-only mechanical skip |

Entry conditions and domain completion checks are explicit GDScript functions in `TutorialCoordinator`. Do not create a general expression language for fourteen prototype states.

## 8. Cost and reward bundle contract

Reusable bundles represent item changes and unlocks without embedding presentation logic.

### 8.1 CostBundle

Minimum fields:

- item ID to required amount;
- whether reserved amounts count as spendable, normally false;
- optional owner-secured amount for mandatory onboarding costs;
- player-facing explanation metadata.

Costs validate completely before any amount is consumed.

### 8.2 RewardBundle

Minimum fields:

- item grants;
- unlock IDs;
- tether-capacity delta;
- guarantee IDs;
- resonance ID;
- optional objective/report metadata.

Reward application is atomic and exactly-once when attached to a milestone or purchase.

## 9. Runtime state contracts

Runtime classes use typed fields and explicit `to_save_data()` / `from_save_data()` conversion. Serialization code must not use generic reflection to dump arbitrary object properties.

### 9.1 SaveEnvelope

| Field | Type | Rule |
|---|---|---|
| `schema_version` | runtime `int` | Schema version 1 is the frozen M02 input contract; accepted `DEC-0034` authorizes M04A to make version 2 the current write schema. JSON wire values are canonical decimal strings. |
| `codec_id` | `StringName` | Identifies the byte codec, initially `JSON_V1` |
| `content_revision` | `String` | Identifies the validated content catalog revision used by this snapshot |
| `save_revision` | runtime `int` | Increases on each successful snapshot; JSON wire value is a decimal string |
| `time_authority` | `TimeAuthorityState` | Trusted external anchor and already-credited foreground accounting |
| `last_offline_resolution_id` | `String` | Stable diagnostic/idempotency identity for the last committed offline resolution |
| `game_state` | dictionary | Complete authoritative state |
| `metadata` | dictionary | Minimal diagnostics; no secrets, machine paths, or device-clock values used for progress |

### 9.2 TimeAuthorityState

| Field | Type | Rule |
|---|---|---|
| `trusted_source_id` | `StringName` | Empty before the first trusted sample; production uses stable source ID `STEAM_SERVER_TIME` through the approved GodotSteam 4.20 adapter |
| `has_trusted_anchor` | `bool` | False until a trusted sample establishes the first anchor |
| `trusted_anchor_utc_msec` | runtime `int` | Last accepted external trusted epoch; canonical decimal string in JSON |
| `foreground_credited_since_anchor_msec` | runtime `int` | Non-negative active-session time already simulated since the anchor |
| `pending_trusted_reconciliation` | `bool` | True when the game loaded or resumed without a usable trusted sample |
| `last_sample_diagnostic_code` | `StringName` | Diagnostic only; never changes production by itself |

Rules:

- no authoritative field is populated from the player's local wall clock, timezone, calendar, or file timestamp;
- when `has_trusted_anchor` is false, `trusted_anchor_utc_msec` must be zero and no retroactive closed-session credit is granted before the first trusted sample;
- the M01 runtime currently represents no anchor internally with `trusted_anchor_utc_msec = -1`; the schema mapper must encode that state as `has_trusted_anchor = false`, empty source ID, and canonical wire value `"0"`, then reconstruct the runtime sentinel on load without exposing `-1` as an authoritative wire value;
- a newly accepted trusted sample may not move the anchor backwards;
- `foreground_credited_since_anchor_msec` is reset only in the same successful transaction that commits a new trusted anchor;
- trusted-time source details remain outside domain state; only the normalized sample and accounting state are persisted;
- GodotSteam version, App ID, connection state, and wrapper-specific callback details are diagnostics or configuration, not authoritative save fields;
- changing the binding implementation must not change the meaning of `STEAM_SERVER_TIME` or invalidate otherwise compatible saves.

### 9.3 GameState

The table below is the full prototype direction. Implementation is staged by lettered slices. M04A implements only `simulation_time_msec`, inventory entries/reservations, Form state, Threshold state including acquisition records, Reaping records, and command-tether capacity. Halls, Recollections, story, tutorial, and report history remain deferred and must not be added merely to make the full table exist early.

| Field | Type | Source of truth |
|---|---|---|
| `inventory` | `InventoryState` | All item totals and reservation ledgers |
| `forms` | ID-to-`FormState` | Reveal, awakening, Mastery |
| `thresholds` | ID-to-`ThresholdState` | Knowledge, availability, lifecycle, backlog, persistent returns, discovery |
| `reapings` | Threshold-ID-to-`ReapingState` | Active assignments and carries |
| `halls` | ID-to-`HallState` | Restore, recipe, target, progress |
| `recollections` | set/list of IDs | Purchased nodes |
| `progression` | `ProgressionState` | Tethers, unlocks, milestones, resonances, guarantees |
| `story` | `StoryState` | Opening action, entities, Brand, narrative checkpoints |
| `tutorial` | `TutorialState` | State, completion, skip, Help/presentation checkpoint |
| `report_accumulator` | `ReportAccumulatorState` | Pending already-applied deltas and events |
| `report_history` | ordered list of `ReportSnapshot` | Bounded presentation history; never the source of inventory |
| `simulation_time_msec` | runtime `int` | Monotonic credited gameplay timeline for authoritative event/report ordering |
| `session_playtime_msec` | runtime `int` | Active playtime for local analysis; JSON wire value is a decimal string |

`schema_version`, codec ID, content revision, save revision, and trusted-time accounting belong to the save envelope, not duplicated inside each substate. `simulation_time_msec` belongs to `GameState` and advances only when simulation time is committed.

### 9.4 InventoryState and reservations

Inventory is keyed by item ID.

Each item entry contains:

| Field | Type | Rule |
|---|---|---|
| `total` | `int` | Non-negative |
| `reservations` | reservation-ID-to-amount | Non-negative; sum cannot exceed total |

Derived:

```text
reserved = sum(reservations.values())
available = total - reserved
```

A reservation ID is stable and identifies its owner, for example a Retinue assignment. Do not persist a second independently mutable `reserved_total`.

### 9.5 FormState

| Field | Type | Rule |
|---|---|---|
| `revealed` | `bool` | Presentation/progression visibility |
| `awakened` | `bool` | Exactly-once normal or narrative awakening |
| `mastery_subunits` | `int` | Non-negative central fixed-point units; display Mastery is derived |
| `awakened_by` | `StringName` | Narrative Brand or normal purchase source for diagnostics |

No Art state is required beyond optional locked placeholders.

### 9.6 ThresholdState

| Field | Type | Rule |
|---|---|---|
| `knowledge_state` | enum | `UNKNOWN`, `DETECTED`, or `CHARTED` |
| `availability_state` | enum | `LOCKED` or `AVAILABLE`; separate from knowledge and lifecycle |
| `lifecycle_state` | enum | `OVERDUE` or `SETTLED` |
| `remaining_backlog` | `int` | `0..initial_backlog`; zero requires `SETTLED` after transition processing |
| `persistent_returns_total` | `int` | Returns from authoritative Reapings only; excludes opening four |
| `familiarity_subunits` | `int` | Non-negative central fixed-point units; provisional system |
| `channel_discovery` | channel-ID-to-`DiscoveryChannelState` | Discovery state and progress |
| `channel_acquisition` | channel-ID-to-`ThresholdAcquisitionState` | Durable progress toward whole discrete outputs for channels that use accumulation |

The opening action modifies `remaining_backlog` and story state but does not modify `persistent_returns_total`.

### 9.7 DiscoveryChannelState

| Field | Type | Rule |
|---|---|---|
| `discovery_state` | enum | Unknown, Identified, Charted |
| `progress_subunits` | `int` | Non-negative central fixed-point units |
| `discovery_rate_residual` | `int` | Normalized remainder needed to continue discovery progress exactly across chunking and save/load |
| `total_produced` | `int` | Optional diagnostic/history counter if required by reports |

The inventory total exists independently. A progression-gated source cannot accumulate before Access is unlocked. Unlock atomically identifies the item/currently available source and initializes acquisition at zero; later insight changes neither grant output nor reset accumulated post-unlock work. Discovery/insight progress and acquisition progress remain separate state.

### 9.8 ThresholdAcquisitionState

A Threshold stores one acquisition record for each discrete output channel that can accumulate partial progress toward a whole item.

| Field | Type | Rule |
|---|---|---|
| `progress_subunits` | `int` | `0 <= value < FixedPoint.SCALE`; normalized completed work toward the next whole unit |
| `rate_carry` | typed integer carry/result state | Finer-than-subunit arithmetic remainder with an explicit denominator and one owner; it preserves exact accumulation but does not encode a prior effective rate |
| `total_banked_units` | `int` | Optional non-negative diagnostic/report counter; inventory remains the ownership source of truth |

Rules:

- the record is keyed by stable Threshold ID and output channel/source ID;
- Form, Writ, Retinue, or assignment revisions do not clear it;
- the old setup is resolved to the command or unlock timestamp before the future rate changes;
- an effective rate is derived from immutable channel baseline data plus current modifiers for each applicable segment; it is never derived from a previous effective rate;
- ordinary modifier changes do not rescale `progress_subunits` or `rate_carry` and cannot compound through repeated recall/redispatch; the carry remains valid because the channel's normalized period/denominator is stable within the content revision;
- inactive Thresholds retain but do not advance the record;
- Overdue-to-Settled transition retains it when the source remains available;
- crossing one or more whole-unit boundaries banks those whole units immediately and retains only the remainder;
- the same progress/carry cannot also be stored in `ReapingState`;
- effective rate, remaining duration, and display percentage are derived and are not persisted in this record;
- a locked progression-gated source has no record and no progress; once initialized, later disclosure or insight changes do not stop, erase, or rebase it;
- a progress increase, if ever approved, is an explicit exactly-once progression grant rather than pre-unlock backfill or a rate modifier.

### 9.9 ReapingState

| Field | Type | Rule |
|---|---|---|
| `threshold_id` | `StringName` | Key and reference must agree |
| `is_active` | `bool` | Active records occupy one tether; inactive records retain assignment continuity without producing |
| `form_id` | `StringName` | Must be awakened and valid when active |
| `writ_id` | `StringName` | Must be available |
| `retinue_ids` | ordered array | Must match reservations and slots |
| `assignment_revision` | `int` | Increments after each committed configuration change |
| `cycle_phase_msec` | `int` | Presentation/runtime continuity; normalized integer milliseconds |
| `completed_cycle_count` | `int` | Optional persisted diagnostic/trigger count where required |
| `flow_residuals` | flow-ID-to-residual data | Sole owner for backlog, Essence, Mastery, cycle, and support flows that are operation-scoped; durable Threshold-source acquisition progress is excluded and belongs to `ThresholdAcquisitionState` |
| `support_buffer_amounts` | item-ID-to-int | Per-Reaping allocated/support amount where the Writ uses a buffer |
| `active_fallback_id` | `StringName` | Empty in the prototype unless an approved fallback is active |
| `support_state` | enum | Full, low, depleted/reduced as implemented |
| `started_simulation_msec` | `int` | Immutable first-successful-dispatch timestamp for the Threshold-scoped Reaping operation; `0` is valid and record existence is the initialization fact |
| `last_configuration_change_simulation_msec` | `int` | Most recent successful dispatch, recall, redispatch, or later approved configuration change |

There is one global trusted-time accounting record in the save envelope and one `simulation_time_msec` in `GameState`. Per-Reaping wall-clock or trusted-time cursors must not independently drift.

### 9.10 HallState

| Field | Type | Rule |
|---|---|---|
| `restored` | `bool` | Exactly-once restoration |
| `active` | `bool` | Production enabled when rules permit |
| `active_recipe_id` | `StringName` | Must belong to Hall |
| `target_amount` | `int` | Non-negative; Larder starts with configurable 50 |
| `production_phase_msec` | `int` | Runtime continuity if cycle-based |
| `flow_residuals` | flow-ID-to-residual data | The sole persisted remainder owner for Hall input, output, and cycle/rate flows |

### 9.11 ProgressionState

| Field | Type | Rule |
|---|---|---|
| `command_tether_capacity` | `int` | Starts at one, becomes two once |
| `unlocked_ids` | set/list | Stable IDs only |
| `completed_milestone_ids` | set/list | Exactly-once |
| `applied_reward_ids` | set/list | Prevent repeated reward application |
| `completed_guarantee_ids` | set/list | Idempotency and diagnostics |
| `completed_resonance_ids` | set/list | Separate 5,000 and 10,000 events |

A milestone completion flag and its reward-completion flag are distinct enough to recover safely if a future migration or interrupted transaction requires diagnosis. The atomic snapshot normally commits them together.

### 9.12 StoryState

Minimum fields as required by milestones:

- opening direct-action completed;
- `scripted_returns_total` equal to four after the direct action;
- opening four entities created/recorded;
- Eustace available;
- Man-at-Arms narrative character available;
- damaged rat/wolf outcome committed;
- Brand applied;
- Sanctum/window reveal state;
- active narrative sequence ID and checkpoint when resume is required.

### 9.13 TutorialState

| Field | Type | Rule |
|---|---|---|
| `current_state_id` | `StringName` | One approved `TUT_...` ID |
| `completed_state_ids` | set/list | Supports early completion and replay distinction |
| `skipped_presentation_ids` | set/list | Presentation-only skip record |
| `help_entry_ids` | set/list | Reconstruct available Help guidance |
| `dialogue_checkpoint` | fields | Sequence and line/cue as needed |
| `dismissed_notice_ids` | set/list | Optional; pending notices are otherwise derived |

Do not duplicate resource totals, Form awakening, Hall activity, or milestone completion inside tutorial state.

### 9.14 ReportAccumulatorState

| Field | Type | Rule |
|---|---|---|
| `window_started_simulation_msec` | runtime `int` | Start of accumulated report period on the simulation timeline |
| `last_event_simulation_msec` | runtime `int` | Authoritative ordering/summary on the simulation timeline |
| `souls_by_threshold` | ID-to-int | Already banked |
| `backlog_reduction_by_threshold` | ID-to-int | Already applied |
| `resource_deltas` | item-ID-to-int | Already applied whole-unit inventory changes |
| `mastery_delta_subunits` | Form-ID-to-int | Already applied fixed-point Mastery changes |
| `discovery_events` | ordered list | Explanatory only |
| `milestone_events` | ordered list | Explanatory only |
| `support_events` | ordered list | Explanatory only |
| `hall_events` | ordered list | Explanatory only |
| `forecast_delta_events` | ordered list | Optional when meaningful |

Clearing or archiving this state never mutates inventory, backlog, Mastery, milestones, or Hall output.


### 9.15 ReportSnapshot

A report snapshot is created when the current accumulator is opened, archived, or rolled over by an approved report policy.

Minimum fields:

| Field | Type | Rule |
|---|---|---|
| `report_id` | `String` | Stable within the save; not a gameplay content ID |
| `created_simulation_msec` | runtime `int` | Snapshot point on the simulation timeline |
| `window_started_simulation_msec` / `window_ended_simulation_msec` | runtime `int` | Covered simulation interval |
| `summary` | save-safe dictionary | Copy of applicable already-applied deltas and ordered events |
| `acknowledged` | `bool` | Presentation state only |

Report history is bounded by a configurable retention count. Removing an old snapshot changes no authoritative production or progression state.

## 10. Domain event contract

A domain event is a typed, ordered description of a committed gameplay fact. Events support report aggregation, tutorial observation, presentation refresh, diagnostics, and local playtest instrumentation. They are not the authoritative save history and do not make the project event-sourced.

Minimum event fields:

| Field | Type | Rule |
|---|---|---|
| `event_type` | `StringName` | Approved event type or canonical `REPORT_EVENT_...` ID when persistence requires it |
| `occurred_simulation_msec` | runtime `int` | Effective boundary on the authoritative simulation timeline |
| `priority` | `int` | Central same-time transition priority |
| `subject_id` | `StringName` | Primary Threshold, Form, Hall, milestone, or other affected entity |
| `source_id` | `StringName` | Optional rule, Trait, Retinue, Recollection, or command source |
| `payload` | dictionary | Save-safe primitives only; schema owned by the event type |
| `reportable` | `bool` | Whether the event enters the Reaping Report accumulator |
| `tutorial_relevant` | `bool` | Whether the TutorialCoordinator should reevaluate after the commit |

Ordering rules:

1. order by effective `occurred_simulation_msec`;
2. order by documented transition priority;
3. order by stable subject/source IDs when priorities are equal;
4. preserve a sequence number only when the preceding rules cannot express a meaningful distinction.

Events describe state that has already committed. Replaying an event is not the normal way to reconstruct inventory, backlog, Hall state, or tutorial state.

## 11. Action result contract

Every player-facing state-changing command returns a typed result rather than relying on an exception, a UI-side guess, or a partially mutated dictionary.

Minimum result fields:

| Field | Type | Rule |
|---|---|---|
| `success` | `bool` | True only after the complete domain transaction commits in memory |
| `error_code` | `StringName` | Stable code for a correctable rejection; empty on success |
| `player_message` | `String` or localization key | Concise explanation suitable for presentation |
| `developer_details` | `String` | Diagnostic context without secrets or local paths |
| `change_summary` | typed summary | IDs/domains that presentation should refresh |
| `events` | ordered event array | Facts produced by the committed transaction |
| `save_checkpoint_requested` | `bool` | Whether the application layer must request persistence |

A failed command must not leave partial authoritative mutation. Validate the complete cost, capacity, compatibility, reservation, and state-transition contract before committing changes.

Save failure occurs after an in-memory command and is reported separately by the application/persistence layer. The UI must not claim durable completion when the required checkpoint failed.

## 12. Numeric and unit rules

### 12.1 Time

Use:

- integer milliseconds for every simulation duration;
- `GameState.simulation_time_msec` as the monotonic authoritative timeline for events, reports, assignments, and diagnostics;
- a monotonic process clock adapter only to measure foreground elapsed duration;
- `TimeAuthorityState.trusted_anchor_utc_msec` only for externally trusted closed-session reconciliation;
- explicit `_msec`, `_simulation_msec`, or `_trusted_utc_msec` suffixes in code and serialized keys.

Do not:

- use the device wall clock, timezone, calendar, daylight-saving state, file modification time, or user input to award progress;
- serialize rendered frame counts as gameplay time;
- let simulation or domain services read any clock directly;
- confuse active playtime, simulation time, trusted epoch, and report-window duration.

When trusted time is unavailable, closed-session credit is deferred rather than estimated from an untrusted source. Foreground monotonic production continues.

### 12.2 Discrete quantities

Use non-negative unscaled integers for:

- owned and reserved whole Souls;
- whole catalysts, resources, materials, and Stores after extraction;
- remaining backlog;
- persistent-return counters;
- command tether capacity;
- completed-cycle counts when persisted;
- milestone, guarantee, resonance, and unlock membership.

Do not represent a whole Soldier Soul, rare catalyst, backlog soul, or Ration as a floating-point or scaled inventory count. The fixed-point scale does not multiply these counts; it is used only for meaningful fractional state.

### 12.3 Authoritative fractional progress

`DEC-0026` defines `FixedPoint.SCALE = 1_000_000` subunits per whole unit.

Authoritative fractional production, Mastery, discovery progress, familiarity, support consumption, forecast calculations, acquisition progress, and rate carries use the central fixed-point utility defined by the architecture.

Runtime representation uses signed 64-bit integer values with non-negative flow contracts where applicable:

- one project-wide scale constant;
- one conversion path from validated content numbers to fixed-point values;
- an explicit positive rate period rather than an assumed integer subunit-per-second rate;
- normalized whole-progress remainders in `0 <= progress_subunits < SCALE` after extraction;
- explicitly typed arithmetic carries whose range is defined by their denominator;
- checked arithmetic for the supported prototype horizon;
- exact extraction of whole units before inventory mutation.

A canonical long-horizon example is one whole item per `86_400_000` milliseconds. From zero progress, six hours produces exactly `250_000` acquisition subunits; twenty-four hours banks one whole unit. Equivalent chunking must produce the same whole count, progress, and carry.

Content Resources may expose editor-friendly finite decimal numbers. `ContentRegistry` validates and normalizes them into the fixed-point representation once. Simulation code does not repeatedly convert or independently round authored floats.

### 12.4 Rounding and display

One fixed-point utility owns:

- conversion from authored decimal values;
- multiply/divide and per-period accumulation behavior;
- whole-unit extraction;
- remainder normalization;
- overflow checks;
- any documented half-up, floor, or truncation rule.

Presentation may format derived values with decimals, abbreviations, uncertainty ranges, or acquisition percentages. Presentation rounding never writes back to authoritative state.

For an Identified long-horizon whole-unit source, derive a one-decimal progress percentage by flooring to tenths of a percent. While `progress_subunits < SCALE`, the display must remain at or below `99.9%`; `100.0%` is shown only as part of the actual whole-unit completion/banking presentation. Do not display fractional Souls, catalysts, or other whole inventory objects.

### 12.5 JSON integer wire representation

Every schema field that is an authoritative runtime integer is encoded in JSON as a canonical base-10 string. This includes trusted timestamps, simulation time, revisions, quantities, backlog, counters, fixed-point values, residuals, and durations.

The save codec must:

- reject leading plus signs, decimal points, exponents, whitespace, and non-digit characters;
- permit a leading minus sign only for a field whose runtime contract explicitly permits negative values;
- reject values outside the signed 64-bit range;
- convert to runtime `int` before validation or simulation;
- emit one canonical representation without leading zeroes except the value `0`.

Small booleans remain JSON booleans. Canonical IDs and enum values remain JSON strings. Dictionary keys are strings. Set-like collections are serialized as sorted arrays. Authoritative save data does not contain JSON floating-point values, non-finite values, or locale-formatted numbers.

Example:

```json
{
  "schema_version": "1",
  "codec_id": "JSON_V1",
  "save_revision": "42",
  "last_offline_resolution_id": "offline-000042",
  "metadata": {},
  "time_authority": {
    "trusted_source_id": "STEAM_SERVER_TIME",
    "has_trusted_anchor": true,
    "trusted_anchor_utc_msec": "1783872000000",
    "foreground_credited_since_anchor_msec": "125000",
    "pending_trusted_reconciliation": false,
    "last_sample_diagnostic_code": "TIME_OK"
  },
  "game_state": {
    "simulation_time_msec": "3485000",
    "thresholds": {
      "THR_GLOAMWOOD": {
        "remaining_backlog": "998996",
        "persistent_returns_total": "1000"
      }
    }
  }
}
```

Do not pass exact runtime integers directly to `JSON.stringify()` and assume integer type or precision will survive parsing.

### 12.6 Save codec and integrity boundary

The primitive snapshot schema is independent from its byte representation. `SaveCodec` owns encoding and decoding; domain state, migrations, and validation do not call JSON APIs directly.

Prototype rules:

- use codec ID `JSON_V1`;
- prefer inspectability and exactness over opacity;
- optional unkeyed digests may detect accidental corruption only;
- do not describe JSON, binary encoding, compression, local encryption, obfuscation, or a locally stored key as tamper-proof;
- reject unknown codec IDs without overwriting the last valid save.

Before commercial release, profile realistic worst-case state and decide whether JSON remains adequate or a compressed/binary codec is justified. A wire-format change requires codec compatibility and migration tests, not a rewrite of authoritative state.

## 13. Enumeration contracts

Persist stable string values or canonical IDs rather than language-level enum ordinals. Renaming a persisted value requires a migration.

### 13.1 Threshold state dimensions

Persist stable values for three independent dimensions:

| Dimension | Values | Meaning |
|---|---|---|
| Knowledge | `UNKNOWN`, `DETECTED`, `CHARTED` | What site information the player may see |
| Availability | `LOCKED`, `AVAILABLE` | Whether a Reaping may be assigned when capacity permits |
| Lifecycle | `OVERDUE`, `SETTLED` | Whether finite backlog remains or renewable passage rules apply |

Activity is derived from whether an active Reaping references the Threshold. Presentation composes labels such as `Active - Overdue`, `Active - Settled`, or `Inactive - Settled`.

Validation requirements:

- an active Reaping requires `AVAILABLE`;
- `SETTLED` requires zero remaining backlog;
- after the zero-backlog transition, zero backlog cannot remain `OVERDUE`;
- `UNKNOWN` knowledge never overrides output Access. A progression-gated channel produces only after its item is globally unlocked and its available source is initialized; the Threshold itself must still be known and available before dispatch.

Do not persist one combined enum containing every knowledge, availability, activity, and lifecycle combination.

### 13.2 Access, knowledge, and insight

| Value | Meaning |
|---|---|
| `LOCKED` | Progression-gated output cannot accumulate; a latent row/category hint may still be shown |
| `UNKNOWN` | Item/source identity is not yet disclosed and no unavailable location is named |
| `IDENTIFIED` | Name, icon, qualitative frequency, and currently available source relationships are visible; production may occur only when Access is unlocked |
| `CHARTED` | Expected range, current modifiers, ETA confidence, and source relationships are visible |

### 13.3 Support

Minimum prototype values:

| Value | Meaning |
|---|---|
| `FULL` | Intended Retinue/support effects apply |
| `LOW` | Warning state before depletion; exact softening is configurable |
| `DEPLETED_REDUCED` | Affected premium/Retinue effects use the configured floor; base Reaping continues |

A future automatic Low-Upkeep fallback needs an approved Writ/fallback contract before adding another persisted state.

### 13.4 Tutorial states

The exact persisted tutorial state IDs are:

- `TUT_00_BOOT`
- `TUT_01_WINDOW`
- `TUT_02_DIRECT_REAP`
- `TUT_03_SOULS_RETURN`
- `TUT_04_FIRST_DISPATCH`
- `TUT_05_ARCHIVE`
- `TUT_06_SOULWEAVE`
- `TUT_07_RETINUE`
- `TUT_08_SCRIBE`
- `TUT_09_SECOND_THRESHOLD`
- `TUT_10_DISCOVERY`
- `TUT_11_LARDER`
- `TUT_12_SEAL_CHOICE`
- `TUT_13_COMPLETE`

The tutorial state is not a substitute for checking authoritative world conditions.

## 14. Save schema version 1 outline

The initial JSON structure should follow this conceptual shape:

```text
SaveEnvelope
├── schema_version
├── codec_id
├── content_revision
├── save_revision
├── time_authority
│   ├── trusted_source_id
│   ├── has_trusted_anchor
│   ├── trusted_anchor_utc_msec
│   ├── foreground_credited_since_anchor_msec
│   ├── pending_trusted_reconciliation
│   └── last_sample_diagnostic_code
├── last_offline_resolution_id
├── metadata
└── game_state
    ├── simulation_time_msec
    ├── inventory
    ├── forms
    ├── thresholds
    ├── reapings
    ├── halls
    ├── recollections
    ├── progression
    ├── story
    ├── tutorial
    ├── report_accumulator
    ├── report_history
    └── session_playtime_msec
```

The M02 persistence milestone must document the exact key spelling and add representative save fixtures before another system depends on the schema.

All fields typed as authoritative runtime integers use the canonical decimal-string wire representation from §12.5. The tree above describes semantic fields, not JSON primitive types.

Do not save:

- Node paths or live Node/Object references;
- current screen layout, hover state, tweens, or animation frames;
- cached rate plans or forecast results that can be derived;
- content-definition fields already supplied by the catalog;
- absolute local filesystem paths;
- device wall-clock values used to calculate production;
- Steam user IDs, development App IDs, GodotSteam configuration, or unrelated storefront state;
- signal connections, Callables, script instances, or arbitrary object dumps;
- the complete lifetime domain-event log.

## 15. Derived counters and the opening-four rule

The scripted opening transaction and persistent Reaping counters are intentionally separate.

Required behavior:

1. new Gloamwood state begins with `remaining_backlog = 1_000_000`;
2. the one-time direct action changes it to `999_996` and commits its story/exactly-once flag;
3. `persistent_returns_total` remains `0` after that action;
4. the first Gloamwood Reaping begins its own counter at `0` on dispatch;
5. `MS_GLOAMWOOD_REAPING_1000`, `_2500`, and `_5000` use that persistent counter;
6. regional `10_000` and `25_000` milestones sum persistent Reaping returns only;
7. the scripted four never enter those regional sums.

Narrative presentation, debug audit, or a broader history surface may mention the opening four. If a Reaping Report presents that context, it must use a separately labelled scripted direct-action event and must exclude the four from every automated-Reaping total.

Tests must cover the exact `999`, `1_000`, `2_499`, `2_500`, `4_999`, `5_000`, `9_999`, and `10_000` boundaries without an off-by-four result.

## 16. Required content validation

`ContentRegistry` must reject or clearly report:

- duplicate canonical IDs;
- empty required display names or duplicate/malformed `TERM_...` entries;
- any rule or reference keyed by display text rather than canonical ID;
- deprecated `RES_CORRUPTED_ESSENCE` or deprecated Essence-channel IDs in production content;
- IDs with an invalid or mismatched prefix;
- missing required prototype definitions;
- unresolved references between definitions;
- negative costs, rates, backlogs, requirements, targets, or durations where forbidden;
- non-finite numeric values;
- conversion values outside the supported fixed-point range;
- a required Settled Passage channel with a non-positive renewable rate;
- milestone dependency cycles or impossible trigger references;
- a milestone reward that references a missing guarantee or resonance;
- an Emergency Writ that does not name `WRIT_STANDARD` as its approved transition;
- `RET_SOLDIER_COMPANY` requiring anything other than twelve `SOUL_CALLING_SOLDIER` Souls;
- Retinue slot/category definitions that cannot match the approved Form slots;
- a missing or duplicate tutorial state definition;
- tutorial presentation data that attempts to own a gameplay grant, cost, or mutation;
- arbitrary executable expression strings, Callables, or script paths in content rules;
- provisional balance embedded only in a scene or tutorial script instead of authored data.

Validation errors must identify the definition path, canonical ID, field, and expected contract where practical.

## 17. Required runtime and save validation

Before simulation and before committing a save candidate, validate at least:

- inventory totals are non-negative;
- reservation amounts are non-negative and their sums do not exceed owned totals;
- every reservation owner exists and agrees with the relevant Retinue/Hall assignment;
- active Reapings do not exceed command tether capacity;
- no Threshold has more than one active Reaping;
- each active Reaping references an available Threshold, awakened Form, valid Writ, and compatible Retinues;
- Reaping Retinue IDs agree with inventory reservation records;
- remaining backlog is within `0..initial_backlog`;
- `lifecycle_state` agrees with remaining backlog and the exactly-once settlement transition;
- fixed-point remainders are normalized, have exactly one documented owner, and all integers are within supported range;
- every integer wire value is a canonical decimal string, parses exactly, and rejects malformed, non-canonical, or out-of-range input;
- every set-like array is sorted and duplicate-free after decoding;
- saved IDs resolve in the current content revision or through a migration;
- completed milestones, rewards, guarantees, and resonances do not contain impossible duplicates or unresolved references;
- tether 2 is not granted more than once;
- the 5,000 and 10,000 resonance IDs remain distinct;
- tutorial state is one approved `TUT_...` value;
- Scribe is not marked awakened merely because `TUT_08_SCRIBE` was presented or skipped;
- report data is explanatory and does not exceed configured history bounds;
- `simulation_time_msec` and `foreground_credited_since_anchor_msec` are non-negative;
- when no trusted anchor exists, its epoch field is zero and no closed-session credit is applied;
- an accepted trusted sample never moves the persisted anchor backwards;
- pending trusted reconciliation does not itself grant production;
- no save field sourced from local wall-clock, timezone, calendar, or file timestamps affects production;
- schema and content revisions are supported.

A corrupted or unsupported snapshot must not be partially loaded into the live session.

## 18. Provisional value ownership

The following values remain configurable authored data or focused settings. They must not be scattered through UI, tutorial, or simulation scripts:

- Broken Watch initial backlog;
- base Reaping rates and cycle presentation durations;
- Form rate, discovery, and uncertainty inputs;
- Man-at-Arms and Scribe Trait coefficients;
- Soldier Company rate, Essence, Mastery, support-consumption, reduced-floor, and stacking values;
- Essence yield;
- Mastery rate;
- Form Soul, Calling Soul, and material channel rates;
- discovery thresholds and Scribe/non-Scribe fallback progress;
- Archive, Recollection, Soulweave, Scribe, Larder, and Ration-batch costs;
- Larder conversion rate and Maintain target;
- starting Ration support, consumption, warning threshold, and reduced-effect floor;
- Provisions onboarding buffer;
- optional Recollection coefficients;
- Settled Passage rates/multipliers;
- report aggregation cadence and retained-history count;
- any offline cap beyond the required eight-hour path.
- trusted-time retry cadence and anomaly tolerance that do not weaken the no-local-clock rule;
- commercial-release save codec, compression, and integrity policy after profiling and threat-model review.

Pacing goals such as “first automated Reaping within seven minutes” are playtest targets. Do not implement them as wall-clock unlock timers unless an approved requirement explicitly calls for time-based behavior.

## 19. Requirement traceability in content

Keep editor-facing source notes concise. Use requirement IDs where they materially prevent confusion.

Representative mappings:

| Content/rule | Primary traceability |
|---|---|
| Emergency Writ and transition | `P90-B04`, `P90-B06`, `P90-G02`, `IF-REQ-01`, `IF-REQ-07` |
| Soldier Company and reservation | `P90-B06`, `P90-SAFE-10`, `IF-REQ-06`, `IF-REQ-13` |
| Scribe awakening/discovery | `P90-B07`, `P90-B09`, `P90-AC05`, `IF-REQ-10`, `IF-REQ-12` |
| Provisions and Larder | `P90-B09`, `P90-B10`, `P90-G05`, `P90-SAFE-07` |
| Resonance/tether distinction | `P90-B08`, `P90-B11`, `P90-G04`, `P90-G06` |
| Shared offline/forecast resolution | `P90-AC07`, `IF-REQ-07`, `IF-REQ-08`, `IF-REQ-15` |
| Reports | `P90-SAFE-11`, `IF-REQ-02` |

Do not paste large design passages into `.tres` notes. The maintained Markdown remains the full source of context.

## 20. Change-control rule

Update this document, applicable tests, and the decision log when a pull request changes any of the following:

- a canonical ID or prefix;
- a definition type or required field;
- a serialized field or key meaning;
- a persisted enum value;
- a time, quantity, or fixed-point unit;
- reservation ownership or availability semantics;
- milestone, guarantee, reward, or resonance flags;
- derived-counter rules;
- report event or history schema;
- validation invariants;
- save schema version, migration path, or content-revision compatibility.

A code change is incomplete when this contract describes a state shape or identifier that the implementation no longer uses.

## M01 concrete runtime contracts

M01 introduces these runtime-only contracts. They are not a save schema and do not create JSON fields.

### `GameState`

- `simulation_time_msec: int` — non-negative authoritative simulation timeline in milliseconds.
- Advanced only by validated elapsed-time operations.
- Does not contain `TimeAuthorityState`, inventory, Reapings, Halls, tutorial, reports, or save metadata.

### `TimeAuthorityState`

- `trusted_anchor_utc_msec: int` — accepted external trusted UTC anchor in milliseconds, or `-1` when no anchor exists.
- `trusted_source_id: String` — stable source ID for the accepted anchor.
- `foreground_credited_since_anchor_msec: int` — foreground elapsed milliseconds already credited after the anchor.
- `pending_trusted_reconciliation: bool` — true when trusted time was unavailable and closed-session credit must remain pending.
- `last_sample_diagnostic_code: String` — stable diagnostic from the latest commit or rejection.

### Fixed-point values

- `FixedPoint.SCALE = 1_000_000` subunits per whole fractional unit.
- Fixed-point flow helpers accept non-negative inputs and return typed result dictionaries with stable failure codes.
- Explicit-period accumulation stores and returns its arithmetic carry in the same units as the period denominator. The caller owns the single durable progress/carry record for a future flow key.



## M02 schema-version-1 save contract

Schema version 1 is the frozen minimal M01 persistence snapshot. Top-level keys are exactly `codec_id`, `schema_version`, `save_revision`, `content_revision`, `time_authority`, `last_offline_resolution_id`, `metadata`, and `game_state`. `codec_id` must be `JSON_V1`. `schema_version`, `save_revision`, `game_state.simulation_time_msec`, `time_authority.trusted_anchor_utc_msec`, and `time_authority.foreground_credited_since_anchor_msec` are canonical signed-64-bit decimal strings, with non-negative policies for current schema fields. JSON numeric values in these fields are invalid.

`game_state` contains exactly `simulation_time_msec`. `last_offline_resolution_id` is a diagnostic/idempotency string, and `metadata` is an explicit dictionary reserved for schema diagnostics; M02 writes an empty resolution ID and empty metadata. `time_authority` contains exactly `has_trusted_anchor`, `trusted_anchor_utc_msec`, `trusted_source_id`, `foreground_credited_since_anchor_msec`, `pending_trusted_reconciliation`, and `last_sample_diagnostic_code`. The M01 no-anchor runtime sentinel `trusted_anchor_utc_msec = -1` is encoded as `has_trusted_anchor = false`, `trusted_anchor_utc_msec = "0"`, empty `trusted_source_id`, and foreground credit `"0"`; decoding reconstructs the runtime sentinel. Anchored saves require `has_trusted_anchor = true`, a non-empty source ID, and non-negative anchor/foreground credit.

Stable M02 diagnostics include `SAVE_INT_*` integer errors, `SAVE_SCHEMA_*` validation errors, `SAVE_CODEC_*` codec errors, `SAVE_MIGRATION_*` migration errors, and `SAVE_TRANSACTION_FAILED` storage orchestration failures. Fixtures live under `tests/fixtures/saves/`.



## Approved M04A schema-version-2 and migration contract

Accepted `DEC-0034` resolves `GATE-GAMEPLAY-SCHEMA`. The rules below are the approved M04A target. They do not describe the current executable schema until M04A merges.

### Schema-version constants and dispatch

Persistence keeps explicit constants for every supported schema:

```text
SCHEMA_VERSION_V1 = 1
SCHEMA_VERSION_V2 = 2
CURRENT_SCHEMA_VERSION = 2
```

`validate_v1()` remains a historical validator and compares against `SCHEMA_VERSION_V1`, never against `CURRENT_SCHEMA_VERSION`. `validate_v2()` owns the new exact key set. A version-dispatch function selects the correct source validator before migration.

The byte codec remains:

```text
codec_id = JSON_V1
```

Schema evolution does not imply a new codec.

### Version-2 top-level structure

Top-level key spelling remains:

```text
codec_id
schema_version
save_revision
content_revision
time_authority
last_offline_resolution_id
metadata
game_state
```

The version-2 `game_state` key set is exactly:

```text
simulation_time_msec
inventory
forms
thresholds
reapings
progression
```

Representative empty version-2 shape:

```json
{
  "codec_id": "JSON_V1",
  "schema_version": "2",
  "save_revision": "1",
  "content_revision": "prototype-content-r1",
  "time_authority": {
    "has_trusted_anchor": false,
    "trusted_anchor_utc_msec": "0",
    "trusted_source_id": "",
    "foreground_credited_since_anchor_msec": "0",
    "pending_trusted_reconciliation": false,
    "last_sample_diagnostic_code": "TIME_SAMPLE_NONE"
  },
  "last_offline_resolution_id": "",
  "metadata": {},
  "game_state": {
    "simulation_time_msec": "0",
    "inventory": {"entries": {}},
    "forms": {},
    "thresholds": {},
    "reapings": {},
    "progression": {"command_tether_capacity": "0"}
  }
}
```

The example diagnostic string is illustrative; the implementation preserves the existing valid M01 diagnostic contract.

### M04A runtime-state subset

All maps are keyed by canonical IDs. Mutable player state is represented by typed runtime classes; dictionaries are serialization and indexed-collection boundaries, not the object model.

#### `InventoryState`

```text
entries: item-ID -> InventoryEntryState
```

`InventoryEntryState` contains:

| Field | Type | Rule |
|---|---|---|
| `total` | `int` | Non-negative unscaled whole count |
| `reservations` | reservation-ID-to-`int` | Non-negative; sorted by canonical key in snapshots; sum cannot exceed total |

M04A implements structure, validation, cloning, and round trip only. Spending and reservation commands remain later work.

#### `FormState`

| Field | Type | Rule |
|---|---|---|
| `revealed` | `bool` | Visibility/progression state |
| `awakened` | `bool` | Whether normal or narrative awakening has occurred |
| `mastery_subunits` | `int` | Non-negative fixed-point value |
| `awakened_by` | `StringName` | Empty when unawakened; stable diagnostic/source token when awakened |

M04A does not implement awakening or Mastery gain.

#### `ThresholdState`

| Field | Type | Rule |
|---|---|---|
| `knowledge_state` | enum string | `UNKNOWN`, `DETECTED`, or `CHARTED` |
| `availability_state` | enum string | `LOCKED` or `AVAILABLE` |
| `lifecycle_state` | enum string | `OVERDUE` or `SETTLED` |
| `remaining_backlog` | `int` | `0..authored initial backlog` |
| `persistent_returns_total` | `int` | Non-negative; excludes the scripted opening four |
| `familiarity_subunits` | `int` | Non-negative fixed-point value; no M04A behavior |
| `channel_acquisition` | channel-ID-to-`ThresholdAcquisitionState` | Durable whole-output work owned by Threshold plus channel |

Zero backlog requires `SETTLED`; a positive backlog requires `OVERDUE` until a later approved rule says otherwise.

`ThresholdAcquisitionState` contains:

| Field | Type | Rule |
|---|---|---|
| `progress_subunits` | `int` | `0 <= value < FixedPoint.SCALE` |
| `rate_carry_units` | `int` | Non-negative; when content is available it must be lower than the channel's stable `period_msec` |
| `total_banked_units` | `int` | Non-negative diagnostic/report total; inventory remains ownership authority |

M04A stores and validates representative values but performs no accumulation.

#### `ReapingState`

The `reapings` map is keyed by Threshold ID and contains at most one record per Threshold.

| Field | Type | Rule |
|---|---|---|
| `threshold_id` | `StringName` | Must match the map key and a Threshold state/content definition |
| `is_active` | `bool` | Only active records occupy a tether or later produce output |
| `form_id` | `StringName` | Valid Form ID; active records require an awakened Form state |
| `writ_id` | `StringName` | Valid Writ ID |
| `retinue_ids` | ordered array | Sorted and duplicate-free; M04A fixture uses an empty array and implements no Retinue behavior |
| `assignment_revision` | `int` | Non-negative, monotonically increased only by later assignment commands |
| `cycle_phase_msec` | `int` | Non-negative; no M04A advancement |
| `completed_cycle_count` | `int` | Non-negative; no M04A advancement |
| `flow_carry_units` | flow-ID-to-`int` | Non-negative operation-owned carries; M04A permits empty or representative fixture values |
| `started_simulation_msec` | `int` | Non-negative and no later than current simulation time |
| `last_configuration_change_simulation_msec` | `int` | Non-negative and no later than current simulation time |

M04A constructs a valid fixture directly but implements no dispatch, recall, or production command.

#### `ProgressionState`

| Field | Type | Rule |
|---|---|---|
| `command_tether_capacity` | `int` | Non-negative unscaled count |

Tether occupancy is derived from active Reaping records and may not exceed capacity. M04A implements no grant or dispatch behavior.

### Version-2 wire rules

- Every authoritative integer is a canonical signed-64-bit decimal string in the primitive snapshot and JSON.
- Every set-like array is sorted and duplicate-free.
- Map keys are stable canonical IDs or stable owner/reservation/flow IDs, never display names or filenames.
- Runtime objects, Resources, Nodes, Callables, and floats never enter the snapshot.
- The schema validator checks structure, primitive types, integer encoding, and cross-field rules without constructing live state.
- The domain validator checks canonical IDs, content types, authored backlog bounds, channel ownership/periods, reservation totals, lifecycle consistency, Form awakening consistency, Reaping references, and tether capacity.
- Invalid construction, mapping, or validation returns a working-candidate failure and does not partially mutate live state.

### Canonical `v1 -> v2` migration

The production migration:

1. validates the source with the frozen version-1 validator;
2. deep-copies the primitive snapshot;
3. changes only `schema_version` to `"2"`;
4. preserves the complete version-1 envelope, time-authority fields, `content_revision`, metadata, offline-resolution ID, save revision, and simulation time;
5. adds:

```json
{
  "inventory": {"entries": {}},
  "forms": {},
  "thresholds": {},
  "reapings": {},
  "progression": {"command_tether_capacity": "0"}
}
```

6. validates the full version-2 snapshot;
7. maps and validates typed runtime state and content compatibility before any persistence or live-state adoption.

The migration does not awaken a Form, unlock a Threshold, add items, create a Reaping, change content revision, or infer story progress.

The pure transform preserves `save_revision`. The transactional upgrade increments revision once, checks overflow, writes through the existing temporary/validate/backup/promote transaction, and returns runtime state only after that write succeeds. Already-current version-2 snapshots do not rewrite on load.

### Historical-support and reset policy

- Keep at least one immutable schema-version-1 fixture permanently while version 1 is supported.
- Keep version-specific validators and migration tests.
- Reject unknown future versions without file mutation.
- On migration or upgrade-write failure, preserve the original candidate and any valid fallback.
- A developer reset may be offered separately, but it must be explicit and preserve/archive the incompatible file. It is not a substitute for the supported `v1 -> v2` path.
- Before any public save baseline is distributed, migration history may be consolidated only through another owner-approved decision. Publicly supported baselines retain their migration path.

### Content-revision interaction

Schema migration preserves the source `content_revision`. Before simulation or persisted upgrade, the caller supplies the validated `ContentRegistry` compatibility result. Persistence remains catalog-agnostic and never imports production `.tres` files. A later ordinary save writes the current catalog revision explicitly.


## Approved M03 catalog and scaffold contract

The M03 prompt approval accepts the structure and values below only as editable prototype scaffold, not final balance.

### Catalog identity and compatibility

- Root path: `content/prototype_content_catalog.tres`.
- Current revision: `prototype-content-r2`.
- Compatible save revisions, canonically sorted and duplicate-free: `prototype-content-r1`, `prototype-content-r2`, `prototype-m02`.
- Required first-class gameplay/content definitions: fifty-four non-channel definitions plus six `OutputChannelDefinition` records, for sixty total.
- Required terminology: one `CoreTerminologyDefinition` containing the twenty `TERM_...` entries in §5.8.
- Required inline Trait identities: `TRAIT_OLD_DRILL` and `TRAIT_UNCLOSED_LEDGER`, with editable names and stable modifiers.
- New saves receive the registry's current revision explicitly. Persistence retains no content-owned default and does not import `ContentRegistry`.
- Unknown revisions fail with `CONTENT_REVISION_INCOMPATIBLE` before simulation.

### Naming and terminology policy

- `display_name` and optional localization fields are mutable presentation data; IDs and references are stable.
- Rebuilding a registry after changing **Unclosed Ledger**, a Recollection name, or another entity name changes only normalized presentation text.
- Changing `TERM_THRESHOLD` changes the shared player-facing noun but leaves `THR_...` IDs and save compatibility untouched.
- The production catalog uses `RES_ESSENCE`, `CHANNEL_GLOAMWOOD_ESSENCE`, and `CHANNEL_BROKEN_WATCH_ESSENCE`. The deprecated dual terminology is rejected.
- Text-only naming changes do not require a schema migration. A content revision may stay the same for a pure presentation edit, or advance while retaining previous compatibility for release bookkeeping.

### Finite modifier grammar

Approved M03 metric tokens:

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

Approved operations are `ADD`, `MULTIPLY`, and exceptional `OVERRIDE`. Approved target scopes are `REAPING_TOTAL`, `RETINUE_OWN_CONTRIBUTION`, `OUTPUT_CHANNEL`, and `FORECAST_ONLY`. Approved conditions are `ALWAYS`, `THRESHOLD_HAS_ANY_TAG`, `RETINUE_CATEGORY`, `OUTPUT_ITEM`, `OUTPUT_KIND`, `SUPPORT_STATE`, and `THRESHOLD_LIFECYCLE`.

M03 validates and normalizes this grammar; it does not execute a complete modifier stack.

### Provisional production and progression data

| Content | Prototype scaffold value |
|---|---|
| Gloamwood / Broken Watch base returned-soul rate | `1.0` per `1,000 ms` |
| Prototype cycle duration | `60,000 ms` |
| Base active Form Mastery | `1.0` per `60,000 ms` |
| Settled output multiplier | `0.25` |
| Both Essence channels | `1.0` per `10,000 ms` |
| Gloamwood Soldier Soul channel | `1.0` per `300,000 ms`; Common; initially Unknown |
| Gloamwood Scribe Form Soul channel | `1.0` per `28,800,000 ms` (8 hours); Uncommon; progress display enabled after identification |
| Broken Watch Provisions channel | `1.0` per `30,000 ms`; Common; initially Unknown |
| Broken Watch Man-at-Arms Form Soul channel | `1.0` per `86,400,000 ms` (24 hours); Uncommon; progress display enabled after identification |
| Provisions identification | six base discovery cycles; Scribe's `+100%` discovery reaches it in approximately three |
| Provisions charting | twelve base discovery cycles |
| Scribe awakening | one `SOUL_FORM_SCRIBE` plus `50` Essence |
| Soldier Company support consumption | one Ration per `300,000 ms`; reduced-effect floor `0.50` |
| Archive restore / Weave / Muster | `25` Essence each |
| Larder restore | `25` Essence plus `20` Provisions |
| Larder recipe | `10` Provisions → `10` Rations in `120,000 ms`; default target `50` |
| Optional Recollections | `50` Essence each |
| Quicker Reckoning | `+10%` returned-soul rate |
| Names Kept | `+10%` Whole-Soul output-channel rate |
| Open Ledgers | `+25%` discovery rate; forecast uncertainty × `0.90` |
| 10,000 regional resonance | `50` Essence and expose all three optional Recollections |
| Provisions onboarding buffer | `20%` of restoration plus first-batch Provisions, producing a current floor of `36` |
| 25,000 regional milestone | enabled scaffold trigger with no locked reward; does not gate the tutorial |

### Prototype Form and Retinue modifiers

- Man-at-Arms / **The Old Drill**: `+15%` returned-soul rate at Settlement or Martial Thresholds; `+10%` Martial Retinue contribution. Slots: Martial; Martial/Logistics.
- Scribe / **Unclosed Ledger**: `+100%` discovery rate; forecast uncertainty × `0.50`. Slots: Specialist; Logistics/Extraction.
- Soldier Company: twelve reserved Soldier Souls; provisional `+30%` own returned-soul contribution, `+20%` Essence, and `+15%` Mastery. Stacking remains centralized and provisional.

All floats are normalized once to `FixedPoint.SCALE = 1_000_000`; normalized runtime data contains no authoritative floats. M03 uses one documented conversion path: validate that the authored value is finite and within range, multiply by `SCALE`, round to the nearest integer subunit using Godot's deterministic integer-rounding helper, and retain only the integer result. Values finer than one subunit are rounded rather than creating a second precision model.

## Approved M04B assignment and identity contract

This section is authoritative under accepted `DEC-0035` and the approved M04B prompt.

### Four identity layers

| Layer | Authoritative identity | Rule |
|---|---|---|
| Reaping operation | `threshold_id` | One stable operation per Threshold; stored at `GameState.reapings[threshold_id]` |
| Loadout | canonical value tuple | Form, Writ, ordered Retinue IDs, and later approved configuration components |
| Assignment state | `(threshold_id, assignment_revision)` | One committed version of the operation's assignment |
| Activation episode | resulting revision of a successful dispatch/redispatch | One active interval until recall; derived, not separately persisted |

A formatted diagnostic such as `THR_GLOAMWOOD@5` may identify an assignment state or activation episode. It is not a new canonical content ID and is not serialized as another authority field.

Loadout equality does not imply Reaping identity. The same loadout may create or resume another Threshold's operation. Conversely, changing the loadout at one Threshold does not create a new operation.

### Stable Reaping record and first-start timestamp

- `GameState.reapings` is keyed by Threshold ID.
- At most one record exists for a Threshold.
- A Threshold has no operation record before first dispatch.
- First successful dispatch creates the record and sets `started_simulation_msec` once.
- `started_simulation_msec = 0` is valid. Do not use zero or another numeric sentinel for “never started.”
- Recall sets `is_active = false`; it never deletes the record.
- Recall, redispatch, loadout changes, inactivity, Settlement, and save/load preserve `started_simulation_msec`.
- Ordinary gameplay commands cannot remove the record.
- Threshold discovery and acquisition remain in `ThresholdState`; operation cycle state and carries remain in `ReapingState`.
- Occupied tether count is derived from active records.
- One Form ID may appear on at most one active Reaping.
- If current-episode start time is later required, add a separate field; never repurpose the immutable first-start timestamp.
- Multiple Reapings at one Threshold require a later first-class instance ID and save migration.

### Scenario matrix

| Scenario | Operation identity | Loadout identity | Assignment/episode result |
|---|---|---|---|
| Same Threshold, same loadout after recall | Same | Equal tuple | New revision and activation episode |
| Different Threshold, same loadout | Different Threshold operation | Equal tuple | Independent revision/episode sequence |
| Same Threshold, different loadout | Same | Different tuple | New revision and activation episode |
| Return to an earlier loadout | Same | Equal to historical tuple | New revision/episode; historical state/rate is not restored |

Threshold-owned backlog, familiarity, discovery, and channel acquisition never move with a loadout.

### Command inputs

M04B uses explicit typed command values or strongly typed method parameters. Arbitrary command dictionaries are not authoritative.

#### Initial dispatch

| Field | Type | Rule |
|---|---|---|
| `threshold_id` | `StringName` | Existing enabled Threshold definition and runtime state; state must be `AVAILABLE` |
| `form_id` | `StringName` | Existing revealed/awakened Form state and enabled Form definition |
| `writ_id` | `StringName` | Enabled Writ definition |
| command kind | typed invariant | Initial dispatch requires no existing operation record for the Threshold |

Success creates revision 1 at the current simulation cursor, sets both timestamps to that cursor, and does not advance it.

#### Recall

| Field | Type | Rule |
|---|---|---|
| `threshold_id` | `StringName` | Existing active operation record |
| `expected_assignment_revision` | `int` | Must exactly equal the current positive revision |

Success sets inactive, increments once, and updates only the configuration-change timestamp.

#### Redispatch

| Field | Type | Rule |
|---|---|---|
| `threshold_id` | `StringName` | Existing inactive operation record |
| `form_id` | `StringName` | Valid awakened Form, not active elsewhere |
| `writ_id` | `StringName` | Valid enabled Writ |
| `expected_assignment_revision` | `int` | Must exactly equal the current revision |

Success reactivates the same operation, increments once, and preserves first-start time.

### Revision and timestamp rules

- Existing Reaping records use positive assignment revisions; first dispatch is revision 1.
- Every committed recall or redispatch adds exactly one after checked signed-64-bit overflow validation.
- Failed, duplicate, no-op, stale, replayed, or unsupported commands do not increment.
- `started_simulation_msec` never changes after creation.
- `last_configuration_change_simulation_msec` equals the current committed `GameState.simulation_time_msec` after each successful assignment command.
- Assignment commands never accept a device timestamp or trusted epoch.
- `started_simulation_msec <= last_configuration_change_simulation_msec <= simulation_time_msec`.
- Timestamps do not identify operations or episodes.

### Validation

Before mutation:

- current `GameState` and `ContentRegistry` validate;
- Threshold exists in state/content and is `AVAILABLE`;
- Form exists in state/content, is revealed/awakened, and is not active elsewhere;
- Writ exists and is enabled;
- initial dispatch requires no operation record;
- recall requires active;
- redispatch requires inactive;
- active count after the command does not exceed tether capacity;
- no persisted occupied-tether counter exists.

M04B does not require tutorial/new-game unlock state or a Writ-specific progression set that does not yet exist. Later presentation decides which otherwise-valid command is offered.

### Frozen operation state and changed redispatch

Recall freezes operation-owned state.

- Same-loadout redispatch preserves cycle phase and carries.
- Changing Form or Writ is allowed in M04B only when rate-dependent cycle phase and carry are canonically zero.
- A changed request with nonzero rate-dependent state returns `REAPING_RESOLUTION_REQUIRED` without mutation.
- M04C/M04D later resolve elapsed time under the old setup before committing a changed configuration.
- Retinue changes are outside M04B.

Returning to an earlier loadout re-derives current behavior from current content/progression. It does not restore an old effective-rate snapshot.

### Result and events

A command returns one typed result conforming to §11. Success includes:

- `success = true`;
- empty error code;
- operation identity (`threshold_id`);
- resulting assignment revision;
- derived assignment-state ID;
- loadout summary;
- active state and occupied tether count;
- one ordered event;
- `save_checkpoint_requested = true`.

Event types:

```text
REAPING_DISPATCHED
REAPING_RECALLED
REAPING_REDISPATCHED
```

Dispatch and redispatch events identify the new activation episode through their resulting revision. These are committed facts, not event-sourced save authority.

Stable rejection categories:

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

Expected invalid actions do not use `push_error()` as ordinary control flow.

### Persistence

M04B uses schema version 2 without a schema bump. The existing mapper persists:

- active state;
- Form/Writ IDs;
- assignment revision;
- phase, count, and carries;
- immutable first-start and latest-configuration timestamps;
- Threshold-owned progress;
- tether capacity.

Operation identity remains the Reaping map key. Loadout, assignment-state, and episode identities are derived from existing fields; no UUID or extra identity key is serialized.

Active and inactive records round-trip exactly. The assignment service requests a checkpoint but performs no file I/O.

## Approved M04C core Reaping resolution contract

This section is authoritative under accepted `DEC-0036` and the approved M04C v0.1 prompt.

### Supported state

| Condition | M04C behavior |
|---|---|
| `elapsed_msec < 0` | Reject with no mutation |
| `elapsed_msec = 0` | Successful no-op |
| No active Reaping | Advance `simulation_time_msec`; produce nothing |
| One active Reaping | Resolve the core streams |
| More than one active Reaping | Reject as unsupported concurrency; no mutation |
| Active Reaping has Retinues | Reject as unsupported M04C configuration |
| Active Reaping has unknown nonzero flow key | Reject rather than ignore authoritative state |

M04C uses schema version 2 and adds no new serialized field. It is not wired into player-facing application flow.

### Normalized core rate plan

A rate is represented by:

```text
rate_subunits_per_period: int
period_msec: int
```

The current core metrics are:

| Flow | Base source | Supported modifiers | Settled behavior |
|---|---|---|---|
| Returned souls | active Form `base_returned_souls_rate` | active Form Trait `SOULS_RETURNED_RATE` multipliers | multiply once by Threshold settled multiplier |
| Essence | owning Threshold's enabled `RES_ESSENCE` channel rate | active Form Trait `ESSENCE_YIELD` multipliers | multiply once by Essence-channel settled multiplier |
| Mastery | active Form `active_mastery_rate` | active Form Trait `MASTERY_RATE` multipliers | unchanged |
| Cycle | active Form `cycle_duration_msec` | none in M04C | unchanged |

The M04C modifier subset is:

```text
MULTIPLY
REAPING_TOTAL
ALWAYS or THRESHOLD_HAS_ANY_TAG
SOULS_RETURNED_RATE, ESSENCE_YIELD, MASTERY_RATE
```

Relevant unsupported modifiers fail explicitly. Irrelevant discovery/forecast modifiers do not affect the rate plan. Multiplication is checked fixed-point arithmetic with deterministic floor semantics.

### Stable core flow keys

These keys live in `ReapingState.flow_carry_units`. The shared `CoreFlowKeys` owner defines membership, deterministic ordering, progress-key classification, and content-derived carry validation:

| Key | Owner and range |
|---|---|
| `FLOW_CORE_RETURNS_PROGRESS_SUBUNITS` | returned-soul progress; `0 <= value < FixedPoint.SCALE` |
| `FLOW_CORE_RETURNS_RATE_CARRY_UNITS` | returned-soul numerator remainder; below returned-soul period |
| `FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS` | Essence progress; `0 <= value < FixedPoint.SCALE` |
| `FLOW_CORE_ESSENCE_RATE_CARRY_UNITS` | Essence numerator remainder; below Essence period |
| `FLOW_CORE_MASTERY_RATE_CARRY_UNITS` | Mastery numerator remainder; below Mastery period |

Additional rules:

- missing known keys mean zero;
- known keys are written canonically after a successful positive resolution;
- unknown zero-valued keys are preserved;
- unknown nonzero keys on an active Reaping are unsupported;
- `cycle_phase_msec` satisfies `0 <= value < cycle_duration_msec`;
- `completed_cycle_count` is a non-negative whole count;
- long-horizon channel progress remains in `ThresholdAcquisitionState`;
- effective rates and ETAs are derived and not saved.

### Whole extraction

For returned souls and Essence:

1. use `FixedPoint.accumulate_for_elapsed_msec()` with the flow's rate carry;
2. checked-add produced subunits to the flow's progress remainder;
3. extract whole units;
4. retain the normalized subunit remainder;
5. commit whole units immediately.

Returned souls:

- always increment the owning Threshold's `persistent_returns_total`;
- reduce `remaining_backlog` only while Overdue;
- never make backlog negative.

Whole Essence increments the `RES_ESSENCE` inventory total. Existing reservations remain unchanged.

Mastery adds produced subunits directly to the active Form and retains only its arithmetic carry.

### Cycle advancement

For each successfully resolved active segment:

```text
total_phase = cycle_phase_msec + segment_msec
completed = total_phase / cycle_duration_msec
next_phase = total_phase % cycle_duration_msec
```

All arithmetic is checked. M04C may aggregate multiple cycle completions; it does not loop once per cycle or execute discovery/tutorial effects.

### Settlement boundary

For a positive Overdue backlog:

- determine whether the requested interval can produce enough whole returns to reach zero;
- if yes, find the minimum integer millisecond at which that occurs;
- apply all core flows and cycle progress through that millisecond under Overdue rates;
- count all whole returns produced at the boundary;
- set backlog to zero and lifecycle to `SETTLED`;
- emit one `THRESHOLD_SETTLED` event;
- apply Settled rates only to remaining time.

A Threshold already in `SETTLED` emits no new Settlement event.

After Settlement:

- persistent returns continue;
- backlog remains zero;
- Essence continues at the channel's Settled rate;
- Mastery continues unchanged;
- cycle cadence continues unchanged.

### Hand-calculable production fixtures

Using production Gloamwood, Standard Writ, awakened Man-at-Arms, no Retinue, and zero residuals:

#### Sixty Overdue seconds

```text
returned souls: 69
Essence: 6
Mastery subunits: 1_000_000
completed cycles: 1
cycle phase: 0
```

This includes Old Drill's `1.15` returned-soul multiplier because Gloamwood has `TAG_SETTLEMENT`.

#### One-backlog Settlement fixture over ten seconds

Starting with one remaining backlog and zero residuals:

```text
exact Settlement boundary: 870 ms
persistent returned souls after 10,000 ms: 3
remaining backlog: 0
lifecycle: SETTLED
returned progress remainder: 625_375 subunits
returned rate carry: 0
Essence whole units: 0
Essence progress remainder: 315_250 subunits
Essence rate carry: 0
Mastery gained: 166_666 subunits
Mastery rate carry: 40_000
cycle phase: 10_000 ms
Settlement events: exactly 1
```

The same result must occur for one 10,000-millisecond call and equivalent chunks such as `869 + 1 + 9,130`.

### Typed simulation result

Minimum fields:

```text
success
error_code
developer_details
requested_elapsed_msec
committed_elapsed_msec
change_summary
segments
events
```

The change summary contains exact deltas for simulation time, returned souls, backlog, Essence, Mastery, completed cycles, and lifecycle. Segment summaries identify start/end simulation cursors, lifecycle/rate context, and exact committed deltas. Events follow the domain-event minimum contract and are not persisted.

## Approved M04D access, schema-v3, and sliced-channel contract

Accepted `DEC-0037` supersedes the earlier M04D draft contract.

### Access, knowledge, and insight

| Layer | Authoritative representation in M04D1 | Rule |
|---|---|---|
| Access | `ProgressionState.unlocked_output_item_ids` plus per-source acquisition-record initialization | Gates production |
| Knowledge | Derived item/source identification for available initialized sources | Unlock identifies the item and available locations |
| Insight | Existing content hints and later M13 state/read models | Controls category, rarity, rate/ETA precision, and modifier explanation |

Knowledge or insight never grants Access. Access never names an unavailable Threshold.

M04D1 command results use the bounded `AccessActionResult`, `AccessChangeSummary`, and `AccessEvent` contracts. Events are `OUTPUT_ITEM_UNLOCKED` and `OUTPUT_SOURCE_IDENTIFIED`; stable access error codes include `OUTPUT_ACCESS_ITEM_NOT_FOUND`, `OUTPUT_ACCESS_ITEM_DISABLED`, `OUTPUT_ACCESS_ESSENCE_EXCLUDED`, `OUTPUT_ACCESS_NO_AUTHORED_SOURCE`, `OUTPUT_ACCESS_CHANNEL_INVALID`, `OUTPUT_ACCESS_CHANNEL_OWNERSHIP_INVALID`, and `OUTPUT_ACCESS_MIGRATION_FINALIZATION_FAILED`.

### Schema version 3

Explicit constants become:

```text
SCHEMA_VERSION_V1 = 1
SCHEMA_VERSION_V2 = 2
SCHEMA_VERSION_V3 = 3
CURRENT_SCHEMA_VERSION = 3
```

The top-level envelope and version-2 `game_state` key set remain unchanged. Version 3 changes only the progression object:

```json
"progression": {
  "command_tether_capacity": "1",
  "unlocked_output_item_ids": [
    "RES_PROVISIONS",
    "SOUL_FORM_SCRIBE"
  ]
}
```

Rules for `unlocked_output_item_ids`:

- runtime type: `Array[StringName]` or an equally explicit typed set boundary;
- wire type: sorted array of unique JSON strings;
- every value is a valid canonical item ID;
- no display names, channel IDs, Threshold IDs, or localization keys;
- empty is valid;
- no duplicate or unsorted input is accepted;
- deep clone, mapper, validator, and equality helpers preserve it exactly.

### Version-2 to version-3 migration

The pure migration:

1. validates with the frozen version-2 validator;
2. deep-copies the complete primitive snapshot;
3. changes `schema_version` to `"3"`;
4. adds `progression.unlocked_output_item_ids = []`;
5. preserves every other byte-equivalent primitive value and the existing save revision;
6. validates the structural version-3 candidate.

Before persistence, a content-aware migration finalizer processes every existing `thresholds[*].channel_acquisition` entry in sorted Threshold/channel order:

- resolve the referenced channel in the validated compatible registry;
- require a valid non-Essence item output and correct Threshold ownership;
- add its `output_item_id` to the global access set;
- preserve progress, carry, and banked totals exactly;
- initialize any other matching source that is already available at canonical zero;
- reject contradictions rather than dropping data.

The finalizer does not grant inventory, elapsed progress, discovery bonuses, or unavailable source names. The complete sequential upgrade increments the save revision once and persists atomically before runtime exposure.

Frozen version-1 and version-2 fixtures remain immutable. Add a representative version-3 fixture containing a non-empty access set and matching source records.

### Progression runtime state

`ProgressionState` becomes:

| Field | Type | Rule |
|---|---|---|
| `command_tether_capacity` | `int` | Non-negative whole count |
| `unlocked_output_item_ids` | sorted unique `Array[StringName]` | Global mechanical access to progression-gated output items |

Tether capacity and output access are independent.

### Channel eligibility

For non-Essence channel `C` at Threshold `T`:

```text
eligible(C, T) =
    T.availability_state == AVAILABLE
    and C.enabled
    and C is referenced by T
    and C.source_threshold_id == T.id
    and C.output_item_id is a valid item
    and (
        C.progression_required == false
        or C.output_item_id in progression.unlocked_output_item_ids
    )
```

`RES_ESSENCE` channels are never eligible for `ThresholdAcquisitionState` because M04C owns Essence.

For an available Threshold, every eligible channel must have a `ThresholdAcquisitionState`; every progression-gated acquisition record must correspond to a globally unlocked item. An unavailable Threshold is not initialized or disclosed merely because its item is globally unlocked.

### Output access command

Minimum command input:

```text
output_item_id: StringName
```

Preconditions:

- valid current `GameState` and ready compatible registry;
- valid enabled item;
- at least one authored non-Essence channel outputs that item;
- caller has already resolved elapsed time to the command boundary;
- no clock, timestamp, inventory grant, or progression-cost logic is owned here.

Success result minimum:

```text
success
error_code
player_message
developer_details
change_summary
events
save_checkpoint_requested
```

Change summary minimum:

```text
output_item_id
access_added
initialized_source_channel_ids
identified_threshold_ids
already_unlocked
```

Events:

```text
OUTPUT_ITEM_UNLOCKED
OUTPUT_SOURCE_IDENTIFIED
```

`OUTPUT_ITEM_UNLOCKED` uses the item as subject. `OUTPUT_SOURCE_IDENTIFIED` uses the Threshold as subject and channel as source. Payloads are primitive and include item/channel/Threshold IDs. Events are ordered by Threshold then channel ID, are non-persisted, reportable, and tutorial-relevant when the channel is progression-required.

A repeated unlock is an idempotent success/no-op with no duplicate state, event, or checkpoint request.

### Available-source reconciliation

A reconciliation command receives an already-updated authoritative state and initializes every missing eligible source at currently available Thresholds. It is used after a Threshold-availability transaction or migration finalization.

It:

- never changes availability itself;
- never reveals unavailable Thresholds;
- never grants elapsed progress or inventory;
- is idempotent;
- emits only newly identified source events;
- requests a save checkpoint only when state changed.

### Canonical source initialization

```text
progress_subunits = 0
rate_carry_units = 0
total_banked_units = 0
```

No pre-unlock duration is represented. An access command at simulation cursor `T` does not change `simulation_time_msec`; future M04D2 production begins strictly after the committed boundary.

### Effective identification query

A pure query may reconstruct:

```text
LOCKED
IDENTIFIED
CHARTED
```

For M04D1:

- inaccessible/uninitialized progression-gated source: `LOCKED`;
- initialized source: at least `IDENTIFIED`;
- authored `CHARTED` content remains `CHARTED`;
- unavailable Threshold source is omitted rather than named.

The query does not persist an insight meter or mutate content.

## Approved M04D2 discrete-channel accumulation contract

This section is authoritative under accepted `DEC-0038` and the approved M04D2 v0.1 prompt.

### Content revision and authored values

M04D2 advances normalized content to:

```text
CURRENT_REVISION = "prototype-content-r2"
COMPATIBLE_REVISIONS = [
    "prototype-content-r1",
    "prototype-content-r2",
    "prototype-m02"
]
```

The four current non-Essence output channels use:

```text
settled_multiplier_subunits = 1_000_000
```

Both Essence channels and both Threshold core multipliers remain `250_000`. Channel IDs, output items, source Thresholds, periods, access requirements, and discovery metadata do not change. Historical revision-1 fixtures remain unchanged and compatible; new saves use revision 2.

### Simulation eligibility

M04D2 resolves a channel only when:

```text
one Reaping is active at the channel's Threshold
Threshold is AVAILABLE
channel relationship is enabled, referenced, and correctly owned
output item is valid, enabled, whole-unit, and non-Essence
ThresholdAcquisitionState already exists
and access is satisfied when progression_required == true
```

Channels are sorted by canonical channel ID. The engine does not create access or acquisition state. A locked gated channel is ineligible and produces nothing. A currently eligible missing record is an invalid complete state.

### Rate plan

For each M04C lifecycle segment:

| Context | Effective M04D2 channel rate |
|---|---|
| Overdue | Authored normalized channel rate |
| Settled | Authored normalized channel rate multiplied once by that channel's Settled multiplier |

The Threshold core multiplier is never applied. M04D2 applies no Form, Writ, Retinue, Art, Recollection, support, or global channel modifier; those prospective rate contexts belong to M04D3.

### Accumulation and banking

Given acquisition state `A`, normalized channel rate `R/P`, and segment duration `E`:

```text
acc = FixedPoint.accumulate_for_elapsed_msec(R, P, E, A.rate_carry_units)
combined = A.progress_subunits + acc.produced_subunits
whole = combined / FixedPoint.SCALE
A.progress_subunits = combined % FixedPoint.SCALE
A.rate_carry_units = acc.carry_units
A.total_banked_units += whole
inventory[channel.output_item_id].total += whole
```

Every operation is checked signed-64-bit arithmetic. Existing inventory reservations are preserved. Missing inventory entries are created only when at least one whole unit banks. A progress-only segment creates no fractional inventory entry.

Required ranges after every successful segment:

```text
0 <= progress_subunits < FixedPoint.SCALE
0 <= rate_carry_units < channel.period_msec
0 <= total_banked_units <= INT64_MAX
```

### Channel delta record

Each changed channel contributes one canonical delta to the segment and overall result:

```text
channel_id: StringName
output_item_id: StringName
banked_units_delta: int
progress_subunits_before: int
progress_subunits_after: int
rate_carry_units_before: int
rate_carry_units_after: int
total_banked_units_before: int
total_banked_units_after: int
```

Delta arrays are sorted by channel ID. They are result records, not save authority.

### Banking event

One segment-level aggregate event is emitted when `banked_units_delta > 0`:

```text
event_type = OUTPUT_CHANNEL_BANKED
occurred_simulation_msec = segment end cursor
priority = channel gain priority, before lifecycle transition
subject_id = Threshold ID
source_id = channel ID
payload = {
    output_item_id,
    quantity,
    lifecycle_state,
    total_banked_units,
    progress_subunits_after
}
reportable = true
tutorial_relevant = true
```

A progress-only delta emits no event. Events are ordered by time, priority, Threshold ID, then channel ID and are not persisted.

### Exact production fixtures

All fixtures begin with eligible zeroed acquisition records, no channel inventory, and zero channel residuals.

| Fixture | Expected channel result |
|---|---|
| Gloamwood, 2 Overdue hours | Soldier Souls `24`; Scribe progress `250_000` |
| Gloamwood, 8 Overdue hours | Soldier Souls `96`; Scribe Form Souls `1`, progress `0` |
| Broken Watch, 6 Overdue hours | Provisions `720`; Man-at-Arms Form Soul progress `250_000` |
| Broken Watch, 24 Overdue hours | Provisions `2_880`; Man-at-Arms Form Souls `1`, progress `0` |

A late-unlock fixture resolves six hours while the Scribe channel is locked, unlocks it at the exact cursor, then resolves two active hours. The channel ends at `250_000` progress and receives no six-hour backfill. An early-unlock eight-hour state banks one whole Scribe Form Soul.

A copied Settlement fixture uses one returned-soul backlog, a synthetic channel baseline of one whole unit per `1_000` ms, channel Settled multiplier `0.5`, and a `2_000` ms call. The existing core boundary remains `870` ms; channel work uses the Overdue rate through that boundary and the Settled rate afterward.

### Recall and persistence

- Recall/inactivity changes no channel progress, carry, banked history, or inventory.
- Same-loadout redispatch resumes the same Threshold-owned source state.
- Changed-loadout compatibility and modifier re-derivation remain M04D3.
- Schema version 3 persists inventory and acquisition values exactly.
- Events, deltas, effective rates, and ETAs are not serialized.
- Essence remains solely in the M04C `ReapingState.flow_carry_units` path and must never appear in channel acquisition.

### Realized M04D2 evidence

M04D2 is implemented and verified at merge commit `24228a078199d9728eb57e4e26c27447aa6911a3` from final head `96f4db53b2513a8ab6182c074113efe72d5fd968`.

The realized contract retains:

- schema version 3;
- content revision `prototype-content-r2`;
- strict complete-source validation at resolver entry and commit;
- exact initialized-source accumulation and immediate whole banking;
- current non-Essence Settled multipliers of `1_000_000`;
- aggregate reportable/tutorial-relevant `OUTPUT_CHANNEL_BANKED` events;
- exact Overdue/Settled segmentation;
- no persisted result artifacts or duplicate Essence acquisition authority.

Final owner verification passed `123/123` full tests, `15/15` focused M04D2 tests, all fourteen trace markers, import, cleanup, cleanup proof, and artifact audit.

## Approved M04D3 rate-context, loadout-identity, and acquisition-query contract

This section is authoritative under accepted `DEC-0039` and approved M04D3 prompt v0.2.

### Loadout validity is separate from rate continuity

A loadout candidate is structurally valid when all currently authoritative selection rules pass. The current prototype checks:

```text
Threshold exists, is enabled, is available, and permits the selected Form
Form exists, is enabled, revealed, awakened, and not actively assigned elsewhere
Writ exists, is enabled, and is selectable
Retinue list is empty until the Retinue assignment slice implements slot rules
command-tether capacity remains valid
```

Future rules extend the same validation result with Circle restrictions, Retinue Slot/category capacity, ownership, reservations, Arts, support policies, and other component constraints.

`ReapingAssignmentService.validate_loadout_candidate(...)` is pure and may be used while assembling a loadout. Dispatch and redispatch must invoke the same rules again immediately before mutation.

A failed commit-time revalidation indicates stale or contradictory state. It does not replace the assembly-time player-facing validation path.

### LoadoutIdentity

A non-persisted `LoadoutIdentity` contains canonical component identity:

```text
form_id: StringName
writ_id: StringName
retinue_ids: Array[StringName]  # ordered
```

Future selected component fields may extend the value object. Derived rate, output totals, ETA, and modifier values are never identity fields.

Rules:

- different component tuples remain different even when every calculated output is equal;
- equal effective-rate plans do not compare as equal loadout identities;
- collection deduplication, caches, comparison rows, assignment events, and later history/preset systems key by component identity, assignment identity, or explicit preset ID—not by output value;
- current assignment identity remains Threshold operation plus assignment revision;
- the component tuple is already persisted through existing `ReapingState` fields; a duplicate derived identity key is not serialized.

### LoadoutValidationResult

A bounded pure result contains:

```text
valid: bool
error_code: StringName
player_message: String
developer_details: String
loadout_identity: LoadoutIdentity or null
invalid_component_ids: Array[StringName]
constraint_ids: Array[StringName]
```

Arrays are canonical and sorted unless authored ordering is semantically required.

### RateContextSignature

A non-persisted `RateContextSignature` contains:

```text
returned_soul_period_msec: int
mastery_period_msec: int
cycle_duration_msec: int
essence_period_msec: int
non_essence_channel_period_msec_by_id: Dictionary[StringName, int]
```

The channel-period map contains every initialized eligible non-Essence source at the Threshold and uses canonical channel-ID ordering when rendered or compared.

The signature is about arithmetic remainder meaning. It is not a performance rating.

A numerator or multiplier change such as:

```text
1,000,000 / 14,400,000 ms
to
1,200,000 / 14,400,000 ms
```

is supported and preserves carry. A period or cycle-duration change requires exact normalization support.

### RateContextContinuityResult

A continuity comparison returns:

```text
supported: bool
error_code: StringName
developer_details: String
normalization_required_fields: Array[String]
old_signature: RateContextSignature
new_signature: RateContextSignature
old_loadout_identity: LoadoutIdentity
new_loadout_identity: LoadoutIdentity
```

When an unsupported denominator change is detected:

```text
error_code = REAPING_RATE_CONTEXT_NORMALIZATION_REQUIRED
```

`normalization_required_fields` is sorted and contains stable field paths such as:

```text
returned_soul_period_msec
mastery_period_msec
cycle_duration_msec
essence_period_msec
channel_period_msec.CHANNEL_...
```

This result is a prototype/content-authoring guard. A player-valid production loadout must not be exposed until its denominator change is exactly normalizable. Performance differences alone never cause this result.

### Supported redispatch mutation

After the caller resolves old elapsed time and recalls the operation, a supported changed redispatch preserves exactly:

```text
ReapingState.started_simulation_msec
ReapingState.flow_carry_units
ReapingState.cycle_phase_msec
ReapingState.completed_cycle_count
ThresholdState.channel_acquisition
Threshold backlog/returns/familiarity/lifecycle
inventory and reservations
```

The existing assignment transaction updates only:

```text
ReapingState.is_active = true
ReapingState.form_id
ReapingState.writ_id
ReapingState.retinue_ids
ReapingState.assignment_revision += 1
ReapingState.last_configuration_change_simulation_msec
```

The existing `REAPING_REDISPATCHED` event remains the assignment fact. No persisted rate-context entity is introduced.

### OutputChannelRatePlan

A non-persisted output-channel rate plan contains:

```text
loadout_identity: LoadoutIdentity
threshold_id: StringName
channel_id: StringName
output_item_id: StringName
lifecycle_state: StringName
baseline_rate_subunits_per_period: int
effective_rate_subunits_per_period: int
period_msec: int
lifecycle_multiplier_subunits: int
applied_modifiers: Array[ModifierTraceEntry]
```

Two plans may be numerically equal while their `loadout_identity` and source trace remain different.

A `ModifierTraceEntry` contains save-safe primitive diagnostic values:

```text
source_type = FORM_TRAIT
source_id = Trait ID
modifier_index: int
metric = OUTPUT_CHANNEL_RATE
operation = MULTIPLY
scope = OUTPUT_CHANNEL
condition
condition_values: Array[String]
multiplier_subunits: int
rate_before_subunits_per_period: int
rate_after_subunits_per_period: int
```

Form Trait evaluation order is authored Trait order, then authored modifier order. Each multiplication floors once through central checked fixed-point arithmetic. The channel lifecycle multiplier is applied last and exactly once.

Supported conditions are:

```text
ALWAYS
OUTPUT_ITEM
OUTPUT_KIND
THRESHOLD_HAS_ANY_TAG
THRESHOLD_LIFECYCLE
```

Multiple operands use deterministic any-match semantics. Relevant malformed or unsupported operation/scope/condition data returns a typed failure. Non-`OUTPUT_CHANNEL_RATE` modifiers are irrelevant and ignored.

### Modifier-source boundary

M04D3 executes active Form Trait modifiers only.

The following remain non-executable until authoritative state and command boundaries exist:

```text
Writ rate modifiers
Retinue rate modifiers
Form Arts
Recollection modifiers
support-state modifiers
global efficiencies
```

The rate-plan API must accept later normalized sources without changing stored progress or deriving from a previous effective rate. Production content remains unchanged; copied fixtures provide `x1.20` and equal-output/different-loadout demonstrations.

### AcquisitionQueryResult

A pure query result contains:

```text
success: bool
error_code: StringName
developer_details: String
loadout_identity: LoadoutIdentity or null
threshold_id: StringName
channel_id: StringName
output_item_id: StringName
access_state: StringName
disclosure_state: StringName
is_active: bool
lifecycle_state: StringName
progress_subunits: int
progress_tenths_percent: int
rate_plan: OutputChannelRatePlan or null
eta_available: bool
current_context_eta_msec: int
eta_basis = CURRENT_RATE_CONTEXT
eta_display: EtaDisplayValue or null
```

Rules:

- locked or uninitialized progression-gated source: `access_state = LOCKED`, no active plan or ETA;
- initialized source: at least `IDENTIFIED`;
- authored Charted source remains `CHARTED`;
- unavailable Threshold source is not exposed as active;
- Essence is rejected because its authority remains M04C core flow;
- inactive Reaping returns stored progress but no active ETA;
- active eligible Reaping returns the current plan and exact current-context ETA.

Percentage uses:

```text
floor(progress_subunits * 1000 / FixedPoint.SCALE)
```

and cannot display `100.0%` for a stored remainder.

ETA is the smallest non-negative integer millisecond duration for which checked accumulation using current rate, period, progress, and carry reaches the next whole boundary. The algorithm uses bounded search or an equivalent checked exact method and never loops once per millisecond.

### EtaDisplayValue

`EtaDisplayValue` is derived, non-authoritative, and localization-ready:

```text
exact_eta_msec: int
components: Array[EtaDisplayComponent]  # exactly 3 when present
fallback_text: String
```

Each component contains:

```text
unit: DAY | HOUR | MINUTE | SECOND
value: int
```

Formatting rules:

```text
eta < 86,400,000 ms:
    HOUR, MINUTE, SECOND

eta >= 86,400,000 ms:
    DAY, HOUR, MINUTE
```

Additional rules:

- only DAY, HOUR, MINUTE, and SECOND are valid;
- no more than three units are shown; these templates show exactly three;
- values use a minimum two-digit display width;
- days may exceed two digits and are never converted to weeks, months, or years;
- English fallback text uses singular for value `1` and plural otherwise;
- positive sub-second ETA rounds up to one displayed second;
- backend `current_context_eta_msec` remains unchanged and exact;
- player-facing fallback text never displays aggregate milliseconds.

Required examples:

```text
13,935,000 ms
-> 03 hours, 52 minutes, 15 seconds

183,840,000 ms
-> 02 days, 03 hours, 04 minutes
```

### Persistence and compatibility

M04D3 adds no authoritative state.

```text
save schema = 3
content revision = prototype-content-r2
```

The following never serialize:

```text
LoadoutValidationResult
LoadoutIdentity derived key
RateContextSignature
RateContextContinuityResult
OutputChannelRatePlan
ModifierTraceEntry
AcquisitionQueryResult
EtaDisplayValue
effective rate
progress percentage
ETA
```

Selected component IDs already persisted in `ReapingState` remain authoritative. After supported redispatch and subsequent production, existing Reaping, Threshold acquisition, inventory, assignment revision, and simulation fields round-trip through schema v3 exactly.

## Realized M04D3 evidence

M04D3 merged through PR #15 from final head `5a5cafc6b640001fba86c7ea9531ae9daf43fcc3` at merge commit `9fd8f98e3787f711f3d03c9de03d3615d531216a`.

The realized derived contracts preserve:

- component-based loadout identity inside every public output-channel rate plan;
- canonical authored modifier operands and legacy lifecycle normalization;
- initialized-source disclosure of at least `IDENTIFIED`;
- null ETA display when no active ETA exists;
- exact-millisecond ETA template selection;
- the canonical `non_essence_channel_period_msec_by_id` residual-signature field;
- no serialization of validation, identity-key, rate, modifier-trace, percentage, or ETA artifacts.

Schema version 3 and content revision `prototype-content-r2` remain current.

## Realized M04E1 simulation-run and forecast contracts

M04E1 merged through PR #16 from final head `738e89c606dd9f1f9f0396334ea9d8587ff389f3` at merge commit `03f05a3d78609a993cecab8b0077e5f7d7d55900`.

The realized non-persisted result contains:

```text
success: bool
error_code: StringName
developer_details: String
mode: StringName
requested_elapsed_msec: int
baseline_simulation_time_msec: int
result_simulation_time_msec: int
simulation_result: SimulationEngine.SimulationResult or null
projected_state: GameState or null
```

Rules:

- committed foreground-supplied, offline-fixture, and debug modes use the exact shared engine and return no projection;
- successful forecast returns a detached projection and leaves the baseline and source save bytes unchanged;
- wrapper failures before engine invocation have `simulation_result = null`;
- engine failures retain the exact engine result and return no projection;
- generic core streams and initialized eligible engine-supported channel state/deltas pass through without a forecast whitelist;
- no run, projection, comparison, segment, event, or mode value serializes.

Final Windows evidence passed `153/153` full tests and `2,522` assertions before and after the trace, `9/9` focused tests and `295` assertions, all fifteen markers, import, cleanup, cleanup proof, and artifact audit.

## Approved M04E2A report-state and schema-v4 contracts

These contracts are authoritative under accepted `DEC-0041` and approved M04E2A prompt v0.2.

### Schema version 4

Schema version 4 extends `game_state` with:

```text
report_state
```

Codec remains `JSON_V1`. Content revision remains `prototype-content-r2`.

Every authoritative integer continues to serialize as a canonical base-10 string. Arrays and maps serialize in canonical order. Runtime report objects use typed `RefCounted` classes and explicit mapping; they are not saved through Resources, Nodes, generic object serialization, or JSON cloning.

### `ReportState`

```text
ingested_through_simulation_msec: int
next_report_sequence: int
next_event_sequence: int
dropped_history_count: int
live: ReportAccumulatorState
history: Array[ReportRecord]
```

Rules:

- `0 <= ingested_through_simulation_msec <= GameState.simulation_time_msec`;
- next sequences are positive;
- counters are non-negative;
- retained history sequences are strictly increasing and unique;
- history length is at most `REPORT_HISTORY_LIMIT`;
- no runtime object aliases another live/history/query object.

### `ReportAccumulatorState`

```text
window_started_simulation_msec: int
window_ended_simulation_msec: int
ingested_run_count: int
committed_mode_counts: Dictionary[StringName, int]
attribution_slices: Array[ReportAttributionSlice]
event_type_counts: Dictionary[StringName, int]
recent_events: Array[ReportEventRecord]
omitted_event_count: int
```

Rules:

- start and end are non-negative and ordered;
- an empty accumulator has start=end=report cursor, zero runs, empty slices/maps/events, and zero omitted count;
- a positive no-gain run advances end and run count even when slices/events remain empty;
- mode-count totals equal `ingested_run_count`;
- slices are ordered by `(threshold_id, assignment_revision, lifecycle_order)`;
- recent events are ordered by persistent event sequence;
- recent events never exceed `REPORT_RECENT_EVENT_LIMIT`.

### `ReportRecord`

An archived report deep-copies the complete live accumulator and adds:

```text
report_sequence: int
snapshot_reason: StringName
snapshot_simulation_msec: int
```

Allowed reasons:

```text
MANUAL_REVIEW
OFFLINE_RETURN
SYSTEM_BOUNDARY
```

`OFFLINE_RETURN` requires a non-empty window whose committed mode counts contain only the approved offline committed mode. Under M04E1 this is `OFFLINE_FIXTURE`.

A record is immutable after insertion. Viewing it does not change state.

### `ReportAttributionSlice`

The persisted reporting unit is:

```text
threshold_id: StringName
assignment_revision: int
lifecycle_state: StringName
loadout_identity: ReportLoadoutIdentity
window_started_simulation_msec: int
window_ended_simulation_msec: int
elapsed_msec: int
returned_souls_delta: int
backlog_reduced: int
completed_cycles_delta: int
inventory_gains_by_item_id: Dictionary[StringName, int]
mastery_gains_subunits_by_form_id: Dictionary[StringName, int]
channel_summaries_by_channel_id: Dictionary[StringName, ReportChannelSummary]
```

Identity and ordering rules:

- `threshold_id` is the current Threshold-scoped Reaping operation identity;
- `assignment_revision` is positive and identifies one loadout/activation episode;
- `lifecycle_state` is one of the engine-supported canonical lifecycle tokens;
- the unique key is `(threshold_id, assignment_revision, lifecycle_state)`;
- equal loadout or equal numeric output does not merge different revisions;
- returning to an earlier component tuple produces a new revision and a separate slice;
- `elapsed_msec` equals the sum of exact engine segment durations aggregated into the slice;
- start is the earliest included segment start and end is the latest included segment end;
- all maps are stable-ID keyed and canonically ordered;
- every numeric aggregation uses checked signed-64-bit arithmetic.

### `ReportLoadoutIdentity`

```text
form_id: StringName
writ_id: StringName
ordered_retinue_ids: Array[StringName]
```

This is component identity only. Display names, rates, ETA, modifier totals, and output vectors are not identity.

### `ReportChannelSummary`

```text
threshold_id: StringName
channel_id: StringName
output_item_id: StringName
elapsed_msec: int
banked_units_delta: int
progress_subunits_start: int
progress_subunits_end: int
rate_carry_units_start: int
rate_carry_units_end: int
total_banked_units_start: int
total_banked_units_end: int
```

Rules:

- IDs exist in the validated registry and ownership relationship;
- progress/carry/history endpoints exactly match the first and last included engine deltas;
- banked delta and elapsed values checked-add across contiguous segments/runs;
- generic item/channel IDs pass through without a current prototype whitelist;
- no fractional inventory is created.

### `ReportEventRecord`

```text
event_sequence: int
event_type: StringName
occurred_simulation_msec: int
priority: int
subject_id: StringName
source_id: StringName
```

Only events with `reportable == true` are retained. Raw arbitrary event payload dictionaries are not persisted. Typed attribution/channel summaries retain report quantities.

### Derived report read model

Read models are detached and non-authoritative. A global or filtered view may expose:

```text
window start/end and elapsed
overall returned Souls/backlog reduction/cycles
overall inventory_gains_by_item_id
overall mastery_gains_subunits_by_form_id
Threshold operation groups
assignment/loadout episode groups
lifecycle groups
channel groups
event counts/recent detail
is_empty
has_whole_gain
has_progress_change
has_meaningful_event
```

Required pure queries are equivalent to:

```text
peek_live_global(state)
peek_live_threshold(state, threshold_id)
peek_live_assignment(state, threshold_id, assignment_revision)
get_report_record(state, report_sequence)
```

Queries:

- never mutate report or gameplay state;
- never increment sequences;
- never request checkpoints;
- never write files;
- return detached data;
- use the current live-window boundary rather than a persisted last-click timestamp;
- retain zero-valued facts internally even when later presentation chooses to hide them.

### Committed simulation ingestion result

Public service results contain at least:

```text
success
error_code
developer_details
changed
duplicate
checkpoint_requested
report_cursor_before
report_cursor_after
```

Ingestion accepts only successful committed M04E1 modes with `projected_state == null` and an exact successful `simulation_result`.

Interval rules:

```text
zero duration:
  unchanged success

result end <= report cursor:
  duplicate unchanged success

result baseline < report cursor < result end:
  REPORT_INTERVAL_OVERLAP

result baseline > report cursor:
  REPORT_INTERVAL_GAP

result baseline == report cursor and candidate cursor == result end:
  aggregate exactly once
```

Requested elapsed and engine committed elapsed must equal `result end - baseline`. Failed, forecast, projected, malformed, and cursor-inconsistent inputs reject without mutation.

For an accepted interval, each exact engine segment is mapped to the slice selected by:

```text
segment threshold_id
segment assignment_revision
segment lifecycle_state
```

The exact committed engine segment supplies canonical historical loadout identity (`form_id`, `writ_id`, and ordered `retinue_ids`) plus duration and core/channel facts. The service does not reconstruct past attribution from the mutable current Reaping record and does not recompute production.

### Offline report isolation

`committed_mode_counts` is persisted in live and archived state.

To archive `OFFLINE_RETURN`:

- live must be non-empty;
- every ingested run in the window must use the approved offline committed mode;
- a mixed foreground/debug/offline window rejects with a typed error;
- callers archive any pre-existing foreground live window before ingesting the offline interval.

M04E2A provides the state and validation contract. M06 later owns trusted-time orchestration.

### Snapshot result

Expected API:

```text
snapshot_live(state, expected_next_report_sequence, snapshot_reason)
```

A non-empty snapshot requires:

- report cursor equals gameplay simulation cursor;
- expected sequence equals `next_report_sequence`;
- snapshot reason is valid;
- offline purity holds for `OFFLINE_RETURN`;
- complete candidate validation succeeds.

Success deep-copies live into one record, appends in sequence order, increments sequence, resets live at the cursor, prunes oldest history beyond 20, increments `dropped_history_count` for each pruned record, and requests one checkpoint.

An empty live accumulator is an unchanged success. No destructive clear, history delete, or partial per-Threshold clear exists in M04E2A.

### Retention and Codex Mortis boundary

```text
REPORT_HISTORY_LIMIT = 20
REPORT_RECENT_EVENT_LIMIT = 64
```

History is recent player-readable report history. It is not a permanent statistical ledger. Later Codex Mortis graphs, cumulative statistics, and time buckets require a separate authoritative analytics contract and retention policy. M04E2A adds no analytics state, but its stable report records can be consumed prospectively by that later owner.

### Schema migration

The production migration chain becomes:

```text
v1 -> v2 -> v3 -> v4
```

The pure `v3 -> v4` step:

- validates the complete frozen v3 source;
- deep-copies the source;
- sets schema version to `4`;
- adds canonical empty `report_state`;
- initializes report/live cursors to the source simulation cursor;
- initializes report/event sequences to `1`;
- creates no history;
- fabricates no previous report;
- preserves save revision, content revision, codec, metadata, time authority, offline identity, and all gameplay exactly.

Persisted upgrade increments save revision once through the existing coordinator. Current v4 loads without rewrite. Future versions reject without overwrite.

### Persistence exclusions

Do not serialize:

- `SimulationRunResult`;
- `SimulationResult` objects;
- forecast projections;
- ReportService result objects;
- derived report read models;
- UI formatting or last-click state;
- raw arbitrary event payloads;
- a report coordinator;
- Codex analytics state.

## Approved high-level M04E2B atomic reported-run boundary

M04E2B adds no schema fields. It will introduce a narrow `SimulationReportCoordinator` that performs one candidate transaction:

```text
clone live state
  -> committed SimulationRunService call on candidate
  -> ReportService ingestion on candidate
  -> complete candidate validation
  -> one live copy_from commit
```

The coordinator's result contains the exact `SimulationRunResult`, report-ingestion result, and checkpoint request. It never accepts forecast mode. Any failure leaves both gameplay and report state unchanged.

The final M04 harness will compare a M04E1 forecast with an equivalent atomic reported commit, snapshot report sequence 1, prove gameplay gains preexist report inspection, and round-trip the record through schema version 4.

M04E2B receives no implementation prompt until M04E2A is Merged and Passed.

## M04E2A report state schema-v4 addition

Schema v4 adds `game_state.report_state` while retaining `JSON_V1` and `prototype-content-r2`. The report state stores a simulation-time report cursor, live window, monotonic report/event sequences, bounded recent history, attributed slices keyed by Threshold ID, positive assignment revision, and lifecycle state, plus bounded reportable event details. All report integers continue to use decimal-string wire encoding; report records are explanatory only and never claim, grant, delay, or remove gameplay output.
