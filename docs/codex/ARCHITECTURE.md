# Death Idle Architecture

**Document role:** Maintained implementation architecture for the 0-90 minute prototype  
**Repository path:** `docs/codex/ARCHITECTURE.md`  
**Document status:** Draft for Phase 6 approval  
**Architecture revision:** 1  
**Last updated:** 2026-07-12  
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
4. Reapings and Halls continue while menus, dialogue, reports, and tutorial overlays are open.
5. Output is banked immediately; reports never gate claims.
6. Support depletion changes rates or effects without normally stopping valid base production.
7. Milestones and tutorial guarantees are exactly-once, additive, resumable, and testable.
8. Calling Soul reservations remain visible and reversible instead of consuming the underlying Souls.
9. Content and prototype balance remain editable without rewriting tutorial or UI scripts.
10. A future junior engineer can find system ownership, state flow, and invariants without reconstructing them from scenes.

## 3. Deliberate non-goals

The prototype does not need:

- an entity-component-system framework;
- event sourcing as the save model;
- dependency-injection or service-locator frameworks;
- multithreaded simulation;
- networked authority, accounts, or a backend;
- Steamworks or another storefront SDK;
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
- actual system time;
- implicit global gameplay singletons.

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
- `GuaranteeDefinition`.

A checked-in `ContentCatalog` explicitly lists prototype definitions. `ContentRegistry` loads that catalog, validates IDs and references, and exposes read-only lookup methods.

Definitions describe what content means. They do not contain mutable quantities such as the player's current backlog, inventory, Mastery, active assignments, or tutorial progress.

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
| Thresholds | Knowledge state, lifecycle state, backlog, discovery, familiarity, and stream remainders. |
| Reapings | Current Form, Writ, Retinues, cycle cursor, support buffer, fallback state, and assignment revision. |
| Halls | Restored state, active recipe, production cursor, reserve policy, target, and active state. |
| Recollections | Purchased nodes and resulting unlock/effect state. |
| Progression | Command tether capacity, milestones, guarantees, resonance IDs, counters, unlock flags, and world flags. |
| Story | Scripted opening state, narrative entities, Brand state, and resumable narrative checkpoints. |
| Tutorial | Current state, completed presentation steps, skip/help flags, and presented notification IDs. |
| Reports | Current accumulator and bounded report history. |

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

### 9.1 Units

All authoritative elapsed and timestamp fields use integer milliseconds and end in `_msec` or `_utc_msec`.

Do not mix:

- seconds and milliseconds;
- elapsed durations and absolute timestamps;
- wall-clock time and monotonic active-session time;
- simulation time and UI animation time.

### 9.2 Online clock

Online play uses a monotonic clock source. The production loop advances at a configurable application cadence, not once per rendered frame as an authoritative rule.

Recommended behavior:

1. `GameApp` samples the injected monotonic clock and tracks the application cursor.
2. At each application simulation update, it computes elapsed monotonic milliseconds.
3. It passes the elapsed interval to `GameSession`, which invokes `SimulationEngine`.
4. UI may interpolate committed values between updates.

The simulation cadence is a prototype tuning value. Changing it must not change the final result for a fixed interval.

### 9.3 Offline clock

Offline elapsed time uses a UTC wall-clock timestamp saved with the committed snapshot.

On load or focus regain:

```text
elapsed_msec = now_utc_msec - last_resolved_utc_msec
```

Rules:

- clamp a negative result to zero and record a warning;
- apply any configured offline cap explicitly and report reduced or unprocessed time;
- the cap remains configurable and must permit the required eight-hour prototype path;
- do not attempt production-grade anti-cheat during the prototype;
- do not mix an online monotonic cursor into a persisted wall-clock calculation.

### 9.4 Focus changes

On focus loss, resolve online time to the current monotonic cursor and save. While unfocused, treat the interval as offline rather than allowing a second live loop to resolve the same time. On focus regain, resolve the wall-clock gap once, save the result, then restart the monotonic cursor.

Menus, dialogue, and tutorial overlays are not focus loss and never pause simulation.

### 9.5 Clock injection

Application lifecycle code receives clock adapters through construction. Simulation and domain services receive elapsed durations, not clocks, except where a narrowly scoped timestamp service is explicitly required. They do not call system time directly. Tests use a `FakeClock`.

## 10. Deterministic simulation architecture

### 10.1 One engine, four modes

`SimulationEngine` supports four call contexts:

| Mode | Mutates authoritative state | Purpose |
|---|---:|---|
| Live | Yes | Normal foreground progress. |
| Offline | Yes, through a transactional load flow | Elapsed time since the last committed timestamp. |
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

Discrete owned quantities, returned-soul counters, backlog, reservations, completed-cycle counts, and authoritative timestamps use 64-bit integers.

