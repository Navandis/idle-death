# Death Idle Decision Record

**Document role:** Durable record of approved and proposed design and architecture decisions  
**Repository path:** `docs/codex/DECISIONS.md`  
**Document status:** Approved architecture and active decision record  
**Revision:** 13  
**Last updated:** 2026-07-16

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
- Architecture proposals become Accepted only after explicit owner approval. Phase 6 approval was recorded on 12 July 2026.

## 2. Index

| ID | Title | Status | Date |
|---|---|---|---|
| `DEC-0001` | Maintained Markdown and source precedence | Accepted | 2026-07-12 |
| `DEC-0002` | Emergency Writ transitions the same Reaping to Standard | Accepted | 2026-07-12 |
| `DEC-0003` | Separate 5,000 and 10,000 resonance events | Accepted | 2026-07-12 |
| `DEC-0004` | Scribe awakening remains a player action | Accepted | 2026-07-12 |
| `DEC-0005` | Scripted opening four are excluded from Reaping counters | Accepted | 2026-07-12 |
| `DEC-0006` | Godot, platform, and storefront boundary | Accepted | 2026-07-12 |
| `DEC-0007` | Authoritative state is scene-tree independent | Accepted | 2026-07-12 |
| `DEC-0008` | Persistent `GameApp` root without a gameplay autoload | Accepted | 2026-07-12 |
| `DEC-0009` | Typed Resource definitions in an explicit content catalog | Accepted | 2026-07-12 |
| `DEC-0010` | One deterministic global resolver and fixed-point numeric model | Accepted | 2026-07-12 |
| `DEC-0011` | Codec-independent versioned snapshot with JSON as the prototype codec | Accepted | 2026-07-12 |
| `DEC-0012` | Commands mutate state; queries and events expose committed results | Accepted | 2026-07-12 |
| `DEC-0013` | One inventory total plus an explicit reservation ledger | Accepted | 2026-07-12 |
| `DEC-0014` | Small modifier and progression-effect grammars | Accepted | 2026-07-12 |
| `DEC-0015` | Tutorial orchestrates presentation and never executes skipped cost-bearing choices | Accepted | 2026-07-12 |
| `DEC-0016` | Reports store already-applied deltas; forecasts simulate a clone | Accepted | 2026-07-12 |
| `DEC-0017` | GUT 9.7.1 is the pinned Godot 4.7 test framework | Accepted | 2026-07-12 |
| `DEC-0018` | Single-threaded prototype and local-only playtest telemetry | Accepted | 2026-07-12 |
| `DEC-0019` | Threshold knowledge, lifecycle, availability, and activity are orthogonal | Accepted | 2026-07-12 |
| `DEC-0020` | One active Reaping per Threshold and one tether per Reaping | Accepted | 2026-07-12 |
| `DEC-0021` | Trusted external time governs closed-session progress | Accepted | 2026-07-12 |
| `DEC-0022` | Prototype save resilience and release-format security gate | Accepted | 2026-07-12 |
| `DEC-0023` | Required Linux and Windows test wrappers with split execution responsibility | Accepted | 2026-07-12 |
| `DEC-0024` | GodotSteam 4.20 and project-setting App ID 480 are the approved prototype bridge | Accepted | 2026-07-12 |
| `DEC-0025` | Milestone-specific owner verification packages and generated logs | Accepted | 2026-07-13 |
| `DEC-0026` | Six-decimal fixed-point scale, unscaled discrete counts, and checked period accumulation | Accepted | 2026-07-14 |
| `DEC-0027` | Threshold-owned long-horizon acquisition progress survives Reaping reconfiguration | Accepted | 2026-07-14 |
| `DEC-0028` | Rare-output progress is normalized work; rate changes are prospective and non-compounding | Accepted | 2026-07-14 |
| `DEC-0029` | Explicit content revisions govern save compatibility | Accepted | 2026-07-14 |
| `DEC-0030` | Output channels are first-class catalog definitions with stable `CHANNEL_...` IDs | Accepted | 2026-07-14 |
| `DEC-0031` | Stable canonical IDs and mutable player-facing language | Accepted | 2026-07-14 |
| `DEC-0032` | Essence is the sole resource term and canonical ID | Accepted | 2026-07-14 |
| `DEC-0033` | Rolling-wave implementation slices and review-surface guardrails | Accepted | 2026-07-15 |
| `DEC-0034` | Schema version 2 and sequential migration are the gameplay-state compatibility path | Accepted | 2026-07-15 |
| `DEC-0035` | Reaping operations are Threshold-scoped; recalled records persist and assignment commands are revision-guarded and Form-exclusive | Accepted | 2026-07-16 |

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
- Keep authoritative simulation, save-schema meaning, and content independent of Steamworks or any storefront SDK.
- Defer achievements, cloud saves, depots, DRM, release packaging, and speculative multi-store adapters beyond the prototype. A narrowly scoped trusted-time platform adapter is the only currently approved exception and is governed by `DEC-0021`.

### Consequences

- No C#, .NET project, or unrelated storefront dependency is part of the prototype architecture. A Godot-to-Steam binding may be added only by the approved trusted-time milestone after the exact dependency is reviewed.
- Headless verification may run on Linux without changing game rules.

### Affected documents

- `AGENTS.md`
- `project.godot`
- `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md`

---

## `DEC-0007` — Authoritative state is scene-tree independent

**Status:** Accepted  
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

**Status:** Accepted  
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

**Status:** Accepted  
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

**Status:** Accepted  
**Date:** 2026-07-12  
**Decision type:** Simulation and time

### Context

Reapings and Halls share Stores and can cross milestones, discovery changes, support transitions, and settlement during one elapsed interval. Independent timers or float-per-frame accumulation would create order and chunking differences. Closed-session progress also requires a time source whose trust policy is separate from simulation.

### Decision

- Use one `SimulationEngine` to advance all active Reapings and Halls over a shared integer-millisecond interval.
- Segment at the earliest meaningful global state boundary.
- Use the same resolver and normalized content for live, offline, forecast, and debug modes; forecast runs on a deep clone.
- Use a monotonic process clock for foreground elapsed time.
- Obtain closed-session elapsed time only through the trusted-time policy in `DEC-0021`; the simulation engine receives a duration and never reads a clock.
- Use centralized 64-bit fixed-point arithmetic and persisted residuals for authoritative fractional progress.
- Use stable same-time ordering and sorted canonical IDs.
- Do not use authoritative randomness in the first-session prototype.

### Consequences

- Online/offline/forecast equivalence is directly testable.
- A Larder completion and support depletion at the same timestamp have one documented order.
- The exact fixed-point scale remains a foundation-milestone choice, but it cannot differ by subsystem.
- Simulation services receive elapsed durations and do not read clocks, scene state, frame delta, Steam APIs, or device wall time directly.

### Alternatives considered

- **One timer per Reaping/Hall:** rejected because shared Stores make results order-dependent.
- **Replay every elapsed second:** rejected because long absences should resolve analytically.
- **Ordinary float accumulation without saved residuals:** rejected because chunking can change results.
- **Device wall clock for offline elapsed:** rejected because players, operating-system changes, time synchronization, timezone changes, or clock faults can alter it.

### Affected documents

- `docs/codex/ARCHITECTURE.md`
- `docs/codex/IMPLEMENTATION_RULES.md`
- `docs/codex/TESTING_AND_VALIDATION.md`

---

## `DEC-0011` — Codec-independent versioned snapshot with JSON as the prototype codec

**Status:** Accepted  
**Date:** 2026-07-12  
**Decision type:** Persistence

### Context

Save integrity and offline idempotency are foundational. Godot JSON converts numerical Variant values to JSON numbers/floats, so directly encoding 64-bit counters, fixed-point values, residuals, revisions, or trusted-time fields would not provide a reliable exact-integer contract. At the same time, choosing JSON for inspectability during the prototype must not permanently couple the full game to a text wire format.

### Decision

Define a schema-controlled snapshot model and a project-owned `SaveCodec` boundary. The prototype implementation uses a custom versioned JSON codec under `user://saves/` with:

- explicit state-to-dictionary conversion;
- canonical base-10 strings for every schema field typed as an authoritative integer;
- canonical ID strings and sorted arrays for set-like state;
- temporary-file write, reopen, parse, and full validation;
- previous valid primary retained as backup;
- highest-valid-revision load selection;
- sequential dictionary migrations;
- working-clone offline resolution followed by atomic commit.

