# Death Idle G0 — Development Governance Findings, Pivots, and Resulting Actions

**Status:** Owner-approved historical decision and anti-drift record
**Effective date:** 2 August 2026
**Revision:** 1.1 — architect-lane session separation clarified
**Document role:** Durable rationale for the major project-governance, context-routing, workflow, review, and model-selection pivots made before returning to game implementation
**Applies to:** Future architect sessions, handovers, repository-documentation realignment, milestone planning, and development-workflow maintenance
**Use with:**
- [Development environment scope charter](DEVELOPMENT_ENVIRONMENT_SCOPE_CHARTER.md);
- [Standard milestone slice workflow](STANDARD_MILESTONE_SLICE_WORKFLOW.md);
- the latest dated operational bootstrap;
- current repository sources of truth, decisions, milestones, and active slice packet.

---

## 1. Purpose

Death Idle uses an **architect lane** with three deliberately separated chat roles, plus several narrow Codex and verification contexts.

- The **planning architect** is the long-lived, continuity-sensitive context.
- The **scope assessor architect** is a fresh, transactional context for one candidate packet or material planning revision.
- The **triage architect** is a fresh, transactional context for one implementation PR and its review/correction lifecycle.

All three architect roles may use the same ChatGPT Enterprise subscription and Sol Pro reasoning. Context separation—not account separation—is the control. The scope assessor and triage architect are normally disposed after their bounded responsibility ends.

The planning architect must retain broad product, architecture, history, workflow, and repository context over many decisions. Implementation, review, correction, verification, scope-assessment, and PR-triage actors should normally operate on one bounded packet, task, or exact pull-request head. This difference creates a specific continuity risk:

> When the architect session reaches context or memory limits, uncodified reasoning can be lost even though repository code and transactional agent work remain intact.

This record exists to prevent that loss. It captures the findings that caused major pivots, the resulting owner-approved actions, and the rules that future architect sessions must preserve. It is not a transcript. It records decisions, rationale, consequences, and the next required work.

Mutable operational facts—current branches, SHAs, pull requests, CI runs, credentials, and the immediate next command—belong in the latest dated bootstrap, not in this stable record.

---

## 2. Project and tooling model

The ultimate goal is to develop and release **Death Idle**.

The project distinguishes three layers:

| Layer | Meaning | Lifetime |
|---|---|---|
| **Death Idle** | The game, content, assets, tests, builds, releases, and player-facing behavior | Product lifetime |
| **Development environment and workflow tooling** | The durable planning, implementation, testing, review, correction, verification, integration, and release system | Full development and maintenance lifecycle |
| **Environment-bootstrap scaffolding** | Temporary audits, probes, one-off setup transactions, and installation/configuration machinery used to establish the durable environment | Primarily setup; later freeze, archive, simplify, or remove |

The development environment is not disposable scaffolding. It is long-lived tooling intended to support more than a year of development. The temporary scaffolding is the machinery used only to construct or validate that environment.

This distinction governs all later scope decisions.

---

## 3. Historical trajectory

### 3.1 Ad-hoc prototype development exposed workflow failure

The initial prototype used:

- one ChatGPT session for architecture and design;
- one Codex context for implementation, review, bug fixing, and related code work.

That arrangement was too concentrated. It produced long regression chains, weak role separation, repeated corrections, and insufficiently independent evidence.

**Resulting pivot:** Pause further prototype implementation and establish a durable development environment with explicit roles, deterministic tests, independent review, bounded slices, and owner-controlled integration.

### 3.2 Environment setup became excessively manual

During setup, the owner repeatedly copied commands into terminals and returned large output blocks. This was initially useful for discovering Windows, PowerShell, Git, credential, sandbox, and GitHub edge cases. Over time, however, manual execution continued beyond the point where it added meaningful security.

**Resulting pivot:** Preserve human authorization at consequential boundaries while moving deterministic checks and ordinary feature-branch operations into narrow, auditable scripts and helpers.

