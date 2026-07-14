# Death Idle repository instructions

## Project identity

Death Idle is a 2D, UI-led idle and incremental management game built in Godot.

The current target is the playable 0-90 minute prototype. The prototype must prove that the player can configure persistent Reapings, leave them operating online or offline, return to automatically banked progress, understand what happened, and make a small number of consequential configuration decisions.

This is a prototype-first, solo-developed project. Prefer clear, deterministic, testable solutions over launch-scale frameworks or speculative abstractions.

## Design source documents

The repository's implementation-oriented Markdown files are the normal operational sources for Codex:

- `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md`
- `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md`

These Markdown files must distill the two original design documents into concise, implementation-relevant requirements. They must preserve confirmed behavior, status labels, terminology, sequence, guarantees, exclusions, and source mapping without reproducing the DOCX files verbatim.

If the original DOCX files are committed, store them under `docs/design/source-documents/` as archival provenance. They are not the files Codex should use for routine implementation work.

Rules for archived source documents:

- Do not edit, rename, convert, or replace a DOCX file during ordinary implementation work.
- Do not assume a binary document has been updated merely because the Markdown changed.
- If Markdown appears to omit or contradict an archived source requirement, inspect the applicable decision record and report the discrepancy instead of silently choosing one version.
- Approved decisions may intentionally refine or supersede ambiguous wording from an archived document; those decisions must be reflected in the maintained Markdown.
- Each source-of-truth Markdown file must identify the originating document version and map major requirements to the relevant source section.

## Source-of-truth hierarchy

Apply requirements in this order:

1. The latest explicit instruction in the current task or from the project owner.
2. `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md` for prototype sequence, tutorial behavior, guarantees, first-session content, and acceptance criteria.
3. `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md` for broader system rules, terminology, product direction, and expansion-compatible constraints.
4. Approved decisions in `docs/codex/DECISIONS.md` when they clarify, refine, or supersede ambiguous source wording.
5. Existing repository behavior and maintained documentation.
6. Your own recommendations.

Do not silently resolve a conflict between sources.

When two applicable sources disagree:

- identify the conflict;
- describe its practical implementation consequence;
- check whether `docs/codex/DECISIONS.md` already resolves it;
- stop and request a decision unless the hierarchy clearly resolves it;
- do not choose whichever interpretation is easiest to implement.

Do not restore assumptions from the older expedition model. In particular, do not introduce claim-gated output, mandatory recalls, repeated redispatch chores, hard shutdowns from ordinary support depletion, or finite locations that permanently lose essential sources.

## Required reading before implementation

Before modifying non-trivial behavior:

1. Read this file completely.
2. Read the relevant design source-of-truth documents.
3. Read:
   - `docs/codex/ARCHITECTURE.md`;
   - `docs/codex/IMPLEMENTATION_RULES.md`;
   - `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`;
   - `docs/codex/TESTING_AND_VALIDATION.md`;
   - `docs/codex/DECISIONS.md`;
   - `docs/codex/OWNER_VERIFICATION_WORKFLOW.md` when the task has owner-run Windows, editor, visual, audio, functional, A/B, persistence, or Steam checks.
4. Read the applicable milestone definition and milestone prompt.
5. Inspect the current implementation and tests before proposing changes.

If a referenced document required by the current task is missing, stale, or internally inconsistent, report that before implementing dependent behavior.

For non-trivial work, briefly state the proposed approach, expected files, and verification plan before editing.

## Confirmed prototype decisions

The following decisions supersede ambiguous shorthand in the design documents:

- At 1,000 Gloamwood returns, the active Emergency Writ transitions seamlessly to Standard behavior. The Reaping does not stop, release its command tether, discard progress, or require a new dispatch.
- The 5,000-Gloamwood milestone, after Scribe is awakened, produces a minor first seal resonance. It charts or unlocks Broken Watch and grants the second command tether.
- The 10,000-regional-souls milestone produces a separate second resonance event, an Essence reward, and access to the optional Recollection choice.
- At the Scribe tutorial step, guarantees secure the required Scribe Form Soul and mandatory Essence. The player must still press **Awaken**. Normal tutorial progression must not awaken Scribe automatically.
- The timings, coefficients, costs, rates, and balance values identified as provisional remain configurable and may change after playtesting.

## Technology, platform, and distribution

