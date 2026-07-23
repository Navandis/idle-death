# Death Idle Implementation Rules

**Document role:** Detailed engineering conventions for Godot 4.7 and GDScript implementation  
**Repository path:** `docs/codex/IMPLEMENTATION_RULES.md`  
**Document status:** Approved engineering rules  
**Rules revision:** 8  
**Last updated:** 2026-07-22  
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
| Simulation timeline | simulation suffix | `occurred_simulation_msec` |
| Trusted external epoch | trusted UTC suffix | `trusted_anchor_utc_msec` |

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
## This service mutates a supplied GameState but does not read clocks,
## platform APIs, the scene tree, or save files. Callers must supply elapsed
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

### 8.4 Single-provenance supplied-duration simulation

For the one-active-Reaping supplied-duration resolver, open one internal
transaction from the validated source. The transaction owns one deep-cloned
candidate, one immutable run context, one bounded fact journal, checked
mutation operations, final candidate/journal validation, compatibility result
projection, and the one final live `copy_from`.

`SimulationEngine` remains the formula and segmentation owner. It may calculate
pure endpoint plans from detached transaction snapshots, but no gameplay field
may be written outside the transaction operations. The operation that changes a
candidate endpoint must record its explanatory fact from the same before/after
values. Do not add a public commit method that accepts an arbitrary candidate and
independently authored result. Do not derive a second authoritative summary by
diffing candidate state after the journal projection.

Candidate validation precedes journal freeze and result projection; any failure
after partial private work returns without changing live state. The journal is
runtime evidence only and is not persisted, replayed, or retained as report
history.

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

Simulation code must not call Godot device-wall-clock APIs, Steam APIs, file timestamp APIs, or any clock adapter.

### 10.2 Distinct time owners

Use three distinct concepts:

- `elapsed_msec`: duration supplied to one simulation call;
- `simulation_time_msec`: monotonic credited gameplay timeline stored in `GameState`;
- `trusted_anchor_utc_msec`: external trusted epoch stored only in `TimeAuthorityState` for closed-session reconciliation.

Never substitute one for another. Domain events, report windows, Reaping start times, and configuration-change times use the simulation timeline rather than the device calendar.

### 10.3 Foreground monotonic clock

Only the application/lifecycle layer samples the injected monotonic process clock. It computes a non-negative foreground duration, passes that duration into `GameSession`, and records the same credited interval in time-authority accounting.

Do not use rendered frame count, delta accumulation in a screen, animation completion, or timers attached to hidden scenes as authoritative production.

A Node may schedule calls to `GameSession`, but the result must be independent of frame rate and window focus.

### 10.4 Trusted closed-session time

Closed-session elapsed time comes only from the injected `TrustedTimeProvider` contract described in `ARCHITECTURE.md` and `DEC-0021`.

Rules:

- never use local date, local UTC, timezone, daylight-saving state, file modification time, or user input as a fallback;
- when trusted time is unavailable, load without closed-session gains, mark reconciliation pending, and continue foreground production;
- subtract foreground time already credited since the last trusted anchor before resolving a later trusted gap;
- never move a trusted anchor backwards;
- suspicious or contradictory samples grant no progress and produce diagnostics;
- apply the configured offline cap after deriving the non-negative uncredited gap;
- update the trusted anchor and reset credited-foreground accounting only in the same successful save transaction that commits the offline result.

The approved binding is GodotSteam 4.20 under `addons/godotsteam/`. Only M06 may call it, and all wrapper-specific methods remain inside the platform adapter. Headless tests use fake providers or a fake Steam bridge and never initialize Steam.

### 10.5 No frame-dependent authority

Presentation interpolation may use `_process()`. Authoritative production must not be computed from a screen's frame loop, animation state, or visibility.

### 10.6 Stable ordering

Sort canonical IDs before processing equal-priority dictionaries or sets. Use the boundary priority in `ARCHITECTURE.md`.

### 10.7 Central fixed-point utility

All fixed-point conversion and arithmetic belongs in one documented utility. Do not reproduce scaling, period accumulation, whole-unit extraction, or remainder logic in each output channel.

The project scale is `1_000_000` subunits per whole unit under `DEC-0026`. Apply it only to meaningful fractional state. Whole inventory objects, backlog, command tethers, and other discrete counts remain unscaled integers.

The utility must:

- use signed 64-bit integers and non-negative flow contracts unless a method explicitly documents signed behavior;
- support rates with an explicit positive period, not only integer subunits per second;
- check invalid inputs before mutation;
- return produced subunits and any exact arithmetic carry explicitly;
- extract whole units and retain `progress_subunits % SCALE` exactly;
- avoid integer overflow for supported prototype horizons, including decomposed final-fit calculations;
- have direct unit tests, including one whole unit per twenty-four hours;
- explain scale, period, denominator, ownership, and floor behavior for junior reviewers.

Every progress value and carry has exactly one documented owner identified by a stable flow key. Do not store the same fractional state in both a Threshold/channel record and its active Reaping. Reassignment, save/load, and settlement must preserve or exactly normalize the owner through a tested rule.

### 10.8 Chunking invariance

A change is not deterministic merely because repeated full runs happen to match. Test that equivalent elapsed intervals resolved in different chunk sizes produce identical authoritative results when they cross the same boundaries.

### 10.9 Randomness

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

### 11.7 Long-horizon discrete output channels

For a deterministic rare source governed by `DEC-0027`:

- store progress on the stable Threshold output channel, not on the current Form, Writ, Retinue, or a disposable Reaping record;
- resolve elapsed time under the old configuration before changing future modifiers;
- bank every whole unit crossed and retain the remaining normalized progress and exact carry;
- derive each future effective rate from immutable baseline data plus current modifiers; never apply a new modifier to a previously modified effective rate;
- keep one stable normalized rate period/denominator per channel within a content revision; ordinary live modifiers change the effective numerator or multiplier so the existing carry retains its meaning;
- leave stored progress unchanged when a Form, Writ, Retinue, Form Art, Recollection, support state, lifecycle, or other ordinary rate modifier changes;
- treat modifier changes as simulation boundaries so the old rate applies before the boundary and the new rate applies after it;
- ensure repeated recall/redispatch with the same state cannot compound a bonus;
- preserve progress while the Threshold is inactive and across Overdue-to-Settled transition when the source remains available;
- do not persist effective rate, ETA, or a time-based reinterpretation of the progress percentage;
- do not create a timer or object per future drop;
- keep player inventory whole-numbered;
- keep Unknown progress hidden, and expose a one-decimal, floor-derived progress bar only when disclosure permits it.

A Threshold-level acquisition bar is not a second Reaping-cycle bar. It displays durable saved progress toward a specific known whole output.

At `50.0%` progress, an improved rate may shorten the ETA without changing the bar. A percentage jump requires actual future accumulation or an explicit exactly-once progress grant; an ordinary rate bonus is not retroactive.

### 11.8 Single-provenance simulation transactions

For an authoritative elapsed transaction, candidate mutation and explanatory facts must share one provenance.

Required shape:

```text
validated source + explicit request
  -> transaction-owned private candidate
  -> checked mutation operation
  -> journal fact recorded from the same before/after values
  -> candidate validation
  -> public result derived from finalized journal
  -> one live commit
```

Rules:

- No production or test-facing commit method accepts both an independently supplied mutable candidate and an independently supplied result, event list, or summary.
- The transaction creates its candidate from the source and does not expose it for arbitrary mutation before finalization.
- Every authoritative field changed by the transaction appears in a mutation-ownership inventory before implementation.
- A transaction mutation method either updates all affected candidate fields and records its corresponding fact, or does neither.
- Formula/rate helpers may remain pure and return checked calculations; they do not mutate the candidate or author public result facts.
- Compatibility summaries and public events are derived from finalized journal facts. They are never populated independently in parallel with the mutation.
- Boundary facts capture values at the boundary. Do not reconstruct an event's payload from the final run state after later segments.
- The journal is bounded runtime evidence for one call. Do not persist it, replay it, expose it as analytics authority, or generalize it into a project-wide event-sourcing framework.
- Candidate validation occurs before the live `copy_from` commit. Failure at any stage leaves the source state canonically unchanged.
- Public detached results are constructed only after the journal is finalized and the candidate is valid.

A source audit is useful supplemental evidence, but behavioral fault tests must also prove that failures after partial candidate work do not mutate the live state.

### 11.9 Result and compatibility-view ownership

A public result is an observation of a finalized transaction, not a second mutation authority.

- Do not allow callers to construct a result and submit it for live-state commit.
- Do not make a compatibility dictionary the only owner of historical identity or channel endpoints.
- Compare detached typed objects by documented fields, not object identity.
- When a public result contract changes, migrate all current production, debug, test, and trace consumers in one bounded slice; do not maintain parallel raw and typed public grammars indefinitely.
- Internal journal/trace dictionaries remain permitted when they are bounded diagnostics and never become the public result or persistence contract.

### 11.10 Finalized typed simulation facts

M04E2T2 public facts are projected only after the M04E2T1 candidate is valid and the transaction journal is frozen.

