# Death Idle Architect Handover and Bootstrap Standard

**Status:** Owner-approved durable workflow standard
**Effective date:** 9 August 2026
**Revision:** 1.1 — quantitative guardrail routing added
**Document role:** Canonical package, content, source-confidence, cutoff, and bootstrap rules for transition between long-lived Death Idle planning-architect sessions
**Applies to:** A planning architect approaching context or memory limits and the fresh planning architect that succeeds it
**Companions:**
- [Development environment scope charter](DEVELOPMENT_ENVIRONMENT_SCOPE_CHARTER.md);
- [Governance findings and actions](DEVELOPMENT_GOVERNANCE_FINDINGS_AND_ACTIONS.md);
- [Standard milestone slice workflow](STANDARD_MILESTONE_SLICE_WORKFLOW.md);
- [Actor prompt standard](ACTOR_PROMPT_STANDARD.md);
- [Quantitative scope budgets and anti-bloat guardrails](QUANTITATIVE_SCOPE_BUDGETS_AND_ANTI_BLOAT_GUARDRAILS.md);
- [Versioned slice-packet template](PROMPT_TEMPLATE.md);
- the current repository decisions, milestones, architecture, active planning memo, active slice packet, pull request, CI, and review state.

---

## 1. Purpose

This standard preserves planning continuity without turning a successor bootstrap into a duplicate repository, a chronological transcript, an implementation packet, or a bundle-construction record.

A handover has one principal transition:

```text
current durable authority + net outgoing-session delta + exact lifecycle cutoff
-> fresh planning architect able to resume one bounded planning responsibility
```

The handover must let the successor locate current authority, understand what became true during the outgoing session, distinguish verified facts from reports or unknowns, identify the exact next workflow action, and remain inside the planning-architect boundary.

It is not intended to recreate the predecessor's entire memory. It transfers only the information that cannot be recovered more reliably from current repository and GitHub authority.

---

## 2. Governing principles

### 2.1 Reference durable authority; never copy it by default

Repository documents, active packets, branches, pull requests, CI, review threads, and owner-verification evidence remain authoritative in their canonical locations. The handover names exact paths, headings, decision IDs, packet versions, PRs, runs, or threads and directs the successor to fetch them at current refs.

Do not place copied governance, architecture, decision, milestone, testing, workflow, planning, packet, PR, CI, or review documents in the runtime package merely to make the package self-contained.

### 2.2 Transfer delta, not transcript

Record accepted outcomes, changed planning implications, current unresolved decisions, and the exact cutoff. Omit failed approaches, debugging chronology, superseded drafts, repeated evidence, and conversational back-and-forth that no longer affects authority.

### 2.3 State the cutoff as an ownership chain

The handover distinguishes:

```text
next workflow action
execution owner for that action
planning architect's immediate responsibility
```

These fields are often different. A fixer may own the next correction while the planning architect owns only packet preparation or escalation. The handover must not make the architect sound like the implementer.

### 2.4 Verify mutable facts or label them honestly

Current branch, head, pull request, CI, review, owner-verification, local-workspace, and external-session facts must be queried near handover time or given an explicit source label. A stale fact must not be presented as current merely because it appeared in an earlier prompt or response.

### 2.5 Do not invent inaccessible state

The outgoing architect may not infer a clean owner working tree, an unpublished branch state, another private session's latest conclusion, or a passed owner gate from silence. Unknown state is carried as unknown and assigned a reverification route.

### 2.6 Protect actor separation

The planning architect may inspect broadly, reconcile authority, draft decisions and bounded actor prompts, receive escalations, and prepare continuity records. It does not:

- implement the feature;
- assess its own material packet as the independent assessor;
- perform routine PR-lifetime finding triage;
- serve as the sole independent reviewer;
- take owner-only integration, destructive, credential, governance, or spending actions.

### 2.7 Minimize successor preload

The successor reads one session handover first, then fetches only the named current authority. The initial bootstrap must make the role boundary more salient than implementation detail.

### 2.8 Route later actors explicitly

Every active or next actor named by the handover includes its recommended model, effort, session choice, and session rationale under `ACTOR_PROMPT_STANDARD.md`.

---

## 3. Reliable-information model

The outgoing architect designs the package around information it can actually access.

### 3.1 Normally reliable

- the current architect conversation and explicit owner decisions in it;
- artifacts attached to the current conversation;
- repository and GitHub state read near handover time;
- decisions, prompts, and continuity records drafted by the architect in the current session;
- explicit outputs returned by scope assessors, implementers, reviewers, triage actors, fixers, CI, or the owner;
- current generated workflow-state evidence when an actual artifact exists and has been validated under its current contract.

