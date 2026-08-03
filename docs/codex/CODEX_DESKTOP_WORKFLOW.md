# Codex desktop implementation and pull-request workflow

**Document role:** Repository operating procedure for transactional Codex implementation and fixer tasks
**Status:** Approved operational workflow for G2-forward implementation slices
**Revision:** 2
**Last updated:** 2026-08-03
**Companion:** root `AGENTS.md`, the owner-approved versioned slice packet, `docs/codex/CODEX_PR_BRANCH_RECOVERY.md`, and `tools/codex/publish_milestone_pr.ps1`

## Purpose

Codex desktop can edit a local checkout, run repository checks, commit, push, and invoke GitHub CLI. This procedure preserves one owner-controlled feature branch and pull request while keeping planning, independent scope assessment, implementation, PR-lifetime triage, corrections, exact-head verification, and integration in appropriately bounded contexts.

The default actor flow is:

```text
long-lived planning architect
-> fresh independent scope assessor
-> owner approval
-> transactional implementation Codex task
-> one feature branch and one pull request
-> fresh PR-lifetime triage architect
-> fresh bounded fixer task for material corrections
-> exact-head review and owner verification
-> owner integration
```

The planning architect does not independently assess its own packet or perform routine PR-lifetime triage. The implementation task executes the approved packet and does not rewrite its own authority. The triage architect classifies findings and convergence. A fixer receives a bounded correction packet rather than the entire planning history.

## One slice, one branch, one pull request

For each directly executable slice:

1. start from a clean, current local checkout;
2. read root `AGENTS.md`, the exact owner-approved versioned slice packet, and only its context-manifest entries;
3. fast-forward local `main` to `origin/main` using fast-forward-only behavior;
4. create the exact feature branch named by the packet before modifying files;
5. implement and verify only the packet scope;
6. commit the intended change;
7. push the feature branch without force;
8. create one pull request targeting `main` or update the one existing PR for that branch;
9. report the PR number, URL, branch, exact head SHA, changed-path set, and validation;
10. stop without merge.

Every implementation and correction for the slice remains on that feature branch and pull request unless the owner explicitly authorizes replacement. This continuity rule does **not** require one long-lived implementation task.

A material correction round normally uses a fresh transactional fixer context supplied with the exact findings, current PR head, bounded correction authority, affected code/contracts/tests, and required regressions. A trivial mechanical correction may remain in the original implementation task only when the exception is explicit, directly provable, and does not broaden context, scope, ownership, or authority.

## Packet-driven operating context

The owner-approved slice packet supplies:

```text
verified base ref
feature branch
PR target and title
primary owner and principal transition
sole context manifest
included scope and exclusions
acceptance/test oracle
scope and convergence guards
delivery and owner-verification contract
hard stop
```

Do not replace the packet manifest with broad routine reading. Failed branches, superseded prompt bodies, architect transcripts, full design sources, the full decision log, and the full milestone map are exceptional context only when an exact packet entry or concrete unresolved conflict requires them.

If live repository state materially differs from the packet baseline, stop before dependent edits. Record the exact mismatch and return to the planning architect rather than resetting legitimate newer work or silently adapting the packet.

## Prohibited actions

Codex implementation and fixer tasks must not:

- edit, commit, or push directly on `main`;
- merge or auto-merge a pull request;
- close a pull request;
- approve their own pull request;
- delete a local or remote milestone branch;
- force-push or rewrite published history during ordinary publication;
- change the PR base away from `main` without owner instruction;
- use a branch or PR from an abandoned milestone as the implementation base;
- create a replacement PR merely because a correction is required;
- broaden or materially rewrite the active packet;
- treat “finish,” “publish,” “submit,” or “complete” as merge authority.

Merge, close, branch deletion, replacement, force, and history rewrite are owner-only actions. `CODEX_PR_BRANCH_RECOVERY.md` is an exceptional deliberately authorized recovery procedure, not ordinary publication guidance.

## Environment capability checks

The local implementation environment should provide:

```text
git
gh
packet-required language/runtime tools
Godot 4.7 through GODOT_BIN or PATH when executable Godot work is in scope
PowerShell 5.1 or newer on Windows when an owner package is in scope
```

