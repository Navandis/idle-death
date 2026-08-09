# Death Idle Standard Milestone Slice Workflow and Information-Flow Specification

**Status:** Owner-approved durable workflow specification
**Effective date:** 2 August 2026
**Revision:** 1.2 — architect handover and actor-prompt routing codified
**Last updated:** 9 August 2026
**Document role:** Standard actor, artifact, context, information-transfer, review, verification, integration, and handover model for one Death Idle implementation slice
**Applies to:** Game implementation milestones, architecture-driven documentation slices, review corrections, owner verification, and future workflow automation
**Companion records:**
- [Development environment scope charter](DEVELOPMENT_ENVIRONMENT_SCOPE_CHARTER.md);
- [Governance findings and actions](DEVELOPMENT_GOVERNANCE_FINDINGS_AND_ACTIONS.md);
- [Architect handover standard](ARCHITECT_HANDOVER_STANDARD.md);
- [Actor prompt standard](ACTOR_PROMPT_STANDARD.md);
- current repository decisions, milestones, architecture, testing, and operational workflow documents;
- the active approved slice packet.

---

## 1. Purpose

This workflow defines how one standard Death Idle milestone slice moves from product intent to merged, verified repository state.

It is designed around four context profiles:

1. **The planning architect is long-lived, broad, and continuity-sensitive.**
2. **The scope assessor architect is fresh, independent, transactional, and disposable.**
3. **The triage architect is fresh for one PR, remains available through that PR’s correction loop, and is disposable after merge or closure.**
4. **Implementation, review, correction, and verification contexts are narrow, transactional, and disposable.**

The workflow therefore moves durable information through repository documents, branches, pull requests, CI, review threads, and generated evidence rather than relying on one chat transcript or the owner manually relaying every detail.

The normal lifecycle is:

```text
owner intent
-> architecture and decomposition
-> independent scope review
-> owner-approved slice packet
-> implementation on one branch and PR
-> deterministic local and CI validation
-> independent review
-> triage and bounded correction
-> final review and optional CodeRabbit
-> exact-head owner verification
-> owner merge
-> post-merge CI, synchronization, cleanup, and milestone closure
```

---

## 2. Governing principles

### 2.1 One slice, one principal result

A slice normally has:

- one primary subsystem owner;
- one principal behavior or state transition;
- explicit included and excluded behavior;
- a test oracle capable of disproving defects;
- one feature branch;
- one pull request;
- one owner integration decision.

### 2.2 The repository is durable authority

- Chat is the planning and approval workspace.
- Repository documentation is the durable product, architecture, decision, and task authority.
- The feature branch and PR are the implementation ledger.
- CI is the automated execution record.
- Review threads are the finding and disposition record.
- Owner logs and explicit PASS/FAIL statements are the owner-only verification record.
- The merge commit and post-merge CI are the integration record.

### 2.3 The owner is not the routine message bus

The owner triggers consequential transitions and supplies decisions, but ordinary technical state should move through Git, GitHub, CI, tracked packets, and generated evidence.

### 2.4 Exact-head evidence

Any code or relevant documentation commit after review or owner verification invalidates the affected exact-head evidence. The workflow must reconcile the new head before merge.

### 2.5 Deterministic evidence precedes expensive review

Focused tests, broader regression, import, smoke, and CI run before asking an independent reviewer to spend effort on the change.

### 2.6 Review limits diagnose convergence

After two substantial correction rounds, pause for a convergence assessment. Continue when remaining defects are local and testable. Split or redesign only when evidence shows systemic failure.

### 2.7 Owner authority remains concentrated

The owner retains final authority over:

- product and architecture acceptance;
- integration into `main`;
- governance;
- credentials and permission expansion;
- destructive cleanup;
- force or history-rewriting operations;
- exceptional recovery;
- spending.

---

## 3. Session topology

