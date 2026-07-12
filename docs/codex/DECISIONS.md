# Death Idle Decision Record

**Document role:** Durable record of approved and proposed design and architecture decisions  
**Repository path:** `docs/codex/DECISIONS.md`  
**Document status:** Phase 6 proposal  
**Revision:** 1  
**Last updated:** 2026-07-12

## 1. How to use this file

A decision record explains why a choice exists and what it changes. The maintained design and architecture documents state the resulting current rule.

| Status | Meaning |
|---|---|
| **Proposed** | Recommended in the current planning phase but not yet approved by the project owner. |
| **Accepted** | Approved and currently authoritative. |
| **Superseded** | Replaced by a later linked decision and retained for history. |
| **Rejected** | Considered and deliberately not adopted. |
| **Experimental** | Approved for a bounded trial with an explicit review condition. |

Rules:

- Do not delete historical entries.
- A replacement entry names the decision it supersedes.
- Update the applicable source-of-truth, architecture, contracts, and tests when a decision changes behavior.
- Ordinary balance tuning does not require a decision entry unless it changes ownership, semantics, compatibility, or a protected invariant.
- Phase 6 proposals become Accepted only after explicit owner approval.

## 2. Index

| ID | Title | Status | Date |
|---|---|---|---|
| `DEC-0001` | Maintained Markdown and source precedence | Accepted | 2026-07-12 |
| `DEC-0002` | Emergency Writ transitions the same Reaping to Standard | Accepted | 2026-07-12 |
| `DEC-0003` | Separate 5,000 and 10,000 resonance events | Accepted | 2026-07-12 |
| `DEC-0004` | Scribe awakening remains a player action | Accepted | 2026-07-12 |
| `DEC-0005` | Scripted opening four are excluded from Reaping counters | Accepted | 2026-07-12 |
| `DEC-0006` | Godot, platform, and storefront boundary | Accepted | 2026-07-12 |
| `DEC-0007` | Authoritative state is scene-tree independent | Proposed | 2026-07-12 |
| `DEC-0008` | Persistent `GameApp` root without a gameplay autoload | Proposed | 2026-07-12 |
| `DEC-0009` | Typed Resource definitions in an explicit content catalog | Proposed | 2026-07-12 |
| `DEC-0010` | One deterministic global resolver and fixed-point numeric model | Proposed | 2026-07-12 |
| `DEC-0011` | Versioned JSON snapshot with exact integer strings and atomic replacement | Proposed | 2026-07-12 |
| `DEC-0012` | Commands mutate state; queries and events expose committed results | Proposed | 2026-07-12 |
| `DEC-0013` | One inventory total plus an explicit reservation ledger | Proposed | 2026-07-12 |
| `DEC-0014` | Small modifier and progression-effect grammars | Proposed | 2026-07-12 |
| `DEC-0015` | Tutorial orchestrates presentation and never executes skipped cost-bearing choices | Proposed | 2026-07-12 |
| `DEC-0016` | Reports store already-applied deltas; forecasts simulate a clone | Proposed | 2026-07-12 |
| `DEC-0017` | GUT 9.7.1 is the planned Godot 4.7 test framework | Proposed | 2026-07-12 |
| `DEC-0018` | Single-threaded prototype and local-only playtest telemetry | Proposed | 2026-07-12 |
| `DEC-0019` | Threshold knowledge, lifecycle, availability, and activity are orthogonal | Proposed | 2026-07-12 |
| `DEC-0020` | One active Reaping per Threshold and one tether per Reaping | Proposed | 2026-07-12 |

---

## `DEC-0001` — Maintained Markdown and source precedence

**Status:** Accepted  
**Date:** 2026-07-12  
**Decision type:** Project governance

### Context

The project began from two DOCX design sources and requires repeated Codex work. Later owner decisions may deliberately clarify or supersede ambiguous source wording.

### Decision

Use this precedence:

1. latest explicit owner instruction;
2. `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md` for prototype behavior;
3. `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md` for broader direction;
4. accepted records in this file;
5. existing repository behavior and maintained documentation;
6. implementation recommendations.