Required rules:

- The projector receives immutable run context and frozen journal facts only. It receives no live or candidate `GameState`.
- Public result classes are focused global `RefCounted` types with static field types, junior-readable ownership documentation, detached-copy behavior, and value equality.
- Prefer read-only public properties backed by private fields. Consumers do not mutate retained facts.
- Result kinds are closed and structurally distinct: failure, zero-duration, positive timeline-only, and positive active-Reaping.
- Segment identity is historical context captured at run time, not a lookup against current Reaping state.
- Channel carry includes its rate period so the detached endpoint is locally interpretable.
- Public events use a closed typed union. Do not accept an arbitrary event payload dictionary or unknown event type.
- Every event names its owning segment index and also obeys start-exclusive/end-inclusive timing and stable sort order.
- Pure structural validation may check domains, timing, identity continuity, ordering, cardinality, and projection integrity. It must not recreate candidate/result reconciliation or duplicate gameplay formulas.
- Raw public segment/channel dictionaries, generic event payload dictionaries, and simulation `change_summary` are removed when current consumers migrate. Do not keep a hidden fallback public API.
- Result facts remain non-authoritative and non-persisted. Schema and content revision do not change merely because the public representation changes.

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

### 13.2 Stable IDs and editable player-facing names

- Use canonical IDs for logic, references, saves, tests, and analytics. Never branch on `display_name`, Trait text, Recollection text, or another player-facing string.
- Keep editable fallback names and descriptions in content Resources. Optional localization keys may be present before the full localization pipeline exists.
- Give inline named rules such as the prototype Traits a stable `TRAIT_...` identity plus editable display text. Future Arts and Denizens follow the same identity-versus-name rule when introduced.
- Resolve shared system nouns through the catalog's `TERM_...` entries. Do not hard-code core labels throughout scenes or view models.
- A player-facing rename does not rename internal prefixes or saved IDs. For example, a future replacement for the word Threshold does not require changing `THR_...`.
- Free-form prose is not generated by terminology substitution. A core-term change requires a reviewed repository/content search so grammar and narrative context remain correct.
- Use **Essence** and `RES_ESSENCE` everywhere. Production content validation rejects the deprecated alternate name and ID.

### 13.3 No arbitrary content execution

Definitions contain values, conditions from an approved grammar, modifiers, and effects. They do not contain arbitrary `Callable` fields, script paths to execute, or expressions evaluated from strings.

### 13.4 Central validation

Content validation runs before gameplay. Invalid content should produce all useful errors in one pass where practical, with:

- file or definition ID;
- field name;
- invalid value;
- expected contract;
- referenced missing ID when applicable.

### 13.5 Provisional values

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
- trusted UTC anchors, simulation timeline values, and elapsed durations;
- inventory, reservation, backlog, and counter quantities;
- fixed-point subunits and residuals;
- cycle and assignment revisions.

Use one shared codec. It must reject whitespace, leading plus signs, decimal points, exponents, non-canonical leading zeroes, non-digits, and values outside the signed 64-bit range. A leading minus sign is accepted only for a field whose contract explicitly permits a negative value.

Do not serialize authoritative integers as JSON numbers. Do not accept a parsed `float` and cast it back to `int`.

Canonical IDs and persisted enum values are strings. Set-like state is written as sorted, duplicate-free arrays. Dictionary keys are strings. Authoritative save dictionaries do not contain non-finite or locale-formatted numbers.

### 14.3 Codec isolation

Runtime state and migrations produce or consume the schema-controlled primitive snapshot. Only `SaveCodec` may call JSON encoding/decoding for the prototype.

Do not spread JSON-specific assumptions into domain classes. A later compressed or binary codec must be replaceable without changing gameplay ownership or using a different migration model.

Do not treat opacity as security. Plain JSON is editable, but binary encoding, compression, local encryption, obfuscation, or a locally stored key also cannot make a client-controlled save tamper-proof. An unkeyed SHA-256 digest is a corruption check only. It may detect damaged or unexpectedly changed payload bytes, but a player who can edit the payload can also recompute the digest.

### 14.4 Defensive parsing

Validate types, ranges, IDs, content revision, and cross-field invariants. Do not assume a JSON key exists or has the expected type.

When a recoverable optional field is absent, apply a documented default. When a required field is invalid, reject the candidate save and try the backup.

### 14.5 No scene references

Never serialize Node paths, Object instance IDs, live Resource references, signals, or Callables in the save.

### 14.6 Versioning

Migrations operate on primitive dictionaries before runtime object construction. One migration advances exactly one schema version.