- Engine: Godot 4.7.
- Language: GDScript only.
- Primary development platform: Windows.
- Product target: Windows PC.
- Initial commercial storefront target: Steam.
- Possible later storefronts, such as Epic Games Store or GOG, are deferred and depend on demonstrated demand and acceptable return on implementation effort.
- Presentation: 2D and UI-led.
- Reference viewport: 1920 x 1080.
- Support ordinary window resizing and sensible stretch behavior.
- Preserve the current renderer unless a scoped task demonstrates and documents a reason to change it.
- Do not add C#, .NET project files, native libraries, GDExtensions, or another scripting language beyond the already approved GodotSteam 4.20 GDExtension used only by the trusted-time platform adapter. Updating or replacing that dependency requires explicit approval. The exception does not authorize other Steam features or move time authority into domain code.
- GUT 9.7.1 and GodotSteam 4.20 are pinned repository dependencies. Do not update, replace, auto-download, or re-vendor either dependency during unrelated work.
- Development Steam App ID `480` is configured in `project.godot`; automatic Steam initialization remains disabled until M06 explicitly wires the adapter. Do not add `steam_appid.txt` by default. Add one only if a verified launch path requires it, and never include it in a shipped build.
- Do not commit machine-specific executable paths.

The prototype targets eventual Steam distribution, but Steam integration is not part of the current prototype unless an approved milestone explicitly includes it.

Keep authoritative game rules, simulation, save data, and content independent of a storefront SDK. Do not add Steamworks, achievements, cloud-save integration, depot configuration, DRM, store APIs, or a multi-store abstraction during prototype work without explicit approval. Avoid hard-coding Steam assumptions into domain logic, but do not build speculative adapter frameworks for stores that are not yet supported.

## Repository map

The intended repository responsibilities are:

- `project.godot`: Godot project configuration, including the development Steam App ID and disabled automatic Steam initialization.
- `addons/gut/`: pinned GUT 9.7.1 test dependency; M00 owns harness validation, not dependency acquisition.
- `addons/godotsteam/`: pinned GodotSteam 4.20 GDExtension; only M06 may introduce trusted-time behavior through it.
- `tools/test/`: cross-platform repository test wrappers created and maintained by M00.
- `tools/test/owner/`: milestone-specific owner verification scripts; generated logs live under the ignored `tools/test/owner/logs/` directory.
- `test_main_scene.tscn`: current temporary editor and asset dry-run scene. It is not final application architecture.
- `src/app/`: application startup, composition, and high-level coordination.
- `src/domain/`: authoritative game-state concepts and domain rules.
- `src/simulation/`: deterministic online, forecast, and offline resolution.
- `src/persistence/`: save schema, serialization, migrations, and transaction safety.
- `src/content/`: content loading, lookup, and validation code.
- `src/tutorial/`: tutorial and narrative orchestration.
- `src/presentation/`: scenes, screen controllers, view models, and UI behavior.
- `src/debug/`: prototype-only inspection and pacing tools.
- `content/`: authored game definitions and configurable prototype values.
- `assets/`: source art, audio, fonts, icons, and placeholders.
- `tests/`: deterministic unit, integration, save/load, and simulation tests.
- `docs/design/`: implementation-oriented design sources of truth.
- `docs/design/source-documents/`: optional archived DOCX source material; not routine implementation guidance.
- `docs/codex/`: architecture, engineering rules, decisions, validation, owner-verification workflow, milestones, and prompts.

Do not create every planned directory merely to reproduce this map. Introduce a directory when its first real file is needed, except for approved asset destinations that require placeholders.

Do not rename or reorganize the current dry-run scene or imported assets as part of an unrelated task.

## Current prototype scope

The prototype includes only the systems needed to demonstrate:

- the opening narrative sequence;
- the one-time failed four-soul action;
- Gloamwood Hamlet;
- Man-at-Arms and Scribe;
- the Emergency-to-Standard Writ transition;
- persistent Reapings;
- Corrupted Essence and Form Mastery;
- the Archive and early Recollections;
- the 30-position Soulweave presentation, with only two functional Forms;
- Soldier Calling Soul inventory and reservation;
- one Soldier Company requiring 12 reserved Soldier Souls;
- Broken Watch and a second command tether;
- two concurrent Reapings and Form reassignment;
- discovery states and Scribe-led Provisions discovery;
- the Larder and Provisions-to-Rations conversion;
- support pressure and graceful degradation;
- the two approved prototype resonance events;
- Reaping Reports;
- an eight-hour forecast and offline return;
- save/load through the complete sequence.

## Explicit non-goals

Do not implement unless a later approved milestone explicitly includes them:

- the complete thirty-Form functional roster;
- Form Arts;
- additional Retinues;
- Calling Soul attrition, strain, turnover, relief reserves, scattering, or Recovery Retinues;
- advanced Writs or custom automation;
- Frayed or Anchored Thresholds;
- Deep Incursion or prestige;
- Denizen Souls;
- complete Codex Mortis analytics;
- advanced Store policies;
- a complete region or production-scale content quantity;
- final balance;
- final narrative dialogue, voice acting, art, animation, or audio;
- Steamworks or other storefront SDK integration beyond the separately approved trusted-time adapter;
- achievements, cloud saves, depot or release configuration, DRM, or launch packaging;
- launch telemetry, accounts, servers, or backend services.

Small interfaces may leave room for later content only when doing so prevents clear and near-term prototype rework. Do not build speculative subsystems for hypothetical future needs.

## Architectural boundaries

Keep these responsibilities separate.

### Authoritative state

Authoritative game state owns gameplay facts such as:

- inventory;
- Threshold state and backlog;
- active Reaping assignments;
- command tether use;
- Forms and Mastery;
- Retinue reservations;
- Halls and recipes;
- Recollections;
- unlocks and milestones;
- tutorial state;
- guarantee-completion flags;
- report accumulators;
- timestamps needed for resolution.

Do not make a UI node, animation, open screen, dialogue box, or temporary scene-tree object the sole owner of authoritative state.

### Simulation

The simulation layer owns production and elapsed-time resolution.

It must be usable independently of presentation so that the same rules can support:

- online progress;
- offline progress;
- forecasts;
- automated tests;
- debug time advancement.

Do not place authoritative production formulas inside UI scripts.

### Presentation

Presentation observes authoritative state and issues explicit commands or requests.

UI code may:

- display values;
- animate transitions;
- gather player choices;
- request domain actions;
- present reports and tutorial guidance.

UI code must not independently grant resources, consume resources, complete milestones, reserve Souls, or calculate a competing version of production.

### Tutorial orchestration

The tutorial may:

- detect authoritative conditions;
- guide the player;
- queue notices;
- request an approved guarantee;
- open or highlight a screen;
- record tutorial presentation state.

The tutorial must not own duplicate versions of inventory, Reaping, Form, Retinue, Hall, or save rules.

### Persistence

The persistence layer owns save representation, schema versioning, validation, migration, transaction markers, the relative simulation timeline, and trusted-time reconciliation metadata.

Changing serialized data is an architectural change. Update tests, migrations or compatibility handling, and the data contract in the same task.

### Reports

Resources and progress are applied immediately to authoritative state.

A Reaping Report stores deltas and explanatory events for presentation. Opening, dismissing, clearing, or losing a report accumulator must never remove or delay the underlying gains.

## Simulation invariants

Treat the following as protected architecture rules:

- Ordinary Reaping output is banked automatically.
- Production continues while menus, dialogue, reports, forecasts, and tutorial overlays are open.
- A persistent Reaping continues until intentionally reassigned or otherwise resolved by an explicit rule.
- The Emergency Writ transitions to Standard behavior without interrupting production.
- Online, offline, and forecast calculations use the same authoritative simulation rules.
- UI animation timing is never authoritative simulation timing.
- Elapsed-time resolution is deterministic from committed state and elapsed time.
- Foreground elapsed time uses an injected monotonic clock. Authoritative offline elapsed time must never be calculated from the player device wall clock, timezone, file timestamps, registry values, or another locally adjustable absolute-time source.
- Offline rewards require an approved external `TrustedTimeProvider`. If trusted time is unavailable, reversed, or inconsistent, record the reconciliation as pending and grant no closed-session progress until trust is restored; never fall back silently to local wall time. Foreground monotonic progress may continue.
- Resolve elapsed time analytically or in meaningful deterministic segments rather than simulating every rendered frame.
- Segment at state boundaries such as support depletion, milestone grants, discovery changes, Hall targets, backlog zero, and fallback transitions.
- Parallel output channels resolve independently unless an approved content rule explicitly links them.
- Hidden output is real output and is banked before identification.
- Ordinary support depletion degrades affected effects or premium channels. It does not stop valid base backlog, Essence, or Mastery production.
- Reaching zero backlog automatically changes an active Standing Threshold to renewable Settled Passage behavior.
- Essential sources remain accessible after settlement at the applicable renewable rate.
- Tutorial-critical guarantees are deterministic, additive, idempotent, and evaluated against current state.
- A top-up grants only the missing amount and never overwrites legitimate earlier gains.
- Non-recommended valid Form assignments may be slower but cannot permanently block progression.
- Multiple active Reapings use the same simulation model.
- Reports are informational and are never claim gates.

