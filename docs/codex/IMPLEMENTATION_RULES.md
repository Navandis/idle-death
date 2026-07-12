# Death Idle Implementation Rules

**Document role:** Detailed engineering conventions for Godot 4.7 and GDScript implementation  
**Repository path:** `docs/codex/IMPLEMENTATION_RULES.md`  
**Document status:** Draft for Phase 6 approval  
**Rules revision:** 1  
**Last updated:** 2026-07-12  
**Architecture companion:** [ARCHITECTURE.md](ARCHITECTURE.md)  
**Data companion:** [DATA_AND_CONTENT_CONTRACTS.md](DATA_AND_CONTENT_CONTRACTS.md)

## 1. Purpose

The root `AGENTS.md` contains the rules Codex must see on every task. This document expands the engineering details without turning the root file into a full technical manual.

Apply these rules to new code and to code materially changed by a task. Do not perform broad rewrites solely to make untouched prototype scaffolding conform before its milestone.

## 2. General implementation priorities

When several implementations are possible, prefer the one that is:

1. correct under save/load and elapsed-time resolution;
2. deterministic and directly testable;
3. clear to a junior engineer;
4. explicit about ownership and units;
5. small enough for the current prototype;
6. data-driven where the prototype already needs variation;
7. easy to inspect in a pull request;
8. compatible with Godot 4.7 and GDScript only.

Avoid compressed, clever, or highly generic code when an explicit version is easier to verify.

## 3. GDScript naming and file organization

Follow the Godot GDScript style guide unless this repository documents a narrower rule.

| Item | Convention | Example |
|---|---|---|
| Script filename | `snake_case.gd` | `simulation_engine.gd` |
| Scene filename | `snake_case.tscn` | `threshold_detail.tscn` |
| Class name | `PascalCase` | `SimulationEngine` |
| Method and variable | `snake_case` | `resolve_elapsed_msec` |
| Signal | past-tense or event phrase in `snake_case` | `state_changed` |
| Constant | `SCREAMING_SNAKE_CASE` | `PROGRESS_SCALE` |
| Canonical content ID | uppercase prefix format | `THR_GLOAMWOOD` |
| Boolean | affirmative predicate | `is_awakened`, `has_pending_report` |
| Duration | unit suffix | `elapsed_msec` |
| Absolute time | UTC suffix | `saved_at_utc_msec` |

Use `class_name` for reusable domain, simulation, content-definition, and result types when global naming improves readability. Avoid globally naming one-off screen helpers.

## 4. Static typing

Use static type annotations for:

- public methods;
- return values;
- exported fields;
- state fields;
- arrays and dictionaries where Godot supports the needed typed form;
- IDs represented as `StringName`;
- numeric values whose units matter;
- command results and simulation results.

Do not force an awkward type solely to eliminate every inferred local. Inference is acceptable when the type is immediate and unambiguous.

Avoid returning loosely structured dictionaries from domain services when a small named result type would make the contract clearer. Primitive dictionaries remain appropriate at the explicit JSON serialization boundary.

## 5. Junior-readable documentation and comments

### 5.1 Script documentation

Every non-trivial script begins with a `##` documentation block that explains:

- its responsibility;
- what state it owns or mutates;
- what state it explicitly does not own;
- its important collaborators;
- its time units;
- its determinism, save, or lifecycle assumptions where relevant.

Example subject matter:

```gdscript
## Resolves all active Reapings and Halls over one elapsed interval.
##
## This service mutates a supplied GameState but does not read system time,
## access the scene tree, or save files. Callers must supply elapsed
## milliseconds and a validated ContentRegistry.
```

### 5.2 Public member documentation

Use `##` comments for non-obvious reusable:

- classes;
- signals;
- enums;
- constants;
- exported properties;
- public methods;
- domain commands;
- serialization methods;
- simulation boundary calculations.

Document preconditions, units, mutations, failure behavior, and whether a returned object is mutable.

### 5.3 Inline reasoning comments

Use ordinary `#` comments before non-obvious sections to explain:

- why a boundary is resolved before another boundary;
- which invariant is being protected;
- why a clone is required;
- how duplicate offline rewards are prevented;
- why a reservation remains part of owned inventory;
- why a tutorial callback cannot directly grant a reward;
- why a value is deliberately not persisted;
- how a Godot lifecycle callback relates to application state.