### 3.3 Setup formalism began to exceed owner needs

Owner-facing instructions included script hashes, byte lengths, exhaustive guards, expected metadata, and full success schemas even when the owner’s only meaningful action was to run one all-or-nothing command and return its output.

**Resulting pivot:** Use a concise owner format—**Purpose / Run / Return / Stop only if**—and keep internal guards inside the script, architect analysis, or technical evidence.

### 3.4 Fixed correction-round rules discarded potentially converging work

Earlier workflow language treated a third material review finding as an almost automatic terminal event. That risked abandoning otherwise sound pull requests when the remaining defects were local and testable.

**Resulting pivot:** After two substantial correction rounds, require an explicit convergence assessment. Continue bounded corrections when findings are local, understood, testable, and within scope. Split or stop only when evidence indicates a systemic architecture, ownership, scope, or oracle problem.

### 3.5 PR #23 exposed a real architecture problem

PR #23 attempted to persist a complete future report graph before the legal runtime transition owners were stable. It persisted mutually derivable counters, cursors, sequences, endpoints, and totals; runtime and wire validators duplicated semantics; repeated reviews continued to expose new inconsistency classes.

This was not merely a process failure. It was a genuine modeling and ownership failure.

**Resulting pivot:** Define and prove the normalized runtime ledger and its legal transitions first, derive redundant values, and persist the stable representation only afterward. The provisional replacement sequence became:

```text
M04E2R1 — normalized live report ledger and committed-run ingestion
M04E2R2 — snapshot, history, retention, and detached reads
M04E2P1 — GameState integration, schema-v4 migration, and persistence
M04E2B  — atomic simulation/report coordinator and final M04 harness
```

### 3.6 The development environment became sufficient

After governance, CI, publication, review, owner-verification, integration, post-merge validation, and cleanup paths were proven, no additional environment component remained a prerequisite for returning to the game.

**Resulting pivot:** Close development-environment setup as a blocking project phase. Retain durable tooling; freeze or defer bootstrap-only expansion; resume game architecture and milestone planning.

### 3.7 Documentation and context routing emerged as the next risk

A review of the repository’s game-development instructions showed that root and task-level context had become too broad, temporally mixed, and repetitive. The repository still pointed toward the pre-PR-#23 M04E2A2 sequence. Implementers were instructed to read large portions of design, architecture, decisions, milestones, testing, history, and failed-branch material for one slice.

**Resulting pivot:** Before implementing M04E2R1, realign repository authority and replace broad implementation prompts with lean, versioned slice packets and exact context manifests.

---

## 4. Findings and resulting actions ledger

### G0-01 — Durable tooling and bootstrap scaffolding were conflated

**Finding**

The phrase “scaffolding” was being used ambiguously. It could be read as applying to the entire development environment rather than only to the machinery used to construct it.

**Risk**

A later session could prematurely dismantle durable role separation, testing, review, CI, publication, or owner-verification tooling on the mistaken belief that all setup work was temporary.

**Owner-approved action**

- Treat the development environment as durable project tooling.
- Treat one-off setup probes, audits, migration scripts, and environment-construction transactions as bootstrap scaffolding.
- Classify ambiguous artifacts by recurring use, security value, owner-burden reduction, and maintenance cost.

**Guardrail**

A setup artifact is retained only when it serves ordinary game-development work or a recurring consequential boundary. Technical sophistication alone is not a reason to keep it.

---

### G0-02 — Manual repetition was mistaken for security

**Finding**

The owner manually executed and transferred many deterministic commands whose safety properties were already enforceable by exact scripts and narrow credentials.

**Risk**

This increased copy/paste errors, command-transport defects, cognitive burden, and orchestration time without materially improving the trust boundary.

**Owner-approved action**

