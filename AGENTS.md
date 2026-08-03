# Death Idle repository instructions

## Project posture

Death Idle is a Godot 4.7, GDScript-only, 2D UI-led idle/incremental management game. The current target is the playable 0-90 minute prototype. This is a prototype-first, solo-developed project. Prefer clear, deterministic, testable, save-safe solutions over launch-scale frameworks, speculative abstractions, or unrelated cleanup.

## Authority and conflict handling

Apply requirements in this order:

1. the latest explicit instruction in the current task or from the project owner;
2. `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md` for prototype sequence, behavior, guarantees, first-session content, and acceptance;
3. `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md` for broader rules, terminology, product direction, and expansion-compatible constraints;
4. accepted records in `docs/codex/DECISIONS.md`;
5. existing repository behavior and maintained documentation;
6. implementation recommendations.

Do not silently reconcile applicable sources. Identify the conflict, its practical consequence, and any decision that resolves it. Stop for an owner decision when the hierarchy does not resolve it.

A current owner-approved versioned slice packet is the task authority within its stated scope. Read this root file, the packet, and only the packet's exact context-manifest entries, code paths, tests, fixtures, and nested instructions. Do not routinely load failed branches, superseded prompt bodies, architect transcripts, the full decision log, the full milestone map, or full design sources unless the packet names an exact part or a concrete unresolved conflict requires escalation. Treat those sources as exceptional context, not default implementation input.

## Technology and dependency boundary

- Use Godot 4.7 and GDScript only.
- GUT 9.7.1 and GodotSteam 4.20 are pinned repository dependencies. Do not update, replace, auto-download, re-vendor, or broaden their use during unrelated work.
- GodotSteam is approved only for the separately scoped trusted-time adapter. Keep authoritative state, simulation, persistence meaning, and content independent of storefront APIs.
- Do not add C#, .NET files, native libraries, plugins, frameworks, services, network dependencies, analytics providers, or storefront integrations without explicit approved scope.
- Do not commit machine-specific executable paths, credentials, secrets, generated logs, `.godot/`, or exported builds.

## Ownership boundaries

- **Authoritative state:** typed scene-independent runtime state owns gameplay facts. UI nodes, open screens, animations, and scene callbacks are never the sole authority.
- **Simulation:** receives explicit elapsed time and validated dependencies. It owns deterministic production rules and must not read clocks, input, scenes, files, or platform APIs.
- **Presentation:** observes committed read models and issues explicit commands. It never grants resources, completes milestones, reserves inventory, or calculates competing production.
- **Tutorial:** observes conditions, presents guidance, and requests ordinary commands or approved guarantees. It does not duplicate another subsystem's rules or execute skipped strategic choices.
- **Persistence:** owns explicit primitive mapping, schema validation, migration, codec and atomic-storage boundaries. A serialized-meaning change requires an approved schema/compatibility plan and synchronized tests/contracts.
- **Reports:** explain already-applied gains and never claim-gate output. Follow the current accepted report architecture and packet; do not infer a service, API, field set, or persistence boundary from historical material.

Detailed engineering contracts belong in `docs/codex/IMPLEMENTATION_RULES.md`, maintained architecture/contracts, and the active packet rather than in this root router.

## Implementation principles

- Validate before mutation; commit coherent changes once; preserve source state on failure.
- Authoritative elapsed-time work uses explicit integer milliseconds, injected monotonic/trusted-time adapters at their approved boundaries, and deterministic ordering. Never award progress from the local wall clock, timezone, file timestamps, rendered frames, or unseeded randomness.
- Follow accepted single-provenance transaction rules when a task changes authoritative state: private candidate mutation and explanatory facts share one owner; detached results are observations, not commit inputs.
- Keep state required for exact continuation; derive display-only values. Keep provisional balance in content or fixtures.
- Use canonical IDs rather than display text. Keep authored definitions immutable during play.
- Extend save fixtures, migrations/compatibility handling, tests, and maintained documentation in the same approved slice whenever authoritative meaning changes.
- Implement only the current packet. Do not import later-slice behavior because it is visible, create speculative extension systems, or perform broad unrelated refactors/reformatting.
- Write junior-readable GDScript and reasoning comments as required by `docs/codex/IMPLEMENTATION_RULES.md`.

## Slice, branch, review, and owner authority

One implementation slice uses one owner-approved packet, one feature branch, and one pull request. Start from verified current `main`; never commit or push directly to `main`. All implementation and correction commits for the slice remain on the same branch and PR unless the owner explicitly authorizes replacement.

Material correction rounds normally use a fresh bounded fixer context. A trivial mechanical correction may stay in the original implementation task only when it is explicitly identified, directly provable, and does not expand authority or scope.

Agents must not merge or auto-merge, close a PR, approve their own PR, delete branches, force-push, rewrite history, or create a replacement PR. These actions require explicit owner authority. Ordinary publication is non-force. Use `docs/codex/CODEX_PR_BRANCH_RECOVERY.md` only for a deliberately authorized exceptional recovery; do not generalize that path into routine work.

Planning packets require fresh independent scope assessment. PR-lifetime triage is performed by a fresh triage context, not by the packet author or routine implementer. After two substantial correction rounds, pause for an evidence-based convergence assessment: continue when remaining findings are local, understood, testable, and within the design; stop, split, or redesign only on affirmative architecture, ownership, scope, oracle, or persistent-root-cause evidence.

## Validation and stop rules

Canonical executable validation is defined in `docs/codex/TESTING_AND_VALIDATION.md` sections 3-4:

- Linux/Codex: `tools/test/run_gut.sh`;
- owner Windows machine: `tools/test/run_gut.ps1`.

Run only the checks required by the packet and changed surface. Never claim a check passed unless it was actually run. Keep owner-run, visual, editor, audio, Steam, and exact-head evidence pending until explicitly supplied. Documentation-only packets may define documentation/CI checks instead of GUT when no runtime surface changes.

Stop and report before proceeding when:

- the live repository materially differs from the packet baseline;
- a required authority or dependency is missing, stale, or contradictory;
- the work needs another primary owner, risk dimension, integration seam, changed path, schema transition, or behavior outside the approved packet;
- an approved required suite or check remains red, or the required evidence cannot be established;
- acceptance cannot be proved with the packet oracle;
- a byte/output ceiling cannot be met without ambiguity or omission;
- the branch is based on stale `main`, publication would require force, or repository state is unexpectedly dirty;
- a prompt/packet defect, non-converging design, or owner decision is required.

Do not reset, discard, overwrite, or reorganize legitimate work merely to match an older snapshot.

## Handoff

At the packet's hard stop, report concisely and factually:

- resulting behavior or documentation outcome;
- exact files changed and purpose;
- commands/checks actually run and results;
- branch, PR, and exact head when published;
- assumptions, pending owner evidence, known limitations/risks, and deferred work.

Do not describe work as complete while an acceptance criterion or merge gate is failed, blocked, or unverified. Stop without merge.
