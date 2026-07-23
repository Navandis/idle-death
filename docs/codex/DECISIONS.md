# Death Idle Decision Record

**Document role:** Durable record of approved and proposed design and architecture decisions  
**Repository path:** `docs/codex/DECISIONS.md`  
**Document status:** Approved architecture and active decision record  
**Revision:** 29  
**Last updated:** 2026-07-22

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
| `DEC-0036` | Core Reaping resolution is transactional; settlement is an exact boundary and residual ownership is explicit | Accepted | 2026-07-17 |
| `DEC-0037` | Output access is global and prospective; schema version 3 persists unlocks and available-source initialization | Accepted | 2026-07-17 |
| `DEC-0038` | Discrete non-Essence channels resolve only initialized sources; whole banking is immediate and Settlement is channel-specific | Accepted | 2026-07-18 |
| `DEC-0039` | Valid loadouts remain distinct and swappable; rate-context changes preserve residuals and ETAs are baseline-derived views | Accepted | 2026-07-18 |
| `DEC-0040` | Forecasts clone current state through the shared resolver; authoritative report history is a separate slice | Accepted | 2026-07-19 |
| `DEC-0041` | Reports use schema-v4 attributed, cursor-idempotent state with read-only live views and bounded recent history | Superseded | 2026-07-19 |
| `DEC-0042` | Abandon the combined M04E2A implementation; require typed committed results and four replacement slices | Superseded | 2026-07-20 |
| `DEC-0043` | Simulation mutation and explanatory facts share one transaction provenance; M04E2 is re-sliced after failed PRs #17 and #18 | Accepted | 2026-07-22 |
| `DEC-0044` | Finalized simulation facts use one detached typed result family and a closed event union | Accepted | 2026-07-22 |

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
**Amended by:** `DEC-0037`

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
- Production eligibility and disclosure are separate. A locked progression-gated channel creates no progress, carry, banked units, inventory, or retroactive entitlement. Once `DEC-0037` access is authoritatively unlocked and the source is initialized, its Threshold-owned progress follows every persistence and reconfiguration rule in this decision.
- Identification and later insight changes never erase or rebase already-unlocked progress. A known long-horizon source may show a progress bar and a percentage truncated to one decimal place, such as `45.6%`; it must not show `0.4563 Rare Soul` or round to `100.0%` before the whole unit is banked.
- A Charted channel may additionally show an estimated time, rate, relevant modifiers, and forecast range without changing the underlying progress.

### Amendment — 2026-07-17

The original 2026-07-14 wording allowed an Unknown channel to accumulate before its mechanical unlock. Accepted `DEC-0037` supersedes only that hidden pre-unlock banking rule. The Threshold-plus-channel ownership, normalized progress, recall/reconfiguration continuity, whole-unit banking, and no-fractional-inventory rules remain authoritative.

### Consequences

- Players can change Forms, Retinues, or Writs without feeling forced to preserve an opaque configuration for many hours after a source is unlocked.
- Different configurations still matter because they change the future acquisition rate and forecast, not ownership of prior effort.
- Threshold state, save fixtures, forecasts, reports, and UI read models need a stable per-channel progress contract before the first long-horizon source is implemented.
- M01 implements only the generic fixed-point and per-period arithmetic needed by this rule. M03 defines channel data, M04 proves Threshold-owned accumulation and reconfiguration persistence with a test channel, and later presentation milestones expose the progress bar when a known channel requires it.
- Unlock timing affects cumulative output only through opportunity cost. It never creates a deadline, permanent exclusion, or later baseline-rate penalty.
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

## `DEC-0036` — Core Reaping resolution is transactional; settlement is an exact boundary and residual ownership is explicit

**Status:** Accepted  
**Date:** 2026-07-17  
**Decision type:** Deterministic simulation, lifecycle, and numeric ownership  
**Refines:** `DEC-0010`, `DEC-0012`, `DEC-0019`, `DEC-0020`, `DEC-0026`, `DEC-0035`

### Context

M04B established stable Threshold-scoped Reaping operations, exact assignment revisions, immutable first-start timestamps, and active/inactive persistence. M04C must now advance one active Reaping over an explicitly supplied elapsed interval without importing output-channel accumulation, progression effects, forecasts, reports, or concurrent-Reaping behavior.

The first core resolver needs unambiguous rules for:

- transactional mutation and failure behavior;
- what happens when no Reaping is active;
- the temporary single-active-Reaping implementation boundary;
- how normalized content and the supported modifier subset derive rates;
- where fractional returned-soul, Essence, and Mastery arithmetic is stored;
- the exact instant an Overdue Threshold becomes Settled;
- which rates change after Settlement;
- cycle phase and completed-cycle ownership;
- save-schema compatibility.

### Decision

#### One transactional resolver

- `SimulationEngine` is the sole M04C owner of elapsed-time production.
- It receives:
  - a validated `GameState`;
  - a ready `ContentRegistry`;
  - a non-negative integer elapsed duration in milliseconds.
- It reads no monotonic clock, trusted epoch, device wall clock, frame delta, scene state, Steam API, file timestamp, or UI state.
- It deep-clones the supplied state, resolves and validates the complete candidate, then commits the candidate through one explicit state-replacement boundary.
- Any validation, arithmetic, boundary, unsupported-state, or overflow failure leaves the supplied authoritative state equality-equivalent to its pre-call value.
- `elapsed_msec = 0` is a successful no-op.
- A positive interval advances `GameState.simulation_time_msec` exactly once after successful resolution.

#### Active-operation support in M04C

- Zero active Reapings is valid. The simulation timeline advances, while inventory, backlog, Mastery, Reaping phase/carry, and counters remain unchanged.
- One active Reaping is the supported M04C production case.
- More than one active Reaping returns a stable unsupported-concurrency result and commits nothing. Concurrent resolution remains a later slice.
- An inactive Reaping retains state but produces nothing.
- A non-empty Retinue configuration returns a stable unsupported-configuration result in M04C. Retinue modifiers and support remain later work.
- M04C is not wired into the player-facing application shell. It is a tested domain/simulation foundation.

#### Core rate plan

M04C derives one immutable rate plan per segment from normalized registry records and current authoritative state.

- **Returned souls**
  - begin with the active Form's `base_returned_souls_rate`;
  - apply supported Form-Trait modifiers for `SOULS_RETURNED_RATE`;
  - while Overdue, use that resulting rate;
  - while Settled, multiply it once by the Threshold's `settled_multiplier_subunits`.
- **Essence**
  - comes from the Threshold's one enabled `RES_ESSENCE` output channel;
  - begins with that channel's normalized rate;
  - applies supported Form-Trait modifiers for `ESSENCE_YIELD`;
  - while Settled, multiplies it once by the Essence channel's `settled_multiplier_subunits`;
  - does not also apply the Threshold multiplier a second time.
- **Mastery**
  - begins with the active Form's `active_mastery_rate`;
  - applies supported Form-Trait modifiers for `MASTERY_RATE`;
  - is not reduced by Settlement.
- **Cycle cadence**
  - uses the Form's `cycle_duration_msec`;
  - is not accelerated by returned-soul, Essence, or Mastery multipliers;
  - advances only while the Reaping is active.

The supported M04C modifier subset is deliberately narrow:

```text
operation: MULTIPLY
scope: REAPING_TOTAL
conditions: ALWAYS, THRESHOLD_HAS_ANY_TAG
metrics: SOULS_RETURNED_RATE, ESSENCE_YIELD, MASTERY_RATE
source: active Form Trait modifiers only
```

A relevant modifier outside that subset fails explicitly rather than being silently ignored. Irrelevant metrics such as discovery or forecast uncertainty do not affect the M04C core plan. Multipliers use central checked fixed-point floor semantics in deterministic authored order.

#### Stable residual ownership

M04C uses the existing schema-version-2 `ReapingState.flow_carry_units` map. It introduces these stable internal keys:

```text
FLOW_CORE_RETURNS_PROGRESS_SUBUNITS
FLOW_CORE_RETURNS_RATE_CARRY_UNITS
FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS
FLOW_CORE_ESSENCE_RATE_CARRY_UNITS
FLOW_CORE_MASTERY_RATE_CARRY_UNITS
```

Rules:

- returned-soul and Essence progress values remain in `0 <= value < FixedPoint.SCALE`;
- each rate carry remains in `0 <= value < its stable period_msec`;
- Mastery is already fractional authoritative state, so it needs only its rate carry;
- `cycle_phase_msec` remains the cycle remainder and `completed_cycle_count` remains the whole-cycle count;
- unknown zero-valued flow keys are preserved;
- an active Reaping with an unknown nonzero flow key fails as unsupported rather than losing or misinterpreting it;
- no core residual is duplicated in `ThresholdAcquisitionState`;
- no cached effective rate or ETA is persisted.

Returned-soul and Essence rates use `FixedPoint.accumulate_for_elapsed_msec()`. Produced subunits are added to the corresponding progress remainder; complete whole units are extracted immediately. Returned souls are whole counter/backlog changes. Whole Essence is added immediately to `InventoryState[RES_ESSENCE]`. Mastery subunits are added directly to the active Form.

#### Exact Settlement boundary

For an Overdue Threshold with positive backlog:

1. calculate analytically, with checked integer arithmetic, whether the requested interval reaches backlog zero;
2. when it does, find the minimum integer millisecond at which enough whole returned souls have been extracted to settle the remaining backlog;
3. resolve all Overdue core flows and cycle progress through that exact boundary;
4. apply every whole return produced at the boundary:
   - increment `persistent_returns_total`;
   - reduce `remaining_backlog` no lower than zero;
5. set backlog to zero and lifecycle to `SETTLED` exactly once;
6. emit one non-persisted `THRESHOLD_SETTLED` event at that simulation timestamp;
7. re-derive rates;
8. resolve the remaining interval under Settled rules.

Old rates apply through the boundary. Settled rates apply only after it. If several whole returns are produced at the boundary millisecond, all are counted while backlog still clamps at zero.

A zero-duration boundary that repeats without changing state is an error. M04C must resolve analytically or with a bounded checked search; it may not replay each millisecond, second, rendered frame, or cycle.

#### Settled core behavior

Once Settled:

- `remaining_backlog` stays zero;
- returned souls continue incrementing `persistent_returns_total` at the Threshold-settled returned-soul rate;
- Essence continues banking at the Essence-channel settled rate;
- active Form Mastery continues at its current core rate;
- cycle phase and completed-cycle count continue;
- the Settlement event is not emitted again.

M04C does not process milestones, guarantees, resonance effects, Emergency-to-Standard transition, discovery, reports, or tutorial reactions. No player-facing system calls this incomplete foundation yet.

#### Results, adapters, and persistence

- The core resolver returns one typed result containing success/error state, committed elapsed time, a typed change summary, deterministic ordered segment summaries, and ordered simulation events.
- A small supplied-duration API and a debug-advance adapter call the same resolver. Debug mode does not select alternate formulas.
- Schema version 2 remains current. No field or top-level key is added.
- The new stable flow keys are values inside the existing serialized `flow_carry_units` map.
- Integration tests save and reload Overdue, boundary-crossing, and Settled states exactly.
- The resolver does not write files; the caller persists the committed state through the existing coordinator when required.

