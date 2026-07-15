# Death Idle Codex Milestone Prompt Template

**Document role:** Reusable authoring template for one bounded Codex implementation milestone  
**Repository path:** `docs/codex/PROMPT_TEMPLATE.md`  
**Document status:** Phase 8 approved  
**Template revision:** 4  
**Last updated:** 2026-07-15  
**Companion documents:** [Milestones](MILESTONES.md), [Architecture](ARCHITECTURE.md), [Data and content contracts](DATA_AND_CONTENT_CONTRACTS.md), [Implementation rules](IMPLEMENTATION_RULES.md), [Testing and validation](TESTING_AND_VALIDATION.md), [Owner verification workflow](OWNER_VERIFICATION_WORKFLOW.md), [Decisions](DECISIONS.md), [Milestone recalibration](MILESTONE_RECALIBRATION_PROPOSAL.md), [Prototype source of truth](../design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md), and [Idle-fork source of truth](../design/IDLE_FORK_SOURCE_OF_TRUTH.md)

## 1. Purpose

Use this template to create one versioned prompt for one approved implementation slice in `docs/codex/MILESTONES.md`. Under `DEC-0033`, conceptual epics are planning containers and never receive direct implementation prompts.

The template standardizes scope, traceability, verification, save/load expectations, and Codex handoff reporting. It does not replace the milestone definition, design sources, architecture, accepted decisions, or root `AGENTS.md`.

Do not use this file itself as an implementation prompt. An instantiated prompt belongs under:

```text
docs/codex/milestone-prompts/M[NN][LETTER]-[short-kebab-case-title].md
```

Copy only the section beginning with `# Milestone [[MILESTONE_ID]]` through the end of `## Final response format`. Replace every placeholder and remove all template-author notes before requesting approval or execution.

## 2. Prompt authoring workflow

Before drafting a milestone prompt:

1. Read the current implementation-slice definition, its parent conceptual epic, dependencies, decision gates, and status in `docs/codex/MILESTONES.md`.
2. Confirm that the selected work item is directly executable. Do not instantiate a prompt for a conceptual epic.
3. Re-read all accepted decisions that affect the slice, especially `DEC-0033`.
4. Inspect the current repository rather than relying on the state that existed when the milestone map was written.
5. Confirm that required prior slices are merged and that their documented verification is not failed or blocked.
6. Identify one primary subsystem owner and the smallest concrete result that satisfies the slice without importing later-slice work.
7. Complete the scope and review-surface assessment: risk dimensions, cross-layer seams, estimated source/test files, estimated code/test lines, authored-data volume, owner package, and guardrail result.
8. Split the work or obtain explicit owner approval when a mandatory review trigger is crossed.
9. Add exact requirement labels, decision IDs, paths, commands, and observable pass conditions.
10. Keep provisional balance values configurable and identify their status explicitly.
11. Separate checks Codex can run from checks the project owner must run on the Windows Godot machine.
12. Decide the owner verification package under `OWNER_VERIFICATION_WORKFLOW.md`: canonical wrapper only, milestone-specific PowerShell script, script plus interactive checklist, or a justified direct command/checklist file.
13. Use `Not applicable` with a reason when a mandatory section does not apply. Do not delete the section.
14. Update the prompt version and date whenever an approved prompt changes materially.

Once implementation has started, do not silently rewrite the prompt. A material change requires a new prompt version, an explanation of what changed, and any necessary update to `MILESTONES.md` or `DECISIONS.md`.

### 2.1 Prompt authorship boundary

Milestone prompts are drafted through the project planning workflow, reviewed by the project owner, and explicitly approved before execution. The normal implementation Codex task executes that approved prompt. It does not author, materially rewrite, broaden, or replace its own prompt, and it does not create a future milestone prompt as part of implementation work.

Codex may update milestone status or other documentation only when the approved implementation prompt explicitly includes that update. Documentation maintenance does not authorize Codex to redefine milestone scope, acceptance criteria, owner gates, design requirements, or architecture decisions.

If implementation exposes a material prompt defect, contradiction, or missing decision, Codex must stop the affected work and report it. The planning workflow then produces a new prompt version for owner approval. Codex may describe a proposed clarification in its handoff, but it must not silently edit the prompt to make the task easier or to legitimize work already performed.

A separate owner-authorized prompt-authoring task may ask Codex to help inspect repository facts or draft text, but that is not the default Death Idle implementation workflow and does not make Codex the approver of its own instructions.

### 2.2 Owner verification evidence

Owner-run Windows, editor, visual, audio, functional, A/B, and Steam checks use the following evidence policy:

- Every owner-run check marked `Merge gate: Yes` requires an explicit owner result before merge. Silence or the passage of time is not evidence that the check was run or passed.
- A non-merge-gate exploratory check may proceed without a formal result. In that case, record only `No blocking issue reported`; do not record `Passed`.
- The owner does not need to edit a repository Markdown file manually for each validation cycle. A pull-request comment or another explicit project-owner message is sufficient evidence.
- The minimum useful confirmation states the tested commit or branch, `PASS` or `FAIL`, the checks performed, and the date. Example: `Owner verification: PASS - commit abc1234 - Windows GUT and M00 manual smoke flow - 2026-07-13.`
- Until explicit evidence exists, Codex and repository status documents must use `Pending owner verification` and keep milestone verification `Partial` when any pending item is a merge gate.
- After explicit owner confirmation and merge, `MILESTONES.md` may be synchronized by the next planning package or a scoped documentation update. The owner is not required to hand-edit the file merely to communicate the result.
- A reported failure returns to troubleshooting and triage. The planning workflow decides whether the correct response is a follow-up Codex fix prompt, more diagnostics, a prompt revision, or a design decision.

### 2.3 Owner verification package

When a milestone has owner-run checks, the prompt must choose and specify the package defined in `OWNER_VERIFICATION_WORKFLOW.md`.

Preferred order:

1. Use the canonical `tools/test/run_gut.ps1` only when it fully covers the owner automation.
2. Otherwise require Codex to add `tools/test/owner/run_mNN_owner_verification.ps1` in the milestone pull request.
3. Require a companion `docs/codex/owner-checklists/MNN-owner-verification.md` when visual, editor, audio, A/B, functional, or live Steam observations remain.
4. Use a direct `.md` or `.txt` command sheet only when a script is unsafe or would add no practical value; state the reason.

A milestone-specific PowerShell script must write a UTF-8 log under the ignored `tools/test/owner/logs/` directory, record the requested PR head or commit, tool versions, commands, exit codes, cleanup, and final result, and return nonzero on an automated failure. Git CLI must remain optional; accept a `-CommitSha` parameter when exact evidence is a merge gate.

The prompt must name the expected script/checklist paths and the exact owner invocation. Generated logs are evidence to upload or quote, not files to commit.

### 2.4 Scope assessment and split gate

Every post-M03 implementation prompt must contain a completed **Scope and review-surface assessment**. The assessment is a planning control, not a promise that an exact line count can be predicted.

Normal targets under `DEC-0033` are:

- one primary subsystem owner;
- one principal behavior or state transition;
- no more than two cross-layer integration seams;
- approximately 10–25 non-documentation source/test files;
- approximately 500–1,200 non-documentation code/test lines, excluding `.uid` files and repetitive authored data;
- one focused owner-verification package.

Mandatory split review is triggered by four or more risk dimensions, more than one primary subsystem owner, more than one save transition, native/platform work mixed with unrelated gameplay, production-catalog bulk mixed with a new framework, a forecast above approximately 35 source/test files, or a forecast above approximately 1,500 code/test lines.

A trigger does not create an automatic rejection. The prompt must either split the work or record the specific owner-approved reason that the task remains coherent. During implementation, material growth beyond the approved assessment is a stop-and-report condition.

## 3. Placeholder and identifier rules

- Replace every `[[REQUIRED_PLACEHOLDER]]` before the prompt is approved.
- Remove any `[[OPTIONAL: ...]]` item that does not apply.
- Use ISO dates in `YYYY-MM-DD` format.
- Use the exact implementation-slice ID from `MILESTONES.md`, including its letter suffix such as `M04A`.
- Give required behaviors stable local IDs such as `RB-01`.
- Give state transitions stable local IDs such as `ST-01`.
- Give acceptance criteria stable local IDs such as `AC-01`.
- Reference existing design requirement labels, canonical IDs, and decision IDs exactly.
- Do not invent final values where authoritative sources mark values provisional, open, tentative, or TBD.
- Do not leave generic phrases such as "test it," "make it work," or "handle errors" without an observable result.

---

# Implementation slice [[MILESTONE_ID]]: [[MILESTONE_TITLE]]

**Prompt version:** [[PROMPT_VERSION]]  
**Prompt date:** [[YYYY-MM-DD]]  
**Prompt status:** [[Draft | Approved]]  
**Work item type:** Implementation slice  
**Parent conceptual epic:** [[PARENT EPIC ID AND HEADING]]  
**Milestone definition:** `docs/codex/MILESTONES.md` - [[EXACT IMPLEMENTATION-SLICE HEADING]]  
**Recommended task size:** [[TASK SIZE FROM MILESTONE MAP]]  
**Scope-gate result:** [[Within guardrails | Owner-approved exception with exact reason]]  
**Expected base branch or ref:** [[BASE BRANCH, COMMIT, OR "current default branch after required dependencies merge"]]  
**Planned prompt path:** `docs/codex/milestone-prompts/[[PROMPT_FILENAME]].md`

> This prompt authorizes only the milestone scope below. It does not authorize future milestones, broad cleanup, dependency changes, or silent changes to accepted design and architecture decisions.

## Execution protocol

Before editing:

1. Read `AGENTS.md` completely.
2. Read every document and section listed under **Authoritative context**.
3. Inspect the repository state, relevant implementation, tests, addon metadata, and `git status`.
4. Verify the dependencies and baseline assumptions in this prompt.
5. Briefly state the proposed approach, primary subsystem owner, expected files, expected cross-layer seams, verification plan, and whether the repository still fits the approved scope assessment before making non-trivial edits.
6. Report any material mismatch between this prompt and the repository before implementing dependent behavior.
7. Stop before broadening the task when actual implementation needs another primary owner, another risk dimension, or material growth beyond the approved review surface.

