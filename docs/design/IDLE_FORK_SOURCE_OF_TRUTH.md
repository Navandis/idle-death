# Death Idle - Idle Fork Source of Truth

**Document role:** Maintained implementation context for the idle/incremental branch  
**Repository path:** `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md`  
**Markdown revision:** 4  
**Last updated:** 2026-07-14  
**Primary source:** *Death Idle - Idle & Incremental Fork - Design Direction v0.1* (12 July 2026)  
**Companion prototype contract:** [PROTOTYPE_0_90_SOURCE_OF_TRUTH.md](PROTOTYPE_0_90_SOURCE_OF_TRUTH.md)

## 1. Purpose and authority

This file is the normal operational source for Codex when a task depends on the broader Death Idle product direction, system vocabulary, idle-model invariants, or expansion-compatible constraints. It is an implementation-oriented condensation, not a verbatim conversion of the source DOCX.

Use the following precedence order:

1. The latest explicit instruction from the project owner for the current task.
2. `PROTOTYPE_0_90_SOURCE_OF_TRUTH.md` for prototype-specific sequence, tutorial behavior, first-session content, guarantees, and acceptance criteria.
3. This file for broader design rules, terminology, product boundaries, and intended system ownership.
4. Approved records in `docs/codex/DECISIONS.md` when they clarify or deliberately supersede ambiguous source wording.
5. Existing repository behavior and other maintained documentation.
6. Recommendations made during implementation.

Do not silently resolve a conflict. Check the decision record, state the practical consequence, and request a decision when the hierarchy does not settle it.

### Status labels

| Label | Meaning |
|---|---|
| **Confirmed** | Implement unless an explicit later decision changes it. |
| **Prototype confirmed** | Required for the current 0-90 minute prototype; later balance or presentation may change. |
| **Provisional** | A scaffold value or mechanism that must remain configurable and be tested. |
| **Deferred** | Valid later direction, but not required for the current prototype. |
| **Out of scope** | Must not be implemented during the current prototype without explicit approval. |
| **Open** | Requires a focused design decision or playtest evidence. |

## 2. Product identity and boundaries

**Status: Confirmed**

Death Idle is a 2D, UI-led idle and incremental management game for Windows PC. The player is Death, newly awakened after roughly three thousand years of absence and restricted by ancient chains and seals. The mortal world has accumulated impossible soul debts. The player restores the machinery of mortality by opening Thresholds, assigning Forms, fielding Retinues, rebuilding Halls, recovering Recollections, settling finite backlogs, and weakening the seals that limit Death's authority.

The initial commercial storefront target is Steam. Broad Steamworks integration, achievements, cloud saves, depot configuration, DRM, and release packaging are not part of the current prototype. The sole approved exception is a narrowly scoped external trusted-time adapter required to prevent local-wall-clock offline credit; it remains behind a project-owned interface at the platform boundary. Core game state, simulation, saves, and content remain independent of a storefront SDK. Epic Games Store, GOG, or other storefronts are possible later only when demand and return on implementation effort justify them.

### Design thesis

> Complex setup, simple execution, transparent unattended resolution.

The player makes macro-level configuration decisions. The game executes them continuously, banks ordinary output automatically, and explains the consequences clearly when the player returns.

### What the game is

- A persistent idle/incremental management game about restoring cosmic order.
- A build-optimization game driven by Forms, Writs, Retinues, Halls, Stores, discovery, Recollections, and limited command capacity.
- A narrative mystery with a visible long-term progression horizon.
- A game in which finite campaign goals coexist with renewable post-clear economies.
- A restrained 2D production suitable for solo development and selective outsourcing.

### What the game is not

- An action RPG, tactical battler, or rapid-input clicker.
- A combat simulator built around attacks, critical hits, cooldown rotations, or animation-heavy encounters.
- A dialogue-first visual novel that delays the core loop for a long period.
- A one-way map in which early choices can permanently destroy critical sources.
- A large RPG, colony simulation, procedural world, or squad-management game.

### Tone and language

Death is a cosmic office, not a sadist, conqueror, or corpse collector. The tone is medieval high fantasy without grimdark excess. It supports dry humor, strange bureaucracy, solemn wonder, and occasional tenderness. Eustace provides argumentative humor without trivializing the underlying disorder.

Preferred verbs include **return, guide, restore, remember, weave, settle, balance, dispatch, preserve, cleanse, release, fulfill, chart,** and **account**.

Avoid language that frames souls as disposable troops or loot. Avoid terms such as **minions, slaughter, troop HP, resurrecting troops,** and **DPS** in player-facing text. Use **settled** or **duty fulfilled** for normal Calling Soul release, and reserve **scattered** for serious failure.

