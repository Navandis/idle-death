# Codex desktop implementation and pull-request workflow

**Document role:** Repository operating procedure for Codex desktop milestone tasks  
**Status:** Proposed operational workflow for M04E2T2 onward  
**Date:** 2026-07-22  
**Companion:** root `AGENTS.md`, milestone prompt, and `tools/codex/publish_milestone_pr.ps1`

## Purpose

The Codex desktop app can edit the local repository, run Godot/GUT, commit, push, and invoke GitHub CLI. Unlike the earlier web workflow, it does not provide a separate owner-facing “Create PR” button. This procedure makes branch publication explicit while preserving owner-only merge authority.

The workflow separates four roles:

| Activity | Owner |
|---|---|
| Implementation, corrections, local tests, commit, push, PR creation/update | Codex desktop task |
| Formal targeted and unrestricted code review | GitHub PR through `@codex review` |
| Exact-head Windows merge gate | Project owner/local Windows checkout |
| Merge, close, branch deletion, replacement PR, history rewrite | Project owner only |

## One milestone, one task, one branch, one PR

For each new implementation slice:

1. start a new Codex desktop task from an updated local checkout;
2. read the approved repository prompt `.md` file;
3. fast-forward local `main` to `origin/main`;
4. create the exact feature branch named by the prompt before modifying files;
5. implement and verify on that branch;
6. commit the intended change;
7. push the feature branch;
8. create one PR targeting `main`;
9. stop and report the PR number, URL, branch, and exact head SHA.

Every refinement, bug fix, review correction, and requested change for that milestone remains in the same desktop task and updates the same feature branch/PR. Do not create a replacement PR unless the owner explicitly closes the original and orders replacement.

## Prohibited actions

Codex desktop must not:

- edit, commit, or push directly on `main`;
- merge or auto-merge a PR;
- close a PR;
- approve its own PR;
- delete the feature branch;
- force-push or rewrite published history;
- change the PR base away from `main` without owner instruction;
- use a branch or PR from an abandoned milestone as the implementation base;
- run a merge command as part of “publish” or “finish.”

When instructions are ambiguous, stop after pushing/creating the PR. “Finish,” “publish,” “submit,” or “complete the milestone” never implies merge.

## Environment capability checks

The local Codex environment should make these commands available:

```text
git
gh
Godot 4.7 executable through GODOT_BIN or PATH
PowerShell 5.1 or newer on Windows
```

Before implementation or publication, verify:

```powershell
git --version
gh --version
gh auth status
git remote -v
git status --short
```

Environment setup provides tools and credentials. It does not replace repository policy in `AGENTS.md` or the task-specific delivery contract.

## Safe publication helper

After all intended changes are committed, use:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
    -File .\tools\codex\publish_milestone_pr.ps1 `
    -RepoRoot '<repository root>' `
    -ExpectedBranch 'codex/implement-<milestone>' `
    -BaseBranch 'main' `
    -Title '<approved PR title>' `
    -BodyFile '<temporary PR description file>'
```

The helper:

- refuses `main`;
- checks Git and GitHub CLI authentication;
- refuses tracked or staged uncommitted changes;
- verifies the feature branch is based on current `origin/main` and has commits ahead of it;
- pushes only the current feature branch;
- creates a PR when none exists for the branch;
- updates the title/body of the existing open PR when one exists;
- prints the PR number, URL, branch, base, and exact head SHA;
- contains no merge, close, auto-merge, deletion, or force-push operation.

The PR body file should be created outside the repository or removed before publication so it does not become an unrelated tracked change.

## Task-specific delivery contract

Every approved milestone prompt repeats a short contract with:

```text
Base branch
Feature branch
PR target
Approved PR title
Required handoff evidence
Hard stop after PR creation/update
```

Repository policy is durable. The prompt supplies the exact branch/title for the current task.

## Review and correction loop

```text
Codex desktop implementation and readiness pass
-> push/update PR
-> targeted GitHub @codex review
-> corrections in the same Codex desktop task and branch
-> repeat the same targeted audit only within the stop rule
-> final unrestricted GitHub review
-> exact-head owner verification
-> owner merge
```

Do not run final owner verification before the final review is clean. Any code or documentation commit after the reviewed head invalidates exact-head evidence.

## Recommended GitHub `main` ruleset

Repository instructions are advisory to an agent. GitHub protection should enforce the boundary:

- require pull requests before changes enter `main`;
- require at least one approval;
- require approval from someone other than the latest pusher;
- dismiss stale approvals after new commits;
- require all review conversations resolved;
- block force pushes and branch deletion;
- do not give Codex, GitHub CLI automation, or another bot a bypass role.

The ruleset is configured by the owner in GitHub and is not changed by milestone implementation tasks.

## Failure recovery

- If edits began on `main`, stop before committing; create the feature branch at the current working tree and verify no main commit was created.
- If a commit was accidentally pushed to `main`, stop. Do not self-revert, merge, or rewrite. Report the exact SHA and wait for owner instructions.
- If a PR was accidentally merged, stop. Do not create a revert or replacement PR without owner instructions.
- If the helper finds more than one open PR for the branch, stop and report the URLs.
- If the branch is behind or not based on current `origin/main`, stop for a deliberate rebase/merge decision; do not force-push automatically.
- If `gh auth status` fails, ask the owner to authenticate; do not substitute a credential or remote URL.