### 3.2 Conditional and source-labelled

- local branch, working-tree, staged-file, untracked-file, or index-lock state;
- owner-machine and interactive verification state;
- another long-lived or PR-lifetime chat's current state;
- unpublished local changes;
- mutable model availability, platform behavior, or commercial limits.

These facts may be recorded only with their source, time, and consequence if stale.

### 3.3 Never infer

- a clean working tree without current evidence;
- a passed CI, review, or owner gate from silence or elapsed time;
- the current head from an old prompt or review request;
- another session's unstated conclusion;
- implementation completion from planning approval;
- model availability from an old selector;
- hidden reasoning or discarded conversational attempts.

The `WORKFLOW_STATE_DOCUMENT_CONTRACT.md` contract is not itself current-state evidence. Use a current generated and validated document only for facts it actually proves.

---

## 4. Runtime package composition

A normal successor-facing package contains exactly two files:

```text
00_BOOTSTRAP_PROMPT.txt
01_SESSION_HANDOVER.md
```

Use the repository templates under:

```text
docs/codex/templates/architect-handover/
```

The template files and the generation request are authoring tools. They are not copied into the filled runtime package except as the two completed files above.

### 4.1 Optional files

An optional file is permitted only when all of the following are true:

1. it is active at the exact cutoff;
2. it was produced or accepted in the outgoing session;
3. it is not yet stored in the repository, PR, CI, review threads, owner evidence, or the session handover;
4. the successor needs it for the next bounded planning action;
5. `01_SESSION_HANDOVER.md` names and justifies it.

Examples may include one pending owner decision matrix or one paste-ready prompt that is itself the immediate next action and has no durable location yet.

### 4.2 Files excluded from the runtime package

Do not include:

- stable governance, architecture, decisions, milestones, testing, workflow, or implementation documents already in the repository;
- active planning memos or slice packets already committed or present on the active PR;
- PR bodies, CI logs, review transcripts, or completion records available in canonical systems;
- package manifests, checksum lists, byte counts, file inventories, archive indexes, or assembly notes;
- full chat transcripts or chronological command histories;
- failed approaches and correction back-and-forth that do not affect current authority;
- superseded prompts merely for completeness;
- repeated mutable-state blocks in more than one file;
- exhaustive commit history or historical SHAs;
- implementation code, patch instructions, or unaccepted speculative design.

Operational Git SHAs are not package checksums. A current head or base SHA may appear once when exact-head continuation requires it, with a verification time and source.

---

## 5. `00_BOOTSTRAP_PROMPT.txt`

The bootstrap prompt initializes the fresh planning architect. It should normally be 250 to 500 words.

It must:

- establish the successor as the long-lived planning architect;
- recommend the current architect model and high reasoning effort, normally ChatGPT Sol Pro / High under current policy;
- distinguish planning, independent scope assessment, PR-lifetime triage, implementation, fixing, review, owner verification, and integration;
- direct the successor to read `01_SESSION_HANDOVER.md` first;
- direct it to fetch the exact current authority named there;
- require reverification of mutable facts that affect the next action;
- require a concise first response reconstructing the continuation boundary;
- prohibit implementation, repository edits, GitHub mutation, and actor dispatch in that first response unless the latest owner instruction explicitly authorizes the exact action.

It must not restate the current architecture, milestone history, changed-path list, SHAs, findings, implementation contract, or validation evidence already present in the handover or repository.

---

## 6. `01_SESSION_HANDOVER.md`

This is the only required session-specific continuity record.

**Normal target:** 1,200 to 2,500 words.
**Review trigger:** More than 3,000 words requires an explicit reason in the document and a duplicate-authority check.

It contains:

1. handover identity and current phase;
2. planning-architect role and operating boundary;
3. exact authority map;
4. source-labelled mutable state;
5. net session delta;
6. current cutoff and next-step chain;
7. active actor/model/effort/session routing;
8. open decisions, blockers, and risks;
9. superseded routes or prohibited reuse that remain active drift risks;
10. pending unpublished prompts or artifacts, if any;
11. facts requiring reverification;
12. successor first-turn completion test.

The exact authority map always names `QUANTITATIVE_SCOPE_BUDGETS_AND_ANTI_BLOAT_GUARDRAILS.md`. Active packet-specific concept budgets, governed totals, review-zone or reassessment state, correction deltas, and approved exceptions appear only when they affect continuation. Do not copy the policy or its default tables.

