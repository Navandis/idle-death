# Death Idle - Prototype 0-90 Minute Source of Truth

**Document role:** Maintained implementation contract for the playable first-session prototype  
**Repository path:** `docs/design/PROTOTYPE_0_90_SOURCE_OF_TRUTH.md`  
**Markdown revision:** 6  
**Last updated:** 2026-07-18  
**Primary source:** *Death Idle - Prototype 0-90 Minute Beat Sheet & Implementation Brief v0.1* (12 July 2026)  
**Broader design companion:** [IDLE_FORK_SOURCE_OF_TRUTH.md](IDLE_FORK_SOURCE_OF_TRUTH.md)

## 1. Purpose and authority

This document converts the first-session Beat Sheet into state, content, presentation, guarantee, save, fallback, and acceptance requirements that Codex can use during implementation.

It is not a final script, final balance sheet, or instruction to implement the entire prototype in one task. Later milestones should reference the requirement labels in this file and implement only their approved slice.

Follow the source precedence in the root `AGENTS.md`. For the 0–90 minute prototype, this file is the normal operational design source. The broader idle-fork document applies where this file does not specify prototype behavior.

### Status vocabulary

| Status | Meaning for the prototype |
|---|---|
| **Required** | Must be present or demonstrably supported by the prototype. |
| **Prototype scaffold** | Must be represented, but exact numbers or presentation remain configurable. |
| **Optional** | Useful if inexpensive, but not required for prototype completion. |
| **Deferred** | Do not implement in the current prototype. |
| **Open** | Requires a later decision; do not invent a permanent rule. |

Requirement labels such as `P90-B04`, `P90-G02`, and `P90-AC05` are traceability references for milestone definitions, tests, and pull-request acceptance criteria. They are not runtime content IDs.

Revision 2 incorporates the approved counter rule: the four scripted opening returns are excluded from all persistent-Reaping Threshold and regional milestone counters.

Revision 4 adopts **Essence** as the sole resource term (`RES_ESSENCE`) and records that player-facing names remain editable content while canonical IDs remain stable.

## 2. Prototype thesis and required end state

The prototype must prove the first-hour product promise:

> Death identifies an impossible backlog, delegates persistent Reapings, restores systems through Essence, differentiates two Forms, fields a reserved-soul Retinue, opens a second Threshold, establishes a simple Hall supply chain, and sees that the same machinery will continue while the game is closed.

The prototype is not intended to prove the launch economy, the full Form roster, final balance, or final presentation.

### Required end state

| Area | Required state after approximately 75–90 minutes |
|---|---|
| Forms | Man-at-Arms and Scribe are awakened and gaining Mastery. |
| Thresholds | Gloamwood Hamlet and Broken Watch are both active. |
| Capacity | Two command tethers are available and occupied. |
| Retinue | Soldier Company is fielded using twelve reserved Soldier Souls. |
| Halls | Archive is restored; Larder is converting Provisions into Rations. |
| Recollections | The Weave Remembered and The Muster Remembered are purchased; one optional early Recollection is purchased. |
| Progress | Backlogs are visibly moving; a clear next objective is shown. |
| Resonances | The minor 5,000-Gloamwood resonance and the separate 10,000-regional resonance have occurred exactly once. |
| Idle proof | An eight-hour forecast is viewable and uses the same rules as actual offline resolution. |
| Persistence | Save/load preserves the full functional sequence and does not duplicate any reward or event. |
| Tutorial | Mandatory guidance is complete; optional objective hints may remain. |

The two-resonance wording above reflects the approved owner clarification and supersedes source shorthand that summarized the end state as “one seal resonance.”

## 3. Global prototype safeguards

