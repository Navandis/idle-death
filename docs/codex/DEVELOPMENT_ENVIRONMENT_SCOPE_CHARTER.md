# Death Idle Development Environment Purpose, Scope, and Anti-Drift Charter

**Status:** Owner-approved operating charter
**Effective date:** 2 August 2026
**Document role:** Stable purpose, scope, proportionality, interaction, review, and handover guardrails for completing and operating the Death Idle AI-assisted development environment
**Applies to:** Development-environment setup, workflow tooling, future setup handovers, and later improvements to the recurring development process
**Use with:** The latest dated setup bootstrap for mutable repository, branch, pull-request, CI, credential, and machine state

---

## 1. Core purpose

The ultimate goal is, and remains, to develop **Death Idle**.

The project initially used an ad-hoc arrangement in which one ChatGPT session handled architecture and design while one Codex context handled most code-related work, including implementation, review, correction, and testing. That arrangement proved too vulnerable to long regression chains, incomplete review separation, and repeated correction cycles.

Further prototype development was therefore paused so a proper development environment could be established with:

- clear authority and source-of-truth rules;
- defined actor roles and responsibility boundaries;
- bounded implementation slices;
- deterministic automated testing;
- independent review;
- controlled correction workflows;
- owner-governed integration;
- durable evidence and recovery paths.

This development environment is not a temporary diversion from the game. It is long-lived project tooling intended to support the game throughout implementation, playtesting, release preparation, patching, and maintenance. That lifecycle may extend for more than a year.

The temporary element is the **bootstrap scaffolding used to construct and validate that environment**.

---

## 2. Corrected terminology and scope model

The project uses three distinct layers.

| Layer | Purpose | Expected lifetime |
|---|---|---|
| **Death Idle** | The game itself: production code, content, assets, tests, builds, releases, and player-facing behavior | Product lifetime |
| **Development environment and workflow tooling** | The durable system used to plan, implement, test, review, correct, integrate, and release the game | Throughout development and maintenance |
| **Environment-bootstrap scaffolding** | Temporary scripts, probes, audits, transactions, and evidence used to install, configure, validate, or improve the development environment | Primarily during setup; later frozen, archived, simplified, or removed |

The following interpretation is explicitly rejected:

> The entire development environment is disposable scaffolding that should be abandoned as soon as coding resumes.

The correct interpretation is:

> The development environment is durable tooling. The machinery used only to build or validate that tooling is scaffolding.

Some artifacts created during setup may begin as scaffolding and later become durable tooling. Their classification depends on recurring use, not on when they were created.

---

## 3. Authority and relationship to other project documents

This charter governs **setup purpose, proportionality, owner interaction, review convergence, and anti-drift discipline**. It does not replace the game’s design or engineering sources of truth.

Apply authority by subject:

### Game behavior and product direction

Use, in order:

1. the latest explicit owner instruction;
2. `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md` for prototype sequence, safeguards, and acceptance;
3. `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md` for broader product direction and idle-model invariants;
4. accepted entries in `docs/codex/DECISIONS.md`;
5. maintained repository behavior and documentation.

### Engineering implementation

Use the maintained repository contracts, especially:

- `AGENTS.md`;
- `docs/codex/ARCHITECTURE.md`;
- `docs/codex/IMPLEMENTATION_RULES.md`;
- `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`;
- `docs/codex/TESTING_AND_VALIDATION.md`;
- `docs/codex/MILESTONES.md`;
- `docs/codex/OWNER_VERIFICATION_WORKFLOW.md`;
- `docs/codex/CODEX_DESKTOP_WORKFLOW.md`.

### Development-environment purpose and scope

Use this charter.

### Current operational state

Use the latest dated setup bootstrap or handover. It owns mutable facts such as:

- current local branch and SHA;
- `origin/main` SHA;
- open pull requests;
- exact CI runs;
- unresolved review threads;
- active credentials and helper identities;
- the next bounded setup operation.

Historical bootstraps remain evidence only. They do not override a newer bootstrap or this charter.

When applicable sources conflict, do not silently reconcile them. State the conflict, the affected decision, and which authority governs it.