Authored content may expose editor-friendly decimal coefficients. `ContentRegistry` normalizes those values once into immutable fixed-point runtime values before gameplay. `SimulationEngine` uses only the normalized integer values.

Fractional production uses one centralized fixed-point utility and persisted residuals. The exact scale is selected in the foundation milestone, recorded in `FixedPoint`, and may not vary by subsystem.

Required properties:

- every authoritative fractional state is represented by an integer scaled value or integer residual;
- residuals survive save/load;
- resolving one eight-hour interval produces the same authoritative result as resolving equivalent smaller intervals when the same boundaries are crossed;
- UI formatting never writes rounded values back into state;
- rate changes occur only at explicit boundaries;
- overflow bounds are documented and tested;
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
- discovery progress per channel.

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
- stream fractional remainders that belong to the operation;
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

Each Threshold definition declares independent channels. The prototype channel types are:

- backlog returns;
- Corrupted Essence;
- active Form Mastery;
- Form Souls;
- Calling Souls;
- materials;
- future Denizen Souls, disabled for the prototype unless explicitly added.

The resolver computes each channel separately from the same segment context. Adding or changing one channel must not silently reduce another unless a documented modifier explicitly does so.

Discovery state controls player knowledge, not whether output exists. Hidden Provisions produced at Broken Watch are banked to inventory and reported as hidden output events until identified. Identification changes disclosure; it does not retroactively generate or erase resources.

Forecast uncertainty is information uncertainty, not necessarily production randomness. Scribe may narrow the displayed range around a deterministic underlying result.

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

### 20.1 Save format

Use an explicit versioned JSON snapshot under `user://saves/` for the prototype. Runtime objects are converted to schema-controlled dictionaries and arrays before encoding.

Godot JSON represents all JSON numbers as floating-point values. To preserve 64-bit counters, fixed-point values, residuals, save revisions, and timestamps exactly, the save codec serializes every schema field typed as an authoritative integer as a canonical base-10 string. It decodes that string with range and format validation before constructing runtime state. Small enums and booleans remain ordinary JSON values; canonical IDs are strings; sets are sorted arrays.

Example wire representation:

```json
{
  "schema_version": "1",
  "save_revision": "42",
  "last_resolved_utc_msec": "1783872000000",
  "remaining_backlog": "998996",
  "mastery_subunits": "1250000"
}
```

Do not pass runtime dictionaries containing exact integers directly to `JSON.stringify()` and assume integer type or precision will survive.

The top-level envelope includes:

- schema version;
- content revision;
- save revision;
- creation, commit, and last-resolved UTC milliseconds;
- optional last offline-resolution ID for diagnostics;
- authoritative `GameState` data.

### 20.2 Atomic write pattern

`SaveService` should:

1. serialize the complete candidate snapshot to a temporary file;
2. flush and close it;
3. reopen, parse, and validate the temporary snapshot;
4. retain the previous valid primary as a backup;
5. replace the primary with the validated candidate;
6. report failure without deleting the last valid save.

The exact file-rename sequence must be tested on Windows and in the Codex Cloud Linux environment.

### 20.3 Load selection

On load:

- validate primary and backup independently;
- choose the valid snapshot with the highest save revision;
- reject an unsupported future schema with a clear error;
- apply sequential migrations for older supported schemas;
- validate IDs and invariants before simulation begins.

### 20.4 Offline resolution transaction

Offline resolution uses a working clone:

1. load, migrate, and validate a committed snapshot;
2. calculate the target UTC time and elapsed interval;
3. resolve the interval on the clone;
4. assign a stable offline resolution ID;
5. update the last-resolved timestamp;
6. atomically save the resolved clone while retaining the pre-resolution file as backup;
7. only then expose the resolved state and welcome-back report to presentation.

If the application stops before step 6, the old committed snapshot resolves again on next load. If it stops after step 6, the new timestamp and resolution ID prevent duplicate gains.

### 20.5 Migrations

Migrations are explicit functions from schema N to N+1. They operate on save dictionaries before runtime objects are constructed. Every migration has fixtures and tests.

Changing the meaning of a canonical ID, removing a persisted field, or changing reservation semantics requires a migration or a deliberate prototype save reset documented in the decision log.

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
| Clock | monotonic plus UTC system clock adapter | `FakeClock` with explicit values |
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
    save_service.gd
    save_storage.gd
    file_save_storage.gd
    save_migrations.gd
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
- adds an autoload, plugin, dependency, or framework without scoped approval;
- introduces a content rule that cannot be explained through the shared modifier or effect grammar;
- makes a UI animation or tutorial callback the only trigger for a required state change.

## 26. Open architecture items

The following remain deliberately open until a later approved milestone or playtest provides evidence:

- exact simulation update cadence during live play;
- exact fixed-point scale, provided it is centralized and tested;
- general offline cap beyond the required eight-hour path;
- report-history retention count;
- final save-file naming and number of player slots;
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