## 3. Design pillars

**Status: Confirmed**

| Pillar | Implementation consequence |
|---|---|
| Complex setup, simple execution | The player may compare Forms, Writs, Retinues, and forecasts, but an active operation must not require frequent maintenance. |
| Finite progress, renewable access | Overdue backlogs can be exhausted; essential sources remain available in lower-volume Settled Passage behavior. |
| More opportunities than command tethers | The player should usually have more worthwhile objectives than active Reaping capacity. |
| Forms are economic strategies | A Form changes throughput, preservation, discovery, targeting, logistics, hazard handling, or outcome shaping. |
| Identity survives the idle conversion | The fixed thirty-Form Soulweave remains meaningful through ancestry, one innate Trait, structural Retinue Slots, and later Mastery-gated Arts. |
| Logistics determine efficiency, not permission | Shortages reduce rate, quality, or premium effects. A valid Standing Reaping should rarely become completely inert. |
| Visible compounding | Rate, yield, quality, and efficiency are distinct and should visibly improve through different systems. |
| Information is progression | Basic clarity is free; improved forecasts, source knowledge, comparisons, records, and automation are progression rewards. |
| No permanent tutorial regret | Critical sources are guaranteed, discovery is recoverable, and finite backlog progress cannot consume irreplaceable hidden rewards. |
| Milestones inside milestones | Cycles, backlog thresholds, settlement, regional completion, and seal work create nested payoff horizons. |

## 4. Core idle loop and session rhythm

**Status: Confirmed**

1. Choose an objective: backlog settlement, Corrupted Essence, a Whole Soul source, materials, Mastery, Recollection progress, or seal progress.
2. Allocate limited command tethers among available Thresholds.
3. Configure each Reaping with a leading Form, Writ, compatible Retinues, and support policy.
4. Allow Reapings and Halls to operate online and offline.
5. Review reports that explain gains, milestones, discoveries, bottlenecks, support changes, and changed estimates.
6. Invest in the Soulweave, Recollections, Halls, support capacity, and seals, then reconfigure where the next marginal gain is greatest.

Expected session rhythms:

| Session type | Expected behavior |
|---|---|
| Short check-in, roughly 2-5 minutes | Review a report, spend one upgrade, adjust one assignment, leave production running. |
| Active optimization, roughly 15-30 minutes | Compare forecasts, awaken a Form, change a Writ, move a Retinue, restore a Hall, or pursue a milestone. |
| Long first/content session | Experience narrative beats, unlock systems, make linked investments, and establish new production chains. |
| Extended absence | Resolve elapsed time analytically, apply fallbacks, cross milestones, and enter Settled Passage when required. |

## 5. Player-facing vocabulary and system ownership

**Status: Confirmed**

| Term | Mechanical meaning and owner |
|---|---|
| Form / Soulform | A persistent operational archetype assigned to lead a Reaping. Form definitions own Traits, slot profiles, and modifiers. |
| Soulweave | The fixed thirty-Form progression structure across five Circles. It owns awakening and ancestry relationships. |
| Circle | A Soulweave tier, First through Fifth. |
| Mastery | Use-based progression earned primarily while a Form leads productive Reapings. Mastery later gates Form Arts. |
| Threshold | A passage to a location in the living world. |
| Overdue Threshold | A Standing Threshold with a finite accumulated soul backlog. |
| Settled Passage | A cleared Standing Threshold that continues to receive lower-volume natural deaths. |
| Reaping | A persistent automated soul-return operation assigned through a Threshold. |
| Writ | The operating policy for priorities, support behavior, fallback rules, and risk posture. |
| Command tether | One slot of active Reaping capacity. |
| Reaping Report | A non-blocking summary of gains, progress, discoveries, bottlenecks, milestones, and later service outcomes. |
| Stores | Global logistics stockpiles such as Rations, Tools, Wards, Armaments, and Medical Supplies. |
| Support buffer | A small per-Reaping allocation maintained automatically under a Writ. |
| Stable Runtime | How long the current setup is expected to remain at intended efficiency before degrading, not how long it can produce anything. |
| Whole Soul | A cleanly recovered soul that retained meaningful identity. |
| Form Soul | A Whole Soul tied to a Soulweave Form. |
| Calling Soul | A Whole Soul tied to an ordinary mortal calling and used for Retinues, Halls, and later service systems. |
| Denizen Soul | A Whole Soul of a creature, spirit, monster, undead being, or other Threshold inhabitant. |
| Recollections | Recovered global rules, capabilities, automation, knowledge, and lost principles of Death's authority. |
| Codex Mortis | Glossary, source records, performance history, statistics, and later advanced analysis. |
| Halls | Persistent conversion and infrastructure systems. |
| Seals | Major account progression, chapter gates, capacity changes, and restored authority. |