- Concentrate human authorization at consequential boundaries.
- Automate deterministic work inside those boundaries.
- Use narrow, fail-closed, project-specific helpers rather than general host-shell access.
- Keep owner-only authority for `main` integration, credentials, governance, destructive cleanup, force operations, exceptional permissions, and spending.

**Guardrail**

Manual execution is a fallback for platform or sandbox limits, not the desired steady state for ordinary feature-branch work.

---

### G0-03 — Owner-facing instructions were too verbose

**Finding**

Routine publication steps exposed script identities, byte lengths, exhaustive preconditions, internal transaction checks, and complete expected metadata even when the owner only needed to download one script, run one command, and return the output.

**Risk**

Actionable instructions were obscured by evidence intended for the architect, not the operator.

**Owner-approved action**

Use the default format:

```text
Purpose
Run
Return
Stop only if
```

Expose expected output only when it is needed to make a safe next decision.

**Guardrail**

Internal checks remain required, but they belong in scripts, automated evidence, or architect analysis unless the owner must inspect them.

---

### G0-04 — The correction-stop rule was too absolute

**Finding**

Earlier workflow language treated additional P1/P2 findings after two rounds as presumptive grounds for abandoning the pull request.

**Risk**

Converging work could be discarded merely because another bounded defect was found.

**Owner-approved action**

After two substantial correction rounds:

1. pause;
2. perform a convergence assessment;
3. continue on the same pull request when findings are local, understood, regression-testable, and within the existing design;
4. split or redesign only when evidence shows systemic ownership, architecture, scope, or oracle failure.

**Guardrail**

Round count is a diagnostic signal, never the sole disposition rule.

---

### G0-05 — Root `AGENTS.md` became a full technical manual

**Finding**

The root instruction file accumulated source hierarchy, workflow, platform rules, prototype scope, architecture, simulation invariants, persistence rules, content rules, GDScript conventions, documentation standards, UI constraints, testing policy, and refactoring restrictions. The project configuration raised the instruction-size ceiling because the root file was already near the default limit.

**Risk**

Every Codex task received excessive universal context. Root rules duplicated specialist documents and made it harder to distinguish truly global constraints from subsystem guidance.

**Resulting action**

G2 must reduce root `AGENTS.md` to stable rules needed by almost every task:

- project identity and source precedence;
- global technology and dependency constraints;
- high-level ownership boundaries;
- deterministic/save-safe/non-speculative principles;
- branch, PR, and owner-integration rules;
- canonical validation entry points;
- requirement to follow an approved slice packet;
- conflict and scope-growth stop rules.

Detailed subsystem rules remain in canonical specialist documents or a small number of justified nested instruction files.

**Guardrail**

Do not create nested instructions for every directory. Add them only where stable subsystem rules materially differ from global rules.

---

### G0-06 — Mandatory implementation context was too broad

**Finding**

Non-trivial tasks were instructed to read both design sources, architecture, implementation rules, data contracts, testing, decisions, owner verification, desktop workflow, milestone definitions, prompts, current code, tests, and sometimes several historical planning documents and failed PRs.

**Risk**

The implementer had to retain too many future concerns and historical constraints at once. This encouraged speculative extension points, over-engineering, duplicated contracts, and lengthy pre-edit reports.

**Resulting action**

G2 must introduce a lean, versioned slice packet with an embedded context manifest that names exact:

- document sections;
- requirement labels;
- decision IDs;
- code paths;
- tests and fixtures;
- explicitly excluded historical sources.

The implementer reads the packet and only the referenced context.

**Guardrail**

Full-document reading is exceptional. A packet should normally reference no more than the small set of authorities needed to implement and disprove defects in the current slice.

---

### G0-07 — Current, deferred, superseded, and historical contracts were mixed

**Finding**

Canonical documents contained earlier outlines, current implemented contracts, approved future contracts, superseded decisions, historical evidence, and milestone-specific plans in the same reading path. Report-state terminology and shapes appeared in more than one form.

**Risk**