The runtime schema, migrations, validation, and storage transaction must not depend on JSON-specific code outside the codec. A later compressed or binary codec may replace JSON after profiling without changing domain ownership or the conceptual save schema.

### Consequences

- The prototype save remains human-readable, exact, and easy to diagnose.
- The JSON codec must validate integer strings and signed-64-bit ranges.
- Schema changes require migrations or an explicit prototype reset decision.
- File replacement behavior must be tested on Windows and the Linux headless environment.
- JSON is not approved as an anti-tamper mechanism, and binary encoding alone would not improve the trust boundary.
- Commercial-release codec and integrity policy are reviewed at the gate defined by `DEC-0022`.

### Alternatives considered

- **Direct `JSON.stringify()` of runtime integers:** rejected because JSON number conversion does not preserve the intended integer type contract.
- **Scene or Resource serialization:** rejected because mutable state would be coupled to Godot objects and migrations.
- **Commit to opaque binary saves now:** rejected because no measured size or performance problem exists and binary representation would reduce prototype diagnosability without making local saves tamper-proof.
- **Event sourcing:** rejected as excessive.

### Affected documents

- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`
- `docs/codex/TESTING_AND_VALIDATION.md`

---

## `DEC-0012` — Commands mutate state; queries and events expose committed results

**Status:** Accepted  
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

**Status:** Accepted  
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

**Status:** Accepted  
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

**Status:** Accepted  
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

**Status:** Accepted  
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

## `DEC-0017` — GUT 9.7.1 is the pinned Godot 4.7 test framework

**Status:** Accepted  
**Date:** 2026-07-12  
**Decision type:** Test tooling

### Context

The prototype needs GDScript unit and integration tests that run locally and headlessly in Codex Cloud. The project owner has now committed GUT 9.7.1 under `addons/gut/`.

### Decision

Use the repository-pinned GUT 9.7.1 CLI with a checked-in configuration. M00 does not download or replace the dependency; it verifies the committed version and retained license, creates the project harness and wrappers, and proves execution under Godot 4.7 in both the Codex Cloud Linux environment and the owner's Windows Godot environment.

### Consequences

- No floating test dependency version or test-time network download.
- GUT remains a test-only dependency.
- Updating or replacing GUT requires explicit scope and re-validation of both wrappers.
- Later milestones may treat the canonical commands as mandatory only after M00 passes `GATE-GUT`.

### Alternatives considered

- **Custom test framework:** rejected because it would recreate discovery, assertions, exit codes, filtering, and reports without improving the game.
- **No automated harness:** rejected because deterministic simulation and persistence require regression tests.

### Affected documents

- `docs/codex/TESTING_AND_VALIDATION.md`
- `docs/codex/MILESTONES.md`
- future M00 prompt and pull request

---

## `DEC-0018` — Single-threaded prototype and local-only playtest telemetry

**Status:** Accepted  
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

**Status:** Accepted  
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

**Status:** Accepted  
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

## `DEC-0021` — Trusted external time governs closed-session progress

**Status:** Accepted  
**Date:** 2026-07-12  
**Decision type:** Time authority and platform boundary  
**Refines:** `DEC-0006`, `DEC-0010`

### Context

The project owner requires authoritative progress to be independent of the player's local calendar, timezone, and device wall clock. Foreground production can use a monotonic process clock, but the application cannot know how long it was closed without an external trusted reference. The initial commercial target is Steam, whose utility API exposes Steam server time.

### Decision

- Foreground elapsed time uses an injected monotonic process clock and is credited immediately.
- Closed-session elapsed time uses an injected `TrustedTimeProvider`; no authoritative code may fall back to the device wall clock.
- The planned Steam production adapter obtains server time through `ISteamUtils::GetServerRealTime`; the approved binding must also define the connection/session checks that make a sample acceptable.
- If trusted time is unavailable, load the save without closed-session credit, mark the gap pending, and continue foreground production normally.
- Persist the last trusted anchor and the amount of foreground monotonic time already credited since that anchor. When trusted time later becomes available, subtract already-credited foreground time before resolving the remaining closed-session gap, then apply any configured offline cap.
- Never move the trusted anchor backwards. A negative, stale, contradictory, or implausible sample grants no progress and produces a diagnostic event.
- The Steam adapter remains at the platform/application boundary. Domain, simulation, save-schema meaning, and tests depend only on the project-owned interface.
- The approved Godot-to-Steam binding is recorded in `DEC-0024`. Replacing or upgrading that GDExtension or its repository footprint requires new owner approval.

### Consequences

- Changing Windows date, time, timezone, daylight-saving settings, or clock synchronization does not create or remove offline production.
- A player may continue playing without trusted time, but pending closed-session progress is not granted until a trusted sample is available.
- Headless tests use a fake trusted-time source and require no Steam client.
- This prevents ordinary local-clock abuse and accidental clock faults. It does not make a fully client-side single-player executable secure against a determined user who patches the process or spoofs platform calls; strong resistance to that threat requires a server-controlled authority.
- This is the sole currently approved prototype exception to the broader Steam-integration deferral in `DEC-0006`.

### Alternatives considered

- **Local UTC wall clock with rollback detection:** rejected because forward jumps remain exploitable and legitimate synchronization can create false behavior.
- **No offline progress:** secure against clock changes but contradicts the core product promise.
- **Always-online custom backend:** stronger authority, but disproportionate for the prototype and solo-development scope.
- **Signed local timestamps only:** cannot prove elapsed closed time without a trusted signer available after the interval.

### Affected documents

- `AGENTS.md`
- `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md`
- `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md`
- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`
- `docs/codex/IMPLEMENTATION_RULES.md`
- `docs/codex/TESTING_AND_VALIDATION.md`
- `docs/codex/MILESTONES.md`

---

## `DEC-0022` — Prototype save resilience and release-format security gate

**Status:** Accepted  
**Date:** 2026-07-12  
**Decision type:** Persistence security and release planning  
**Refines:** `DEC-0011`

### Context

The prototype needs exact, recoverable saves and easy diagnostics. The full game may eventually have larger state, Steam Cloud synchronization, achievements, or other incentives to edit saves. Plain JSON is readable and editable, but replacing it with an opaque binary file does not by itself create security because the game client must still contain every local decoding and validation rule.

### Decision

For the prototype:

- prioritize schema validation, exact numeric round trips, atomic replacement, backup recovery, migration fixtures, and idempotent offline transactions;
- keep JSON behind `SaveCodec` and do not add encryption or obfuscation solely to create an appearance of security;
- an optional unkeyed digest may detect accidental corruption but must not be described as tamper protection.

Before commercial release, run the dedicated `RG01` save-format and threat-model gate that:

1. profiles realistic worst-case save size, parse time, write time, memory use, and Steam Cloud transfer behavior;
2. decides whether JSON remains sufficient or whether a compressed or binary codec is justified;
3. states whether the product only needs corruption resilience, also wants casual-edit deterrence, or requires server-backed authority for protected outcomes;
4. treats local encryption, obfuscation, or a locally stored HMAC key as deterrence only;
5. requires a server-held signing key or server-authoritative state for any outcome that must be strongly protected from a determined client owner.

### Consequences

- JSON is sufficient for the prototype and may also be sufficient for the full game if aggregate saves remain small and profiling meets release budgets.
- The project can change the wire codec without rewriting domain state or migrations.
- Steam Cloud may synchronize save files later, but synchronization is not integrity verification.
- No milestone may claim that a local save is tamper-proof.
- Achievement, leaderboard, economy, or other protected-state policy remains a later product decision rather than an accidental property of the file extension.

### Alternatives considered

- **Encrypt JSON immediately:** rejected as prototype scope with weak protection when the key is shipped in the client.
- **Use binary solely to hide values:** rejected as security through obscurity.
- **Add a backend now:** rejected as unnecessary for the current single-player prototype.

### Affected documents