## 6. Architecture-level design invariants

The identifiers below are stable requirement references for later architecture and milestone documents.

- **IF-REQ-01 - Persistent assignments:** A Standing Reaping continues until intentionally reassigned or otherwise resolved by an explicit rule. Routine collection never requires recall.
- **IF-REQ-02 - Automatic banking:** Ordinary production is applied to authoritative global state immediately. A report is not a claim gate.
- **IF-REQ-03 - No presentation pause:** Reapings and Halls continue while menus, dialogue, reports, forecasts, and tutorial overlays are open.
- **IF-REQ-04 - Finite-to-renewable Thresholds:** An Overdue backlog is finite campaign progress. At zero, an active Standing Reaping automatically continues under Settled Passage rules.
- **IF-REQ-05 - Renewable essential sources:** Settlement cannot permanently remove an essential source or punish early experimentation.
- **IF-REQ-06 - Graceful degradation:** Ordinary support shortages reduce affected effects, rates, or premium channels; valid base backlog, Essence, and Mastery progress continue.
- **IF-REQ-07 - Shared simulation:** Online progress, offline progress, and forecasts use the same authoritative rules and balance data.
- **IF-REQ-08 - Deterministic elapsed-time resolution:** Resolve analytically or in meaningful deterministic segments, not by replaying rendered frames or every elapsed second.
- **IF-REQ-09 - Independent channels:** Backlog, Essence, Mastery, Form Souls, Calling Souls, Denizen Souls, and materials resolve independently unless an approved rule explicitly links them.
- **IF-REQ-10 - Hidden output remains real:** Production generated before discovery is banked and becomes visible later; discovery never retroactively creates or deletes earlier output.
- **IF-REQ-11 - Additive guarantees:** Tutorial-critical reward floors add only the missing amount, preserve legitimate gains, and remain idempotent across save/load.
- **IF-REQ-12 - Recoverable deviations:** A valid non-recommended Form assignment may be slower but cannot permanently block required progress.
- **IF-REQ-13 - Reserved Calling Souls:** Retinue assignment reserves the complete required cohort; it does not silently consume or destroy those Souls.
- **IF-REQ-14 - Domain ownership:** Tutorial and UI code may request actions or present results, but they do not own duplicate resource, Reaping, Form, Retinue, Hall, or save rules.
- **IF-REQ-15 - Save integrity:** Active operations, accumulated state, guarantees, unlocks, reservations, Hall state, tutorial state, reports, and timestamps must reconstruct correctly after load.
- **IF-REQ-16 - Storefront independence:** Authoritative gameplay rules, save-schema meaning, and content must not depend on Steamworks or another storefront SDK. A narrowly approved platform adapter may supply trusted time through the project-owned interface, but domain and simulation code remain storefront-independent.
- **IF-REQ-17 - Trusted time authority:** Foreground elapsed time uses a monotonic process clock. Closed-session elapsed time is credited only from an approved external trusted-time provider; the player's local wall clock, timezone, calendar, file timestamps, and manually supplied time are never authoritative fallbacks. If trusted time is unavailable, unresolved closed-session progress remains pending rather than being guessed.
- **IF-REQ-18 - Persistent long-horizon source progress:** Deterministic partial progress toward a rare whole output belongs to its Threshold channel, survives Form/Writ/Retinue reconfiguration and inactivity, banks whole units automatically, and is never represented as fractional inventory.

## 7. Incremental progression architecture

**Status: Confirmed direction; exact formulas provisional**

### Four visible growth axes

| Axis | Player question | Typical owners |
|---|---|---|
| Rate | How quickly does a Reaping resolve cycles and reduce backlog? | Form baseline, Mastery, Martial support, Writ, Threshold fit, later scale-oriented Forms. |
| Yield | How much useful value does each cycle produce? | Threshold familiarity, Retinues, Halls, Writs, tags, material systems. |
| Quality | How often are Whole Souls, rare Souls, or premium materials recovered? | Preservation-oriented Forms, Ritual/Recovery/Specialist support, later Recollections. |
| Efficiency | How long can the setup remain optimal and how much support does it consume? | Logistics-oriented Forms, Halls, support policies, Recollections, later Recovery systems. |

### Distinct system responsibilities

| System | Primary responsibility |
|---|---|
| Form Mastery | Sustained use, Form-specific milestones, later Arts, and competence with that archetype. |
| Threshold familiarity | Better forecasts, discovered channels, local yield, and location-specific knowledge. |
| Halls | Persistent conversion capacity, Store production, Keeper assignments, and infrastructure. |
| Recollections | Global rules, automation, offline capacity, knowledge, and system unlocks. |
| Soulweave | Horizontal specialization, ancestry, new build identities, and capstone direction. |
| Seals | Large account transformations, chapter gates, additional command tethers, and restored authority. |