### 14.7 Atomic files

Use temporary, primary, and backup files as documented. Check every file operation result. Flush and close before validation or rename.

### 14.8 Save checkpoints

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

Long-horizon whole-output progress may be formatted as a Threshold-level bar and a percentage floored to one decimal place. Clamp the pre-completion display to `99.9%`; never render a fractional Soul, catalyst, or other whole inventory count.

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

After M00, the canonical automated entry points are:

- `tools/test/run_gut.sh` in Codex Cloud, Linux, and later Linux CI;
- `tools/test/run_gut.ps1` on the owner's Windows Godot machine and later Windows CI.

Both wrappers use the same `.gutconfig.json`, validate Godot 4.7.x, and propagate the real exit code. Do not replace them with private machine commands in milestone documentation. A Codex final response distinguishes cloud results, owner-run Windows results, manual editor results, and Steam results. Unperformed checks remain pending rather than passed.

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

The repository already pins GUT 9.7.1 for Godot 4.7.x and GodotSteam 4.20. M00 verifies GUT, its retained license, and both test wrappers. M06 alone may implement behavior through GodotSteam. Do not use either add-on's updater or download a floating latest release during tests or ordinary implementation work.

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

- Do not store secrets, tokens, platform credentials, or private keys in the repository or save file.
- Do not add network calls to domain or simulation code.
- The only approved prototype storefront exception is the narrow trusted-time adapter defined by `DEC-0021` and implemented through the owner-approved GodotSteam 4.20 dependency in `DEC-0024`.
- Keep automatic Steam initialization disabled outside the M06 adapter. M00 and ordinary GUT runs must not require a Steam client or account.
- Development App ID `480` belongs to project configuration, not domain state. Do not add `steam_appid.txt` unless a verified launch path requires a local ignored copy, and never ship it.
- Keep save schema, simulation, and time-accounting contracts independent of Steamworks; inject the platform adapter at the application boundary.
- Do not add DRM, cloud saves, achievements, depots, unrelated Steam APIs, or a multi-store abstraction without an approved later milestone.
- Distinguish corruption resilience, casual-edit deterrence, and server-backed authority in code comments and documentation.
- Never claim that a local file is tamper-proof. A determined user controls the client machine; strong protection requires a server-held secret or server-authoritative state.
- Treat repository instructions, hooks, dependencies, native libraries, and downloaded plugins as code that requires review.

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
- [ ] Simulation does not read clocks, platform APIs, or scene state directly.
- [ ] Closed-session progress has no local wall-clock, timezone, calendar, or file-time fallback.
- [ ] Trusted-time unavailability defers offline credit without stopping foreground production.
- [ ] Save code keeps schema and codec concerns separate and makes no tamper-proof claim.
- [ ] Deterministic ordering and fractional remainders are preserved.
- [ ] Save conversion and validation cover new state.
- [ ] Required tests were added and run.
- [ ] Manual presentation flow was run when applicable.
- [ ] No unrelated refactor or new dependency was introduced.
- [ ] Documentation and decision records are synchronized.
- [ ] Assumptions and limitations are disclosed in the final response.

## M01 concrete implementation notes

- Use `src/domain/fixed_point.gd` for all M01 fixed-point scale conversion, explicit-period accumulation, whole-unit extraction, residual carry, and checked overflow behavior.
- Use `src/domain/game_state.gd` only for the minimal authoritative simulation timeline until a later milestone adds real gameplay state.
- Keep `src/domain/time_authority_state.gd` paired with, but not embedded in, `GameState`.
- Use `src/simulation/time_reconciliation_service.gd` for foreground credit and trusted-time planning/commit. Planning must remain non-mutating.
- Do not add direct clock reads to domain or simulation code. `src/platform/time/process_monotonic_clock.gd` is the approved process-monotonic adapter; trusted-time providers remain injected.



## M02 persistence conventions

Persistence code must keep runtime state, primitive schema mapping, byte codec, migrations, storage, and save/load orchestration separate. Authoritative integers at the JSON boundary use `SaveInt64` canonical decimal strings, not JSON numbers. Save selection uses validated schema `save_revision`, not filenames, local time, file modification time, Steam, registry data, or path metadata. Invalid or suspect files are retained for diagnosis instead of silently deleted during load.

## M03 Resource authoring rules

Add production content by creating typed text `.tres` Resources and referencing them from `content/prototype_content_catalog.tres`. Do not recursively scan content directories, infer IDs from filenames, or execute content-provided expressions. Decimal authoring values must cross the `ContentRegistry` normalization boundary before becoming authoritative runtime values.