- `AGENTS.md`
- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`
- `docs/codex/IMPLEMENTATION_RULES.md`
- `docs/codex/TESTING_AND_VALIDATION.md`
- `docs/codex/MILESTONES.md`

---

## `DEC-0023` — Required Linux and Windows test wrappers with split execution responsibility

**Status:** Accepted  
**Date:** 2026-07-12  
**Decision type:** Test execution and review workflow  
**Refines:** `DEC-0017`

### Context

Codex Cloud runs in a Linux environment, while the Godot editor is installed on a separate Windows machine. Git synchronizes repository changes between them, but it does not allow Codex to execute commands on the Windows machine. The project needs one test contract without requiring Codex App or CLI on the Godot machine.

### Decision

M00 creates and maintains both:

- `tools/test/run_gut.sh` for Codex Cloud, Linux, and later Linux CI;
- `tools/test/run_gut.ps1` for the owner's Windows Godot machine and later Windows CI.

Both wrappers:

- resolve the repository root from their own location;
- locate Godot through an explicit argument, then `GODOT_BIN`, then a documented executable on `PATH`;
- require Godot 4.7.x;
- use the same checked-in `.gutconfig.json` and test directories;
- run the default clean import and full GUT suite unless a documented focused mode is requested;
- forward the real process exit code;
- contain no committed machine-specific path.

Codex runs the shell wrapper in its environment. The owner pulls the branch and runs the PowerShell wrapper on the Windows Godot machine. Windows, visual, editor, and Steam checks are reported separately. A pull request may be opened while a Windows check is pending, but no task may report that check as passed until the owner actually runs it, and a milestone-defined Windows merge gate must pass before merge.

### Consequences

- Codex does not need to be installed on the Windows Godot machine.
- The owner normally executes one repository command for automated Windows validation, then the milestone's manual editor checklist.
- Wrapper defects are fixed in the branch rather than patched privately on one machine.
- Git remains the transfer mechanism, not a remote execution channel.

### Affected documents

- `AGENTS.md`
- `docs/codex/IMPLEMENTATION_RULES.md`
- `docs/codex/TESTING_AND_VALIDATION.md`
- `docs/codex/MILESTONES.md`

---

## `DEC-0024` — GodotSteam 4.20 and project-setting App ID 480 are the approved prototype bridge

**Status:** Accepted  
**Date:** 2026-07-12  
**Decision type:** Platform dependency and development configuration  
**Refines:** `DEC-0006`, `DEC-0021`

### Context

The project owner committed GodotSteam GDExtension 4.20 under `addons/godotsteam/` and configured development App ID `480` in `project.godot`. The project setting disables automatic Steam initialization. This resolves the previously open choice of Godot-to-Steam bridge for the prototype.

### Decision

- Use the pinned GodotSteam 4.20 GDExtension as the sole prototype Steam bridge.
- Use App ID `480` for internal development and technical smoke tests until Death Idle receives its own App ID.
- Keep automatic Steam initialization disabled. M06 initializes Steam explicitly inside the platform adapter and uses no Steam feature beyond the trusted-time contract.
- M00 verifies that the project imports and tests headlessly with the extension present and Steam uninitialized.
- M06 verifies the pinned wrapper API and maps it to live-connection semantics equivalent to `ISteamUser::BLoggedOn()` and server-time semantics equivalent to `ISteamUtils::GetServerRealTime()`.
- Do not add `steam_appid.txt` by default. Add one only when a specific verified launch path requires it; keep it local or ignored and exclude it from shipped builds.
- Updating, replacing, or auto-updating GodotSteam requires explicit owner approval, license/footprint review, and Windows plus headless re-validation.

### Consequences

- `GATE-STEAM-TIME` is satisfied for M06 prompt drafting with GodotSteam 4.20 as the selected dependency.
- Live Steam testing remains a Windows responsibility; cloud tests use fakes and must not require a Steam client or account.
- App ID `480` proves bridge behavior only. Death Idle's own App ID, package ownership, launch-through-Steam behavior, and external distribution remain later validation.
- The addon remains isolated from domain, simulation, save-schema meaning, and non-Steam tests.

### Affected documents

- `AGENTS.md`
- `project.godot`
- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`
- `docs/codex/IMPLEMENTATION_RULES.md`
- `docs/codex/TESTING_AND_VALIDATION.md`
- `docs/codex/MILESTONES.md`

---

## `DEC-0025` — Milestone-specific owner verification packages and generated logs

**Status:** Accepted  
**Date:** 2026-07-13  
**Decision type:** Test execution and evidence workflow  
**Refines:** `DEC-0023`

### Context

Codex Cloud cannot execute commands or perform editor, visual, audio, Windows-specific, or live Steam checks on the project owner's separate Godot machine. M00 verification showed that long copy/paste command sequences are error-prone and that a generated execution log is more useful evidence than an informal summary alone. The owner requested future manual and Windows checks to be supplied as ready-to-run files, preferably a script that records its output.

### Decision

For each milestone with owner-run checks:

- the planning prompt must define the exact owner verification package;
- when checks are safely automatable, Codex creates a milestone-specific PowerShell script under `tools/test/owner/`;
- the script invokes the canonical project wrappers and only the additional checks required by that milestone;
- the script writes one UTF-8 execution log under the Git-ignored `tools/test/owner/logs/` directory;
- the script records the tested milestone, requested PR head or commit, detected commit when Git is available, tool versions, commands, exit codes, cleanup result, and final pass/fail summary;
- Git CLI is optional on the Windows machine; the owner may provide the PR head through a script parameter;
- temporary failure, corruption, migration, or save fixtures created by the script must be removed and their removal verified before success;
- a clean regression suite runs after any intentional-failure test;
- visual, editor, audio, A/B, and live Steam observations remain an explicit owner checklist and are never auto-marked as passed;
- when a script would add no value or cannot safely drive the required tool, provide a repository-tracked `.md` or `.txt` command/checklist file instead and state why;
- generated logs are uploaded as evidence when useful but are not committed.

The canonical format and path rules are maintained in `docs/codex/OWNER_VERIFICATION_WORKFLOW.md`.

### Consequences

- The owner normally runs one PowerShell entry point rather than reconstructing milestone commands from chat.
- Test evidence is reproducible and easier to review, while machine-specific paths remain outside committed configuration.
- Future prompts must budget the verification script or checklist as part of the milestone, not as post-implementation improvisation.
- Interactive judgment remains human-owned; a log cannot prove an unperformed visual or Steam check.
- No automatic upload, credential collection, or network transmission is authorized.

### Affected documents

- `AGENTS.md`
- `.gitignore`
- `docs/codex/OWNER_VERIFICATION_WORKFLOW.md`
- `docs/codex/PROMPT_TEMPLATE.md`
- `docs/codex/TESTING_AND_VALIDATION.md`
- `docs/codex/MILESTONES.md`


---


## `DEC-0026` — Six-decimal fixed-point scale, unscaled discrete counts, and checked period accumulation

**Status:** Accepted  
**Date:** 2026-07-14  
**Decision type:** Numeric representation  
**Refines:** `DEC-0010`

### Context

M01 must choose one exact fixed-point scale before production rates, Mastery, discovery, support, forecasts, and save residuals depend on it. The same numeric model must support very large campaign counters and small inventories without forcing whole objects such as Souls, catalysts, or Rations to become fractional inventory. It must also represent long-horizon deterministic sources that may take eight to twenty-four hours to produce one whole item.

### Decision

- Use `FixedPoint.SCALE = 1_000_000` subunits per whole unit.
- Represent `1.0` as `1_000_000`; for example, `0.15` is `150_000` and a `1.15` multiplier is `1_150_000`.
- Keep inherently discrete authoritative counts as ordinary unscaled signed 64-bit integers. This includes backlog, owned and reserved whole Souls, whole resources and Stores, command tethers, completed cycles, milestones, and other countable objects.
- Use the fixed-point scale only where fractional state is meaningful: rates, multipliers, Mastery, discovery, familiarity, support consumption, forecasts, acquisition progress toward the next whole unit, and arithmetic residuals.
- A deterministic rate is represented with an explicit period, such as `rate_subunits_per_period` plus `period_msec`; systems must not assume every rate can be rounded safely to integer subunits per second.
- Central fixed-point operations use deterministic floor semantics and return any unproduced numerator as an explicit remainder with a documented denominator and one owner.
- Whole-unit extraction is exact: transfer `progress_subunits / SCALE` whole units into inventory and retain `progress_subunits % SCALE` toward the next unit.
- Integer-millisecond accumulation must be chunking invariant when callers preserve the returned progress and arithmetic remainder.
- Arithmetic must check inputs and mathematical results before mutation. It must never silently wrap or use a float as an authoritative intermediate.
- Operations document their supported ranges and reject unsupported overflow with typed reason codes.
- No subsystem may define another fixed-point scale or duplicate conversion, accumulation, extraction, or remainder logic.
- M02 serializes all authoritative integers and remainders exactly through the approved codec-independent snapshot contract; JSON later represents them as canonical decimal strings.

