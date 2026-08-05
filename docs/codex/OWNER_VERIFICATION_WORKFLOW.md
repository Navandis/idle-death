# Death Idle Owner Verification Workflow

**Document role:** Canonical packaging, owner-interface, and evidence rules for checks that must run on the project owner's Windows Godot machine or require owner observation
**Repository path:** `docs/codex/OWNER_VERIFICATION_WORKFLOW.md`
**Document status:** Approved workflow
**Workflow revision:** 3
**Last updated:** 2026-08-03
**Companion documents:** [Testing and validation](TESTING_AND_VALIDATION.md), [Slice-packet template](PROMPT_TEMPLATE.md), [Milestones](MILESTONES.md), [Decisions](DECISIONS.md), and [Codex PR branch recovery](CODEX_PR_BRANCH_RECOVERY.md)

## 1. Purpose and default owner interface

Codex/Linux can run headless verification, but it cannot operate the owner's separate Windows Godot environment, inspect interactive presentation, or exercise a live Steam client. This file defines the smallest truthful owner package for those checks while preserving exact-head evidence, cleanup, and owner-only integration authority.

The planning packet decides which owner checks exist. The implementation task adds the approved script/checklist. The responsible architect or triage actor analyzes the returned evidence. The owner is not the routine message bus for repository state already available through Git, GitHub, CI, tracked artifacts, or generated logs.

Routine owner instructions use this form:

```text
Purpose
- One sentence explaining why the owner action is needed.

Run
- One exact command or precise UI action. Insert the PR head and known arguments when practical.

Return
- The complete generated log, exact result block, or requested observation.

Stop only if
- A prompt, mismatch, or state requiring an owner decision appears.
```

Keep internal hashes, byte counts, guard implementation, expected metadata, and repetitive success output in scripts, CI, tracked artifacts, or architect analysis unless the owner must inspect them to decide safely.

Any commit after owner verification invalidates the prior exact-head evidence. A new current-head run or explicit evidence reconciliation is required before merge.

## 2. Smallest applicable owner package

When a slice has owner-run merge gates, its pull request provides the smallest applicable package.

### 2.1 Automated or scriptable checks

Prefer one milestone-specific Windows PowerShell entry point:

```text
tools/test/owner/run_mNN_owner_verification.ps1
```

The script normally calls `tools/test/run_gut.ps1` and adds only the Windows, recovery, persistence, artifact, or platform checks required by the approved packet. The owner should not assemble several commands manually when one safe deterministic script can do so.

### 2.2 Interactive checks

When visual inspection, editor interaction, audio judgment, A/B comparison, functional observation, or a live Steam client is required, also provide:

```text
docs/codex/owner-checklists/MNN-owner-verification.md
```

Do not create a checklist when there is no meaningful interactive observation. In that case the script and generated log are sufficient.

### 2.3 Canonical wrapper only

Use the canonical `tools/test/run_gut.ps1` without a milestone-specific wrapper when it fully covers the owner automation and no additional evidence formatting, cleanup, failure injection, trace, artifact audit, or interactive flow is required.

### 2.4 Direct command/checklist file

A direct `.md` or `.txt` command sheet is acceptable only when the checks are genuinely short, automation would add more risk than value, or an interactive/platform tool cannot be driven safely. The approved packet states the reason.

## 3. PowerShell script contract

A milestone-specific owner script is compatible with Windows PowerShell 5.1 unless the packet explicitly approves another requirement. It must:

1. derive the repository root from the script's location;
2. accept `-GodotBin` or use `GODOT_BIN` and the canonical wrapper contract;
3. accept an optional `-CommitSha` copied from the current PR head;
4. attempt to detect the local Git commit only when Git is available, without making Git a prerequisite;
5. reject a supplied commit SHA that conflicts with a successfully detected local SHA;
6. create its log directory when needed;
7. capture PowerShell, native command, Godot, and GUT output in one UTF-8 log;
8. record every command or named step, start/end time, exit code, and pass/fail result;
9. fail the run when a required automated check fails;
10. clean every temporary test, save, UID companion, export, work root, or fixture it created;
11. verify cleanup before reporting success;
12. rerun the applicable clean regression suite after intentional failure, corruption, or recovery checks;
13. return exit code `0` only when every automated owner check passed and cleanup passed;
14. return nonzero when any required automated check failed, exact-head validation failed, or cleanup was incomplete;
15. print the final log path prominently;
16. avoid secrets, tokens, Steam credentials, private keys, unrelated personal information, and automatic uploads.

A script may print interactive checklist reminders, but it must not mark a visual, audio, editor, functional, A/B, or Steam observation as passed. Those checks require explicit owner evidence.

## 4. Log location, naming, and evidence shape

Generated logs belong under the ignored directory:

```text
tools/test/owner/logs/
```

Use a stable name such as:

```text
M01-owner-verification-20260713-221530Z-75a1752a.log
```

