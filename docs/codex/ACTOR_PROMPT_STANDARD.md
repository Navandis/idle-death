# Death Idle Architect-Drafted Actor Prompt Standard

**Status:** Owner-approved durable prompt-routing standard
**Effective date:** 9 August 2026
**Revision:** 1.0
**Document role:** Canonical model, effort, session, context, proportionality, and output rules for prompts drafted by a Death Idle architect or triage actor for another execution or review actor
**Applies to:** Scope assessors, implementation tasks, fixers, triage architects, auditors, reviewers, owner-verification actions, and exceptional recovery actors
**Companions:**
- [Standard milestone slice workflow](STANDARD_MILESTONE_SLICE_WORKFLOW.md);
- [Architect handover standard](ARCHITECT_HANDOVER_STANDARD.md);
- [Versioned slice-packet template](PROMPT_TEMPLATE.md);
- [Codex desktop workflow](CODEX_DESKTOP_WORKFLOW.md);
- [Owner verification workflow](OWNER_VERIFICATION_WORKFLOW.md).

---

## 1. Purpose

This standard gives each actor enough context to perform and disprove one bounded task without loading the full planning history or forcing the owner to decide session routing implicitly.

Every prompt must answer before its task body:

```text
Who performs the task?
Which model is recommended?
Which reasoning effort is required?
Should the actor use a fresh or existing session?
Why is that session choice beneficial rather than harmful?
```

Prompt length is proportional to uncertainty, risk, required independence, and the strength of the task oracle. A small direct-oracle correction is not given a planning dossier. A new architecture-sensitive milestone assessment is not reduced to an underspecified brief.

---

## 2. Governing principles

### 2.1 One prompt, one actor responsibility

Do not combine planning, implementation, independent assessment, finding triage, correction, and review into one task unless the workflow explicitly defines that combination as a trivial exception.

### 2.2 Reference current authority

Name exact repository paths, headings, decision IDs, packet versions, findings, tests, PR threads, or evidence. Do not paraphrase entire current documents into the prompt.

### 2.3 Include only unavailable or decision-relevant facts

A prompt contains facts the actor cannot obtain more reliably from its own execution context and facts needed to interpret scope, ownership, risk, or the oracle.

### 2.4 Independence and continuity are deliberate choices

A fresh session removes irrelevant context and bias. An existing session preserves useful local context. Neither is always safer. State the choice and rationale explicitly.

### 2.5 Semantic completeness outranks a mechanical word limit

The prompt must retain the ownership boundary, required result, acceptance or finding standard, validation, and stop conditions. Size ranges diagnose excess or insufficiency; they do not authorize omission of a necessary contract.

### 2.6 The actor does not rewrite its authority

An implementer or fixer may report a packet defect or mismatch, but may not broaden or replace the approved scope. A reviewer reports findings; it does not implement. A triage architect classifies and routes; it does not silently fix.

### 2.7 Mutable routing policy is labelled

Model availability and platform behavior can change. Use current project policy and do not invent a selectable model for a platform-selected review actor.

---

## 3. Mandatory routing header

Every architect-drafted actor prompt begins with:

```text
ROUTING

Actor:
Recommended model:
Effort:
Session:
Session rationale:
```

### 3.1 Allowed session values

| Value | Meaning |
|---|---|
| `FRESH` | Start a new session because independence, bias control, context reset, or narrow task isolation is required |
| `EXISTING: <session name>` | Continue a named session because its prior bounded context materially improves the task and independence is not required |
| `FRESH THEN PR-LIFETIME` | Start a fresh triage chat for one PR and keep it through that PR's correction lifecycle |
| `PLATFORM INVOCATION` | Invoke GitHub `@codex review` or another platform-selected actor rather than creating a conventional chat |
| `OWNER ACTION` | The task is a deterministic owner command or observation and requires no AI session |

Do not use `existing session` without naming which session. Do not use `fresh` without explaining the independence or context-isolation benefit.

### 3.2 Model and effort expression

Use separate fields:

```text
Recommended model: Codex Terra
Effort: High
```

Do not compress them into an ambiguous label when the model and effort are independently selectable.

For GitHub review, use:

```text
Recommended model: Platform-selected GitHub Codex reviewer
Effort: Platform-managed; request an adversarial/high-depth review through scope and focus
Session: PLATFORM INVOCATION
```

Do not claim that Terra, Sol, or another implementation model was selected when the review platform selects the model.

---

## 4. Session-selection decision

Choose the session by answering:

1. Does the actor need independence from the session that authored or implemented the work?
2. Does prior context create anchoring, confirmation, or scope-drift risk?
3. Does the task continue the same bounded responsibility and rely on local context that would be expensive or error-prone to reconstruct?
4. Has the existing session accumulated unrelated work or approached its context limit?
5. Does the workflow intentionally keep one session alive across a lifecycle, such as PR-lifetime triage?

### 4.1 Default routing table

| Task | Recommended model and effort | Session | Rationale |
|---|---|---|---|
| Long-lived planning architect successor | ChatGPT Sol Pro / High | `FRESH` | New continuity context bootstrapped from durable records |
| New milestone or materially changed packet scope assessment | ChatGPT Sol Pro / High | `FRESH` | Independent challenge to planning assumptions |
| Bounded rereview of the same packet | ChatGPT Sol Pro / High | `EXISTING: <assessor>` | Prior findings remain the intended context and independence from planning is preserved |
| First triage of one implementation PR | ChatGPT Sol Pro / High | `FRESH THEN PR-LIFETIME` | Independent from planning and implementation; consistent convergence judgment across rounds |
| Standard bounded implementation | Codex Terra / Medium | `FRESH` | Narrow packet-driven execution |
| Simulation, persistence, migration, transaction, or cross-layer implementation | Codex Terra / High | `FRESH` | High error cost and narrow approved authority |
| Local deterministic correction with direct oracle | Codex Luna / Medium | `FRESH` by default | Avoid accumulated implementation drift; use only the exact finding and oracle |
| Material multi-file or cross-layer correction | Codex Terra / High | `FRESH` | Bounded correction authority with sufficient reasoning depth |
| Direct continuation of the same still-bounded correction | Same assigned model/effort | `EXISTING: <fixer>` only when justified | Local context remains useful and no independence requirement applies |
| Primary, bounded, or final independent PR review | Platform-selected GitHub Codex reviewer | `PLATFORM INVOCATION` | Exact-head independent review |
| Owner verification command or observation | N/A | `OWNER ACTION` | Deterministic operation or human observation, not an AI task |

Model names are current policy labels, not permanent commercial guarantees. A material selector update requires current verification and a durable policy change.

---

## 5. Prompt body modules

After the routing header, use only the modules the task requires:

```text
OBJECTIVE
MINIMUM AUTHORITY AND CONTEXT
AUTHORIZED SCOPE
REQUIRED OUTCOME OR FINDING STANDARD
VALIDATION OR EVIDENCE
BOUNDARIES AND STOP CONDITIONS
PUBLICATION OR HANDOFF
OUTPUT CONTRACT
```

### 5.1 `OBJECTIVE`

State one concrete result or decision. Do not use a broad phrase such as `finish the milestone` or `review everything` when the actor owns one bounded phase.

### 5.2 `MINIMUM AUTHORITY AND CONTEXT`

Name exact current sources and why each applies. Prefer the active slice packet plus exact referenced contracts. Do not add the full decision log, milestone map, design sources, failed branches, or architect transcript unless one exact unresolved question requires them.

### 5.3 `AUTHORIZED SCOPE`

For mutation tasks, name exact files, directories, findings, or responsibility boundaries. For review and triage, name the audit or classification surface. State what may be inspected and what may be changed.

### 5.4 `REQUIRED OUTCOME OR FINDING STANDARD`

Define the semantic result. A fixer receives the exact defect and required correction. A reviewer receives the material-finding threshold. A triage architect receives the classification vocabulary and correction-authority boundary.

### 5.5 `VALIDATION OR EVIDENCE`

Name the direct oracle, regressions, focused checks, broader checks, CI, exact-head evidence, or owner result required for the actor's task. Do not use green CI alone as a substitute for semantic acceptance.

### 5.6 `BOUNDARIES AND STOP CONDITIONS`