---

## 4. Why durable development tooling is necessary for this game

Death Idle is a stateful idle/incremental game whose correctness depends on more than immediate screen behavior. The project includes or plans:

- deterministic elapsed-time simulation;
- common online, offline, forecast, and debug rule paths;
- versioned persistence and migrations;
- exact integer and fixed-point handling;
- transactional state changes;
- save-safe exactly-once progression;
- persistent assignments and long-horizon progress;
- independent presentation and authoritative-state ownership;
- trusted-time boundaries;
- content identity and compatibility contracts;
- recovery from malformed or interrupted state.

Many defects in those areas appear only after long-duration resolution, save/load, migration, reassignment, simultaneous boundaries, correction retries, or platform-specific execution. A single actor functioning as planner, implementer, tester, reviewer, and fixer is therefore not a sufficient steady-state control.

The development environment exists to make the following recurring loop reliable:

```text
design requirement or milestone need
-> architecture and scope decision
-> approved bounded task packet
-> implementation on one feature branch and pull request
-> deterministic local and CI validation
-> independent review
-> bounded correction and regression proof
-> exact-head owner verification where required
-> owner-controlled integration into main
-> post-merge validation and cleanup
```

The environment is successful when this loop supports game development repeatedly with low owner friction and without weakening consequential security or integration boundaries.

---

## 5. Minimum durable capabilities

The durable environment should provide the smallest reliable version of each capability below.

### 5.1 Maintained context and authority

Agents must be able to identify the applicable design, architecture, decision, implementation, testing, and milestone sources without reconstructing requirements from old chat transcripts.

Context should be scoped to the task. The solution is not to remove authoritative documentation, but to avoid loading irrelevant historical material into every narrow operation.

### 5.2 Role separation

The recurring workflow should distinguish, as needed:

- owner and final integration authority;
- architect or planner;
- scope assessor;
- implementer;
- deterministic validation executor;
- independent reviewer;
- finding triage;
- corrective implementer or fixer;
- owner-verification packager;
- release or patch operator.

Not every low-risk task requires a separate person or chat for every role. The controlling principle is that one actor should not be the sole authority for task definition, implementation, evidence interpretation, and final review of material game behavior.

### 5.3 Bounded implementation slices

Each implementation slice should normally have:

- one principal result;
- one primary subsystem owner;
- explicit in-scope and out-of-scope behavior;
- a reviewable change surface;
- deterministic acceptance criteria;
- one branch and one pull request;
- a clear owner handoff.

File counts, line counts, risk dimensions, and review-round counts are planning signals. They are not mechanical reasons to discard otherwise coherent work.

### 5.4 Deterministic validation

The environment must retain automated checks appropriate to the affected behavior, including where relevant:

- focused tests during implementation;
- broader regression tests before handoff;
- import and smoke checks;
- chunking and mode-equivalence tests;
- migration and malformed-input fixtures;
- failure-injection and no-mutation tests;
- CI on feature-branch updates;
- Windows, editor, Steam, visual, audio, or platform checks that hosted CI cannot establish.

AI review is supplemental evidence. It does not replace deterministic tests.

### 5.5 Independent review and correction

Material implementation must receive review from a context that did not serve as the sole implementation authority. Corrections normally remain on the same branch and pull request so history, evidence, and discussion remain coherent.

### 5.6 Low-burden owner verification

Checks that can be executed safely and deterministically should be packaged into one narrow script or command. Interactive checklists should be reserved for observations that cannot be automated meaningfully.

The owner should normally authorize and execute a bounded transaction, not manually reproduce its internal checks one command at a time.

### 5.7 Protected integration boundaries

Durable controls include:

- feature-branch development;
- protected `main` integration;
- normal non-force publication;
- exact-head evidence;
- explicit merge authority;
- controlled credentials;
- recovery procedures;
- post-merge validation.

These controls remain after setup. One-time audits used to establish them do not necessarily remain active.

---

## 6. Classifying an artifact: tooling or scaffolding

Use the following questions whenever a new setup component is proposed or an existing setup artifact is reviewed.