Delete unused template rows and placeholder sections. A filled handover is not required to preserve the blank template's full size.

---

## 7. Source and verification labels

Use one of these labels for mutable or session-specific facts:

| Label | Meaning |
|---|---|
| `REPO_VERIFIED` | Read from the current repository ref near handover time |
| `GITHUB_VERIFIED` | Read from current branch, PR, CI, review, or workflow state near handover time |
| `OWNER_REPORTED` | Explicitly supplied by the owner but not independently reproduced |
| `ACTOR_REPORTED` | Supplied by another task or session; the canonical evidence is named |
| `SESSION_ONLY` | Accepted or drafted in the outgoing architect chat but not yet persisted |
| `UNVERIFIED` | Relevant but not currently confirmable; the successor must verify before use |

Every mutable-state row records:

```text
fact | current value | label | verified/reported at | canonical source | consequence if stale
```

Do not apply these labels to stable repository policy that the successor will fetch directly.

---

## 8. Net session delta

The delta is the primary continuity payload. Include only facts that became true, were accepted, were rejected with a continuing implication, or remain unresolved during the outgoing session.

For each item record:

```text
outcome or decision
final status: accepted | implemented | merged | rejected | superseded | open
why it changes current planning
canonical durable location, or SESSION_ONLY
```

Good delta items include:

- an accepted architecture or ownership decision;
- a changed milestone sequence;
- an approved or revised slice packet;
- a merge, closure, or abandonment that changes the next lifecycle stage;
- a material finding and final disposition;
- a model or session-routing rule adopted during the session;
- an owner decision still pending;
- a conflict discovered between current authorities.

Exclude:

- every attempt made before the accepted result;
- debugging or correction chronology;
- prompts superseded by later prompts;
- repeated summaries of documents already updated;
- implementation detail that does not change planning authority;
- evidence copied solely to prove that work occurred.

When an outcome is already durable, point to it. Do not paraphrase the entire durable record.

---

## 9. Exact authority map

The handover uses one exact manifest:

| Priority | Repository or GitHub source | Exact heading, decision ID, packet version, PR, run, or thread | Why the successor needs it | Authority band |
|---:|---|---|---|---|

Authority bands are:

- stable policy;
- current implemented contract;
- current approved planning authority;
- open owner decision;
- operational state;
- historical or superseded evidence.

The manifest normally includes only:

- this handover standard and the standard milestone workflow;
- `QUANTITATIVE_SCOPE_BUDGETS_AND_ANTI_BLOAT_GUARDRAILS.md`, with exact sections relevant to current planning, implementation surface, correction, exception, or convergence work;
- current `DECISIONS.md`, `MILESTONES.md`, and relevant architecture or contract sections;
- the active planning memo and active slice packet;
- the active PR, CI, review threads, or owner evidence when relevant to the cutoff;
- one current validated workflow-state evidence artifact when it exists and reduces manual transfer;
- one historical source only when an exact unresolved question requires it.

Do not list every project document. Do not copy the cited sections into the package.

---

## 10. Current cutoff and continuation chain

The handover must fill this structure explicitly:

```text
Parent milestone or sequence:
Current bounded slice or task:
Current lifecycle stage:
Last completed bounded operation:
Current blocking fact or decision:
Single next workflow action:
Execution owner for that action:
Planning architect's immediate responsibility:
Required authorization:
Expected next 2-4 transitions:
Completion condition:
Escalation or stop condition:
```

The next workflow action is one bounded planning, approval, implementation, verification, routing, administration, or escalation step. It is not `continue the milestone`, `finish review`, or another phrase covering several actors and gates.

When a PR is active, distinguish:

- implementation state;
- exact-head CI state;
- primary review state;
- PR-lifetime triage state;
- correction round and convergence state;
- final-review state;
- owner-verification state;
- integration and cleanup state.

The handover must not imply that the planning architect executes work assigned to another actor.

---

## 11. Active actor and session routing

Record only actors that remain active or are the next likely handoff.

| Actor/task | Recommended model | Effort | Session | Session rationale | Current state | Next handoff |
|---|---|---|---|---|---|---|

Use the session values defined by `ACTOR_PROMPT_STANDARD.md`:

- `FRESH`;
- `EXISTING: <session name>`;
- `FRESH THEN PR-LIFETIME`;
- `PLATFORM INVOCATION`;
- `OWNER ACTION`.