### Consequences

- Small inventories in the normal `1`–`1,000` range remain simple exact integers; a player owns `1` rare Soul, not `1_000_000` inventory units and never `0.4563` of a Soul.
- Six decimal places remain available for continuous progress and coefficients. One fixed-point subunit represents `0.000001` of a whole unit.
- A source authored as one whole unit per twenty-four hours can accumulate exactly to `250_000` progress subunits after six hours and one whole unit after twenty-four hours, subject to the documented rate period and residual.
- A scaled signed-64-bit value can represent approximately 9.22 trillion whole units, while unscaled discrete counters retain the full signed-64-bit whole-number range.
- High-value arithmetic needs decomposition or other checked algorithms so a final result that fits is not rejected solely because a naive intermediate multiplication would overflow.
- Every fractional flow needs one documented progress and residual owner, and equivalent time chunking becomes an exact regression test.
- A later scale change would alter persisted numeric meaning and require an explicit migration decision after M02.

### Alternatives considered

- **Scale 1,000:** simpler but unnecessarily coarse for cumulative rates, long-horizon progress, and forecast coefficients.
- **Scale 1,000,000,000 or larger:** more precision than current design needs and materially reduces comfortable overflow headroom.
- **Scaling every inventory count:** rejected because whole objects and campaign counters do not benefit from fractional storage and would lose useful range.
- **Integer subunits per second as the only rate unit:** rejected because very rare sources can require a finer long-horizon rate than that representation expresses cleanly.
- **Binary fixed point:** viable but less legible for designer-authored decimal coefficients and junior review.
- **Floating-point authoritative state:** rejected because chunking, serialization, and cross-platform reproducibility become harder to prove exactly.
- **Different scales by subsystem:** rejected because conversions and residual ownership would become error-prone.
- **Arbitrary-precision or rational-number dependency:** rejected as unnecessary prototype complexity.

### Affected documents

- `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md`
- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`
- `docs/codex/IMPLEMENTATION_RULES.md`
- `docs/codex/TESTING_AND_VALIDATION.md`
- `docs/codex/MILESTONES.md`
- `docs/codex/milestone-prompts/M01-deterministic-time-foundation.md`

---

## `DEC-0027` — Threshold-owned long-horizon acquisition progress survives Reaping reconfiguration

**Status:** Accepted  
**Date:** 2026-07-14  
**Decision type:** Output-channel ownership and presentation  
**Refines:** `DEC-0010`, `DEC-0019`, `DEC-0020`

### Context

Some rare Souls, Denizen Souls, catalysts, or future materials may take eight to twenty-four hours of productive Threshold operation to yield one whole item. Requiring the player to keep the same Form, Writ, or Retinue configuration until a hidden timer finishes would contradict persistent strategic reconfiguration and would create an uncommunicated forfeiture risk. At the same time, player-facing inventory must remain whole and readable rather than displaying fractional Souls or catalysts.

### Decision

- When a discrete Threshold output uses deterministic long-horizon accumulation, its progress belongs to the stable pair `Threshold ID + output channel/source ID`, not to the currently assigned Form, Writ, Retinue, or transient Reaping configuration.
- The Threshold channel persists `acquisition_progress_subunits` toward the next whole item. Any finer arithmetic carry required for exact chunking has exactly one persistent owner and must be preserved or exactly normalized when the active rate context changes.
- Reconfiguration first resolves elapsed time under the old setup to the command timestamp. The new setup changes only the future rate and modifiers; it does not reset, consume, or reroll already accumulated acquisition progress.
- Recalling or leaving the Threshold inactive freezes the stored progress. Redispatch resumes from the same progress unless a separately approved rule explicitly changes the source itself.
- Transitioning from Overdue to Settled Passage does not clear the channel. Remaining progress continues under the channel's Settled rate when the source remains available.
- A long elapsed interval may bank multiple whole items. Whole units are added immediately to normal inventory and only the remainder toward the next item remains in channel state.
- The system is one channel accumulator inside the global deterministic resolver, not an independent item timer, per-item object, or separate simulation loop.
- Discovery controls disclosure, not ownership. Unknown progress remains banked but hidden. Once the channel is Identified, the Threshold view may show a progress bar and a percentage truncated to one decimal place, such as `45.6%`. It must not show `0.4563 Rare Soul` or round to `100.0%` before the whole unit is actually banked.
- A Charted channel may additionally show an estimated time, rate, relevant modifiers, and forecast range without changing the underlying progress.

### Consequences

- Players can change Forms, Retinues, or Writs without feeling forced to preserve an opaque configuration for many hours.
- Different configurations still matter because they change the future acquisition rate and forecast, not ownership of prior effort.
- Threshold state, save fixtures, forecasts, reports, and UI read models need a stable per-channel progress contract before the first long-horizon source is implemented.
- M01 implements only the generic fixed-point and per-period arithmetic needed by this rule. M03 defines channel data, M04 proves Threshold-owned accumulation and reconfiguration persistence with a test channel, and later presentation milestones expose the progress bar when a known channel requires it.
- Future stochastic rare drops, if ever approved, require a separate randomness and bad-luck-protection decision; this record governs deterministic accumulated acquisition progress.

### Alternatives considered

- **Reaping-owned progress:** rejected because recall or reassignment would require fragile transfer logic and could make prior effort appear lost.
- **Form-owned progress:** rejected because the source belongs to the Threshold and should survive a Form swap.
- **Independent countdown timer per item:** rejected because it creates competing time authority and does not compose cleanly with offline segmentation or rate changes.
- **Fractional inventory:** rejected because partial Souls and catalysts are confusing player-facing objects and complicate inventory semantics.
- **Hide all progress until a drop occurs:** rejected for long-horizon deterministic sources because it makes reconfiguration consequences opaque and can feel punitive.

### Affected documents

- `AGENTS.md`
- `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md`
- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`
- `docs/codex/IMPLEMENTATION_RULES.md`
- `docs/codex/TESTING_AND_VALIDATION.md`
- `docs/codex/MILESTONES.md`

---


## `DEC-0028` — Rare-output progress is normalized work; rate changes are prospective and non-compounding

**Status:** Accepted  
**Date:** 2026-07-14  
**Decision type:** Output-rate semantics and exploit prevention  
**Refines:** `DEC-0010`, `DEC-0027`

### Context

A long-horizon Threshold source may already have partial progress when the player recalls a Reaping, changes Form or Retinue configuration, unlocks a Form Art, purchases a Recollection, changes support state, or otherwise alters the acquisition rate. The player should benefit immediately from the new future rate without forfeiting prior work. The implementation must also prevent repeated recall and redispatch from applying the same bonus again to progress that was already earned.

A representative case starts with a four-hour source at `50.0%` progress. A stronger configuration can reduce the remaining estimate from two hours to one hour forty minutes. That does not mean the stored progress becomes `60.0%` or that a second redispatch should reduce the estimate again without another state change.

### Decision

- Persist acquisition progress as normalized completed work toward a fixed one-whole-unit target, using `progress_subunits` in `0 <= value < FixedPoint.SCALE` plus the exact arithmetic carry owned by the Threshold channel.
- Do not persist elapsed time spent, a current effective duration, a cached ETA, or a percentage rebased to the current loadout.
- Before any assignment or modifier change, resolve elapsed time to the exact command or unlock boundary under the old rate context.
- After the state change, derive the next segment's effective rate from immutable authored baseline data plus the currently active modifiers. Never derive a new effective rate from a previous effective rate.
- Within one content revision, each channel has one stable normalized rate period/denominator. Ordinary live modifiers change the effective numerator or multiplier, not that denominator, so the existing arithmetic carry retains the same mathematical meaning. A future rule that changes the denominator at runtime requires a separate accepted contract and exact carry normalization at the boundary.
- Apply ordinary Form, Writ, Retinue, Form Art, Recollection, support, lifecycle, and global-efficiency modifiers prospectively. They change future accumulation only and do not multiply, divide, or otherwise rebase progress already earned.
- Recalling and redispatching the same configuration derives the same effective rate and leaves stored progress unchanged. Repeating the operation cannot compound the bonus.
- The Threshold progress bar is based only on normalized stored progress. A rate change updates the derived ETA and modifier trace, not the percentage already earned.
- A future design that intentionally awards retroactive progress must use a separate explicit, exactly-once progress-grant effect with its own ID and tests. It must not be encoded as a rate modifier.
- Cached rate plans or ETAs may exist as rebuildable performance data only; they are never the sole source of truth and are not serialized.