### Consequences

- Chunking equivalence can be tested over ordinary and Settlement-crossing intervals.
- No active assignment still advances authoritative simulation time without fabricating output.
- Settlement is an exact rate-change boundary rather than an end-of-update approximation.
- Returned-soul, Essence, Mastery, cycle, and long-horizon acquisition residuals have non-overlapping owners.
- M04D can later add discrete channels and resolve-before-loadout-change behavior without replacing the core engine.
- M04E can later run forecast and other modes through the same engine.
- Concurrent Reapings remain blocked rather than being partially or order-dependently simulated.
- The implementation cannot silently apply Retinue or unsupported modifier behavior before those contracts exist.

### Alternatives considered

- **Mutate live state flow by flow:** rejected because a later overflow or invalid boundary could leave partial production.
- **Do not advance the timeline when nothing is active:** rejected because the simulation cursor is a global committed gameplay timeline, not a production counter.
- **Support multiple active Reapings immediately:** rejected because M04C is explicitly the single-Reaping core slice.
- **Replay every millisecond, second, or cycle:** rejected for performance and chunking reasons.
- **Round Settlement to the end of the requested interval:** rejected because it applies the wrong rate to part of the interval.
- **Apply both Threshold and Essence-channel settled multipliers to Essence:** rejected as double application.
- **Reduce Mastery or cycle cadence at Settlement:** rejected because Settlement lowers passage output, not the active Form's use-based progression or presentation cycle cadence.
- **Persist effective rates or ETAs:** rejected because they are derived from current content and state.
- **Ignore unknown nonzero carry keys:** rejected because that could destroy or reinterpret authoritative fractional work.
- **Add schema version 3 for named residual keys:** rejected because schema version 2 already owns a string-keyed flow residual map.

### Affected documents

- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`
- `docs/codex/MILESTONES.md`
- `docs/codex/TESTING_AND_VALIDATION.md`
- `docs/codex/milestone-prompts/M04C-single-reaping-core-resolver.md`

---

## `DEC-0037` — Output access is global and prospective; schema version 3 persists unlocks and available-source initialization

**Status:** Accepted  
**Date:** 2026-07-17  
**Decision type:** Output access, source identification, save-schema evolution, and implementation slicing  
**Refines:** `DEC-0011`, `DEC-0012`, `DEC-0019`, `DEC-0027`, `DEC-0028`, `DEC-0030`, `DEC-0034`, `DEC-0036`  
**Supersedes:** the hidden pre-unlock banking clause of `DEC-0027`

### Context

The first M04D draft allowed every enabled Threshold channel to accumulate and bank while its item/source remained Unknown. The project owner rejected that behavior because it turns mechanical unlocks into delayed UI reveals, permits unexplained inventory, makes unlock timing economically irrelevant, and allows external guides to bypass most discovery value.

The replacement must preserve three other goals:

- no item becomes permanently missable because a player discovers it late or settles a Threshold first;
- long-horizon progress remains Threshold-and-channel owned after access begins;
- specialist Forms retain information value through source counts, categories, rarity, forecast precision, and modifier explanation.

A global access fact is required because unlocking an item must activate every currently available source and automatically apply to later-available Thresholds without revealing locked regions. The existing schema version 2 has no field that can persist that global fact.

### Decision

#### Access, knowledge, and insight are separate

- **Access** answers whether an output may produce. It is authoritative gameplay state.
- **Knowledge** answers which item and currently available Threshold sources are identified.
- **Insight** answers how precisely the player understands category, rarity, rate, progress, ETA, and modifiers.
- Knowing an item from a guide or narrative hint never changes Access.
- Specialist Forms, Retinues, Recollections, repeated operation, and later Codex upgrades may improve Knowledge or Insight without bypassing an access requirement.

#### Global prospective access

- Progression-gated output access is global by canonical output item ID.
- `ProgressionState.unlocked_output_item_ids` is a sorted, duplicate-free array of canonical item IDs.
- A progression-gated non-Essence channel is eligible only when:
  - its Threshold is `AVAILABLE`;
  - the channel is enabled, referenced by, and owned by that Threshold;
  - the output item is valid;
  - the item ID is present in `unlocked_output_item_ids`.
- A non-progression-gated non-Essence channel may be initialized automatically when its Threshold becomes available.
- Essence remains owned by the M04C core stream and is excluded from this access/channel-acquisition path.

A locked channel produces:

```text
no progress
no arithmetic carry
no banked units
no inventory
no banking event
no retroactive entitlement
```

Unlocking begins prospectively at the exact committed command boundary. Elapsed time before that boundary is never backfilled.

#### Unlock and source-identification transaction

A successful output-item unlock:

1. operates on already-resolved authoritative state at the current simulation cursor;
2. validates the item and at least one authored channel relationship;
3. adds the item ID to the global sorted access set;
4. finds all currently `AVAILABLE` Thresholds with enabled, correctly owned matching channels;
5. creates canonical zero `ThresholdAcquisitionState` records for missing eligible sources;
6. identifies the item and those currently available source relationships;
7. emits one `OUTPUT_ITEM_UNLOCKED` event and sorted `OUTPUT_SOURCE_IDENTIFIED` events;
8. requests a save checkpoint.

Canonical source initialization is:

```text
progress_subunits = 0
rate_carry_units = 0
total_banked_units = 0
```

The transaction grants no item, progress, carry, inventory, elapsed production, or historical backfill. Repeating the same unlock is idempotent and emits no duplicate event.

#### Availability-scoped disclosure and reconciliation

- Unlocking an item does not reveal the name or existence of an unavailable Threshold or locked region.
- When a Threshold later becomes `AVAILABLE`, a deterministic reconciliation command initializes every channel whose item is already globally unlocked and identifies only that newly available source.
- Access may therefore exist before any source is currently available.
- The effective minimum knowledge for an initialized source is `IDENTIFIED`. Later discovery systems may advance it to `CHARTED` or expose richer insight.
- M04D1 does not add a separate persisted channel-insight state. Current source identification is reconstructible from global access, Threshold availability, canonical channel content, and acquisition-record existence. M13 may add richer persisted insight when that slice is planned.

#### Timing, order, and recoverability

- There are no unlock deadlines, real-time countdowns, order-sensitive permanent lockouts, or “unlock within N days” rules.
- Delaying an unlock has only opportunity cost: production that could have occurred after an earlier unlock did not occur.
- A later unlock uses the same applicable future baseline rate as an earlier unlock; it receives no permanent efficiency penalty because it was delayed.
- A source may be initialized after its Threshold is already Settled. It begins at zero and uses that channel's then-applicable rate.
- Guarantees or onboarding top-ups may grant a defined missing quantity after unlock, but they are explicit progression rewards and never simulated pre-unlock production.

#### Channel-specific Settlement behavior

- Settlement behavior is stream-specific and channel-specific.
- M04C's returned-soul and Essence behavior remains unchanged by this decision. M04C Mastery remains unchanged until a later explicit balance decision.
- Non-Essence resources, rare Souls, and location-exclusive outputs default to `settled_multiplier = 1.0` for the prototype so players are not pressured to delay or avoid engaging rare Thresholds.
- M04D2 will update the current non-Essence scaffold channels to the prototype default before implementing their accumulation.
- Later balance passes may tune an individual channel multiplier through content data. They do not change access ownership or retroactively alter stored progress.

#### Schema version 3

Schema version 3 becomes the M04D1 target writer and adds only:

```text
game_state.progression.unlocked_output_item_ids
```

Version 3 retains the version-2 top-level envelope and all existing gameplay-state fields. The new array is sorted, duplicate-free, contains canonical item IDs, and is mapped to runtime `StringName` values.

The production upgrade remains sequential:

```text
v1 -> v2 -> v3
```

The pure `v2 -> v3` primitive transform adds an empty access array and preserves every existing field. Before the upgraded candidate is persisted, a deterministic content-aware finalization step examines any pre-existing schema-v2 `channel_acquisition` records, resolves their valid non-Essence output item IDs through the validated registry, and unions those IDs into the access set. This preserves valid historical acquisition progress instead of making it inaccessible under the new invariant.

The finalization:

- runs only on the working upgrade candidate;
- rejects missing, disabled, misowned, Essence, or invalid historical channel references;
- preserves every acquisition value exactly;
- may initialize other currently available sources of the same derived item at canonical zero;
- validates schema, content compatibility, and domain state before persistence;
- increments save revision exactly once for the complete upgrade;
- exposes no runtime state until the atomic write succeeds;
- preserves the original valid candidate on any failure.

Already-current version-3 saves do not rewrite automatically. Frozen version-1 and version-2 validators and fixtures remain supported.

#### Revised M04D implementation slices

The former single M04D prompt is superseded by:

- **M04D1 — Output access and source-identification foundation:** schema v3, migration/finalization, global access state, unlock/reconciliation commands, source identification, no-backfill proof, save/load, and owner verification.
- **M04D2 — Discrete channel accumulation and long-horizon banking:** resolve only eligible non-Essence channels, whole banking, Threshold-owned progress/carry, channel-specific Settlement behavior, events, chunking, and persistence.
- **M04D3 — Compatible rate-context changes and acquisition queries:** compatible changed redispatch, residual preservation, incompatible-denominator rejection, non-compounding, progress/ETA query, and the full recall/reconfiguration matrix.

### Consequences

- Unlock timing has meaningful economic consequences without creating permanent exclusion.
- Players never receive unexplained gated items before the game can identify their source.
- A public drop chart cannot satisfy the authoritative unlock requirement.
- Available source locations become known at unlock; the player is not forced through a second source-location hunt.
- Locked regions remain undisclosed and reconcile correctly when later made available.
- Existing version-2 acquisition fixtures and saves retain their progress through content-aware upgrade finalization.
- M04D2 and M04D3 can operate on a clear access boundary instead of conflating locked, hidden, and accumulating channels.
- M13 can focus on information precision and presentation rather than deciding whether production occurred.

### Alternatives considered

- **Continue hidden banking before unlock:** rejected because unlock timing and progression choices become economically irrelevant and inventory can appear without an explained source.
- **Use only per-Threshold acquisition-record existence as global access:** rejected because it cannot remember an item unlock before another source Threshold becomes available.
- **Store access by channel ID:** rejected because an item-level unlock must apply to every available and future source of that item.
- **Infer access from inventory:** rejected because items may come from grants, costs, migration fixtures, or other systems and inventory does not encode source eligibility.
- **Reveal every future location at item unlock:** rejected because global item access must not disclose locked regions or Threshold names.
- **Backfill elapsed time when a source unlocks:** rejected because it nullifies timing and can trivialize the newly opened economy.
- **Make late unlocks permanently slower:** rejected because the only intended penalty is opportunity cost.
- **Apply one Threshold Settlement multiplier to every channel:** rejected because it pressures players to delay or avoid rare/exclusive Thresholds.
- **Keep schema version 2 and hide access in metadata:** rejected because unlock state is authoritative gameplay data requiring explicit validation and migration.
- **Implement access, accumulation, reconfiguration, and ETA in one PR:** rejected under `DEC-0033` review-surface guardrails.

### Affected documents

- `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md`
- `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md`
- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`
- `docs/codex/MILESTONES.md`
- `docs/codex/TESTING_AND_VALIDATION.md`
- `docs/codex/milestone-prompts/M04D-output-channels-long-horizon-progress.md`
- `docs/codex/milestone-prompts/M04D1-output-access-source-identification-foundation.md`