The Markdown source-of-truth files are Codex's normal operational sources. Archived DOCX files, when present, are provenance rather than routine implementation guidance.

### Consequences

- Conflicts are reported rather than silently resolved.
- Approved clarifications update the maintained Markdown.
- Routine Codex tasks do not depend on parsing binary documents.

### Affected documents

- `AGENTS.md`
- `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md`
- `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md`

---

## `DEC-0002` — Emergency Writ transitions the same Reaping to Standard

**Status:** Accepted  
**Date:** 2026-07-12  
**Decision type:** Prototype lifecycle

### Context

The detailed Beat Sheet could be read as ending the Emergency operation and dispatching a new persistent operation. That would teach the obsolete expedition lifecycle.

### Decision

At 1,000 post-dispatch Gloamwood Reaping returns, update the existing Reaping from `WRIT_EMERGENCY_FIRST_RETURN` to `WRIT_STANDARD`.

Do not stop the Reaping, free its tether, reset its Threshold, Form, Mastery, report accumulator, or simulation carry, or require another dispatch.

### Consequences

- The Writ change is a deterministic simulation boundary.
- Remaining elapsed time resolves under Standard behavior.
- Timing and presentation may be calibrated after playtesting without changing the persistence invariant.

### Affected documents

- `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md`
- `docs/codex/ARCHITECTURE.md`
- `docs/codex/TESTING_AND_VALIDATION.md`

---

## `DEC-0003` — Separate 5,000 and 10,000 resonance events

**Status:** Accepted  
**Date:** 2026-07-12  
**Decision type:** Prototype progression

### Context

Source shorthand sometimes summarized the prototype as containing one resonance, while detailed beats define a tether resonance at 5,000 and another progression event at 10,000.

### Decision

- At 5,000 post-dispatch Gloamwood Reaping returns plus Scribe awakened, record a minor first resonance, reveal or chart Broken Watch, and grant command tether 2.
- At 10,000 regional persistent-Reaping returns, record a distinct second resonance, grant its configured Essence reward, and expose the optional Recollection choice.

### Consequences

- Use separate milestone, resonance, event, report, and exactly-once IDs.
- Prototype end-state documentation refers to two resonance events.

### Affected documents

- `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`

---

## `DEC-0004` — Scribe awakening remains a player action

**Status:** Accepted  
**Date:** 2026-07-12  
**Decision type:** Tutorial behavior

### Context

One tutorial table could be read as automatically awakening Scribe, while the detailed beat requires the player to use the Soulweave and press **Awaken**.

### Decision

Guarantees secure or top up one Scribe Form Soul and the required Essence. The normal tutorial waits for the player to issue the ordinary Awaken command.

### Consequences

- Tutorial code cannot directly set Scribe to awakened.
- The Form service validates and consumes the normal cost.
- The player learns the Soulweave awakening interaction.

### Affected documents

- `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md`
- `docs/codex/ARCHITECTURE.md`

---

## `DEC-0005` — Scripted opening four are excluded from Reaping counters

**Status:** Accepted  
**Date:** 2026-07-12  
**Decision type:** Counter semantics

### Context

The scripted direct action reduces Gloamwood's backlog before persistent automation exists. The source did not state whether those four advance later Reaping milestones.

### Decision

The scripted four:

- reduce Gloamwood backlog from `1,000,000` to `999,996`;
- are recorded as scripted returns and backlog reduction;
- do not increment Threshold persistent-Reaping counters;
- do not increment regional persistent-Reaping counters;
- do not advance the 1,000, 2,500, 5,000, 10,000, or 25,000 milestones;
- never enter automated-Reaping totals; a later history or report surface may mention them only as a separately labelled scripted direct-action event.

Persistent-Reaping counters begin at zero when the first Reaping is dispatched.

### Consequences

- Backlog reduction and automated-return counters are intentionally different fields.
- Tests must prevent off-by-four milestone behavior.

### Affected documents

- `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`
- `docs/codex/TESTING_AND_VALIDATION.md`

---

## `DEC-0006` — Godot, platform, and storefront boundary