When no commit is available, use `unknown-ref` rather than inventing a SHA:

```text
M01-owner-verification-20260713-221530Z-unknown-ref.log
```

The log begins with:

```text
Milestone or slice:
UTC start:
Repository root:
Requested commit or PR head:
Detected Git commit, when available:
Windows version:
PowerShell version:
Godot executable:
Godot version:
```

It ends with:

```text
Automated result: PASS|FAIL
Failed step count:
Pending interactive checks:
Cleanup result: PASS|FAIL
Log path:
```

The generated log is evidence to upload or quote. It is never committed. The owner returns the log/result; they do not need to manually transcribe Git status, command-by-command metadata, or CI state that the responsible actor can inspect directly.

## 5. Normal owner experience

The responsible actor should prefill the exact current PR head and command whenever practical. A representative instruction is:

```text
Purpose
- Verify the exact PR head on the Windows Godot machine.

Run
- powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test\owner\run_m01_owner_verification.ps1 -CommitSha "<exact-current-pr-head>"

Return
- Upload the generated log and paste the interactive result block if a checklist exists.

Stop only if
- The script reports a SHA mismatch, requests a decision, cannot find the approved Godot executable, or leaves cleanup incomplete.
```

When `GODOT_BIN` is not configured, the exact command may include the owner's local console executable path. That path belongs only in the invocation and generated log, never in committed files.

The owner normally:

1. checks out or pulls the current PR revision on the Windows machine;
2. runs the supplied exact command;
3. performs the companion checklist, if any;
4. returns the generated log and explicit interactive result;
5. does not privately edit the repository script to bypass a failure;
6. returns failures for visible triage and correction.

A check not performed remains `Pending owner verification`. Owner silence or elapsed time is never PASS. A non-gating exploratory check with no reported blocker may be recorded only as `No blocking issue reported`.

## 6. Interactive checklist contract

A companion checklist identifies:

- exact prerequisites and current PR head field;
- required starting state;
- numbered actions;
- visible or audible expected result for each action;
- whether each item is a merge gate;
- cleanup or reset steps;
- one compact result block.

Use:

```text
Owner verification: PASS|FAIL — PR head <sha> — <automated and manual checks performed> — YYYY-MM-DD.
Log: <generated filename>
Observed warnings or failures: <none or concise description>
```

The owner must state PASS or FAIL for every interactive merge gate. The architect or triage actor then verifies that the reported head still matches the current PR and that no relevant commit invalidated the evidence.

## 7. Slice-packet authoring requirements

Every G2-forward versioned slice packet explicitly decides whether owner verification needs:

- no owner package;
- the canonical Windows GUT wrapper only;
- a milestone-specific PowerShell script;
- a script plus interactive checklist; or
- a direct command/checklist file with a stated reason.

The packet names the expected paths, generated log location, exact owner invocation pattern, executor, merge-gate behavior, cleanup requirements, and evidence returned. The implementation task creates only that approved package.

The planning workflow—not the implementer—defines verification scope. Low-level command syntax may be corrected after repository inspection, but an implementer or fixer may not remove an owner gate, substitute silence for evidence, or mark an unperformed observation passed.

For each owner action, the responsible actor should use `Purpose / Run / Return / Stop only if`, insert the exact current head when practical, and avoid asking the owner to relay data available from GitHub, CI, or the generated log.

## 8. Scope and security limits

Owner-verification scripts are development tools. They must not:

- ship in a release export unless explicitly required and reviewed;
- expose debug-time control in release builds;
- initialize Steam except in a packet that explicitly requires live Steam checks;
- change the local device clock;
- read or write Steam credentials;
- upload logs automatically;
- transmit repository or machine data over the network;
- delete user saves outside a clearly isolated test location;
- modify production content to manufacture a pass;
- bypass a SHA mismatch, failing check, or cleanup failure.

A log proves what commands and observations were recorded at one head. It is not a security boundary and does not prove a client machine is uncompromised.

## 9. Exceptional branch recovery

`CODEX_PR_BRANCH_RECOVERY.md` governs the exceptional case where an active Codex-managed PR branch contains an unintended owner/tool edit or commit and the remote history must be corrected.

That guide is inspect-only authority for ordinary packets unless recovery is actually needed. Its force-with-lease procedure requires deliberate owner authorization, correct-branch and clean-tree proof, an immediately verified remote head, a local safety branch, an explicit lease, and post-push verification. It is not a standard publication step and does not weaken the ordinary no-force, owner-only history boundary.

After an authorized recovery, all prior final review and owner evidence is stale. Refresh the PR head and rerun the approved exact-head package. Generated logs remain local evidence and must not enter the branch.

## 10. M00 completion note

M00 predates this standardized owner package. Its explicit Windows evidence covered full and focused GUT, outside-root execution, editor smoke, passive Steam configuration, intentional failing-test exit propagation, temporary-file cleanup, and clean recovery. No retroactive M00 owner script is required.