Do not let every system collapse into interchangeable global percentage bonuses. Each progression layer should change a different part of the player's decision model.

## 8. Thresholds, backlogs, channels, and discovery

### Standing Threshold lifecycle

**Status: Confirmed**

| State | Behavior |
|---|---|
| Overdue | Finite backlog, high density, visible milestones, strong campaign and seal progress. |
| Settled Passage | Backlog is zero; lower and steadier renewable natural passage; essential sources remain accessible. |

Frayed and Anchored Thresholds are valid later concepts but are deferred from the current prototype.

### Backlog rule

A backlog is a deterministic campaign objective, not a pre-generated bag of individual drops. Form choice can affect rate and output weighting, but it cannot determine whether irreplaceable tutorial or progression items still exist. Critical rewards may be milestone-linked. Essential sources remain renewable after settlement.

### Parallel output streams

| Stream | Produces |
|---|---|
| Backlog | Souls Returned and settlement progress. |
| Essence | Corrupted Essence generated from returned souls and local conditions. |
| Mastery | Mastery for the leading Form while the Reaping is productive. |
| Form Soul channel | Location-appropriate Form Souls. |
| Calling Soul channel | Location-appropriate ordinary callings. |
| Denizen Soul channel | Creature, spirit, monster, undead, or other non-Soulweave inhabitants. |
| Material channel | Raw resources such as Provisions, Metal, Remains, Timber, Stone, Reagents, or Relics. |

### Discovery states

| State | Player-facing information |
|---|---|
| Unknown | Question mark or hidden category; no expected range. |
| Identified | Name, icon, and qualitative frequency. |
| Charted | Expected range, relevant modifiers, and known source relationships. |

Scribe-line Forms, Specialist Retinues, Recollections, repeated operation, and later Codex upgrades improve discovery speed or precision. Discovery changes information, not whether production occurred.

### Long-horizon discrete acquisition progress

**Status: Confirmed direction through `DEC-0026`, `DEC-0027`, and `DEC-0028`**

Some rare Souls, Denizen Souls, catalysts, or future materials may require many hours of productive Threshold operation before one whole unit is banked. These sources use deterministic accumulated acquisition progress rather than an opaque item timer or fractional inventory.

- Partial acquisition progress is owned by the Threshold's stable output channel/source and represents normalized completed work toward the next whole unit.
- The stored percentage is not elapsed time and is not recalculated from the current estimated duration.
- A Form, Writ, Retinue, Form Art, Recollection, support state, or other modifier change first resolves elapsed time to the exact change boundary under the old rate. The new configuration changes only the future rate.
- Existing progress is never multiplied by a newly acquired efficiency bonus. Recalling and redispatching the same loadout cannot apply the same bonus again because effective rate is always derived from the authored baseline plus current modifiers, never from a previous effective rate. The channel keeps one stable normalized rate period within the current content revision; ordinary live bonuses alter future throughput rather than changing that denominator.
- At `50.0%` progress, a stronger setup can shorten the remaining estimate from two hours to one hour forty minutes while the bar remains `50.0%`. Ordinary rate modifiers do not turn the bar into `60.0%` or reduce the displayed remaining percentage to `40.0%`.
- An inactive Threshold retains progress without advancing it.
- Settlement does not clear progress when the source remains available in Settled Passage.
- Whole items are banked automatically when progress crosses the whole-unit boundary; the remainder continues toward the next item.
- Unknown progress remains hidden. Once Identified, the Threshold may show a progress bar and a percentage truncated to one decimal place. It must not present a fractional Soul or catalyst count.
- A future effect intended to grant retroactive progress must be authored as an explicit, exactly-once progress grant. It must not masquerade as a rate modifier.
- This is resolved by the shared simulation engine and is not a separate timer per item.

## 9. Persistent Reapings, Writs, support, and offline resolution

### Persistent assignment model

**Status: Confirmed**

A Standing Reaping begins when a Form is assigned to an available Threshold and continues until the player strategically reassigns it. Recall or reconfiguration is used to change the Form, Writ, or Retinues, not to collect ordinary output. When the backlog reaches zero, remaining time resolves under Settled Passage behavior rather than being discarded.

For the prototype, the Emergency Writ is a temporary policy on the first Gloamwood Reaping. At 1,000 returned Gloamwood souls it transitions seamlessly to Standard behavior. The authoritative Reaping does not stop, release its tether, discard its accumulator, or require a second dispatch. Presentation may guide the player through adding the Soldier Company and reviewing the Standard configuration, but it must not create a stop-and-restart lifecycle.