---

## `DEC-0038` — Discrete non-Essence channels resolve only initialized sources; whole banking is immediate and Settlement is channel-specific

**Status:** Accepted  
**Date:** 2026-07-18  
**Decision type:** Deterministic channel simulation, content compatibility, lifecycle segmentation, and event semantics  
**Refines:** `DEC-0010`, `DEC-0012`, `DEC-0014`, `DEC-0026`–`DEC-0030`, `DEC-0036`, `DEC-0037`

### Context

M04D1 established schema version 3, global output-item Access, available-source initialization, strict current-state validation, no pre-unlock backfill, and Threshold-owned `ThresholdAcquisitionState`. M04D2 must now make those initialized sources productive without reopening access ownership or combining the later loadout-rate-change work from M04D3.

The resolver must avoid several failure modes:

- elapsed simulation silently creating or unlocking a source;
- processing a locked channel because its authored content exists;
- duplicating Essence through both M04C core flow and channel acquisition;
- storing fractional items in inventory;
- losing or rebasing long-horizon progress at recall or Settlement;
- applying the Threshold's core Settled multiplier to a channel a second time;
- changing authoritative channel balance while retaining the old content revision;
- emitting unbounded per-unit events during long offline intervals.

### Decision

#### Resolver ownership and complete-state precondition

- `SimulationEngine` remains the sole owner of elapsed production.
- M04D2 extends the existing M04C transaction; it does not add a parallel channel simulator.
- The engine receives validated `GameState`, a ready `ContentRegistry`, and explicit elapsed milliseconds. It reads no clock, frame delta, scene state, Steam API, file timestamp, report state, or UI state.
- It resolves on a deep-cloned candidate and commits once after all core and channel arithmetic plus complete domain validation succeeds.
- M04D2 resolution requires the strict current-v3 access/source invariant. A currently eligible but missing source record is invalid and rejects without mutation.
- Elapsed simulation never calls the access service, inserts an access ID, creates an acquisition record, identifies a source, or backfills locked time.

#### Eligible channel set

For the one active Reaping at Threshold `T`, M04D2 processes a channel only when all of the following are true:

```text
T is AVAILABLE
T is the active Reaping operation's Threshold
channel is enabled and referenced by T
channel.source_threshold_id == T.id
channel.output_item_id is a valid enabled whole-unit item
channel is not an Essence channel
T.channel_acquisition contains the channel ID
and (
    channel.progression_required == false
    or channel.output_item_id is globally unlocked
)
```

- Eligible channels are processed in canonical channel-ID order.
- A locked progression-gated channel with no acquisition record produces nothing.
- A non-gated channel at an available Threshold is expected to have been initialized by M04D1 reconciliation; a missing record is an invalid complete state rather than an invitation for simulation to create it.
- Inactive Reapings and acquisition records at other Thresholds produce nothing.
- Discovery labels, frequency hints, and progress-bar visibility do not change production once Access/source initialization exists.

#### M04D2 channel rate context

M04D2 deliberately supports only the immutable authored channel baseline plus lifecycle behavior:

- Overdue rate starts from the channel's normalized `rate_subunits_per_period` and stable `period_msec`.
- Settled rate applies that channel's own `settled_multiplier_subunits` exactly once.
- The Threshold's core Settled multiplier is not applied to a non-Essence channel.
- Form, Writ, Retinue, Art, Recollection, support, global-efficiency, and other output-channel modifiers remain deferred to M04D3.
- A relevant modifier is therefore not silently approximated or compounded in M04D2; no authoritative runtime state currently activates one.

The period remains stable within one content revision. M04D2 changes neither period nor stored progress/carry during lifecycle transitions.

#### Content revision 2 and prototype Settlement defaults

Changing the four current non-Essence channel Settled multipliers from `0.25` to `1.0` changes normalized authoritative simulation data. Under `DEC-0029`, M04D2 therefore advances the content revision:

```text
CURRENT_REVISION = "prototype-content-r2"
COMPATIBLE_REVISIONS = [
    "prototype-content-r1",
    "prototype-content-r2",
    "prototype-m02"
]
```

The same values are authored in `content/prototype_content_catalog.tres`.

M04D2 changes exactly these current channel multipliers to `1.0`:

```text
CHANNEL_GLOAMWOOD_SOLDIER_SOULS
CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS
CHANNEL_BROKEN_WATCH_PROVISIONS
CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS
```

It does not change:

- either Essence-channel multiplier (`0.25`);
- either Threshold core multiplier (`0.25`);
- M04C returned-soul, Essence, Mastery, cycle, or Settlement semantics;
- channel periods, item IDs, source IDs, access requirements, or discovery metadata.

Existing revision-1 and `prototype-m02` saves remain explicitly compatible. Frozen historical fixtures retain their original revision. New saves use revision 2.

#### Exact accumulation and immediate whole banking

For every eligible channel in every M04C lifecycle segment:

1. accumulate authored rate subunits for the segment with the channel's persisted `rate_carry_units`;
2. checked-add produced subunits to `progress_subunits`;
3. extract every complete whole unit;
4. retain `0 <= progress_subunits < FixedPoint.SCALE`;
5. retain `0 <= rate_carry_units < channel.period_msec`;
6. checked-add whole units to the output item's inventory total;
7. preserve every existing reservation unchanged;
8. checked-add the same quantity to `total_banked_units`.

Whole output is authoritative immediately. Reports, disclosure, and later UI never own a claim step. Fractional inventory is never created.

`total_banked_units` is source history, not an inventory mirror. Inventory may later be spent or granted by another system without changing that historical counter.

#### Settlement and same-time ordering

M04D2 uses the exact M04C segment boundary:

```text
Overdue segment, including the boundary millisecond
    -> channel uses Overdue rate
THRESHOLD_SETTLED transition
Settled remainder
    -> channel uses its own Settled rate
```

- Settlement never clears, rebases, or moves channel progress/carry.
- Channel whole gains at the boundary commit before the lifecycle transition.
- Current production channels use multiplier `1.0`, so their rate remains continuous through Settlement.
- Copied test fixtures with a non-`1.0` channel multiplier prove that the segment boundary still applies correctly.

#### Result, segment, and banking-event contract

The existing `SimulationResult` remains the result envelope. M04D2 adds canonical channel deltas to the overall change summary and to each lifecycle segment.

Each channel delta contains at least:

```text
channel_id
output_item_id
banked_units_delta
progress_subunits_before
progress_subunits_after
rate_carry_units_before
rate_carry_units_after
total_banked_units_before
total_banked_units_after
```

- Channel-delta arrays are sorted by channel ID.
- A channel with no state change may be omitted; tests compare complete authoritative state independently.
- A progress-only segment contains a delta but emits no banking event.

When a channel banks one or more whole units in one lifecycle segment, the engine emits one aggregate event:

```text
OUTPUT_CHANNEL_BANKED
```

Event rules:

- occurred time: segment end cursor;
- priority: channel-gain priority before lifecycle-transition priority at the same timestamp;
- subject: Threshold ID;
- source: channel ID;
- payload: primitive output item ID, quantity, lifecycle context, total banked units, and normalized progress after banking;
- `reportable = true`;
- `tutorial_relevant = true` for the prototype; later consumers filter by item/channel ID.

Events are ordered by occurred time, priority, Threshold ID, then channel ID. They are bounded per channel per segment rather than per produced unit and are not persisted.

#### Persistence and slice boundary

- Schema version 3 remains current; no schema migration is added.
- Inventory totals and `ThresholdAcquisitionState` already persist every M04D2 authority fact.
- Active, inactive, Overdue, and Settled states round-trip exactly.
- Events, segment summaries, effective rates, and ETAs are not serialized.
- M04D2 does not permit changed-loadout redispatch, apply output-channel modifiers, calculate ETA, process progression effects, run forecasts/reports, support concurrent Reapings, or add player-facing presentation. Those remain M04D3 and later slices.

### Consequences

- Access timing remains economically meaningful because only initialized sources accumulate.
- Rare progress survives recall, inactivity, Settlement, and save/load without becoming fractional inventory.
- Inventory always contains banked whole units before any report or UI reads them.
- Current rare/resource channels remain fully renewable after Settlement, reducing incentives to delay engaging a Threshold.
- Content compatibility explicitly records the balance change rather than silently mutating revision 1.
- M04D3 can add prospective modifiers and compatible reconfiguration without replacing channel ownership or arithmetic.
- Long offline intervals remain bounded because arithmetic and banking events are aggregated rather than replayed per unit.

### Alternatives considered

- **Auto-create a missing source during elapsed simulation:** rejected because it bypasses M04D1 access/reconciliation, obscures unlock timing, and creates backfill ambiguity.
- **Process every authored channel regardless of acquisition state:** rejected because locked channels would produce and Access would again become presentation-only.
- **Store channel residuals in `ReapingState.flow_carry_units`:** rejected because source work belongs to Threshold plus channel and must survive Form/loadout changes.
- **Delay whole banking until a report is viewed or claimed:** rejected because reports are observations, not inventory authority.
- **Emit one event for every unit:** rejected because common channels and offline intervals could create unbounded event counts.
- **Apply the Threshold Settled multiplier to every channel:** rejected because channel-specific renewable behavior is authoritative under `DEC-0037`.
- **Keep content revision 1 after changing Settled multipliers:** rejected by `DEC-0029`; normalized simulation values changed.
- **Implement output-channel modifiers in M04D2:** rejected to preserve the approved M04D2/M04D3 slice boundary.
- **Add schema version 4:** rejected because schema version 3 already persists inventory and acquisition state.

### Affected documents