### Consequences

- At `50.0%` progress, a twenty-percent future rate increase leaves the bar at `50.0%` while reducing the remaining estimate from two hours to one hour forty minutes.
- A Recollection purchased while a Reaping is active creates a deterministic simulation boundary: progress before the purchase uses the old rate and progress after it uses the new rate.
- Form Arts, support changes, and loadout changes follow the same boundary rule.
- Tests can prove equivalence between one segmented call and separate calls around the modifier boundary.
- Repeated recall/redispatch with no state change becomes a no-op for progress and rate, closing a potential compounding exploit.
- M03 defines baseline rate and modifier data without persisting effective rates. M04 implements the resolver behavior and regression tests. Later presentation uses unchanged progress percentage plus a recalculated ETA.

### Alternatives considered

- **Rebase stored progress when the rate changes:** rejected because it retroactively changes earned work, creates percentage jumps, and is vulnerable to repeated reconfiguration exploits.
- **Store remaining seconds instead of normalized work:** rejected because remaining time depends on the current loadout and becomes ambiguous when modifiers change.
- **Multiply accumulated progress by a newly unlocked efficiency bonus:** rejected because a rate modifier is prospective and repeated application would compound.
- **Store and modify the previous effective rate:** rejected because bonuses could be applied to an already modified value instead of being re-derived from the baseline.
- **Reset progress on every rate change:** rejected because it punishes strategic experimentation and contradicts `DEC-0027`.

### Affected documents

- `AGENTS.md`
- `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md`
- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`
- `docs/codex/IMPLEMENTATION_RULES.md`
- `docs/codex/TESTING_AND_VALIDATION.md`
- `docs/codex/MILESTONES.md`

---

## `DEC-0029` — Explicit content revisions govern save compatibility

**Status:** Accepted  
**Date:** 2026-07-14  
**Decision type:** Content compatibility and persistence boundary  
**Refines:** `DEC-0009`, `DEC-0011`

### Context

M02 persists a non-empty `content_revision`, but the foundation value `prototype-m02` predates the authored content catalog and the persistence API currently permits a default revision. M03 introduces the first authoritative definitions. The project needs an explicit compatibility rule that can accept known-safe foundation saves without inferring compatibility from revision names or coupling `SaveService` to content.

### Decision

- The production `ContentCatalog` declares one exact current revision, initially `prototype-content-r1`.
- The catalog also declares an explicit, duplicate-free, canonically sorted `compatible_save_revisions` list. The current revision must include itself.
- The initial list contains exactly `prototype-content-r1` and `prototype-m02`. The legacy foundation revision is safe because M02 saves contain only the minimal M01 timeline/time-authority state and no gameplay content IDs.
- Compatibility is exact string membership. Do not infer it from lexical order, numeric suffixes, semantic-version ranges, timestamps, or “latest” logic.
- New-save code must receive the current catalog revision explicitly. Persistence code must not silently select a content revision or import `ContentRegistry`.
- Load order is: decode/migrate/schema-validate the snapshot, load/validate the catalog, check exact revision compatibility, validate any persisted content IDs that exist, and only then begin simulation.
- Removing a previously compatible revision requires an explicit migration, documented prototype reset, or new decision with fixtures and owner approval.
- Any authoritative definition, normalized value, source identity, grammar reference, or rule change that can affect state, simulation, forecast, or tests advances the content revision. Presentation-only asset or naming changes do not invalidate saves; they may keep the same compatibility revision or introduce a new explicitly compatible revision for release bookkeeping.

### Consequences

- M02 saves can open after M03 without weakening validation.
- Save-schema version and content revision remain separate compatibility dimensions.
- Content revisions are reviewable and deterministic rather than inferred.
- A later content-only balance change can require a new content revision without necessarily changing schema version.
- Tests cover current, explicitly compatible legacy, missing, duplicate, and unknown revisions.

### Alternatives considered

- **Keep a persistence-owned default revision:** rejected because every content revision would require changing persistence code and callers could create stale saves silently.
- **Accept any non-empty revision:** rejected because a save could reference incompatible rules or IDs.
- **Infer compatibility from `r1`, `r2`, or semantic versions:** rejected because compatibility is not necessarily monotonic and cannot be proven from naming.
- **Bump schema solely because content exists:** rejected because schema key meaning is unchanged.

### Affected documents

- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`
- `docs/codex/IMPLEMENTATION_RULES.md`
- `docs/codex/TESTING_AND_VALIDATION.md`
- `docs/codex/MILESTONES.md`
- `docs/codex/milestone-prompts/M03-content-catalog-prototype-data.md`

---

## `DEC-0030` — Output channels are first-class catalog definitions with stable `CHANNEL_...` IDs

**Status:** Accepted  
**Date:** 2026-07-14  
**Decision type:** Content identity and long-horizon source ownership  
**Refines:** `DEC-0009`, `DEC-0027`, `DEC-0028`

### Context

Threshold outputs need stable identities independent of display names, output item IDs, filenames, and the active Reaping. The same item type may later appear at multiple Thresholds with different rates, discovery, modifiers, and acquisition progress. `DEC-0027` keys durable work by Threshold plus source/channel identity, so M03 must define that identity before M04 persists progress.

### Decision

- Add `CHANNEL_` as the canonical prefix for authored Threshold output channels.
- Treat output channels as first-class typed definitions explicitly referenced by `ContentCatalog`; do not infer them by scanning Threshold folders.
- Each channel has one stable ID, one source Threshold ID, one output item ID, a channel kind, authored baseline amount, explicit stable period, discovery metadata, Settled multiplier, progression requirement flag, and optional acquisition-progress presentation metadata.
- Threshold definitions reference channel IDs. Registry validation enforces bidirectional ownership, global channel-ID uniqueness, valid output items, and deterministic ordering.
- Backlog returns and active Form Mastery remain core Reaping streams rather than `OutputChannelDefinition` item grants.
- Durable acquisition state is keyed by `Threshold ID + channel ID`; item ID alone is insufficient because the same item may have more than one source.
- Ordinary modifiers change the future effective numerator/multiplier derived from the channel baseline. They do not change the stable period within a content revision and do not rewrite prior normalized progress.
- The current prototype channel IDs are:
  - `CHANNEL_GLOAMWOOD_ESSENCE`
  - `CHANNEL_GLOAMWOOD_SOLDIER_SOULS`
  - `CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS`
  - `CHANNEL_BROKEN_WATCH_ESSENCE`
  - `CHANNEL_BROKEN_WATCH_PROVISIONS`
  - `CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS`
- M03 authors and validates these definitions but does not accumulate them. M04 adds runtime acquisition/save state keyed by these IDs.

### Consequences

- Reconfiguration can preserve the correct source progress without attaching it to a Form, Writ, Retinue, or generic item total.
- Multiple sources of the same item remain distinguishable in forecasts, reports, discovery, and saves.
- Catalog completeness and reference validation can catch missing or miswired sources before simulation starts.
- Changing a persisted channel ID later requires migration or an approved reset.
- The catalog gains an explicit output-channel group, increasing required production definitions from fifty-four top-level non-channel records to sixty total first-class records.

### Alternatives considered

- **Use output item ID as the channel key:** rejected because one item can have multiple Threshold sources with different behavior.
- **Use array position:** rejected because reordering content would change saved identity.
- **Use filename or resource path:** rejected because organization and renames are not gameplay identity.
- **Keep channel IDs local strings inside Thresholds only:** rejected because global duplicate detection, save validation, and cross-reference diagnostics would be weaker.
- **Represent backlog and Mastery as ordinary item channels:** rejected because they have different ownership and progression semantics.

### Affected documents