Name the conditions that require return to the planning architect, owner, or triage actor. Avoid exhaustive generic non-action lists when the governing workflow already makes the prohibition clear, but repeat consequential task-specific boundaries.

### 5.7 `PUBLICATION OR HANDOFF`

State whether the actor edits locally, commits, pushes, updates an existing PR, posts a review, returns a correction packet, or performs no mutation. Keep owner-only merge, close, force, replacement, destructive cleanup, credentials, governance, and spending explicit where relevant.

### 5.8 `OUTPUT CONTRACT`

Require only the evidence and decisions the next actor needs. Use one final marker only when it supports deterministic routing.

---

## 6. Context economy rules

### 6.1 Include

- the latest owner instruction that changes this task;
- the active owner-approved packet or exact correction packet;
- exact decision IDs, contract sections, code, tests, or threads needed by the task;
- current head/evidence when exact-head identity matters;
- known unresolved conflicts the actor must decide or report;
- explicit exclusions that prevent a likely adjacent-scope error.

### 6.2 Normally omit

- repository identity when the actor already runs inside the repository;
- PR number, title, branch, and base when the prompt is posted on that PR and no cross-PR ambiguity exists;
- complete changed-path lists already defined by the active packet or available in the PR;
- full CI narratives when only the pass/fail and exact-head relationship matter;
- copied packet requirements;
- historical chronology after the controlling current rule is identified;
- implementation conversation or hidden reasoning;
- repeated owner-only prohibitions already enforced by the workflow unless the task creates an exceptional risk;
- unrelated successful evidence.

### 6.3 Failed or superseded work

An implementer or fixer normally receives distilled current requirements and regressions, not failed production code. Direct historical inspection requires one exact forensic question that current authority cannot answer.

---

## 7. Prompt proportionality

These ranges are review triggers, not hard correctness limits.

| Prompt type | Normal size | Minimum semantic content |
|---|---:|---|
| GitHub `@codex review` trigger | 75-250 words; up to 450 for unusual cross-layer risk | mode, authority, focus, materiality, output limit, read-only boundary |
| One local P2 or mechanical correction | 250-700 words | exact defect, files or responsibility, required result, direct oracle, stop conditions |
| Bounded multi-finding fixer packet | 600-1,200 words | dispositions, authority, authorized files, regressions, publication boundary |
| PR-lifetime triage request | 800-1,600 words | current head/evidence, findings, classification scheme, convergence and correction authority |
| New milestone scope-assessment wrapper | 1,200-2,500 words, normally plus a referenced packet | principal result, ownership, context manifest, risk, oracle, exclusions, decision request |
| Owner-approved implementation packet | Follow `PROMPT_TEMPLATE.md` and its current byte ceiling | complete directly executable contract |
| Owner action | Normally 40-180 words | purpose, one command/action, return evidence, stop condition |

### 7.1 Reduce an oversized prompt by

- deleting repository or PR identity already supplied by the invocation;
- replacing copied authority with exact references;
- removing history once the controlling rule is stated;
- deleting evidence that does not affect the actor's decision;
- moving reusable policy into maintained repository standards;
- separating planning, triage, fixing, and review responsibilities;
- limiting audit questions to the actual risk boundary.

### 7.2 Expand an underspecified prompt by

- adding the missing ownership or authority boundary;
- naming the exact decision, packet, finding, or evidence;
- adding a disprovable acceptance or regression oracle;
- identifying the expected session and independence requirement;
- adding concrete stop and escalation conditions;
- clarifying the handoff expected from the actor.

Do not reduce length by removing ownership, acceptance, validation, or material stop conditions.

---

## 8. Actor-specific requirements

### 8.1 Scope assessor

The prompt states:

- the candidate packet and exact authorities;
- the principal result, owner, seams, risk dimensions, and oracle;
- whether this is a new material assessment or a bounded rereview;
- approve/revise/split/exception output choices;
- prohibition on implementation or silent architecture resolution.

Use a fresh session for a new or materially changed packet. A bounded revision may return to the same assessor.

### 8.2 Implementation task

The owner-approved packet is the task authority. A wrapper prompt should normally contain only routing, the exact packet path/version, baseline or branch state not already in the packet, publication instructions, and the hard stop.

