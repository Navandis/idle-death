# Codex PR Branch Recovery

**Document role:** Repository-safe operating guide for removing accidental owner or tool edits from an active Codex-managed pull-request branch
**Repository path:** `docs/codex/CODEX_PR_BRANCH_RECOVERY.md`
**Document status:** Approved operational companion
**Last updated:** 2026-07-18

## 1. When to use this guide

Use this guide when an active Codex-managed pull-request branch receives an unintended local edit, generated `.uid` companion, amended file, or commit from outside the normal Codex task flow and the branch must be returned to the intended reviewed history.

Do not use this guide to hide reviewed work, bypass failing verification, rewrite `main`, or remove changes that the owner has intentionally accepted into the pull request.

## 2. Why a revert is not enough

A normal Git revert adds a new commit that inverses file content, but it does not remove the original external edit from branch history. GitHub, reviewers, and future rebases can still see and replay both the accidental commit and the revert. When the requirement is that an external edit never be part of the Codex PR branch history, the branch must be reset to the intended commit and pushed with a verified lease rather than merely reverted.

## 3. GitHub Desktop preparation path

When the accidental change is still local in GitHub Desktop:

1. open the active pull-request branch;
2. inspect the changed files and confirm they are unintended;
3. if GitHub Desktop offers an amended commit path, use **Amend** only to inspect whether the change has been folded into the latest local commit;
4. use **Undo** to return an unwanted local commit to working-tree changes when needed;
5. use **Discard changes** only after confirming the files are generated or otherwise unwanted;
6. confirm the working tree is clean before running owner verification again.

After a local rollback or reset, do **not** press **Pull** in GitHub Desktop. Pulling can reintroduce the remote accidental commit that the recovery is trying to remove. Use the verified force-with-lease flow below when the remote branch itself must be corrected.

## 4. Finding Git when GitHub Desktop is installed

The standalone `git` command may be absent from `PATH` even when GitHub Desktop can manage the repository. On Windows, GitHub Desktop normally ships a bundled Git under its application installation. In PowerShell, search for Git before assuming it is unavailable:

```powershell
Get-Command git -ErrorAction SilentlyContinue
Get-ChildItem "$env:LOCALAPPDATA\GitHubDesktop" -Recurse -Filter git.exe -ErrorAction SilentlyContinue |
    Select-Object -First 5 -ExpandProperty FullName
```

If using a bundled executable, store it in a local variable for the current shell session only. Do not commit that machine-specific path.

```powershell
$Git = "<path-to-git.exe>"
& $Git --version
```

## 5. Safe force-with-lease recovery checklist

Use placeholders from the active PR, not historical examples:

```powershell
$Branch = "<codex-pr-branch>"
$GoodHead = "<intended-local-head-sha>"
$Remote = "origin"
```

Before rewriting the remote branch, verify all of the following:

1. **Correct branch**

   ```powershell
   & $Git branch --show-current
   ```

   The output must exactly match `$Branch`.

2. **Clean tree**

   ```powershell
   & $Git status --short
   ```

   The output must be empty. Stop if any generated log, `.godot` file, `.uid` file, trace directory, or edited source file appears unexpectedly.

3. **Local head is the intended head**

   ```powershell
   & $Git rev-parse HEAD
   ```

   The output must match `$GoodHead`.

4. **Remote head is known immediately before the push**

   ```powershell
   & $Git fetch $Remote $Branch
   $RemoteHead = (& $Git rev-parse "refs/remotes/$Remote/$Branch").Trim()
   $RemoteHead
   ```

5. **Parent relationship is understood**

   ```powershell
   & $Git merge-base --is-ancestor $GoodHead $RemoteHead
   $LASTEXITCODE
   ```

   Exit code `0` means the intended local head is an ancestor of the current remote head, which is the usual accidental-extra-commit case. If this is not true, stop and request branch-specific guidance instead of guessing.

6. **Create a local safety branch before rewriting**

   ```powershell
   & $Git branch "safety/$Branch-before-recovery-$((Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmssZ'))" $RemoteHead
   ```

7. **Push with an explicit lease**

   ```powershell
   & $Git push --force-with-lease=$Branch`:$RemoteHead $Remote HEAD`:$Branch
   ```

   Do not use plain `--force`. The explicit lease prevents overwriting someone else's newer remote update.

8. **Verify the remote head after the push**

   ```powershell
   & $Git fetch $Remote $Branch
   & $Git rev-parse "refs/remotes/$Remote/$Branch"
   ```

   The remote-tracking output must match `$GoodHead`.

## 6. After recovery

After the remote branch is corrected:

- reopen or refresh the pull request and confirm the head SHA matches the intended head;
- rerun the milestone owner verification package against that exact SHA;
- keep generated owner logs under `tools/test/owner/logs/` and do not commit them;
- report the recovery and rerun result in the planning conversation.

## 7. Prevention guidance

- Do not manually edit files on an active Codex branch unless the current task explicitly asks for owner-side editing.
- Do not commit generated owner logs, trace roots, `.godot/`, exported builds, or local editor state.
- Treat unexpected `.uid` companions as generated artifacts to inspect and usually discard unless the Codex task intentionally added the corresponding Godot script or scene.
- If Godot creates `.uid` files while importing or running owner checks, verify whether the companion source file is part of the pull request before committing anything.
- Prefer a fresh working tree for owner verification; if GitHub Desktop shows changes after a run, inspect and discard generated artifacts before pulling or rerunning.
