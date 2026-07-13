# M00 correction task: Windows console executable handling and remaining validation

**Task type:** Bounded correction to the existing M00 pull request  
**Prompt version:** v0.1  
**Prompt date:** 2026-07-13  
**Target pull request:** `Navandis/idle-death` PR #1  
**Target branch:** `codex/implement-milestone-00`  
**Current observed PR head at prompt drafting:** `d2d24eaf87c46de35a51425a0d0e060ee828d9b7`

> Update the existing M00 implementation. Do not broaden scope, start M01, modify the approved M00 prompt, or introduce another dependency.

## Evidence that triggered this correction

Owner-run Windows verification exposed this behavior:

1. Supplying the ordinary Windows GUI executable, `Godot_v4.7-stable_win64.exe`, produced an empty version string.
2. `tools/test/run_gut.ps1` then terminated before printing `Importing project...` or running GUT.
3. The termination did not produce a clear actionable failure and could be mistaken for success.
4. Supplying the sibling console executable, `Godot_v4.7-stable_win64_console.exe`, worked correctly:
   - Godot `4.7.stable.official.5b4e0cb0f`;
   - headless import succeeded;
   - full GUT run passed 3/3 tests with exit code 0;
   - focused GUT run passed 3/3 tests with exit code 0.

The current PowerShell wrapper must not treat an empty version probe or a null native exit code as success.

## Required reading

Before editing, read:

- `AGENTS.md`
- `docs/codex/milestone-prompts/M00-repository-test-harness.md`
- `docs/codex/TESTING_AND_VALIDATION.md`
- `docs/codex/IMPLEMENTATION_RULES.md`
- `docs/codex/MILESTONES.md`
- `README.md`
- `tools/test/run_gut.ps1`
- `tools/test/run_gut.sh`
- PR #1 implementation summary and current diff

Inspect the current branch and state the proposed approach before editing.

## Scope

Implement only the following correction:

1. Make `tools/test/run_gut.ps1` safe and explicit for Windows Godot executable selection.
2. Prefer the Windows console executable for command-line use:
   - when the resolved path already points to `*_console.exe`, use it;
   - when it points to a normal Godot GUI executable and a matching sibling `*_console.exe` exists, use the sibling and print a concise notice;
   - when no suitable console executable can be found, fail clearly with a nonzero exit and instructions.
3. Treat all of these as explicit failures before import:
   - native version-process exit status is null or unavailable;
   - version output is empty or whitespace;
   - version process returns nonzero;
   - parsed version is not Godot 4.7.x.
4. Never call `exit` with `$null`. Every failure path must use a documented nonzero integer.
5. Preserve the successful GUT process exit code exactly after tests run.
6. Update `README.md` and `docs/codex/TESTING_AND_VALIDATION.md` so Windows examples:
   - recommend `Godot_v4.7-stable_win64_console.exe`;
   - explain GUI-to-console sibling resolution;
   - include exact outside-repository invocation;
   - include an exact safe one-time failing-test procedure and cleanup;
   - state that blank version output is a wrapper failure, not a pass.
7. Keep `docs/codex/MILESTONES.md` truthful: M00 remains `Pull request open` and verification remains `Partial` until all Linux and owner-run Windows merge gates pass.
8. Keep Steam uninitialized and preserve all existing M00 scope boundaries.

## Non-goals

Do not:

- modify GUT or GodotSteam source;
- initialize Steam or add `steam_appid.txt`;
- change Godot project settings, engine version, renderer, or main scene;
- add Pester or another test dependency;
- implement gameplay, M01, CI, GitHub Actions, or environment secrets;
- modify the approved M00 prompt or `PROMPT_TEMPLATE.md`;
- add machine-specific absolute paths to the repository.

## Required behavior

- A valid `*_console.exe` path prints a non-empty Godot 4.7.x version, imports, runs GUT, and returns GUT's exit code.
- A corresponding GUI executable path either resolves to the sibling console executable and proceeds, or fails clearly and nonzero.
- Empty version output can never produce exit code 0.
- Missing and unsupported executables continue to fail before import with actionable diagnostics.
- Wrapper invocation from outside the repository continues to resolve the project correctly.
- Focused GUT arguments continue to work.
- No Steam client, account, network call, or `steam_appid.txt` is required.

## Codex-executable verification

Run all checks available in the implementation environment and report exact commands and exit codes.

At minimum:

- inspect the PowerShell script for explicit null/empty-output handling;
- run `bash -n tools/test/run_gut.sh`;
- rerun Linux M00 checks if Godot 4.7.x is available;
- run `git diff --check`;
- confirm no local absolute path or temporary failing test remains;
- keep unavailable PowerShell and Windows checks as `Pending owner verification`.

Do not claim the PowerShell behavior passed unless it was executed in a suitable Windows/PowerShell environment.

## Owner-run Windows verification after the correction

The project owner will test the updated PR head with Godot
`D:\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe`.

The required owner checks remain:

1. Full wrapper: exit 0.
2. Focused infrastructure test: exit 0.
3. Outside-repository invocation using the wrapper's absolute path: exit 0.
4. Safe temporary failing-test procedure: nonzero while the test exists, then exit 0 after removal; no temporary file remains.
5. Ordinary GUI executable path:
   - resolves visibly to the sibling console executable and succeeds, or
   - fails clearly and nonzero according to the implemented contract.
6. Godot 4.7 editor opens the project, imports/GDExtensions settle, the dry-run scene runs, and no new errors appear.
7. No `steam_appid.txt` or live Steam initialization is required.
8. Record the exact PR head SHA or branch shown by GitHub for the tested revision.

## Acceptance criteria

- `run_gut.ps1` cannot silently succeed on null exit status or blank version output.
- Windows CLI documentation names the console executable.
- The documented full, focused, outside-root, and failure-propagation procedures are copy/paste complete.
- Linux wrapper behavior is not regressed.
- No new dependency, gameplay feature, or unrelated refactor is introduced.
- M00 remains partial until explicit Linux and owner evidence completes every merge gate.

## Final response

Use the repository-standard headings:

### Implementation completed
### Files changed
### Verification
### Assumptions
### Known limitations and risks
### Deferred work
### Suggested next task

Under **Verification**, list every owner-run Windows item as `Pending owner verification` unless the owner has explicitly supplied a result for the updated PR head.