| Context | Expected lifetime | Context breadth | Normal disposition |
|---|---|---|---|
| **Planning architect** | Long-lived across many milestones | Broad product, architecture, history, workflow, and repository context | Continued until context limits; then formal handover |
| **Scope assessor architect** | One packet or material planning revision | Candidate packet, exact relevant authorities, scope and testability | Separate fresh chat; disposable after assessment |
| **Implementation Codex task** | One slice, branch, and PR | Approved packet plus exact referenced code/tests | Disposable after merge/closure |
| **Primary reviewer** | One exact PR head or bounded rereview | Packet, diff, relevant interfaces, evidence | Disposable |
| **Triage architect** | One implementation PR through its review/correction lifecycle | Approved packet, findings, exact diff/head, current contracts, evidence | Separate fresh chat; disposable after merge/closure |
| **Fixer Codex task** | One correction packet or correction round | Findings, exact paths, regression oracle | Disposable |
| **CodeRabbit** | One owner-authorized PR review | Repository and PR configuration | External review service |
| **Owner verifier** | One exact head | One script, optional interactive checklist, exact SHA | Disposable evidence run |
| **Owner integrator** | One merge and cleanup sequence | Final evidence and exact GitHub state | Human-controlled |

The planning architect is the continuity-sensitive context. The scope assessor and triage architect are intentionally independent and transactional. Every pillar decision and every material assessor/triage conclusion must be codified before its originating session is disposed or lost.

### 3.1 Architect-lane separation rule

For one milestone slice, the default is three distinct Enterprise chats:

```text
long-lived planning architect
-> fresh scope assessor architect
-> fresh triage architect for the eventual PR
```

The same Enterprise account is sufficient; separate subscriptions are unnecessary. The control is independent context and role, not billing identity. The scope assessor and triage architect should also be different chats from each other.

Exceptions are allowed only for trivial, directly provable work where another architect chat would add no meaningful independence. Any exception is stated explicitly in the planning record.

---

## 4. Actors, responsibilities, and model lanes

### 4.1 Project owner

**Responsibilities**

- define desired product/developer outcome;
- approve design and architecture decisions;
- approve the slice packet;
- answer genuinely unresolved product questions;
- authorize review, optional CodeRabbit, exact-head verification, merge, and destructive cleanup;
- perform or attest owner-only checks.

**Produces**

- approval or revision decision;
- explicit PASS/FAIL evidence;
- merge and cleanup authorization.

**Must not be required to**

- manually transfer ordinary repository facts between agents;
- reproduce deterministic script internals;
- inspect every hash, guard, or expected metadata field;
- privately patch a branch to make verification pass.

---

### 4.2 Planning architect

**Subscription/model lane**

- separate ChatGPT Enterprise subscription;
- Sol Pro by default;
- no dependency on the Codex Pro daily/weekly allowance.

**Responsibilities**

- reconcile design, architecture, decisions, history, and current repository state;
- identify the smallest coherent slice;
- decide stored versus derived state;
- define ownership and legal transitions;
- prepare decisions, milestone changes, planning memo, and lean slice packet;
- maintain context-routing rules;
- receive escalations from scope assessment and PR triage;
- create handovers and durable pivot records;
- draft bounded actor prompts under `ACTOR_PROMPT_STANDARD.md`.

**Produces**

- architecture/decision updates;
- approved packet candidate;
- long-range correction or redesign decisions escalated from triage;
- continuity records.

**Must not**

- silently resolve conflicts;
- treat its private transcript as durable authority;
- implement the feature and serve as its sole reviewer;
- downgrade reasoning merely to conserve the separate Codex budget.

---

### 4.3 Independent scope assessor architect

**Subscription and model lane**

- the same ChatGPT Enterprise subscription may be used;
- Sol Pro/High by default for architecture-sensitive packets;
- always a separate fresh chat from the planning architect for the candidate packet.

**Responsibilities**

Check that the proposed packet:

- has one principal result and owner;
- is executable from current repository state;
- does not import later-slice behavior;
- has an independent, meaningful oracle;
- uses a minimal context manifest;
- has realistic review surface;
- states stop conditions;
- does not prescribe speculative architecture.

**Produces**

- approve;
- revise;
- split;
- owner-approved exception recommendation.

**Must not**

- receive or rely on the planning architect’s full private transcript;
- expand the task;
- implement code;
- approve unresolved architecture by assumption.

A small revision may return to the same assessor chat. A material change to ownership, sequence, schema, or principal transition requires a fresh assessment. The assessor chat is disposed after approval or final rejection, and its structured report becomes part of the planning record.

---

### 4.4 Implementation Codex task

**Normal model**