Do not preserve an implementation, review, or triage session merely because it exists. Retain it only when its context improves the next bounded task and does not compromise required independence.

---

## 12. Outgoing-architect generation procedure

Use `docs/codex/templates/architect-handover/GENERATE_ARCHITECT_HANDOVER_REQUEST.txt` as the normal owner request.

The outgoing architect then:

1. stops implementation and GitHub mutation while preparing the handover;
2. reads the latest owner instruction and accepted conclusions from its current session;
3. identifies which conclusions are already durable and which remain `SESSION_ONLY`;
4. queries current repository, PR, CI, and review facts needed by the cutoff;
5. uses a current validated workflow-state artifact when one exists, without treating its contract as evidence;
6. marks inaccessible local, owner-machine, or external-session facts honestly;
7. extracts the net session delta;
8. defines the exact cutoff, execution owner, and architect responsibility;
9. builds the minimum authority map and always names `QUANTITATIVE_SCOPE_BUDGETS_AND_ANTI_BLOAT_GUARDRAILS.md` as stable policy;
10. when an active packet, PR, correction, exception, or convergence question exists, records only the slice-specific concept budget, governed totals, correction delta, review-zone/threshold state, and approved exception or delegated variance needed for continuation;
11. records active model, effort, and session routing;
12. fills the two runtime templates and deletes unused rows;
13. includes optional artifacts only when the section 4.1 test passes;
14. checks for copied repository prose, copied quantitative default tables, repeated state, implementation leakage, chronology, and unstated assumptions;
15. produces the runtime archive without a manifest or checksum file.

The outgoing architect does not use handover preparation as an opportunity to implement, fix, merge, resolve review threads, or silently decide an open owner question.

---

## 13. Successor boot sequence

The fresh planning architect:

1. reads `01_SESSION_HANDOVER.md` once;
2. fetches the named stable policy and active authority from current repository refs;
3. verifies mutable GitHub facts that affect the next action;
4. identifies any handover fact contradicted by current authority;
5. states the parent milestone, active bounded task, lifecycle stage, last completed operation, next workflow action, execution owner, and its own immediate responsibility;
6. states the applicable role and owner-only boundaries;
7. names any fact that must be reverified before a dependent action;
8. stops before implementation or actor dispatch unless the latest owner instruction explicitly authorizes it.

The first response should be concise and should not repeat the complete handover.

---

## 14. Successor first-turn completion test

Before advancing work, the successor must be able to answer:

1. What is current durable authority?
2. What changed during the outgoing session?
3. What is the current parent milestone or sequence?
4. Which bounded task and lifecycle stage are active?
5. What was the last completed bounded operation?
6. What is the single next workflow action?
7. Who executes that action?
8. What is the planning architect's immediate responsibility?
9. Which owner-only boundary applies?
10. Which model, effort, and session routing applies to active or next actors?
11. Which active concept/quantitative boundary or approved exception applies, when relevant?
12. Which superseded route remains a drift risk?
13. Which mutable facts remain unverified?

If these answers cannot be derived from current durable sources plus the handover, the package is incomplete.

---

## 15. Validation checklist

A handover is complete only when all answers are `yes`:

- Can the successor identify current authority without reading copied duplicates?
- Does the handover state the net session delta rather than a chronological narrative?
- Does it connect the next action to the active bounded task, lifecycle stage, and parent milestone?
- Are the execution owner and planning architect responsibility separate?
- Are mutable facts timed and source-labelled?
- Are inaccessible facts marked instead of inferred?
- Are active and next actors routed by model, effort, session, and rationale?
- Does the authority map name the quantitative-scope policy, and are active threshold or exception facts included only when they affect continuation?
- Are current owner decisions and owner-only boundaries explicit?
- Are superseded items included only when restoration remains a credible risk?
- Is implementation detail absent when it already belongs to the active packet or PR?
- Does the package contain only the two required files plus justified session-only material?
- Are manifests, checksums, copied repository documents, and transcript history absent?
- Can the successor remain inside the planning-architect boundary after reading the bootstrap?

---

## 16. Template authority

The maintained authoring templates are:

```text
docs/codex/templates/architect-handover/GENERATE_ARCHITECT_HANDOVER_REQUEST.txt
docs/codex/templates/architect-handover/00_BOOTSTRAP_PROMPT.txt
docs/codex/templates/architect-handover/01_SESSION_HANDOVER.md
```

The standard governs semantics. The templates may be improved for usability without weakening the two-file package, source-labelling, delta, cutoff, role-boundary, or no-duplication requirements.