Do not comment every assignment or restate syntax.

Good:

```gdscript
# Hall output at this timestamp is banked before support is recalculated.
# This lets a Ration batch completing exactly at depletion prevent a false
# one-segment degradation, and it matches the documented boundary order.
```

Poor:

```gdscript
# Add rations.
rations += amount
```

### 5.4 Comments are maintained behavior

A stale explanatory comment is a defect. Update comments in the same change as behavior. Delete dead code instead of leaving large commented-out blocks.

## 6. Dependency and ownership rules

### 6.1 Domain and simulation

Domain and simulation scripts:

- extend `RefCounted` unless a different base type is required for authored content;
- receive dependencies through constructors or explicit initialization;
- do not call `get_tree()`;
- do not search `/root`;
- do not access screen nodes;
- do not call system time directly;
- do not read input;
- do not play audio or animation;
- do not save files;
- do not use `await` for authoritative progression;
- do not contain storefront code.

### 6.2 Presentation

Presentation scripts:

- extend appropriate Node or Control classes;
- read view models or immutable snapshots;
- issue commands through `GameSession`;
- may animate displayed values independently;
- must not grant resources, reduce backlog, reserve Souls, complete milestones, or calculate a competing production formula.

### 6.3 Tutorial

Tutorial scripts may request normal commands or approved guarantees. They do not mutate another subsystem's state dictionary directly.

### 6.4 Persistence

Persistence code serializes and reconstructs explicit state contracts. It does not own game rules, calculate production, or decide whether a milestone should fire.

## 7. Application root and no-gameplay-autoload rule

The configured main scene becomes a persistent root `Control` named `GameApp`. It owns the `GameSession` instance, screen host, persistent HUD regions, overlays, and Godot lifecycle callbacks.

Do not add a gameplay autoload initially. Screens receive an explicit `GameSession` or narrower presenter/controller reference when they are instantiated. They must not search `/root` to obtain authority.

Adding an autoload later requires:

- a scoped persistent cross-scene need that `GameApp` cannot satisfy clearly;
- ownership and lifetime documentation;
- tests or a validation plan;
- an entry in `DECISIONS.md`;
- explicit owner approval when it changes the architecture.

Do not add separate global singletons for inventory, tutorial, saves, reports, Forms, Halls, or simulation. Tests construct application and domain services directly without loading `GameApp`.

## 8. State mutation rules

### 8.1 Validate before mutation

For a player command:

1. resolve simulation to the command time;
2. inspect all required state;
3. return a failure result without mutation if any precondition fails;
4. apply the complete valid change;
5. run progression evaluation;
6. save when required;
7. notify presentation once the state is coherent.

Do not debit one resource, discover a later failure, and leave a partial transaction.

### 8.2 Centralize mutation

Only the owning service mutates its state:

- inventory service owns spending and reservations;
- Form service owns awakening and Mastery state transitions outside simulation accumulation;
- Reaping service owns dispatch and assignment;
- Hall service owns restoration and configuration;
- Recollection service owns purchases;
- progression processor owns milestone, guarantee, unlock, and resonance completion;
- tutorial coordinator owns tutorial presentation state;
- report service owns report accumulator snapshots and history.

Simulation may call these services or narrowly scoped internal mutation methods. It must not duplicate their validation rules.

### 8.3 No shared mutable definition data

Treat authored Resources as immutable after registry validation. Never store player progress by changing a loaded `FormDefinition`, `ThresholdDefinition`, or other shared Resource.

## 9. Commands and results

Use explicit command methods with stable failure reason codes.

A command result should normally include:

```text
success
reason_code
message
domain_event_ids
```

Examples of reason codes:

```text
INSUFFICIENT_AVAILABLE_RESOURCE
FORM_NOT_AWAKENED
THRESHOLD_NOT_AVAILABLE
COMMAND_TETHER_LIMIT_REACHED
RETINUE_SLOT_INCOMPATIBLE
RESERVATION_CONFLICT
ALREADY_COMPLETED
INVALID_CONTENT_REFERENCE
```

Player-correctable validation failures should not call `push_error()`. Unexpected invariant violations should produce clear diagnostics and fail tests.

## 10. Time and determinism rules