Do not introduce unseeded or non-reproducible randomness into authoritative simulation. Any future random process must be reproducible from saved state or replaced by a deterministic resolution model approved for the prototype.

## Save/load and time requirements

Save/load integrity is foundational rather than a final polish task.

Persist all state required to reconstruct gameplay, including:

- active Reapings and assignments;
- Threshold state and remaining backlog;
- resources and Souls;
- Form awakening and Mastery;
- Retinue reservations;
- Hall state and production targets;
- Recollections;
- tutorial state, skip state, and completed guarantees;
- unlock and milestone flags;
- report accumulators;
- the authoritative simulation timeline and trusted-time cursor state;
- schema version and transaction state where applicable.

Requirements:

- Re-loading the same committed state must not duplicate output, grants, unlocks, reports, or milestone rewards.
- Save after meaningful irreversible actions and tutorial state changes.
- Offline resolution must be safe across interruption or repeated load attempts.
- Record units explicitly. Do not leave it ambiguous whether a value is seconds, milliseconds, cycles, per-second rate, per-cycle yield, simulation time, or a trusted absolute timestamp.
- Do not call Godot system-clock methods to award gameplay progress. Local calendar time may be used only for clearly non-authoritative display or diagnostics.
- Do not use rendered frame count as elapsed gameplay time.
- Save data must not depend on a scene currently being open.
- Test round trips and relevant boundary transitions whenever persisted state changes.
- The prototype JSON representation is a schema-controlled payload, not a permanent promise about the full-game file container and not a security boundary. Keep runtime-state serialization, payload encoding, container framing, integrity checks, and storage as separate responsibilities.
- Do not claim that JSON, binary encoding, compression, encryption, obfuscation, or a client-held HMAC key makes a local single-player save tamper-proof. Strong prevention requires an external authority. Preserve invalid or suspect files for diagnosis and recovery rather than deleting or overwriting them.

## Data-driven content

Keep content definitions and balance values separate from one-off tutorial or UI scripts.

Forms, Traits, Thresholds, channels, Writs, Retinues, Halls, Recollections, milestones, and guarantees should be represented through reusable definitions and shared rule grammar where practical.

Rules:

- Treat provisional rates, costs, coefficients, durations, backlog sizes, support values, and milestone rewards as configurable data.
- Do not scatter canonical IDs as unrelated string literals.
- Separate stable canonical IDs from player-facing display names.
- Validate missing IDs, duplicate IDs, invalid references, and incompatible assignments clearly.
- Do not hard-code Man-at-Arms or Scribe behavior directly into tutorial presentation when the behavior belongs to Form data or simulation rules.
- Do not hard-code Soldier Company resource reservation into a single button when it belongs to Retinue and inventory rules.
- Avoid building a generic framework substantially larger than the two-Form, two-Threshold prototype requires.

Canonical IDs use the approved uppercase prefix format, for example:

- `FORM_...`
- `THR_...`
- `RET_...`
- `SOUL_...`
- `HALL_...`
- `RES_...`
- `STORE_...`
- `REC_...`
- `WRIT_...`
- `TUT_...`

Use the exact IDs defined in `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`.

## GDScript conventions

Follow the Godot GDScript style guide unless a documented repository rule overrides it.

Use:

- `snake_case` for script filenames, variables, functions, and signals;
- `PascalCase` for `class_name` declarations and named classes;
- `SCREAMING_SNAKE_CASE` for constants;
- static type annotations where they improve correctness and comprehension;
- descriptive names rather than abbreviations;
- early validation and clear error messages for invalid content or state.

Prefer small methods with one understandable responsibility. Extract named helpers when doing so makes a state transition, calculation, or invariant easier to follow.

Do not use clever compact expressions when a more explicit version would be easier for a junior developer to review.

## Code comments and junior-reviewer documentation

Write code under the assumption that a future reviewer may be:

- unfamiliar with Death Idle terminology;
- new to GDScript;
- new to Godot signals, nodes, Resources, and lifecycle callbacks;
- unfamiliar with deterministic idle-game or offline-simulation design.

When choosing between leaving a non-obvious assumption implicit and documenting it, document it.

### Required documentation

For every non-trivial script, add a `##` script description explaining:

- the script's responsibility;
- which state it owns;
- which state it explicitly does not own;
- its important collaborators;
- any relevant lifecycle, determinism, save, or time-unit assumptions.

