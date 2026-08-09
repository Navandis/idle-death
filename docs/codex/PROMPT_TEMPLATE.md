# Death Idle versioned slice-packet template

**Document role:** Active template for one bounded, directly executable implementation slice
**Repository path:** `docs/codex/PROMPT_TEMPLATE.md`
**Compatibility note:** The filename is retained as a legacy compatibility path. Its active contents define a slice packet, not the historical monolithic prompt model.
**Last updated:** 2026-08-09
**Companions:** `docs/codex/ACTOR_PROMPT_STANDARD.md`, `docs/codex/STANDARD_MILESTONE_SLICE_WORKFLOW.md`, and `docs/codex/CODEX_DESKTOP_WORKFLOW.md`

## 1. Use and provenance

Create one versioned owner-approved packet for one directly executable lettered slice. Conceptual epics do not receive implementation packets. The packet compiles broad planning context into the smallest durable authority a transactional implementer, reviewer, fixer, and owner need.

`PROMPT_TEMPLATE.md` remains the active path to avoid reference churn. The `Prompt` column in `MILESTONES.md` is also a legacy column name pending a separately scoped migration. Historical rows continue to describe their original prompt artifacts, status, and provenance. Only G2-forward directly executable work uses that column to record versioned packet status. Do not rewrite or reclassify completed or superseded prompt bodies.

Before approval, the planning architect verifies live repository state, drafts the packet, obtains a fresh independent scope assessment, incorporates bounded corrections, and obtains explicit owner approval. The implementation task executes the approved packet; it does not author, broaden, replace, or approve its own authority.

The packet is durable task authority. Any separate wrapper prompt for the implementer, scope assessor, reviewer, triage architect, or fixer follows `ACTOR_PROMPT_STANDARD.md` and references this packet rather than paraphrasing it.

Semantic completeness outranks brevity. The active packet must fit within 20,480 bytes only after every required field below is present and unambiguous. Stop and revise the design if the complete contract cannot fit without compressed or omitted rules.

---

# Slice [[SLICE_ID]]: [[TITLE]]

## 2. Identity and delivery metadata

```text
Packet version and date:
Packet status:
Parent epic/sequence:
Expected verified baseline:
Feature branch:
PR target and title:
Primary subsystem owner:
Risk dimensions:
Integration seams:
Implementation actor:
Recommended model:
Effort:
Session:
Session rationale:
Output ceiling:
Hard stop:
```

State whether the packet is proposed, independently assessed, owner-approved, implemented, or historical. Name the exact branch and owner-only actions. Do not rely on relative terms such as `latest` without a verified ref.

The normal implementation routing is a fresh transactional Codex session. An existing session requires an explicit reason that its prior bounded context is useful, it is not near its context limit, and continuity does not compromise independence or scope control. Keep model and effort in separate fields.

## 3. Objective, outcome, and principal transition

Provide:

- one or two sentences defining the concrete result;
- one observable player/developer demonstration;
- one principal behavior, state, or documentation transition.

```text
current state
-> approved result
```

## 4. Sole authoritative context manifest

This table is the sole task manifest. Use exact headings, requirement labels, decision IDs, paths, and reasons. Mark every entry **Modify**, **Add**, **Delete**, or **Inspect only**. Do not add a second competing reading list.

| Priority | Source/path | Exact section, record, or line-bounded artifact | Why it applies | Change status |
|---:|---|---|---|---|
| 1 | Latest owner instruction | Approval/correction of this packet | Current authority | Inspect only |
| 2 | `AGENTS.md` | Full file | Universal router | Inspect only |
| 3 | This packet | Full file | Executable task authority | Add/modify unchanged after approval |
| 4 | [[PATH]] | [[EXACT HEADING/ID]] | [[REASON]] | [[STATUS]] |

Also list:

- exact implementation code paths to inspect or change;
- exact tests, fixtures, content, tools, and validation paths;
- exact historical/forensic reference, only when current authority cannot answer a concrete question;
- explicitly excluded failed branches, superseded prompt bodies, transcripts, broad documents, and later-slice material.

When more than one authority band is relevant, label entries as current implementation, current authority, future/open owner decision, or historical/superseded evidence. The implementer reads the root, this packet, and this manifest—not whole documents by default.

## 5. Included scope and ownership

Specify:

- authoritative state or behavior added/changed, or `None`;
- legal mutation/read owner and explicit non-owners;
- principal transition and integration seams;
- persistence/schema/content-revision effect, or `None`;
- required documentation synchronization;
- verification package and evidence owner.

For state, reporting, persistence, or projection work, include a stored-versus-derived table. Otherwise state why it is not applicable.

| Value/fact | Stored or derived | Owner | Persistence | Reason |
|---|---|---|---|---|
| [[ITEM]] | [[STORED/DERIVED]] | [[OWNER]] | [[YES/NO]] | [[WHY]] |