- Luna Medium for deterministic, low-risk slices;
- Terra Medium for standard gameplay implementation;
- Terra High for simulation, persistence, migration, transactional, or cross-layer work;
- Sol High only for an exceptionally difficult coding problem after architecture is already approved.

**Responsibilities**

- read root instructions and the approved packet;
- read only the exact context listed by the packet;
- verify baseline, branch, and dependencies;
- implement the authorized behavior;
- add or update tests;
- run focused and broader local validation;
- create owner-verification assets when specified;
- commit, publish, and update one draft PR;
- stop and report exact head and evidence.

**Must not**

- redefine architecture, scope, or acceptance;
- inspect failed branches unless the packet names an exact forensic question;
- add later-slice behavior;
- merge, close, delete branches, force-push, or rewrite history;
- create a replacement PR merely because corrections are needed.

---

### 4.5 Deterministic toolchain

**Includes**

- GUT wrappers;
- import and smoke checks;
- trace or fixture runners;
- GitHub Actions;
- exact owner-verification scripts.

**Responsibilities**

- execute repeatable checks;
- propagate real failure exits;
- emit bounded evidence;
- clean temporary artifacts;
- preserve exact-head identity.

**Must not**

- decide ambiguous product behavior;
- convert a missing owner observation into PASS;
- mutate unrelated repository state.

---

### 4.6 Primary independent reviewer

**Execution lane**

- GitHub `@codex review`;
- platform-selected review model.

**Responsibilities**

- review the exact head;
- audit the primary risk boundary and complete current diff;
- report only material findings;
- include reproducer, impact, and smallest correction;
- respect explicit exclusions and deferred work.

**Receives**

- exact head and base;
- approved slice objective;
- primary contracts and acceptance criteria;
- validation evidence;
- explicit out-of-scope behavior.

**Does not receive**

- the implementer’s full chat transcript;
- every historical document;
- failed-branch production code unless specifically necessary;
- speculative future requirements.

---

### 4.7 Triage architect

**Subscription and session boundary**

- use a separate fresh ChatGPT Enterprise chat from both the planning architect and scope assessor;
- Sol Pro/High by default for architecture-sensitive or non-converging findings;
- create one triage chat per implementation PR, not one chat per finding;
- retain that chat through the PR’s review and correction rounds so convergence is judged consistently;
- dispose it after the PR merges or closes.

**Responsibilities**

Classify each finding as:

```text
true positive — correction required
false positive — disposition required
duplicate
prompt or contract defect
architecture or scope signal
```

Determine whether to:

- issue a bounded correction;
- clarify the packet;
- update architecture;
- perform a convergence assessment;
- stop and redesign.

**Produces**

- correction packet;
- owner decision request;
- disposition text;
- redesign recommendation;
- compact triage/convergence record for the planning architect and handover bundle.

The triage architect handles ordinary true-positive, false-positive, duplicate, and bounded-correction decisions. It escalates product intent, architecture ownership, milestone decomposition, or a systemic non-convergence signal to the planning architect. A trivial, mechanically provable false positive may be handled by the planning architect only as an explicit exception.

---

### 4.8 Fixer Codex task

**Normal model**

- Luna Medium for a local, direct-oracle correction;
- Terra Medium or High for multi-file or cross-layer correction.

**Responsibilities**

- work on the same branch and PR;
- change only authorized paths;
- add a named regression for every real finding;
- run the required focused and broader validation;
- publish the correction;
- report exact new head.

**Must not**

- broaden scope;
- rewrite the packet;
- fix unrelated defects;
- merge or administer the PR beyond the authorized transaction.

A trivial mechanical correction may remain in the original implementation task when the oracle and scope are exact. Material corrections should normally use a fresh fixer context.

---

### 4.9 CodeRabbit

**Role**

Optional owner-authorized secondary review after the primary Codex review is clean and the PR is ready.

**Responsibilities**

- provide another independent review perspective;
- run configured pre-merge checks;
- create no autonomous fixes under the project policy.

**Must not**

- be invoked automatically on every draft/update;
- autonomously modify code;
- replace deterministic tests or primary review;
- trigger another review without owner authorization.

---

### 4.10 Owner verifier

**Responsibilities**

- check out the exact PR head;
- run one milestone-specific PowerShell entry point where required;
- perform genuinely interactive editor, visual, audio, Windows, or Steam checks;
- return explicit PASS or FAIL with exact SHA and generated log reference.

