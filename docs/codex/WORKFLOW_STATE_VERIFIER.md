# Workflow-state verifier

## Purpose and boundary

`tools/codex/verify_workflow_state.ps1` captures a read-only, schema-versioned snapshot of the current Death Idle checkout and the GitHub evidence associated with its current HEAD. It never stages, commits, publishes, creates or edits pull requests, changes GitHub settings, writes a spool, or reads credential values. It does not replace the owner's merge authority.

The verifier expects the `origin` remote to identify `Navandis/idle-death`. Normal authenticated use is through the constrained `navandis-automation` GitHub CLI identity. The identity is reported only as its login; tokens, authorization headers, `hosts.yml`, and environment contents are never emitted.

## Invocation, output, and exits

The supported invocation has no arguments:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File ".\tools\codex\verify_workflow_state.ps1"
```

The verifier resolves the repository from its own script path and targets that root explicitly for every local Git query, so invocation is independent of the caller's current directory and does not change it.

It writes exactly one UTF-8-without-BOM compressed JSON object to stdout.

- Exit `0`: `result` is `pass`; all local and GitHub reads completed.
- Exit `2`: `result` is `partial`; local state is valid but a non-mutating GitHub read failed.
- Exit `1`: `result` is `fail`; a local inspection, identity/invariant, schema, or output-validation failure occurred.

Missing feature refs, zero matching open pull requests, no check runs, no workflow runs, and skipped review-thread reads when no PR exists are normal state, not failures. A dirty workspace is also state, not a verifier failure.

To capture output without introducing a BOM:

```powershell
$text = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\codex\verify_workflow_state.ps1"
$utf8_no_bom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText("workflow-state.json", ($text | Out-String).Trim(), $utf8_no_bom)
```

## Contract

The strict draft-2020-12 schema is `tools/codex/workflow-state.schema.json`. `workflow_state_contract.ps1` supplies the PowerShell 5.1-compatible cross-field validation used by both the production verifier and offline tests. Every object rejects unknown fields and every nullable field remains present as `null` when unavailable.

The root fields are `schema_version`, `tool`, `generated_at_utc`, `result`, `repository`, `tools`, `workspace`, `github`, and `queries`. Repository state records the resolved root, expected identity, branch and SHA fields. Workspace state records porcelain status, staged paths, and request/lock presence. GitHub state records the login, matching PR metadata, current-HEAD checks/workflows, and review threads. `queries` records each attempt using a boolean, native exit code, and a bounded sanitized error string.

`pass` has no failed query. `partial` is reserved for GitHub-query failures after valid local capture. `fail` identifies a local, invariant, schema, or generated-output failure. A remote feature SHA is `null` on `main`; a 404 for a feature branch is also represented as `null`.

## Offline validation

The four synthetic fixtures under `tools/codex/tests/fixtures/` cover main, feature PR, partial-GitHub, and forbidden-unknown-field states. Run their dependency-free validation with:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File ".\tools\codex\tests\test_workflow_state_contract.ps1"
```

The test parses the schema, accepts the three valid fixtures, rejects the unknown-field fixture, and proves malformed SHA, PR/count, review-count, result/query, array-shape, and duplicate-thread rejections. It makes no network calls.

## Manual fallback and future composition

If GitHub is unavailable, run the verifier to retain the local snapshot; it exits `2` with sanitized failed GitHub query records. The owner can then inspect the GitHub pull request, Actions, checks, and review threads manually before deciding what to do. Do not treat a partial result as permission to publish or merge.

Future owner-controlled composition may place raw evidence, plans, approvals, and journals in a private repository-external spool. Transaction execution, approval digests, PR administration, bridge integrity/self-test data, staging, commits, publication, close/merge/auto-merge, branch deletion, force operations, rulesets, credentials, billing, and deployment behavior are explicitly deferred from this verifier.