### 10.1 Explicit elapsed input

A simulation method receives an integer elapsed duration. It must not calculate elapsed time internally.

Preferred signature shape:

```text
resolve(state, content, elapsed_msec, mode) -> SimulationResult
```

### 10.2 No frame-dependent authority

Do not use rendered frame count, delta accumulation in a screen, animation completion, or timers attached to hidden scenes as authoritative production.

A Node may schedule calls to `GameSession`, but the elapsed amount comes from the application clock and the simulation result is independent of frame rate.

### 10.3 Stable ordering

Sort canonical IDs before processing equal-priority dictionaries or sets. Use the boundary priority in `ARCHITECTURE.md`.

### 10.4 Central fixed-point utility

All fixed-point conversion and arithmetic belongs in one documented utility. Do not reproduce scaling and remainder logic in each output channel.

The utility must:

- use 64-bit integers;
- check invalid negative inputs where the domain forbids them;
- preserve remainders;
- avoid integer overflow for supported prototype horizons;
- have direct unit tests;
- explain rounding behavior for junior reviewers.

Every residual has exactly one documented owner identified by a stable flow key. Do not store the same fractional remainder in both a Threshold/channel record and its active Reaping. Reassignment, save/load, and settlement must preserve or deliberately transform that owner through a tested rule.

### 10.5 Chunking invariance

A change is not deterministic merely because repeated full runs happen to match. Test that equivalent elapsed intervals resolved in different chunk sizes produce identical authoritative results when they cross the same boundaries.

### 10.6 Randomness

Do not introduce authoritative randomness during the prototype. If a milestone later requires it, stop and define seed ownership, save fields, forecast semantics, and deterministic tests first.

## 11. Simulation implementation rules

### 11.1 Global resolution

Resolve all active Reapings and Halls within one global simulation call. Shared Stores make independent loops unsafe.

### 11.2 Pure rate derivation

Rate derivation should be a pure calculation from:

- validated definitions;
- current runtime state;
- current assignments;
- active modifiers;
- support and lifecycle state.

It returns effective rates and a modifier trace without mutating state.

### 11.3 Boundary finders

Each subsystem may report its next possible boundary, but one coordinator chooses the earliest global boundary.

A boundary report should contain:

```text
time_until_boundary_msec
boundary_type
source_id
stable_sort_key
```

Use a sentinel or optional value for no boundary. Never return zero repeatedly without a transition that changes state.

### 11.4 Apply transitions after flows

Continuous flows for the elapsed segment are committed before transitions at its endpoint. Then use the documented same-time priority.

### 11.5 Forecast mode

Forecast mode uses a deep state clone and the same engine. Do not add `if forecast` branches that change balance behavior. Mode-specific differences may include:

- how much trace data is retained;
- whether report events are accumulated;
- whether a save checkpoint is requested;
- whether tutorial presentation is emitted.

### 11.6 No per-cycle history

Store aggregate totals, fractional remainders, completed-cycle counts, and meaningful events. Do not retain an object for every cycle or returned soul.

## 12. Inventory and reservation rules

### 12.1 One owned total

Inventory stores one owned total per ID. Reservation records make part of that total unavailable.

Never model a reservation by subtracting from owned and adding to an unrelated hidden inventory bucket.

### 12.2 Spending and availability

Normal spending checks available quantity. The inventory service calculates availability; UI does not subtract reservation totals independently.

### 12.3 Reservation lifecycle

Reservation creation, change, and release are atomic. A reservation identifies its owner and purpose. Removing Soldier Company releases exactly its twelve-Soldier reservation.

### 12.4 No attrition in prototype

Do not add strain, settlement, scattering, replacement, or time-based Soul loss while implementing reservation foundations.

## 13. Content implementation rules

### 13.1 Typed Resources

Use custom Resource classes for authored definitions. Store them as text `.tres` files and register them through the explicit `ContentCatalog`.

Do not embed game balance inside `.tscn` node properties when it belongs to a definition.

### 13.2 No arbitrary content execution

Definitions contain values, conditions from an approved grammar, modifiers, and effects. They do not contain arbitrary `Callable` fields, script paths to execute, or expressions evaluated from strings.

### 13.3 Central validation

Content validation runs before gameplay. Invalid content should produce all useful errors in one pass where practical, with:

- file or definition ID;
- field name;
- invalid value;
- expected contract;
- referenced missing ID when applicable.

### 13.4 Provisional values

A temporary rate or cost must be:

- stored once;
- labeled as prototype scaffold or provisional;
- referenced by tests through fixture values or definitions rather than duplicated literals;
- easy to tune without changing presentation code.

## 14. Serialization rules

### 14.1 Explicit conversion

Each runtime state class provides an explicit primitive conversion such as:

```text
to_save_data() -> Dictionary
from_save_data(data, content) -> ValidationResult
```

Avoid generic reflection-based object dumps.

### 14.2 Exact JSON integer codec

Godot JSON converts numerical Variant values to JSON number/float values. Every authoritative runtime integer therefore crosses the JSON boundary as a canonical base-10 string, including:

- schema and save revisions;
- UTC timestamps and elapsed durations;
- inventory, reservation, backlog, and counter quantities;
- fixed-point subunits and residuals;
- cycle and assignment revisions.

Use one shared codec. It must reject whitespace, leading plus signs, decimal points, exponents, non-canonical leading zeroes, non-digits, and values outside the signed 64-bit range. A leading minus sign is accepted only for a field whose contract explicitly permits a negative value.

Do not serialize authoritative integers as JSON numbers. Do not accept a parsed `float` and cast it back to `int`.

Canonical IDs and persisted enum values are strings. Set-like state is written as sorted, duplicate-free arrays. Dictionary keys are strings. Authoritative save dictionaries do not contain non-finite or locale-formatted numbers.

### 14.3 Defensive parsing

Validate types, ranges, IDs, content revision, and cross-field invariants. Do not assume a JSON key exists or has the expected type.

When a recoverable optional field is absent, apply a documented default. When a required field is invalid, reject the candidate save and try the backup.

### 14.4 No scene references

Never serialize Node paths, Object instance IDs, live Resource references, signals, or Callables in the save.

### 14.5 Versioning

Migrations operate on primitive dictionaries before runtime object construction. One migration advances exactly one schema version.

### 14.6 Atomic files

Use temporary, primary, and backup files as documented. Check every file operation result. Flush and close before validation or rename.

### 14.7 Save checkpoints

A required checkpoint is part of the feature, not optional polish. Save after the actions listed in the prototype source of truth and after report archival when necessary to prevent duplicate presentation.

## 15. Godot scene and lifecycle rules

### 15.1 Scene responsibility

Use scenes for:

- visual composition;
- reusable controls;
- screen routing;
- overlays;
- animation and audio presentation.

Do not use scenes as the only storage for domain state.

### 15.2 `_ready()`

Use `_ready()` to acquire injected or onready presentation references and connect presentation signals. Do not silently grant resources, create saves, or resolve offline time from arbitrary screen `_ready()` methods.

Godot lifecycle ownership belongs to `GameApp`; startup, load, and domain coordination are delegated to its `GameSession` instance.

### 15.3 `_process()` and timers

Presentation interpolation may use `_process()`. Authoritative simulation scheduling should be centralized in the application layer and pass elapsed time to the simulation engine.

Avoid many unrelated Timer nodes for production systems.

### 15.4 Signals

Signals describe committed changes or presentation events. Document:

- who emits;
- who is expected to listen;
- whether the state is already committed;
- whether a listener may issue another command.

Avoid signal chains in which the order of listeners determines authoritative results.

### 15.5 Node references

Use typed `@onready` references for known scene children. Validate optional references clearly. Avoid repeated `get_node()` searches through unrelated ancestors.

## 16. UI and view-model rules

### 16.1 Read-only data

Controls receive read models or copied values. They do not retain mutable `GameState` or substate references.

### 16.2 Button flow

A button:

1. gathers player intent;
2. optionally displays a non-authoritative preflight state;
3. sends a command;
4. handles success or a stable failure reason;
5. refreshes from committed state.

It does not optimistically mutate authoritative values.

### 16.3 Display rounding

Formatting belongs to presentation helpers. Display strings never become inputs to domain calculations.

### 16.4 Unknown information

Do not leak hidden output names, exact quantities, or ranges through tooltips, accessibility labels, logs intended for players, or comparison widgets before discovery permits them.