**Status:** Accepted  
**Date:** 2026-07-12  
**Decision type:** Technology and product boundary

### Context

The owner develops on Windows, uses Godot, intends a Steam-first commercial release, and may evaluate other stores only when justified by return on effort.

### Decision

- Use Godot 4.7 and GDScript only.
- Target Windows PC first.
- Use a 1920 × 1080 reference viewport with ordinary resizing and stretching.
- Keep authoritative simulation, saves, and content independent of Steamworks or any storefront SDK.
- Defer Steam integration, achievements, cloud saves, depots, DRM, release packaging, and speculative multi-store adapters beyond the prototype.

### Consequences

- No C#, .NET project, GDExtension, native library, or storefront dependency is part of the prototype architecture.
- Headless verification may run on Linux without changing game rules.

### Affected documents

- `AGENTS.md`
- `project.godot`
- `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md`

---

## `DEC-0007` — Authoritative state is scene-tree independent

**Status:** Proposed  
**Date:** 2026-07-12  
**Decision type:** State architecture

### Context

Offline resolution, forecasts, save/load, debug advancement, and headless tests must work without depending on whichever UI screen is instantiated.

### Decision

Represent authoritative gameplay state as a typed non-`Node` object graph, rooted at `GameState`, with explicit cloning, validation, and serialization.

Nodes own Godot lifecycle and presentation adapters. They are not the sole owners of gameplay facts.

### Consequences

- Screens can be rebuilt without changing production.
- Core services can run in headless tests.
- State classes require explicit contracts rather than incidental scene serialization.

### Alternatives considered

- **Scene-tree groups and per-node saves:** rejected because state lifetime would depend on instantiated scenes.
- **One untyped global dictionary:** rejected because ownership and junior readability would be weak.

### Affected documents

- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`

---

## `DEC-0008` — Persistent `GameApp` root without a gameplay autoload

**Status:** Proposed  
**Date:** 2026-07-12  
**Decision type:** Godot composition

### Context

The application needs persistent services while screens change, but a gameplay autoload would make authority globally reachable and easier to misuse.

### Decision

Use a persistent root `Control` scene named `GameApp`. It owns one `GameSession`, screen routing, HUD regions, overlays, and Godot lifecycle callbacks. Screens are replaced inside a host and receive explicit session or presenter references.

Do not add a gameplay autoload initially.

### Consequences

- Service lifetime is stable without implicit global access.
- Screens cannot gain authority by searching `/root`.
- Save, focus, and quit handling have one visible owner.
- A later autoload requires a separate accepted decision.

### Alternatives considered

- **One `GameSession` autoload:** workable, but rejected for the initial prototype because the persistent root already solves lifetime and explicit references make dependencies clearer.
- **Replace the main scene for every screen:** rejected because service continuity becomes fragile.

### Affected documents

- `docs/codex/ARCHITECTURE.md`
- `docs/codex/IMPLEMENTATION_RULES.md`

---

## `DEC-0009` — Typed Resource definitions in an explicit content catalog

**Status:** Proposed  
**Date:** 2026-07-12  
**Decision type:** Content architecture

### Context

Prototype values must remain editable and data-driven. Definitions benefit from Godot Inspector support, while mutable state must remain separate.

### Decision

Use typed custom Godot `Resource` definitions stored as text `.tres` files. One explicit `ContentCatalog` Resource references the definitions used by the build. `ContentRegistry` loads and validates the catalog, then creates immutable normalized runtime tables.

Do not discover authoritative content through recursive directory scanning, and do not mutate definition Resources during play.

### Consequences

- Content is editor-friendly and diffable.
- Saves reference definitions by canonical ID.
- Export behavior does not depend on directory enumeration.
- Editor-friendly decimal values can be normalized once into deterministic fixed-point runtime values.

### Alternatives considered

- **JSON for every definition:** possible, but weaker Godot editor integration and typing for this solo workflow.
- **Balance embedded in scenes:** rejected because it couples rules to presentation.

### Affected documents

- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`

---

## `DEC-0010` — One deterministic global resolver and fixed-point numeric model