1. Will it be used repeatedly during ordinary game-development pull requests?
2. Does it protect a recurring consequential boundary?
3. Does it remove material recurring owner work or a demonstrated source of error?
4. Does it provide evidence required for implementation, review, testing, release, or recovery?
5. Is its expected maintenance cost lower than the recurring manual burden or risk it replaces?
6. Does it remain useful after environment setup is declared sufficient?

### Classification outcomes

**Durable tooling — retain and maintain**
Use when the artifact supports recurring game-development work. Examples may include canonical test wrappers, CI, branch governance, scoped publication helpers, owner-verification runners, task templates, and maintained context manifests.

**Scaffolding that graduates into tooling**
Use when a setup artifact proves useful in the recurring workflow. Before retaining it, simplify its interface, document its owner, remove bootstrap-only assumptions, and define its maintenance boundary.

**Bootstrap scaffolding — freeze or archive**
Use when the artifact was needed to install, configure, audit, migrate, or validate the environment but has no recurring operational role.

**Obsolete scaffolding — remove**
Use when the artifact duplicates authority, no longer protects a live boundary, or imposes maintenance and cognitive cost without recurring value.

Creation during setup does not automatically make an artifact temporary. Conversely, technical sophistication does not justify keeping an artifact that has no continuing purpose.

---

## 7. Anti-overengineering and scope guardrails

The development environment is a means to produce the game. It must not become a second product.

Every remaining setup task must answer:

1. **Which recurring game-development problem does this close?**
2. **Is the result durable tooling or bootstrap scaffolding?**
3. **What owner burden, defect class, or security boundary does it improve?**
4. **What is the smallest implementation that provides that value?**
5. **What is explicitly outside scope?**
6. **When is this component sufficient?**
7. **What is its retirement, freeze, or reassessment condition?**

Do not add a setup component merely because:

- it completes an architecture diagram;
- an earlier roadmap listed it;
- an existing helper makes a more general framework possible;
- it could support hypothetical future workflows;
- it increases formalism without reducing recurring risk or owner work;
- it automates an operation unlikely to recur;
- it duplicates semantics already owned by another contract, schema, validator, journal, or evidence source.

Prefer:

- narrow project-specific helpers over generalized workflow platforms;
- one authoritative contract over parallel partial oracles;
- explicit readable scripts over configurable meta-frameworks;
- disposable setup transactions over permanent infrastructure when the operation is truly one-off;
- deferring an enhancement until recurring evidence justifies it.

A setup task should stop or return to planning when it begins to require:

- another unapproved authority or subsystem owner;
- another schema or semantic source of truth;
- broad host-shell capability;
- speculative platform abstraction;
- unrelated repository cleanup;
- major complexity whose recurring value is not demonstrated.

The governing principle is **sufficiency over completeness**.

---

## 8. Owner interaction and instruction standard

The owner-facing part of a routine scripted operation should normally contain only the information needed to act safely.

### Default format

```text
Purpose
- One sentence describing the intended result.

Run
- One download or file reference when needed.
- One exact command or one precise UI action.

Return
- The complete terminal output, generated evidence file, or requested result block.

Stop only if
- A condition requiring an owner decision, such as an unexpected credential, UAC, destructive-action, authentication, or approval prompt.
```

### Details normally kept out of owner instructions

Unless the owner must inspect them to make a decision, keep the following inside the script, agent analysis, or technical evidence:

- script byte length;
- script SHA or blob identity;
- exhaustive internal transaction guards;
- every expected metadata field;
- internal preflight and postflight comparisons;
- detailed non-action lists already enforced by the helper;
- complete expected successful output.

Those controls still matter. They should be implemented and reviewed rather than transferred to the owner as repetitive reading.

### Expected output guidance

Show expected output only when the owner needs it to:

- choose the next safe action;
- identify data that must be supplied to another actor;
- distinguish a normal warning from a stop condition;
- confirm that a credential, UAC, or approval prompt must be rejected;
- select between materially different recovery paths.