## 6. Explicit exclusions

List tempting adjacent work, later slices, architecture/product decisions, unapproved dependencies, historical implementations, and prohibited restoration. Exclusions are enforceable scope boundaries, not a generic disclaimer.

Do not repeat generic workflow prohibitions at length when `AGENTS.md`, `CODEX_DESKTOP_WORKFLOW.md`, or another exact authority already governs them. Repeat a prohibition only when the present slice creates a realistic task-specific risk.

## 7. Behavioral and transition requirements

Use stable IDs only where they improve traceability.

### [[REQ-ID]] - [[NAME]]

State exact preconditions, transition, result, ownership, units/order, failure/no-mutation behavior, and later-slice exclusions. Do not prescribe private helpers or class layouts unless ownership or safety requires them.

## 8. Acceptance and test oracle

The oracle must be able to disprove defects. Cover the applicable groups:

- positive behavior and developer/player demonstration;
- boundary/order/identity/overflow behavior;
- malformed input, aliasing, and no-mutation failure behavior;
- equivalence, idempotency, migration, save/load, or detachment behavior;
- exact changed-path/name/status set and forbidden-path checks;
- focused and broader automated commands;
- owner-run/manual checks and exact-head evidence;
- documentation/link/diff checks;
- final handoff fields and hard stop.

| AC | Observable pass condition | Evidence/command | Executor |
|---|---|---|---|
| AC-01 | [[EXACT CONDITION]] | [[COMMAND/ARTIFACT]] | [[IMPLEMENTER/CI/OWNER]] |

Do not use size, file count, marker count, or green CI as a substitute for semantic completeness. Map every required packet field and protected invariant to a positive pass/fail check.

## 9. Scope, convergence, and escalation guards

Record informed estimates and exact ceilings:

```text
Primary owners:
Authoritative aggregates:
Schema transitions:
Risk dimensions:
Cross-layer seams:
Expected changed paths/files/lines:
Authored-data volume:
Owner-verification surface:
```

State mandatory stop conditions. Stop before adding another owner, risk dimension, seam, schema transition, unapproved path, or material scope beyond the assessment. After two substantial correction rounds, require explicit convergence assessment. Round count alone is never dispositive; continue only when remaining findings are local, understood, testable, and within the design.

State the independent scope-assessor and PR-lifetime triage boundaries. One slice keeps one branch and one PR. Material correction rounds normally use a fresh bounded fixer context on that same branch/PR; a trivial mechanical correction may remain in the implementation task only when explicitly justified and directly provable.

Any material change to the principal transition, ownership, schema, milestone sequence, or oracle returns to planning and fresh independent assessment before implementation continues.

## 10. Delivery, review, verification, and owner interface

Define the actor handoff:

```text
planning architect
-> fresh independent scope assessor
-> owner approval
-> transactional implementer
-> PR publication
-> exact-head CI
-> compact paste-ready exact-head review trigger
-> primary independent reviewer
-> persisted review findings
-> fresh PR-lifetime triage architect
-> bounded fixer task when correction is required
-> new-head CI and bounded rereview
-> bounded-rereview findings returned to PR-lifetime triage architect
-> convergence assessment when required
-> final unrestricted review
-> material-thread reconciliation
-> applicable exact-head owner verification
-> owner integration
```

Provide:

- publication helper or connector path;
- required PR body and handoff evidence;
- targeted and unrestricted review boundary;
- CI and owner-verification ordering;
- exact-head invalidation rule;
- merge/close/delete/force/replacement/history authority;
- final hard stop without merge.

Every architect-drafted wrapper or handoff prompt states:

```text
Actor
Recommended model
Effort
Session
Session rationale
```

Use `ACTOR_PROMPT_STANDARD.md` for fresh-versus-existing-session selection and prompt proportionality.

The GitHub `@codex review` comment should normally contain only the review mode, active authority, two to five risk bullets, materiality standard, output ceiling, and read-only boundary. Do not repeat repository, PR, branch, base, complete path list, or full packet content already supplied by the PR and current packet unless an exact ambiguity requires it.

Owner-facing instructions use:

```text
Purpose
Run
Return
Stop only if
```

Prefill the exact command, PR head, expected artifact/log, and decision alternatives when practical. Keep routine internal guard detail in scripts, CI, tracked artifacts, or architect analysis.

## 11. Final response contract

Report only facts supported by the implementation and evidence:

```text
Result
Exact files/path statuses
Verification actually run
Branch / PR / exact head
Assumptions
Pending owner evidence
Known limitations and risks
Deferred work
Hard stop reached
```

Never claim a pending merge gate passed. Do not merge, close, delete, force, rewrite, or replace unless the owner explicitly authorizes that exact action.