- `AGENTS.md`
- `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md`
- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`
- `docs/codex/IMPLEMENTATION_RULES.md`
- `docs/codex/TESTING_AND_VALIDATION.md`
- `docs/codex/MILESTONES.md`
- `docs/codex/milestone-prompts/M03-content-catalog-prototype-data.md`

---


## `DEC-0031` — Stable canonical IDs and mutable player-facing language

**Status:** Accepted  
**Date:** 2026-07-14  
**Decision type:** Content identity, terminology, and localization readiness  
**Refines:** `DEC-0009`, `DEC-0014`, `DEC-0029`

### Context

Names such as **Unclosed Ledger**, Form Arts, Denizens, Recollections, and even core system terms will evolve during design, alpha/beta testing, and localization. Coupling mechanics or save references to those strings would make ordinary copy iteration risky. A later decision may also replace a player-facing system noun such as Threshold without changing the underlying mechanic.

### Decision

- Canonical IDs are stable mechanical/save identities. Player-facing names, descriptions, and terminology are editable authored content.
- Every named definition exposes fallback display text and may expose localization keys. Rules, saves, tests, and references never use display text as a key.
- The two prototype Traits use stable inline IDs, `TRAIT_OLD_DRILL` and `TRAIT_UNCLOSED_LEDGER`, plus editable names/descriptions and data-driven modifiers. Future Arts and Denizens follow the same ID-versus-name rule when introduced.
- Shared system nouns are centralized in one terminology catalog using stable `TERM_...` keys. Presentation resolves common labels such as Threshold, Recollection, Form, Retinue, and Essence through that catalog rather than scattering literals.
- A player-facing rename does not rename persisted prefixes or IDs. If Threshold is later displayed as another term, existing `THR_...` IDs remain stable.
- Free-form dialogue, narrative, and long descriptions are not blindly generated through term substitution. A core-term change requires a reviewed search/update pass for grammar and context.
- A display-only rename does not require a save migration. If release bookkeeping advances the content revision for text-only changes, the previous revision remains explicitly compatible.

### Consequences

- Designers can rename Traits, Recollections, and future Arts/Denizens in `.tres` content without changing gameplay code.
- UI code later receives resolved text from content/terminology lookups rather than embedding core vocabulary.
- Internal IDs may preserve historic abbreviations even when player-facing terminology changes, reducing migration risk.
- A full localization pipeline remains deferred, but M03 fields are localization-ready.

### Alternatives considered

- **Use display names as IDs:** rejected because copy changes would break references and saves.
- **Hard-code all core nouns in scenes:** rejected because a terminology change would require broad manual code edits.
- **Automatically replace core words inside prose:** rejected because grammar, inflection, and narrative context cannot be handled safely by blind substitution.
- **Rename canonical prefixes whenever the UI term changes:** rejected because internal identity does not need to mirror current marketing language.

### Affected documents

- `AGENTS.md`
- `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md`
- `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md`
- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`
- `docs/codex/IMPLEMENTATION_RULES.md`
- `docs/codex/TESTING_AND_VALIDATION.md`
- `docs/codex/MILESTONES.md`
- `docs/codex/milestone-prompts/M03-content-catalog-prototype-data.md`

---

## `DEC-0032` — Essence is the sole resource term and canonical ID

**Status:** Accepted  
**Date:** 2026-07-14  
**Decision type:** Terminology and canonical data identity  
**Refines:** `DEC-0009`, `DEC-0030`, `DEC-0031`

### Context

The design sources used both **Essence** and the earlier label **Corrupted Essence** for the same resource. Keeping two names for one inventory item would invite duplicate IDs, mismatched references, inconsistent UI, and migration mistakes. M03 is the final safe point to settle the identity before item/channel IDs enter gameplay saves.

### Decision

- Use **Essence** as the sole internal and player-facing resource term.
- Use canonical item ID `RES_ESSENCE`.
- Use channel IDs `CHANNEL_GLOAMWOOD_ESSENCE` and `CHANNEL_BROKEN_WATCH_ESSENCE`.
- Use `TERM_ESSENCE` for shared player-facing terminology.
- Code variables, metrics, tests, content, and documentation use `essence`; `ESSENCE_YIELD` remains the metric token.
- Production catalog validation rejects the deprecated item/channel IDs and the deprecated alternate display term.
- M00–M02 saves require no migration because schema version 1 currently contains no item or channel IDs. If a deprecated ID ever appears in a shipped save later, changing it requires an explicit migration.

### Consequences

- One resource has one canonical identity across authored data, runtime state, reports, saves, tests, and presentation.
- M03 definitions start with the final current ID rather than introducing an alias layer.
- Historical design provenance may mention the retired wording, but operational files and production content use Essence only.

### Alternatives considered

- **Keep both names as aliases:** rejected because aliases would spread ambiguity into content validation and reporting.
- **Use the longer player-facing name but shorter internal ID:** rejected because the owner explicitly selected one term for both boundaries.
- **Delay the decision until gameplay saves exist:** rejected because that would create avoidable migration work.

### Affected documents