**Must not**

- assemble many deterministic commands manually when one script can do so;
- privately change the script or branch;
- report an unperformed check as passed.

---

### 4.11 Owner integrator

**Responsibilities**

- confirm exact-head evidence;
- merge through the approved merge method;
- verify post-merge CI;
- authorize local synchronization and exact branch cleanup.

No agent or automation infers merge permission from words such as “finish,” “publish,” or “complete.”

---

## 5. Canonical artifacts

| Artifact | Owner | Purpose | Lifetime |
|---|---|---|---|
| Design sources of truth | Owner/architect | Product behavior and direction | Durable |
| Architecture, data contracts, implementation rules | Architect/project | Technical authority | Durable |
| Decision record | Architect + owner approval | Why a consequential choice exists | Durable |
| Milestone map | Architect + owner approval | Sequence, dependencies, status | Durable |
| Planning memo | Architect | Broad analysis and decomposition rationale | Until superseded; retained historically |
| Approved slice packet | Architect + owner approval | Executable task authority and context manifest | Durable for the slice |
| Feature branch | Implementer/fixer | Code and test work | Until merged/closed and cleaned |
| Pull request | Implementer/owner | Live implementation, evidence, and review ledger | Durable GitHub history |
| CI run | GitHub Actions | Automated exact-head validation | Durable GitHub evidence |
| Review threads | Reviewers/owner | Findings, replies, and disposition | Durable PR history |
| Correction packet | Triage architect | Temporary bounded fix authorization | Until correction closes |
| Owner verification log | Owner tool | Windows/interactive exact-head evidence | Generated local evidence; not committed |
| Merge commit | Owner | Integration record | Permanent |
| Post-merge CI | GitHub Actions | Integrated-main validation | Permanent evidence |
| Setup operational bootstrap | Architect | Mutable setup state and next setup step | Replaced by later setup bootstrap |
| Planning architect runtime handover | Outgoing planning architect | Successor bootstrap, net session delta, source-labelled mutable state, and exact cutoff | Replaced by later handover |
| Handover and actor-prompt standards | Architect + owner approval | Continuity, prompt proportionality, and explicit session routing | Durable |
| G0 governance/workflow records | Architect + owner approval | Continuity and anti-drift | Durable |

---

## 6. Information-transfer map

| From | To | Information | Carrier | Who moves it | Mode |
|---|---|---|---|---|---|
| Owner | Architect | Desired player/developer outcome, constraints, approvals | Architect chat | Owner | Manual, concise |
| Architect | Scope assessor | Planning memo and slice packet candidate | Repository doc or attached Markdown | Architect/owner | Manual trigger, durable artifact |
| Scope assessor | Owner/architect | Approve, revise, split, exception | Review response | Assessor | Manual |
| Owner | Repository | Approved decision, milestone, packet | Documentation PR | Docs implementer + owner merge | Git/GitHub |
| Approved packet | Implementer | Objective, context manifest, scope, tests, delivery | Repository path | Implementer reads it | Automatic/self-service |
| Implementer | CI | Committed branch head | Git push | Publication tooling | Automatic after authorization |
| CI | PR/actors | Test/check result | GitHub Actions | GitHub | Automatic |
| Owner/architect | Primary reviewer | Paste-ready exact-head review request | PR comment | Owner or authorized helper | Manual trigger |
| Reviewer | Triage architect | Findings | PR threads | GitHub | Automatic persistence; architect reads |
| Triage architect | Fixer | Bounded correction packet | Chat or small `.md/.txt` | Owner starts fixer task | Manual trigger |
| Fixer | PR/CI | Corrected commit and tests | Same branch/PR | Publication tooling | Automatic after task |
| Owner | CodeRabbit | One opt-in review | PR label/comment | Owner | Manual trigger |
| Implementation PR | Owner verifier | Exact head and committed verification script | Git checkout + packet | Git/GitHub | Self-service |
| Owner verifier | Architect/PR | PASS/FAIL and log reference | Chat or PR comment | Owner | Manual, concise |
| Owner | `main` | Merge decision | GitHub UI/CLI | Owner | Manual, consequential |
| Merge | CI | Integrated main head | Push event | GitHub | Automatic |
| Outgoing architect | Future architect | Net session delta, source-labelled mutable state, exact cutoff, and authority manifest | Two-file runtime handover referencing current repository/GitHub authority | Owner supplies new session | Manual bootstrap, durable sources |

