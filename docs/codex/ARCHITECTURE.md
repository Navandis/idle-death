# Death Idle Architecture

**Document role:** Maintained implementation architecture for the 0-90 minute prototype  
**Repository path:** `docs/codex/ARCHITECTURE.md`  
**Document status:** Approved architecture  
**Architecture revision:** 11  
**Last updated:** 2026-07-17  
**Engine target:** Godot 4.7, GDScript only  
**Primary design context:** [Prototype source of truth](../design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md) and [Idle-fork source of truth](../design/IDLE_FORK_SOURCE_OF_TRUTH.md)

## 1. Purpose and authority

This document defines where authoritative behavior belongs, how time and production are resolved, how mutable state is persisted, and how Godot presentation code observes the game without becoming a second source of truth.

Use the source hierarchy in the root `AGENTS.md`. This file translates approved design requirements into technical boundaries. It does not replace the design source-of-truth files, lock provisional balance, or authorize systems outside the current prototype.

Important supporting documents:

- [Data and content contracts](DATA_AND_CONTENT_CONTRACTS.md)
- [Implementation rules](IMPLEMENTATION_RULES.md)
- [Testing and validation](TESTING_AND_VALIDATION.md)
- [Decision log](DECISIONS.md)

## 2. Architecture goals

The prototype architecture must make the following properties straightforward to implement and verify:

1. One authoritative game state survives screen changes and save/load.
2. Online progress, offline progress, debug time advancement, and forecasts use the same simulation rules.
3. Simulation is deterministic for the same committed state, content revision, and elapsed interval.
4. Authoritative closed-session elapsed time never depends on the player's local wall clock, timezone, or calendar.
5. Reapings and Halls continue while menus, dialogue, reports, and tutorial overlays are open.
6. Output is banked immediately; reports never gate claims.
7. Support depletion changes rates or effects without normally stopping valid base production.
8. Milestones and tutorial guarantees are exactly-once, additive, resumable, and testable.
9. Calling Soul reservations remain visible and reversible instead of consuming the underlying Souls.
10. Content and prototype balance remain editable without rewriting tutorial or UI scripts.
11. A future junior engineer can find system ownership, state flow, and invariants without reconstructing them from scenes.
12. Long-horizon progress toward rare whole outputs survives Reaping reconfiguration and remains readable without fractional inventory.

## 3. Deliberate non-goals

The prototype does not need:

- an entity-component-system framework;
- event sourcing as the save model;
- dependency-injection or service-locator frameworks;
- multithreaded simulation;
- networked authority, accounts, or a backend;
- Steamworks features other than the approved narrow trusted-time adapter;
- a generic visual scripting language for rules;
- arbitrary script callbacks embedded in content Resources;
- per-cycle object histories or one saved object per returned soul;
- a launch-scale plugin architecture;
- a universal system capable of implementing all deferred Forms, Retinues, Writs, and prestige mechanics now.

Small extension points are justified only where the prototype already exercises the abstraction.

## 4. Architectural overview

```text
Authored content (.tres Resources)
        |
        v
ContentCatalog --> ContentRegistry --> validated immutable definitions
                                      |
                                      v
GameApp (persistent root scene and Godot lifecycle owner)
        |
        +--> GameSession (RefCounted application facade/composition root)
        |      |
        |      +--> authoritative GameState (RefCounted runtime state)
        |      +--> domain services
        |      |      inventory, Forms, Retinues, Halls, Recollections,
        |      |      milestones, guarantees, unlocks
        |      +--> SimulationEngine
        |      |      live, offline, forecast, and debug modes
        |      +--> TutorialCoordinator
        |      |      observes state and requests domain actions
        |      +--> ReportService / ForecastService
        |      +--> SaveService
        |      +--> MonotonicClock / TrustedTimeProvider adapters
        |
        +--> screen router, HUD, dialogue/tutorial overlays, effects
                  |
                  +--> receive an explicit GameSession reference
                  +--> send commands and query read models
                  +--> animate committed state changes
```

### Core dependency rule

Dependencies point inward toward data and rules:

```text
presentation -> application -> domain/simulation/content contracts
persistence  -> domain serialization contracts
content      -> definition base types only
```

Domain and simulation code must not depend on:

- scene paths;
- whichever screen is open;
- animations;
- dialogue nodes;
- input devices;
- Steam APIs;
- device wall-clock or calendar time;
- implicit global gameplay singletons.

The approved production bridge for the prototype is the pinned GodotSteam 4.20 GDExtension. M06 may use it only to implement `TrustedTimeProvider` at the platform/application boundary. The adapter is injected by `GameApp`, replaced by fakes in automated tests, and never imported by domain or simulation code. No other Steam feature is implied by this exception.

## 5. Three data bands

The project uses three intentionally different kinds of data.

### 5.1 Authored definitions

Authored definitions are immutable during normal play and stored as custom Godot `Resource` files under `content/`.

Examples:

- `FormDefinition`;
- `ThresholdDefinition`;
- `OutputChannelDefinition`;
- `WritDefinition`;
- `RetinueDefinition`;
- `HallDefinition` and `RecipeDefinition`;
- `RecollectionDefinition`;
- `MilestoneDefinition`;
- `GuaranteeDefinition`;
- `CoreTerminologyDefinition` and its `TERM_...` entries.

A checked-in `ContentCatalog` explicitly lists prototype definitions. `ContentRegistry` loads that catalog, validates IDs and references, and exposes read-only lookup methods.

Definitions describe what content means. They do not contain mutable quantities such as the player's current backlog, inventory, Mastery, active assignments, or tutorial progress.

#### Stable identity and mutable player-facing language

Canonical IDs are durable mechanical and save identities. Player-facing names, descriptions, and shared system terminology are content. A Form, Trait, future Art, Denizen, Recollection, or other named object therefore exposes editable fallback text and may expose a localization key, while rules and saves continue to reference its canonical ID.

`CoreTerminologyDefinition` centralizes shared nouns through stable `TERM_...` keys. Presentation later resolves labels such as Threshold, Recollection, Form, Retinue, and Essence from those entries instead of scattering literals through scenes. A player-facing rename does not rename persisted prefixes such as `THR_`; changing a canonical ID is a migration decision. Free-form dialogue and long descriptions still require a deliberate reviewed copy update.

The catalog uses `RES_ESSENCE` and the player-facing term **Essence**. The deprecated dual terminology is not accepted by production content validation.

### 5.2 Mutable runtime state

Mutable state is represented by typed `RefCounted` GDScript classes. It is created for a new game or reconstructed from explicit save dictionaries.

Examples:

- `GameState`;
- `InventoryState`;
- `ThresholdState`;
- `FormState`;
- `ReapingState`;
- `HallState`;
- `ProgressionState`;
- `TutorialState`;
- `ReportAccumulatorState`.

Runtime state must implement explicit conversion to and from save-safe primitives. Mutable game state is not saved through `ResourceSaver`, scene serialization, or node ownership.

### 5.3 Presentation state

Presentation state belongs to Nodes, scenes, and view models. It includes:

- which screen is visible;
- scroll position;
- temporary hover and focus state;
- animation progress;
- an open comparison panel;
- which archived report the player is viewing.

Presentation state is not authoritative gameplay state. A screen may be rebuilt without changing production, inventory, assignments, unlocks, or milestone completion.

## 6. Application composition and lifetime

### 6.1 `GameApp`

The configured main scene should become a persistent root `Control` scene named `GameApp`. It remains in the scene tree for the entire application session and owns:

- the Godot lifecycle callbacks for startup, focus loss/regain, and graceful quit;
- one `GameSession` instance;
- the screen host/router;
- persistent HUD regions;
- dialogue, tutorial, modal/report, effect, and debug overlay layers.

Screens are replaced inside the host instead of replacing the root scene. This keeps production and service lifetime independent of whichever screen is visible.

### 6.2 `GameSession`

`GameSession` is a typed `RefCounted` application facade and composition root owned by `GameApp`. It:

- loads and validates the content catalog;
- constructs services and injects their dependencies;
- owns the current authoritative `GameState` reference;
- starts a new game or loads an existing save;
- advances live simulation when the application root supplies elapsed time;
- accepts player commands;
- coordinates post-command progression evaluation;
- requests save checkpoints;
- publishes committed state-change signals or summaries to presentation.

`GameSession` must not become a large script containing every rule. Domain, simulation, tutorial, report, forecast, and persistence behavior remains in focused `RefCounted` services.

### 6.3 No gameplay autoload initially

The prototype does not require a gameplay autoload. Screens receive `GameSession` or a narrower presenter/controller reference when instantiated. They must not obtain authority by searching `/root`.

An autoload may be added later only when a persistent cross-scene need cannot be handled clearly by `GameApp`. Adding one requires an explicit architecture decision, ownership documentation, and tests. Do not add separate global singletons for inventory, tutorial, saves, reports, Forms, Halls, or simulation.

### 6.4 Test construction

Tests construct `GameState`, `ContentRegistry`, clocks, services, `SimulationEngine`, and `GameSession` directly without entering the scene tree or loading `GameApp`.

## 7. Authoritative `GameState`

`GameState` is the aggregate root for committed gameplay facts. It owns or references the following substates:

| Substate | Authoritative responsibility |
|---|---|
| Inventory | Total owned quantities and reservation ledger. |
| Forms | Awakening, Mastery, and future Form-specific progression. |
| Thresholds | Knowledge state, lifecycle state, backlog, discovery, familiarity, durable output-channel acquisition progress, and Threshold-owned channel carries. |
| Reapings | Current Form, Writ, Retinues, cycle cursor, support buffer, fallback state, and assignment revision. |
| Halls | Restored state, active recipe, production cursor, reserve policy, target, and active state. |
| Recollections | Purchased nodes and resulting unlock/effect state. |
| Progression | Command tether capacity, milestones, guarantees, resonance IDs, counters, unlock flags, and world flags. |
| Story | Scripted opening state, narrative entities, Brand state, and resumable narrative checkpoints. |
| Tutorial | Current state, completed presentation steps, skip/help flags, and presented notification IDs. |
| Reports | Current accumulator and bounded report history. |
| Simulation timeline | Monotonic `simulation_time_msec` used for authoritative event ordering and report windows. |

### 7.1 Stored versus derived values

Store values that are needed to continue resolution exactly. Derive display-only values when queried.

Normally derived rather than persisted:

- available inventory, calculated as owned minus active reservations;
- occupied command tether count, calculated from active Reapings;
- current settlement estimate;
- forecast ranges;
- screen disclosure;
- compatibility labels;
- visible support warning text;
- formatted durations and rates.

A value may be cached for performance only when the cache can be rebuilt and is never treated as the sole source of truth.

## 8. Command, query, and state-change flow

### 8.1 Commands

Presentation requests gameplay changes through the explicit `GameSession` reference or typed command objects. Representative commands include:

- create new game;
- perform the scripted opening return;
- dispatch a Reaping;
- change a Reaping's Form, Writ, or Retinue assignments;
- awaken a Form;
- field or remove a Retinue;
- restore or activate a Hall;
- select a Hall recipe or target;
- purchase a Recollection;
- acknowledge or archive a report;
- skip or complete tutorial presentation;
- request a manual save.

A command follows this transaction order:

1. Advance simulation to the command time.
2. Validate all preconditions without mutating state.
3. Apply the command atomically in memory.
4. Emit plain domain-event records describing what changed.
5. Evaluate milestones, guarantees, unlocks, and tutorial conditions until no additional immediate transition applies.
6. Append report and notification events.
7. Write a required save checkpoint when the command is irreversible or tutorial-critical.
8. Emit one committed `state_changed` signal to presentation.

UI code must not perform a partial mutation before validation completes.

### 8.2 Command results

Commands return a typed result containing:

- success or failure;
- a stable reason code;
- junior-readable diagnostic text for logs or debug UI;
- resulting domain-event IDs when useful.

Expected invalid player actions are validation results, not engine errors. Programmer-contract violations may use assertions in tests and debug builds.

### 8.3 Queries and read models

Presentation obtains read-only snapshots or purpose-specific view models. A view model may combine definition data and runtime state, but it cannot expose mutable state references to controls.

Examples:

- `ThresholdCardViewModel`;
- `ReapingDetailViewModel`;
- `FormComparisonViewModel`;
- `RetinueReservationViewModel`;
- `HallViewModel`;
- `ReportViewModel`;
- `ForecastViewModel`.

### 8.4 Domain events are not event sourcing

Domain events are small records used for:

- reports;
- tutorial condition evaluation;
- presentation effects;
- diagnostics;
- tests.

The save file remains a state snapshot. It is not rebuilt by replaying the entire event history.

## 9. Time model

### 9.1 Three distinct time concepts

The architecture separates three concepts that must never be substituted for one another:

| Concept | Representation | Purpose |
|---|---|---|
| Simulation elapsed time | integer milliseconds | Duration passed into `SimulationEngine` for live, offline, forecast, and debug resolution. |
| Simulation timeline | `GameState.simulation_time_msec` | Monotonic authoritative ordering for domain events, reports, assignments, and tutorial diagnostics. |
| Trusted external epoch | integer UTC milliseconds from `TrustedTimeProvider` | Determines uncredited duration while the application was not running. It is not read by simulation rules. |

The player's device wall clock, timezone, calendar, and daylight-saving settings are not authoritative inputs.

### 9.2 Foreground elapsed time

Foreground play uses an injected monotonic process clock. The production loop advances at a configurable application cadence, not once per rendered frame as an authoritative rule.

Recommended behavior:

1. `GameApp` samples the monotonic clock and tracks an application cursor.
2. At each application simulation update, it computes non-negative elapsed monotonic milliseconds.
3. It passes that interval to `GameSession`, which invokes `SimulationEngine`.
4. `SimulationEngine` increments `GameState.simulation_time_msec` by the committed interval.
5. The time-accounting service increments `foreground_credited_since_anchor_msec` by the same interval when a trusted anchor exists.
6. UI may interpolate committed values between updates.

Changing the simulation cadence must not change the final result for a fixed elapsed interval.

### 9.3 Trusted-time source

Closed-session elapsed time is supplied by a project-owned interface:

```text
TrustedTimeProvider.sample() -> TrustedTimeSample

TrustedTimeSample:
    status
    source_id
    utc_msec
    diagnostic_code
```

Required statuses include at least `TRUSTED` and `UNAVAILABLE`. A stale, contradictory, disconnected, or failed platform result is never silently promoted to trusted.

The selected prototype bridge is **GodotSteam GDExtension 4.20**, committed under `addons/godotsteam/`. The development App ID is `480`, stored in `project.godot`. Automatic Steam initialization is disabled in project settings so ordinary imports, GUT runs, and non-platform code do not connect to Steam implicitly.

M06 owns the production adapter and must:

1. initialize Steam explicitly through the pinned GodotSteam API;
2. confirm a live server connection with behavior equivalent to Steamworks `ISteamUser::BLoggedOn()` before accepting a sample;
3. obtain the server epoch with behavior equivalent to `ISteamUtils::GetServerRealTime()`;
4. normalize the result to integer UTC milliseconds and return it through `TrustedTimeSample`;
5. return `UNAVAILABLE` rather than a guessed value when initialization, connectivity, or sampling fails;
6. keep all GodotSteam method names and callbacks inside the platform adapter.

