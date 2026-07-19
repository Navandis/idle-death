# Death Idle Owner Verification Workflow

**Document role:** Canonical packaging and evidence rules for checks that must run on the project owner's Windows Godot machine
**Repository path:** `docs/codex/OWNER_VERIFICATION_WORKFLOW.md`
**Document status:** Approved workflow
**Workflow revision:** 2
**Last updated:** 2026-07-18
**Companion documents:** [Testing and validation](TESTING_AND_VALIDATION.md), [Prompt template](PROMPT_TEMPLATE.md), [Milestones](MILESTONES.md), [Decisions](DECISIONS.md), and [Codex PR branch recovery](CODEX_PR_BRANCH_RECOVERY.md)

## 1. Purpose

Codex Cloud can run the Linux/headless portion of Death Idle's verification, but it cannot execute commands, inspect the editor, or operate Steam on the separate Windows Godot machine. This file defines how each milestone packages owner-run checks so that the owner normally runs one PowerShell entry point, receives a durable log, performs any remaining interactive checklist, and returns explicit evidence for merge gates.

This workflow does not replace the canonical GUT wrappers. A milestone-specific owner script normally calls `tools/test/run_gut.ps1` and then adds only the Windows, recovery, persistence, visual-support, or platform checks required by that milestone.

## 2. Default deliverables for owner-run checks

When a milestone has one or more owner-run merge gates, its implementation pull request must provide the smallest applicable verification package.

### 2.1 Automated or scriptable checks

Prefer a milestone-specific PowerShell script:

```text
tools/test/owner/run_mNN_owner_verification.ps1
```

Examples:

```text
tools/test/owner/run_m01_owner_verification.ps1
tools/test/owner/run_m06_owner_verification.ps1
```

The owner should not need to assemble several commands manually when the checks can be executed safely and deterministically by one script.

### 2.2 Interactive checks

When visual inspection, editor interaction, audio judgment, A/B comparison, or a live Steam client is required, also provide a concise checklist:

```text
docs/codex/owner-checklists/MNN-owner-verification.md
```

Do not create a checklist file for a milestone that has no meaningful interactive verification. In that case, the PowerShell script and its generated log are sufficient.

### 2.3 Direct command file

A standalone `.md` or `.txt` command sheet is acceptable instead of a script only when:

- the checks are genuinely one-off and very short;
- automation would create more risk or complexity than it removes;
- an interactive tool cannot be driven safely from PowerShell; or
- the applicable platform API must be exercised manually.

The prompt must explain why a script is not appropriate.

## 3. PowerShell script contract

A milestone-specific owner script must be compatible with Windows PowerShell 5.1 unless the milestone explicitly approves a newer requirement.

It must:

1. derive the repository root from the script's own location;
2. accept `-GodotBin` or use `GODOT_BIN` and the existing wrapper contract;
3. accept an optional `-CommitSha` value copied from the pull request;
4. attempt to read the current Git commit only when Git CLI is available, without making Git CLI a prerequisite;
5. reject a supplied commit SHA that conflicts with a successfully detected local SHA;
6. create its log directory when needed;
7. capture PowerShell, native command, Godot, and GUT output in one UTF-8 log;
8. record every command or named step, start and end time, exit code, and pass/fail result;
9. stop or mark the run failed when a required automated check fails;
10. clean every temporary test, save, UID companion, export, or fixture it created;
11. verify cleanup before reporting success;
12. rerun the applicable clean regression suite after any intentional-failure or corruption test;
13. return process exit code `0` only when all automated owner checks passed;
14. return a nonzero process exit code when any required automated owner check failed or cleanup was incomplete;
15. print the final log path prominently;
16. avoid storing secrets, tokens, Steam credentials, private keys, or unrelated personal information.

The script may print interactive checklist items, but it must not falsely mark a visual, audio, editor, or Steam observation as passed. Those checks require an explicit owner result.

## 4. Log location and naming

Generated logs belong under:

```text
tools/test/owner/logs/
```

This directory is ignored by Git. The script should use a stable name such as:

```text
M01-owner-verification-20260713-221530Z-75a1752a.log
```

When no commit SHA is available, use `unknown-ref` rather than failing an otherwise valid test run:

```text
M01-owner-verification-20260713-221530Z-unknown-ref.log
```

The log must begin with an evidence header containing:

```text
Milestone:
UTC start:
Repository root:
Requested commit or PR head:
Detected Git commit, when available:
Windows version:
PowerShell version:
Godot executable:
Godot version:
```

The log must end with a summary containing:

```text
Automated result: PASS|FAIL
Failed step count:
Pending interactive checks:
Cleanup result: PASS|FAIL
Log path:
```

The owner may upload this generated log in the planning conversation as execution evidence. Generated logs are never committed to the repository.

## 5. Required owner experience

The normal owner workflow is:

1. pull or check out the pull-request revision on the Windows Godot machine;
2. copy the current PR head SHA from GitHub;
3. run the milestone-specific script with the SHA and, when needed, the local Godot console executable;
4. perform the companion interactive checklist, if one exists;
5. upload the generated log and report the interactive result in the planning conversation;
6. do not privately edit the repository script to bypass a failure;
7. return failures for triage so the repository branch, prompt, or implementation is corrected visibly.

Representative invocation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
    -File .\tools\test\owner\run_m01_owner_verification.ps1 `
    -CommitSha "<PR_HEAD_SHA>"
```

When `GODOT_BIN` is not already configured:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
    -File .\tools\test\owner\run_m01_owner_verification.ps1 `
    -GodotBin "C:\Path\To\Godot_v4.7-stable_win64_console.exe" `
    -CommitSha "<PR_HEAD_SHA>"
```

Repository documentation must use placeholder paths. A real local absolute path belongs only in the owner's command invocation and generated log, never in committed files.

## 6. Interactive checklist contract

A companion checklist must identify:

- exact prerequisites;
- the tested PR head or commit field;
- required starting state;
- numbered actions;
- visible or audible expected result for each action;
- whether each item is a merge gate;
- cleanup or reset steps;
- a compact result block the owner can paste into the planning conversation.

Use this result block:

```text
Owner verification: PASS|FAIL — PR head <sha> — <automated and manual checks performed> — YYYY-MM-DD.
Log: <generated filename>
Observed warnings or failures: <none or concise description>
```

A check that was not performed remains `Pending owner verification`. A non-gating exploratory check with no reported blocker may be described only as `No blocking issue reported`, not `Passed`.

## 7. Prompt-authoring requirements

Every future milestone prompt must explicitly decide whether owner verification needs:

- no additional package beyond the canonical Windows GUT wrapper;
- a milestone-specific PowerShell script;
- a PowerShell script plus interactive checklist; or
- a direct command/checklist file with a stated reason automation is inappropriate.

The prompt must name the expected path, log path, owner command, merge-gate behavior, and cleanup requirements. Codex implements the approved package in the same pull request as the behavior it verifies.

The planning workflow, not Codex's implementation task, decides the verification scope. Codex may adjust low-level command syntax after repository inspection, but it may not remove an owner merge gate or replace explicit evidence with an assumption.

## 8. Scope and security limits

Owner-verification scripts are development tools. They must not:

- ship in a release export unless explicitly required and reviewed;
- expose debug time control in release builds;
- initialize Steam except in milestones that explicitly require live Steam checks;
- change the local device clock;
- read or write Steam credentials;
- upload logs automatically;
- transmit repository or machine data over the network;
- delete user saves outside a clearly isolated test location;
- modify production content to manufacture a passing result.

A log is evidence of commands and observed results, not a security boundary or proof against a compromised client machine.

## 9. Codex-managed PR branch recovery

When an active Codex-managed pull-request branch receives an unintended owner-side edit, generated `.uid` companion, or accidental commit, use [Codex PR branch recovery](CODEX_PR_BRANCH_RECOVERY.md) before rerunning owner verification. The recovery guide explains why a revert preserves the unwanted edit in branch history, how to prepare a rollback in GitHub Desktop, why the owner must not pull after local rollback, and how to verify a clean-tree, correct-branch, safety-branch, explicit `--force-with-lease` recovery when the remote PR head must be corrected.

Owner-verification logs remain generated local evidence during recovery. Do not commit recovery logs, temporary trace roots, or generated editor artifacts while preparing the corrected PR head.

## 10. M00 completion note

M00 predates this standardized package. Its Windows evidence was supplied through explicit PowerShell execution logs covering the full suite, focused run, outside-root invocation, editor smoke, passive Steam configuration, intentional failing-test exit code, cleanup, and successful recovery. No retroactive M00 owner script is required.
