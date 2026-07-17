# Death Idle Testing and Validation

**Document role:** Canonical test strategy, commands, fixture rules, and manual validation flows
**Repository path:** `docs/codex/TESTING_AND_VALIDATION.md`
**Document status:** Approved validation plan through M04B with M04C approved
**Validation revision:** 15
**Last updated:** 2026-07-17
**Engine target:** Godot 4.7 standard build, GDScript only
**Architecture companion:** [ARCHITECTURE.md](ARCHITECTURE.md)  
**Owner evidence companion:** [OWNER_VERIFICATION_WORKFLOW.md](OWNER_VERIFICATION_WORKFLOW.md)

## 1. Current status

The repository already contains:

- GUT 9.7.1 under `addons/gut/`;
- GodotSteam GDExtension 4.20 under `addons/godotsteam/`;
- development Steam App ID `480` in `project.godot`;
- disabled automatic Steam initialization.

M00 has added the approved automated harness:

- `.gutconfig.json`;
- `tools/test/run_gut.sh`;
- `tools/test/run_gut.ps1`;
- `tests/unit/infrastructure/test_project_harness.gd`;
- canonical import, focused-test, full-test, outside-root, and smoke documentation.

M00 merged through PR #4. Linux/Codex Cloud and owner-run Windows verification passed, including full and focused GUT execution, outside-root invocation, main-scene/editor smoke, passive Steam configuration, intentional failing-test propagation, cleanup, and clean recovery. Future milestones use the same canonical wrappers and the owner evidence package described in `OWNER_VERIFICATION_WORKFLOW.md`.

M01 merged through PR #5. Linux/Codex and owner-run Windows verification passed the full suite, focused fixed-point/time/source-ownership suite, import preflight, trusted-time reconciliation trace, long-horizon 24-hour fixed-point trace, cleanup, and generated-log checks.

M02 merged through PR #6 and passed codec, schema, migration, atomic-storage, corruption-recovery, and Windows filesystem verification.

M03 merged through PR #7 at merge commit `5e2b9b23878c9280f75b987cc9ad567d8980030d` from final head `971cdaa0fd46f641ec7409148e259d54f953d8c7`. Linux/Codex and owner-run Windows verification passed the full and focused content suites, import, deterministic semantic catalog trace, artifact audit, and Godot Inspector checklist. The repository now uses lettered implementation slices under `DEC-0033`.

M04A merged through PR #8 at merge commit `673ad884357fc742a0a26dbb542d5b8d9fe557c9` from final head `04b12d8ba2edeecbf13f252216249341469b40a8`. Schema version 2 is current, version 1 remains a frozen supported input, and the production upgrade preserves the historical envelope before atomic persistence. Linux/Codex and owner Windows verification passed.

M04B merged through PR #9 at merge commit `c641d74cebedf07c51ebb579cccee21db7aa2410` from final head `5301c94bfd0fb837f9961fda624d7559042327e2`. Threshold-scoped operation identity, typed assignment results/events, global assignment validation, persistence, the complete identity trace, and Windows owner verification passed.

Accepted `DEC-0036` and approved M04C v0.1 define transactional core resolution, exact Settlement segmentation, stable core residual ownership, and the temporary one-active-Reaping implementation limit.

## 2. Pinned test and platform dependencies

### 2.1 GUT 9.7.1

GUT 9.7.1 is the approved GDScript test framework for Godot 4.7.x. It is already committed and is not downloaded by M00 or at test time.

M00 verified the committed version from `addons/gut/plugin.cfg`, retained `addons/gut/LICENSE.md`, and added `.gutconfig.json` with repository-relative recursive discovery under `res://tests`. The wrappers avoid addon updaters, floating versions, and runtime network downloads. Failure propagation and clean recovery are verified on both Linux/Codex Cloud and the owner's Windows Godot machine.

Official project references:

- [GUT repository and version table](https://github.com/bitwes/Gut/tree/v9.7.1)
- [GUT 9.7.1 release](https://github.com/bitwes/Gut/releases/tag/v9.7.1)
- [GUT command-line documentation](https://gut.readthedocs.io/en/latest/Command-Line.html)

### 2.2 GodotSteam 4.20 during M00

GodotSteam is present so the project can later implement the trusted-time adapter. M00 does not initialize Steam or call a Steam API.

M00 verifies only that:

- the pinned GDExtension loads under Godot 4.7 in supported headless and Windows environments;
- ordinary import and GUT execution work when Steam is absent or not initialized;
- development App ID `480` remains in `project.godot` and automatic initialization remains disabled;
- the dependency and applicable license/notice footprint are documented;
- no `steam_appid.txt` file is required as a standard repository prerequisite.

Live Steam behavior belongs to M06.

## 3. Execution environments and Godot executable contract

### 3.1 Separate execution environments

The project uses two required execution environments:

| Environment | Executor | Required automated entry point | Additional responsibility |
|---|---|---|---|
| Codex Cloud or Linux | Codex | `tools/test/run_gut.sh` | Headless import, GUT, and safe smoke checks |
| Windows Godot machine | Project owner | `tools/test/run_gut.ps1` | Windows test run, editor/manual checks, and later Steam integration checks |

Git transfers the branch between machines. It does not allow Codex to run commands on the Windows Godot machine. Codex App or CLI does not need to be installed there.

A pull request may be opened while the owner-run Windows check is pending. The result must be labelled **Pending**, not **Passed**. Any milestone that makes Windows or Steam a merge gate cannot merge until that check is recorded as passed.

### 3.2 Godot executable discovery

Both wrappers must locate the Godot executable in this order:

1. an explicit wrapper argument;
2. the local `GODOT_BIN` environment variable;
3. a documented executable name on `PATH`.

They must:

- print the detected executable and `godot --version` output;
- require Godot 4.7.x;
- fail clearly when Godot cannot be found or is the wrong version;
- contain no committed user-specific absolute path.

The owner may set `GODOT_BIN` or `PATH` locally on Windows. That configuration is never committed. On Windows, `GODOT_BIN`, `-GodotBin`, or `PATH` should resolve to the console executable, for example `Godot_v4.7-stable_win64_console.exe`. The normal GUI executable is for editor launches and is not the documented harness path because command-line output and exit-code capture are less reliable through the GUI binary.

## 4. Canonical commands after M00

### 4.1 Full automated suite

Linux or Codex Cloud:

```sh
./tools/test/run_gut.sh
```

Windows PowerShell:

```powershell
.\tools\test\run_gut.ps1 -GodotBin 'C:\Path\To\Godot_v4.7-stable_win64_console.exe'
```

Default full mode must:

1. resolve the repository root from the wrapper location;
2. print and validate Godot 4.7.x;
3. run a headless project import;
4. run the full GUT suite using `.gutconfig.json`;
5. return the real failing or successful process exit code.

Focused selectors are forwarded after `--` on Linux and through `-GutArgs` on Windows. The final milestone verification uses the default full mode.

### 4.2 Underlying import fallback

If a wrapper itself is being diagnosed, the repository-relative import command is:

```text
godot --headless --path . --import
```

### 4.3 Underlying GUT fallback

The pinned GUT runner is:

```sh
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json
```

`.gutconfig.json` supplies test directories and other stable options. Command-line arguments may override it for focused execution.

### 4.4 Focused tests

The wrappers forward GUT selectors with these exact forms:

```sh
./tools/test/run_gut.sh -- -gtest=res://tests/unit/infrastructure/test_project_harness.gd
./tools/test/run_gut.sh -- -gunit_test_name=steam_development
```

```powershell
.\tools\test\run_gut.ps1 -GodotBin 'C:\Path\To\Godot_v4.7-stable_win64_console.exe' -GutArgs @('-gtest=res://tests/unit/infrastructure/test_project_harness.gd')
.\tools\test\run_gut.ps1 -GodotBin 'C:\Path\To\Godot_v4.7-stable_win64_console.exe' -GutArgs @('-gunit_test_name=steam_development')
```

Codex may run focused tests while iterating, but it must run the applicable broader suite before marking a task complete.

### 4.5 Main-scene smoke

Until a dedicated smoke wrapper exists, the repository-relative fallback is:

```sh
godot --headless --path . --quit-after 5
```

M00 validates the current dry-run scene without redesigning it. M05 may replace this with a dedicated ready-state smoke runner and must update this document in the same pull request.

### 4.6 Outside-root wrapper checks

Linux:

```sh
repo_root="$(pwd)"; tmp_dir="$(mktemp -d)"; (cd "$tmp_dir" && "$repo_root/tools/test/run_gut.sh"); result=$?; rmdir "$tmp_dir"; exit $result
```

Windows PowerShell:

```powershell
$repoRoot = (Get-Location).Path
Push-Location $env:TEMP
& "$repoRoot\tools\test\run_gut.ps1" -GodotBin "C:\Path\To\Godot_v4.7-stable_win64_console.exe"
$result = $LASTEXITCODE
Pop-Location
exit $result
```

### 4.7 M00 temporary failure-propagation check

M00 completion proved failure propagation and clean recovery on Linux/Codex Cloud and Windows. The following PowerShell procedure remains the canonical reproducible Windows check. Use the console executable path for reliable output and exit-code capture.

```powershell
$godotBin = 'C:\Path\To\Godot_v4.7-stable_win64_console.exe'
$temporaryTest = 'tests/unit/infrastructure/test_m00_expected_failure.gd'
$temporaryUid = "$temporaryTest.uid"

@'
extends GutTest

func test_expected_failure_propagates() -> void:
	assert_true(false, "temporary M00 Windows failure-propagation check")
'@ | Set-Content -Path $temporaryTest -Encoding utf8

.\tools\test\run_gut.ps1 -GodotBin $godotBin -GutArgs @('-gtest=res://tests/unit/infrastructure/test_m00_expected_failure.gd')
$failingExit = $LASTEXITCODE
if ($failingExit -eq 0) {
    throw "Expected the temporary failing GUT test to return a nonzero exit code."
}
Write-Host "Temporary failing-test exit code: $failingExit"

Remove-Item -LiteralPath $temporaryTest -Force
Remove-Item -LiteralPath $temporaryUid -Force -ErrorAction SilentlyContinue

if (Test-Path -LiteralPath $temporaryTest) {
    throw "Temporary failing test still exists: $temporaryTest"
}
if (Test-Path -LiteralPath $temporaryUid) {
    throw "Temporary failing test UID still exists: $temporaryUid"
}
Write-Host "Temporary failing test and UID companion are absent."

.\tools\test\run_gut.ps1 -GodotBin $godotBin
$recoveryExit = $LASTEXITCODE
if ($recoveryExit -ne 0) {
    throw "Expected the clean full wrapper rerun to exit 0; got $recoveryExit."
}
Write-Host "Clean full wrapper recovery exit code: $recoveryExit"
```

Do not commit `test_m00_expected_failure.gd`, `test_m00_expected_failure.gd.uid`, generated logs, or machine-specific Godot paths.

## 5. Planned test layout

```text
tests/
  unit/
    content/
    domain/
    simulation/
    persistence/
    tutorial/
  integration/
    progression/
    save_load/
    prototype_paths/
  fixtures/
    content/
    saves/
    states/
  support/
    fake_monotonic_clock.gd
    fake_trusted_time_provider.gd
    fixture_factory.gd
    assertion_helpers.gd
    memory_save_storage.gd
```

Do not create empty folders solely to match this map. Add each directory with its first test or support file.

## 6. Test design principles

### 6.1 Test behavior, not implementation trivia

Prefer assertions about authoritative state and externally meaningful events:

- exact backlog remaining;
- exact owned, reserved, and available quantities;
- completed milestone IDs;
- active Writ after a transition;
- report delta versus inventory total;
- save round-trip equality;
- forecast versus committed offline result.

Avoid tests that break because a private helper was renamed while behavior stayed correct.

### 6.2 Use explicit small fixtures

Fixture values should be easy to calculate by hand. For example:

- backlog of 100;
- rate of 10 returns per second;
- milestone at 50;
- Hall batch every 5 seconds;
- ten Rations with one per-second consumption.

Do not use full production tuning values when a small fixture proves the rule more clearly.

### 6.3 No real waiting

Never use real-world sleeps to test progression. Pass elapsed milliseconds directly or advance `FakeMonotonicClock` or supply a `FakeTrustedTimeProvider` sample.

### 6.4 One reason per test

A test name states the condition and expected result, for example:

```text
test_emergency_writ_transitions_without_replacing_reaping
test_opening_four_do_not_increment_reaping_milestones
test_report_clear_does_not_change_inventory
test_ration_depletion_preserves_base_progress
```

### 6.5 Deterministic test setup

Every test controls:

- content definitions;
- initial state;
- elapsed time;
- monotonic clock values and trusted-time samples;
- content revision;
- random source, if one is ever introduced.

## 7. Required unit-test groups

### 7.1 Fixed-point and time-authority utilities

Test:

- exact `FixedPoint.SCALE = 1_000_000` and proof that discrete inventory/backlog counts remain unscaled;
- fixed-point conversion and canonical rounding;
- multiply/divide, explicit-period accumulation, whole-unit extraction, and residual preservation;
- one whole unit per eight hours: `250_000` progress subunits after two hours, one whole unit after eight hours, and identical results across equivalent chunks;
- one whole unit per twenty-four hours: `250_000` progress subunits after six hours, one whole unit after twenty-four hours, and identical results across equivalent chunks;
- overflow and invalid negative handling, including a final-fit case whose naive intermediate multiplication would overflow;
- equivalent interval chunking;
- monotonic foreground clock behavior;
- trusted sample statuses, source IDs, and normalization to integer milliseconds;
- first trusted anchor establishes a baseline without retroactive credit;
- already-credited foreground time is subtracted from a later trusted gap;
- unavailable trusted time grants no closed-session progress and preserves pending reconciliation;
- backward, stale, contradictory, and implausible trusted samples grant no progress and emit diagnostics;
- exact signed 64-bit integer-string encode/decode at `0`, ordinary values, `2^53 - 1`, `2^53`, signed 64-bit limits, and representative trusted UTC timestamps;
- rejection of JSON numeric values, leading plus signs, non-canonical leading zeroes, decimal strings, exponent notation, whitespace, non-digits, and out-of-range integer strings for authoritative integer fields;
- proof that authoritative save dictionaries contain no JSON numeric values for integer fields.

### 7.2 Content registry

Test:

- valid content catalog loads;
- duplicate ID rejection;
- wrong-prefix rejection;
- missing reference rejection;
- invalid Retinue requirement rejection;
- invalid recipe rejection;
- unsupported modifier metric or operation rejection;
- deterministic lookup and iteration order.

### 7.3 Inventory and reservations

Test:

- owned, reserved, and available reconciliation;
- spending cannot use reserved quantity;
- creating and releasing a reservation;
- duplicate reservation prevention;
- Soldier Company reserves exactly twelve Souls;
- removing Soldier Company returns all twelve to availability;
- save round trip preserves reservations;
- malformed reservation greater than owned is rejected.

### 7.4 Form and modifier evaluation

Test:

- Man-at-Arms and Scribe load as data, not name-based branches;
- Threshold-tag conditions;
- stable modifier ordering;
- support-state multiplier;
- Recollection modifier;
- modifier trace before and after values;
- Scribe discovery and uncertainty effects;
- no UI formatting value enters the calculation.

### 7.5 Reaping dispatch and assignment

Test:

- cannot dispatch an unawakened Form;
- cannot exceed command tether capacity;
- cannot dispatch twice at one Threshold;
- valid dispatch creates one runtime record;
- assignment change resolves prior elapsed time first;
- assignment revision increments;
- Retinue compatibility validation;
- dispatch and assignment save round trips.

### 7.6 Hall behavior

Test:

- Hall cannot run before restoration;
- recipe consumes input and banks output;
- output target stops or idles production as defined;
- insufficient input pauses Hall production without corrupting progress;
- cycle remainder survives save/load;
- Larder output is available at a same-time support boundary.

### 7.7 Milestones and guarantees

Test:

- each condition fires exactly once;
- completion is recorded even when top-up amount is zero;
- top-up grants only the missing amount;
- current legitimate production is preserved;
- secured Scribe costs cannot be spent elsewhere;
- the player still performs the Awaken command;
- Broken Watch and tether 2 unlock once;
- 5,000 and 10,000 resonance IDs remain distinct;
- repeated load cannot duplicate Essence, tether capacity, or resonance events.

### 7.8 Tutorial coordinator

Test:

- current state persists;
- already-satisfied conditions skip redundant guidance;
- only one blocking presentation is selected;
- pending notices rebuild from state;
- narrative skip applies required world state exactly once;
- non-recommended assignment selects fallback discovery;
- report completion while another screen is open remains queued;
- mechanical guidance skip does not directly mutate domain systems under the current conservative rule.

## 8. Required simulation tests

### 8.1 Repeatability

Given the same validated state, content revision, and elapsed interval, two independent runs must produce identical:

- inventory;
- backlog;
- Mastery;
- discovery;
- milestone and guarantee IDs;
- support transitions;
- Hall state;
- report deltas;
- final simulation cursor.

### 8.2 Chunking invariance

Compare:

```text
resolve(8 hours once)
```

with logically equivalent chunking such as:

```text
resolve(1 hour eight times)
resolve(15 minutes thirty-two times)
```

When the same boundary rules apply, authoritative end state must match exactly.

### 8.3 Online, offline, and forecast equivalence

From the same baseline:

1. resolve in Live mode on one clone;
2. resolve in Offline mode on another clone;
3. forecast on a third clone;
4. compare authoritative or predicted end values.

Allowed differences are limited to commit metadata, report-presentation packaging, and other mode-specific non-balance data.

### 8.4 Global shared-resource resolution

Test two Reapings plus Larder together. The result must not depend on calling each subsystem in a different external order.

### 8.5 Same-time boundaries

Create fixtures where:

- a Ration batch completes exactly as support would deplete;
- a milestone and backlog zero occur together;
- discovery and a Hall target occur together;
- Emergency completion and another guarantee boundary occur together.

Assert the documented priority and stable event order.

### 8.6 Zero-time loop protection

An invalid boundary implementation that repeatedly returns zero without state change must fail clearly rather than hang.

### 8.7 Opening-four exclusion

After the scripted transaction:

- Gloamwood backlog is `999,996`;
- scripted returns equal four;
- Gloamwood persistent-Reaping returns equal zero;
- regional persistent-Reaping returns equal zero;
- none of the 1,000, 2,500, 5,000, 10,000, or 25,000 milestones advances.

After the Reaping produces 1,000 returns, only the 1,000 post-dispatch milestone completes.

### 8.8 Emergency-to-Standard continuity

Resolve an interval that crosses the 1,000 boundary and continues beyond it. Assert:

- the same Reaping runtime record remains active;
- command tether occupancy never drops;
- Writ changes to Standard exactly once;
- progress before and after the boundary uses the appropriate data;
- remaining elapsed time is not lost;
- report and guarantee events are not duplicated.

### 8.9 Settled Passage continuity

Resolve an interval that reaches zero backlog and has time remaining. Assert:

- lifecycle becomes Settled exactly once;
- the Reaping remains active;
- remaining time uses Settled rates;
- essential channels remain available;
- no negative backlog occurs.

### 8.10 Long-horizon discrete acquisition progress

Using a deterministic test channel that produces one whole item per twenty-four hours, verify:

- six hours records `250_000` acquisition subunits and zero whole inventory units;
- changing the active Form/Writ/Retinue rate context after resolving to the command time preserves prior progress and carry while deriving a new numerator against the same normalized channel period;
- a four-hour baseline fixture at `50.0%` progress remains at `50.0%` after a twenty-percent future rate increase while the ETA changes from two hours to one hour forty minutes;
- purchasing a test Recollection or enabling another global rate modifier mid-operation resolves the old rate before the unlock boundary and the new rate after it;
- repeated recall and redispatch with the same state does not reapply or compound the rate bonus;
- effective rate is re-derived from immutable baseline data plus current modifiers rather than from the previous effective rate;
- recalling the Reaping freezes progress and redispatch resumes it;
- a twenty-four-hour equivalent interval banks exactly one whole item and retains the exact remainder;
- one-shot, hourly, and mixed-chunk resolution produce identical whole units, Threshold progress, and arithmetic carry;
- Overdue-to-Settled transition does not reset the source when the Settled definition retains it;
- Unknown disclosure hides the progress while debug/state inspection confirms it remains authoritative;
- the player-facing percentage helper floors to one decimal and never shows `100.0%` before a whole unit is banked.

### 8.11 Support degradation

Resolve through Ration depletion. Assert:

- Soldier Company effect changes to the configured floor;
- base backlog, Essence, and Mastery continue;
- forecast identifies the boundary and post-depletion behavior;
- report records one transition;
- later Ration production can restore support if current prototype policy permits it.

### 8.12 Hidden production and discovery

Produce Provisions while its channel is Unknown, then identify it. Assert:

- inventory increased before identification;
- no duplicate grant occurs at identification;
- player-facing read model hid the ID or exact row before identification;
- the identified read model reveals the existing banked total;
- Scribe and fallback paths reach the same required state at different speeds.

## 9. Persistence and offline tests

### 9.1 State and codec round trip

Every saved runtime class needs a primitive-schema round trip. The prototype JSON codec also needs a byte-codec round trip:

```text
state -> primitive snapshot -> state
primitive snapshot -> JSON bytes -> primitive snapshot
```

Compare all authoritative fields and invariants. Include fixture values above `2^53` so the test fails if the codec accidentally emits JSON numbers and recovers them through floating-point conversion.

Also assert that:

- authoritative integers are written as canonical decimal strings and reconstruct exactly as runtime integers;
- `codec_id` is validated and an unknown codec never overwrites a valid save;
- `TimeAuthorityState` reconstructs exactly;
- the M01 no-anchor runtime sentinel (`-1`) maps to `has_trusted_anchor = false`, empty source, and canonical wire anchor `"0"`, then reconstructs the no-anchor runtime state exactly;
- set-like arrays are sorted and duplicate-free;
- persisted enum values and IDs are stable strings;
- malformed integer strings reject the candidate save rather than being clamped or cast;
- domain-state tests do not require JSON and remain valid if a later codec changes the byte representation.

### 9.2 Primary and backup selection

Test:

- valid primary selected;
- corrupt primary falls back to valid backup;
- valid snapshot with highest save revision selected;
- both invalid produce a clear recoverable failure;
- unsupported future schema is rejected without overwriting files.
- a payload digest mismatch rejects that candidate and preserves both files for diagnosis;

### 9.3 Atomic-write failure points

Using memory or temporary storage, simulate failure:

- before temporary write;
- during write;
- after write but before validation;
- after backup rotation but before primary replacement;
- after primary replacement.

At least one valid committed snapshot must remain loadable.

### 9.4 Migration fixtures

Keep one immutable fixture for every supported historical schema. Test each source with its own version-specific validator before sequential migration to the current schema.

For M04A specifically:

- retain a canonical schema-version-1 foundation fixture;
- add representative valid and invalid schema-version-2 fixtures;
- prove that `v1 -> v2` preserves simulation time, all `TimeAuthorityState` wire fields, content revision, metadata, offline-resolution ID, and source save revision during the pure transform;
- prove that the persisted upgrade increments save revision exactly once;
- prove that the migration adds only canonical empty gameplay maps and tether capacity zero;
- prove that a successful upgrade retains a recoverable prior valid snapshot;
- prove that source validation, migration, target validation, content/domain validation, revision-overflow, and atomic-write failures preserve the original and expose no migrated live state;
- prove that an already-current version-2 load does not rewrite the file or increment revision;
- prove that an unknown future version is rejected without overwrite.

### 9.5 Interrupted offline resolution

Test two failure windows:

- failure before resolved state is committed: next load resolves from the old cursor once;
- failure after resolved state is committed: next load begins at the new cursor and does not duplicate output.

### 9.6 Trusted-time anomalies and clock manipulation

Test:

- zero trusted gap;
- first trusted anchor establishes a baseline without retroactive production;
- trusted time unavailable at load, during play, and at quit;
- foreground progress continues while closed-session credit remains pending;
- reconnecting later resolves only `trusted gap - already credited foreground time`;
- a trusted sample earlier than the anchor grants zero and does not move the anchor;
- a materially negative or implausible reconciliation is rejected and reported;
- elapsed time beyond the configured cap reports both credited and capped/unprocessed time;
- exact one-hour and eight-hour paths;
- focus loss, simulated suspend, regain, quit, and repeated load do not double count;
- changing a fake local wall clock, timezone, or calendar has no effect because no authoritative code reads it;
- release builds cannot select a debug or manual trusted-time provider.

Also maintain a focused source-ownership check or review rule that rejects authoritative calls to device-time APIs such as Godot system Unix-time methods or file modification timestamps. Non-authoritative display code may use local calendar time only when it is clearly isolated from progression and documented.

### 9.7 Save corruption and tamper-posture tests

Test the promises the project actually makes:

- malformed or truncated files are rejected and fall back to the last valid backup;
- an optional unkeyed digest mismatch is treated as corruption, not as proof of malicious editing;
- hand-editing a JSON payload to violate an invariant is rejected by schema or domain validation;
- replacing both local copies with an older but internally valid snapshot is documented as outside strong client-only prevention unless a future server-backed high-water mark is added;
- a binary or compressed test codec, if introduced later, must pass the same schema, migration, and atomic-storage suite.

## 10. Report and forecast tests

Test:

- gains are in inventory before the report opens;
- opening snapshots the accumulator into history;
- clearing the live accumulator leaves inventory unchanged;
- report history survives save/load;
- the same gain is not reported twice;
- forecast does not mutate its baseline state;
- two forecasts from the same baseline are identical;
- hypothetical assignment comparison starts both branches from the same clone;
- forecast hides unknown channels appropriately;
- actual offline resolution matches the forecast under unchanged state and content.

## 11. Integration test paths

### 11.1 Foundation path

Developer-visible path:

1. create a fixture new game;
2. dispatch one dummy Reaping;
3. resolve online time;
4. save and reload;
5. provide a trusted-time sample and resolve the uncredited closed-session interval;
6. compare final state and report totals.

### 11.2 Opening through first Reaping

1. create new game;
2. perform opening four once;
3. reload and prove it cannot repeat;
4. Brand Man-at-Arms;
5. dispatch Emergency Writ;
6. cross 1,000 post-dispatch returns;
7. prove seamless Standard transition and Soldier top-up.

### 11.3 Form and Retinue path

1. reach 2,500 Gloamwood Reaping returns;
2. secure Scribe resources;
3. player issues Awaken;
4. unlock Muster;
5. field Soldier Company;
6. verify twelve reserved and no destruction;
7. remove and re-field after save/load.

### 11.4 Concurrent Reaping and discovery path

1. awaken Scribe;
2. reach 5,000 Gloamwood Reaping returns;
3. unlock minor resonance, Broken Watch, and tether 2 once;
4. dispatch both Reapings;
5. run Scribe discovery path;
6. run non-Scribe fallback path from the same setup;
7. verify banked Provisions in both.

### 11.5 Hall and support path

1. identify Provisions;
2. apply the onboarding floor;
3. restore Larder;
4. start Provisions-to-Rations;
5. cross support depletion and Hall batch boundaries;
6. verify graceful degradation and recovery behavior;
7. save/reload during an incomplete Hall cycle.

### 11.6 Trusted-time and offline-return path

1. create or load a save without a trusted anchor and prove no retroactive offline credit is granted;
2. establish a fake trusted anchor and save;
3. credit foreground monotonic time and save again;
4. advance trusted time by a larger interval;
5. resolve only the trusted span minus already-credited foreground time;
6. repeat with trusted time unavailable and confirm the closed-session interval remains pending;
7. restore trusted time and prove the pending interval resolves once;
8. change a fake local calendar by large forward and backward amounts and prove results are unchanged;
9. interrupt before and after atomic commit and prove no duplicate offline reward;
10. generate the welcome-back report from already-committed gains.

### 11.7 Full tutorial path

The final integration suite should cover:

- normal recommended path;
- non-recommended Form placement;
- quit during dialogue;
- quit with Soulweave open when Emergency completes;
- early legitimate Soldier or Scribe drops;
- spending attempts against secured costs;
- Ration depletion before Larder guidance;
- offline settlement;
- narrative skip;
- mechanical guidance skip under the approved final rule;
- repeated load after each exactly-once reward;
- completion at `TUT_13_COMPLETE`.

## 12. Manual validation

Automated tests do not replace player-facing, Windows-specific, or Steam-specific checks.

### 12.1 Verification ownership matrix

| Check | Normal executor | May be completed by Codex Cloud? | Merge treatment |
|---|---|---:|---|
| Linux import and GUT | Codex | Yes | Required after M00 |
| Windows GUT wrapper | Project owner | No | Required for milestones that change executable Godot behavior |
| Godot editor and visual flow | Project owner | No | Required when presentation or resources change |
| Windows file-replacement behavior | Project owner | No | Required for persistence milestones |
| Live GodotSteam behavior | Project owner | No | Required for M06, M16, and relevant release checks |
| Fake trusted-time behavior | Codex or owner | Yes | Required for time/offline milestones |

The pull-request report records these categories separately. An unperformed category remains pending.

### 12.2 Current minimum Windows check

For a presentation or executable Godot change:

1. pull the branch on the Windows Godot machine;
2. run `tools/test/run_gut.ps1` after M00, or perform the documented temporary checks before M00;
3. open the project in Godot 4.7 and allow imports to complete;
4. confirm no new parser, import, GDExtension, or resource errors;
5. run the configured main scene;
6. exercise the exact changed flow;
7. resize the window to at least two common smaller sizes when UI changed;
8. confirm no authoritative production pauses while navigating applicable screens;
9. record what was observed and what was not checked.

### 12.3 Fake trusted-time checks

In an automated or debug-only test environment with an explicit fake trusted-time source:

1. save with a known trusted anchor;
2. reload through the test harness;
3. advance the fake trusted source by one hour and verify the expected return;
4. advance only a fake device wall clock and verify that no additional progress appears;
5. load with trusted time unavailable and verify that foreground production continues while the closed-session interval remains pending;
6. restore trusted time and verify that already-credited foreground time is subtracted exactly once.

Do not expose fake-time controls in release exports.

### 12.4 Windows GodotSteam trusted-time checks

When M06 implements the adapter, run these checks on the Windows Godot machine with the pinned GodotSteam 4.20 addon and Steam client.

Development configuration:

- App ID `480` comes from `project.godot`;
- automatic Steam initialization is disabled;
- the adapter initializes Steam explicitly;
- `steam_appid.txt` is not a standard prerequisite and must not be added merely as a precaution.

Required checks:

1. Confirm GodotSteam loads under Godot 4.7 without extension errors.
2. Initialize through the M06 adapter and confirm the active development App ID and initialization result.
3. Confirm the adapter accepts a sample only when the pinned wrapper reports semantics equivalent to a live `ISteamUser::BLoggedOn()` connection.
4. Confirm the accepted epoch is obtained through semantics equivalent to `ISteamUtils::GetServerRealTime()` and normalized to integer milliseconds.
5. Save an active Reaping, close for a short controlled interval with Steam connected, relaunch, and verify one credited result.
6. Repeat while Steam is unavailable or in a disconnected state; verify no guessed closed-session credit and a pending reconciliation state.
7. Reconnect and verify reconciliation commits once after subtracting already-credited foreground time.
8. Change Windows date, time, and timezone without changing the Steam source; verify credited progress does not change.
9. Reload repeatedly after the committed result and verify no duplicate reward or welcome-back record.
10. Record the Godot version, GodotSteam version, App ID, connection scenario, and outcome.

The underlying Steamworks semantics are documented by [ISteamUser::BLoggedOn](https://partner.steamgames.com/doc/api/ISteamUser#BLoggedOn) and [ISteamUtils::GetServerRealTime](https://partner.steamgames.com/doc/api/ISteamUtils#GetServerRealTime). M06 must still inspect the pinned GodotSteam wrapper names rather than assume a direct one-to-one method name.

App ID `480` proves the bridge and adapter behavior only. Death Idle's own App ID, package ownership, launch-through-Steam behavior, external Playtest distribution, and final export configuration remain later validation.

If a specific launch method proves that `steam_appid.txt` is required despite the project setting, record the exact method and evidence before adding a local ignored file. Do not commit or ship it by default.

### 12.5 Pull-request evidence handoff

A Codex pull request should leave a concise owner checklist when Windows work is required. The owner records:

```text
Windows Godot version:
run_gut.ps1 result:
Editor/manual flow result:
Steam result, when applicable:
Observed failures or warnings:
```

Do not modify a wrapper privately to bypass a failure. Fix the repository script in the branch so both environments keep one contract.

## 13. Codex Cloud environment

The Codex Cloud environment must provide:

- a pinned Godot 4.7 standard Linux editor binary;
- `godot` on `PATH` or `GODOT_BIN` configured in the environment;
- the repository-pinned GUT and GodotSteam files from the checkout;
- no required GUI session;
- no machine-specific path committed to the repository;
- setup-time installation only, with import and tests able to run without network access;
- enough time for import and the full headless suite.

M00 configures or documents the environment so Codex can run:

```text
./tools/test/run_gut.sh
```

The wrapper prints the Godot version, imports the project, and runs GUT. M00 also proves that a deliberately failing temporary test returns a nonzero status before removing that test from the final diff.

GodotSteam may be present as a loadable GDExtension, but M00 and ordinary cloud tests keep automatic initialization disabled and do not require Steam, a Steam account, storefront credentials, or `steam_appid.txt`. M06 cloud tests use a fake provider or fake bridge. A cloud result never substitutes for the owner-run Windows Steam checklist.

## 14. GitHub Actions

GitHub Actions is deferred until:

1. local Windows commands pass reliably;
2. Codex Cloud runs the same suite reliably;
3. GUT and Godot installation are pinned;
4. test runtime is reasonable;
5. artifacts and failure logs have a defined value.

When added, CI should run import, tests, and a main-scene smoke check. It should not download an unpinned latest Godot build.

## 15. Test output and artifacts

Once configured, headless tests should:

- return a nonzero process code on failure;
- show failed test names and assertions in stdout;
- optionally write JUnit XML to a generated test-results directory;
- avoid committing generated results;
- preserve useful logs as CI or Codex task artifacts when available;
- write milestone-specific owner logs only under the ignored `tools/test/owner/logs/` path defined in `OWNER_VERIFICATION_WORKFLOW.md`.

Do not hide failures behind a wrapper that always exits successfully.

## 16. Pull-request verification report

Every Codex pull request reports:

### Scope assessment versus actual

Record the implementation-slice ID, parent epic, primary subsystem owner, risk dimensions, expected and actual non-documentation source/test file count, expected and actual code/test line delta, cross-layer seams, and any owner-approved deviation. A conceptual epic is not a valid pull-request task.

### Automated commands run

List each exact command and result, grouped as Codex Cloud/Linux and owner-run Windows. Do not merge the categories or infer one from the other.

### Focused assertions covered

Name the important invariants or regression tests added.

### Manual flow

List the player or developer steps actually performed.

### Not verified

State environment, asset, platform, or timing checks that were not performed.

### Known failures

Include pre-existing and new failures separately. A new failing required test blocks completion.

## 17. Commercial-release persistence gate

Before a public Steam release, execute `RG01` from `MILESTONES.md` and the release gate defined in `DEC-0022`:

- profile worst-case JSON save size, parse time, write time, memory use, and cloud transfer behavior;
- validate the selected Steam trusted-time binding and its unavailable/reconnect behavior;
- test Steam Cloud conflicts and multi-machine synchronization separately from local save validity;
- decide whether JSON, compressed JSON, or a binary codec meets measured budgets;
- document whether the product promises corruption resilience, casual-edit deterrence, or server-backed protection for selected outcomes;
- never report client-only encryption, obfuscation, or local HMAC as absolute tamper prevention.

M17 may record representative prototype baselines, but the shipping codec, Steam Cloud conflict policy, and final threat model remain RG01 work.

## 18. Definition of validated

An implementation slice is validated only when:

- all acceptance criteria have an automated or manual verification method;
- applicable automated tests pass;
- the main scene has no new parser or resource errors;
- save/load is exercised when authoritative state changes;
- deterministic equivalence is tested when simulation changes;
- long-horizon discrete output progress survives reconfiguration when a milestone introduces or changes such a channel;
- trusted-time accounting, unavailable behavior, and duplicate-prevention are tested when offline resolution changes;
- exactly-once behavior is tested when progression changes;
- the exact manual demonstration path is recorded;
- limitations are disclosed rather than inferred away;
- actual scope remains within the approved slice assessment, or implementation stopped until a revised owner-approved prompt existed.

A conceptual epic is complete only when every required implementation slice is merged and passed; an epic-level summary does not substitute for slice evidence.

## 19. Owner verification packages and generated logs

Owner-run merge gates follow [OWNER_VERIFICATION_WORKFLOW.md](OWNER_VERIFICATION_WORKFLOW.md) and `DEC-0025`.

For each milestone, the approved prompt must select one of these packages:

1. canonical Windows GUT wrapper only;
2. milestone-specific PowerShell script under `tools/test/owner/`;
3. milestone-specific PowerShell script plus interactive checklist under `docs/codex/owner-checklists/`; or
4. a direct `.md` or `.txt` command/checklist file when automation is unsafe or adds no practical value.

A milestone-specific script normally writes a UTF-8 log under:

```text
tools/test/owner/logs/
```

The generated log records the requested PR head or commit, detected commit when Git is available, Windows and PowerShell versions, Godot executable and version, commands, exit codes, cleanup, pending interactive checks, and final result. Git CLI is optional; scripts accept a `-CommitSha` parameter when exact owner evidence is required.

Scripts must return nonzero on automated failure, verify cleanup of any temporary fixtures, and rerun the clean regression suite after intentional-failure or corruption checks. Logs are uploaded or quoted as validation evidence and are never committed. Visual, editor, audio, A/B, functional, and live Steam observations remain explicit owner results and cannot be inferred from the script log.



### 19.1 Lettered implementation-slice evidence

Under `DEC-0033`, every lettered slice has its own evidence boundary.

- Use the slice ID in script, checklist, trace, fixture, and log names where practical, for example `run_m04a_owner_verification.ps1` and `M04A-owner-verification-<UTC>-<sha>.log`.
- The generated log identifies the slice ID and parent conceptual epic.
- Run the focused tests for the slice and the full regression suite. A later slice's full suite preserves prior regressions but does not replace the earlier slice's missing focused evidence.
- A trace or demonstration proves only the slice's outcome. Do not build one full-epic harness that obscures which slice failed.
- A slice that changes authoritative state must include exact state validation, cloning where applicable, save-schema/reset handling, fixtures, and round-trip evidence in that slice.
- A slice that changes deterministic resolution must include repeatability, equivalent-chunk, boundary, and zero-progress-loop checks appropriate to its scope.
- A slice that introduces exactly-once progression must include duplicate/reload evidence in that slice.
- A slice that changes presentation, editor-authored Resources, audio, live Steam behavior, or gameplay observation requires the matching explicit owner checklist.
- A slice with no visual, editor, or platform-specific behavior may use an automated owner log only and state why no interactive checklist is required.
- A later slice may reuse a prior PowerShell helper, but the top-level entry point and summary remain slice-specific.
- Owner logs from earlier slices remain valid local evidence and must not be deleted merely to run a later script; they remain ignored and untracked.

Every slice log ends with:

```text
Automated result: PASS|FAIL
Failed step count:
Pending interactive checks:
Cleanup result: PASS|FAIL
Log path:
```

## M01 validation commands

M01 adds a focused deterministic numeric/time foundation suite and trace.

Codex/Linux focused suite:

```sh
./tools/test/run_gut.sh -- -gtest=res://tests/unit/m01/test_fixed_point.gd -gtest=res://tests/unit/m01/test_time_authority.gd -gtest=res://tests/unit/m01/test_source_ownership.gd
```

Deterministic trace:

```sh
godot --headless --path . -s res://tools/test/m01/m01_deterministic_trace.gd
```

Owner Windows verification:

```powershell
./tools/test/owner/run_m01_owner_verification.ps1 -CommitSha <PR_HEAD_SHA>
```

The owner script logs the requested `-CommitSha`, compares it with the detected checkout only when Git CLI is available, continues with GitHub Desktop checkouts when Git CLI is unavailable, runs the full suite, focused M01 suite, source-ownership check, explicit trace import preflight, and trace, then writes a generated UTF-8 log under `tools/test/owner/logs/`. Logs remain ignored and are not committed.

## M01 completion record

M01 merged through PR #5 at merge commit `a5b231682967e4cb71b4404af158e93ff8bbf261` from final head `e2b291e75dab5e3484da7dec1d4420a2fb9637be`.

The owner log recorded:

- Godot `4.7.stable.official.5b4e0cb0f`;
- full Windows suite: `12/12` tests, `109` assertions, exit `0`;
- focused M01 suite: `10/10` tests, `103` assertions, exit `0`;
- deterministic-trace import preflight: pass;
- trusted-time trace: zero first-anchor credit, ten foreground minutes, fifty uncredited minutes from a one-hour trusted gap, zero repeat credit;
- fixed-point trace: `250_000` subunits after six hours toward a twenty-four-hour item, one whole item and zero residual after twenty-four hours;
- failed step count `0`, cleanup `PASS`, and no interactive checks required.

`GATE-FIXED-POINT` is satisfied.

## M02 validation package

M02 must add a focused persistence suite, a headless storage trace, and one owner-run Windows entry point:

```text
tools/test/owner/run_m02_owner_verification.ps1
```

The script follows `OWNER_VERIFICATION_WORKFLOW.md`, keeps Git CLI optional, accepts `-CommitSha`, writes its log under `tools/test/owner/logs/`, and uses an isolated disposable directory rather than the owner's normal `user://` save location.

Required automated owner steps:

1. run the full Windows GUT suite;
2. run the focused M02 codec, schema, migration, storage, and transaction tests;
3. run a headless M02 persistence trace in an isolated Windows temporary directory;
4. write revision 1 and revision 2 through the real file-storage path;
5. corrupt the primary deliberately and prove the valid backup is selected while the corrupt primary bytes remain available for diagnosis;
6. exercise the documented Windows rename/replacement sequence and verify at least one valid committed snapshot at every tested failure boundary;
7. verify unsupported codec/future schema candidates do not overwrite valid files;
8. delete the entire isolated test directory and verify cleanup;
9. rerun the clean full suite after the corruption/recovery trace;
10. finish with automated result `PASS`, failed step count `0`, cleanup `PASS`, and no pending interactive checks.

No visual/editor checklist is required for M02 because the milestone introduces no player-facing save UI. Windows filesystem behavior remains an owner merge gate.



## M02 completion record

M02 merged through PR #6 at merge commit `480a9eae2fe0c3591503da56b07c272be74ec027` from final head `0dd0c1d5c799db45aa4a8387d93750e02b2e485f`.

Linux/Codex evidence recorded:

- focused persistence suite: `17/17` tests, exit `0`;
- full regression suite: `29/29` tests, exit `0`;
- real-file trace: revision 1, revision 2, backup rotation, corrupt-primary rejection, backup selection, and corrupt-byte retention passed;
- source-ownership and `git diff --check` passed.

The owner Windows log recorded:

- Godot `4.7.stable.official.5b4e0cb0f`;
- full suite before and after trace: `29/29` tests and `253` assertions each;
- focused M02 suite: `17/17` tests and `144` assertions;
- import preflight: pass;
- real-file trace: both revisions written, revision-1 backup present, primary corrupted, backup selected, stable diagnostic emitted, corrupt bytes retained;
- isolated test directory removed and verified absent;
- automated result `PASS`, failed step count `0`, cleanup `PASS`, and no interactive checks.

`GATE-SAVE-SCHEMA` is satisfied.

## M03 approved validation package

M03 must add content-focused tests, one deterministic headless trace, one owner-run Windows entry point, and one Inspector checklist.

Focused Linux/Codex command:

```bash
./tools/test/run_gut.sh -- \
  -gdir=res://tests/unit/content \
  -gdir=res://tests/integration/content
```

Headless trace after explicit import:

```bash
godot --headless --path . --import
godot --headless --path . -s res://tools/test/m03/m03_content_catalog_trace.gd
```

The trace must print:

- current content revision and exact compatibility list;
- per-group counts and deterministic canonical ID order;
- representative normalized fixed-point values;
- the eight-hour Scribe Form Soul and twenty-four-hour Man-at-Arms Form Soul channel periods;
- one invalid duplicate-ID diagnostic;
- one provisional override whose normalized value changes without code modification;
- a fixture rename of Unclosed Ledger and a Recollection that preserves their canonical IDs/modifiers;
- a `TERM_THRESHOLD` override that changes shared display text while `THR_...` identities remain unchanged;
- `RES_ESSENCE`, `CHANNEL_GLOAMWOOD_ESSENCE`, and `CHANNEL_BROKEN_WATCH_ESSENCE`, with deprecated IDs rejected;
- acceptance of `prototype-m02` and rejection of an unknown save revision.

Owner Windows automation must be packaged as:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
    -File .\tools\test\owner\run_m03_owner_verification.ps1 `
    -CommitSha "<PR_HEAD_SHA>"
```

The script follows `OWNER_VERIFICATION_WORKFLOW.md`, keeps Git CLI optional, captures complete output in one UTF-8 log, runs full suite before, focused M03 suite, explicit import, trace, and full suite after, and finishes with failed step count `0`, cleanup `PASS`, and the Inspector checklist pending until the owner reports it.

Interactive Inspector verification must be supplied at:

```text
docs/codex/owner-checklists/M03-owner-verification.md
```

The checklist must cover:

1. `content/prototype_content_catalog.tres` revision, compatibility list, and explicit group references;
2. Man-at-Arms and Scribe typed fields, stable inline Trait IDs, editable Trait labels, optional localization keys, and modifiers;
3. Gloamwood, Broken Watch, and representative `CHANNEL_...` definitions, including explicit periods and progress-display flags;
4. Soldier Company requirement/support fields;
5. Archive, Larder, and the Provisions-to-Rations recipe;
6. representative Recollection, milestone, guarantee, resonance, tutorial, and narrative identity Resources with editable names independent of IDs;
7. the core terminology Resource, including `TERM_THRESHOLD`, `TERM_RECOLLECTION`, and `TERM_ESSENCE`;
8. a production or fixture override showing an exported provisional value can differ without editing GDScript;
9. no import/parser errors and no arbitrary script callback/expression fields in authored content.

M03 merge requires both the owner script log and explicit checklist result.

## M03 completion record

M03 merged through PR #7 on 2026-07-15 at merge commit `5e2b9b23878c9280f75b987cc9ad567d8980030d` from final head `971cdaa0fd46f641ec7409148e259d54f953d8c7`.

Linux/Codex and owner evidence established:

- the typed production catalog contains the exact sixty approved definitions and twenty terminology entries;
- full Windows suite before and after the trace: `42/42` tests and `496` assertions each;
- focused M03 suite: `13/13` tests and `243` assertions;
- explicit import, semantic catalog trace, and artifact audit passed;
- Gloamwood/Broken Watch values, discovery metadata, modifier operands, milestone/guarantee mappings, derived guarantee previews, resonance effects, terminology, rename isolation, and content compatibility passed the trace;
- the Godot Inspector checklist passed with no parser, import, or Resource errors;
- automated result `PASS`, failed step count `0`, cleanup `PASS`.

`GATE-CONTENT-CATALOG` is satisfied.

## 20. Rolling-wave slice validation and scope evidence

The post-M03 implementation sequence uses conceptual epics and lettered slices under `DEC-0033`.

Before a slice prompt is approved, its validation plan must state:

1. the slice ID and parent epic;
2. focused test directories/files;
3. the trace or demonstration entry point;
4. whether authoritative state or save compatibility changes;
5. whether deterministic chunking, exactly-once, editor, visual, Windows, or live-platform checks apply;
6. the owner package and exact invocation;
7. the expected review surface and any approved exception.

Before merge, the pull-request handoff and owner evidence must state:

- actual source/test files changed;
- actual code/test line delta, excluding `.uid` files and repetitive authored data;
- whether another subsystem owner or risk dimension appeared;
- whether implementation remained within the approved assessment;
- every focused/full command and exit code;
- every pending interactive check;
- cleanup and final PASS/FAIL.

M04A through M04E receive separate focused suites, traces, and owner logs. No unsplit M04 verification package is valid.

## 21. M04A schema-version-2 validation package

M04A introduces the first production schema migration and the first typed gameplay-state subset. Its verification boundary is separate from M04B dispatch and M04C simulation.

### 21.1 Focused Linux/Codex checks

The realized prompt may adjust exact filenames while preserving this scope. The expected focused command is:

```bash
./tools/test/run_gut.sh -- \
  -gdir=res://tests/unit/m04a \
  -gdir=res://tests/integration/m04a
```

Also run:

```bash
godot --headless --path . --import
godot --headless --path . -s res://tools/test/m04a/m04a_state_persistence_trace.gd
./tools/test/run_gut.sh
git diff --check
```

Required focused groups:

1. typed gameplay-state construction and validation;
2. deep-clone isolation at every nested collection;
3. version-1 historical validator and immutable fixture;
4. version-2 exact key/type/integer-string validator;
5. current runtime mapper round trip;
6. production `v1 -> v2` pure migration;
7. content/domain compatibility before persisted upgrade;
8. transactional migration persistence and failure injection;
9. already-current no-rewrite behavior;
10. unknown future-schema rejection.

### 21.2 Required migration trace

`tools/test/m04a/m04a_state_persistence_trace.gd` must use a caller-supplied disposable save root and demonstrate:

1. construct and validate the representative M04A Gloamwood/Man-at-Arms state;
2. clone it, mutate nested state, and prove the baseline is unchanged;
3. save/load schema version 2 exactly;
4. create a canonical schema-version-1 primary;
5. load it as a working candidate;
6. preserve its simulation/time-authority/content fields;
7. add only canonical empty gameplay state;
8. persist schema version 2 with save revision incremented once;
9. retain the version-1 source as a recoverable backup under the ordinary M02 transaction;
10. reload the version-2 primary without another rewrite;
11. report stable PASS markers and exit zero.

Failure-injection tests may remain in memory/injected storage; the owner trace does not deliberately damage the normal user save directory.

### 21.3 Owner Windows package

Codex must create:

```text
tools/test/owner/run_m04a_owner_verification.ps1
```

Expected invocation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
    -File .\tools\test\owner\run_m04a_owner_verification.ps1 `
    -CommitSha "<PR_HEAD_SHA>"
```

The script is Windows PowerShell 5.1 compatible, resolves the repository and Godot console executable through the canonical contract, keeps Git CLI optional, and writes:

```text
tools/test/owner/logs/M04A-owner-verification-<UTC>-<sha>.log
```

Required order:

1. Godot 4.7 validation;
2. full GUT suite before;
3. focused M04A suite;
4. explicit import;
5. real-file M04A state/migration trace in a unique Windows temporary directory;
6. verification that the version-1 source or backup and the upgraded version-2 primary have the expected roles/revisions;
7. cleanup and proof that the isolated directory is absent;
8. full clean GUT suite after;
9. artifact audit that tolerates prior ignored owner logs;
10. standardized summary.

Expected summary:

```text
Automated result: PASS
Failed step count: 0
Pending interactive checks: None for M04A
Cleanup result: PASS
Log path: <generated path>
```

No Inspector, visual, audio, gameplay, or Steam checklist is required for M04A.

### 21.4 Merge evidence

M04A cannot merge until:

- Linux/Codex focused, trace, and full regression pass;
- the owner Windows log passes against the exact PR head;
- schema version 1 fixture and validator remain present;
- schema version 2 is current and new saves write it;
- migration failure preserves the original candidate;
- the actual review surface remains within the approved prompt assessment or received an owner-approved revision.

## M04A realized correction and completion record

M04A's final implementation and evidence supersede the planning-only wording above where counts or trace markers differ.

### Realized focused command

```bash
./tools/test/run_gut.sh -- \
  -gdir=res://tests/unit/m04a \
  -gdir=res://tests/integration/m04a
```

Tracked compatibility fixtures:

```text
tests/fixtures/saves/schema_v1_foundation.json
tests/fixtures/saves/schema_v2_m04a_representative.json
```

Realized trace markers:

```text
TRACE M04A typed_state_and_clone=PASS
TRACE M04A v2_round_trip=PASS
TRACE M04A v1_upgrade_preserved_authority=PASS
TRACE M04A file_primary_schema=2_save_revision=13
TRACE M04A file_backup_schema=1_save_revision=12
TRACE M04A no_repeat_rewrite=PASS
```

Completion evidence:

- PR #8 final head: `04b12d8ba2edeecbf13f252216249341469b40a8`.
- Merge commit: `673ad884357fc742a0a26dbb542d5b8d9fe557c9`.
- Full owner Windows suite before and after: `59/59` tests, `722` assertions, exit `0`.
- Focused M04A owner Windows suite: `16/16` tests, `207` assertions, exit `0`.
- Explicit import: pass.
- All six trace markers: pass.
- Cleanup and proof of isolated-directory absence: pass.
- Artifact audit with prior ignored logs present: pass.
- Failed step count: `0`.
- Pending interactive checks: none.
- Final review surface: 28 changed files, 1,352 additions, 61 deletions; within the approved guardrails.

`GATE-GAMEPLAY-SCHEMA` is satisfied.

## 22. M04B approved assignment validation package

M04B is a command/assignment slice. It must not test production by waiting or advancing elapsed time.

### 22.1 Focused Linux/Codex checks

Expected focused command:

```bash
./tools/test/run_gut.sh -- \
  -gdir=res://tests/unit/m04b \
  -gdir=res://tests/integration/m04b
```

Also run:

```bash
godot --headless --path . --import

trace_root="$(mktemp -d)"
godot --headless --path . \
  -s res://tools/test/m04b/m04b_assignment_trace.gd \
  -- --save-root "$trace_root"
trace_exit=$?
rm -rf "$trace_root"
test ! -e "$trace_root"
test "$trace_exit" -eq 0

./tools/test/run_gut.sh
git diff --check
```

### 22.2 Required focused groups

1. valid initial dispatch and revision 1;
2. Threshold ID as operation identity with no redundant UUID;
3. canonical loadout tuple equality independent of operation identity;
4. assignment-state identity as Threshold ID plus revision;
5. activation episode identity from dispatch/redispatch revision;
6. immutable `started_simulation_msec`, including valid zero;
7. record existence as initialization rather than a timestamp sentinel;
8. available Threshold, awakened Form, enabled Writ, and tether-capacity validation;
9. one active Reaping per Threshold;
10. one Form leading at most one active Reaping;
11. exact expected-revision handling;
12. duplicate, stale, already-active, and already-inactive rejection;
13. checked assignment-revision overflow;
14. recall retaining the stable inactive record and freeing the derived tether;
15. same-configuration redispatch preserving frozen phase/carry;
16. changed configuration with nonzero rate-dependent state returning `REAPING_RESOLUTION_REQUIRED`;
17. same Threshold/same loadout creates a new episode without a new operation;
18. same loadout/different Threshold uses an independent operation and revision sequence;
19. different loadout/same Threshold retains the operation and first-start timestamp;
20. returning to an earlier loadout creates a new episode and does not restore old state/rates;
21. exact configuration timestamps at externally established simulation cursors;
22. typed result, event, change-summary, operation ID, assignment-state ID, and save-checkpoint contract;
23. state equality after every failed command;
24. active and inactive schema-v2 round trips;
25. malformed assignment-state rejection;
26. no clock, Steam, file-time, simulation, report, tutorial, UI, or new identity field ownership.

### 22.3 Assignment trace

`tools/test/m04b/m04b_assignment_trace.gd` must use a supplied disposable save root and demonstrate a scenario sequence equivalent to:

```text
Gloamwood + loadout 1
→ recall
→ Gloamwood + loadout 3
→ recall
→ Broken Watch + loadout 3
→ recall
→ Gloamwood + loadout 1
```

The trace must:

1. construct available Gloamwood/Broken Watch, awakened Man-at-Arms/Scribe, and one tether;
2. establish known committed simulation cursors between commands without letting the assignment service advance time;
3. dispatch loadout 1 to Gloamwood at revision 1 and capture the immutable first-start timestamp;
4. reject duplicate and stale commands with exact no-mutation comparison;
5. save/load the active Gloamwood assignment;
6. recall to revision 2 and prove tether release plus full state preservation;
7. redispatch a different zero-carry loadout to Gloamwood at revision 3 while preserving the same operation and first-start timestamp;
8. recall Gloamwood to revision 4;
9. dispatch the same loadout value to Broken Watch at its independent revision 1 and first-start timestamp;
10. prove timestamps may coincide without identity collision;
11. recall Broken Watch to revision 2;
12. return loadout 1 to Gloamwood at revision 5;
13. prove the final loadout equals the original value but is a new activation episode, not revision/episode 1;
14. prove Threshold-owned Gloamwood progress never moved to Broken Watch;
15. prove `started_simulation_msec` for each operation never changed;
16. save/load representative active and inactive records;
17. exit nonzero on any mismatch.

Required markers:

```text
TRACE M04B operation_identity=THR_GLOAMWOOD
TRACE M04B dispatch_revision=1_tethers=1
TRACE M04B duplicate_and_stale_rejected=PASS
TRACE M04B active_round_trip=PASS
TRACE M04B recall_revision=2_tethers=0
TRACE M04B different_loadout_same_threshold_same_operation=PASS
TRACE M04B same_loadout_different_threshold_separate_operation=PASS
TRACE M04B return_to_prior_loadout_new_episode=PASS
TRACE M04B started_simulation_msec_immutable=PASS
TRACE M04B zero_start_is_valid=PASS
TRACE M04B preserved_threshold_and_operation_state=PASS
TRACE M04B inactive_round_trip=PASS
TRACE M04B simulation_time_unchanged=PASS
```

### 22.4 Owner Windows package

The M04B prompt requires:

```text
tools/test/owner/run_m04b_owner_verification.ps1
```

Expected invocation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
    -File .\tools\test\owner\run_m04b_owner_verification.ps1 `
    -CommitSha "<PR_HEAD_SHA>"
```

The script follows the corrected M04A workflow:

- Windows PowerShell 5.1 compatible;
- repository root resolved from the script;
- `-GodotBin`, `GODOT_BIN`, then `PATH`;
- Git CLI optional with visual GitHub Desktop confirmation when unavailable;
- one UTF-8 log using the PR head;
- complete output and exit codes;
- full suite before;
- focused M04B suite;
- explicit import;
- assignment trace and marker verification using a stable captured trace buffer;
- guaranteed cleanup in `finally`;
- prior ignored log tolerance;
- artifact audit;
- full suite after;
- standardized summary.

Expected summary:

```text
Automated result: PASS
Failed step count: 0
Pending interactive checks: None for M04B
Cleanup result: PASS
Log path: <generated path>
```

No Inspector, visual, audio, gameplay, A/B, or Steam checklist is required because M04B has no player-facing presentation.

### 22.5 M04B merge evidence

M04B cannot merge until:

- accepted `DEC-0035` remains the implemented assignment/identity contract;
- Linux/Codex focused/import/trace/full checks pass;
- the owner Windows package passes against the exact PR head;
- schema version remains 2 and no undocumented migration is added;
- every failed command proves no mutation;
- active/inactive assignment round trips pass;
- no elapsed production or later-slice behavior enters the diff;
- actual review surface remains within the approved prompt assessment or receives an approved revision.

## M04B completion record

M04B merged through PR #9 on 2026-07-17 at merge commit `c641d74cebedf07c51ebb579cccee21db7aa2410` from final head `5301c94bfd0fb837f9961fda624d7559042327e2`.

Final evidence:

- full Windows suite before and after: `75/75` tests and `1,083` assertions;
- focused M04B suite: `16/16` tests and `356` assertions;
- explicit import: pass;
- complete Threshold/loadout/assignment/episode identity trace: pass;
- all 13 approved trace markers: pass;
- global load rejection for malformed assignment state: pass;
- cleanup, cleanup proof, and artifact audit: pass;
- failed step count `0`;
- pending interactive checks: none;
- final review surface: 13 changed files, 1,092 additions, 10 deletions.

`GATE-REAPING-ASSIGNMENT` is satisfied.

## 23. M04C approved core-resolver validation package

M04C validates deterministic core production only. No test may depend on elapsed wall time, rendered frames, Steam, or UI.

Current PR #12 focused evidence covers duration and transaction failures, supported and unsupported modifier/rate plans, Essence-channel validation, Settlement/chunking fixtures, overflow and fixed-point helper failures, source ownership, and persistence invariants. The corrected focused suite currently reports 19 focused tests and 253 assertions; the full repository suite currently reports 94 tests and 1,346 assertions in Codex/Linux evidence.

### 23.1 Focused Linux/Codex checks

Expected focused command:

```bash
./tools/test/run_gut.sh -- \
  -gdir=res://tests/unit/m04c \
  -gdir=res://tests/integration/m04c
```

Also run:

```bash
godot --headless --path . --import

trace_root="$(mktemp -d)"
godot --headless --path . \
  -s res://tools/test/m04c/m04c_core_reaping_trace.gd \
  -- --save-root "$trace_root"
trace_exit=$?
rm -rf "$trace_root"
test ! -e "$trace_root"
test "$trace_exit" -eq 0

./tools/test/run_gut.sh
git diff --check
```

### 23.2 Required focused groups

1. production rate-plan derivation from normalized content;
2. Old Drill's Gloamwood tag-conditioned returned-soul multiplier;
3. Essence-channel lookup and no double Settled multiplier;
4. Mastery and cycle independence from lifecycle;
5. central checked multiplier and boundary helper arithmetic;
6. exact 60-second Overdue fixture;
7. one-shot versus regular and irregular chunking;
8. no-active timeline advancement;
9. inactive operation no production;
10. more-than-one-active rejection with no mutation;
11. Retinue and unknown-nonzero-flow rejection;
12. negative duration and zero-duration no-op;
13. exact `869 ms` no-settlement and `870 ms` settlement boundary;
14. ten-second one-backlog fixture values;
15. `869 + 1 + 9,130` equivalence;
16. Settlement event time, priority, subject, payload, and exactly-once behavior;
17. already-Settled continuation;
18. returned/Essence whole extraction and normalized residual ranges;
19. Mastery carry and cycle phase/count;
20. inventory, return-counter, Mastery, cycle, residual, and simulation-time overflow;
21. zero-duration-boundary/transition guard;
22. complete state equality after every failure;
23. schema-v2 Overdue/Settled round trips;
24. no clock, scene, frame, Steam, file-time, report, forecast, or UI source ownership.

### 23.3 Hand-calculable fixtures

#### Sixty seconds, Overdue Gloamwood, Man-at-Arms

Expected:

```text
returned souls = 69
Essence whole units = 6
Mastery delta subunits = 1000000
completed cycles = 1
cycle phase msec = 0
```

#### Ten seconds starting from one remaining backlog

Expected:

```text
Settlement boundary = 870 ms
persistent returns = 3
remaining backlog = 0
lifecycle = SETTLED
returned progress remainder = 625375
returned rate carry = 0
Essence whole units = 0
Essence progress remainder = 315250
Essence rate carry = 0
Mastery delta subunits = 166666
Mastery rate carry = 40000
cycle phase msec = 10000
Settlement events = 1
```

### 23.4 M04C trace markers

Negative trace invocations with a missing, blank, or `user://` save root must exit nonzero. The trace uses the supplied disposable root for production file-backed persistence and prints a PASS marker only after checking the corresponding condition.

Focused paths are `res://tests/unit/m04c` and `res://tests/integration/m04c`; Windows owner rerun remains pending until the corrected package passes against the PR head.


Required exact markers:

```text
TRACE M04C overdue_60s_returns=69_essence=6_mastery=1000000_cycles=1
TRACE M04C one_shot_equals_chunks=PASS
TRACE M04C settlement_boundary_msec=870
TRACE M04C settlement_end_returns=3_backlog=0_lifecycle=SETTLED
TRACE M04C settlement_event_once=PASS
TRACE M04C settled_mastery_and_cycle_continue=PASS
TRACE M04C core_residuals_return=625375_essence=315250_mastery_carry=40000
TRACE M04C inactive_produces_nothing=PASS
TRACE M04C idle_timeline_advances=PASS
TRACE M04C save_round_trip=PASS
TRACE M04C no_clock_sources=PASS
```

The trace requires an explicit disposable `--save-root`, exits nonzero when it is missing, and writes nothing to ordinary `user://` state.

### 23.5 Owner Windows package

The M04C prompt requires:

```text
tools/test/owner/run_m04c_owner_verification.ps1
```

Expected invocation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
    -File .\tools\test\owner\run_m04c_owner_verification.ps1 `
    -CommitSha "<PR_HEAD_SHA>"
```

The script follows the corrected M04B workflow:

- Windows PowerShell 5.1 compatible;
- repository root resolved from the script;
- explicit `-GodotBin`, then `GODOT_BIN`, then `PATH`;
- Git CLI optional with owner checkout confirmation when unavailable;
- one UTF-8 PR-head log;
- full suite before;
- focused M04C suite;
- explicit import;
- isolated trace;
- stable captured trace output and 11-marker verification;
- guaranteed cleanup and proof;
- prior ignored log tolerance and artifact audit;
- full suite after;
- standardized summary.

Expected summary:

```text
Automated result: PASS
Failed step count: 0
Pending interactive checks: None for M04C
Cleanup result: PASS
Log path: <generated path>
```

No Inspector, visual, audio, gameplay, A/B, or Steam checklist is required.

### 23.6 M04C merge evidence

M04C cannot merge until:

- accepted `DEC-0036` remains the implemented core-resolver contract;
- Linux/Codex focused/import/trace/full checks pass;
- the owner Windows package passes against the exact PR head;
- exact one-shot/chunk and Settlement-boundary fixtures pass;
- every failure proves no mutation;
- schema version remains 2;
- no discrete non-Essence channel, Retinue, progression, report, forecast, concurrency, UI, or platform behavior enters the diff;
- actual review surface remains within the approved assessment or receives a revised prompt.