### Writ direction

| Writ | Status | Role |
|---|---|---|
| Emergency Writ | Prototype confirmed | First 1,000 Gloamwood souls, then automatic transition to Standard. |
| Standard | Prototype confirmed | Balanced persistent default. |
| Low-Upkeep Watch | Deferred | Lower rate, conservative support use, stronger unattended floor. |
| Mass Harvest | Deferred | High backlog rate, Essence, and Mastery with aggressive support use and weaker quality. |
| Preservation | Deferred | Prioritizes Whole Souls, safety, and clean Calling Soul recovery. |
| Extraction Focus | Deferred | Prioritizes materials, Denizen Souls, and high-value physical sources. |
| Deep Incursion | Deferred / tentative | Escalating push content separate from Standing Reapings. |
| Custom Writ | Deferred | Later reserve floors, source priorities, fallbacks, and stop conditions. |

### Support model

Halls produce global Stores. A Reaping maintains a small support buffer according to its Writ and draws automatically while respecting later reserve rules. The prototype begins with a simple Ration policy for the Soldier Company.

| Support condition | Expected behavior |
|---|---|
| Fully supported | Full Reaping rate, Retinue effects, premium channels, and mitigation. |
| Running low | Forecast warns the player; affected premium effects may begin to soften. |
| Depleted | Base backlog, Corrupted Essence, and Mastery continue; affected Retinue or premium effects operate at a reduced value. |
| Fallback enabled | A later Writ may switch automatically to a low-upkeep behavior. |

Stable Runtime must state the likely bottleneck and the post-bottleneck behavior. It is not a countdown until all production stops.

### Elapsed-time resolution

**Status: Confirmed architecture; exact rates and caps open**

Use one authoritative resolver for online, forecast, and offline calculation. The resolver accepts an elapsed duration; it does not read clocks directly. Foreground duration comes from an injected monotonic process clock. Closed-session duration comes only from an approved external trusted-time provider. Do not derive authoritative offline progress from the player's local date, time, timezone, calendar, file modification times, or a manually entered timestamp. If the trusted provider is unavailable, load committed state, continue foreground production, and leave closed-session reconciliation pending until trust returns.

Split elapsed time at meaningful state boundaries, including:

- support depletion or recovery;
- milestone grants;
- discovery changes;
- backlog reaching zero;
- Hall output target completion;
- fallback transitions;
- any other event that changes the active rule set.

For each segment, resolve production under the current state, apply the boundary transition exactly once, and continue with the remaining interval.

Required properties:

- Idempotent repeated load behavior.
- Automatic Overdue-to-Settled transition.
- No ordinary hard failure from support depletion.
- Transparent offline caps or storage ceilings if later introduced.
- Deterministic tutorial guarantees.
- Sufficient aggregate report data without persisting every cycle.

## 10. Soulweave, Forms, Traits, Mastery, and Arts

### Fixed structure

**Status: Confirmed**

The Soulweave contains thirty Forms across five Circles in an `8 -> 7 -> 6 -> 5 -> 4` ancestry structure.

| Circle | Forms and ancestry |
|---|---|
| First | Man-at-Arms, Squire, Acolyte, Scribe, Arcanist, Rogue, Hunter, Tinker. |
| Second | Knight = Man-at-Arms + Squire; Templar = Squire + Acolyte; Cleric = Acolyte + Scribe; Sage = Scribe + Arcanist; Occultist = Arcanist + Rogue; Ranger = Rogue + Hunter; Trapper = Hunter + Tinker. |
| Third | Paladin = Knight + Templar; Exorcist = Templar + Cleric; Oracle = Cleric + Sage; Thaumaturge = Sage + Occultist; Veilwalker = Occultist + Ranger; Beastbinder = Ranger + Trapper. |
| Fourth | Ashen Justiciar = Paladin + Exorcist; Hierophant = Exorcist + Oracle; Fateweaver = Oracle + Thaumaturge; Harrower = Thaumaturge + Veilwalker; Cullwarden = Veilwalker + Beastbinder. |
| Fifth | Pale Marshal = Ashen Justiciar + Hierophant; Last Seraph = Hierophant + Fateweaver; Astral Magister = Fateweaver + Harrower; Umbral Reeve = Harrower + Cullwarden. |

Only Man-at-Arms and Scribe are functional in the current prototype. The other positions and ancestry threads may be visible as veiled placeholders. Do not implement the remaining roster merely because the structure is shown.

### Form identity contract

Every higher Form is authored as:

> Parent A behavior + Parent B behavior + synthesis + visible trade-off.

Ancestry is a mechanical contract, not only a visual naming rule. Higher Circles should increasingly alter rules or constraints rather than merely add larger coefficients.

Each complete Form is expected to have:

- one named innate Trait;
- a structural Retinue Slot profile;
- use-based Mastery;
- approximately three passive, data-driven Arts later;
- a shared modifier grammar where practical;
- an explicit weakness or trade-off.

Avoid active combat abilities, cooldown rotations, and bespoke scripting for every Art. Form Arts are out of scope for the current prototype.

### Prototype identities

- **Man-at-Arms:** organized force, backlog throughput, Corrupted Essence, Mastery, and Martial Retinue synergy; weak at preservation and spiritual or magical handling.
- **Scribe:** discovery, forecast precision, Codex-oriented information value, and reduced uncertainty; lower direct throughput and diminishing value at fully charted sites.

Exact prototype coefficients are defined and status-labeled in the companion prototype contract.

## 11. Soul taxonomy and Retinue model

### Soul taxonomy

**Status: Confirmed**

| Category | Meaning | Primary uses |
|---|---|---|
| Corrupted Essence | Soul matter too damaged to retain stable identity. | Recollections, Hall work, Threshold control, and general progression costs. |
| Whole Soul | Umbrella category for cleanly recovered souls. | Parent category for Form, Calling, and Denizen Souls. |
| Form Soul | Whole Soul tied to a Soulweave Form. | Awakening, later weaving, Arts, and higher-form requirements. |
| Calling Soul | Whole Soul tied to an ordinary calling. | Retinues, Hall Keepers, later relief, commissions, and settlement. |
| Denizen Soul | Whole Soul of a creature, spirit, monster, undead being, or magical entity. | Later catalysts, Hall recipes, rare progression, and place identity. |

### Retinue grammar

**Status: Confirmed direction; only one Retinue in the prototype**

Retinues are support cards assigned through Form-defined Slots. They shape rate, quality, discovery, support use, risk, and long-horizon reliability. They are not tactical squads and do not have individual gear, personal XP, inventories, or live casualty micromanagement.

| Category | Strategic role | Typical later pressure |
|---|---|---|
| Martial | Mass Reaping pressure, Essence, Mastery, and resistance handling. | Rations, Armaments, Medical Supplies. |
| Ritual | Spiritual, cursed, undead, arcane, oathbound, and Frayed handling. | Wards, Relics, Reagents. |
| Recovery | Calling Soul preservation, strain reduction, understrength floor, and service resolution. | Medical Supplies, Rations, Wards. |
| Extraction | Raw and rare materials, Denizen recovery, Remains, and Provisions. | Tools, Rations. |
| Logistics | Support efficiency, buffer capacity, reserve discipline, and offline reliability. | Rations, Tools, Provisions. |
| Specialist | Discovery, forecasts, source identification, targeting, and records. | Tools, Rations, possible Insight. |

Only the categories and slot grammar are relevant to the current architecture. Recovery service behavior and Retinues beyond Soldier Company remain deferred.

Core rules:

- Each Retinue has one anchor Calling Soul type and a fixed visible requirement.
- The backend reserves the complete required cohort.
- The player does not assign individual Souls one at a time.
- Duplicate Retinues require duplicate Soul commitments unless marked Unique.
- A no-Retinue Reaping remains viable.
- Removing a Retinue releases its reserved Souls unless a later explicit service rule changes their state.

Calling Soul attrition, strain, relief reserves, settlement, understrength cohorts, Recovery Retinues, and scattering are deferred from the current prototype. The prototype must still model reservation correctly so those later systems are not forced into a destructive-consumption design.

## 12. Resources, Halls, Recollections, Codex Mortis, and seals

### Economy layers

| Layer | Examples | Purpose |
|---|---|---|
| Soul economy | Corrupted Essence, Form Souls, Calling Souls, Denizen Souls, Mastery. | Forms, Retinues, Halls, Recollections, seals, and later Arts. |
| Material economy | Provisions, Metal, Timber, Stone, Remains, Reagents, Relics. | Hall inputs, recipes, biome identity, and unlock requirements. |
| Logistics economy | Rations, Armaments, Tools, Wards, Medical Supplies. | Support buffers, Writs, Retinues, hazards, and later anchoring. |
| Knowledge economy | Insight, Codex records, Threshold familiarity. | Forecasts, source knowledge, automation, and Recollections. |

### Halls

**Status: Confirmed direction**

Halls are persistent production lines rather than manual batch-crafting menus. A mature Hall can expose an active recipe or priority list, input reserve rules, output targets, capacity, efficiency, and an optional Keeper.