- `AGENTS.md`
- `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md`
- `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md`
- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`
- `docs/codex/IMPLEMENTATION_RULES.md`
- `docs/codex/TESTING_AND_VALIDATION.md`
- `docs/codex/MILESTONES.md`
- `docs/codex/milestone-prompts/M03-content-catalog-prototype-data.md`

---

## `DEC-0033` — Rolling-wave implementation slices and review-surface guardrails

**Status:** Accepted  
**Date:** 2026-07-15  
**Decision type:** Project governance and implementation planning  
**Refines:** `DEC-0025`

### Context

M03 ultimately passed, but one implementation pull request changed 131 files and added 3,347 lines. Its broad review surface combined Resource-family design, sixty production definitions, terminology, normalization, persistence compatibility, tests, traces, owner automation, Inspector checks, and documentation. Several defects were individually simple—wrong IDs, values, mappings, condition operands, and effect declarations—but became difficult to detect because too many correctness domains changed together.

The existing milestone map already requires focused, reviewable pull requests. The original M04 definition nevertheless combines authoritative state, save evolution, assignment commands, deterministic simulation, output channels, long-horizon progress, rate changes, forecasts, reports, and a developer harness. Later conceptual milestones contain similar multi-domain combinations.

### Decision

- Treat M04 through M17 as conceptual epics. A conceptual epic defines an approved outcome and boundary but is not directly executable and receives no Codex implementation prompt.
- Use lettered implementation slices such as `M04A`, `M04B`, and `M04C`. Only an approved implementation slice receives a versioned prompt and pull request.
- Apply rolling-wave planning: inspect the merged repository immediately before each slice, confirm dependencies and tests, reassess risk dimensions, and draft only the next slice prompt.
- Approve M04A through M04E as the immediate decomposition of the Reaping-simulation epic. Later epic decompositions remain preliminary until their planning turn.
- A normal slice should have one primary subsystem owner, one principal behavior or state transition, no more than two cross-layer integration seams, one demonstration, and one focused owner-verification package.
- Before prompt approval, assess these risk dimensions:
  - new authoritative state ownership;
  - save-schema or migration changes;
  - deterministic simulation or boundary algorithms;
  - a new player-facing UI flow;
  - native or platform integration;
  - bulk authored content;
  - live, offline, or forecast equivalence;
  - exactly-once progression or transactional guarantees;
  - multiple independently testable domain services.
- Four or more risk dimensions trigger mandatory split review.
- Use these planning signals rather than mechanical merge quotas:
  - normally one primary subsystem owner;
  - normally zero or one new authoritative aggregate family;
  - normally zero or one save transition;
  - normally zero or one new player-facing flow;
  - approximately 10–25 non-documentation source/test files;
  - approximately 500–1,200 non-documentation code/test lines, excluding `.uid` files and repetitive authored data.
- A forecast above approximately 35 source/test files or 1,500 code/test lines triggers mandatory split review or an explicit owner-approved exception.
- Do not mix native/platform integration with unrelated gameplay work, or production-catalog bulk with a new framework, without explicit owner approval.
- Every future prompt records the scope assessment, expected changed areas, estimated review surface, owner package, and guardrail result.
- If implementation materially exceeds the approved estimate, introduces another risk dimension, or requires another primary owner, Codex stops and reports the growth before continuing.
- A later slice may reuse prior infrastructure or validation helpers, but its evidence must remain slice-specific and must identify exactly which slice failed or passed.

### Consequences

- The project will use more, smaller pull requests and more explicit dependency handoffs.
- Conceptual epic numbers remain stable for design and architecture references, while lettered slice IDs give implementation work precise scope.
- Review effort shifts earlier into scope assessment, reducing late correction loops and making simple data mistakes easier to isolate.
- Line and file estimates remain planning triggers. A coherent task is not rejected solely for crossing a number, but the exception must be visible and approved.
- The next implementation prompt is M04A only after its gameplay-schema gate is resolved. No unsplit M04 prompt is valid.
- M05–M17 preliminary splits may change after repository inspection; this decision does not freeze speculative future class or file layouts.

### Alternatives considered

- **Keep the original M04–M17 tasks unchanged:** rejected because M03 demonstrated that broad review surfaces increase avoidable implementation and content errors.
- **Renumber every remaining milestone sequentially:** rejected because existing decisions and architecture references already use M06, M16, M17, and other conceptual IDs.
- **Use hard file or line limits as merge rules:** rejected because repetitive data, migrations, and focused tests can vary materially in size without changing conceptual coherence.
- **Fully specify every future lettered slice now:** rejected because later boundaries should use the actual merged repository rather than speculative state.
- **Allow Codex to split its own approved prompt during implementation:** rejected because prompt scope and dependency changes require owner-visible planning and approval.

### Affected documents

- `docs/codex/MILESTONE_RECALIBRATION_PROPOSAL.md`
- `docs/codex/MILESTONES.md`
- `docs/codex/PROMPT_TEMPLATE.md`
- `docs/codex/TESTING_AND_VALIDATION.md`

---

## `DEC-0034` — Schema version 2 and sequential migration are the gameplay-state compatibility path

**Status:** Accepted  
**Date:** 2026-07-15  
**Decision type:** Persistence compatibility and schema evolution  
**Refines:** `DEC-0011`, `DEC-0022`, `DEC-0029`, `DEC-0033`

### Context

M02 froze schema version 1 as the exact minimal snapshot for M01's simulation timeline and trusted-time accounting. Its `game_state` contains only `simulation_time_msec`. M04A introduces the first durable gameplay state: inventory, Forms, Thresholds, Reaping assignment records, Threshold-owned channel progress, and command-tether capacity.

Silently adding those fields to schema version 1 would destroy the meaning of a frozen schema. Resetting every prototype save would be cheaper in the short term, but it would defer the real migration path until public builds have more state, more users, and a larger compatibility surface. The existing persistence architecture already separates runtime state, primitive schema, codec, migration, validation, and atomic storage, so the first production migration can be established while version 1 is still small.

### Decision

- M04A introduces save schema version 2 as the current write schema.
- Schema version 1 remains an immutable supported input. Its key spelling and field meaning never change.
- Schema migrations are sequential transformations of deep-copied primitive dictionaries. They are independent of JSON bytes, filesystem paths, scenes, Nodes, Resources, and local device time.
- The production `v1 -> v2` step must validate the source as schema version 1 before transforming it.
- The pure migration step:
  - sets `schema_version` to canonical string `"2"`;
  - preserves `codec_id`, `save_revision`, `content_revision`, `time_authority`, `last_offline_resolution_id`, `metadata`, and `game_state.simulation_time_msec` exactly;
  - adds the canonical empty M04A gameplay substates defined in `DATA_AND_CONTENT_CONTRACTS.md`;
  - does not invent inventory, awakened Forms, Threshold progress, Reapings, rewards, or story completion;
  - preserves the source `content_revision`; schema migration does not silently perform a content migration.
- The pure migration does not increment `save_revision`. A successful persisted upgrade increments it exactly once before the new schema-version-2 snapshot is committed.
- Loading a historical save uses a working candidate. The complete sequence is: decode, identify version, validate the historical schema, migrate sequentially, validate schema version 2, map to typed runtime state, validate domain/content compatibility, atomically persist the upgraded snapshot, and only then expose the runtime candidate as committed.
- If migration, validation, content compatibility, save-revision increment, or atomic persistence fails, no migrated runtime is exposed and the original valid bytes remain available. Temporary or suspect files follow the existing M02 recovery policy.
- When the selected source is a valid version-1 primary and upgrade succeeds, normal primary/backup rotation retains that source as the prior valid backup. When a backup is selected because the primary is invalid, the existing invalid-primary preservation rules still apply.
- New saves write only the current schema. Already-current version-2 saves load without an automatic rewrite or save-revision increment.
- Unknown future schema versions are rejected without overwrite.
- Every supported historical schema retains at least one immutable fixture, version-specific validator coverage, and a sequential migration test to the current version.
- A debug/development reset command may exist as an explicit fallback, but reset is not the ordinary compatibility path. It must preserve or archive the incompatible save and require an explicit developer or player action; it never silently deletes a save.
- Internal-only migration history may be consolidated before any external demo, Steam Playtest, early-access, or commercial save is distributed only through another explicit owner-approved decision. Once a public baseline is distributed, its required migration path cannot be replaced by a silent reset.
- A schema version changes when persisted structure or meaning changes. It does not increment automatically for every milestone, content-only tuning change, or presentation change.
- Content revision and save-schema version remain separate compatibility dimensions. `ContentRegistry` owns content-revision compatibility; persistence receives the compatible/current revision policy from the caller and does not import the production catalog.

### Consequences

- M04A must implement the first production migration rather than only a test seam.
- Future schema work becomes additive maintenance through `v1 -> v2 -> v3...`, not a later persistence-architecture rewrite.
- The codec ID remains `JSON_V1`; changing the schema does not require changing the byte codec.
- Version-specific validators and fixtures remain in the repository even after the current writer advances.
- Migration persistence becomes a transactional load concern and must be failure-injected like an ordinary save.
- Prototype testers can retain supported progress across schema changes, while explicit reset remains available for unsupported development states.
- `GATE-GAMEPLAY-SCHEMA` is satisfied for M04A prompt drafting. M04A implementation must still prove every migration and owner-verification criterion before merge.

### Alternatives considered

- **Extend schema version 1 in place:** rejected because it would make the same version number describe incompatible key sets and meanings.
- **Use a prototype reset as the primary policy:** rejected because it postpones the production migration architecture, breaks longer playtests, and increases later refactoring risk.
- **Auto-upgrade before domain/content validation:** rejected because a structurally valid but incompatible candidate must not replace a valid historical save.
- **Change the JSON codec ID with every schema:** rejected because schema and byte representation are independent contracts.
- **Migrate directly from every old version to the newest:** rejected because explicit sequential steps are easier to test, reason about, and retire deliberately.
- **Persist guessed gameplay defaults such as an awakened Form or available Threshold:** rejected because version-1 saves contain no evidence for those accomplishments.

### Affected documents

- `docs/codex/MILESTONES.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`
- `docs/codex/TESTING_AND_VALIDATION.md`
- `docs/codex/milestone-prompts/M04A-gameplay-state-persistence-foundation.md`

---

## `DEC-0035` — Reaping operations are Threshold-scoped; recalled records persist and assignment commands are revision-guarded and Form-exclusive

**Status:** Accepted  
**Date:** 2026-07-16  
**Decision type:** Reaping identity, assignment safety, capacity, and timeline semantics  
**Refines:** `DEC-0012`, `DEC-0019`, `DEC-0020`, `DEC-0027`, `DEC-0028`

### Context

M04A introduced one persisted `ReapingState` record per Threshold, including active state, Form and Writ IDs, assignment revision, operation-owned phase/carries, and simulation-timeline context. M04B must define what is meant by “the same Reaping” when a player recalls and later redispatches:

1. the same loadout to the same Threshold;
2. the same loadout to a different Threshold;
3. a different loadout to the same Threshold;
4. a later return to an earlier loadout.

The architecture must distinguish the persistent operation, its current loadout, a particular assignment-state version, and one active dispatch episode. It must also prevent recall from resetting progress, stale input from overwriting a newer assignment, and the same Form from leading two active Reapings.

### Decision

#### Identity layers

- **Reaping operation identity:** under the prototype's one-Reaping-per-Threshold rule, the stable operation is uniquely identified by its canonical `threshold_id`.
  - `GameState.reapings[threshold_id]` is the authoritative record.
  - No separate UUID or redundant persisted `reaping_id` is introduced.
  - A Threshold has no Reaping operation until its first successful dispatch creates the record.
- **Loadout identity:** a loadout is a canonical value tuple, not an entity:
  - `form_id`;
  - `writ_id`;
  - ordered canonical `retinue_ids`;
  - later approved configuration components such as Arts or support policy.
  Equal loadout values may be assigned to different Threshold-scoped operations.
- **Assignment-state identity:** each committed assignment version is identified by:
  - `threshold_id`;
  - `assignment_revision`.
  Diagnostics and events may format this as `THR_GLOAMWOOD@5`; the formatted string is derived and not separately persisted.
- **Activation-episode identity:** each successful dispatch or redispatch begins a distinct active episode identified by the resulting assignment revision for that Threshold. No extra episode UUID or persisted episode object is required in M04B.

#### First-start timestamp

- `started_simulation_msec` is the immutable simulation-timeline timestamp of the first successful dispatch that created the Threshold-scoped Reaping record.
- It is set exactly once from the current `GameState.simulation_time_msec`.
- A value of `0` is valid. Record existence—not a numeric sentinel—proves that the operation was initialized.
- Recall, redispatch, loadout changes, inactivity, Settlement, save/load, and returning to an earlier loadout never modify it.
- Ordinary gameplay commands never delete the record or remove the timestamp.
- Only a new game, an explicit owner-approved complete reset, or a future save migration that deliberately removes/replaces the Threshold operation may remove it.
- If the current activation's start time is later required by reports or gameplay, it receives a separate field such as `activation_started_simulation_msec`; `started_simulation_msec` is never repurposed.

`last_configuration_change_simulation_msec` records the latest successful dispatch, recall, redispatch, or later approved configuration change. Timestamps are not identities: two operations or commands may legitimately share the same simulation timestamp.

#### Command behavior

- `GameState.reapings` contains at most one stable record per Threshold.
- Initial dispatch creates the record when none exists:
  - `is_active = true`;
  - `assignment_revision = 1`;
  - first-start and configuration timestamps equal the current simulation cursor;
  - operation phase, completed-cycle count, Retinue list, and carries begin at canonical empty values.
- Recall does not delete the record. It:
  - requires an exact `expected_assignment_revision`;
  - sets `is_active = false`;
  - increments the revision exactly once;
  - updates only the configuration timestamp and command-owned active facts;
  - preserves first-start time, Form/Writ IDs, cycle state, operation carries, and every Threshold-owned discovery/acquisition record.
- Redispatch operates on the existing inactive record. It:
  - requires an exact expected revision;
  - completely validates the requested Form and Writ;
  - reactivates the same Threshold-scoped operation;
  - increments the revision exactly once;
  - updates the configuration timestamp;
  - preserves first-start time and all state not explicitly changed.
- Occupied tether count remains derived from active records. No persisted occupied-tether field is added.
- A Threshold has at most one active Reaping, every active Reaping consumes exactly one tether, and one Form may lead at most one active Reaping.
- Duplicate, stale, invalid, replayed, and overflow commands return stable rejections and leave state equality-equivalent to the pre-command candidate. They do not silently succeed or increment.
- Commands operate at the current committed simulation cursor. They do not read a clock or advance production.
- M04B implements initial dispatch, recall, and inactive-record redispatch. It does not implement active in-place Form/Writ/Retinue reconfiguration.
- Same-loadout redispatch preserves frozen operation phase/carry.
- Changing Form or Writ while rate-dependent phase/carry is nonzero returns `REAPING_RESOLUTION_REQUIRED`. M04C/M04D later resolve the old setup to the command boundary before a changed configuration commits.
- M04B introduces no schema-version bump. Schema version 2 already persists the required assignment fields.
- Success returns a typed result, ordered assignment event, and `save_checkpoint_requested = true`; the domain service does not write files.

#### Scenario semantics

- **Same Threshold, same loadout:** same operation, same loadout value, new assignment state, and new activation episode.
- **Different Threshold, same loadout:** different Threshold-scoped operation, same loadout value, and a distinct assignment sequence. Threshold-owned backlog, familiarity, discovery, and channel progress do not travel with the loadout.
- **Same Threshold, different loadout:** same operation, different loadout value, new assignment state, and new activation episode.
- **Return to an earlier loadout:** same Threshold-scoped operation and equal loadout value, but not the historical assignment state or episode. Current behavior is re-derived from current content and modifiers; no old effective-rate snapshot is restored.

If a future design permits multiple independent Reapings at one Threshold, it requires a first-class Reaping-instance ID, an explicit ownership revision, and a save migration. M04B must not anticipate that future with a redundant UUID.

### Consequences

- Recall is a pause in one durable Threshold operation, not destruction of an entity.
- Redispatch cannot erase Threshold-owned rare-output progress or operation continuity.
- The first-start timestamp is stable for the entire operation lineage within the save.
- The same loadout can move between Thresholds without conflating their state.
- Returning to an old loadout creates a new episode instead of restoring an old snapshot.
- Revision guards protect against stale UI input even though the prototype is single-threaded.
- Tether capacity cannot drift from Reaping activity.
- M04C/M04D receive a precise resolve-before-rate-change handoff.
- Later Retinue assignment extends the same record, loadout tuple, and revision rule.
- The first tutorial dispatch may later use `WRIT_EMERGENCY_FIRST_RETURN`; M04B's developer trace remains presentation-neutral and uses `WRIT_STANDARD`.

### Alternatives considered

- **Separate UUID for every Reaping now:** rejected because the Threshold key is already unique and a redundant ID could disagree with it.
- **Delete the record on recall:** rejected because it discards operation identity, first-start time, revision history, phase/carry continuity, and future report context.
- **Create a new operation on every redispatch:** rejected because recall would become a reset exploit and Threshold-owned continuity would be ambiguous.
- **Treat loadout equality as Reaping identity:** rejected because the same loadout can operate different Thresholds.
- **Use timestamps as identity:** rejected because separate commands and operations can share one simulation timestamp.
- **Repurpose `started_simulation_msec` as the current activation start:** rejected because it would erase the immutable first-dispatch fact.
- **Allow one Form to lead several active Reapings:** rejected for the prototype's unique active Form assignments.
- **Omit expected revisions because the prototype is single-threaded:** rejected because repeated input and stale view models can still submit obsolete commands.
- **Reset nonzero carry on changed redispatch:** rejected because it would silently destroy earned work.
- **Preserve nonzero carry under a changed rate context without resolution:** rejected until M04C/M04D can prove denominator and boundary correctness.
- **Write the save inside the assignment service:** rejected because domain mutation and file transaction ownership remain separate.

### Affected documents

- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`
- `docs/codex/MILESTONES.md`
- `docs/codex/TESTING_AND_VALIDATION.md`
- `docs/codex/milestone-prompts/M04B-dispatch-recall-assignment-integrity.md`