The owner should not manually paste implementation details that are already present in the branch, PR, CI, or packet.

---

## 7. Standard slice lifecycle

### Stage 0 — Intake and readiness

**Actor:** Owner and architect
**Input:** Desired game or developer outcome
**Actions:**

- identify whether the request is design, architecture, documentation, implementation, or recovery;
- verify current repository/milestone baseline;
- determine whether a prior decision must be reopened;
- identify conflicts or missing authority.

**Output:** Planning question or confirmed planning target
**Stop when:** Product behavior or authority is ambiguous.

---

### Stage 1 — Broad architecture and decomposition

**Actor:** Architect
**Context:** Broad, including relevant history and failed attempts
**Actions:**

- identify one principal result;
- assign one primary subsystem owner;
- define stored versus derived values;
- define legal mutation and read owners;
- identify risk dimensions and integration seams;
- choose the smallest coherent sequence;
- draft decision and milestone changes where needed.

**Output:** Planning memo and slice packet candidate
**Transfer:** Durable Markdown, not only chat.

---

### Stage 2 — Independent scope assessment

**Actor:** Scope assessor
**Actions:**

- test packet coherence;
- inspect context breadth;
- challenge hidden future behavior;
- verify acceptance can disprove defects;
- compare forecast against review-surface guardrails;
- recommend approve, revise, split, or explicit exception.

**Output:** Scope-review result
**Stop when:** Another owner, schema, transition, or unresolved design decision is required.

---

### Stage 3 — Owner approval and packet versioning

**Actor:** Owner and architect
**Actions:**

- resolve assessor feedback;
- approve design and scope;
- commit or otherwise publish the accepted decision, milestone, and packet;
- assign version, date, baseline, branch, and PR title.

**Output:** Approved executable packet
**Rule:** Implementation cannot begin from an unapproved or superseded packet.

---

### Stage 4 — Implementation task bootstrap

**Actor:** Implementation Codex
**Actions:**

- synchronize `main`;
- verify expected baseline;
- create/switch to exact feature branch;
- verify clean state and current dependencies;
- read root instructions, packet, and exact context manifest;
- inspect listed code and tests;
- give a short approach and verification plan.

**Output:** Pre-edit readiness report
**Stop when:** Repository state materially differs, required context conflicts, or the packet cannot be implemented within scope.

The pre-edit report should normally be concise. It is not a second planning memo.

---

### Stage 5 — Implementation and local validation

**Actor:** Implementation Codex
**Actions:**

- implement only the packet;
- keep provisional values configurable;
- add deterministic behavior tests;
- add failure/no-mutation/migration tests as applicable;
- run focused checks while iterating;
- run specified broader regression before handoff;
- build the owner-verification package when required;
- run `git diff --check` and scope audit.

**Output:** Complete local change and evidence
**Stop when:** Scope grows materially, another authority is needed, or a required oracle cannot be made trustworthy.

---

### Stage 6 — Commit, publish, and draft PR

**Actor:** Implementation Codex through approved tooling
**Actions:**

- stage exact paths;
- commit intentionally;
- push normally;
- create or update one draft PR;
- populate concise PR body with objective, scope, validation, and exclusions;
- report exact head.

**Output:** Draft PR and exact SHA
**Non-actions:** No merge, close, force-push, auto-merge, replacement PR, or branch deletion.

---

### Stage 7 — Automatic CI gate

**Actor:** GitHub Actions
**Actions:**

- import;
- full GUT;
- smoke and other approved checks;
- later project-specific static/evidence checks.

**Output:** Exact-head check result
**Rule:** A red or missing required check returns to implementation before primary review unless the failure itself needs triage.

---

### Stage 8 — Primary independent review

**Actor:** GitHub Codex reviewer
**Trigger:** Owner posts a paste-ready request or authorizes an exact PR-admin helper
**Actions:**

- review exact head;
- focus on material correctness, evidence, ownership, confidentiality, migration, and trust-boundary defects;
- review the complete current diff;
- respect packet exclusions.