Prototype Halls:

- **Archive:** first restored Hall, early Recollections, records, and Eustace as unique Keeper.
- **Larder:** converts Provisions into Rations and maintains a simple target.

Later candidates such as the Scriptorium, Smithy, Reliquary, Infirmary, Workshop, and Portal Engine are deferred.

### Recollections and Codex ownership

- Recollections own global rules, automation, system unlocks, offline capacity, knowledge, and seal support.
- The Soulweave owns awakening and weaving Forms.
- Mastery owns use-based Form progression and later Art gates.
- Calling Souls own Retinue and Keeper staffing commitments.
- Halls own persistent conversion and infrastructure.
- Codex Mortis owns glossary, source lookup, history, statistics, and later advanced analytics.

### Seals

**Status: Confirmed direction; exact long-term structure open**

Chains and rune-like seals are the primary narrative and meta-progression axis. Backlog settlement, regional completion, Hall restoration, and story discoveries can cause seals to resonate, fracture, or break. Major seal work may unlock command tethers, Soulweave access, Halls, offline capacity, or later Threshold rules.

Approved prototype interpretation:

1. At 5,000 Gloamwood souls with Scribe awakened, a **minor first seal resonance** charts or opens Broken Watch and grants the second command tether.
2. At 10,000 regional souls, a **second resonance event** grants an Essence bundle and exposes an affordable optional Recollection choice.

This supersedes older shorthand that described the prototype end state as containing only one seal resonance. Neither event is a full seal break.

Deep Incursion and any prestige/reset currency are deferred and tentative until the persistent Standing Reaping loop is proven.

## 13. UI, forecasts, and reports

**Status: Confirmed direction**

### Forecast first, formulas second

Before dispatch or reconfiguration, the player should be able to understand:

- Souls Returned and estimated settlement time;
- expected output categories and ranges;
- Stable Runtime, likely support pressure, and post-depletion behavior;
- Form Trait and Retinue Slot compatibility;
- what continues online and offline.

Historical trends, advanced comparisons, channel-level return on investment, source graphs, and automation rules are later progression.

### Reaping Reports

Reports aggregate already-applied production into a satisfying review moment. A report can explain:

- souls returned and backlog progress;
- Corrupted Essence and other resources;
- Whole Souls and materials;
- Mastery;
- discoveries;
- milestones;
- support transitions and bottlenecks;
- changed settlement estimates;
- later service outcomes.

Opening, dismissing, clearing, or losing a report accumulator must never remove or delay the underlying gains.

### Presentation constraints

- Dialogue uses a lower-third presentation with portrait or silhouette, text, sound, and modular overlay effects.
- Full-body combat animation is not required.
- Regional maps use separate terrain, points of interest, and state overlays.
- Backlog, rate, settlement estimate, output categories, support condition, and discovery state remain visually distinct.
- One central Reaping-cycle indicator is preferred over unrelated bars for every output.
- A known long-horizon discrete source may use its own Threshold-level acquisition bar because it represents durable progress toward the next whole item, not another Reaping-cycle timer. Show at most one decimal place and never display fractional inventory.

## 14. Technical and production boundaries

**Status: Confirmed**

- Engine: Godot 4.7.
- Language: GDScript only.
- Primary development platform and product target: Windows PC.
- Initial storefront target: Steam. Prototype integration is limited to the separately approved trusted-time adapter; other Steam features remain deferred.
- Presentation: 2D and UI-led, using static or lightly animated art.
- Simulation: data-driven and deterministic, with analytical elapsed-time resolution.
- Save integrity and idempotent resolution take priority over combat AI or animation systems.
- Tutorial triggers and guaranteed rewards are state-based, resumable, and safe after save/load.
- The implementation must remain appropriate for a solo-developed project.
- Final art, voice, animation, release content quantity, and release-scale balancing are not prerequisites for proving the prototype.

Code and comments should be understandable to junior engineers who may be unfamiliar with Godot, GDScript, or the game's domain model. Non-obvious ownership, state transitions, time units, determinism, and save behavior require explicit documentation.

## 15. Current prototype boundary

The current prototype must prove:

- the opening narrative and one-time failed direct action;
- Gloamwood Hamlet and Broken Watch;
- persistent Reapings and automatic banking;
- Man-at-Arms and Scribe;
- Corrupted Essence and active Form Mastery;
- Archive, early Recollections, and the visible thirty-position Soulweave;
- one Soldier Company using twelve reserved Soldier Souls;
- two command tethers and two concurrent Reapings;
- discovery and a Scribe-led information advantage;
- Provisions, the Larder, Rations, and graceful support degradation;
- the two approved resonance events;
- reports, an eight-hour forecast, offline return, and save/load through the complete sequence.