Use `##` documentation comments for non-trivial reusable:

- classes;
- signals;
- enums;
- constants;
- exported properties;
- public functions;
- domain or simulation methods whose contract is not obvious from the signature.

Use ordinary `#` comments before non-obvious implementation sections to explain:

- why the algorithm is structured that way;
- which invariant it preserves;
- what state boundary is being handled;
- why a seemingly simpler implementation would be unsafe;
- how save/load or offline idempotency is protected;
- why a Godot lifecycle callback or signal connection is required;
- the units and interpretation of important numerical values;
- fallback and recovery behavior.

Comments should explain intent and consequences, not merely translate syntax into English.

Good comment subject:

> Resolve only until the Ration-depletion boundary. Production after that boundary must use the reduced Retinue multiplier, including when the entire interval is resolved offline.

Poor comment subject:

> Subtract elapsed time from remaining time.

Err on the side of fuller explanations for game-specific state transitions, simulation boundaries, persistence behavior, and Godot-specific control flow.

Do not compensate for unnecessarily confusing code with comments. Make the code clear first, then document the reasoning a reader still cannot infer safely.

Update or remove comments whenever behavior changes. A stale explanatory comment is a defect.

Do not leave large blocks of commented-out code. Use version control instead.

## Godot scene and script rules

- Use scenes for presentation composition and reusable UI structures.
- Keep authoritative game rules out of `.tscn`-specific presentation assumptions.
- Avoid making domain and simulation code depend on node paths or whichever screen is currently active.
- Use signals or explicit application-layer coordination to notify presentation of state changes.
- Document signal direction and ownership where it may not be obvious.
- Do not add an autoload merely for convenient global access. An autoload must have a defined ownership role and be approved by the applicable architecture or milestone.
- Do not perform authoritative production once per rendered `_process()` frame.
- UI interpolation may use frame callbacks, but it must display simulation state rather than create a competing source of truth.
- Avoid hidden behavior in scene callbacks. Explain important `_ready()`, `_process()`, `_notification()`, focus, and quit behavior.
- Prefer typed node references and clear failure behavior over repeated unvalidated scene-tree searches.
- Treat `test_main_scene.tscn` as temporary scaffolding until a milestone explicitly replaces or promotes it.

## UI and presentation constraints

- Use 1920 x 1080 as the reference layout.
- Preserve reasonable behavior under ordinary window resizing and stretch scaling.
- Do not build final presentation polish before the underlying state and simulation are proven.
- Use placeholders where final assets do not exist.
- Do not pause production because a menu, dialogue, report, or tutorial overlay is open.
- Backlog, rate, settlement estimate, output channels, support condition, and discovery state are separate concepts and should not be represented as if they were interchangeable.
- Forecast changes caused by a Form, Retinue, Hall, or Recollection should show an understandable before-and-after result when required by the milestone.
- Unknown, Identified, and Charted states must remain distinguishable.
- Presentation may smooth or animate displayed numbers, but authoritative values must remain available immediately.

## Testing and validation

The canonical test commands and manual flows belong in `docs/codex/TESTING_AND_VALIDATION.md`. Owner-run packaging and generated-log rules belong in `docs/codex/OWNER_VERIFICATION_WORKFLOW.md`.

M00 established and verified `.gutconfig.json`, `tools/test/run_gut.sh`, `tools/test/run_gut.ps1`, and the initial GUT suite on Linux/Codex Cloud and the owner's Windows Godot machine.

For executable Godot work:

- Codex Cloud and other Linux environments run `tools/test/run_gut.sh`;
- the project owner runs `tools/test/run_gut.ps1` on the separate Windows machine that has Godot 4.7;
- both wrappers use the same checked-in GUT configuration and must propagate the real process exit code;
- a Codex task may report the Windows check as pending, but must never report it as passed unless the owner actually ran it;
- required Windows, visual, or Steam checks must pass before merge when the milestone says they are merge gates.

When a milestone has owner-run merge gates, the approved prompt must define the owner verification package. Prefer a milestone-specific script under `tools/test/owner/` that runs the automatable checks and writes an ignored log under `tools/test/owner/logs/`. Provide a concise repository-tracked checklist for visual, editor, audio, A/B, or live Steam observations that cannot be automated safely.

Codex does not need to be installed on the Windows Godot machine. Git transfers the branch; the owner executes the committed PowerShell entry point and any manual checklist there. Generated logs may be shared as evidence but are not committed.

Simulation and persistence changes normally require tests for applicable cases such as:

- deterministic repeated resolution;
- online and offline equivalence;
- state-boundary segmentation;
- zero-backlog transition;
- support depletion;
- additive guarantee top-ups;
- exactly-once milestone behavior;
- save serialization and round trip;
- interrupted offline resolution;
- multiple concurrent Reapings;
- report clearing without inventory loss.

Use test fixtures with explicit values and readable setup. Explain unusual fixture state so a junior reviewer can understand why it exists.

Do not claim a test passed unless it was actually run. If the environment cannot execute a required check, state the limitation and provide exact local verification steps.

Never commit a local absolute path to a Godot executable.

## Scope, refactoring, and dependencies

- Limit changes to the stated task and acceptance criteria.
- Do not perform broad unrelated refactors.
- Do not rename large groups of files as cleanup during feature work.
- Do not reformat unrelated files.
- Do not change the engine version, renderer, save format, central architecture, or directory structure without explicit task scope.
- Do not add plugins, test frameworks, third-party libraries, services, storefront SDKs, or network dependencies without approval. GUT 9.7.1 and GodotSteam 4.20 are the only currently approved repository dependencies; their presence does not broaden task scope.
- Do not add production backends, analytics providers, or telemetry services during the prototype.
- Do not replace a simple working solution with a more abstract system solely to anticipate hypothetical future scale.
- Refactoring is appropriate when it is required to preserve a documented boundary, remove duplication in the current task, or make the required behavior safely testable. Explain the reason in the pull request.

## Assets, generated files, and repository hygiene

- Do not commit `.godot/`, exported builds, temporary logs, owner-verification logs, or local editor state.
- Preserve Godot import metadata that is intentionally tracked by the repository.
- Do not manually edit generated binary data.
- Do not overwrite, recompress, rename, or delete source art, audio, fonts, archived design documents, or other binary assets without explicit scope.
- New source asset filenames should use stable, descriptive naming. Do not rename existing assets with spaces or inconsistent casing as part of unrelated work because Godot references may change.
- Keep placeholders clearly identifiable.
- Do not introduce secrets, credentials, tokens, private paths, or machine-specific configuration.
- Record attribution or licensing information when future assets require it.

## Documentation maintenance

A code change is incomplete when it leaves maintained documentation inaccurate.

Update the applicable files in the same pull request:

- `docs/codex/ARCHITECTURE.md` for changed ownership or data flow;
- `docs/codex/IMPLEMENTATION_RULES.md` for changed engineering conventions;
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` for changed IDs, schemas, fields, guarantees, or serialized state;
- `docs/codex/TESTING_AND_VALIDATION.md` for changed commands or validation paths;
- `docs/codex/OWNER_VERIFICATION_WORKFLOW.md` for changed owner-run script, checklist, log, or evidence conventions;
- `docs/codex/DECISIONS.md` for approved architectural or design decisions;
- the applicable design source of truth for an approved design change;
- `docs/codex/MILESTONES.md` for changed status, scope, dependencies, or acceptance criteria.

Do not put milestone-specific detail into this root file.

Do not rewrite historical decisions. Mark superseded decisions and link their replacements.

Do not update an archived DOCX source document as a side effect of a code or Markdown change. Source-document revision is a separate, explicitly scoped task.

## Definition of done

Work is complete only when:

- the requested scope and acceptance criteria are implemented;
- the implementation respects architectural and design invariants;
- provisional values remain configurable;
- relevant automated checks were run and passed, or limitations are disclosed;
- required manual verification was performed and reported;
- save/load behavior was verified when state changed;
- failure, fallback, and deviation paths required by the milestone were considered;
- non-obvious code contains accurate junior-readable comments;
- no new parser, runtime, or resource errors are known;
- no unrelated behavior was silently changed;
- maintained documentation is synchronized;
- remaining assumptions, risks, and deferred work are disclosed.

Do not describe work as complete when an acceptance criterion remains unverified.

## Required final response

At the end of a Codex task, report:

### Implementation completed

A concise description of the resulting behavior.

### Files changed

Every added, modified, renamed, or deleted file, with its purpose.

### Verification

Every automated command and manual flow actually run, with results.

### Assumptions

Any interpretation that was not directly established by authoritative context.

### Known limitations and risks

Anything incomplete, environment-dependent, provisional, or not verified.

### Deferred work

Related work intentionally excluded from the task.

### Suggested next task

One bounded follow-on task, when appropriate.

Be explicit and factual. Do not hide failed checks or present an unverified assumption as a confirmed requirement.