---

## 3. Current approval state

- `DEC-0001` through `DEC-0035` are Accepted.
- M03 prompt approval accepted `DEC-0029` through `DEC-0032`, including explicit revision compatibility, stable channel IDs, editable player-facing language, centralized terminology, and Essence as the single resource identity.
- M01 prompt approval accepted `DEC-0026`; long-horizon source ownership is recorded in `DEC-0027`; prospective, non-compounding rate-change semantics are recorded in `DEC-0028`.
- The Phase 6 architecture is approved with trusted-time, save-format, cross-machine testing, GodotSteam, owner-verification, fixed-point, Threshold-channel ownership, content compatibility, naming, and terminology refinements recorded in `DEC-0021` through `DEC-0032`.
- The post-M03 implementation workflow uses conceptual epics, lettered slices, rolling-wave planning, and review-surface guardrails under `DEC-0033`.
- `DEC-0034` resolved `GATE-GAMEPLAY-SCHEMA`; M04A implemented and verified schema version 2 plus the production sequential migration from frozen schema version 1.
- `DEC-0035` defines Threshold-scoped Reaping identity, canonical loadout values, assignment revisions/episodes, immutable first-start timestamps, stable recalled records, Form exclusivity, and resolve-before-rate-change handoff.
- Future changes preserve decision IDs for wording clarifications and create a new decision only when semantics, ownership, compatibility, or security posture changes.