The detailed sequence, content IDs, guarantees, screen disclosure, and acceptance criteria are defined in [PROTOTYPE_0_90_SOURCE_OF_TRUTH.md](PROTOTYPE_0_90_SOURCE_OF_TRUTH.md).

## 16. Deferred and out-of-scope systems

### Deferred

- Calling Soul strain, relief reserves, baseline settlement, service turnover, and Recovery Retinues.
- Additional Writs and custom automation.
- Form Arts and functional implementation of the remaining twenty-eight Forms.
- Denizen Souls.
- Advanced Store policies and competing Hall priorities.
- Frayed Thresholds and anchoring.
- Deep Incursion and prestige/reset systems.
- Full Codex Mortis analytics.
- Additional regions and production-scale content.
- Later storefronts.

### Out of scope for the current prototype

- Steamworks or other storefront SDK integration beyond the separately approved trusted-time adapter.
- Achievements, cloud-save integration, depot/release configuration, DRM, and launch packaging.
- Launch telemetry services, accounts, servers, or backend services.
- Final voice acting, final art, final animation, or final release balance.
- Combat systems, active ability rotations, or tactical squad control.

Local playtest logging is permitted when it is file-based, development-only, and independent of an external analytics service.

## 17. Provisional and open items

Keep all of the following in configurable data or documented policy rather than hard-coded assumptions:

- base Reaping formulas;
- the interaction of Threshold resistance with rate, yield, quality, and efficiency;
- cycle lengths and channel frequencies;
- Form and Retinue coefficients;
- support-buffer size, reserve policy, draw cadence, and reduced-effect floors;
- Hall rates, recipes, costs, and target quantities;
- Recollection costs and coefficients;
- settlement multipliers;
- report cadence and retained history;
- offline caps or storage ceilings;
- complete Trait and Art content for the thirty-Form roster;
- exact first-region content beyond Gloamwood and Broken Watch;
- Deep Incursion currency and reset behavior;
- final art direction and production values.

A prototype scaffold value may be changed after playtesting, but changing it must not silently weaken an architecture invariant such as automatic banking, deterministic guarantees, renewable access, or graceful degradation.

## 18. Maintenance rules

Update this file when the project owner approves a broader design change, a system responsibility changes, or a prototype decision deliberately refines a general rule. Do not edit it merely to match an accidental implementation quirk.

When changing a confirmed rule:

1. Record the decision and rationale in `docs/codex/DECISIONS.md`.
2. Update this file and the prototype contract if applicable.
3. Update architecture, data contracts, tests, and milestone acceptance criteria in the same pull request.
4. Mark superseded wording explicitly rather than deleting historical context from the decision record.

## 19. Source mapping

| This file section | Source document mapping |
|---|---|
| Product identity and boundaries | Idle Fork v0.1 sections 1-4, pages 3-6. |
| Vocabulary and ownership | Section 5, page 7. |
| Core loop and session rhythm | Section 6, page 8. |
| Progression architecture | Section 7, page 9. |
| Soul taxonomy | Section 8, page 10. |
| Thresholds, channels, and discovery | Section 9, page 11. |
| Persistent Reapings, support, and offline resolution | Section 10, pages 12-13. |
| Soulweave and roster structure | Sections 11-12, pages 14-16, plus Appendix A on page 24. |
| Retinue direction | Section 13, pages 17-18, plus Appendix B on pages 24-25. |
| Resources, Halls, Recollections, and Codex Mortis | Section 14, page 18. |
| Seals and later prestige direction | Section 15, page 19. |
| UI, onboarding, and reports | Section 16, page 20. |
| Technical and production constraints | Section 17, page 21. |
| Prototype and vertical-slice boundary | Section 18, page 22. |
| Status, risks, and open questions | Section 19, page 23. |
| Prototype Thresholds and guarantees | Appendices C-E, pages 25-26. |
| Emergency-to-Standard transition, two prototype resonances, manual Scribe awakening, Godot 4.7/GDScript, and Steam-first distribution | Project-owner decisions recorded during the 2026-07-12 planning session. |
| External trusted-time authority and prohibition on local wall-clock offline credit | Project-owner clarification recorded during the 2026-07-12 planning session; implemented by `DEC-0021`. |
| Normalized rare-output work, prospective rate changes, and non-compounding modifier application | Project-owner clarification recorded during the 2026-07-14 planning session; implemented by `DEC-0028`. |
| Six-decimal fractional scale, unscaled whole counts, and persistent Threshold-owned long-horizon acquisition progress | Project-owner clarifications approved on 2026-07-14; implemented by `DEC-0026` and `DEC-0027`. |