During implementation:

- Limit changes to this milestone and its acceptance criteria.
- Preserve unrelated work and do not reset, discard, rename, or reformat unrelated files.
- Do not implement later milestone behavior merely because the current design makes it visible.
- Keep provisional values in configurable content or test fixtures rather than embedding permanent constants in presentation code.
- Preserve deterministic behavior, explicit time units, save integrity, and the documented ownership boundaries.
- Add junior-readable GDScript documentation and reasoning comments required by `AGENTS.md` and `IMPLEMENTATION_RULES.md`.
- Add or update the tests needed to prove the behavior.
- Run all Codex-executable verification listed in this prompt.
- State honestly which owner-run Windows, visual, audio, or Steam checks remain pending.
- Do not create, rewrite, or broaden the current milestone prompt or any future milestone prompt. Report a material prompt defect and wait for an owner-approved revision.
- Track material scope growth against the approved assessment. Stop and report before crossing a mandatory split trigger or adding an unapproved subsystem owner.

Do not describe the milestone as complete when an acceptance criterion is failed, blocked, or unverified. A pull request may be ready for owner testing while verification remains `Partial`, but a listed merge gate must receive explicit passing evidence before merge. Owner silence is not a passing result.

## Objective

[[ONE OR TWO SENTENCES DEFINING THE CONCRETE RESULT CODEX MUST PRODUCE]]

## Player or developer outcome

[[DESCRIBE THE OBSERVABLE PLAYER-VISIBLE OR DEVELOPER-VISIBLE RESULT. STATE HOW IT IS DEMONSTRATED.]]

## Authoritative context

Read the following before editing. The entries must name exact sections, requirement labels, or decision IDs rather than only listing whole documents when a narrower reference is practical.