- `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md`
- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`
- `docs/codex/MILESTONES.md`
- `docs/codex/TESTING_AND_VALIDATION.md`
- `docs/codex/milestone-prompts/M04D2-discrete-channel-accumulation-banking.md`

---

## `DEC-0039` — Valid loadouts remain distinct and swappable; rate-context changes preserve residuals and ETAs are baseline-derived views

**Status:** Accepted  
**Date:** 2026-07-18  
**Decision type:** Loadout validity and identity, Reaping reconfiguration, deterministic modifier evaluation, and acquisition-query presentation  
**Refines:** `DEC-0027`, `DEC-0028`, `DEC-0035`, `DEC-0036`, `DEC-0038`

### Context

M04B conservatively rejected changed redispatch when nonzero cycle phase or flow carry existed because no resolver then proved what those residuals meant under another setup. M04C and M04D2 now resolve core and channel production exactly, and M04D1 preserves Threshold-owned source state.

The initial M04D3 wording said a changed Form/Writ loadout was compatible only when every denominator matched. That wording could be misread as forbidding a stronger or weaker loadout. It also did not explicitly state that two structurally different loadouts remain separate even when they produce identical results, or that player-facing ETA must be formatted as readable days/hours/minutes/seconds.

The project owner clarified the intended full-game rules:

- any valid loadout may be swapped into an eligible Threshold operation;
- validity is checked while assembling the loadout, with authoritative revalidation at commit;
- rate or output equality never merges two different loadouts;
- ordinary performance differences are allowed;
- milliseconds remain backend authority, while player-facing ETA uses readable time units.

### Decision

#### Loadout validity, identity, and performance are orthogonal

**Validity** answers whether selected components form a legal assignment. It includes Threshold restrictions, Form state, Writ state, Retinue Slot/category rules, ownership, reservations, and future policy constraints.

**Identity** is the canonical selected component tuple.

**Performance** is a derived result of content, state, modifiers, lifecycle, and Threshold.

None is inferred from another.

A faster loadout is not less compatible. A slower loadout is not invalid. Two different loadouts with equal performance remain different loadouts.

#### Validate while assembling; revalidate before commit

The assignment domain exposes one pure loadout-candidate validator for assembly-time use.

Future UI must use it to avoid offering impossible selections where practical. For example, a Martial Retinue is hidden or disabled when the selected Form lacks an available Martial slot. Threshold Circle restrictions are handled the same way.

Dispatch and redispatch run the same validation again immediately before mutation. This second check protects against stale state, changed ownership, changed availability, or content changes. It is not intended to be the first time the player is told that an assembled loadout is invalid.

M04D3 implements the current Form/Writ seam. Retinue, Art, support, and later loadout-builder rules extend it when their authoritative systems exist.

#### Component identity never derives from output

Canonical loadout identity is based on selected components:

```text
form_id
writ_id
ordered_retinue_ids
future selected component/policy IDs
```

Two loadouts are never assimilated, deduplicated, or merged merely because they produce:

- the same effective rate;
- the same ETA;
- the same modifier total;
- the same complete output vector.

Queries, comparison rows, assignment events, caches, future histories, and future saved presets retain distinct loadout identity. Current assignment episodes remain Threshold operation plus assignment revision. A future preset system may add a preset ID without replacing component identity.

#### Denominators are residual units, not performance

Fixed-period production has a numerator and denominator.

```text
1,000,000 subunits / 14,400,000 ms
1,200,000 subunits / 14,400,000 ms
```

The second loadout is twenty percent faster and fully supported because the period is unchanged. Ordinary Form, Writ, Retinue, Art, Recollection, support, lifecycle, and global-efficiency modifiers should change future numerators/multipliers, not residual denominators.

A denominator defines the mathematical unit of persisted carry. Carry recorded against one period cannot always be represented exactly against another period without an explicit normalization rule.

For M04D3:

- all production loadouts presented as valid retain stable denominators;
- Man-at-Arms and Scribe are supported because their current periods/cycle duration match;
- copied period/cycle mismatch fixtures represent unsupported content, not legitimate faster/slower player choices;
- such content returns `REAPING_RATE_CONTEXT_NORMALIZATION_REQUIRED` with no mutation.

This is a prototype/content-integrity guard. Before any denominator-changing loadout is exposed as valid in the full game, an exact normalization contract must be implemented. The final design may not permanently reject an otherwise intended valid loadout merely because it performs differently.

#### Resolve before assignment change

The caller must:

1. validate the candidate during assembly;
2. resolve explicit elapsed time under the old active setup to the exact command cursor;
3. recall the Reaping;
4. revalidate the candidate;
5. compare residual-denominator signatures;
6. commit the supported assignment or reject unsupported denominator-changing content without mutation;
7. derive future rates from baseline content plus newly active modifiers.

M04D3 does not add active in-place mutation and does not estimate elapsed time itself.

#### Residual and operation preservation

A supported changed redispatch preserves:

- all core progress and carries;
- cycle phase and completed cycles;
- every Threshold channel progress/carry/history record;
- inventory and reservations;
- Threshold backlog, returns, familiarity, lifecycle, and availability;
- immutable first-start time;
- Threshold operation identity.

Assignment revision, active state, selected loadout components, and configuration-change cursor update through the existing assignment transaction.

Different Thresholds keep separate operation and source state. Returning to a prior loadout derives its current rate from baseline content; it does not restore a historical effective-rate snapshot.

#### Prospective baseline-derived modifiers

M04D3 applies active Form Trait modifiers with:

```text
metric = OUTPUT_CHANNEL_RATE
operation = MULTIPLY
scope = OUTPUT_CHANNEL
condition in {
    ALWAYS,
    OUTPUT_ITEM,
    OUTPUT_KIND,
    THRESHOLD_HAS_ANY_TAG,
    THRESHOLD_LIFECYCLE
}
```

Evaluation order is authored Trait order then modifier order. Each multiplier uses checked fixed-point floor multiplication. The channel lifecycle multiplier applies last and once.

Every plan starts from immutable normalized baseline data. Repeated redispatch cannot compound a bonus, and equal numeric plans still retain distinct loadout identity and source traces.

Active Form Traits are the only newly executable modifier source in M04D3. Writ, Retinue, Art, Recollection, support, and global modifier execution remain deferred until their authoritative state exists.

Production content remains unchanged; copied fixtures prove `x1.20` and equal-output/different-loadout behavior. Content revision remains `prototype-content-r2`.

#### Pure acquisition query

A pure query exposes exact backend progress/rate/ETA plus derived display data. It includes persisted carry and calculates the minimum integer milliseconds needed to reach the next whole unit under the current unchanged context.

For the canonical fixture:

```text
baseline source duration = 14,400,000 ms
stored progress = 500,000
baseline ETA = 7,200,000 ms
new multiplier = 1.20
stored progress remains = 500,000
new current-context ETA = 6,000,000 ms
```

The bar remains `50.0%`; only future rate and ETA change.

ETA basis is `CURRENT_RATE_CONTEXT`. It does not forecast future Settlement, support depletion, unlocks, content changes, or player commands. M04E owns boundary-aware forecasting.

#### Player-facing ETA format

Backend arithmetic and state continue using integer milliseconds.

Any player-facing ETA uses only days, hours, minutes, and seconds and shows no more than three units:

```text
ETA below 1 day:
    HH hours, MM minutes, SS seconds

ETA at least 1 day:
    DD days, HH hours, MM minutes
```

Rules:

- the templates contain exactly three components;
- values use at least two digits;
- days may exceed two digits and are not converted to weeks, months, or years;
- English fallback text uses correct singular/plural;
- positive sub-second ETA displays as at least one second;
- localization receives structured unit/value components;
- player-facing text never shows aggregate milliseconds.

Required examples:

```text
13,935,000 ms -> 03 hours, 52 minutes, 15 seconds
183,840,000 ms -> 02 days, 03 hours, 04 minutes
```

Traces and logs may continue using exact milliseconds unless a test explicitly validates display formatting.

#### Persistence

M04D3 adds no authoritative state or migration.

```text
schema version = 3
content revision = prototype-content-r2
```

Loadout-validation results, derived loadout keys, denominator signatures, continuity results, rate plans, modifier traces, percentages, exact ETAs, and ETA-display values are never serialized. Existing selected component IDs and assignment revisions remain authoritative.

### Consequences

- Every valid currently supported loadout can be swapped after old-context resolution.
- Performance differences do not trigger a continuity rejection.
- Future denominator-changing mechanics require exact normalization before becoming valid player choices.
- The player receives validity feedback while assembling rather than after confirmation.
- Dispatch remains transactionally safe against stale state.
- Equal-output loadouts remain distinct and trackable.
- Core and long-horizon residual work survives supported changes.
- Repeated redispatch does not compound modifiers.
- Progress bars remain stable while exact and formatted current-context ETA changes.
- M04E can reuse the rate-plan/query seam for future forecasts.

### Alternatives considered

- **Treat any rate difference as incompatible:** rejected because rate numerators are intended to vary by loadout.
- **Use effective output as loadout identity:** rejected because different component choices may legitimately converge on the same result.
- **Validate only at dispatch:** rejected because the player should receive compatibility feedback while assembling the loadout.
- **Skip dispatch revalidation:** rejected because state may change after assembly.
- **Reset residuals on changed loadout:** rejected because it forfeits earned work.
- **Rebase progress to preserve old remaining time:** rejected because progress would jump and modifiers could compound.
- **Expose denominator-changing loadouts before normalization exists:** rejected because carry meaning could be corrupted.
- **Persist effective rate or ETA:** rejected because both are rebuildable views.
- **Display player ETA as milliseconds:** rejected because it is not readable.
- **Display weeks/months or four units:** rejected to keep ETA compact and consistent.
- **Implement Retinue/Art/Recollection/support state now:** rejected as outside M04D3.
- **Treat current-context ETA as a full forecast:** rejected because future boundaries belong to M04E.

### Affected documents

- `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md`
- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`
- `docs/codex/MILESTONES.md`
- `docs/codex/TESTING_AND_VALIDATION.md`
- `docs/codex/milestone-prompts/M04D3-compatible-rate-context-and-acquisition-queries.md`

---

## `DEC-0040` — Forecasts clone current state through the shared resolver; authoritative report history is a separate slice

**Status:** Accepted  
**Date:** 2026-07-19  
**Decision type:** Projection ownership, supplied-duration adapters, report-state boundary, and milestone decomposition  
**Refines:** `DEC-0010`, `DEC-0012`, `DEC-0016`, `DEC-0033`, `DEC-0039`

### Context

The approved M04E definition combined five independently reviewable concerns:

- clone-based projection;
- foreground/offline-fixture/debug execution adapters;
- authoritative report accumulation;
- report-history persistence and migration;
- the final M04 developer harness.

The merged repository now has a mature transactional `SimulationEngine`, deep-cloneable schema-v3 `GameState`, M04D3 rate-context/query seams, and no report fields in authoritative state. Forecasting can therefore be added without a migration, while implementing save-safe report accumulation necessarily introduces a new authoritative aggregate, migration, idempotency contract, and retention policy.

M04D3 also demonstrated that a nominally cohesive task can become difficult to review when multiple boundary contracts are changed together. `DEC-0033` requires a fresh rolling-wave split review before drafting the next prompt.

### Decision

#### Decompose M04E

M04E becomes a conceptual sub-epic with two implementation slices:

```text
M04E1 — Forecast clone and supplied-resolution adapters
M04E2 — Report accumulator, history, persistence, and final M04 harness
```

No direct `M04E-forecast-report-simulation-harness.md` implementation prompt is valid.

#### One gameplay formula path

`SimulationEngine` remains the sole gameplay formula and mutation owner.

M04E1 adds one `SimulationRunService` whose modes are caller metadata only:

```text
FOREGROUND_SUPPLIED
OFFLINE_FIXTURE
DEBUG
FORECAST
```

Committed modes invoke `SimulationEngine.resolve_elapsed()` on the supplied state. Forecast mode deep-clones the baseline and invokes the same method on the clone.

No mode may:

- change a rate or balance rule;
- process a different channel set;
- reorder boundaries or events;
- call a different simulation formula;
- sample elapsed time internally.

#### Generic stream and channel coverage

Forecasting delegates the complete state to `SimulationEngine` and returns the complete projected state plus the exact engine result. `SimulationRunService` must not enumerate or whitelist current Threshold IDs, channel IDs, item IDs, or output kinds.

For the current prototype, a successful forecast covers:

- every core stream resolved by the engine, including Returned Souls/backlog, Essence, Mastery, cycle progress, and lifecycle transitions;
- every initialized, eligible Threshold output channel that the engine supports, represented through stable `Threshold ID + channel ID` state, delta, and event contracts;
- initialized channel records whose selected horizon produces no whole item, because their exact projected progress and carry remain present in the projected state.

Access still gates production. Locked or uninitialized channels receive no progress, carry, inventory, or retroactive output, and player-facing disclosure remains a later presentation concern.

A future channel kind becomes forecastable by adding its normalized content/state and deterministic arithmetic once to `SimulationEngine` and its generic channel-result contract. The forecast adapter then passes that state and result through without a type-specific branch or major refactor. A channel kind that the engine does not yet support fails visibly rather than being silently omitted or approximated.

#### Forecast is detached projection

A forecast validates the current baseline, deep-clones it, resolves an explicit non-negative duration on the clone, and returns the detached projected state plus the exact engine result.

Forecasting never:

- mutates the baseline;
- writes a save or requests a checkpoint;
- appends report state;
- completes tutorial/progression presentation;
- reads clocks, scenes, files, Steam, or another platform API;
- creates authoritative history.

M04E1 implements current-state forecasts only. A later consumer may apply a separately approved hypothetical command to a clone before invoking the same seam; M04E1 does not add a generic command-replay framework.

#### Committed mode labels are not authority

Foreground-supplied, offline-fixture, and debug calls are mathematically identical for the same state and elapsed duration. Their mode label supports diagnostics and tests but is not persisted and does not enter domain events.

M05 may later supply monotonic foreground duration. M06 may later supply trusted closed-session duration. Neither replaces the simulation path.

#### Report state is separate

M04E2 owns report accumulation and history under `DEC-0016`:

- simulation gains are already applied before reporting;
- reports ingest committed deltas/events only;
- forecasts never enter report authority;
- snapshotting or clearing reports never changes inventory, backlog, Mastery, acquisition progress, or time.

Direct M04E2 work remained blocked until `GATE-REPORT-SCHEMA` approved the exact report-state schema, sequential migration, retention bound, ordering, attribution, and idempotent ingestion identity. Accepted `DEC-0041` and approved M04E2A prompt v0.2 now satisfy that gate for M04E2A; M04E2B still requires a later prompt and scope review.

### Consequences

- M04E1 remains a single-owner, no-migration projection slice.
- Forecast and committed outcomes are directly comparable through complete canonical state.
- Core streams and supported Threshold channels flow through one generic result/state contract; adding a future channel kind does not require a forecast-service branch.
- The current one-active-Reaping engine limitation remains explicit until M12.
- M05 and M06 gain one stable supplied-duration seam without importing clocks into simulation.
- Report persistence cannot silently extend schema version 3.
- M04 closes only after both M04E1 and M04E2 are Merged and Passed.
- The final M04 harness moves to M04E2, where it can demonstrate both forecast and report behavior without forcing report authority into M04E1.

### Alternatives considered

- **Keep M04E as one pull request:** rejected because projection, new report authority, migration, idempotency, and harness behavior exceed the normal review surface.
- **Put report state inside forecast results:** rejected because forecasts are non-authoritative and report history records committed gains.
- **Add a second forecast formula:** rejected because online, offline, debug, and forecast modes must share the same resolver.
- **Hard-code the current Soldier/Scribe channel set in the forecast adapter:** rejected because channel identity and kinds are content-driven and future engine-supported channels must pass through generically.
- **Pass a mode into `SimulationEngine` and branch formulas:** rejected; mode-specific differences belong outside gameplay arithmetic.
- **Persist forecast projections:** rejected because projections are rebuildable and may become stale immediately.
- **Implement hypothetical command replay now:** rejected because current-state clone equivalence is sufficient for M04E1 and a generic replay framework would broaden scope.
- **Add report fields without a migration:** rejected by the sequential schema policy established in M04A.
- **Delay all report architecture until UI:** rejected because later report UI needs an authoritative, non-claim-gated foundation first.

### Affected documents

- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`
- `docs/codex/MILESTONES.md`
- `docs/codex/TESTING_AND_VALIDATION.md`
- `docs/codex/milestone-prompts/M04E1-forecast-clone-resolution-adapters.md`

---

## `DEC-0041` — Reports use schema-v4 attributed, cursor-idempotent state with read-only live views and bounded recent history

**Status:** Superseded  
**Superseded by:** `DEC-0042`; report semantics carried forward, implementation packaging replaced  
**Date:** 2026-07-19  
**Decision type:** Report authority, attribution, save compatibility, idempotent ingestion, read-versus-archive behavior, retention, atomic orchestration, and milestone recalibration  
**Refines:** `DEC-0011`, `DEC-0012`, `DEC-0016`, `DEC-0033`, `DEC-0034`, `DEC-0035`, `DEC-0039`, `DEC-0040`

### Context

M04E1 now provides a verified explicit-duration `SimulationRunService`, detached forecasts, exact `SimulationResult` passthrough, generic channel coverage, and production-persistence evidence without report authority.

The remaining direct M04E2 definition combines:

- a new authoritative report aggregate;
- schema version 4 and sequential `v3 -> v4` migration;
- report attribution, live read models, bounded history, and event compaction;
- exact duplicate/gap/overlap handling;
- atomic coordination with committed simulation;
- the final M04 forecast/commit/report harness.

Those concerns span a new state family, a migration, retry/idempotency semantics, presentation-facing attribution contracts, and a cross-owner transaction. The post-M04E1 scope assessment therefore triggers the rolling-wave split review established by `DEC-0033`.

The report foundation must also support three later presentation surfaces without becoming UI itself:

1. an offline-return report with overall totals plus Threshold/Reaping, loadout-episode, lifecycle, and channel breakdowns;
2. recent immutable report history that can support basic Codex Mortis records;
3. a live active-Reaping view that can be inspected repeatedly without fragmenting history or treating the last click as authoritative state.

A report remains explanatory rather than claim-gated. The system must avoid:

1. gameplay committing while report ingestion fails, leaving a silent reporting gap;
2. a committed result being delivered twice and report totals doubling;
3. different loadouts or later returns to the same loadout being merged because their numeric output is equal;
4. a live Threshold inspection accidentally archiving or clearing the accumulator;
5. foreground and trusted-offline gains being mislabeled as one offline-only report.

Version-3 saves contain already-applied gameplay but no report cursor or historical event record. Migration cannot safely invent past reports.

### Decision

#### Recalibrate M04E2

Replace the direct implementation slice with:

```text
M04E2A — Report state, schema-v4 migration, attributed ingestion, read-only peeks, snapshot, and bounded recent history
M04E2B — Atomic reported-run coordinator and final M04 harness
```

M04E2 becomes a conceptual sub-epic and receives no direct prompt. M04E completes only when M04E1, M04E2A, and M04E2B are Merged and Passed.

#### Report state is authoritative explanation, never reward authority

Add `GameState.report_state` in schema version 4.

The report aggregate stores already-applied explanatory facts only. It cannot:

- grant or remove inventory;
- change backlog, Mastery, channel acquisition, lifecycle, assignments, or simulation time;
- require a claim action;
- ingest forecast projections;
- execute tutorial, progression, Hall, support, service, or platform behavior.

Archiving a report clears only the live explanation window. Gameplay remains unchanged.

#### Stable attribution hierarchy

The current Reaping operation identity is the stable Threshold ID. A report therefore attributes production through this hierarchy:

```text
Threshold-scoped Reaping operation
  -> assignment revision / loadout episode
    -> lifecycle slice
      -> output channel
```

The persisted atomic attribution unit is a typed `ReportAttributionSlice` identified by:

```text
threshold_id
assignment_revision
lifecycle_state
```

Every slice stores:

```text
canonical loadout_identity
window_started_simulation_msec
window_ended_simulation_msec
elapsed_msec
returned_souls_delta
backlog_reduced
completed_cycles_delta
inventory_gains_by_item_id
mastery_gains_subunits_by_form_id
channel_summaries_by_channel_id
```

The loadout identity contains the canonical selected component tuple, including Form, Writ, and ordered Retinue IDs. Display names, calculated rates, ETAs, and output vectors are never identity.

Consequences:

- two different loadouts with equal numeric output remain separate;
- A -> B -> A creates three assignment-episode summaries because the assignment revisions differ;
- Overdue and Settled work remain separately attributable even within one committed run;
- the same item produced by different Threshold/channel sources remains distinguishable;
- later multiple-Reaping-per-Threshold support still requires a first-class Reaping-instance ID and migration; M04E2A does not invent a redundant ID now.

#### Generic gains and channel detail

Report aggregation is ID-driven rather than hard-coded to current prototype outputs.

`inventory_gains_by_item_id` covers Essence, Souls, resources, Stores, and future engine-supported whole outputs. `mastery_gains_subunits_by_form_id` remains separate because Mastery is not inventory. Channel summaries preserve:

```text
threshold_id
channel_id
output_item_id
elapsed_msec
banked_units_delta
progress_subunits_start/end
rate_carry_units_start/end
total_banked_units_start/end
```

Adding a future engine-supported channel or item must not require a report-service formula branch or current-ID whitelist. Unsupported engine behavior still fails in the engine rather than being approximated by reporting.

#### Overall, Threshold, assignment, and history views are derived

The persisted report state stores canonical attribution slices and bounded event facts. `ReportService` exposes detached, pure read models that derive:

- overall totals;
- Threshold/Reaping-operation totals;
- assignment/loadout-episode totals;
- lifecycle and channel breakdowns;
- generic inventory gains by item ID;
- Mastery gains by Form ID;
- `is_empty`, `has_whole_gain`, `has_progress_change`, and `has_meaningful_event` flags.

Required pure queries are equivalent to:

```text
peek_live_global(state)
peek_live_threshold(state, threshold_id)
peek_live_assignment(state, threshold_id, assignment_revision)
get_report_record(state, report_sequence)
```

They deep-copy or derive their result, mutate nothing, request no checkpoint, and perform no file I/O.

A live active-Reaping panel uses the current assignment revision and the portion of that episode contained in the current live window. Its effective start is therefore the later of the live-window boundary and the first ingested interval for that assignment revision. The backend never persists “last clicked” state and never snapshots merely because the player inspects a Reaping.

Zero-row suppression, compact-versus-modal presentation, animations, labels, and minimum-duration presentation thresholds remain UI policy. The backend preserves exact facts.

#### Snapshot reasons and offline isolation

Every archived `ReportRecord` stores one canonical snapshot reason:

```text
MANUAL_REVIEW
OFFLINE_RETURN
SYSTEM_BOUNDARY
```

The live accumulator also records committed run-mode counts. `OFFLINE_RETURN` may be assigned only when the complete non-empty live window contains the approved offline committed mode and no foreground/debug run. Under current M04E1 tokens, that mode is `OFFLINE_FIXTURE`.

A future trusted-offline flow therefore uses this sequence:

```text
archive any pre-existing foreground live window if non-empty
  -> resolve and ingest the trusted offline interval
  -> archive that isolated window as OFFLINE_RETURN