Do not create a second monolithic implementation prompt that paraphrases the packet.

### 8.3 PR-lifetime triage architect

The first triage prompt uses `FRESH THEN PR-LIFETIME` and states that the session is distinct from planning, assessment, implementation, and review. It receives persisted findings, current exact-head evidence, active packet authority, classification vocabulary, convergence rules, and authority to produce one bounded correction packet when needed.

The triage actor does not edit repository files or mutate GitHub unless a separately approved administration transaction authorizes that exact operation.

### 8.4 Fixer

A fixer prompt contains:

- exact findings and final triage disposition;
- current expected branch/head when relevant;
- exact authorized files or responsibility boundary;
- required text-level or behavioral outcomes;
- protected current behavior;
- direct regression and broader validation;
- commit/publication boundary;
- stop conditions and final evidence.

A simple P2 fix should not receive the full planning history. A cross-layer correction must not be reduced to a vague one-paragraph instruction.

### 8.5 Auditor or reviewer

The prompt defines the audit mode, current authority, primary risk boundary, materiality standard, and output ceiling. It is read-only unless the workflow explicitly routes a separate fixer task.

### 8.6 Owner action

Use:

```text
Purpose
Run
Return
Stop only if
```

Expose internal hashes, byte counts, guards, or expected metadata only when the owner needs them to choose safely.

---

## 9. GitHub `@codex review` standard

A review comment is already posted on a specific PR. Unless ambiguity or exact-head reconciliation requires otherwise, omit:

- repository name;
- PR number and title;
- branch and base;
- complete changed-path list;
- full active-packet restatement;
- broad CI narrative;
- exhaustive generic mutation prohibitions.

Include an exact head SHA only when:

- distinguishing a corrected head from an earlier review;
- requesting a bounded rereview after correction;
- recording exact-head evidence is operationally necessary;
- the PR may move before the requested review and the identity matters.

### 9.1 Routing record

The architect's own routing record is:

```text
Actor: Primary independent reviewer
Recommended model: Platform-selected GitHub Codex reviewer
Effort: Platform-managed; adversarial/high-depth through requested focus
Session: PLATFORM INVOCATION
Session rationale: Fresh exact-head review independent of planning and implementation context
```

This routing record need not be pasted into the PR comment unless the owner wants it retained there.

### 9.2 Normal PR comment

```text
@codex review

Mode: <primary independent | bounded rereview | final unrestricted> review of the current PR head.

Authority:
- `<active packet path>`
- `<exact decision or contract reference>`

Focus:
- <risk boundary 1>
- <risk boundary 2>

Report only material P1/P2 findings. Ignore style-only observations and behavior explicitly deferred by the packet.
Limit: at most <N> findings and <N> words.
Read-only; do not implement or mutate the PR.
```

### 9.3 Mode differences

**Primary independent review** audits the complete current diff and named principal risks.

**Bounded rereview** names only corrected findings, changed code, and adjacent regression surface. It does not re-paste the original complete review request.

**Final unrestricted review** removes the bounded-finding restriction and reviews the complete stable current head, while retaining the active authority, materiality standard, and output ceiling.

---

## 10. Template files

Use:

```text
docs/codex/templates/actor-prompts/ACTOR_PROMPT_TEMPLATE.md
docs/codex/templates/actor-prompts/GITHUB_CODEX_REVIEW_TEMPLATE.txt
```

The template is modular. Delete unused sections rather than filling them with `not applicable` prose.

---

## 11. Validation checklist

Before issuing a prompt, confirm:

- one actor responsibility is named;
- model and effort are separate and current;
- session and rationale are explicit;
- the session choice protects the required independence or continuity;
- current authority is referenced rather than duplicated;
- only decision-relevant context is included;
- scope and mutation authority are unambiguous;
- the required result or finding standard is concrete;
- validation can disprove the relevant defect;
- stop and escalation conditions are stated;
- output is limited to what the next actor needs;
- prompt size is proportionate to risk and uncertainty;
- GitHub review metadata already supplied by the PR is omitted;
- no actor is asked to implement and independently review its own material work.