An agent could treat an obsolete outline as current authority, merge future semantics into the present slice, or attempt to satisfy mutually incompatible representations.

**Resulting action**

G1 and G2 must normalize documentation around four clearly marked bands:

1. current implemented contract;
2. approved but not implemented contract;
3. open decisions;
4. superseded or historical material.

A named type should have one current authoritative definition. Historical shapes remain available only as explicitly historical evidence.

**Guardrail**

Do not silently reconcile duplicate definitions. Remove or clearly supersede stale canonical text when the maintained contract changes.

---

### G0-08 — Repository authority remained stale after PR #23

**Finding**

`MILESTONES.md`, `DECISIONS.md`, report contracts, testing documentation, M04E2A2 planning, and the M04E2A2 implementation prompt still presented schema-v4 report persistence as the active next slice.

**Risk**

A new implementation task could correctly follow repository authority and still restart the architecture that PR #23 proved unsound.

**Resulting action**

G1 is required before any report implementation. It must:

- record the PR #23 outcome;
- add the new accepted architecture decision;
- replace the A2/A3/A4 sequence with R1/R2/P1/B;
- update architecture, contracts, milestones, testing, and decision status;
- mark the former M04E2A2 plan and prompt superseded;
- retain PR #23 only as forensic and regression evidence.

**Guardrail**

No M04E2R1 implementation packet is approved while repository authority still points to M04E2A2.

---

### G0-09 — Failed branches were used as direct implementer context

**Finding**

Implementation prompts asked Codex to inspect failed PRs for useful scenarios while warning it not to copy their production designs.

**Risk**

The failed decomposition remained salient and could anchor the implementer toward the same structures, even when described as prohibited reuse.

**Resulting action**

The architect or planning actor reads failed branches and converts valid lessons into:

- current requirements;
- named regression scenarios;
- malformed-input cases;
- explicit exclusions.

The implementer normally receives those distilled requirements and does not inspect failed production code.

**Guardrail**

Direct failed-branch inspection by an implementer requires one exact forensic question that cannot be answered from maintained current documentation.

---

### G0-10 — The former M04E2A2 prompt prescribed too much future structure

**Finding**

The prompt simultaneously specified architecture, runtime classes, schema, migration, field propagation, malformed matrices, fixtures, traces, owner tooling, review limits, and future exclusions. It effectively encoded a complete future graph rather than the smallest exercisable transition.

**Risk**

The implementer was incentivized to build a persistence-ready framework before runtime mutation, snapshot, retention, and read ownership had been exercised.

**Resulting action**

The replacement R1 packet must define:

- one normalized live ledger;
- one legal ingestion transition;
- exact stored-versus-derived decisions;
- bounded no-mutation and idempotency cases;
- no persistence;
- no history;
- no public read/snapshot policy beyond what R1 requires;
- no UI or trusted-time orchestration.

Private class and file layout should be constrained only where ownership or interoperability requires it.

**Guardrail**

A task packet defines observable behavior, authority, acceptance, and exclusions. It does not pre-design every helper solely to anticipate later slices.

---

### G0-11 — Parallel semantic oracles repeatedly drifted

**Finding**

Several setup and report attempts created multiple partial representations or validators that tried to prove each other equivalent. Review repeatedly found gaps in fields, casing, conditionals, counters, or identity semantics.

**Risk**

Each additional authority increased the number of relationships that had to be kept synchronized and expanded the false-positive PASS surface.

**Resulting action**

Prefer:

- one authoritative runtime contract;
- derived values instead of persistently duplicated values;
- executable validation rather than hand-written partial evidence;
- one transition owner that creates mutation and explanatory facts from the same provenance;
- independent tests that challenge the authority rather than reimplement it.

**Guardrail**

Do not add another schema, summary, counter, journal, or oracle unless it has a distinct required consumer and a credible independent validation strategy.

---

### G0-12 — Information movement depended too much on the owner

**Finding**