**Status:** Proposed  
**Date:** 2026-07-12  
**Decision type:** Simulation and time

### Context

Reapings and Halls share Stores and can cross milestones, discovery changes, support transitions, and settlement during one elapsed interval. Independent timers or float-per-frame accumulation would create order and chunking differences.

### Decision

- Use one `SimulationEngine` to advance all active Reapings and Halls over a shared integer-millisecond interval.
- Segment at the earliest meaningful global state boundary.
- Use the same resolver and normalized content for live, offline, forecast, and debug modes; forecast runs on a deep clone.
- Use a monotonic clock for foreground elapsed time and a persisted UTC wall-clock timestamp for offline elapsed time.
- Use centralized 64-bit fixed-point arithmetic and persisted residuals for authoritative fractional progress.
- Use stable same-time ordering and sorted canonical IDs.
- Do not use authoritative randomness in the first-session prototype.

### Consequences

- Online/offline/forecast equivalence is directly testable.
- A Larder completion and support depletion at the same timestamp have one documented order.
- The exact fixed-point scale remains a foundation-milestone choice, but it cannot differ by subsystem.
- Simulation services receive elapsed durations and do not read clocks, scene state, or frame delta directly.

### Alternatives considered

- **One timer per Reaping/Hall:** rejected because shared Stores make results order-dependent.
- **Replay every elapsed second:** rejected because long absences should resolve analytically.
- **Ordinary float accumulation without saved residuals:** rejected because chunking can change results.

### Affected documents

- `docs/codex/ARCHITECTURE.md`
- `docs/codex/IMPLEMENTATION_RULES.md`
- `docs/codex/TESTING_AND_VALIDATION.md`

---

## `DEC-0011` — Versioned JSON snapshot with exact integer strings and atomic replacement

**Status:** Proposed  
**Date:** 2026-07-12  
**Decision type:** Persistence

### Context

Save integrity and offline idempotency are foundational. Godot JSON converts numerical Variant values to JSON numbers/floats, so directly encoding 64-bit counters, fixed-point values, residuals, revisions, or timestamps would not provide a reliable exact-integer contract.

### Decision

Use a custom versioned JSON snapshot under `user://saves/` with:

- explicit state-to-dictionary conversion;
- canonical base-10 strings for every schema field typed as an authoritative integer;
- canonical ID strings and sorted arrays for set-like state;
- temporary-file write, reopen, parse, and full validation;
- previous valid primary retained as backup;
- highest-valid-revision load selection;
- sequential dictionary migrations;
- working-clone offline resolution followed by atomic commit.

### Consequences

- The save remains human-readable and exact.
- The codec must validate integer strings and 64-bit ranges.
- Schema changes require migrations or an explicit prototype reset decision.
- File replacement behavior must be tested on Windows and the Linux headless environment.

### Alternatives considered

- **Direct `JSON.stringify()` of runtime integers:** rejected because JSON number conversion does not preserve the intended integer type contract.
- **Scene or Resource serialization:** rejected because mutable state would be coupled to Godot objects and migrations.
- **Opaque binary-only saves:** viable later, but less inspectable for the prototype and unnecessary if the explicit JSON codec remains small.
- **Event sourcing:** rejected as excessive.

### Affected documents

- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`
- `docs/codex/TESTING_AND_VALIDATION.md`

---

## `DEC-0012` — Commands mutate state; queries and events expose committed results

**Status:** Proposed  
**Date:** 2026-07-12  
**Decision type:** Application flow

### Context

UI and tutorial code need to request actions and react to changes without partially mutating state or duplicating rules.

### Decision

- Player and scripted actions enter through explicit application commands.
- Commands resolve elapsed time, validate fully, mutate through owning services, run progression evaluation, request required saves, and publish one coherent state-change summary.
- Presentation reads immutable snapshots or view models.
- Domain events describe committed facts for reports, tutorial evaluation, diagnostics, and tests.
- The save remains a state snapshot; domain events are not an event-sourcing log.

### Consequences

- Invalid actions fail without partial cost consumption.
- UI cannot observe half-applied state.
- Junior reviewers can trace who owns each mutation.

### Affected documents

- `docs/codex/ARCHITECTURE.md`
- `docs/codex/IMPLEMENTATION_RULES.md`

---

## `DEC-0013` — One inventory total plus an explicit reservation ledger

**Status:** Proposed  
**Date:** 2026-07-12  
**Decision type:** Inventory and Retinues

### Context

Calling Souls remain owned while assigned. Moving them to an unrelated hidden bucket or consuming them would contradict the Retinue model and complicate guarantees.

### Decision

Store one owned total per item or Soul ID. Store reservations as ledger records with stable owner and purpose identities. Derive availability as owned minus active reservations.

Soldier Company creates and releases a twelve-Soldier reservation; it does not consume those Souls.

### Consequences

- Spending checks available quantity.
- Reservation ownership is diagnosable.
- Save validation ensures reservations do not exceed owned totals.
- Tutorial cost protection can use the same reservation grammar without duplicating inventory.

### Affected documents

- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`

---

## `DEC-0014` — Small modifier and progression-effect grammars

**Status:** Proposed  
**Date:** 2026-07-12  
**Decision type:** Data-driven rules

### Context

Forms, Traits, Retinues, Recollections, Writs, milestones, and guarantees need data-driven behavior, but an arbitrary expression or scripting engine would be excessive and difficult to validate.

### Decision

Use:

- a finite modifier grammar for approved metrics, conditions, and operations;
- a finite progression-effect grammar for grants, top-ups, reservations, unlocks, tether changes, resonance IDs, Writ transitions, world flags, and presentation events.

Do not store arbitrary Callables, expression strings, or script execution paths in content definitions.

### Consequences

- Modifier evaluation produces a trace for forecast explanations.
- Adding a new metric or effect is a reviewed contract change.
- Man-at-Arms and Scribe remain data-driven without a launch-scale rules engine.

### Affected documents

- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`
- `docs/codex/IMPLEMENTATION_RULES.md`

---

## `DEC-0015` — Tutorial orchestrates presentation and never executes skipped cost-bearing choices

**Status:** Proposed  
**Date:** 2026-07-12  
**Decision type:** Tutorial architecture

### Context

Tutorial progression must be resumable and cannot become a duplicate implementation of inventory, Reaping, Form, Hall, or unlock rules. The source says skipped mechanical guidance becomes a Help entry but does not clearly authorize silently performing the underlying choice.

### Decision

`TutorialCoordinator` observes authoritative conditions, controls tutorial presentation, requests approved guarantees, and invokes normal domain commands only for explicit scripted world-state transitions.

Skipping mechanical guidance dismisses the instructional presentation and creates or updates a Help entry. It does not silently execute a cost-bearing or strategic player choice. In particular, Scribe remains unawakened until the player issues Awaken.

### Consequences

- Tutorial and non-tutorial actions use the same rules.
- Early completion and save/load recovery are testable.
- A player who skips guidance may need to act without arrows, but cannot be charged or assigned silently.
- Pending notices are reconstructed from saved state rather than transient queues.

### Alternatives considered

- **Auto-execute the action on skip:** rejected as the default because it would make strategic and cost-bearing choices without explicit player input.
- **Tutorial directly edits state:** rejected because it duplicates authority.

### Affected documents

- `docs/codex/ARCHITECTURE.md`
- `docs/codex/TESTING_AND_VALIDATION.md`

---

## `DEC-0016` — Reports store already-applied deltas; forecasts simulate a clone

**Status:** Proposed  
**Date:** 2026-07-12  
**Decision type:** Reports and forecasts

### Context

Reports need a review moment without reintroducing claim-gated output, and forecasts must not maintain a second formula.

### Decision

- Simulation applies gains immediately and appends explanatory deltas/events to a report accumulator.
- Opening a report snapshots the accumulator into bounded history and clears only the live presentation accumulator.
- Forecasting deep-clones authoritative state, optionally applies a hypothetical command to the clone, and runs the same simulation engine without saves or commits.

### Consequences

- Inventory never depends on report interaction.
- Report archival is save-safe.
- Before/after comparisons and actual progression share the same rules.

### Affected documents

- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`