Developer debug views may show hidden values when clearly marked and unavailable in release builds.

### 16.5 Accessibility and resizing

Build controls with anchors, containers, minimum sizes, and stretch-aware assets. Avoid hard-coded pixel positions for functional UI unless a scene is an explicitly fixed cutscene composition with a validated scaling plan.

## 17. Error handling and diagnostics

### 17.1 Error categories

Distinguish:

- player validation failure;
- invalid content;
- corrupt or unsupported save;
- recoverable file-operation failure;
- programmer invariant failure;
- environment limitation.

### 17.2 Logging

Logs should include stable IDs and units. Avoid vague messages such as `something failed`.

Good:

```text
Cannot field RET_SOLDIER_COMPANY at THR_GLOAMWOOD: 10 Soldier Souls available, 12 required, 2 reserved elsewhere.
```

### 17.3 Assertions

Use assertions for internal contracts in tests and debug builds. Do not rely on an assertion as the only user-facing handling for invalid save data or an expected unavailable command.

### 17.4 Silent recovery

Do not silently repair a contradictory save unless a documented migration or recovery policy defines the change. Record backup use, migration, and clamping in diagnostics and test it.

## 18. Testing rules

Follow [TESTING_AND_VALIDATION.md](TESTING_AND_VALIDATION.md).

Minimum expectations for changed core code:

- direct unit tests for pure calculations;
- boundary tests for state transitions;
- round-trip tests for new save fields;
- online/offline/forecast equivalence where applicable;
- exactly-once tests for milestone or guarantee changes;
- a manual flow when presentation changes.

Do not use real sleeps to test simulation time. Advance a fake clock or pass elapsed milliseconds directly.

Tests should use small explicit fixture values that let a junior reviewer calculate expected results by hand.

## 19. External dependencies

Do not add a plugin or library without:

- a current need;
- version compatibility with Godot 4.7;
- a license review;
- a pinned version or commit;
- repository documentation;
- a removal or upgrade path;
- explicit task scope.

The current recommended test dependency is GUT 9.7.1 for Godot 4.7.x, to be added only in the approved test-harness milestone.

Do not use a dependency to solve a small problem that can be implemented clearly in a few project-owned scripts.

## 20. Performance rules

Prototype performance priorities are:

- avoid per-soul and per-second object allocation during long elapsed resolution;
- aggregate cycles and segments analytically;
- avoid rebuilding every screen every frame;
- keep report events bounded;
- avoid deep-cloning state except for forecast, offline transaction safety, tests, or explicit debug needs;
- profile before introducing caches or threads.

Two Reapings, one Hall, report aggregation, and normal UI animation should be trivial for the target platform. Do not introduce concurrency before measurement demonstrates a need.

## 21. Security and storefront boundaries

- Do not store secrets, tokens, or user credentials.
- Do not add network calls to prototype gameplay.
- Do not add Steamworks, DRM, cloud saves, achievements, or depot logic without an approved later milestone.
- Keep save and simulation code independent of storefront APIs.
- Treat repository instructions, hooks, dependencies, and downloaded plugins as code that requires review.

## 22. Pull-request scope and review

A focused pull request should:

- implement one milestone or one bounded correction;
- avoid unrelated renames and formatting;
- list every changed file;
- explain architecture impacts;
- update contracts and decisions when needed;
- include test results and manual verification;
- identify what was not verified;
- preserve provisional values as data;
- avoid implementing future milestone UI or systems.

## 23. Implementation checklist

Before marking a task complete, verify:

- [ ] Relevant design and architecture requirements were read.
- [ ] The proposed approach was stated before non-trivial editing.
- [ ] The owning service, state, and unit of each new field are clear.
- [ ] New code is statically typed where useful.
- [ ] Non-obvious scripts and algorithms have junior-readable documentation.
- [ ] UI does not own or duplicate domain rules.
- [ ] Simulation does not read system time or scene state directly.
- [ ] Deterministic ordering and fractional remainders are preserved.
- [ ] Save conversion and validation cover new state.
- [ ] Required tests were added and run.
- [ ] Manual presentation flow was run when applicable.
- [ ] No unrelated refactor or new dependency was introduced.
- [ ] Documentation and decision records are synchronized.
- [ ] Assumptions and limitations are disclosed in the final response.