The owner often acted as a manual message bus between architect, implementer, reviewer, fixer, CI, and GitHub.

**Risk**

Information could be truncated, reformatted, misplaced, or left only in chat history.

**Resulting action**

Use canonical channels:

- repository documentation for durable product, architecture, decisions, and approved packets;
- one branch and PR for implementation and corrections;
- CI for automated evidence;
- PR review threads for findings and dispositions;
- generated logs plus a concise owner statement for owner-only verification;
- chat for planning discussion, approvals, and temporary correction packets.

**Guardrail**

The owner still triggers consequential transitions, but should not manually transfer ordinary implementation state that Git, GitHub, CI, or a tracked packet can carry.

---

### G0-13 — Model selection conflated two separate subscriptions and roles

**Finding**

The original model selector optimized heavily for the metered coding account and treated architecture routing as part of the same budget.

The actual project has two distinct lanes:

1. the architect uses a separate ChatGPT Enterprise subscription and works almost exclusively on Sol Pro;
2. Codex implementation uses a separate ChatGPT/Codex Pro plan with its own limits and budget.

The architect lane does not consume the coding plan’s daily or weekly allowance.

**Resulting action**

- Default the architect/planning lane to **Sol Pro** for broad reasoning, long-term continuity, architecture, milestone decomposition, triage, and handover.
- Do not downgrade the architect merely to preserve Codex quota.
- Continue cost- and quota-aware routing only for transactional Codex actors.
- Maintain the coding-lane selector separately and revalidate it when OpenAI pricing, retirement dates, or plan behavior changes.

**Guardrail**

Concise architect outputs remain desirable for clarity, transferability, and handover—not because the architect must conserve the Codex budget.

---

### G0-14 — Architect-session continuity is a first-class project risk

**Finding**

The architect is the only actor expected to retain broad multi-month context. Other sessions are intentionally narrow and replaceable. Technical context limits therefore threaten planning continuity more than implementation continuity.

**Resulting action**

Create and maintain a durable architect continuity bundle:

1. development-environment scope and anti-drift charter;
2. this governance findings and actions record;
3. the standard milestone workflow specification;
4. current repository decisions, milestones, and architecture;
5. latest dated operational bootstrap;
6. active planning memo and approved slice packet;
7. explicit supersession and prohibited-reuse list.

Pillar decisions must be written into durable records before the architect proceeds to the next major phase.

**Guardrail**

A future architect session must be able to reconstruct the project’s current direction from durable records without relying on the predecessor’s hidden reasoning or chat transcript.

---

### G0-15 — Setup completion needed an explicit stop condition

**Finding**

The setup roadmap could be interpreted as an obligation to implement every proposed helper, schema, static-analysis tool, or workflow component.

**Risk**

Environment work could become an open-ended second product and indefinitely delay game development.

**Resulting action**

The environment is declared sufficient when the recurring development loop can reliably provide:

- authoritative context;
- bounded planning;
- one branch/PR implementation;
- deterministic validation and CI;
- independent review;
- bounded corrections;
- concise exact-head owner verification;
- owner integration;
- post-merge validation and recovery.

Remaining enhancements are added later only when demonstrated recurring friction justifies them.

**Guardrail**

Sufficiency takes priority over roadmap completeness.

---

## 5. Resulting work sequence

The owner approved the following sequence before M04E2 implementation resumes:

```text
G0 — codify governance findings/actions and the standard milestone workflow
G1 — realign report architecture and repository authority after PR #23
G2 — refactor instruction routing and the milestone packet format
G3 — draft and approve M04E2R1 under the new context model
G4 — implement M04E2R1
```

### G1 — Architecture and repository-authority realignment

Required outcomes:

- PR #23 historical/postmortem record;
- accepted replacement architecture decision;
- normalized runtime-ledger-first principle;
- R1/R2/P1/B milestone sequence;
- updated architecture, data contracts, testing, decisions, and milestones;
- former M04E2A2 planning and prompt marked superseded;
- no implementation code.