**Output:** Clean result or review threads.

---

### Stage 9 — Finding triage

**Actor:** Triage architect
**Actions:**

- validate each finding against current authority and code;
- classify true/false/duplicate/prompt defect/architecture signal;
- identify smallest correction and regression;
- draft false-positive dispositions;
- decide whether owner input is needed.

**Output:** Correction packet, disposition, or redesign decision.

---

### Stage 10 — Correction loop

**Actor:** Fixer Codex
**Actions:**

- remain on same branch and PR;
- apply exact corrections;
- add named regressions;
- rerun focused and broader checks;
- publish new head;
- allow CI to rerun;
- request bounded rereview.

**After two substantial rounds:** Architect performs a convergence assessment.

**Continue when:**

- defects are local;
- root cause is understood;
- regression is reliable;
- scope remains stable;
- next correction plausibly converges.

**Stop/split/redesign when:**

- semantic authority is duplicated;
- oracle remains unreliable;
- each correction exposes a new independent defect class;
- another owner/schema/seam is required;
- scope expands without a credible endpoint.

---

### Stage 11 — Final review, thread disposition, and optional CodeRabbit

**Actors:** Primary reviewer, owner, optional CodeRabbit
**Actions:**

1. obtain one final unrestricted Codex review at the stable head;
2. post owner dispositions and resolve all material threads;
3. reconcile PR body and metadata;
4. mark ready;
5. optionally trigger one CodeRabbit review;
6. triage any CodeRabbit finding;
7. resolve or correct before integration.

**Rule:** A code commit after final review returns the PR to review reconciliation. A metadata-only change does not invalidate code review but must preserve protected metadata.

---

### Stage 12 — Exact-head owner verification

**Actor:** Owner verifier
**Actions:**

- check out exact PR head;
- run the single milestone verification entry point;
- perform any interactive checklist;
- return explicit result.

**Minimum evidence:**

```text
Owner verification: PASS|FAIL
PR head: <sha>
Checks performed: <concise list>
Date: YYYY-MM-DD
Log: <generated filename, when applicable>
Observed warnings/failures: <none or concise description>
```

**Rule:** Any subsequent code/documentation commit affecting the verified scope invalidates this evidence.

---

### Stage 13 — Integration readiness

**Actor:** Architect/owner
**Verify:**

- exact head unchanged;
- required CI successful;
- final Codex review clean;
- optional CodeRabbit disposition complete;
- all conversations resolved;
- owner verification passed where required;
- PR body accurate;
- merge method and base correct;
- no unexpected labels, auto-merge, or branch divergence.

**Output:** Owner merge authorization.

---

### Stage 14 — Owner integration

**Actor:** Owner integrator
**Actions:**

- merge with the approved normal merge commit;
- preserve feature branch until post-merge validation.

**Output:** Merge commit SHA
**Stop when:** Head mismatch, conflict, requirement failure, or unexpected GitHub state.

---

### Stage 15 — Post-merge validation, synchronization, and cleanup

**Actors:** GitHub Actions and guarded owner tooling
**Sequence:**

1. verify exact merge-commit push CI;
2. fast-forward local `main`;
3. confirm clean state;
4. delete only the exact merged feature branch locally/remotely;
5. verify refs absent;
6. preserve historical PR.

**Rule:** Cleanup remains separate from merge because post-merge evidence may require the branch.

---

### Stage 16 — Milestone closure and next planning turn

**Actor:** Architect
**Actions:**

- update milestone/decision status where required;
- record merge and verification evidence concisely;
- capture new durable lessons;
- classify any tooling friction as:
  - immediate blocker;
  - later durable enhancement;
  - bootstrap artifact to retire;
- define the next bounded planning topic.

**Output:** Updated durable authority and, when necessary, a new bootstrap.

---

## 8. Lean slice packet specification

A standard packet should include the following and omit repeated general project prose.

### 8.1 Identity

```text
Slice ID and title
Packet version and date
Status
Parent epic
Expected baseline
Feature branch
PR target and title
Primary subsystem owner
Risk dimensions
```

### 8.2 Objective and demonstration

- one or two sentences defining the concrete result;
- observable developer/player outcome;
- one principal transition.

### 8.3 Context manifest

Each entry names:

```text
source path
exact heading, requirement labels, or decision IDs
why it applies
```