Every milestone must preserve the [architecture-level idle-fork invariants](IDLE_FORK_SOURCE_OF_TRUTH.md#6-architecture-level-design-invariants). The following prototype-specific safeguards are additionally mandatory:

| ID | Requirement |
|---|---|
| `P90-SAFE-01` | First player input occurs within roughly 15–30 seconds during a normal first-time playthrough. |
| `P90-SAFE-02` | Gloamwood visibly changes from `1,000,000` to `999,996` within roughly two to three minutes. |
| `P90-SAFE-03` | The first automated Reaping normally begins within seven minutes. |
| `P90-SAFE-04` | `Reach Through the Threshold` is a one-time scripted action and is removed permanently after the four-soul result. It must not establish a repeatable clicker loop. |
| `P90-SAFE-05` | Only one blocking tutorial or dialogue lesson is active at once. Later notices queue or reconstruct from state. |
| `P90-SAFE-06` | Production and milestone progress continue while dialogue, reports, menus, Soulweave, Hall, or tutorial UI is open. |
| `P90-SAFE-07` | Soldier Souls, Scribe Form Soul access, and the first Provisions chain cannot fail because of random output. |
| `P90-SAFE-08` | Mandatory costs are secured through reservation, temporary purchase restrictions, discounts, or additive top-ups. The player cannot spend into a tutorial softlock. |
| `P90-SAFE-09` | Any valid two-Reaping Form arrangement is accepted. The recommended Scribe placement accelerates discovery but is not required to avoid a softlock. |
| `P90-SAFE-10` | Ration depletion weakens the Soldier Company or premium effects but never stops base backlog, Essence, or Mastery production. |
| `P90-SAFE-11` | Reports are informational. All gains shown in a report were already applied to authoritative state. |
| `P90-SAFE-12` | All one-time grants, unlocks, resonance events, and tutorial transitions are save-safe and idempotent. |
| `P90-SAFE-13` | The scripted opening four reduce Gloamwood backlog and are recorded separately, but never increment persistent-Reaping Threshold or regional counters and never advance later Reaping milestones. |
| `P90-SAFE-14` | Authoritative closed-session progress never uses the player's local wall clock, timezone, calendar, file timestamps, or manually supplied time. It is credited only from an approved external trusted-time provider; when trust is unavailable, the unresolved interval remains pending while foreground production continues from a monotonic process clock. |

## 4. Pacing and guidance phases

Pacing values are playtest targets, not hard-coded timers. Progression remains state-driven.

| Phase | Target duration | Purpose |
|---|---|---|
| Mandatory tutorial | Approximately 8–12 minutes | Teach Threshold, backlog, Form, Reaping, Essence, and continuous operation. |
| Guided onboarding | Until approximately 30–40 minutes | Introduce Soulweave, Soldier Company, Scribe, and the second command tether. |
| Player-led first session | Until approximately 60–90 minutes | Operate two Reapings, discover Provisions, restore Larder, choose a Recollection, and inspect an offline forecast. |

### Timeline overview

| Requirement | Target time | Beat | Primary lesson |
|---|---:|---|---|
| `P90-B01` | 0:00–1:30 | Death Wakes | Character, mystery, dialogue interaction. |
| `P90-B02` | 1:30–3:00 | One Million Souls Overdue | Threshold, backlog, direct progress, weakened Death. |
| `P90-B03` | 3:00–6:00 | Four Returns and the Seals | Eustace, the lost millennia, chains, Brand, first Form. |
| `P90-B04` | 6:00–10:00 | Dispatch the First Reaping | Form assignment, Emergency Writ, cycle, automatic production. |
| `P90-B05` | 10:00–18:00 | Archive and Soulweave | Essence spending, Recollections, long-term Form horizon. |
| `P90-B06` | 18:00–26:00 | First Report and Soldier Company | Auto-banked report, Calling Soul reservation, Retinue forecast. |
| `P90-B07` | 26:00–34:00 | The Scribe Form | Form Souls, player-driven awakening, qualitative Form identity. |
| `P90-B08` | 34:00–45:00 | The Second Thread | Minor resonance, second tether, comparison, concurrent Reapings. |
| `P90-B09` | 45:00–52:00 | Scribe Proves Its Value | Discovery and forecast confidence. |
| `P90-B10` | 52:00–63:00 | The First Supply Chain | Provisions → Larder → Rations → support. |
| `P90-B11` | 63:00–75:00 | Second Resonance and First Choice | Incremental payoff and optional Recollection. |
| `P90-B12` | 75:00–90:00 | The Machinery Continues | Player-led operation, reports, objectives, offline forecast. |

## 5. Detailed beat contracts

### `P90-B01` — Death Wakes

**Entry state**

- A new game has been created.
- Tutorial state is `TUT_00_BOOT`.
- No global HUD or production system is exposed.

**Player actions**

- Advance short lines of dialogue.
- Focus or select the faint light beyond the chamber.

**Visible presentation**

- Screen begins mostly black.
- Death appears through the lower-third dialogue presentation.
- Each advance reveals more of the Sanctum and distant window.
- Dialogue supports advance, auto, skip, text speed, and a voice toggle even if final voice assets are absent.

**Authoritative state transition**

- `TUT_00_BOOT` → `TUT_01_WINDOW`.
- Sanctum and window become available in world state.

**Fail-safe**

- Skipping the monologue applies the same scene-state changes and opens the window.
- Skip cannot leave the player in a black screen or omit the next interaction.

**Required save checkpoint**

- Save after the window/Sanctum state is committed.

**Remain hidden**

- Global resources, Threshold configuration, Retinues, Recollections, Soulweave, Halls, and forecasts.

**Exit condition**

- The player focuses the window and Gloamwood can be revealed.

---

### `P90-B02` — One Million Souls Overdue

**Entry state**

- `TUT_01_WINDOW` is active.
- Gloamwood is presented as a Standing Threshold with `1,000,000` Souls Overdue.

**Player action**

- Press the one-time command **Reach Through the Threshold**.

**Visible presentation**

- Gloamwood name, Standing Threshold classification, and backlog are visible.
- Other fields remain hidden or unknown.
- The backlog decrement is central, audible, and clearly animated.
- Do not show an absurdly long numeric settlement estimate before automation is introduced; a placeholder such as “Beyond present calculation” is acceptable.

**Authoritative state transition**

- `TUT_01_WINDOW` → `TUT_02_DIRECT_REAP`.
- Exactly four souls are returned.
- Gloamwood backlog changes from `1,000,000` to `999,996`.
- The four are recorded in a separate scripted-return counter or audit event.
- Persistent Gloamwood Reaping returns and regional Reaping returns remain at zero.
- The four do not advance the 1,000, 2,500, 5,000, 10,000, or 25,000 Reaping milestones.
- A one-time completion flag permanently disables the direct action.

**Fail-safe**

- Repeated input, reload, or re-entry cannot grant another four souls or decrement the backlog again.

**Required save checkpoint**

- Save immediately after the four-soul transaction and one-time flag are committed.

**Remain hidden**

- Repeating direct Reap controls, normal Reaping configuration, Retinues, support, forecasts, Halls, and the global HUD.

**Exit condition**

- The four returned entities can be presented.

---

### `P90-B03` — Four Returns and the Seals

**Entry state**

- The opening transaction completed exactly once.
- Tutorial advances through `TUT_02_DIRECT_REAP` to `TUT_03_SOULS_RETURN`.

**Narrative and player actions**

- Four comet-like souls resolve into Eustace, a battered soldier, a frayed rat, and a frayed wolf.
- Dialogue establishes the roughly three-thousand-year absence.
- Death's attempted assertion causes chains and rune-like seals to tighten.
- The player selects the soldier and confirms application of Death's Brand.

**Visible presentation**

- Lower-third dialogue only.
- Portrait swaps, framing, sound, glow, Brand, chain, seal, portal, and soul-orb overlays carry the scene.
- Full-body animation is not required.

**Authoritative state transition**

- Eustace, the Man-at-Arms character state, and the damaged rat/wolf outcomes are recorded.
- Man-at-Arms is awakened directly as a narrative exception. No Form Soul or awakening cost is required.
- The Brand is recorded as applied.
- The branded Man-at-Arms becomes available for the first dispatch.

**Fail-safe**

- Skipping dialogue still creates the correct persistent character, Form, Brand, and world state.

**Required save checkpoint**

- Save after Brand application and Man-at-Arms availability are committed.

**Remain hidden**

- Soulweave purchase flow, Calling Soul terminology, Retinues, supplies, advanced Form data, and Halls.

**Exit condition**

- The branded Man-at-Arms passes through the portal toward Gloamwood.

---

### `P90-B04` — Dispatch the First Reaping

**Entry state**

- Brand is complete.
- Tutorial state is `TUT_04_FIRST_DISPATCH`.
- Man-at-Arms and command tether 1 are available.

**Player actions**

- Assign Man-at-Arms to Gloamwood.
- Accept the preselected Emergency Writ.
- Dispatch the Reaping.

**Visible presentation**

Expose only:

- Souls Overdue;
- leading Form;
- Emergency Writ;
- one central cycle bar;
- Essence;
- several unknown output rows.

Retinues, Rations, support buffers, advanced forecasts, and supply policies remain hidden.

**Authoritative state transition**

- A persistent Reaping runtime is created for `THR_GLOAMWOOD`.
- Command tether 1 becomes occupied.
- `WRIT_EMERGENCY_FIRST_RETURN` is active.
- The Emergency objective tracks 1,000 returns produced by the active Gloamwood Reaping after dispatch. The scripted opening four are a separate transaction.
- Gloamwood and regional persistent-Reaping counters start at zero for this dispatch; they are not reconstructed from backlog already removed.
- Backlog, Essence, and Man-at-Arms Mastery begin resolving continuously.

**Fail-safe**

- Reaping progress continues while the tutorial returns to the Domain, opens dialogue, or opens another unlocked screen.
- Dispatch cannot be duplicated by repeated confirmation.

**Required save checkpoint**

- Save after dispatch and after the first authoritative simulation cursor is initialized.

**Exit condition**

- The first persistent Reaping is running.

---

### `P90-B05` — The Archive and the Soulweave

**Entry state**

- First Gloamwood cycles have completed.
- Tutorial state is `TUT_05_ARCHIVE`.

**Player actions**

- Restore the Archive.
- Purchase `REC_WEAVE_REMEMBERED`.
- Open the Soulweave.

**Visible presentation**

- Eustace becomes the unique first Archive Keeper.
- Archive/Recollections screen is followed by Soulweave.
- All thirty Soulweave positions and ancestry threads are visible.
- Higher Forms remain veiled.
- Man-at-Arms shows its Trait, Mastery, two slot positions, and three locked Art placeholders.

**Authoritative state transition**

- The damaged rat and wolf patterns resolve into Essence as a narrative/domain event; this is not a repeatable player action.
- `HALL_ARCHIVE` becomes restored.
- `REC_WEAVE_REMEMBERED` becomes purchased.
- Soulweave navigation becomes permanently available.
- Tutorial advances through `TUT_05_ARCHIVE` and `TUT_06_SOULWEAVE` based on committed state.

**Fail-safe**

- If the Emergency milestone is crossed while Soulweave or dialogue is open, production and rewards apply normally; the report and next tutorial notice queue without interrupting the active screen.
- If the player already opened Soulweave through an allowed early path, redundant instruction is skipped.

**Required save checkpoints**

- Save after Archive restoration.
- Save after The Weave Remembered purchase.
- Save after the tutorial records that Soulweave has been opened.

**Remain hidden or untaught**

- Form Arts mechanics, complete Circle explanations, all Retinue categories, support logistics, and advanced Codex features.

**Exit condition**

- Soulweave has been opened once and remains a navigation destination.

---

### `P90-B06` — First Report and Soldier Company

**Entry state**

- The Emergency Gloamwood Reaping has produced 1,000 returns after dispatch.
- The corresponding exactly-once milestone has resolved.
- Tutorial state is `TUT_07_RETINUE`.

**Approved lifecycle clarification**

At the 1,000-return boundary, the existing Reaping transitions seamlessly from `WRIT_EMERGENCY_FIRST_RETURN` to `WRIT_STANDARD`. The operation remains active with the same Threshold, Form, accumulated state, command tether, report accumulator, and simulation cursor. It does not stop or require a new dispatch.

Any UI wording such as “confirm configuration” must not teach a stop-and-redispatch lifecycle. Assigning the Soldier Company reconfigures the ongoing operation transactionally while production remains authoritative.

**Player actions**

- Open the queued first report.
- Purchase `REC_MUSTER_REMEMBERED`.
- Assign `RET_SOLDIER_COMPANY` to a compatible Man-at-Arms slot.

**Visible presentation**

- Report explains 1,000 souls returned, Essence, Man-at-Arms Mastery, and Soldier Souls.
- The report does not grant or claim those rewards.
- Retinue picker exposes one compatible card.
- Required, owned, available, and reserved Soldier Soul counts are visible.
- Before/after forecast shows the Soldier Company effect and future Ration pressure.

**Authoritative state transition**

- Guarantee ensures the player owns at least twelve `SOUL_CALLING_SOLDIER` after legitimate production is counted.
- Required Essence floor is secured for mandatory progression.
- `REC_MUSTER_REMEMBERED` unlocks Retinue assignment.
- Twelve Soldier Souls become reserved while Soldier Company is fielded.
- The same Standard Reaping continues with the new Retinue configuration.

**Fail-safe**

- The Soldier guarantee grants `max(0, 12 - current_owned_total)` and never overwrites a larger legitimate amount.
- Opening, dismissing, or losing the report presentation does not alter inventory.
- Removing the Retinue later releases the twelve reserved Souls to the available pool.
- Service attrition is not simulated in this prototype.

**Required save checkpoints**

- Save after the 1,000-return milestone and Writ transition.
- Save after any additive guarantee.
- Save after The Muster Remembered purchase.
- Save after Retinue assignment or removal.

**Exit condition**

- Soldier Company is assigned and the ongoing Gloamwood Reaping reflects its effect.

---

### `P90-B07` — The Scribe Form

**Entry state**

- Gloamwood reaches 2,500 cumulative returns.
- Tutorial state is `TUT_08_SCRIBE`.

**Player actions**

- Open Soulweave.
- Inspect the newly available Scribe node.
- Press **Awaken**.

**Visible presentation**

- Scribe changes from veiled/unknown to charted and awakenable.
- Comparison emphasizes discovery speed and forecast confidence rather than raw throughput.
- Scribe's two Retinue Slots may be visible but remain empty and untaught.

**Authoritative state transition**

- Guarantee ensures at least one `SOUL_FORM_SCRIBE` exists after legitimate production is counted.
- The required Essence amount is secured for the mandatory awakening.
- The player action consumes the configured awakening requirements and sets `FORM_SCRIBE` to awakened.

**Approved interaction clarification**

The normal guided path must not awaken Scribe automatically. The player is guided to press **Awaken**. The tutorial state table's older shorthand “grant/top up Scribe Soul and awaken Scribe” is interpreted as “grant/top up the requirement, guide the action, and wait for the authoritative awakened state.”

Until a separate owner decision defines mechanical-tutorial skip behavior, skipping presentation must not silently auto-awaken Scribe. Later progression remains gated by the actual awakened flag.

**Fail-safe**

- If a Scribe Form Soul dropped earlier, the milestone grants only the missing amount, which may be zero.
- Mandatory Essence cannot be spent into a softlock before awakening is secure.
- Repeated input or reload cannot awaken twice or charge the cost twice.

**Required save checkpoints**

- Save after the guarantee/reservation is committed.
- Save after the player successfully awakens Scribe.

**Remain hidden or untaught**

- Specialist and Extraction Retinue content, Form Arts, higher-Circle weaving requirements, and duplicate Form Soul sinks.

**Exit condition**

- `FORM_SCRIBE` is awakened by the player.

---

### `P90-B08` — The Second Thread

**Entry state**

- Gloamwood has at least 5,000 cumulative returns.
- Scribe is awakened.
- The minor resonance has not previously resolved.

**Authoritative milestone**

- Resolve the minor first seal resonance exactly once.
- Chart or reveal `THR_BROKEN_WATCH`.
- Grant command tether 2.
- This is a resonance, not a full seal break.

**Player actions**

- Open the regional map.
- Inspect Broken Watch.
- Compare Form assignments.
- Occupy both command tethers.

**Visible presentation**

- Comparison explains that Man-at-Arms has the stronger raw Martial fit at Broken Watch.
- The tutorial recommends Scribe at Broken Watch temporarily because Provisions access/source identification and later insight should be reached quickly.
- Any valid two-Reaping arrangement is accepted.
- Active tether lines and both Threshold states are visible.

**Authoritative state transition**

- `TUT_09_SECOND_THRESHOLD` becomes active and completes when both tethers are occupied.
- A second persistent Reaping is created using the same simulation model as the first.
- Form reassignment changes configuration without using a separate production system.

**Fail-safe**

- Exact pairing does not block tutorial progression.
- Required discovery has a slower non-Scribe fallback.
- The resonance, Threshold unlock, and tether grant are each exactly once across save/load.

**Required save checkpoints**

- Save after the minor resonance and unlock transaction.
- Save after each dispatch, recall, or Form reassignment.

**Exit condition**

- Both command tethers are occupied by valid active Reapings.

---

### `P90-B09` — Scribe Proves Its Value

**Entry state**

- Broken Watch is active.
- Provisions is still Unknown.
- Tutorial state is `TUT_10_DISCOVERY`.

**Player action**

- Observe the Provisions unlock/source-identification event.
- Inspect the newly identified Provisions row, zero-start acquisition state, and changed forecast confidence.

**Visible presentation**

- Unknown material becomes **Provisions — common source**.
- It then progresses toward a Charted expected range.
- When Scribe causes the discovery, the presentation attributes the improvement to **Unclosed Ledger**.

**Authoritative state transition**

- Access unlocks at an explicit deterministic progression boundary; elapsed time before that boundary produces no Provisions.
- Subsequent insight progress advances through the shared simulation. Scribe reaches the prototype information boundary faster and presents narrower forecast uncertainty.
- No Provisions exists from pre-unlock elapsed time. The access transaction identifies the item and Broken Watch source before later production can bank inventory.

**Prototype scaffold values**

- Approximately three successful Scribe-led discovery cycles, or six fallback cycles without Scribe.
- Exact discovery thresholds remain configurable.

**Fail-safe**

- A non-recommended assignment still identifies Provisions through the slower fallback.
- Reloading the discovery boundary cannot duplicate inventory or the identification event.

**Required save checkpoints**

- Save when Provisions changes to Identified.
- Save when it reaches Charted if that occurs during the prototype.

**Exit condition**

- Provisions is at least Identified, its currently available source is known, and post-unlock production has begun from zero.

---

### `P90-B10` — The First Supply Chain

**Entry state**

- Provisions is Identified.
- Soldier Company support is approaching or has reached a warning condition.
- Tutorial state is `TUT_11_LARDER`.

**Player actions**

- Restore `HALL_LARDER`.
- Activate the Provisions → Rations recipe.
- Set the simple output policy to **Maintain 50 Rations**.

**Visible presentation**

- Before restoration, forecast shows the current full-support duration and post-depletion Soldier Company behavior.
- After activation, forecast shows sustained support or a materially longer Stable Runtime.
- Hall detail shows input stock, output stock, recipe, rate, and target.

**Authoritative state transition**

- Guarantee ensures enough Provisions for:
  - Larder restoration;
  - one Ration production batch;
  - a configurable onboarding buffer, initially suggested at approximately 20%.
- `HALL_LARDER` becomes restored and active.
- Rations become a global Store.
- Hall production resolves online and offline using the same elapsed-time model as Reapings.

**Fail-safe**

- The Provisions top-up grants only the missing amount after any legitimate post-unlock production is counted. It never simulates or backfills pre-unlock production.
- If Rations deplete before completion, Soldier Company falls to its configured reduced floor; base Reaping continues.
- Early Larder completion skips redundant tutorial steps.

**Required save checkpoints**

- Save after the Provisions guarantee.
- Save after Larder restoration.
- Save after recipe activation or target-policy change.

**Remain hidden or untaught**

- Multiple recipes, recipe queues, Keeper optimization, protected-reserve UI, Armaments, and advanced Store policies.

**Exit condition**

- Larder is active and has enough input to complete at least one batch.

---

### `P90-B11` — Second Resonance and First Choice

**Entry state**

- Total regional Souls Returned reaches 10,000.
- The 10,000-regional event has not resolved previously.
- Tutorial state is `TUT_12_SEAL_CHOICE`.

**Player actions**

- Review the resonance reward.
- Choose one affordable optional Recollection:
  - `REC_QUICKER_RECKONING`;
  - `REC_NAMES_KEPT`;
  - `REC_OPEN_LEDGERS`.

**Visible presentation**

- A seal rune fractures, dims, or visibly reacts.
- A short audiovisual surge communicates the payoff.
- The seal screen becomes viewable.
- The selected Recollection immediately shows a before/after forecast or information change.

**Authoritative state transition**

- Resolve the second prototype resonance exactly once.
- Grant the configured Essence bundle exactly once.
- Make all three optional Recollections available and ensure at least one is affordable.
- Purchase only the selected node; unchosen nodes remain available later.

**Fail-safe**

- The choice is not exclusive.
- No new mandatory tutorial chain follows.
- Reloading cannot replay the reward, resonance, or purchase.

**Required save checkpoints**

- Save after the 10,000-regional resonance transaction.
- Save after the optional Recollection purchase.

**Exit condition**

- The resonance has resolved and one optional Recollection is purchased.

---

### `P90-B12` — The Machinery Continues

**Entry state**

- Both Reapings are active.
- Larder is active.
- The optional Recollection has been purchased.
- Tutorial state can enter `TUT_13_COMPLETE` once the forecast requirement is satisfied.

**Player actions**

- Operate freely.
- Inspect reports and objectives.
- Reassign Forms if desired.
- Open the eight-hour offline forecast.

**Visible presentation**

- Two active Reaping summaries.
- Global resources and Larder status.
- Form Mastery and seal progress.
- Three objective horizons: immediate, developmental, and long-term.
- Reaping Report history or latest report.
- Eight-hour forecast with expected gains, support transitions, milestones, and resulting state.
- Gloamwood tooltip explains that zero backlog will transition to Settled Passage without removing the location.

**Authoritative state transition**

- Once the required forecast has been presented, tutorial enters `TUT_13_COMPLETE`.
- Mandatory guidance is disabled.
- Optional objective hints may remain.

**Fail-safe**

- Opening, dismissing, or ignoring a report does not affect production.
- No claim or confirmation is required for Reapings or Halls to continue.

**Required save checkpoint**

- Save after `TUT_13_COMPLETE` is committed.

**Exit condition**

- The player has seen the eight-hour forecast and the tutorial controller is complete.

## 6. Milestones and deterministic guarantees

All guarantees are evaluated against current authoritative state after ordinary simulated output is applied. Each uses an exactly-once completion flag plus a current-state check.

Milestones in this section use persistent-Reaping counters. The scripted opening four affect Gloamwood backlog and the separate opening audit counter only. They are excluded from Gloamwood Reaping-return and regional Reaping-return totals.

| ID | Trigger | Guaranteed result | Status |
|---|---|---|---|
| `P90-G01` | Scripted opening attempt | Exactly four souls returned; Gloamwood becomes `999,996`; persistent-Reaping Threshold and regional counters remain zero. | Required and fixed. |
| `P90-G02` | Emergency Gloamwood Reaping produces 1,000 returns after dispatch | Emergency Writ milestone completes; active operation transitions to Standard; at least twelve Soldier Souls; required Essence floor. | Required. Exact Essence floor is configurable. |
| `P90-G03` | First 2,500 Gloamwood returns | At least one Scribe Form Soul; required awakening Essence secured. | Required. Player still presses Awaken. |
| `P90-G04` | First 5,000 Gloamwood returns **and** Scribe awakened | Minor first resonance; Broken Watch revealed/charted; command tether 2. | Required and exactly once. |
| `P90-G05` | Provisions identified | Enough Provisions for Larder restoration, one batch, and onboarding buffer. | Required. Buffer is provisional. |
| `P90-G06` | First 10,000 regional returns | Separate second resonance; Essence bundle; one affordable optional Recollection choice. | Required and exactly once. |
| `P90-G07` | First 25,000 regional returns | Larger reward or next Form-source hint. | Prototype scaffold; does not gate tutorial completion and exact reward is open. |
| `P90-G08` | First Threshold reaches zero backlog | Automatic Settled Passage transition and major region/seal progress. | Lifecycle support required; exact reward may be outside the 90-minute session. |

Reference guarantee logic:

```text
soldier_top_up = max(0, 12 - soldier_souls_owned)

scribe_top_up = max(0, 1 - scribe_form_souls_owned)

provisions_floor = (
    larder_restore_cost
    + first_ration_batch_cost
    + onboarding_buffer
)
provisions_top_up = max(0, provisions_floor - provisions_owned)
```

The calculation must use the project's inventory semantics consistently. If `owned` includes reserved Souls, the available and reserved views must still reconcile to the same authoritative total.

## 7. Prototype content contract

### 7.1 Canonical content IDs

Use these exact IDs and separate them from display names.

| Type | Canonical ID | Display name |
|---|---|---|
| Form | `FORM_MAN_AT_ARMS` | Man-at-Arms |
| Form | `FORM_SCRIBE` | Scribe |
| Retinue | `RET_SOLDIER_COMPANY` | Soldier Company |
| Calling Soul | `SOUL_CALLING_SOLDIER` | Soldier Soul |
| Form Soul | `SOUL_FORM_SCRIBE` | Scribe Form Soul |
| Form Soul | `SOUL_FORM_MAN_AT_ARMS` | Man-at-Arms Form Soul |
| Threshold | `THR_GLOAMWOOD` | Gloamwood Hamlet |
| Threshold | `THR_BROKEN_WATCH` | Broken Watch |
| Hall | `HALL_ARCHIVE` | Archive |
| Hall | `HALL_LARDER` | Larder |
| Resource | `RES_ESSENCE` | Essence |
| Resource | `RES_PROVISIONS` | Provisions |
| Store | `STORE_RATIONS` | Rations |
| Recollection | `REC_WEAVE_REMEMBERED` | The Weave Remembered |
| Recollection | `REC_MUSTER_REMEMBERED` | The Muster Remembered |
| Recollection | `REC_QUICKER_RECKONING` | Quicker Reckoning |
| Recollection | `REC_NAMES_KEPT` | Names Kept |
| Recollection | `REC_OPEN_LEDGERS` | Open Ledgers |
| Writ | `WRIT_EMERGENCY_FIRST_RETURN` | Emergency Writ |
| Writ | `WRIT_STANDARD` | Standard Writ |

No canonical ID is currently approved for the one-time **Reach Through the Threshold** action. Do not invent a permanent content ID merely for symmetry; define one only when the data contract or implementation requires it and record the decision.

### 7.2 Functional Forms

| Field | Man-at-Arms | Scribe |
|---|---|---|
| Identity | Organized force: shield, blade, drill, and boots in mud. | Keeper of names, debts, errors, omissions, and forgotten records. |
| Prototype role | Backlog throughput, Essence, Mastery, Soldier Company synergy. | Discovery, narrower forecast ranges, qualitative information advantage. |
| Retinue Slots | Martial; Martial / Logistics | Specialist; Logistics / Extraction |
| Trait | **The Old Drill** | **Unclosed Ledger** |
| Prototype effect | At Settlement or Martial Thresholds, Souls Returned per cycle `+15%`; Martial Retinue throughput effects `+10%`. | Discovery progress `+100%`; expected output-range uncertainty reduced by `50%`. |
| Weakness | Poor preservation and spiritual or magical handling. | Lower direct throughput and little direct survival value. |
| Status of numbers | Prototype scaffold; configurable. | Prototype scaffold; configurable. |

All other Soulweave nodes are presentational placeholders. They show position, ancestry thread, and reveal state but do not require functional Traits, Arts, Mastery rules, costs, or data beyond what the UI needs.

### 7.3 Soldier Company

| Field | Prototype rule |
|---|---|
| Category | Martial |
| Anchor Soul | `SOUL_CALLING_SOLDIER` |
| Requirement | Twelve Soldier Souls, reserved while fielded. |
| Effects | Provisional `+30%` Souls Returned from its own contribution, `+20%` Essence, `+15%` Mastery. |
| Stacking | Open/TBD; must be centralized and tested before implementation. |
| Main pressure | Rations. Armaments remain hidden. |
| Depletion | Effect falls to a configurable reduced floor; base Reaping continues. |
| Attrition | Not implemented. |

### 7.4 Gloamwood Hamlet

| Field | Prototype rule |
|---|---|
| Type | Standing Threshold — Overdue |
| Tags | Forest, Settlement |
| Opening backlog | `1,000,000`; `999,996` after the scripted attempt |
| Known initially | Essence and active Form Mastery |
| Calling Soul channel | Soldier Souls; common repeatable source; guarantee reaches twelve by 1,000 returns |
| Form Soul channel | Scribe Form Souls; uncommon repeatable source; guarantee reaches one by 2,500 returns |
| Material channel | None required for this prototype |
| Post-settlement | Core returned-soul and Essence streams use their existing Settled rules; Soldier and Scribe Soul channels default to their full authored renewable rate |

### 7.5 Broken Watch

| Field | Prototype rule |
|---|---|
| Type | Standing Threshold — Overdue |
| Tags | Road, Settlement, Martial |
| Backlog | Provisional `250,000` |
| Known at unlock | Essence and active Form Mastery; other rows Unknown |
| Material channel | Provisions; common repeatable source; guaranteed floor after identification |
| Form Soul channel | Man-at-Arms Form Soul; uncommon repeatable source; not required for onboarding |
| Future Calling Soul | Disabled backend slot; Roadwarden is only a later candidate, not prototype content |
| Post-settlement | Core returned-soul and Essence streams use their existing Settled rules; Provisions and Man-at-Arms Form-Soul channels default to their full authored renewable rate |

### 7.6 Halls and Recollections

| Content | Prototype role |
|---|---|
| Archive | First restored Hall; Eustace is unique Keeper; hosts early Recollections and opens Soulweave path. |
| Larder | One Provisions → Rations recipe; simple **Maintain 50 Rations** policy. Target value is configurable prototype data. |
| The Weave Remembered | Unlocks Soulweave screen. |
| The Muster Remembered | Unlocks Retinue assignment. |
| Quicker Reckoning | Optional rate-oriented improvement; exact coefficient provisional. |
| Names Kept | Optional Whole Soul preservation improvement; exact prototype effect provisional. |
| Open Ledgers | Optional discovery and forecast improvement; exact coefficient provisional. |

### 7.7 Writs and command capacity

| Content | Prototype role |
|---|---|
| Reach Through the Threshold | One-time scripted opening action; never a repeatable clicker control. |
| Emergency Writ | Tracks 1,000 returns produced by the first Gloamwood Reaping after dispatch, then automatically transitions the same operation to Standard. |
| Standard Writ | Persistent balanced behavior used after the tutorial objective. |
| Command tether 1 | Available after Brand and first dispatch. |
| Command tether 2 | Granted by the minor 5,000-Gloamwood resonance after Scribe is awakened. |

## 8. Threshold and discovery state models

### Threshold state machine

| State | Entry | Behavior / exit |
|---|---|---|
| Unknown | Region exists but site is not detected. | Hidden or fogged; not interactable. |
| Detected | Narrative, Recollection, or milestone reveals the site. | Silhouette or marker with limited data. |
| Charted | Enough information exists to display backlog and known channels. | Can become Available when requirements are met. |
| Available | Threshold can accept a Reaping. | Assign Form and Writ. |
| Active — Overdue | Active Reaping and backlog `> 0`. | Reduce backlog and resolve parallel outputs. |
| Active — Settled | Active Reaping and backlog `= 0`. | Continue renewable production; each core stream or output channel applies its own authored Settled rule. |
| Inactive — Settled | No Form assigned after settlement. | No production; remains available for later assignment. |

The exact relationship between Detected, Charted, and Available should remain data-driven. Prototype flow may combine an information reveal and availability in one exactly-once transaction when required.

Output-item access is global, but source identification is availability-scoped. Unlocking an item identifies all currently available sources without naming locked regions. If another Threshold becomes available later, that source is identified then and begins from zero. No unlock order or elapsed deadline permanently excludes an item.

Non-Essence resources and rare/location-exclusive Souls default to full renewable channel rate after Settlement during the prototype. Core returned-soul and Essence rules remain separate; later balance passes may tune an individual channel without changing access ownership.

### Output access, discovery, and insight state machine

| State | Display | Prototype behavior |
|---|---|---|
| Locked / Unknown | Question mark, latent row count, or broad category hint; no named unavailable location. | Progression-gated output produces nothing. |
| Unlocked / Identified | Name, icon, qualitative frequency, and every currently available Threshold source. | Each available source begins from zero at the unlock boundary. |
| Unlocked / Charted | Expected per-hour or per-cycle range, current modifiers, and narrower uncertainty. | Scribe reaches this information state faster and with better precision. |

Global item access, currently initialized source records, and later insight state must reconstruct the correct UI after load. Unlock timing has opportunity cost but no deadline, permanent lockout, retroactive output, or later baseline-rate penalty.

## 9. Tutorial controller contract

### Canonical tutorial states

| State ID | Entry condition | Required primary action |
|---|---|---|
| `TUT_00_BOOT` | New game created | Begin opening monologue. |
| `TUT_01_WINDOW` | Player advances or skips opening | Reveal Sanctum and Gloamwood backlog. |
| `TUT_02_DIRECT_REAP` | Player selects Gloamwood | Execute the one-time four-soul transaction. |
| `TUT_03_SOULS_RETURN` | Four returned entities are available | Present Eustace, seals, and Brand; commit persistent character/Form state. |
| `TUT_04_FIRST_DISPATCH` | Brand complete | Guide Gloamwood configuration and Emergency Writ dispatch. |
| `TUT_05_ARCHIVE` | First productive cycles completed | Resolve damaged souls, restore Archive, unlock Recollections. |
| `TUT_06_SOULWEAVE` | The Weave Remembered purchased | Open Soulweave and explain Forms, ancestry, and Mastery. |
| `TUT_07_RETINUE` | Emergency Gloamwood Reaping has produced 1,000 returns | Top up Soldier Souls, transition to Standard, unlock and field Soldier Company. |
| `TUT_08_SCRIBE` | First 2,500 Gloamwood returns resolved | Top up Scribe requirement and guide the player to press **Awaken**. |
| `TUT_09_SECOND_THRESHOLD` | Scribe awakened and 5,000 Gloamwood returns | Resolve minor resonance, reveal Broken Watch, grant tether 2, occupy both tethers. |
| `TUT_10_DISCOVERY` | Broken Watch active | Unlock Provisions access, identify Broken Watch as a source, then demonstrate Scribe/fallback insight progression. |
| `TUT_11_LARDER` | Provisions unlocked/identified and support warning relevant | Apply any missing-amount guarantee, restore Larder, and activate Ration production. |
| `TUT_12_SEAL_CHOICE` | 10,000 regional returns | Resolve second resonance and optional Recollection choice. |
| `TUT_13_COMPLETE` | Both Reapings active and required forecast presented | Disable mandatory guidance; retain optional objective hints. |

### Controller rules

- Persist current tutorial state, completed grants, skip state, and all exactly-once flags.
- Evaluate entry and completion from authoritative domain state rather than UI sequence alone.
- Only one blocking tutorial may be active. Later events queue or are reconstructed from state after load.
- If a condition completed early, skip redundant guidance and proceed to the next unmet authoritative condition.
- Narrative skip applies required world-state changes.
- Skipping mechanical guidance dismisses that presentation and opens a concise Help entry, but it must not invent resource or domain state that contradicts the normal action contract.
- Replaying tutorial guidance from Help is presentational only and cannot repeat grants, costs, unlocks, or world-state transitions.
- Production, offline time, milestones, and Halls continue while tutorial UI is open.
- On load, rebuild pending notices from authoritative state; do not rely on an unsaved transient queue.
- Tutorial code may request a guarantee but does not directly own inventory logic.
- Completion of a tutorial screen is not proof that the corresponding domain action succeeded; validate the authoritative result.

## 10. Deviation and softlock matrix

| Deviation or failure path | Required prevention/recovery |
|---|---|
| Player spends Essence before Scribe awakening | Reserve the minimum, hide unrelated purchases temporarily, discount the requirement, or top up only the missing amount. Exact UX may vary; softlock is forbidden. |
| Scribe Soul drops before 2,500 | The milestone grants zero additional Souls if the requirement is already met. |
| Player never assigns Scribe to Broken Watch | Discovery completes through slower fallback progress after configurable cycles or a fixed site milestone. |
| Player assigns Forms opposite the recommendation | Accept the arrangement; update forecasts honestly; do not block both-tether completion. |
| Player closes during dialogue | Resume at the same authoritative tutorial state; already-committed grants and scene changes do not repeat. |
| Emergency milestone occurs while Soulweave or another screen is open | Apply rewards and Writ transition, queue report/notice, keep the current screen open, and continue production. |
| Player opens or dismisses the report late | No inventory or progress changes; report is presentational only. |
| Rations deplete before Larder completion | Soldier Company degrades to its configured floor; base Reaping continues; Provisions guarantee remains reachable. |
| Provisions unlock occurs late | Begin every currently available Provisions source at zero, apply the onboarding top-up only to the missing amount, and preserve future access after Settlement. |
| Player restores Larder before the guided step | Detect the active Hall and skip redundant instructions. |
| Player reaches a milestone while offline | Apply the event once at the correct simulation boundary and continue remaining elapsed time under the new state. |
| A Threshold settles offline | Transition automatically to Settled Passage and resolve remaining time at renewable rates. |
| Load is repeated after interrupted offline resolution | Transaction/idempotency strategy prevents duplicate production, guarantees, reports, unlocks, or resonances. |
| Tutorial presentation is skipped at Scribe | Skip behavior beyond the normal guided path remains open. Until the owner decides otherwise, do not auto-awaken; keep the authoritative awakening objective available until the player acts. |

## 11. Screen inventory and progressive disclosure

### Required prototype screens

| Screen | Required content |
|---|---|
| Dialogue overlay | Lower-third box, speaker portrait, text, advance/auto/skip, text speed, voice toggle, overlay effects. |
| Death's Domain / Sanctum | Window, active Reaping summaries, global resources, Hall access, objective panel. |
| Regional map | Gloamwood, Broken Watch, veiled later POIs, tether lines, state overlays. |
| Threshold detail | Backlog, active Form, Writ, cycle, known/unknown outputs, forecast, Retinue slots after unlock. |
| Soulweave | All thirty positions and ancestry threads; reveal states; awakened Form access. |
| Form detail | Soulform art/placeholder, Trait, Mastery, locked Art positions, slots, role summary, optional performance placeholder. |
| Recollections / Archive | Available nodes, costs, system unlocks, first optional choice. |
| Retinue picker | Compatible cards, anchor Souls required/owned/reserved, effect preview, support pressure. |
| Hall detail — Larder | Input, output, recipe, rate, active state, Maintain 50 target. |
| Reaping Report | Gains, backlog progress, discoveries, milestones, support warnings, elapsed time, comparison. |
| Offline forecast / return | Expected or realized production, degradation segments, milestones crossed, and resulting state. |

These may be separate scenes, panels, or routed views. The requirement is functional disclosure and state ownership, not a prescribed scene count.

### Threshold disclosure by stage

| Stage | Fields exposed |
|---|---|
| First visit | Backlog, Form assignment, Emergency Writ, cycle bar, Essence, unknown rows. |
| Soulweave restored | Trait, Mastery, Form comparison. |
| Retinues restored | Slots, Soldier Company, reserved Souls, effect forecast. |
| Scribe active | Discovery confidence and output identification. |
| Larder restored | Support pressure, Stable Runtime, post-depletion behavior. |
| Tutorial complete | Offline forecast, report history/latest report, objective panel, bottleneck summary. |

### Readability requirements

- Backlog, rate, settlement estimate, output categories, and support state are visually separate concepts.
- Use one central Reaping-cycle bar; do not create unrelated progress bars for every channel.
- Forecast changes caused by a Trait, Retinue, Hall, or Recollection show understandable before/after values.
- Unknown, Identified, and Charted states are distinguishable at a glance.
- Every relevant screen communicates that production continues while the player is elsewhere.
- UI interpolation cannot hide or delay authoritative banking.

The map may include veiled village, mine, port, and ruined cathedral/cemetery anchors to establish scale, but only Gloamwood and Broken Watch require functional onboarding content.

## 12. Simulation and data requirements

### Architectural production shape

The source formula expresses separation of concerns, not final balance:

```text
souls_returned = threshold_base_rate
    × form_rate
    × tag_fit
    × writ_rate
    × retinue_rate
    × support_state
    × global_modifiers

corrupted_essence += souls_returned × essence_per_soul × essence_modifiers
mastery += productive_time × form_mastery_rate
resolve_parallel_channels(form_souls, calling_souls, materials, denizens)
```

Do not treat this multiplication order, coefficient naming, or channel frequency as locked balance. Preserve independent channels and a shared authoritative resolver.

### Online and offline behavior

- Online play uses a fixed simulation tick or event-driven interval; rendered frames are presentation only. Foreground elapsed time comes from an injected monotonic process clock.
- Simulation and domain services receive elapsed durations and never read clocks, Steam APIs, scene state, or frame delta directly.
- Closed-session progress uses an approved external `TrustedTimeProvider` and a persisted trusted anchor. The player's local wall clock, timezone, calendar, file timestamps, and manually supplied time are not authoritative inputs and are not fallback sources.
- If trusted time is unavailable, load the last committed state, continue foreground production, and retain a pending reconciliation marker. Grant no guessed closed-session progress. When trust returns, subtract foreground time already credited since the last trusted anchor before resolving the remaining non-negative gap exactly once.
- Debug and automated tests may use an explicit fake trusted-time provider. Release builds must not expose a manual or debug provider. The production Steam-compatible adapter is a narrowly scoped platform dependency milestone and does not move time authority into domain code.
- Resolve time analytically and split at support, milestone, discovery, backlog-zero, Hall-target, Writ-transition, and guarantee boundaries.
- Store aggregate report deltas and explanatory events rather than every cycle.
- Forecast mode must call the same rules without committing authoritative state.
- Two active Reapings and one Hall resolve through the same orchestration path rather than separate bespoke loops.

### Minimum entity data

| Entity | Minimum prototype fields |
|---|---|
| Form definition/state | ID, display name, Circle, Trait/modifiers, base rate, discovery modifier, uncertainty modifier, slot profile, awakened state, Mastery. |
| Threshold definition/state | ID, display name, tags, visibility/availability state, backlog, base rate, channels, discovery progress/state, familiarity, settlement multiplier. |
| Reaping runtime | Threshold ID, Form ID, Writ ID, Retinue IDs, active state, support state, start/last-resolved time, cycle/display progress as needed, report accumulator reference. |
| Inventory | Resource/Soul/Store ID, authoritative total, reserved amount where applicable, available amount derived consistently. |
| Retinue definition/state | ID, category, anchor Soul ID, requirement, modifiers, support pressure, active/reduced effect, assignment. |
| Hall definition/state | ID, recipe, rate, input rule, output target, active state, last-resolved time. |
| Tutorial state | Current state ID, completed state/actions, guarantee flags, skip flags, pending-notice derivation data. |
| Milestone/resonance state | Separate scripted-return, Threshold persistent-Reaping, and regional persistent-Reaping counters; completed flags; reward-completion flags. |
| Report accumulator | Elapsed time, souls, resources, Whole Souls, Mastery, discoveries, milestones, support transitions, forecast deltas. |

The detailed serialization schema belongs in `docs/codex/DATA_AND_CONTENT_CONTRACTS.md`, not in this design file.

## 13. Save/load contract

### Required checkpoints

Save after:

- every tutorial state transition;
- every one-time guarantee or unlock;
- direct opening transaction;
- dispatch, recall, Form reassignment, or Writ transition;
- Form awakening;
- Retinue assignment or removal;
- Recollection purchase;
- Hall restoration, activation, or target change;
- resonance and command-tether grants;
- application focus loss and graceful quit;
- tutorial completion.

Before and after offline resolution, use an idempotent transaction or equivalent commit strategy when practical. The exact persistence mechanism is an architecture decision, but the observable guarantee is mandatory: a retry cannot duplicate or lose progress.

### Persisted functional state

At minimum preserve:

- Threshold visibility, availability, backlog, settlement, and discovery;
- active Reapings, Forms, Writs, Retinues, support state, and timing cursors;
- inventory totals and Calling Soul reservations;
- Form awakening and Mastery;
- Halls, recipes, inputs, outputs, targets, and timing cursors;
- Recollections;
- command tethers, milestones, resonances, and rewards;
- tutorial state, skip state, exactly-once grants, and reconstructible notices;
- report accumulators;
- save schema version and any resolution transaction state.

### Save acceptance paths

The implementation must support save/quit/load at least around these boundaries:

1. before and after the four-soul action;
2. during the first active Reaping;
3. while Soulweave is open and the 1,000 milestone occurs;
4. before and after Soldier Company assignment;
5. before and after Scribe awakening;
6. before and after the 5,000 resonance/tether grant;
7. during Broken Watch discovery;
8. before and after Larder activation;
9. before and after the 10,000 resonance and Recollection purchase;
10. before and after an offline interval crossing one or more boundaries;
11. after `TUT_13_COMPLETE`.

## 14. Reports and forecasts

### Reaping Report contract

Resources are applied immediately to authoritative state. A report accumulator stores deltas and explanatory events until presentation.

Opening or dismissing a report may clear or archive only the presentation accumulator. It must never:

- grant the same resources again;
- remove resources;
- delay milestone evaluation;
- pause production;
- be required to continue the tutorial's domain progress.

A report should include applicable values for souls, backlog, Essence, Whole Souls, Mastery, discoveries, milestones, support transitions, elapsed time, and changed estimates.

### Forecast contract

Forecasts are non-committing projections using the same simulation rules as actual resolution. They should explain:

- current configuration;
- expected Souls Returned and output ranges;
- Stable Runtime;
- main support pressure;
- post-depletion behavior;
- milestone or settlement transitions within the forecast window;
- resulting state after one hour or eight hours where exposed.

The eight-hour forecast is required for prototype completion. A one-hour view is useful but not required unless a milestone explicitly includes it.

Forecast uncertainty is presentation data influenced by discovery and Scribe. Uncertainty does not change the authoritative expected production model merely because the player cannot yet see it precisely.

## 15. Narrative, assets, and audio minimum

### Narrative anchors

| Element | Prototype function |
|---|---|
| Death | Genderless cosmic office; confused at awakening, stern but not cruel, weakened by seals. |
| Eustace | Overdue arcane scholar, argumentative guide, first Archive Keeper, dry exposition. |
| Man-at-Arms | First stable recovered Form; nervous individual who becomes practical envoy. |
| Rat and wolf | Demonstrate damaged soul-patterns and that nonhuman souls matter. |
| Death's Brand | Authorization mark and modular visual element. |
| Chains and seals | Visible narrative/account progression; modular overlays support independent reactions. |

Final dialogue is out of scope. Prototype dialogue may be placeholder-quality but must support the state changes and pacing requirements.

### Minimum asset destinations

Required or placeholder-capable assets include:

- Death, Eustace, and Man-at-Arms portrait/cutscene variants;
- Man-at-Arms and Scribe Soulform cards;
- Sanctum background and window view;
- regional terrain map and Gloamwood/Broken Watch POIs;
- Archive and Larder art or clear placeholders;
- Brand, chain, seal, portal, soul-orb, tether, discovery, and milestone overlays;
- icons for Essence, Whole Soul, Form Soul, Calling Soul, Provisions, Rations, Mastery, and command tether.

Optional early art-direction tests may include Squire or Hunter cards, but they are not functional prototype content.

### Audio

Prototype audio may use placeholders, but the intended events include dialogue advance, portal opening, soul return, backlog decrement, Reaping-cycle completion, chain tightening, resonance, Form awakening, Retinue assignment, discovery, Hall activation, milestone completion, and low-key ambience.

No final voice acting is required. Mechanical instructions remain text-led and skippable.

## 16. Local playtest instrumentation and acceptance

The Beat Sheet proposes telemetry events for playtest analysis. In the current prototype, treat these as local debug/test instrumentation unless a later owner decision approves external telemetry. Do not add a network service or backend.

Suggested local events:

- tutorial state entered;
- Threshold dispatched;
- milestone reached;
- Form awakened;
- Retinue fielded;
- discovery completed;
- Hall activated;
- optional Recollection selected;
- session exit state;
- offline return summary.

### Acceptance criteria

| ID | Area | Pass condition |
|---|---|---|
| `P90-AC01` | Pacing | Most first-time players begin automatic Reaping within seven minutes and reach player-led play by approximately 60–75 minutes. |
| `P90-AC02` | Clarity | In playtests, at least 80% of players answer at least eight of ten comprehension questions correctly without using a glossary. |
| `P90-AC03` | Idle promise | Players see progress continue while reading menus and understand the eight-hour forecast. |
| `P90-AC04` | No softlocks | Tested save, quit, skip, early-completion, and non-recommended-assignment paths still reach the required end state. |
| `P90-AC05` | Form differentiation | Players can explain why Scribe and Man-at-Arms may be assigned differently. |
| `P90-AC06` | Supply behavior | Players understand that Ration depletion weakens the Retinue but does not stop the Reaping. |
| `P90-AC07` | Technical integrity | Offline resolution is deterministic, uses an approved external trusted-time source rather than the local device wall clock, and does not duplicate or lose rewards across repeated loads or delayed trusted-time reconciliation. |
| `P90-AC08` | Performance | The prototype remains responsive with two Reapings, one Hall, UI animation, and report aggregation active. |

### Comprehension questions

1. What does Souls Overdue represent?
2. Why did Death return only four souls?
3. What continues while another screen is open or the game is closed?
4. Why might Scribe be assigned instead of Man-at-Arms?
5. What is the difference between a Form Soul and a Calling Soul?
6. What does Soldier Company change?
7. Why does the Larder matter?
8. What happens when Rations run out?
9. What happens when a Threshold reaches zero?
10. What is the next short-term objective?

## 17. Explicit non-goals and deferred hooks

Do not implement in the 0–90 minute prototype:

- Calling Soul attrition, strain, relief reserves, service settlement, scattering, or Recovery Retinues;
- additional advanced Writs or Custom Writ automation;
- Form Arts;
- functional implementation of the remaining twenty-eight Forms;
- Denizen Souls;
- advanced tags or full Codex Mortis analytics;
- advanced Store policies, multiple recipes, or Hall Keeper optimization beyond Eustace's narrative Archive role;
- Frayed Thresholds, anchoring, or Deep Incursion;
- final balance or release-scale content;
- final narrative script, final voice acting, final art, or final animation;
- Steamworks or other storefront integration beyond the separately approved trusted-time adapter; achievements, cloud saves, and release packaging remain out of scope;
- launch telemetry, accounts, servers, or backend services.

Small interfaces may anticipate later systems only where doing so is necessary to avoid clear near-term rework. A speculative generic framework is not justified by future possibility alone.

## 18. Prototype completion checklist

A prototype build is not complete until all applicable items are demonstrably true:

- [ ] New game reaches the opening narrative and exact `1,000,000 → 999,996` transaction.
- [ ] The scripted four are recorded separately and leave all persistent-Reaping milestone counters at zero.
- [ ] The one-time direct Reap action cannot repeat after save/load.
- [ ] The first persistent Reaping continues while other screens are open.
- [ ] Archive restoration and Recollection purchase survive save/load.
- [ ] Soulweave shows thirty positions and two functional Form entries.
- [ ] Soldier Souls top up additively to twelve and reserve/release correctly.
- [ ] The 1,000-return boundary transitions the same Reaping to Standard without stopping it.
- [ ] Scribe Soul guarantee is idempotent and the player performs the awakening action.
- [ ] The 5,000 minor resonance, Broken Watch, and tether 2 unlock exactly once.
- [ ] Two concurrent Reapings use the same simulation model.
- [ ] Provisions produce nothing while locked; unlock identifies available sources, starts them from zero, and does not backfill elapsed time.
- [ ] Non-Scribe discovery fallback prevents a softlock.
- [ ] Larder converts Provisions to Rations online and offline.
- [ ] Ration depletion reduces Soldier Company effect without stopping base production.
- [ ] The 10,000 regional resonance and reward fire exactly once.
- [ ] One optional Recollection can be purchased and changes a visible forecast or information result.
- [ ] Reaping Reports clear only presentation data.
- [ ] Eight-hour forecast and actual offline return use the same rules.
- [ ] Offline resolution crossing support, discovery, milestone, and backlog boundaries is deterministic.
- [ ] Tutorial can skip narrative, dismiss or replay concise Help guidance, resume after quit, tolerate early completion, and reach `TUT_13_COMPLETE` without corrupting progression.
- [ ] End state contains two active Reapings, two awakened Forms, one fielded Retinue, one active Hall chain, and Recollections.

## 19. Source mapping

| Requirement group | Originating source location |
|---|---|
| Prototype thesis, phases, end state, and non-goals | Prototype Brief §1, p. 3 |
| Onboarding guardrails and idle proof | Prototype Brief §2, p. 4 |
| Timeline and pacing scaffold | Prototype Brief §3, p. 5 |
| Detailed beat sequence, UI, actions, exits, and fail-safes | Prototype Brief §4, pp. 6–9 |
| Milestones, guarantees, and economy safeguards | Prototype Brief §5, p. 10 |
| Forms, Soldier Company, Thresholds, Halls, Recollections, and Writs | Prototype Brief §6, pp. 11–12 |
| Threshold and discovery states | Prototype Brief §7, p. 13 |
| Tutorial states, controller rules, and softlock audit | Prototype Brief §8, p. 14 |
| Screens and progressive disclosure | Prototype Brief §9, p. 15 |
| Simulation, entity data, reports, and save checkpoints | Prototype Brief §10, p. 16 |
| Narrative and asset requirements | Prototype Brief §11, p. 17 |
| Playtest events, comprehension, and acceptance | Prototype Brief §12, p. 18 |
| Original implementation breakdown | Prototype Brief §13, p. 19; informative only until Phase 7 milestone planning |
| Deferred systems | Prototype Brief §14, p. 20 |
| Canonical IDs and completion checklist | Prototype Brief §15, p. 21 |
| Persistent Reaping, settlement, support, and offline invariants | Idle Fork §§3–4 and §§9–10, pp. 5–6 and 11–13 |
| Soulweave topology and Form identity | Idle Fork §§11–12, pp. 14–16 |
| Retinue reservation and Hall ownership | Idle Fork §§13–14, pp. 17–18 |
| Emergency-to-Standard transition, two distinct resonances, player-driven Scribe awakening, and exclusion of the scripted four from persistent-Reaping counters | Project-owner decisions in this planning session, 12 July 2026 |
| External trusted-time authority, pending reconciliation when unavailable, and no local wall-clock fallback | Project-owner clarification in this planning session, 12 July 2026; implemented by `DEC-0021` |

## 20. Provisional values and unresolved details

The following remain configurable or open and must not be treated as permanent hard-coded design:

- base Reaping and Hall rates;
- cycle duration and tick cadence;
- costs for Archive, Weave, Muster, Scribe, Larder, recipe, and optional Recollections;
- required Essence floors and the 10,000 reward bundle;
- Man-at-Arms and Scribe Trait coefficients;
- Soldier Company effects and stacking order;
- starting Rations, consumption rate, warning threshold, and reduced-effect floor;
- Broken Watch backlog;
- Provisions and Form Soul frequencies;
- discovery cycle thresholds;
- Larder batch size, rate, and target beyond the prototype default of 50;
- onboarding buffer percentage;
- optional Recollection effects;
- Settled Passage rates;
- report cadence and retained history;
- exact 25,000-regional reward;
- general offline cap beyond required support for the eight-hour prototype path;
- final tutorial behavior when a mechanical guidance step is explicitly skipped, especially Scribe awakening, beyond the conservative no-auto-awaken rule in this document.

When a milestone needs a temporary value, place it in centralized content data, label it as prototype scaffold, test it, and avoid spreading the value across UI and simulation scripts.

## 21. Maintenance rule

When prototype behavior changes:

1. record the owner-approved decision in `docs/codex/DECISIONS.md` once available;
2. update the affected beat, guarantee, content contract, state table, and checklist here;
3. update the broader idle-fork document only when the change affects general product rules;
4. update data contracts, architecture, tests, milestone definitions, and prompts in the same pull request;
5. preserve requirement labels where possible so historical milestone and test references remain understandable;
6. mark replaced decisions as superseded rather than silently rewriting history.