### G2 — Instruction and context-routing refactor

Required outcomes:

- slimmer root `AGENTS.md`;
- exact source hierarchy preserved;
- lean slice packet with embedded context manifest;
- current/deferred/historical separation;
- updated workflow and convergence rules;
- historical documents excluded from routine implementer context;
- only the smallest justified nested instruction files.

### G3 — M04E2R1 planning

Required outcomes:

- one primary owner;
- one normalized live-ledger result;
- explicit stored-versus-derived table;
- one ingestion decision table;
- bounded malformed/no-mutation/idempotency cases;
- exact context manifest;
- reviewable scope and test oracle;
- owner approval.

### G4 — M04E2R1 implementation

Implementation begins only after G1–G3 are merged or otherwise owner-approved as authoritative.

---

## 6. Model-lane policy

### 6.1 Architect and planning lane

**Subscription:** Separate ChatGPT Enterprise account
**Default model:** Sol Pro
**Typical session:** Long-lived and broad
**Budget relationship:** Does not consume the separate Codex Pro plan’s daily/weekly allowance
**Responsibilities:**

- product and architecture synthesis;
- decision records;
- milestone decomposition;
- context-manifest authoring;
- long-range architecture and milestone continuity;
- escalation decisions returned by scope assessment or PR triage;
- workflow maintenance;
- handover and continuity records.

Independent scope assessment and routine PR triage are separate architect chats by default. The planning architect receives their durable conclusions rather than sharing their full live context.

The architect should use the strongest appropriate reasoning mode by default. Economy is not the primary routing constraint in this lane.

### 6.1.1 Architect-session separation

The architect lane uses three context profiles:

| Role | Default lifetime | Independence rule | Durable output |
|---|---|---|---|
| Planning architect | Multiple milestones until context limits require handover | Must not be the sole assessor or routine triage authority for its own packet | Decisions, planning packages, handovers |
| Scope assessor architect | One packet or material revision | Fresh chat; receives the candidate packet and exact authorities, not the planning transcript | Scope assessment: approve, revise, split, or exception recommendation |
| Triage architect | One implementation PR through its review/correction lifecycle | Fresh chat; receives the approved packet, exact PR head/diff, findings, and evidence, not the implementer transcript | Finding classifications, correction packets, convergence/escalation record |

A minor packet revision may return to the same scope-assessor chat. A material architecture change requires a fresh assessment. The triage chat should normally remain alive across all review rounds for one PR so it can judge convergence consistently, then be disposed after merge or closure. It escalates systemic product, architecture, or milestone questions back to the planning architect.

### 6.2 Transactional Codex lane

**Subscription:** Separate ChatGPT/Codex Pro plan
**Typical session:** One bounded task, branch, PR head, correction, or verification activity
**Routing principle:** Use the lowest model/effort that can reliably satisfy the exact task and oracle.

Current policy direction:

| Codex task | Normal tier |
|---|---|
| Read-only orientation, exact deterministic edit, predefined checks | Luna, Light or Medium |
| Small correction with a direct regression oracle | Luna, Medium |
| Standard bounded gameplay implementation | Terra, Medium |
| Simulation, persistence, migration, transactional or cross-layer implementation | Terra, High |
| Exceptionally difficult coding problem after a scoped attempt | Sol, High |
| Micro-interaction or symbol lookup | Spark only when low-risk and useful |

The exact commercial rate card and model availability are time-sensitive. Revalidate this table against current official OpenAI information before a material selector update.

### 6.3 Review lane

GitHub `@codex review` uses the platform-selected review model. Control:

- exact head;
- review scope;
- primary risk boundary;
- output ceiling;
- material-finding definition;
- explicit exclusions.

Do not imply that a particular implementation model was selected when the review platform chooses it.

### 6.4 Owner lane

The owner does not need an AI model for deterministic commands. The owner supplies:

- approvals;
- product decisions;
- exact-head verification;
- integration and destructive authorization;
- observed interactive results.

---

## 7. Architect continuity protocol

### 7.1 Pillar-document rule

The following decisions must be codified before work proceeds materially beyond them:

- source precedence or authority changes;
- architecture ownership changes;
- milestone-sequence changes;
- stored-versus-derived changes;
- role or workflow changes;
- review and convergence-policy changes;
- model-lane changes;
- owner-only boundary changes;
- task-context strategy changes;
- declaration that setup is complete or reopened.

### 7.2 Stable versus mutable records

**Stable records**

- scope and anti-drift charter;
- governance findings and actions record;
- standard milestone workflow;
- accepted decision records;
- architecture and data contracts.

**Mutable records**

- latest bootstrap;
- current main and branch SHAs;
- active PR and CI state;
- unresolved findings;
- immediate next action;
- currently approved slice packet.

### 7.3 Required architect handover bundle

A new architect session should receive, in this order:

1. latest owner instruction;
2. scope and anti-drift charter;
3. this G0 governance record;
4. standard milestone workflow;
5. latest dated bootstrap;
6. current repository `DECISIONS.md`, `MILESTONES.md`, and relevant architecture sections;
7. active planning memo and approved slice packet;
8. exact current GitHub/repository state when needed.

### 7.4 Handover content requirements

A handover must state:

- exact date;
- current phase;
- last completed bounded operation;
- current `main`, active branch, PR, and CI facts;
- accepted architecture and milestone sequence;
- active packet version;
- open decisions and blockers;
- current findings requiring disposition;
- superseded prompts/plans;
- prohibited restoration or reuse;
- the single next bounded topic;
- which subscription/model lane applies to each actor.

### 7.5 Anti-drift test for a new architect session

Before issuing work, the new architect must be able to answer:

1. What is the ultimate project goal?
2. Which tooling is durable and which work was bootstrap-only?
3. What is the current game-development milestone sequence?
4. Which documents are current authority?
5. Which documents are historical or superseded?
6. What is the exact next bounded decision or operation?
7. Which actor owns it?
8. Which owner-only boundary applies?
9. What would constitute a systemic stop versus another bounded correction?
10. Which model/subscription lane applies?

If these cannot be answered from durable records, the handover is incomplete.

---

## 8. Supersession and anti-drift statements

This record supersedes prior wording that:

- treated the entire development environment as temporary scaffolding;
- made the old setup roadmap mandatory;
- required verbose owner instructions for internal script controls;
- treated a fixed correction-round count as automatic abandonment;
- treated M04E2A2 persistence as the current next slice;
- used failed branch implementations as normal implementer context;
- routed the Enterprise architect and metered Codex actors under one budget;
- assumed important pivots could remain only in an architect chat transcript.

The following remain historical evidence only unless explicitly re-approved:

- the original monolithic report-persistence sequence;
- former M04E2A2 planning and prompt;
- PR #23 production implementation;
- the initial model selector’s obsolete price comparisons;
- setup-era command-by-command operating patterns.

---

## 9. Source and provenance record

This document codifies owner-approved conclusions drawn from:

- the earlier and latest development-environment bootstraps;
- the development-environment purpose and anti-drift charter;
- the manual-automation assessment;
- the verbose publication-step example;
- the model-selector document and later pricing reassessment;
- repository `AGENTS.md`, `.codex/config.toml`, architecture, data contracts, implementation rules, testing, decisions, milestones, desktop workflow, and owner-verification workflow;
- the M04E2 failed-attempt postmortem;
- PR #23 architecture conclusions;
- the completed PR #30 workflow and setup-sufficiency reassessment;
- the owner clarification that the architect uses a separate Enterprise/Sol Pro lane.

This is a historical governance record. Current mutable repository state must still be verified through the latest bootstrap and repository/GitHub evidence.