A routine commit-and-publish operation does not require the owner to review every internal branch, SHA, hash, and postcondition before running one all-or-nothing command.

### Failure behavior

A guarded helper should fail closed, preserve the prior state where practical, and emit a concise reason plus enough evidence for diagnosis. After an automated stop, the owner should not perform ad-hoc manual repair unless a separately reviewed recovery step instructs it.

Where practical, one bounded transaction should require no more than one owner execution and one returned evidence package.

---

## 9. Review and correction convergence policy

Review-round limits are diagnostic guardrails, not automatic abandonment rules.

### Material finding

A finding is material when it identifies a concrete issue such as:

- an accepted invalid state;
- a rejected valid state with practical impact;
- a false-positive test or review PASS;
- a confidentiality or credential leak;
- a trust-boundary or ownership violation;
- a reproducible mutation, ordering, uniqueness, migration, failure-propagation, or evidence-integrity defect.

Style preferences, speculative future needs, and functionality explicitly deferred to another component are not material findings by themselves.

### After two substantial correction rounds

Pause for an explicit convergence assessment. Do not automatically close or abandon the pull request.

Continue correcting the same pull request when the new findings are:

- concrete and locally bounded;
- understood well enough to add a reliable regression test;
- within the existing approved responsibility;
- not evidence of a broken architecture or trust boundary;
- not causing uncontrolled scope growth;
- likely to converge through another bounded correction.

Stop, split, or redesign when there is affirmative evidence that:

- each correction exposes another independent defect class;
- the same root cause survives repeated attempted fixes;
- multiple representations duplicate semantic authority and repeatedly drift;
- the test oracle or evidence system cannot be trusted;
- the component owns too many unrelated correctness domains;
- the next correction requires another subsystem owner, schema, or cross-layer seam;
- review surface continues expanding without a credible convergence path.

The controlling rule is:

> After two substantial correction rounds, perform an explicit convergence assessment. Continue with another bounded correction when the remaining findings are local, understood, testable, and within the existing design. Split or stop only when evidence indicates a systemic architecture, ownership, scope, or oracle problem. The round count alone is never dispositive.

Finding one or two additional bugs in a third review does not by itself justify discarding otherwise valid work.

---

## 10. Owner-only and agent-operable boundaries

Human authorization should be concentrated at consequential boundaries, with deterministic automation inside those boundaries.

### Owner-only by default

- integration into `main`;
- credential creation, scope expansion, or replacement;
- repository governance and rulesets;
- force-push or history rewrite;
- destructive branch or repository cleanup;
- billing, subscriptions, or usage-based spending;
- exceptional permission expansion;
- acceptance of a material architecture or product decision.

### Normally agent-operable inside an approved workflow

- repository inspection;
- scoped edits on a feature branch;
- focused and regression tests;
- diff and CI inspection;
- normal commits and non-force feature publication through approved tooling;
- draft pull-request creation or update;
- correction work on the same pull request;
- bounded review-thread administration when explicitly included in the approved transaction;
- evidence collection and owner-verification packaging.

Manual owner execution is a fallback for platform or sandbox limitations. It is not the desired steady state for every low-risk internal command.

---

## 11. Development-environment sufficiency and setup exit criteria

The environment is sufficiently complete to resume sustained game development when ordinary implementation slices can reliably use the following loop:

1. authoritative context is available and conflicts are surfaced;
2. work is divided into a coherent bounded slice;
3. implementation occurs on one feature branch and pull request;
4. applicable deterministic tests and CI run successfully;
5. independent review occurs;
6. corrections remain bounded and evidence-backed;
7. owner verification is concise and exact-head where required;
8. the owner controls integration into `main`;
9. post-merge validation and recovery paths are known;
10. the workflow does not depend on extensive undocumented owner copy/paste.

Setup completion does not require implementing every conceivable helper, role, schema, static-analysis tool, metric, or release feature.

At the end of each major remaining setup component, perform a sufficiency reassessment:

```text
Can the durable development loop now support the next game-development slice safely and efficiently?
```

Classify remaining work as:

- **required durable tooling before resuming game work**;
- **durable enhancement that can be added later when evidence justifies it**;
- **bootstrap scaffolding to freeze, archive, or stop building**.

Once the required loop is sufficient, return to game development. Improve the environment later in response to demonstrated recurring friction, defects, platform needs, or release requirements.

---

## 12. Handover and bootstrap anti-drift requirements

This charter is stable policy. A dated bootstrap is a mutable operational snapshot. Future handovers should use both.

A future setup handover must:

1. identify this charter as the governing purpose and scope document;
2. identify the latest authoritative operational bootstrap;
3. record the current branch, exact head, `origin/main`, working-tree state, open pull request, CI result, and unresolved review state needed for continuation;
4. distinguish durable tooling already completed from active bootstrap scaffolding;
5. state the single next bounded topic;
6. state what must not be repeated, restored, merged, or started;
7. record owner-only boundaries and any current exceptional limitations;
8. carry forward unresolved architecture or security decisions without silently resolving them;
9. avoid reproducing obsolete historical command sequences unless they are still needed for recovery;
10. use exact dates and identifiers for mutable facts.

A future handover must not:

- describe the entire development environment as disposable scaffolding;
- imply that setup is complete merely because some code can be written;
- imply that every item on an old roadmap must be implemented;
- restore an abandoned component because a historical handover listed it;
- treat a third review finding as an automatic terminal event;
- reintroduce verbose owner instructions that duplicate script-enforced checks;
- include stale repository facts without identifying their date or authority.

---

## 13. Required pre-step anti-drift check

Before approving or issuing any additional development-environment setup step, answer the following:

```text
1. What recurring game-development need does this step serve?
2. Is the output durable tooling or bootstrap scaffolding?
3. What demonstrated owner burden, defect class, or security risk does it reduce?
4. Is there already a simpler adequate mechanism?
5. What is the smallest bounded change?
6. What is explicitly excluded?
7. What evidence will prove sufficiency?
8. What is the stop, freeze, or retirement condition?
9. Does this step delay game development more than its recurring value justifies?
10. Could the project safely resume game work before implementing it?
```

A step that cannot answer these questions clearly should not proceed without explicit owner approval of the exception.

---

## 14. Compact future handover template

```markdown
# Death Idle Development Environment — Session Handover

**Handover date:** YYYY-MM-DD
**Governing charter:** `docs/codex/DEVELOPMENT_ENVIRONMENT_SCOPE_CHARTER.md`
**Current phase:**
**Last completed bounded operation:**
**Next bounded topic:**

## Current operational state

- Local branch:
- Local HEAD:
- `origin/main`:
- Working tree:
- Active PR:
- Exact-head CI:
- Unresolved reviews:
- Publication/request locks:

## Durable tooling completed

- ...

## Active bootstrap scaffolding

- ...

## Current decision and scope boundary

- In scope:
- Out of scope:
- Owner-only actions:
- Explicitly prohibited restoration or reuse:

## Next operation

- Purpose:
- Required authorization:
- Stop conditions:
- Evidence expected:

## Sufficiency status

- Required before game development resumes:
- Enhancements safely deferrable:
- Scaffolding to freeze or retire:
```

The handover should be long enough to prevent state loss, but not a transcript of every completed command.

---

## 15. Adoption and supersession statement

This charter codifies the owner-approved clarification that:

- Death Idle remains the ultimate goal;
- the development environment is durable tooling for the full game-development lifecycle;
- the automation and procedures used only to establish that environment are bootstrap scaffolding;
- setup instructions should minimize owner-facing detail that is not actionable;
- review-round limits require convergence assessment rather than automatic abandonment;
- setup should stop expanding when the durable development loop is sufficient.

It supersedes any prior handover wording that:

- characterized the entire development environment as temporary scaffolding;
- treated the setup roadmap as a mandatory list of components;
- made a fixed correction-round count an automatic terminal rule;
- required the owner to inspect internal script identities, guards, or expected output without an operational need.

This charter does not itself authorize a repository, GitHub, credential, or configuration mutation. Current operational actions remain governed by the latest dated bootstrap and explicit owner authorization.