Before implementation or publication, verify:

```powershell
git --version
gh --version
gh auth status
git remote -v
git branch --show-current
git status --short
git rev-parse HEAD
git rev-parse origin/main
```

Environment setup provides tools and credentials. It does not replace repository policy or packet authority.

## Safe publication helper

After all intended changes are committed, use the existing helper when the packet names this publication path:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
    -File .\tools\codex\publish_milestone_pr.ps1 `
    -RepoRoot '<repository root>' `
    -ExpectedBranch '<packet feature branch>' `
    -BaseBranch 'main' `
    -Title '<packet-approved PR title>' `
    -BodyFile '<temporary PR description file>'
```

The helper:

- refuses `main`;
- checks Git and GitHub CLI authentication;
- refuses tracked or staged uncommitted changes;
- verifies that the feature branch is based on current `origin/main` and has commits ahead of it;
- pushes only the current feature branch without force;
- creates a PR when none exists for the branch;
- updates the title/body of the existing open PR when one exists;
- prints the PR number, URL, branch, base, and exact head SHA;
- contains no merge, close, auto-merge, deletion, replacement, or force-push operation.

Create the PR body outside the repository or remove it before publication so it cannot enter the packet diff accidentally.

## Review, triage, correction, and convergence

The default PR lifecycle is:

```text
implementation/readiness pass
-> push or update the one PR
-> CI
-> bounded targeted review
-> fresh triage disposition
-> bounded correction packet when needed
-> fresh fixer task for material corrections on the same branch/PR
-> final unrestricted current-head review
-> exact-head owner verification when required
-> owner merge
```

The triage architect owns true-positive, false-positive, duplicate, correction, scope, and convergence dispositions. The implementer or fixer does not silently dismiss findings or enlarge its own correction authority.

After two substantial correction rounds, pause for an explicit convergence assessment. Continue when remaining findings are local, understood, testable, and within the existing design. Stop, split, or redesign only when affirmative evidence shows an architecture, ownership, scope, oracle, repeated-root-cause, or evidence-integrity problem. Round count alone is never dispositive.

Any code or relevant contract commit after a final review or owner verification invalidates that exact-head evidence. CI may rerun automatically; review and owner evidence require deliberate reconciliation against the new head.

## Recommended GitHub `main` ruleset

Repository instructions are advisory. GitHub protection should enforce the boundary:

- require pull requests before changes enter `main`;
- require at least one approval from someone other than the latest pusher;
- dismiss stale approvals after new commits;
- require review conversations to be resolved;
- require applicable status checks;
- block force pushes and branch deletion;
- give Codex, GitHub CLI automation, and bots no bypass role.

The owner configures the ruleset. Slice implementation tasks do not change it unless a separately approved repository-governance packet says otherwise.

## Failure and recovery

- **Edits began on `main`:** stop before committing; create the packet branch from the current working tree and verify no `main` commit exists.
- **Commit pushed to `main`:** stop. Do not self-revert or rewrite. Report the exact SHA for owner direction.
- **PR accidentally merged:** stop. Do not create a revert or replacement without owner authorization.
- **More than one open PR for the branch:** stop and report all URLs.
- **Branch is stale or not based on current `origin/main`:** stop for a deliberate update strategy; do not force-push automatically.
- **Authentication fails:** ask the owner to restore the normal authenticated environment; do not invent credentials or alter remotes.
- **Packet or contract defect:** preserve work, stop the affected behavior, and return to the planning architect for a new owner-approved version.
- **Unexpected owner/tool edit on an active PR branch:** use `CODEX_PR_BRANCH_RECOVERY.md` only after explicit owner authorization. Its verified force-with-lease path is exceptional and must not be folded into the publication helper.

## Handoff

At the packet hard stop, report:

- resulting behavior or documentation outcome;
- every changed path and purpose;
- commands/checks actually run and results;
- PR number, URL, branch, and exact head;
- assumptions, pending owner evidence, limitations, risks, and deferred work;
- explicit confirmation that no merge or other owner-only action occurred.