| Priority | Source | Required sections, labels, or records | Why it applies |
|---:|---|---|---|
| 1 | `AGENTS.md` | Full file | Repository-wide operating rules and source hierarchy |
| 2 | `docs/codex/MILESTONES.md` | [[MILESTONE HEADING, DEPENDENCY GATES, AND RELEVANT STATUS ROW]] | Approved milestone scope and merge gates |
| 3 | `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md` | [[PROTOTYPE SECTIONS AND REQUIREMENT LABELS]] | Prototype-specific behavior and acceptance |
| 4 | `docs/design/IDLE_FORK_SOURCE_OF_TRUTH.md` | [[IDLE-FORK SECTIONS AND IF-REQ LABELS]] | Broader system invariants and terminology |
| 5 | `docs/codex/ARCHITECTURE.md` | [[ARCHITECTURE SECTIONS]] | Ownership, data flow, time, persistence, and application boundaries |
| 6 | `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | [[CONTRACT SECTIONS, IDS, OR SCHEMAS]] | Canonical IDs and data contracts |
| 7 | `docs/codex/IMPLEMENTATION_RULES.md` | [[IMPLEMENTATION-RULE SECTIONS]] | GDScript, comments, determinism, and repository conventions |
| 8 | `docs/codex/TESTING_AND_VALIDATION.md` | [[TEST SECTIONS AND CANONICAL COMMANDS]] | Required test environments and evidence |
| 9 | `docs/codex/OWNER_VERIFICATION_WORKFLOW.md` | [[APPLICABLE SCRIPT, LOG, AND CHECKLIST RULES OR "Not applicable"]] | Packaging for owner-run Windows and interactive checks |
| 10 | `docs/codex/DECISIONS.md` | [[DECISION IDS]] | Accepted decisions that constrain this milestone |
| 11 | [[OPTIONAL: PRIOR PROMPT, PR, HANDOFF, ISSUE, OR FILE]] | [[EXACT RELEVANT PART]] | [[WHY IT APPLIES]] |

This prompt is the latest owner-approved task instruction only within its stated scope. It does not silently supersede accepted decisions or protected design invariants. When two applicable sources conflict, stop and report the conflict, practical consequence, and options unless the documented hierarchy already resolves it.

## Repository state

The expected baseline at task start is:

| Item | Expected state | Evidence or path to inspect |
|---|---|---|
| Required prior milestones | [[MERGED MILESTONE IDS AND EXPECTED VERIFICATION STATUS]] | `docs/codex/MILESTONES.md` and repository history |
| Existing implementation | [[RELEVANT CLASSES, SCENES, CONTENT, TESTS, OR "none"]] | [[PATHS]] |
| Existing configuration | [[RELEVANT PROJECT SETTINGS, ADDONS, WRAPPERS, OR SAVE VERSION]] | [[PATHS]] |
| Known temporary scaffolding | [[ITEMS THAT MUST BE PRESERVED OR MAY BE REPLACED]] | [[PATHS]] |
| Known absence | [[SYSTEMS OR FILES THAT MUST NOT BE ASSUMED TO EXIST]] | Repository inspection |
| Working-tree expectation | Clean except for task changes | `git status --short` |

Verify this table before editing. If the repository is materially ahead of, behind, or inconsistent with it, report the mismatch. Do not overwrite a newer implementation or recreate an already completed system from the prompt text.

## Dependencies

| Dependency or gate | Required state | Required before | How to verify |
|---|---|---|---|
| [[PRIOR MILESTONE OR GATE]] | [[STATE]] | [[Implementation | PR | Merge]] | [[EVIDENCE]] |
| [[TECHNICAL DEPENDENCY]] | [[VERSION OR CONFIGURATION]] | [[Implementation | Verification]] | [[COMMAND OR FILE]] |
| [[OWNER-RUN OR EXTERNAL PREREQUISITE]] | [[STATE]] | [[PR | Merge | Later release gate]] | [[EVIDENCE]] |

Do not weaken a dependency gate to make the task appear complete. A prerequisite that is intentionally deferred must be identified as deferred and must not be required by this milestone's acceptance criteria.

## Scope and review-surface assessment

Complete this table before prompt approval. Use informed estimates and name uncertainty rather than inventing precision.

| Assessment item | Approved estimate or result |
|---|---|
| Parent conceptual epic | [[EPIC ID]] |
| Primary subsystem owner | [[ONE OWNER]] |
| Principal behavior/state transition | [[ONE PRINCIPAL RESULT]] |
| New authoritative state ownership | [[None | Describe]] |
| Save-schema or migration change | [[None | One change and gate]] |
| Deterministic algorithm/boundary work | [[None | Describe]] |
| New player-facing UI flow | [[None | Describe one flow]] |
| Native/platform integration | [[None | Describe]] |
| Bulk authored content | [[None | Small fixture set | Describe exception]] |
| Live/offline/forecast equivalence | [[None | Describe]] |
| Exactly-once/transactional progression | [[None | Describe]] |
| Independently testable domain services | [[COUNT AND NAMES]] |
| Cross-layer integration seams | [[0–2 NORMALLY; NAME THEM]] |
| Estimated non-documentation source/test files | [[ESTIMATE]] |
| Estimated non-documentation code/test line delta | [[ESTIMATE; EXCLUDE `.uid` AND REPETITIVE AUTHORED DATA]] |
| Owner verification package | [[PACKAGE AND PATHS]] |
| Mandatory split trigger crossed? | [[No | Yes, split performed | Yes, owner-approved exception]] |
| Exception rationale/approval evidence | [[Not applicable | EXACT RATIONALE]] |

Rules:

- Four or more risk dimensions require split review.
- More than one primary subsystem owner requires split review.
- A forecast above approximately 35 source/test files or 1,500 code/test lines requires split review.
- Native/platform work may not be mixed with unrelated gameplay without explicit owner approval.
- Production-catalog bulk may not be mixed with a new framework without explicit owner approval.
- Estimates do not authorize extra work. Scope remains defined by the approved behaviors and acceptance criteria.
- If implementation materially exceeds this assessment, Codex stops and reports the difference before continuing.

## Scope

Implement only the following:

1. [[IN-SCOPE ITEM]]
2. [[IN-SCOPE ITEM]]
3. [[IN-SCOPE ITEM]]

Include the minimum supporting refactor, data, tests, and documentation needed to make these items correct and reviewable. Explain any supporting change that is not obvious from the list.

## Non-goals

Do not implement or refactor:

1. [[EXPLICIT NON-GOAL]]
2. [[FUTURE MILESTONE BEHAVIOR]]
3. [[UNRELATED SYSTEM OR POLISH]]
4. Broad cleanup, dependency upgrades, engine or renderer changes, speculative abstractions, or directory reorganizations not required by this milestone.

A visible placeholder or interface for later work is allowed only when the milestone definition explicitly requires it or omitting it would cause immediate rework in the next approved dependency.

## Required behavior

Every row must be testable or manually observable.

| ID | Required behavior | Source trace |
|---|---|---|
| `RB-01` | [[FUNCTIONAL REQUIREMENT]] | [[REQUIREMENT LABEL, DECISION, OR SECTION]] |
| `RB-02` | [[VALIDATION OR FAILURE REQUIREMENT]] | [[SOURCE]] |
| `RB-03` | [[DETERMINISM, SAVE, OR RECOVERY REQUIREMENT]] | [[SOURCE]] |
| `RB-04` | [[DEMONSTRATION OR PRESENTATION REQUIREMENT]] | [[SOURCE]] |

Include applicable behavior for:

- valid input and normal success;
- invalid input without partial mutation;
- duplicate or repeated execution;
- interruption, reload, or retry;
- non-recommended but valid player behavior;
- zero, boundary, depletion, or exactly-once cases;
- unavailable platform service when the milestone touches one.

Do not add cases that belong only to future milestones.

## State transitions

Describe authoritative transitions, not only UI events. For an infrastructure milestone, use equivalent invocation and failure states.

| ID | Initial state | Trigger or command | Required resulting state | Failure or recovery behavior | Persistence, report, or event effect |
|---|---|---|---|---|---|
| `ST-01` | [[INITIAL STATE]] | [[TRIGGER]] | [[SUCCESS STATE]] | [[FAILURE/RECOVERY]] | [[SAVE/EVENT EFFECT]] |
| `ST-02` | [[INITIAL STATE]] | [[TRIGGER]] | [[INTERMEDIATE OR BOUNDARY STATE]] | [[FAILURE/RECOVERY]] | [[SAVE/EVENT EFFECT]] |
| `ST-03` | [[INITIAL STATE]] | [[RELOAD, RETRY, OR DUPLICATE TRIGGER]] | [[IDEMPOTENT RESULT]] | [[FAILURE/RECOVERY]] | [[SAVE/EVENT EFFECT]] |

State which component owns each mutation when ownership is not obvious. UI callbacks and tutorial presentation must not become substitute owners of domain state.

## Data and content

| Canonical ID, setting, or file | Type | Required value or shape | Status | Source |
|---|---|---|---|---|
| [[ID OR PATH]] | [[FORM, THRESHOLD, CONFIG, FIXTURE, ETC.]] | [[REQUIREMENT]] | [[Confirmed | Provisional | Test-only | Existing]] | [[SOURCE]] |
| [[ID OR PATH]] | [[TYPE]] | [[REQUIREMENT]] | [[STATUS]] | [[SOURCE]] |

Rules:

- Use exact canonical IDs from `DATA_AND_CONTENT_CONTRACTS.md`.
- Separate stable IDs from player-facing names.
- Keep provisional costs, rates, durations, coefficients, limits, and balance values configurable.
- Do not invent missing final balance values. Use a clearly labelled test fixture or stop and ask when a real content value is required.
- Validate duplicate IDs, missing references, wrong prefixes, invalid ranges, and unsupported effects when applicable.
- Do not encode Form, Threshold, Retinue, or tutorial behavior as player-facing-name checks.

Write `Not applicable - [[REASON]]` when the milestone introduces no authored data or configuration.

## UI and presentation

[[DESCRIBE ONLY THE UI OR DEVELOPER-FACING PRESENTATION REQUIRED BY THIS MILESTONE. USE "Not applicable" WITH A REASON WHEN NONE IS REQUIRED.]]

| Surface or state | Required presentation and interaction | Explicitly deferred |
|---|---|---|
| [[SCREEN, DEBUG VIEW, CLI OUTPUT, OR REPORT]] | [[VISIBLE FIELDS, INPUTS, FEEDBACK, EMPTY/ERROR STATE]] | [[POLISH OR FUTURE FEATURES]] |

Applicable baseline constraints:

- Use the 1920 x 1080 reference layout and preserve reasonable resizing behavior.
- Presentation observes committed state and issues commands; it does not grant resources or run a competing simulation.
- Menus, dialogue, reports, and tutorial overlays do not pause production.
- Use placeholders rather than inventing final art, audio, animation, or narrative content.
- Show before/after values when the milestone requires a comparison.
- Keep hidden, identified, and charted information from leaking across disclosure boundaries.

Retain only the baseline bullets that materially apply in the instantiated prompt.

## Architecture constraints

The repository architecture remains authoritative. Restate only constraints that are especially important for this milestone:

- [[OWNERSHIP OR DEPENDENCY BOUNDARY]]
- [[DETERMINISM OR TIME RULE]]
- [[SAVE, TRANSACTION, OR MIGRATION RULE]]
- [[CONTENT OR MODIFIER-GRAMMAR RULE]]
- [[TUTORIAL, REPORT, FORECAST, OR PRESENTATION RULE]]

Unless this milestone explicitly says otherwise, do not:

- add a gameplay autoload;
- add or update a third-party dependency;
- change Godot version, renderer, reference viewport, or scripting language;
- change the save container or schema semantics outside the approved persistence scope;
- add a local-device-time fallback or move platform time into domain simulation;
- add Steam features outside the approved trusted-time adapter;
- introduce authoritative randomness;
- make UI or tutorial code the owner of domain rules;
- build a framework for deferred Forms, Retinues, Writs, regions, or prestige systems.

## Expected files

This list is an informed expectation, not permission to edit every path. Codex may correct it after inspection, but must explain meaningful deviations in the pre-edit plan and final response.

| Path or area | Expected action | Purpose |
|---|---|---|
| `[[PATH]]` | [[Add | Modify | Delete | Inspect only]] | [[PURPOSE]] |
| `[[PATH]]` | [[ACTION]] | [[PURPOSE]] |
| `tests/[[PATH]]` | [[ACTION]] | [[BEHAVIOR PROVED]] |
| `docs/[[PATH]]` | [[ACTION]] | [[CONTRACT OR STATUS UPDATE]] |
| `tools/test/owner/[[OPTIONAL MILESTONE SCRIPT]]` | [[Add | Modify | Not applicable]] | [[OWNER AUTOMATION AND GENERATED-LOG PURPOSE]] |
| `docs/codex/owner-checklists/[[OPTIONAL CHECKLIST]]` | [[Add | Modify | Not applicable]] | [[INTERACTIVE OWNER CHECKS]] |

Do not create empty directories solely to match a planned tree. Do not rename or reorganize unrelated assets or temporary scaffolding.

## Acceptance criteria

Each criterion must be binary and observable. Map every criterion to evidence that can actually be produced in the available environments.

| ID | Pass condition | Verification evidence | Merge gate? |
|---|---|---|---:|
| `AC-01` | [[BINARY OBSERVABLE CONDITION]] | [[TEST, COMMAND, OR MANUAL STEP]] | [[Yes | No]] |
| `AC-02` | [[BINARY OBSERVABLE CONDITION]] | [[EVIDENCE]] | [[Yes | No]] |
| `AC-03` | [[BINARY OBSERVABLE CONDITION]] | [[EVIDENCE]] | [[Yes | No]] |
| `AC-04` | All changed non-trivial GDScript follows the repository documentation and junior-reviewer comment rules. | Review changed scripts against `AGENTS.md` and `IMPLEMENTATION_RULES.md`. | Yes |
| `AC-05` | All maintained documents made inaccurate by this change are updated in the same pull request. | Changed-file review and link validation. | Yes |
| `AC-06` | The implementation remains within the approved slice and review-surface assessment, or any material scope growth received a separately approved prompt revision before implementation continued. | Compare planned and actual subsystem owners, risk dimensions, changed source/test files, and code/test line delta. | Yes |

Completion rules:

- A criterion is `Passed` only when its listed evidence was actually produced.
- A criterion that requires the owner-run Windows, visual, audio, functional, A/B, or Steam environment is `Pending` until the owner records the result explicitly.
- Owner silence is not evidence of a pass. For a non-merge-gate exploratory check, silence may be recorded only as `No blocking issue reported`.
- A pending merge-gate criterion prevents merge and keeps milestone verification `Partial`.
- A failed criterion prevents completion even when the main happy path appears to work.
- Do not weaken or delete an acceptance criterion after implementation begins without owner approval and a prompt version update.

## Automated verification

Use the current canonical commands in `TESTING_AND_VALIDATION.md`. Commands below must be exact for the repository state expected by this milestone.

### Codex Cloud or Linux checks

| Order | Command | Purpose | Required result |
|---:|---|---|---|
| 1 | `[[IMPORT OR SETUP COMMAND]]` | [[PURPOSE]] | [[PASS CONDITION]] |
| 2 | `[[FOCUSED TEST COMMAND]]` | [[PURPOSE]] | [[PASS CONDITION]] |
| 3 | `[[FULL SUITE COMMAND, NORMALLY ./tools/test/run_gut.sh AFTER M00]]` | Regression coverage | Exit code 0 and no new parser/resource errors |
| 4 | `[[OPTIONAL VALIDATOR OR SMOKE COMMAND]]` | [[PURPOSE]] | [[PASS CONDITION]] |

Codex must record the exact command, exit code, and meaningful result. It must not claim a command passed if it was not run. A focused test used while iterating does not replace the applicable broader suite before completion.

### Negative and recovery checks

| Scenario | Method | Expected result |
|---|---|---|
| [[INVALID INPUT, FAILURE PROPAGATION, DUPLICATE LOAD, OR INTERRUPTED TRANSACTION]] | [[TEST OR SAFE TEMPORARY METHOD]] | [[EXPECTED FAILURE/RECOVERY]] |

Do not leave deliberately failing tests, temporary saves, logs, generated result files, or debug-only state in the final diff unless the milestone explicitly requires a committed fixture.

### Owner-run Windows automated checks

| Command or action | Purpose | Required result | Merge gate? |
|---|---|---|---:|
| `[[NORMALLY .\tools\test\run_gut.ps1 AFTER M00]]` | Run the same checked-in suite under Windows Godot 4.7 | Exit code 0 | [[Yes | No]] |
| [[OPTIONAL WINDOWS-SPECIFIC COMMAND]] | [[PURPOSE]] | [[RESULT]] | [[Yes | No]] |

Codex cannot mark an owner-run check as passed unless the owner explicitly reports the result for the tested commit or branch. In the pull-request handoff, label it `Pending owner verification` when it has not been run or no result has been reported. The owner may provide a lightweight pull-request comment or project-owner message; no manual Markdown edit is required. Do not modify the wrappers or tests to hide a platform-specific failure.

**Owner package for this milestone:** [[CANONICAL WRAPPER ONLY | MILESTONE-SPECIFIC POWERSHELL SCRIPT | SCRIPT PLUS CHECKLIST | DIRECT COMMAND/CHECKLIST FILE WITH REASON]]  
**Expected PowerShell path:** [[PATH OR "Not applicable"]]  
**Generated log path:** [[NORMALLY `tools/test/owner/logs/` OR "Not applicable"]]  
**Expected owner invocation:** `[[COPY/PASTE COMMAND OR "Not applicable"]]`  
**Interactive checklist path:** [[PATH OR "Not applicable"]]

When a milestone-specific script is required, Codex must create or update it in the same pull request, make Git CLI optional, capture the requested PR head or commit, record commands and exit codes, clean temporary artifacts, rerun the clean regression suite after intentional failures, and print the generated UTF-8 log path. The log directory must remain ignored by Git.

For a documentation-only milestone, state which automated checks are intentionally not required and why.

## Manual verification

Provide exact reproduction steps. Separate what Codex can observe from what requires the Windows Godot machine, visual inspection, audio, or a live Steam client.

| Step | Actor/environment | Action | Expected result | Merge gate? |
|---:|---|---|---|---:|
| 1 | [[CODEX CLOUD, OWNER WINDOWS, OR BOTH]] | [[EXACT STEP]] | [[VISIBLE RESULT]] | [[Yes | No]] |
| 2 | [[ACTOR]] | [[EXACT STEP]] | [[VISIBLE RESULT]] | [[Yes | No]] |
| 3 | [[ACTOR]] | [[EXACT STEP]] | [[VISIBLE RESULT]] | [[Yes | No]] |

Manual steps must identify required setup, starting state, inputs, expected state changes, and cleanup. Do not write only "test in editor." When several owner steps are required, place the exact checklist in the repository path named above rather than forcing the owner to reconstruct it from the pull-request description.

When a visual, functional, A/B, audio, or Steam check cannot be performed by Codex, implementation may still be delivered for owner testing if the milestone permits it. The final response must call the check pending, not passed. A non-gating check with no reported issue may later be summarized as `No blocking issue reported`, but only an explicit owner result can satisfy a merge gate.

## Save/load verification

[[STATE WHETHER THIS MILESTONE CHANGES AUTHORITATIVE STATE, SERIALIZED FIELDS, SAVE CHECKPOINTS, MIGRATIONS, OR OFFLINE RESOLUTION.]]

| Scenario | Setup and save point | Reload, retry, or recovery action | Expected result |
|---|---|---|---|
| [[ROUND TRIP]] | [[SETUP]] | [[RELOAD]] | [[EXPECTED STATE]] |
| [[INTERRUPTION OR DUPLICATE]] | [[SETUP]] | [[ACTION]] | [[IDEMPOTENT RESULT]] |
| [[MIGRATION OR BACKUP, IF APPLICABLE]] | [[SETUP]] | [[ACTION]] | [[EXPECTED RESULT]] |

Rules:

- If serialized state changes, update the schema contract, codec, migrations or reset decision, fixtures, and tests in the same task.
- Verify that repeated load does not duplicate rewards, progress, reports, reservations, or unlocks.
- Verify that UI scene state is not required to reconstruct gameplay.
- Use exact integer and time-unit contracts from the architecture.
- Write `Not applicable - no authoritative or serialized state changes` only when that statement is true.

## Documentation updates

| Document | Required update |
|---|---|
| `docs/codex/MILESTONES.md` | [[PROMPT/IMPLEMENTATION/VERIFICATION STATUS AND ANY REFINED FILE OR DEPENDENCY FACTS]] |
| `docs/codex/ARCHITECTURE.md` | [[UPDATE OR "No change expected"]] |
| `docs/codex/DATA_AND_CONTENT_CONTRACTS.md` | [[UPDATE OR "No change expected"]] |
| `docs/codex/IMPLEMENTATION_RULES.md` | [[UPDATE OR "No change expected"]] |
| `docs/codex/TESTING_AND_VALIDATION.md` | [[COMMAND, FIXTURE, OR MANUAL-FLOW UPDATE]] |
| `docs/codex/OWNER_VERIFICATION_WORKFLOW.md` | [[UPDATE OR "No change expected"]] |
| `docs/codex/DECISIONS.md` | [[APPROVED DECISION UPDATE OR "No new decision expected"]] |
| Design source of truth | [[APPROVED DESIGN CHANGE OR "No change expected"]] |
| `README.md` | [[SETUP OR USAGE UPDATE OR "No change expected"]] |

Do not create a new decision merely to justify an implementation shortcut. If implementation reveals a real design or architecture choice not settled by current sources, stop and request owner approval before recording it as Accepted.

Do not mark a milestone `Merged` or verification `Passed` in `MILESTONES.md` before those facts are true. A Codex implementation task may set the state appropriate to its actual stage, such as `In progress`, `Pull request open`, or `Partial`, when the project workflow calls for that update. Owner-run merge gates remain `Pending owner verification` until an explicit owner result exists. The owner does not need to edit `MILESTONES.md` manually; the next planning package or a scoped documentation update may synchronize the recorded status after confirmation.

Do not create or modify milestone-prompt files during ordinary implementation. If the current prompt is defective, report the defect and await a separately versioned, owner-approved replacement.

## Stop and ask conditions

Stop before implementing or expanding the affected part when any of the following occurs:

1. Applicable authoritative sources conflict and the documented hierarchy does not resolve them.
2. A required prior milestone, file, API, asset, addon, license, or configuration is missing or materially different from the prompt baseline.
3. The task would require a new or updated third-party dependency, network service, storefront feature, native extension, autoload, engine version, renderer, or scripting language.
4. The task would change a protected architecture boundary, canonical ID meaning, save-format contract, time-authority rule, reservation semantics, or exactly-once guarantee beyond the approved milestone.
5. A real content value is required but authoritative sources leave it open and a clearly labelled configurable prototype value or test fixture is not sufficient.
6. The requested result cannot be achieved without broad unrelated refactoring or implementing a later milestone.
7. Tests expose a pre-existing failure that cannot be isolated safely within scope.
8. A platform API is unavailable or behaves differently enough that the documented adapter contract cannot be implemented honestly.
9. A proposed solution would use local device time for closed-session rewards or weaken trusted-time reconciliation.
10. The milestone is too large for one reviewable pull request and needs an approved split.
11. Actual work introduces another primary subsystem owner, crosses another risk dimension, or materially exceeds the approved file/line estimate or cross-layer seams.

Do not stop for ordinary local implementation choices that are already bounded by the architecture, naming rules, tests, and acceptance criteria. Make the smallest clear choice, document it, and report it under assumptions when appropriate.

An expected owner-run Windows, visual, audio, or Steam check being unavailable to Codex is not by itself a stop condition. Implement the testable scope, mark that check pending, and do not claim the merge gate passed.

## Deliverables

The completed task must provide:

- the scoped implementation;
- applicable content or configuration;
- automated tests and fixtures;
- required manual verification instructions;
- the approved owner verification script, generated-log path, and interactive checklist when owner-run checks apply;
- synchronized documentation;
- junior-readable comments for non-obvious code;
- a complete changed-file inventory;
- an actual-versus-estimated review-surface summary, including non-documentation source/test file count, code/test line delta, subsystem owners, and any approved deviation;
- exact verification evidence and disclosed pending checks;
- no temporary failing tests, generated logs, local paths, secrets, or unrelated changes.

[[ADD MILESTONE-SPECIFIC DELIVERABLES.]]

## Final response format

Use exactly these headings.

### Implementation completed

Summarize the resulting behavior and the milestone outcome. Do not list unverified work as complete.

### Files changed

List every added, modified, renamed, or deleted file and its purpose. Note any expected file that was not changed and why when that matters to review. Report actual non-documentation source/test file count and code/test line delta against the approved estimate.

### Verification

Report separately:

- Codex Cloud or Linux automated commands, exit codes, and results;
- focused and negative checks;
- owner-run Windows automated checks as passed, failed, or `Pending owner verification`;
- manual editor, visual, functional, A/B, audio, or Steam checks as performed, failed, pending, or `No blocking issue reported` for non-gating exploratory checks;
- the tested commit or branch for every explicit owner result;
- acceptance criteria that remain unverified.

### Assumptions

List only assumptions not directly established by authoritative context. Distinguish safe implementation choices from requirements.

### Known limitations and risks

State anything incomplete, provisional, environment-dependent, performance-sensitive, or not verified.

### Deferred work

List related work intentionally excluded because it belongs to another milestone or release gate.

### Suggested next task

Name one bounded follow-on task from the approved milestone map when appropriate. Do not begin it.

---

## 4. Prompt author approval checklist

Do not approve or execute an instantiated prompt until all applicable items are true:

- [ ] Every required placeholder has been replaced.
- [ ] Prompt version, date, status, milestone heading, and planned path are correct.
- [ ] The current repository was inspected after the latest dependency milestone merged.
- [ ] Exact design labels, architecture sections, data contracts, test sections, and decision IDs are cited.
- [ ] The work item is an approved implementation slice, not a conceptual epic.
- [ ] The scope assessment identifies one primary owner, risk dimensions, seams, file/line estimates, and the selected owner package.
- [ ] Every mandatory split trigger is absent, resolved by a split, or supported by explicit owner approval.
- [ ] Scope fits one focused task and does not include future-milestone behavior.
- [ ] Non-goals name the most likely scope-creep paths.
- [ ] Repository-state assumptions identify what exists and what does not.
- [ ] Every dependency and owner gate has a required state and evidence source.
- [ ] Required behavior covers success, invalid input, repetition, and recovery where applicable.
- [ ] State transitions identify authoritative ownership and persistence effects.
- [ ] Canonical IDs and provisional values are handled according to the data contracts.
- [ ] UI requirements are limited to the milestone and do not require final assets or polish unless approved.
- [ ] Architecture constraints restate only milestone-critical safeguards.
- [ ] Expected files are plausible but not treated as permission for broad edits.
- [ ] Every acceptance criterion is binary and mapped to actual evidence.
- [ ] Codex Cloud/Linux checks and owner-run Windows checks are separated.
- [ ] The owner verification package is explicitly selected; any required PowerShell script, log path, invocation, cleanup, and interactive checklist are specified.
- [ ] Every owner-run merge gate requires explicit owner evidence; silence is not treated as a pass.
- [ ] The prompt does not authorize Codex to author, rewrite, or broaden its own prompt or create future milestone prompts.
- [ ] Exact commands match the current `TESTING_AND_VALIDATION.md`.
- [ ] Manual steps specify setup, actions, expected results, and actor/environment.
- [ ] Save/load verification is complete or explicitly not applicable for a valid reason.
- [ ] Documentation updates include accurate milestone status handling.
- [ ] Stop-and-ask conditions cover unresolved conflicts and architecture changes without blocking ordinary choices.
- [ ] The final response uses the seven repository-required headings.
- [ ] No secret, token, private path, local executable path, or machine-specific value is included.
- [ ] `docs/codex/MILESTONES.md` will be updated to `Prompt: Drafted` or `Prompt: Approved` only when that state is true.