```

M04E2A implements and tests the representational and validation support for this sequence. M06 owns trusted-time acquisition and application orchestration.

Snapshotting is global. M04E2A does not add a partial per-Threshold clear, because partial clearing would make global cursor and totals ambiguous. A later UI may filter one global record to a Threshold without changing the archived data.

#### Cursor-idempotent simulation ingestion

Committed simulation ingestion is identified by its explicit half-open interval:

```text
[baseline_simulation_time_msec, result_simulation_time_msec)
```

`ReportState.ingested_through_simulation_msec` is the contiguous cursor already represented by report state.

- A new interval begins exactly at the report cursor and the current candidate-state cursor equals the result end.
- A wholly covered interval is an idempotent duplicate no-op even when current state has advanced beyond the historical end.
- A partial overlap or forward gap rejects.
- Zero duration is an unchanged success.
- Forecast mode, failed runs, projected results, malformed elapsed values, and cursor inconsistencies reject without mutation.
- Positive cursor advancement is persisted even when the interval contains no reportable gain.

This cursor identity is scoped to committed simulation intervals. Later command, progression, Hall, support, service, or other report sources require their own explicit stable ingestion identity rather than overloading this cursor.

#### Typed aggregates, not a second formula

`ReportService` consumes the exact committed `SimulationResult`, its segments, channel deltas, ordered events, and the validated candidate assignment state. It does not calculate rates or production.

Only events with `reportable == true` enter report state. Raw arbitrary event payload dictionaries are not persisted. Current quantities are represented by typed attribution/channel summaries. Recent detail keeps stable event sequence, type, simulation time, priority, subject, and source.

#### Bounded recent report history

Use centralized prototype bounds:

```text
REPORT_HISTORY_LIMIT = 20
REPORT_RECENT_EVENT_LIMIT = 64
```

When recent event detail exceeds 64, remove the oldest detail and increment `omitted_event_count`, while exact event-type counts remain. When history exceeds 20, remove the oldest record and increment `dropped_history_count`.

This history is the recent player-readable report archive. It is not the sole long-term Codex Mortis analytics database. Later graphs, long-term time buckets, and cumulative statistics require a separately owned analytics contract and retention policy. M04E2A must not add that system, but its structured records remain suitable inputs for later analytics.

Ordinary report volume must never block gameplay production.

#### Snapshot semantics

The only operation that clears the live accumulator is equivalent to:

```text
snapshot_live(state, expected_next_report_sequence, snapshot_reason)
```

A successful non-empty snapshot first requires the report cursor to equal the current gameplay simulation cursor. It then:

1. validates the expected sequence and snapshot reason;
2. validates offline-window purity when reason is `OFFLINE_RETURN`;
3. deep-copies the live accumulator into an immutable ordered `ReportRecord`;
4. appends it to bounded recent history;
5. increments the report sequence once;
6. resets live at the current report cursor;
7. prunes oldest history over the bound;
8. requests one save checkpoint.

An empty snapshot is an idempotent no-op. Inspecting live or archived data is read-only. M04E2A adds no destructive clear, history-delete, or partial-Threshold-clear command.

#### Schema version 4

Schema version 4 adds canonical empty report state and keeps codec `JSON_V1` plus content revision `prototype-content-r2`.

The sequential `v3 -> v4` migration initializes the report cursor and live-window cursors to the source simulation cursor. It creates no history and no retroactive report. All earlier gameplay and envelope fields remain unchanged.

The production path is:

```text
v1 -> v2 -> v3 -> v4
```

Version-3 fixtures remain immutable supported inputs. Already-current v4 saves do not rewrite on load.

#### Atomic orchestration is M04E2B

M04E2A implements report state, migration, `ReportService`, ingestion, pure peeks, snapshotting, recent history, and persistence.

M04E2B adds a narrow `SimulationReportCoordinator` that:

```text
clones live state
  -> commits simulation on candidate through SimulationRunService
  -> ingests the exact result through ReportService
  -> validates the complete candidate
  -> replaces live state once
```

Any failure preserves both gameplay and report state. M04E2B also owns the final M04 harness and receives no prompt until M04E2A is Merged/Passed.

### Consequences

- Offline-return presentation can show overall gains and expand by Threshold, assignment/loadout episode, lifecycle, and channel.
- Live Reaping inspection is repeatable and read-only rather than a five-second report-clearing action.
- Recent report history can support basic records without pretending to be complete long-term analytics.
- Equal-output loadouts and later returns to the same loadout remain separately attributable.
- Reports survive save/load without becoming claim gates.
- Version-3 saves begin report tracking prospectively at their existing simulation cursor.
- Duplicate result delivery cannot double report totals.
- Gaps and partial overlaps fail visibly instead of producing misleading history.
- Foreground and offline-only report windows cannot be mislabeled silently.
- Report history remains bounded and diagnosably compacted.
- Forecast projections never enter report authority.
- M04E2A can be reviewed as one state/migration/service slice.
- M04E2B can be reviewed as one atomic-integration/harness slice.

### Alternatives considered

- **Keep M04E2 as one direct pull request:** rejected by the fresh scope assessment.
- **Use Threshold ID alone as the complete attribution key:** rejected because loadout changes inside one Threshold window would be merged.
- **Use loadout identity alone:** rejected because the same loadout can operate different Thresholds and can return later as a new episode.
- **Merge equal-output loadouts:** rejected by component-based identity.
- **Persist last-click timestamps:** rejected because inspection frequency is presentation state, not report authority.
- **Snapshot whenever a Threshold panel opens:** rejected because it fragments history and encourages trivial five-second reports.
- **Allow partial per-Threshold clearing:** rejected because the simulation report cursor is global and partial clears make overall totals ambiguous.
- **Treat all live accumulation as an offline-return report:** rejected because foreground and closed-session intervals must remain separable.
- **Store only overall totals:** rejected because players need Threshold/loadout/channel performance attribution.
- **Store only detailed slices and no derived query seam:** rejected because later UI should not recreate grouping and consistency rules.
- **Use report history as permanent Codex analytics:** rejected because bounded, irregular report windows are not a complete long-term statistical ledger.
- **Store reports outside GameState:** rejected because pending live state and recent history must reconstruct with the save.
- **Reconstruct reports from inventory on load:** rejected because inventory lacks interval, lifecycle, loadout, progress, event, and source detail.
- **Reconstruct version-3 report history:** rejected because no exact source facts exist.
- **Use a set of every ingested interval ID:** rejected as unbounded when a contiguous cursor plus explicit rejection rules suffice.
- **Silently slice partial-overlap results:** rejected because the service cannot safely recompute or subdivide an already-aggregated result.
- **Persist raw event payload dictionaries:** rejected as an unbounded compatibility grammar.
- **Make every event detail permanent:** rejected because ordinary volume must remain bounded.
- **Clear the accumulator without archiving:** rejected because it destroys player-readable explanation.
- **Put atomic simulation/report coordination in M04E2A:** rejected to preserve one principal transition and reviewable migration scope.

### Affected documents

- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`
- `docs/codex/MILESTONES.md`
- `docs/codex/TESTING_AND_VALIDATION.md`
- `docs/codex/milestone-prompts/M04E2A-report-state-schema-history.md`

## `DEC-0042` — Abandon the combined M04E2A implementation; require typed committed results and four replacement slices

**Status:** Superseded  
**Superseded by:** `DEC-0043`; PR #17 reset lessons and report semantics retained, typed-result-first packaging replaced
**Date:** 2026-07-20  
**Decision type:** Implementation packaging, simulation-result contract, report prerequisites, review recovery, and milestone recalibration  
**Supersedes:** `DEC-0041` implementation packaging while carrying forward its report-authority, attribution, idempotency, snapshot, retention, and no-claim semantics  
**Refines:** `DEC-0010`, `DEC-0011`, `DEC-0012`, `DEC-0016`, `DEC-0033`, `DEC-0035`, `DEC-0036`, `DEC-0039`, `DEC-0040`, `DEC-0041`

### Context

PR #17 attempted the approved M04E2A v0.2 package as one branch. It was closed without merge at final head `5c87118045faa6f48f8ce50977a9bcdcfa967e57` after reaching 21 commits, 34 changed files, 2,333 additions, and 32 deletions. Repeated targeted review rounds continued to expose new P1/P2 correctness defects after earlier findings were fixed.

The failure pattern was not a rejection of Reaping Reports or of the accepted `DEC-0041` report semantics. It exposed two implementation-planning defects:

1. the current `SimulationEngine` result boundary carries segment and channel facts in raw dictionaries that require every downstream consumer to reconstruct and revalidate a large implicit grammar; and
2. the attempted `ReportService` accumulated input validation, temporal classification, checked aggregation, historical attribution, public projection, snapshotting, retention, persistence integration, trace evidence, and owner-runner behavior in one implementation branch.

The branch crossed the `DEC-0033` mandatory reassessment triggers: more than two review rounds produced new material findings, more than eight material defects were discovered, and implementation growth substantially exceeded the approved estimate. Continuing to patch the branch would optimize sunk cost rather than reviewability.

### Decision

#### PR #17 is abandoned, not merged

PR #17 is an abandoned implementation attempt. Its branch is retained temporarily as forensic evidence and a regression-scenario source. It is not a production base.

Replacement work must begin from current `main` in new Codex tasks and new pull requests. Do not:

- reopen or continue the old Codex implementation task;
- cherry-pick the PR #17 production implementation wholesale;
- treat passing tests from that branch as merge evidence for a replacement slice;
- copy its `ReportService` decomposition merely because it already exists.

The replacement slices may inspect PR #17 only for accepted review findings, black-box expected behavior, and regression scenarios.

#### Typed committed-result contract is the prerequisite

Before report persistence is implemented, the simulation boundary must expose typed, self-contained, non-persisted committed-result records.

The bounded result family is:

```text
SimulationRunResult
  -> SimulationResult
       -> Array[SimulationSegmentResult]
            -> Array[SimulationChannelDeltaResult]
       -> Array[SimulationEvent]
```

A `SimulationSegmentResult` carries the historical facts needed by delayed consumers:

```text
threshold_id
assignment_revision
form_id
writ_id
ordered_retinue_ids
lifecycle_state
start_simulation_msec
end_simulation_msec
elapsed_msec
returned_souls_delta
backlog_reduced
essence_delta
mastery_delta_subunits
completed_cycles_delta
channel_deltas
```

A `SimulationChannelDeltaResult` carries:

```text
channel_id
output_item_id
banked_units_delta
progress_subunits_before
progress_subunits_after
rate_carry_units_before
rate_carry_units_after
total_banked_units_before
total_banked_units_after
```

Historical identity travels with the committed result. A future report, tutorial, diagnostic, or analytics consumer must not reconstruct past Form, Writ, Retinue, assignment revision, lifecycle, or source identity from current mutable `GameState`.

`SimulationResult` validates its complete local and run-level contract before the engine copies a candidate into live state. Invalid result construction is a transaction failure, not a downstream reporting concern.

These result objects remain non-authoritative and non-persisted. `SimulationEngine` remains the sole production-formula and gameplay-mutation owner.

#### M04E2A becomes a conceptual replacement sub-epic

The abandoned direct M04E2A slice is replaced by four sequential implementation slices:

```text
M04E2A1 — Typed committed simulation-result contract
M04E2A2 — Report runtime state and schema-v4 persistence
M04E2A3 — Cursor-idempotent live report ingestion
M04E2A4 — Report reads, snapshot, bounded history, and final evidence
```

M04E2A is now a conceptual sub-epic and receives no direct implementation prompt.

##### M04E2A1

Adds typed segment/channel result records, self-contained historical attribution, result-contract validation before live commit, and compatibility updates to existing simulation/run consumers. It adds no report state, no schema version, and no report service.

##### M04E2A2

Adds typed report runtime state, clone/copy and validation, schema version 4, exact primitive mapping, frozen historical validators/fixtures, sequential `v3 -> v4` migration, and persistence proof. It adds no report ingestion, peeks, snapshot command, or retention mutation.

##### M04E2A3

Adds cursor-idempotent ingestion of typed committed results into the live report accumulator. It owns the interval decision table, checked aggregation, historical attribution, no-gain advancement, exact-boundary event ownership, and no-mutation failures. It adds no public report read models, archiving, offline classification, or history pruning.

##### M04E2A4

Adds detached global/Threshold/assignment/history read models, snapshot semantics, offline-only classification, bounded event detail and recent history, final real-file trace, owner verification package, and synchronized evidence.

#### One report authority does not require one monolithic script

`ReportService` remains the sole public mutating authority for report state. It may delegate pure work to narrowly scoped helpers such as:

```text
ReportIntervalClassifier
ReportAccumulator
ReportReadModelBuilder
```

Those helpers own no authoritative state, perform no file I/O, read no clocks, and do not become alternate report authorities.

#### M04E2B remains blocked

M04E2B receives no implementation prompt until M04E2A1, M04E2A2, M04E2A3, and M04E2A4 are all Merged and Passed and a fresh `DEC-0033` scope review approves the coordinator/harness prompt.

### Protected semantics carried forward from `DEC-0041`

The replacement preserves all accepted report behavior:

- gameplay gains are committed before and independently of report presentation;
- reports never grant, remove, delay, or claim output;
- report attribution remains Threshold operation -> assignment revision/loadout episode -> lifecycle -> channel;
- component identity, not numeric output, identifies a loadout;
- equal-output loadouts and A -> B -> A episodes remain distinct;
- ingestion uses explicit contiguous simulation intervals and is idempotent for covered duplicates;
- live inspection is read-only and never snapshots or clears state;
- `OFFLINE_RETURN` requires an isolated offline-only live window;
- recent history and event detail remain bounded and are not permanent Codex Mortis analytics;
- schema version 4 begins report tracking prospectively and fabricates no pre-migration history;
- M04E2B owns atomic simulation-plus-report orchestration.

### Consequences

- Schema version 3 and content revision `prototype-content-r2` remain current through M04E2A1.
- M04E2A2 is the only replacement slice authorized to introduce schema version 4.
- A1 must not change production arithmetic, rates, state ownership, or externally observed M04E1 outcomes.
- Each replacement slice receives its own prompt, pull request, targeted review, and owner verification package.
- A replacement prompt must include the relevant field-domain, propagation, consumer-input, temporal, and failure/no-mutation matrices before implementation begins.
- Stop and re-slice again when a replacement slice crosses its approved file/line limit, introduces another authoritative aggregate, or requires another cross-layer seam.

### Alternatives considered

- **Continue patching PR #17:** rejected because review did not converge and the branch crossed mandatory stop thresholds.
- **Rewrite inside PR #17:** rejected because the existing branch and Codex task would continue to bias the implementation toward the failed decomposition and would preserve an unreviewable history.
- **Merge only the Stage 1 schema work from PR #17:** rejected because it was not independently reviewed or evidenced as a standalone mergeable slice and would couple the replacement to abandoned production code.
- **Re-run the same broad M04E2A prompt from scratch:** rejected because the prompt still combines four independently risky transitions.
- **Move reports into UI or reconstruct them from inventory:** rejected by the no-claim, attribution, interval, and persistence requirements carried forward from `DEC-0041`.
- **Persist every simulation result:** rejected because result records are transaction evidence, not save authority.

### Affected documents

- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`
- `docs/codex/DECISIONS.md`
- `docs/codex/MILESTONES.md`
- `docs/codex/TESTING_AND_VALIDATION.md`
- `docs/codex/milestone-prompts/M04E2A-report-state-schema-history.md`
- `docs/codex/milestone-prompts/M04E2A1-typed-committed-simulation-result-contract.md`

---

---

## `DEC-0043` — Simulation mutation and explanatory facts share one transaction provenance; M04E2 is re-sliced after failed PRs #17 and #18

**Status:** Accepted  
**Date:** 2026-07-22  
**Decision type:** Simulation transaction ownership, result provenance, report prerequisite redesign, milestone recalibration, and review governance  
**Supersedes:** `DEC-0042` implementation packaging  
**Carries forward:** the report semantics of superseded `DEC-0041` and the non-claim, attribution, migration, idempotency, read, snapshot, retention, and atomic-coordination requirements retained by `DEC-0042`  
**Refines:** `DEC-0010`, `DEC-0012`, `DEC-0016`, `DEC-0026`, `DEC-0027`, `DEC-0028`, `DEC-0033`, `DEC-0035`, `DEC-0036`, `DEC-0038`, `DEC-0039`, `DEC-0040`

### Context

Two consecutive M04E2 implementation attempts failed the project's objective stop rules.

PR #17 attempted report state, schema version 4, migration, ingestion, temporal/idempotent classification, attribution, reads, snapshots, retention, trace, and owner evidence in one branch. It was closed unmerged at terminal head `5c87118045faa6f48f8ce50977a9bcdcfa967e57` after 21 commits, 34 changed files, 2,333 additions, and 32 deletions. The implementation concentrated too many independent correctness domains in one report service and continued to produce new P1/P2 defects after repeated targeted reviews.

Accepted `DEC-0042` then introduced M04E2A1 as a typed committed-result prerequisite. PR #18 attempted that slice and was closed unmerged at terminal head `602dec077f44338cdb4a2eabbd30d3989c877902` after 8 commits, 15 changed files, 1,973 additions, and 53 deletions. It also continued to produce new P1/P2 findings after the terminal audit.

The second attempt exposed the deeper seam problem. The implementation kept three independently mutable descriptions of one elapsed transaction:

```text
candidate GameState
public typed result segments/events
compatibility change_summary
```

It then added a large post-hoc validator to prove those structures agreed. Each newly considered authoritative field created another comparison obligation: inventory totals, Threshold state, Form Mastery, acquisition progress/carry/history, Reaping flow carries, cycle phase/count, lifecycle transitions, event payloads, and summary values. The validator was therefore duplicating simulation semantics without structurally guaranteeing common provenance.

The report design itself remains valid. Ordinary output is already banked, reports remain explanatory, and later report authority still requires schema version 4, cursor-idempotent ingestion, historical attribution, pure reads, bounded history, and atomic application coordination.

### Decision

#### 1. Abandon both failed production implementations

PR #17 and PR #18 remain closed and unmerged. Their branches are forensic references only.

Do not:

- reopen either implementation task;
- cherry-pick or copy their production implementation wholesale;
- use their service/class decomposition as the starting architecture;
- treat a passing test from either branch as merged repository behavior.

Their accepted black-box values, review findings, boundary cases, and regression scenarios may be re-authored against the replacement contracts.

#### 2. Use one single-provenance simulation transaction

Every authoritative mutation and every explanatory fact for one elapsed simulation call must originate from the same internal transaction operation.

The approved flow is:

```text
validate source state and request
  -> capture immutable SimulationRunContext
  -> create SimulationTransaction with one private deep-cloned candidate
  -> calculate one bounded segment/boundary operation
  -> transaction applies candidate mutation and records its fact atomically
  -> repeat until elapsed interval is exhausted
  -> finalize the transaction
  -> validate the complete candidate GameState
  -> derive detached public result data from the finalized journal
  -> copy the candidate to live state once
```

The transaction boundary contains three conceptual roles:

```text
SimulationRunContext
  immutable baseline cursor and exact operation/loadout identity

SimulationTransaction
  private candidate, checked mutation methods, finalization, one commit result

SimulationFactJournal
  ordered non-persisted facts recorded only by successful transaction mutations