---

## `DEC-0017` — GUT 9.7.1 is the planned Godot 4.7 test framework

**Status:** Proposed  
**Date:** 2026-07-12  
**Decision type:** Test tooling

### Context

The repository has no automated harness. The prototype needs GDScript unit and integration tests that run locally and headlessly in Codex Cloud.

### Decision

Plan to vendor the version-pinned GUT 9.7.1 `addons/gut` directory during M00, retain its MIT license, and use its CLI with a checked-in configuration.

M00 must verify actual execution under Godot 4.7 on Windows and the Codex Cloud Linux environment before later milestones rely on it.

### Consequences

- No floating test dependency version.
- GUT remains a test-only dependency.
- Phase 6 documentation does not install the addon.

### Alternatives considered

- **Custom test framework:** rejected because it would recreate discovery, assertions, exit codes, filtering, and reports without improving the game.
- **No automated harness:** rejected because deterministic simulation and persistence require regression tests.

### Affected documents

- `docs/codex/TESTING_AND_VALIDATION.md`
- future M00 prompt and pull request

---

## `DEC-0018` — Single-threaded prototype and local-only playtest telemetry

**Status:** Proposed  
**Date:** 2026-07-12  
**Decision type:** Scope and diagnostics

### Context

Two Reapings, one Hall, tutorial progression, UI, and report aggregation do not justify concurrency or a telemetry backend. Threads would complicate deterministic order and junior review.

### Decision

- Resolve authoritative gameplay on one thread.
- Use ordinary typed GDScript objects and explicit composition; do not add an ECS, event-sourcing framework, or dependency-injection framework.
- Implement playtest event capture behind a local/null sink only when the telemetry milestone requires it.
- Do not add network analytics, accounts, or backend services.

### Consequences

- Optimize analytical resolution before considering threads.
- Debug or playtest logs can be exported manually without becoming a production service.
- A network telemetry provider requires a later privacy, security, and product decision.

### Affected documents

- `docs/codex/ARCHITECTURE.md`
- `docs/codex/IMPLEMENTATION_RULES.md`

---

## `DEC-0019` — Threshold knowledge, lifecycle, availability, and activity are orthogonal

**Status:** Proposed  
**Date:** 2026-07-12  
**Decision type:** Domain modeling

### Context

The source presents composite labels such as `Active - Overdue` and `Inactive - Settled`. A single enum containing every combination would become brittle as discovery and later Threshold types expand.

### Decision

Track separately:

- knowledge/reveal state;
- availability or lock conditions;
- Overdue versus Settled lifecycle;
- active Reaping reference;
- per-channel discovery state.

Presentation composes those facts into player-facing labels.

### Consequences

- Impossible combinations are easier to validate.
- Settled activity does not require a new monolithic state enum.
- Later Frayed/Anchored concepts can be added without rewriting knowledge progression.

### Affected documents

- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`

---

## `DEC-0020` — One active Reaping per Threshold and one tether per Reaping

**Status:** Proposed  
**Date:** 2026-07-12  
**Decision type:** Prototype capacity model

### Context

The prototype requires two concurrent Reapings and limited command capacity, but it does not require multiple simultaneous operations through the same Threshold.

### Decision

For the prototype:

- a Threshold can have at most one active Reaping;
- each active Reaping occupies exactly one command tether;
- occupied tether count is derived from active Reapings;
- reassignment changes the existing operation after resolving to the command time.

### Consequences

- Reapings can be keyed by Threshold ID.
- Capacity validation is simple and deterministic.
- Multiple Reapings at one Threshold, split tethers, or partial-capacity operations require a later decision.

### Affected documents

- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`

---

## 3. Approval action

When the project owner approves Phase 6:

1. change `DEC-0007` through `DEC-0020` from **Proposed** to **Accepted**, except any specifically revised or rejected entry;
2. change the Phase 6 architecture documents from draft/proposal to approved status;
3. record the approval date or revision;
4. do not change decision IDs when only wording is clarified.