Steamworks references for the required semantics are [ISteamUser::BLoggedOn](https://partner.steamgames.com/doc/api/ISteamUser#BLoggedOn) and [ISteamUtils::GetServerRealTime](https://partner.steamgames.com/doc/api/ISteamUtils#GetServerRealTime).

The exact GDScript wrapper method names must be inspected in the pinned 4.20 package during M06; prompts and implementation must not guess them from another GodotSteam release. The stable domain-facing source ID remains `STEAM_SERVER_TIME`, while binding version and diagnostics remain platform metadata rather than save-schema semantics.

The App ID project setting is the normal development configuration. Do not add `steam_appid.txt` by default. If a specific executable or debugger launch path later proves that the file is required, document that evidence, keep the file local or ignored, and exclude it from shipped builds.

M00 verifies that Godot 4.7 can import the project and load the extension binaries without initializing Steam. Tests and Codex Cloud use `FakeTrustedTimeProvider`; they never require a Steam client, Steam account, or live platform session.

### 9.4 Persisted time-authority state

The save envelope owns one `TimeAuthorityState` containing:

- `trusted_source_id`;
- `trusted_anchor_utc_msec` when an anchor exists;
- `foreground_credited_since_anchor_msec`;
- `pending_trusted_reconciliation`;
- `last_offline_resolution_id`;
- optional diagnostic codes that do not affect production.

The authoritative game state separately owns `simulation_time_msec`. Per-Reaping and per-Hall wall-clock cursors are forbidden.

### 9.5 Closed-session reconciliation

When a trusted sample is available and a previous trusted anchor exists:

```text
gross_gap_msec = trusted_now_utc_msec - trusted_anchor_utc_msec
uncredited_gap_msec = gross_gap_msec - foreground_credited_since_anchor_msec
```

Then:

1. reject a trusted sample that would move the anchor backwards;
2. clamp a small negative `uncredited_gap_msec` caused only by documented rounding to zero;
3. treat a materially negative or implausible result as an anomaly and grant no closed-session progress;
4. apply the configured offline cap to the non-negative uncredited gap;
5. resolve the credited interval transactionally on a working clone;
6. commit the trusted sample as the new anchor and reset `foreground_credited_since_anchor_msec` to zero only in the same successful save transaction;
7. report capped, deferred, or rejected time explicitly.

If no prior trusted anchor exists, establish the anchor and grant no retroactive closed-session progress before that first trusted sample.

### 9.6 Trusted time unavailable

When trusted time is unavailable:

- load the last committed game state without awarding closed-session time;
- set or retain `pending_trusted_reconciliation`;
- continue normal foreground production using the monotonic process clock;
- keep adding foreground intervals to `foreground_credited_since_anchor_msec` when an older anchor exists;
- retry through the platform adapter at controlled lifecycle points;
- never fall back to local UTC, file modification time, timezone, network time from an unapproved service, or user input.

When trust returns, reconciliation subtracts foreground time already credited so the interval is not counted twice.

### 9.7 Focus, suspend, and quit

Opening menus, dialogue, reports, or tutorial overlays is not focus loss and never pauses production.

On focus loss or graceful quit, resolve foreground monotonic time to the current cursor and request a save. The process may continue advancing while merely unfocused. If the operating system suspends the process and the monotonic clock does not advance through the suspension, the next trusted reconciliation supplies the uncredited gap. If the monotonic clock does advance, that credited foreground interval is subtracted from the trusted gap.

### 9.8 Trust boundary

This policy prevents ordinary abuse or faults based on changing the system date, time, timezone, daylight-saving setting, or clock synchronization. It cannot make a fully client-controlled executable cryptographically authoritative against a determined user who patches the process or spoofs platform calls. Strong protection against that threat requires server-held authority and remains outside the prototype.

Simulation and domain services receive elapsed durations only. They do not read monotonic clocks, trusted epoch sources, Steam APIs, scene state, or frame delta directly.

## 10. Deterministic simulation architecture

### 10.1 One engine, four modes

`SimulationEngine` supports four call contexts:

| Mode | Mutates authoritative state | Purpose |
|---|---:|---|
| Live | Yes | Normal foreground progress. |
| Offline | Yes, through a transactional load flow | Trusted, previously uncredited closed-session interval. |
| Forecast | No; runs on a deep clone | Future output, stable runtime, bottlenecks, and comparisons. |
| Debug advance | Yes, through explicit debug commands | Pacing and state-boundary testing. |

Modes may change reporting detail or whether a result is committed. They must not select different balance formulas, support rules, milestone requirements, or channel behavior.

### 10.2 Global segmented resolver

The prototype uses one global resolver rather than one independent timer loop per Reaping or Hall. This is necessary because active systems share inventory and Stores. For example, Larder output can affect Soldier Company support during the same elapsed interval.

High-level algorithm:

```text
remaining_msec = requested_elapsed_msec

while remaining_msec > 0:
    rates = derive_rates_from_current_state()
    next_boundary_msec = find_earliest_global_state_boundary(rates)
    segment_msec = min(remaining_msec, next_boundary_msec)

    apply_all_continuous_flows(segment_msec, rates)
    advance_all_progress_cursors(segment_msec)
    apply_boundaries_reached_at_segment_end()

    remaining_msec -= segment_msec
```

The resolver must calculate or aggregate intervals analytically. It must not replay every rendered frame or every elapsed second.

### 10.3 Meaningful boundaries

A segment ends at the earliest applicable boundary, including:

- support buffer depletion or recovery threshold;
- Hall cycle completion;
- Hall input exhaustion;
- Hall output target reached;
- Reaping cycle completion when a cycle count drives discovery or tutorial behavior;
- backlog milestone threshold;
- regional return milestone threshold;
- discovery state transition;
- backlog reaching zero;
- Emergency-to-Standard Writ transition;
- guarantee or unlock transition that changes subsequent rates;
- configured fallback activation or removal.

If no state-changing boundary occurs before the requested end, the engine resolves the whole remaining interval in one segment.

### 10.4 Same-time boundary order

When multiple boundaries occur at the same simulation timestamp, process them in this stable order:

1. Commit all continuous gains and consumption for the completed segment.
2. Commit producer completions, including Hall batch output and Reaping channel output due at the boundary.
3. Evaluate counters, milestones, guarantees, unlocks, discovery, and resonance effects.
4. Apply Reaping and Threshold lifecycle transitions, including Emergency-to-Standard and Overdue-to-Settled.
5. Recalculate support state and fallback behavior using the inventory now available at that timestamp.
6. Append report and presentation events in stable ID order.

New rates apply to the next segment. Producer output at the exact moment a support buffer would otherwise deplete is therefore available before support degradation is finalized.

### 10.5 Stable ordering and loop safety

- Sort content IDs and runtime keys before applying equal-priority transitions.
- Never rely on `Dictionary` iteration order for authoritative results.
- Each transition has an exactly-once or state-change guard.
- Detect and fail a test if a zero-duration boundary repeats without changing state.
- Apply a documented maximum transition count per resolution call as a safety guard; reaching it is an error, not a silent truncation.

### 10.6 Numeric accumulation

`DEC-0026` fixes the project scale at `FixedPoint.SCALE = 1_000_000` subunits per whole unit.

Inherently discrete values remain ordinary unscaled signed 64-bit integers, including owned whole Souls/items, backlog, reservations, command tethers, completed-cycle counts, milestones, and authoritative timestamps. Fractional state uses the central scale, including rates, multipliers, Mastery, discovery, familiarity, support consumption, forecasts, and progress toward the next whole discrete output.

Authored content may expose editor-friendly decimal coefficients. `ContentRegistry` normalizes those values once into immutable fixed-point runtime values before gameplay. `SimulationEngine` uses only the normalized integer values.

Rate accumulation uses an explicit period rather than assuming every rate is an integer number of subunits per second. A rate plan supplies a normalized numerator such as `rate_subunits_per_period`, a positive `period_msec`, and any exact arithmetic carry needed to continue the same flow. The central utility applies deterministic floor semantics and returns both produced subunits and the next carry.

Required properties:

- every authoritative fractional state is represented by an integer scaled value or an explicitly typed integer carry;
- whole-unit extraction banks `progress_subunits / SCALE` and retains `progress_subunits % SCALE`;
- every progress value and arithmetic carry has exactly one documented owner;
- carries survive save/load and are preserved or exactly normalized when a rate context changes;
- resolving one eight-hour interval produces the same authoritative result as resolving equivalent smaller intervals when the same boundaries are crossed;
- UI formatting never writes rounded values back into state;
- rate changes occur only after elapsed time is resolved to an explicit boundary;
- overflow bounds are documented and tested, including final-fit calculations whose naive intermediate multiplication would overflow;
- tests compare exact authoritative integers; tolerances are allowed only for derived display formatting.

### 10.7 Randomness

The first-session prototype does not need authoritative randomness. Repeatable output channels may use deterministic rates and fractional accumulators.

If later content introduces randomness, its generator state or deterministic draw sequence must be saved and forecast behavior must be explicitly designed. Do not call an unseeded random function from authoritative simulation.

## 11. Threshold and Reaping model

### 11.1 Orthogonal Threshold state

Avoid one enum containing every combination of knowledge, availability, activity, and backlog lifecycle.

A Threshold runtime instead tracks:

- knowledge: Unknown, Detected, or Charted;
- availability: locked or available, usually derived from unlock conditions;
- lifecycle: Overdue or Settled;
- activity: derived from whether an active Reaping references the Threshold;
- backlog and independent output-channel state;
- discovery progress per channel;
- durable acquisition progress for long-horizon discrete sources.

Presentation composes these facts into labels such as `Active - Overdue`, `Active - Settled`, or `Inactive - Settled` from the design document.

### 11.2 Reaping runtime

There is at most one active Reaping per Threshold in the prototype. Active Reapings are keyed by Threshold ID and contain:

- Threshold ID;
- leading Form ID;
- Writ ID;
- assigned Retinue IDs;
- assignment revision;
- cycle cursor and completed-cycle counters;
- support-buffer state;
- active fallback state;
- fractional carries for flows whose stable owner is the active operation; Threshold-source acquisition progress is not stored here;
- timestamps or simulation cursors required to continue exactly.

An assignment change first resolves time to the command moment, then changes the relevant IDs and increments the assignment revision.

### 11.3 Emergency-to-Standard transition

At 1,000 post-dispatch Gloamwood Reaping returns:

- do not remove the Reaping;
- do not free command tether 1;
- do not reset cycle, report, Threshold, or Mastery state;
- change the same runtime record from `WRIT_EMERGENCY_FIRST_RETURN` to `WRIT_STANDARD`;
- apply the Soldier and Essence guarantees;
- queue the report and tutorial progression;
- continue any remaining elapsed interval using Standard behavior.

### 11.4 Opening-four counter rule

The scripted opening transaction:

- reduces Gloamwood backlog by exactly four;
- records exactly four scripted returns for narrative and audit purposes;
- does not increment the post-dispatch Gloamwood Reaping counter;
- does not increment regional Reaping-return counters;
- does not advance the 1,000, 2,500, 5,000, 10,000, or 25,000 Reaping milestones.

Persistent-Reaping counters start at zero when the first Reaping is dispatched.

### 11.5 Settled Passage transition

When backlog reaches zero:

- set lifecycle to Settled exactly once;
- retain the active Reaping and tether assignment;
- switch rate and channel behavior to the Threshold's Settled configuration;
- keep essential channels available at their configured renewable rates;
- resolve remaining elapsed time under Settled rules;
- queue the settlement milestone and report events.

## 12. Parallel output channels and discovery

### 12.1 Independent channels and disclosure

Each Threshold definition declares independent channels. The prototype channel types are:

- backlog returns;
- Essence;
- active Form Mastery;
- Form Souls;
- Calling Souls;
- materials;
- future Denizen Souls, disabled for the prototype unless explicitly added.

The resolver computes each channel separately from the same segment context. Adding or changing one channel must not silently reduce another unless a documented modifier explicitly does so.

Discovery state controls player knowledge, not whether output exists. Hidden Provisions produced at Broken Watch are banked to inventory and reported as hidden output events until identified. Identification changes disclosure; it does not retroactively generate or erase resources.

Forecast uncertainty is information uncertainty, not necessarily production randomness. Scribe may narrow the displayed range around a deterministic underlying result.

### 12.2 Long-horizon discrete acquisition progress

Under `DEC-0027`, deterministic progress toward a rare whole output is keyed by the stable Threshold and output channel/source. The Threshold channel owns `acquisition_progress_subunits` and any finer carry needed to resume the same source exactly. The active Reaping supplies the current rate context but does not own or reset prior acquisition effort.

Acquisition state stores normalized completed work, not time already spent and not a cached remaining duration. The target for one whole item is the fixed-point whole-unit boundary. Effective rate is a pure derivation from the channel's authored baseline plus the current Form, Writ, Retinue, support, Recollection, Form Art, lifecycle, and other approved modifiers. `ContentRegistry` normalizes the channel to one stable rate period/denominator for the active content revision; ordinary live modifiers change the effective numerator or multiplier, not that denominator.

At any assignment or modifier change:

1. resolve elapsed time under the old rate context to the exact command or unlock timestamp;
2. bank every whole item crossed and retain the normalized progress plus arithmetic carry;
3. commit the assignment, Recollection, Art, support, or other state change;
4. derive the next segment's effective rate from immutable baseline data and the newly committed current state;
5. continue from the unchanged Threshold-channel progress.

The stored progress is never multiplied, divided, or rebased merely because the effective rate changed. A repeated recall and redispatch with the same loadout therefore cannot compound a bonus: the same baseline and same current modifiers derive the same rate. Cached effective rates and estimated remaining time are not authoritative and are not persisted.

For example, a source with a four-hour baseline reaches `50.0%` after two hours. If a newly selected configuration is twenty percent faster, the bar remains `50.0%` and the derived remaining estimate becomes one hour forty minutes. The percentage would change only through future productive elapsed time or an explicit exactly-once progress-grant effect, not through an ordinary rate modifier.

Recall or inactivity freezes the channel. Redispatch resumes it. When the Threshold becomes Settled, the same source progress continues at its configured Settled rate if that source remains available. A long interval can bank several items in one analytical segment or across boundaries; no per-item object or timer is created.

Presentation reads this state through disclosure-aware view models. Unknown channels reveal no progress. An Identified long-horizon channel may show a bar and a one-decimal percentage derived by flooring to tenths so it cannot display `100.0%` before the item is banked. A Charted channel may add the current derived rate, contributing modifiers, and estimated time. Inventory and reports still use whole item counts only.

## 13. Inventory and reservation ledger

### 13.1 Owned, reserved, and available

Inventory keeps one authoritative owned total per resource or Soul ID.

```text
available = owned - sum(active reservations)
```

Reservations are separate ledger records. They do not move quantities into a second inventory and do not destroy them.

### 13.2 Reservation records

Each reservation has:

- a stable reservation ID;
- resource or Soul ID;
- amount;
- owner type and owner ID;
- purpose code;
- active state;
- creation revision or event ID for diagnostics.

### 13.3 Soldier Company

Fielding `RET_SOLDIER_COMPANY` creates a reservation for twelve `SOUL_CALLING_SOLDIER` owned by that Retinue assignment. Removing the Retinue releases the same reservation. Attrition and service settlement are not implemented in the prototype.

### 13.4 Tutorial cost protection

Mandatory tutorial requirements may use reservations or a purchase lock:

- Scribe Form Soul and required Essence remain secured until the player presses Awaken;
- unrelated purchases cannot consume the secured minimum;
- awakening consumes the actual costs through the normal Form service;
- top-ups grant only the amount still missing.

## 14. Forms, Traits, Mastery, and awakening

Form definitions own identity and modifier data. Runtime Form state owns awakening and Mastery.

### 14.1 Modifier evaluation

A central modifier evaluator combines:

- Form Trait;
- Threshold tag fit;
- Writ;
- Retinue effects;
- support state;
- Recollections;
- later global modifiers.

It returns both effective values and a trace of contributing sources. Forecast and comparison UI use this same trace for before/after explanations.

Exact coefficients and stacking remain content data. UI scripts must not reimplement the formula.

### 14.2 Mastery

Only the active leading Form gains Mastery while the Reaping is productive under the current rules. Mastery accumulation is part of simulation state and continues online and offline.

Form Arts remain deferred, but the runtime shape may reserve a list of unlocked Art IDs without implementing Art behavior.

### 14.3 Awakening

The Form service validates costs, consumes available resources, marks the Form awakened, emits an event, and creates the required save checkpoint.

Man-at-Arms is the approved narrative exception and is awakened by the Brand without a Form Soul or normal cost.

Scribe is not auto-awakened during the normal tutorial. Guarantees secure the required resources; the player performs the Awaken command.

## 15. Retinues and support

Retinue definitions declare:

- category;
- compatible slot grammar;
- anchor Calling Soul;
- fixed reservation requirement;
- modifiers;
- support pressure;
- reduced-effect floor.

The Retinue service validates Form-slot compatibility and available Souls before creating a reservation and assignment.

Support is evaluated as a rate/effect state, not as permission for the base Reaping to exist. When Rations deplete:

- Soldier Company effects fall to the configured reduced floor;
- base backlog, Essence, and Mastery continue;
- the report records the transition;
- forecast segments before and after the boundary separately.

No Calling Soul attrition, strain, relief reserve, settlement, or scattering is implemented in the first-session prototype.

## 16. Halls and recipes

A Hall is a persistent producer/consumer governed by definition data and runtime state.

The prototype Larder supports:

- one Provisions-to-Rations recipe;
- one target policy, Maintain 50 Rations;
- deterministic cycle progress;
- input availability;
- target completion;
- online and offline resolution through `SimulationEngine`.

Hall output is banked immediately. The Hall UI displays state and issues commands; it does not run production itself.

Future recipe queues, Keepers, protected reserves, and automatic recipe switching are deferred.

## 17. Recollections, unlocks, milestones, guarantees, and resonances

### 17.1 Recollections

A Recollection definition contains costs, unlock effects, and supported modifiers. Purchasing one uses the normal inventory transaction and marks the Recollection owned exactly once.

The three early optional choices are nonexclusive. Unchosen choices remain available later.

### 17.2 Progression processor

After simulation segments and player commands, a progression processor evaluates:

- Threshold and regional counters;
- milestone conditions;
- guarantee floors;
- unlock conditions;
- resonance effects;
- tutorial entry conditions.

It applies a small approved effect grammar rather than arbitrary content scripts. Effects are defined in [Data and content contracts](DATA_AND_CONTENT_CONTRACTS.md).

### 17.3 Exactly-once behavior

Each milestone, guarantee, unlock, and resonance has a stable runtime ID. Application requires both:

1. its condition is currently satisfied; and
2. its completion ID is not already recorded.

Top-ups additionally inspect current inventory and active reservations. A completion ID is recorded even when the calculated top-up is zero because legitimate production already met the floor.

### 17.4 Approved resonance distinction

- The 5,000-Gloamwood milestone after Scribe awakening records the minor first resonance and grants Broken Watch plus command tether 2.
- The 10,000-regional-Reaping-return milestone records a separate second resonance, Essence reward, and optional Recollection access.

These use different IDs and report events.

## 18. Tutorial and narrative architecture

### 18.1 Tutorial ownership

`TutorialCoordinator` observes authoritative state and determines which guidance should be presented. It may:

- request an approved guarantee;
- request navigation or highlighting;
- queue a dialogue or tutorial presentation;
- mark a presentation step shown, skipped, or replayable from Help;
- suggest a Form assignment;
- expose the next objective.

It must not directly edit inventory, awaken Forms, dispatch Reapings, reserve Souls, restore Halls, buy Recollections, or grant command tethers. Those changes go through the same domain services used outside the tutorial.

### 18.2 State-driven progression

Tutorial state is advanced from authoritative conditions, not a chain of UI callbacks. On load, the coordinator:

1. reads saved tutorial and world state;
2. identifies already-satisfied steps;
3. reconstructs pending presentation notices;
4. selects at most one blocking item;
5. leaves production running.

### 18.3 Narrative skipping

Skipping narrative executes the same scripted world-state commands that the skipped sequence would have reached, with idempotent flags.

### 18.4 Mechanical guidance skipping

The conservative prototype rule is that skipping mechanical guidance dismisses the instructional presentation and creates or updates a Help entry; it does not silently execute cost-bearing player choices. Under that rule, Scribe remains unawakened until the player issues Awaken.

This specific UX rule remains an owner-review point in the decision log. Architecture still requires that any final behavior use normal domain commands and remain idempotent.

## 19. Reports and forecasts

### 19.1 Immediate banking

Simulation writes gains directly to authoritative inventory, counters, Mastery, backlog, and Hall state. `ReportAccumulatorState` receives deltas and explanatory events at the same time.

### 19.2 Report lifecycle

When the player opens a report:

1. snapshot the current accumulator into an immutable `ReportRecord`;
2. append it to bounded report history;
3. clear only the live accumulator;
4. save the report transition;
5. render the archived record.

A crash after opening must not lose the report or change inventory. Report history length is configurable.

### 19.3 Forecast service

Forecasting:

- deep-clones the current state;
- optionally applies a hypothetical assignment or purchase to the clone;
- runs the same simulation engine for the requested horizon;
- returns segment summaries, outputs, stable runtime, bottlenecks, milestone crossings, and end state;
- filters disclosure according to discovery and information rules;
- never commits state, report events, saves, or tutorial progression.

Before/after comparisons run from the same baseline snapshot and content revision.

## 20. Persistence and save versioning

### 20.1 Schema and codec are separate

The save system has three layers:

1. typed runtime state;
2. a schema-controlled primitive snapshot;
3. a replaceable `SaveCodec` that converts the snapshot to and from bytes.

The prototype codec is versioned JSON under `user://saves/`. JSON is selected for inspectability and debugging, not as a permanent full-game commitment or a security feature.

Runtime objects are converted to schema-controlled dictionaries and arrays before encoding. Godot JSON represents JSON numbers as floating-point values. To preserve 64-bit counters, fixed-point values, residuals, revisions, durations, simulation time, and trusted-time fields exactly, the JSON codec serializes every schema field typed as an authoritative integer as a canonical base-10 string. It decodes that string with format and signed-64-bit range validation before constructing runtime state.

Example wire representation:

```json
{
  "schema_version": "1",
  "codec_id": "JSON_V1",
  "content_revision": "prototype-r1",
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
    "simulation_time_msec": "3485000"
  }
}
```

Do not pass runtime dictionaries containing exact integers directly to `JSON.stringify()` and assume integer type or precision will survive.

The top-level envelope includes:

- schema version;
- codec ID;
- content revision;
- save revision;
- `TimeAuthorityState`;
- optional last offline-resolution ID and non-authoritative diagnostics;
- authoritative `GameState` data.

No field derived from the device wall clock is used to calculate progress.

### 20.2 Atomic write pattern

`SaveService` should:

1. serialize the complete candidate snapshot through `SaveCodec` to a temporary file;
2. flush and close it;
3. reopen, decode, and fully validate the temporary snapshot;
4. retain the previous valid primary as a backup;
5. replace the primary with the validated candidate;
6. report failure without deleting the last valid save.

The exact file-rename sequence must be tested on Windows and in the Codex Cloud Linux environment.

### 20.3 Load selection

On load:

- decode and validate primary and backup independently;
- choose the valid snapshot with the highest save revision;
- reject an unsupported future schema or codec with a clear error;
- apply sequential migrations for older supported schemas;
- validate IDs, fixed-point ranges, time-authority state, and cross-field invariants before simulation begins.

### 20.4 Offline resolution transaction

Trusted closed-session resolution uses a working clone:

1. load, migrate, and validate a committed snapshot;
2. request a trusted sample from `TrustedTimeProvider`;
3. if unavailable, expose the loaded state without closed-session gains, preserve pending reconciliation, and continue foreground play;
4. if trusted, calculate the uncredited gap using the trusted anchor and already-credited foreground interval;
5. apply anomaly checks and the configured cap;
6. resolve the accepted interval on the clone through `SimulationEngine`;
7. assign a stable offline-resolution ID;
8. update the trusted anchor and reset credited foreground time on the clone;
9. atomically save the resolved clone while retaining the pre-resolution file as backup;
10. only then expose the resolved state and welcome-back report to presentation.

If the application stops before step 9, the old committed snapshot is still authoritative. If it stops after step 9, the new anchor, save revision, and resolution ID prevent duplicate gains.

### 20.5 Migrations

Migrations are explicit functions from schema N to N+1. They operate on primitive dictionaries before runtime objects are constructed. Every migration has fixtures and tests.

Changing the meaning of a canonical ID, removing a persisted field, changing reservation semantics, changing the time-authority accounting contract, or replacing the codec envelope requires a migration or a deliberate prototype save reset documented in the decision log.

### 20.6 Resilience versus tamper resistance

The prototype save design provides:

- exact round trips;
- strict validation;
- atomic replacement;
- backup recovery;
- schema migration;
- idempotent trusted-time reconciliation.

Plain JSON is editable. A binary codec would be less readable but would not make the save trustworthy. Local encryption, obfuscation, or a locally stored HMAC key can deter casual editing but cannot protect against a determined user who controls the executable and machine. An unkeyed digest can detect accidental corruption, not malicious replacement.

Before commercial release, profile realistic worst-case save size and load/write time, then choose whether JSON remains adequate or a compressed/binary codec is justified. Separately decide whether the product needs only corruption resilience, casual-edit deterrence, or server-backed authority for protected outcomes. Steam Cloud is a future synchronization mechanism, not an integrity authority.

## 21. UI and scene flow

### 21.1 Main scene

The eventual application shell should use the persistent root `Control` scene `GameApp`, containing:

- persistent HUD regions;
- a screen host/router;
- dialogue and tutorial overlay layers;
- modal/report layer;
- presentation effect layer;
- optional debug layer in debug builds.

The current `test_main_scene.tscn` remains temporary dry-run scaffolding until a scoped milestone replaces it.

### 21.2 Update contract

After a committed transaction, `GameSession` emits a typed state-change summary. Presentation then requests updated view models for affected domains.

Do not emit dozens of mutation signals while state is half-updated. UI animations may count toward the new total, but the committed total is available immediately.

### 21.3 Navigation

Screen navigation does not pause or own simulation. Closing a screen discards only presentation state. Returning to a screen rebuilds it from view models.

### 21.4 Disclosure

View-model construction enforces tutorial and discovery disclosure. Hidden data may remain present in authoritative state but must not leak into player-facing rows, labels, or forecasts before the applicable state.

For a known long-horizon discrete source, the Threshold detail may expose durable acquisition progress as a bar and a percentage truncated to one decimal place. This is separate from the central Reaping-cycle indicator: it represents saved source progress toward the next whole item and survives assignment changes. Do not display fractional Souls, catalysts, or other whole inventory objects.

## 22. Debug and pacing tools

Debug tools are allowed because first-session pacing requires rapid iteration. They must call the same domain and simulation paths as normal play.

Useful debug actions:

- advance authoritative time by a selected duration;
- inspect simulation segments and modifier traces;
- grant a named test setup through explicit debug commands;
- load a fixture state;
- jump to a tutorial state only after satisfying or explicitly applying its required world state;
- inspect owned, reserved, and available inventory;
- force a save, load, backup fallback, or migration;
- reset prototype save data;
- compare one-hour and eight-hour forecasts.

Debug code must be guarded by debug-build checks and excluded or inaccessible in release exports. Debug shortcuts must not create an alternative production formula.

## 23. Test seams

The architecture provides the following replaceable seams:

| Seam | Production implementation | Test implementation |
|---|---|---|
| Foreground clock | monotonic process clock adapter | `FakeMonotonicClock` with explicit values |
| Trusted time | GodotSteam 4.20-backed `TrustedTimeProvider` implemented in M06 | `FakeTrustedTimeProvider`, fake Steam bridge, or unavailable source |
| Content | checked-in `ContentCatalog` and `.tres` definitions | minimal fixture catalog/registry |
| Save storage | `FileSaveStorage` using `user://` | in-memory or temporary-directory storage |
| Simulation | `SimulationEngine` | same engine with fixture state and trace enabled |
| Presentation sink | `GameSession` state-change summaries and report history | event collector or no-op sink |
| Random source | none for the prototype | deterministic fake if introduced later |

Pure domain and simulation tests must not require a running main scene.

## 24. Intended source layout

This is an ownership map, not an instruction to create every file immediately.

```text
src/
  app/
    game_session.gd
    command_result.gd
    state_change_set.gd
  content/
    content_registry.gd
    definitions/
  domain/
    state/
    services/
    progression/
  simulation/
    simulation_engine.gd
    simulation_result.gd
    simulation_trace.gd
    fixed_point.gd
    forecast_service.gd
  persistence/
    state_codec.gd
    save_codec.gd
    json_save_codec.gd
    save_container.gd
    save_service.gd
    save_storage.gd
    file_save_storage.gd
    save_migrations.gd
  time/
    monotonic_clock.gd
    trusted_time_provider.gd
    trusted_time_sample.gd
  platform/
    steam/
      godot_steam_trusted_time_provider.gd
      godot_steam_bridge.gd
  tutorial/
    tutorial_coordinator.gd
  presentation/
    game_app.tscn
    game_app.gd
    screen_router.gd
    view_models/
    screens/
    overlays/
  debug/
    debug_panel.tscn
    debug_panel.gd

content/
  prototype_content_catalog.tres
  forms/
  thresholds/
  writs/
  retinues/
  halls/
  recollections/
  progression/
  tutorial/

tests/
  unit/
  integration/
  fixtures/
```

## 25. Architecture review checklist

A pull request affecting core behavior should be rejected or revised when it does any of the following without an approved decision:

- places authoritative production in `_process()` on a screen node;
- uses a different formula for offline or forecast mode;
- makes opening a report necessary to receive output;
- stores mutable gameplay state only in scene nodes;
- lets tutorial code edit inventory or unlocks directly;
- consumes reserved Calling Souls when fielding a Retinue;
- counts the scripted opening four toward Reaping milestones;
- destroys a Reaping during the Emergency-to-Standard transition;
- stops base production because Rations reach zero;
- relies on unseeded randomness;
- uses unsorted dictionary iteration for authoritative transition order;
- rounds production independently in multiple systems;
- commits a save before validating it while deleting the last valid copy;
- reads device wall-clock, timezone, calendar, or file timestamps to award authoritative progress;
- grants pending closed-session time when no trusted sample is available;
- describes JSON, binary encoding, local encryption, or a local checksum as tamper-proof;
- adds an autoload, plugin, dependency, or framework without scoped approval;
- introduces a content rule that cannot be explained through the shared modifier or effect grammar;
- makes a UI animation or tutorial callback the only trigger for a required state change.

## 26. Open architecture items

The following remain deliberately open until a later approved milestone or playtest provides evidence:

- exact simulation update cadence during live play;
- general offline cap beyond the required eight-hour path;
- report-history retention count;
- final save-file naming and number of player slots;
- final digest/container framing details after M02 implements and tests the smallest useful version;
- exact GodotSteam 4.20 wrapper method mapping, initialization sequence, callback pumping requirements, and failure diagnostics, to be verified against the pinned addon during M06;
- replacement of development App ID `480` with Death Idle's production App ID and package configuration before external Steam distribution;
- commercial-release save codec after profiling realistic state size and Steam Cloud behavior;
- commercial-release threat model: resilience only, casual-edit deterrence, or server-backed protection for selected outcomes;
- exact mechanical-tutorial skip behavior, especially whether any future Help-assisted shortcut may execute a normal domain command after explicit confirmation;
- final modifier stacking coefficients and balance;
- whether GitHub Actions is added after the local and Codex Cloud harness is stable.

Do not resolve these by scattering provisional constants through implementation. Record temporary choices in content or a focused decision entry.

## 27. Requirement traceability

This table maps protected design requirements to their primary architecture sections. Milestone definitions and tests should cite the original requirement IDs rather than relying only on this summary.

### 27.1 Idle-fork invariants

| Requirement | Primary architecture coverage |
|---|---|
| `IF-REQ-01` — Persistent assignments | Sections 11.2, 11.3, and 11.5 |
| `IF-REQ-02` — Automatic banking | Sections 19.1 and 19.2 |
| `IF-REQ-03` — No presentation pause | Sections 6, 9, 10, and 21 |
| `IF-REQ-04` — Finite-to-renewable Thresholds | Sections 11.1 and 11.5 |
| `IF-REQ-05` — Renewable essential sources | Sections 11.5 and 12 |
| `IF-REQ-06` — Graceful degradation | Section 15 |
| `IF-REQ-07` — Shared simulation | Sections 10.1 and 19.3 |
| `IF-REQ-08` — Deterministic elapsed-time resolution | Sections 9 and 10 |
| `IF-REQ-09` — Independent channels | Section 12 |
| `IF-REQ-10` — Hidden output remains real | Section 12 |
| `IF-REQ-11` — Additive guarantees | Sections 17.2 and 17.3 |
| `IF-REQ-12` — Recoverable deviations | Sections 17 and 18 |
| `IF-REQ-13` — Reserved Calling Souls | Section 13 |
| `IF-REQ-14` — Domain ownership | Sections 5, 8, 18, and 21 |
| `IF-REQ-15` — Save integrity | Section 20 |
| `IF-REQ-16` — Storefront independence | Sections 3 and 24 |
| `IF-REQ-17` — Trusted time authority | Sections 9.3–9.6 and 20.5 |
| `IF-REQ-18` — Persistent long-horizon source progress | Sections 10.6, 11.1–11.2, 12.2, and 21.4 |

### 27.2 Prototype safeguards

| Requirement | Primary architecture coverage |
|---|---|
| `P90-SAFE-01` — First input target | Section 21; enforced through milestone presentation criteria rather than simulation time |
| `P90-SAFE-02` — Exact opening decrement | Section 11.4 |
| `P90-SAFE-03` — First automated Reaping target | Sections 11.2 and 21; treated as a playtest target |
| `P90-SAFE-04` — One-time direct action | Section 11.4 |
| `P90-SAFE-05` — One blocking lesson | Section 18 |
| `P90-SAFE-06` — Production continues behind UI | Sections 6, 10, and 21 |
| `P90-SAFE-07` — Deterministic critical access | Section 17 |
| `P90-SAFE-08` — Mandatory-cost protection | Sections 13.4 and 17 |
| `P90-SAFE-09` — Valid alternative assignments | Sections 17 and 18 |
| `P90-SAFE-10` — Ration depletion does not stop base production | Section 15 |
| `P90-SAFE-11` — Informational reports | Section 19 |
| `P90-SAFE-12` — Save-safe exactly-once events | Sections 17 and 20 |
| `P90-SAFE-13` — Scripted four excluded from Reaping counters | Section 11.4 |
| `P90-SAFE-14` — No local wall-clock offline credit | Sections 9.3–9.6 and 20.5 |

## M01 implemented deterministic time and fixed-point foundation

M01 adds the first scene-independent runtime foundation without adding gameplay production or persistence:

- `GameState` owns only `simulation_time_msec`, a non-negative authoritative timeline advanced through validated elapsed-time operations.
- `TimeAuthorityState` remains separate from `GameState` and owns trusted anchor UTC milliseconds, source ID, foreground credit since anchor, pending reconciliation, and the last diagnostic.
- `FixedPoint` owns the single `1_000_000` subunit scale for fractional state. Discrete counts such as inventory, backlog, and tethers remain unscaled integers.
- `TimeReconciliationService` separates non-mutating trusted-time planning from commit. This lets later save/offline milestones simulate candidate elapsed time and commit the simulation result, anchor update, and foreground-credit reset transactionally.
- `ProcessMonotonicClock` is the only M01 adapter that reads Godot's process-monotonic clock. Authoritative simulation receives elapsed milliseconds and does not query wall-clock, calendar, timezone, file timestamp, Steam, or registry APIs.



## M02 persistence implementation note

M02 adds a scene-independent persistence foundation under `src/persistence/`. `SaveSchemaMapper` maps the current M01 `GameState` and `TimeAuthorityState` to primitive schema-version-1 dictionaries and back. `SaveSchemaValidator` validates those dictionaries before runtime construction or file commit. `SaveInt64` owns canonical signed 64-bit decimal strings so authoritative integers do not cross JSON as numbers. `JsonSaveCodec` owns only `JSON_V1` UTF-8 JSON bytes. `SaveMigrationRegistry` migrates primitive dictionaries one sequential version at a time. `SaveStorage`, `FileSaveStorage`, and `SaveFileSet` isolate file operations and paths. `SaveService` performs temp write, reopen/decode/full validation, backup rotation, primary promotion, independent primary/backup load validation, highest revision selection, suspect primary preservation, and reconciliation-candidate commit after persistence succeeds.

The prototype default save file set is `user://saves/death_idle_m02.json`, `user://saves/death_idle_m02.tmp`, and `user://saves/death_idle_m02.bak.json`. Tests and traces inject isolated roots and must not use the default save root. Persistence selection uses validated `save_revision`, never file timestamps, local wall time, Steam state, or path metadata.

## M03 realized content ownership

M03 introduces `ContentCatalog` as the explicit root authored Resource, typed per-family definition Resources (`ItemDefinition`, `FormDefinition`, `ThresholdDefinition`, `OutputChannelDefinition`, and the other M03 families), bounded subresources, and `CoreTerminologyDefinition` as text `.tres` authoring records; `ContentRegistry` is the all-or-nothing validation and normalization boundary. Runtime code reads copied registry dictionaries, not mutable source Resources. Persistence remains content-agnostic: callers pass a non-empty content revision and content compatibility is checked by the content layer after schema validation.

## M04A realized gameplay-state persistence

M04A adds a typed `GameState` aggregate for inventory, Forms, Thresholds/acquisition, Reapings, and progression while keeping content Resources, clocks, trusted-time provider state, UI, and production simulation outside the aggregate. Schema version dispatch preserves frozen v1 validation and maps current runtime state through schema v2. During v1-to-v2 upgrade, the coordinator validates the migrated primitive candidate, constructs and validates runtime state, increments only `save_revision` on a deep copy of the migrated primitive snapshot, and persists that exact envelope before exposing runtime. This preserves v1 metadata, offline-resolution identity, content revision, time authority, and simulation time instead of rebuilding the envelope from runtime defaults.

M04A also establishes immutable schema-v1 and representative schema-v2 fixtures, explicit wire-key normalization, deep-clone isolation, and the owner-run migration trace. Schema v2 contains structural Reaping records but no dispatch or production command.

## Approved M04B Reaping identity and assignment-command boundary

Accepted `DEC-0035` authorizes M04B to add one focused `ReapingAssignmentService` or equivalent domain service. The service owns initial dispatch, recall, and redispatch of an inactive Reaping record. It does not own elapsed-time resolution, file persistence, tutorial flow, presentation, Retinue assignment, or production.


### Identity model

M04B distinguishes four layers:

| Layer | Identity | Meaning |
|---|---|---|
| Reaping operation | canonical Threshold ID | The stable operation record owned by one Threshold |
| Loadout | canonical value tuple | Form, Writ, ordered Retinues, and later approved components |
| Assignment state | Threshold ID + assignment revision | One committed version of that operation's assignment |
| Activation episode | revision produced by dispatch/redispatch | One continuous active period until recall |

`GameState.reapings[threshold_id]` is the operation identity. No separate UUID is persisted. Equal loadout tuples may operate different Thresholds without sharing state.

`started_simulation_msec` is set once when the first successful dispatch creates the record. It is immutable for the lifetime of that Threshold-scoped operation, and `0` is valid. Record existence is the initialization fact. Recall, redispatch, Settlement, loadout changes, and save/load do not change or remove it. `last_configuration_change_simulation_msec` records later assignment boundaries.

The same Threshold and same loadout after recall is the same operation and equal loadout value but a new activation episode. The same loadout at another Threshold belongs to another operation. A different loadout at the original Threshold still modifies the original operation. Returning to an earlier loadout does not restore an old assignment snapshot or historical effective rate.

If future design allows multiple Reapings at one Threshold, the project must add a first-class instance ID and migration. M04B does not add anticipatory identity fields.

The intended command flow is:

```text
typed command
    -> validate current GameState and ContentRegistry
    -> verify expected assignment revision
    -> build one candidate ReapingState / candidate GameState
    -> validate the complete candidate
    -> commit one Reaping-map insertion or replacement
    -> return ActionResult + ordered assignment event(s)
```

The service uses `GameState.simulation_time_msec` as the committed command boundary and never samples a clock. Initial dispatch creates revision 1. Recall and redispatch each increment exactly once. Failed or stale commands commit nothing.

A recalled record remains in `GameState.reapings` with `is_active = false`; its Threshold-owned progress, immutable first-start time, operation phase, and carries remain available for later resolution. Occupied tether count is always derived from active records. One Form may lead at most one active Reaping.

M04B does not reinterpret nonzero rate-dependent phase/carry under a different Form or Writ. A changed redispatch with unresolved operation progress is rejected until M04C/M04D can resolve and normalize the old rate context. Same-configuration redispatch may resume frozen state.

Successful assignment commands request a save checkpoint through their result. The assignment service does not call `SaveService`; tests and later `GameSession` orchestration persist the already-committed state through the existing schema-v2 coordinator.

### M04B realized command, result, event, and validation boundary

M04B realizes the approved assignment boundary with `ReapingAssignmentService`.

- Durable assignment invariants live in `GameStateValidator`, so load and command candidates reject non-positive assignment revisions, duplicate active Form leadership, active Reapings at unavailable Thresholds, active disabled Writs, invalid content references, and tether over-occupancy before runtime exposure.
- The assignment service retains command-specific preconditions: operation existence, active/inactive state, exact expected revision, requested capacity, active-Form exclusivity, and `REAPING_RESOLUTION_REQUIRED` for changed loadouts with unresolved phase/carry.
- Successful commands return a bounded typed result with player/developer diagnostics, `AssignmentChangeSummary`, one ordered `AssignmentEvent`, and a save-checkpoint request.
- Failures return stable `REAPING_...` codes with no event, summary, checkpoint, or partial state mutation.
- Assignment events use the committed simulation cursor, a stable priority, the Threshold operation as subject, primitive payload data, and deliberate report/tutorial relevance flags. They are not persisted.
- The complete identity trace proves Threshold-scoped operation identity, loadout equality independent from operation identity, assignment/episode revisions, immutable zero-valid first-start time, active/inactive round trips, and no production from assignment commands.

PR #9 merged this boundary from final head `5301c94bfd0fb837f9961fda624d7559042327e2` at merge commit `c641d74cebedf07c51ebb579cccee21db7aa2410`.

## Approved M04C core Reaping resolution boundary

Accepted `DEC-0036` authorizes M04C to introduce the first `src/simulation/` implementation.

### Ownership

`SimulationEngine` owns elapsed-time production. It receives validated state, normalized content, and an explicit duration; it reads no clock or presentation state. It resolves on a deep clone and commits only after complete arithmetic and domain validation.

M04C supports zero or one active Reaping. Zero active Reapings still advances the global simulation timeline. More than one active Reaping is rejected without mutation until the concurrent-Reaping slice extends the global resolver.

### Core rate derivation

One segment rate plan is derived from:

- the active Form's normalized returned-soul and Mastery rates;
- the Threshold's normalized definition and tags;
- the Threshold's enabled Essence channel;
- the narrow approved active-Form Trait modifier subset;
- current Overdue or Settled lifecycle state.

Returned souls use the Threshold's Settled multiplier only after Settlement. Essence uses its channel's Settled multiplier only after Settlement. Mastery and cycle cadence are not reduced by Settlement.

M04C does not execute Retinue modifiers, support, discovery, discrete non-Essence channels, progression effects, or Writ transitions. Unsupported relevant configuration fails clearly.

### Transaction and segmentation

```text
validate state/content/duration
    -> deep-clone candidate
    -> derive current rate plan
    -> find exact Settlement boundary when applicable
    -> apply checked core flows and cycle progress
    -> commit whole returns and Essence immediately
    -> apply Settlement once at the boundary
    -> re-derive Settled rates
    -> resolve remaining interval
    -> validate complete candidate
    -> replace live state once
    -> return typed result, segment summaries, and ordered events
```

Settlement follows the global same-time rule: gains at the boundary commit before lifecycle changes; new rates begin in the next segment. A repeating zero-duration boundary is an error.

### Realized M04C implementation

`SimulationEngine` implements the approved M04C boundary with explicit elapsed milliseconds, checked fixed-point arithmetic, transactional candidate commit, complete result/segment/event records, and the shared `CoreFlowKeys` residual contract. The implementation remains limited to zero or one active Reaping and rejects Retinues, unknown nonzero flow keys, and multiple active Reapings without mutation. PR #12 merged from final head `acb48d0045e41a0f7d73f561e5c3756f8668dd46` at merge commit `719592c85ca4e90ecd5df4593e37a81d36b2789e`.

### Core residual ownership

The existing schema-v2 `ReapingState.flow_carry_units` map receives stable internal keys for:

- returned-soul progress subunits;
- returned-soul arithmetic carry;
- Essence progress subunits;
- Essence arithmetic carry;
- Mastery arithmetic carry.

`cycle_phase_msec` and `completed_cycle_count` remain their own owners. Threshold-channel acquisition progress remains separate and untouched. No effective rate, ETA, or second copy of progress is persisted.

### Extension seams

M04D extends the same engine with discrete output channels and resolve-before-rate-change behavior. M04E adds clone forecasts and report accumulation. Later progression and concurrency slices add their own boundaries without replacing the core resolver.

## Proposed M04D discrete-output channel boundary

Subject to approval of `DEC-0037`, M04D extends the existing transactional `SimulationEngine`; it does not create a second simulation loop.

### Channel resolution owner

For each active segment, the engine obtains the active Threshold's canonically sorted channel IDs and resolves every enabled, correctly owned non-Essence item channel. Essence remains in the M04C core-flow path. A missing Threshold acquisition record means zero and is created when that channel first participates in positive elapsed resolution.

The channel resolver owns:

- immutable baseline rate and stable period lookup;
- bounded output-channel modifier evaluation;
- channel Settled multiplier application;
- checked progress/carry accumulation;
- whole-unit extraction and inventory banking;
- `total_banked_units` source accounting;
- deterministic channel deltas and bank events.

Discovery remains presentation/progression state and does not gate production.

### Bounded channel rate plan

The M04D rate plan is a pure value derived for each segment from normalized content and the active authoritative loadout. Its initial production source list contains active Form Trait modifiers. The builder supports `OUTPUT_CHANNEL_RATE`, `MULTIPLY`, `OUTPUT_CHANNEL`, and the approved channel/Threshold conditions. Later systems extend the ordered modifier-source list rather than changing stored progress or caching effective rates.

The rate plan applies ordinary modifiers first and the channel's own Settled multiplier last. It never applies the Threshold core multiplier to a channel and never derives a rate from the preceding effective rate.

A pure minimum-time query may reuse the same rate plan and bounded checked search. It is derived data for tests, forecasts, and later read models; it is not save authority.

### Residual-preserving assignment compatibility

M04D refines M04B's changed-redispatch guard. The caller still resolves the old configuration to the command boundary before invoking assignment. A changed inactive redispatch may preserve nonzero residuals when old and new returned-soul periods, Mastery periods, and cycle durations are equal. Threshold-owned channel periods are independent of the loadout and therefore remain stable.

A compatible change preserves all operation and channel residuals and changes only future rate derivation after the new assignment revision. An incompatible period/duration change fails without mutation. This closes the current prototype Form-change case without adding a lossy carry conversion or schema field.

### Same-time order and output facts

Channel accumulation occurs inside each M04C segment. Whole channel output at a Settlement boundary banks before the lifecycle transition. `OUTPUT_CHANNEL_BANKED` events are emitted in sorted channel order before the Settlement event. They are non-persisted committed facts; inventory and `ThresholdAcquisitionState` remain authority.

### Persistence and extension seams

Schema version 2 already persists `ThresholdState.channel_acquisition`. M04D adds no schema version. Persistence validation rejects Essence acquisition records, invalid channel ownership, out-of-range progress/carry, and negative banked totals.

M04E consumes the same result/segment channel deltas for forecast and report accumulation. M09/M13/M14/M15 later add Recollection, discovery, support, Retinue, and global modifier sources without replacing the channel accumulator.