```

Exact class/file names may be adjusted during the approved prompt's pre-edit inspection, but these responsibilities and boundaries are mandatory.

#### 3. Candidate state is private to the transaction

No production or test-facing commit method may accept an independently supplied mutable candidate plus an independently supplied result or summary.

This pattern is prohibited:

```text
commit_if_valid(live, caller_supplied_candidate, caller_supplied_result)
```

The transaction creates and owns its candidate. Only finalization may expose a validated candidate for the engine's one `copy_from` commit.

#### 4. Mutation and fact recording are atomic operations

The transaction provides narrow internal operations equivalent to:

```text
advance_timeline
apply_core_segment
apply_channel_segment
apply_settlement_transition
```

Each operation:

1. receives validated calculation inputs;
2. checks all arithmetic before mutation;
3. updates every affected candidate field;
4. records the corresponding journal fact from the same before/after values;
5. either completes both mutation and fact recording or completes neither.

A later validator is not responsible for discovering that inventory, residuals, cycle phase, acquisition endpoints, or event facts diverged from the mutation that produced them.

#### 5. The journal is internal evidence, not persisted event sourcing

The journal is:

- runtime-only;
- bounded to one supplied elapsed call;
- discarded after detached result projection and commit;
- not a save format;
- not a general event bus;
- not a replay framework;
- not a permanent analytics ledger.

`GameState` remains the authoritative persisted aggregate. The project continues to reject event sourcing as the save architecture.

#### 6. Public results are projections of finalized journal facts

M04E2T1 preserves the current merged public `SimulationResult` representation while moving its construction behind the journal. Existing raw segment/channel compatibility data and `change_summary` are generated only from finalized journal facts; they are never independently authored.

M04E2T2 later introduces the final typed, detached, self-contained public run-fact family and migrates consumers. It does not need to revalidate an independently mutated candidate because journal and candidate already share provenance.

`change_summary` in M04E2T2 is either removed from direct consumers or retained temporarily as a pure derived compatibility view. It is never a separate authority.

#### 7. Events use closed transaction operations

Simulation events are created only by bounded transaction/journal operations for currently supported behavior, including channel banking and Threshold Settlement. An arbitrary mutable event object does not enter the commit boundary.

Boundary totals are captured at the boundary where the event is recorded, not reconstructed from the final run state after later segments.

#### 8. Re-slice M04E2

The active implementation sequence becomes:

```text
M04E2T1 — Single-provenance simulation transaction journal and commit boundary
M04E2T2 — Finalized typed run facts and current-consumer migration
M04E2A2 — Report runtime state and schema-v4 persistence
M04E2A3 — Cursor-idempotent live report ingestion
M04E2A4 — Report reads, snapshot, bounded history, and final evidence
M04E2B  — Atomic reported-run coordinator and final M04 harness
```

M04E2A1 is Superseded and failed verification. It remains in the milestone history but is not an active dependency.

No later slice receives an executable prompt until the preceding slice is Merged/Passed and a fresh scope assessment is approved.

### Consequences

- `SimulationEngine` remains the sole gameplay formula owner and becomes a smaller orchestrator around a focused transaction boundary.
- The transaction journal prevents candidate/result/summary divergence by construction rather than through a simulation-sized post-hoc validator.
- M04E2T1 is behavior-preserving and changes no save schema, content revision, formulas, public result representation, report state, or UI.
- M04E2T2 can focus on public typed facts, historical attribution, and consumer migration without also redesigning commit atomicity.
- M04E2A2 through M04E2A4 retain the report requirements carried from `DEC-0041`/`DEC-0042`.
- M04E2B remains the application-level atomic simulation-plus-report coordinator after both simulation provenance and report authority are stable.
- The root and detailed engineering rules now prohibit independently mutable candidate/result commit seams.

### Alternatives considered

- **Continue patching PR #18:** rejected because new P1/P2 findings continued after the terminal audit and the branch exceeded its approved line guardrail.
- **Add more post-hoc comparison fields:** rejected because every authoritative state field would become another duplicated simulation contract.
- **Merge only the typed record classes from PR #18:** rejected because those classes were designed around the failed candidate/result reconciliation seam and would bias the replacement architecture.
- **Build a generic event-sourcing framework:** rejected because the prototype needs one bounded transaction journal, not a new persistence or replay architecture.
- **Move report implementation ahead of the simulation redesign:** rejected because report ingestion requires trustworthy self-contained run facts.
- **Put report mutation inside `SimulationEngine`:** rejected because simulation and report remain separate authorities and M04E2B owns their application-level atomic coordination.

### Affected documents

- `AGENTS.md`
- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`
- `docs/codex/IMPLEMENTATION_RULES.md`
- `docs/codex/TESTING_AND_VALIDATION.md`
- `docs/codex/MILESTONES.md`
- `docs/codex/M04E2_RESET_PLAN.md`
- `docs/codex/M04E2_TRANSACTION_REDESIGN_PLAN.md`
- `docs/codex/M04E2_IMPLEMENTATION_POSTMORTEM.md`
- `docs/codex/milestone-prompts/M04E2A1-typed-committed-simulation-result-contract.md`
- `docs/codex/milestone-prompts/M04E2T1-simulation-transaction-journal.md`

## `DEC-0044` — Finalized simulation facts use one detached typed result family and a closed event union

**Status:** Accepted  
**Date:** 2026-07-22  
**Decision type:** Public simulation-result representation, journal projection, event grammar, historical attribution, consumer migration, and persistence exclusion  
**Requires:** M04E2T1 Merged/Passed under accepted `DEC-0043`  
**Refines:** `DEC-0012`, `DEC-0016`, `DEC-0033`, `DEC-0035`, `DEC-0036`, `DEC-0038`, `DEC-0039`, `DEC-0040`, `DEC-0043`

### Context

M04E2T1 merged through PR #21 and established one private candidate plus a finalized bounded journal whose facts share mutation provenance. The remaining public API is intentionally transitional: `SimulationEngine` owns nested result/event classes, segments and channel deltas are dictionaries, event payloads are dictionaries, and `change_summary` duplicates a subset of those facts for compatibility.

M04E2A3 will need delayed, self-contained historical facts for report ingestion. Current and future consumers must not reconstruct the prior assignment, loadout, lifecycle, channel, or boundary from mutable current state. The project also must not repeat PR #18's failure by making a public result validate or authorize an independently mutated candidate.

### Decision

#### 1. One detached typed result envelope

M04E2T2 introduces a global `SimulationResult` with a closed `result_kind`:

```text
FAILURE
ZERO_DURATION
TIMELINE_ONLY
ACTIVE_REAPING
```

The result contains typed request/commit timing, baseline/result simulation cursors, content revision where applicable, typed segments, and typed events. Failure and zero results carry no committed segment/event authority. Positive timeline-only results carry only the exact interval. Positive active results carry complete contiguous segment facts.

#### 2. Segments carry historical operation identity

`SimulationSegmentResult` carries Threshold ID, assignment revision, Form ID, Writ ID, ordered Retinue IDs, lifecycle, exact timing, core deltas, and typed channel deltas.

Historical identity is copied from the immutable run context/facts and remains stable after same-timestamp recall, redispatch, or later state changes. Component identity remains distinct even when two loadouts produce equal numeric output.

#### 3. Channel facts are self-interpretable

`SimulationChannelDeltaResult` carries channel/item identity, banked quantity, progress endpoints, rate period, rate-carry endpoints, and total-banked endpoints. The period travels with the carry so a retained detached fact does not require current content to interpret the carry domain.

Internal inventory endpoints remain journal provenance and do not become a second public report authority.

#### 4. Simulation events form a closed typed union

The current event union contains only:

```text
SimulationChannelBankedEvent
SimulationThresholdSettledEvent
```

Each event has a typed common envelope and an explicit owning segment index. Each subtype has typed fields instead of a generic payload dictionary. Unknown event types and arbitrary payloads are not part of the public contract.

Stable order remains occurred simulation time, priority, subject ID, source ID. Ownership remains start-exclusive/end-inclusive. Event cardinality must agree with the typed segment/channel facts.

#### 5. Projection consumes finalized evidence only

One pure `SimulationResultProjector` or equivalent maps finalized `SimulationRunContext` plus frozen `SimulationFactJournal` to public typed facts.

The projector receives no live or candidate `GameState`, mutates nothing, calculates no gameplay formula, and cannot authorize commit. Pure validation covers field domains, detachment, timing, identity continuity, ordering, cardinality, and projection integrity only.

#### 6. Remove the transitional public grammar

M04E2T2 removes:

- raw public segment dictionaries;
- raw public channel-delta dictionaries;
- generic public event payload dictionaries;
- simulation `change_summary`;
- nested result/event type ownership inside `SimulationEngine`.

All current consumers migrate directly in the same slice. Internal journal trace dictionaries remain allowed as diagnostic evidence. No parallel raw public compatibility API remains after merge.

#### 7. Preserve behavior, authority, and persistence

M04E2T2 changes no formulas, rates, segmentation, candidate mutation, commit ordering, schema field, content revision, report state, or trusted-time behavior.

```text
save schema = 3
content revision = prototype-content-r2
```

Results and their child facts remain detached, non-authoritative, and non-persisted.

### Consequences

- Later report ingestion receives self-contained historical facts without reading current mutable Reaping state.
- The public contract becomes statically typed and closed without becoming a commit validator.
- Candidate/fact provenance remains owned by M04E2T1; T2 does not duplicate it.
- Current tests and traces must compare typed values rather than dictionary keys or object identity.
- Adding a future simulation event type requires an explicit typed subtype and contract review.
- M04E2A2 remains the only next slice authorized to introduce report state and schema version 4.

### Alternatives considered

- **Retain dictionaries and document their keys:** rejected because delayed consumers need a durable typed contract and dictionary drift is difficult to audit.
- **Keep dictionaries beside typed records:** rejected because parallel public grammars would diverge and prolong migration indefinitely.
- **Retain `change_summary` as a second public API:** rejected because current consumers can migrate and T1 already proved a single journal source.
- **Let the projector compare the candidate with the result:** rejected because that recreates the failed PR #18 seam and duplicates simulation semantics.
- **Persist every result:** rejected because run facts are transaction evidence; report persistence belongs to M04E2A2 onward.
- **Use one generic event plus payload dictionary:** rejected because current event types have a small closed grammar and later report consumers need typed fields.
- **Add report state in the same slice:** rejected because that adds an authoritative aggregate, schema transition, and separate risk domain.

### Affected documents

- `AGENTS.md`
- `docs/codex/ARCHITECTURE.md`
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`
- `docs/codex/IMPLEMENTATION_RULES.md`
- `docs/codex/TESTING_AND_VALIDATION.md`
- `docs/codex/MILESTONES.md`
- `docs/codex/M04E2T2_PLANNING.md`
- `docs/codex/milestone-prompts/M04E2T2-finalized-typed-run-facts.md`

## 3. Current approval state

- `DEC-0001` through `DEC-0040` and `DEC-0043` are Accepted.
- `DEC-0041` is Superseded; its report semantics remain carried forward.
- `DEC-0042` is Superseded by `DEC-0043`; its PR #17 reset record and report-slice lessons remain historical context, while its typed-result-first implementation packaging is retired.
- `DEC-0044` is Proposed and is not authoritative until explicit owner acceptance.
- M04A through M04D3, M04E1, and M04E2T1 are implemented, verified, and merged.
- M04E2T1 merged through PR #21 from final head `a4d8056cb8771e84e1948fc5e59939c46a13003c` at merge commit `68364e0b417a6e7ebc63b50a386ac5d9f2c506bf`.
- `GATE-SINGLE-PROVENANCE-TRANSACTION` and the owner-approved M04E2T1 scope exception are satisfied.
- PR #17 and PR #18 remain closed unmerged forensic references; M04E2A1 remains Superseded/Failed.
- The active M04E2 sequence is M04E2T1 -> M04E2T2 -> M04E2A2 -> M04E2A3 -> M04E2A4 -> M04E2B.
- M04E2T2 has an approved high-level boundary under `DEC-0043`, a proposed exact contract in `DEC-0044`, and a Draft v0.1 prompt. It remains Not started.
- `GATE-FINALIZED-RUN-FACTS` and the M04E2T2 `GATE-SLICE-SCOPE` remain pending explicit owner approval of `DEC-0044` and the prompt.
- M04E2A2, M04E2A3, M04E2A4, and M04E2B remain blocked on their preceding active slices and fresh prompt/scope reviews.
- Future changes preserve decision IDs for wording clarifications and create a new decision when semantics, ownership, compatibility, implementation packaging, or security posture changes.