Also name:

- exact code paths;
- exact tests/fixtures;
- historical sources explicitly excluded;
- one exact forensic reference only when necessary.

### 8.4 Included scope

- authoritative state or behavior added;
- legal mutation/read owner;
- integration seams;
- persistence effect;
- verification package.

### 8.5 Explicit exclusions

List later-slice systems and tempting adjacent work.

### 8.6 Stored-versus-derived table

Required when state, reporting, persistence, or projections are involved.

### 8.7 Behavioral and transition requirements

Use stable IDs only where traceability benefits from them.

### 8.8 Acceptance and test oracle

- positive behavior;
- boundary behavior;
- malformed and no-mutation behavior;
- equivalence/idempotency/migration behavior;
- exact focused and broader checks.

### 8.9 Scope and convergence guards

- forecasted files/lines;
- risk dimensions;
- seams;
- mandatory stop conditions;
- conditions requiring owner decision.

### 8.10 Delivery contract

- publication path;
- PR handoff;
- owner verification;
- output ceiling;
- final marker where useful.

The packet should not duplicate entire canonical documents or prescribe every private helper.

---

## 9. Context rules by actor

### Architect

May read broadly across:

- design sources;
- current architecture and decisions;
- milestones;
- current implementation;
- relevant history and failed attempts;
- workflow and owner evidence.

Must convert broad context into durable decisions and a narrow packet.

### Scope assessor

Reads:

- packet;
- exact authority it references;
- current repository facts needed to challenge scope;
- no unnecessary historical transcripts.

### Implementer

Reads:

- root `AGENTS.md`;
- approved packet;
- exact context-manifest entries;
- listed code/tests;
- relevant nested instructions where named.

Normally does not read:

- full decision log;
- full milestone map;
- full design sources;
- failed branches;
- superseded prompts;
- architect chat history.

### Reviewer

Reads:

- packet;
- exact diff;
- relevant interfaces/contracts;
- validation evidence;
- primary risk boundary.

### Fixer

Reads:

- correction packet;
- exact findings;
- current code;
- tests and contract sections needed for the fix.

### Owner

Receives:

- concise approval question;
- one command or UI action;
- exact decision alternatives when necessary;
- bounded evidence summary.

---

## 10. Model and effort policy

### Architect lane

```text
Subscription: ChatGPT Enterprise
Default: Sol Pro
Constraint: reasoning quality and continuity, not Codex quota
```

Use the architect lane for:

- design reconciliation;
- architecture;
- decisions;
- milestone decomposition;
- scope review;
- triage;
- convergence;
- handover.

### Codex transactional lane

The coding subscription is separate. Route by error cost and uncertainty:

| Task | Default |
|---|---|
| Read-only orientation or exact deterministic change | Luna Light/Medium |
| Small correction with direct oracle | Luna Medium |
| Standard bounded implementation | Terra Medium |
| Simulation, persistence, migration, transaction, cross-layer work | Terra High |
| Difficult coding problem after a scoped attempt | Sol High |
| Low-risk micro-task | Spark selectively |

Model availability and quota economics change. Maintain them in a separate current selector rather than embedding volatile rate numbers in every packet.

### Reviewer lane

Use GitHub’s platform-selected Codex review model. Specify review scope, head, risk boundary, and output limit.

### Effort rule

Use the lowest effort that can reliably resolve the uncertainty:

- Light: exact, deterministic, low-risk;
- Medium: normal implementation or focused diagnosis;
- High: architecture-sensitive, adversarial, cross-layer, or transactional;
- Max/Ultra: exceptional exhaustive pass after a scoped High attempt.

Every architect-drafted prompt must state the recommended model, effort, session choice, and session rationale. Use `ACTOR_PROMPT_STANDARD.md` for prompt proportionality, context selection, and fresh-versus-existing-session rules. Platform-selected review actors are identified as platform-selected rather than assigned a fictitious selectable model.

---

## 11. Owner-facing interaction standard

For ordinary scripted operations:

```text
Purpose
- One sentence.

Run
- One file reference and one command, or one precise UI action.

Return
- Complete output or one result block.

Stop only if
- A prompt or state requiring an owner decision appears.
```

Do not routinely expose:

- file hashes;
- byte lengths;
- every transaction guard;
- full expected metadata;
- repetitive non-action lists;
- complete success output.

The architect analyzes the returned evidence.

---

## 12. Review and finding policy

### Material finding

A material finding demonstrates a concrete:

- accepted invalid state;
- rejected valid state with practical impact;
- false-positive PASS;
- state mutation or aliasing defect;
- ordering, identity, uniqueness, idempotency, migration, or overflow defect;
- confidentiality or credential leak;
- ownership or trust-boundary violation;
- evidence-integrity failure.

Style, speculative improvements, and explicitly deferred functionality are not material by themselves.

### False positives

A false-positive disposition must explain:

- why the reported premise is incorrect;
- the actual contract or counter;
- concrete existing evidence;
- why the proposed change would be wrong or unnecessary.

Then reply and resolve the thread without changing code.

### Exact-head invalidation

A new code or relevant contract commit invalidates:

- prior final review;
- prior owner verification;
- prior exact-head review request.

CI automatically re-runs, but review and owner evidence require deliberate reconciliation.

---

## 13. Failure and exception handling

### Prompt or contract defect

Stop implementation, preserve work, and return to the architect for a packet revision. The implementer must not rewrite its own authority.

### CI failure

Return to implementer/fixer unless the failure is environmental or requires architecture triage.

### Owner verification failure

Return the exact log and observation. The architect decides correction, diagnostics, packet revision, or design decision.

### Merge conflict or base movement

Stop for a deliberate update strategy. Do not force-push automatically.

### Accidental `main` edit or push

Use the documented recovery path. Do not self-rewrite or improvise.

### Non-convergence

Record the evidence and redesign the ownership/model rather than adding another validator layer.

---

## 14. Architect handover and session transition

The planning architect must create a successor bootstrap before context loss becomes operationally dangerous. Use `ARCHITECT_HANDOVER_STANDARD.md`; do not improvise a new package shape for each session.

A normal successor-facing runtime package contains exactly:

```text
00_BOOTSTRAP_PROMPT.txt
01_SESSION_HANDOVER.md
```

The package references current repository and GitHub authority; it does not copy stable governance, architecture, decisions, milestone maps, active packets, PR bodies, CI logs, review transcripts, or other material already available in its canonical system. Package manifests, checksum lists, byte counts, and other bundling scaffolding are excluded.

The handover must preserve:

- the net session delta rather than the path taken to reach it;
- an exact authority map with current, open, and historical/superseded bands;
- mutable facts labelled by source and verification status;
- the current parent milestone, bounded task, lifecycle stage, and last completed operation;
- the single next workflow action;
- the execution owner for that action;
- the planning architect's own immediate responsibility, stated separately;
- open owner decisions, blockers, and active drift risks;
- model, effort, and fresh-versus-existing-session routing for active or next actors.

The outgoing architect must not infer unavailable local, owner-machine, or external-session state. It marks such facts `UNVERIFIED`, `OWNER_REPORTED`, or `ACTOR_REPORTED` as defined by the handover standard.

The successor reads the handover, fetches current durable authority, reverifies mutable facts that affect the next action, states the continuation boundary, and remains read-only during its first reconstruction response unless the latest owner instruction explicitly authorizes a mutation or dispatch.

---

## 15. Slice completion criteria

A slice is complete only when:

- approved scope was delivered or explicitly revised;
- deterministic focused and broader validation passed;
- CI passed at the exact final head;
- material review findings were corrected or dispositioned;
- final review was clean;
- optional CodeRabbit findings were reconciled;
- owner verification passed when required;
- PR metadata accurately described the final change;
- owner merged the exact head;
- post-merge CI passed;
- local `main` synchronized;
- exact merged feature branch cleaned;
- milestone/decision status was updated when needed;
- durable lessons were captured.

A passing implementation response, green local test, or clean AI review alone is not milestone completion.

---

## 16. Workflow evolution rule

This workflow is durable tooling, not immutable ceremony.

Change it when evidence shows recurring:

- owner burden;
- context drift;
- false-positive review patterns;
- missing deterministic evidence;
- failed information transfer;
- platform limitations;
- release-stage needs.

Do not expand it because a generalized framework is theoretically possible. Use the smallest change that closes a demonstrated recurring problem, and codify the rationale before the architect moves on.
