# Death Idle Testing and Validation

**Document role:** Canonical test strategy, commands, fixture rules, and manual validation flows  
**Repository path:** `docs/codex/TESTING_AND_VALIDATION.md`  
**Document status:** Approved architecture validation plan  
**Validation revision:** 3  
**Last updated:** 2026-07-12  
**Engine target:** Godot 4.7 standard build, GDScript only  
**Architecture companion:** [ARCHITECTURE.md](ARCHITECTURE.md)

## 1. Current status

The repository already contains:

- GUT 9.7.1 under `addons/gut/`;
- GodotSteam GDExtension 4.20 under `addons/godotsteam/`;
- development Steam App ID `480` in `project.godot`;
- disabled automatic Steam initialization.

The repository does **not** yet have the approved automated harness. M00 must create and validate:

- `.gutconfig.json`;
- `tools/test/run_gut.sh`;
- `tools/test/run_gut.ps1`;
- the initial `tests/` structure and passing harness test;
- canonical import, focused-test, full-test, and smoke documentation.

Until M00 merges, do not claim the canonical wrappers or automated suite exist. A Godot change must at minimum be imported and run in Godot 4.7 on the Windows Godot machine, and the exact manual behavior changed by the task must be exercised and reported.

## 2. Pinned test and platform dependencies

### 2.1 GUT 9.7.1

GUT 9.7.1 is the approved GDScript test framework for Godot 4.7.x. It is already committed and is not downloaded by M00 or at test time.

M00 must:

1. verify the committed version from the addon metadata;
2. verify that the applicable GUT license file is retained in the repository;
3. add a checked-in `.gutconfig.json` with repository-relative test directories and deterministic exit behavior;
4. prove command-line execution and nonzero failure propagation in Linux and Windows;
5. avoid the addon updater, floating versions, and runtime network downloads.

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

The owner may set `GODOT_BIN` or `PATH` locally on Windows. That configuration is never committed.

## 4. Canonical commands after M00

### 4.1 Full automated suite

Linux or Codex Cloud:

```text
./tools/test/run_gut.sh
```

Windows PowerShell:

```text
.\tools\test\run_gut.ps1
```

Default full mode must:

1. resolve the repository root from the wrapper location;
2. print and validate Godot 4.7.x;
3. run a headless project import;
4. run the full GUT suite using `.gutconfig.json`;
5. return the real failing or successful process exit code.

A documented iteration option may skip the import or select focused tests, but the final milestone verification uses the default full mode.

### 4.2 Underlying import fallback

If a wrapper itself is being diagnosed, the repository-relative import command is:

```text
godot --headless --path . --import
```

### 4.3 Underlying GUT fallback

The pinned GUT runner is:

```text
godot --headless -d -s --path . addons/gut/gut_cmdln.gd -gexit
```

`.gutconfig.json` supplies test directories and other stable options. Command-line arguments may override it for focused execution.

### 4.4 Focused tests

M00 must document how each wrapper forwards GUT selectors such as:

```text
-gtest=res://tests/unit/path/to/test_file.gd
-gunit_test_name=test_name_fragment
```

Codex may run focused tests while iterating, but it must run the applicable broader suite before marking a task complete.

### 4.5 Main-scene smoke

Until a dedicated smoke wrapper exists, the repository-relative fallback is:

```text
godot --headless --path . --quit-after 5
```

M00 validates the current dry-run scene without redesigning it. M05 may replace this with a dedicated ready-state smoke runner and must update this document in the same pull request.

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

- fixed-point conversion and canonical rounding;
- multiply/divide and residual preservation;
- overflow and invalid negative handling;
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

### 8.10 Support degradation

Resolve through Ration depletion. Assert:

- Soldier Company effect changes to the configured floor;
- base backlog, Essence, and Mastery continue;
- forecast identifies the boundary and post-depletion behavior;
- report records one transition;
- later Ration production can restore support if current prototype policy permits it.

### 8.11 Hidden production and discovery

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

Keep one fixture for every supported historical schema. Test sequential migration to current schema and the resulting runtime invariants.

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
- preserve useful logs as CI or Codex task artifacts when available.

Do not hide failures behind a wrapper that always exits successfully.

## 16. Pull-request verification report

Every Codex pull request reports:

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

A milestone is validated only when:

- all acceptance criteria have an automated or manual verification method;
- applicable automated tests pass;
- the main scene has no new parser or resource errors;
- save/load is exercised when authoritative state changes;
- deterministic equivalence is tested when simulation changes;
- trusted-time accounting, unavailable behavior, and duplicate-prevention are tested when offline resolution changes;
- exactly-once behavior is tested when progression changes;
- the exact manual demonstration path is recorded;
- limitations are disclosed rather than inferred away.
