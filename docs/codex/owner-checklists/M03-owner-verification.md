# M03 owner verification checklist

Run this checklist in Godot 4.7 against the same PR head used for `tools/test/owner/run_m03_owner_verification.ps1`.

## Root catalog

- Open `content/prototype_content_catalog.tres`.
- Confirm `content_revision = prototype-content-r1`.
- Confirm `compatible_save_revisions = [prototype-content-r1, prototype-m02]`.
- Confirm the Inspector shows typed groups (`items`, `forms`, `thresholds`, `output_channels`, `writs`, `retinues`, `halls`, `recipes`, `recollections`, `milestones`, `guarantees`, `resonances`, `tutorial_steps`, `narrative_identities`) rather than a generic definition array.

## Typed content spot checks

- Open `content/thresholds/THR_GLOAMWOOD.tres`; confirm `display_name = Gloamwood Hamlet`, `standing_backlog = 1000000`, tags `TAG_FOREST` and `TAG_SETTLEMENT`, Settled multiplier `0.25`, and the three Gloamwood channel references.
- Open `content/thresholds/THR_BROKEN_WATCH.tres`; confirm `display_name = Broken Watch`, `standing_backlog = 250000`, tags `TAG_ROAD`, `TAG_SETTLEMENT`, and `TAG_MARTIAL`, Settled multiplier `0.25`, and the three Broken Watch channel references.
- Open all six files under `content/channels/`; confirm each has typed fields `initial_discovery_state`, `frequency_tier`, `identified_frequency_label`, `frequency_localization_key`, and `show_acquisition_progress` instead of a hidden/display ambiguity:
  - `CHANNEL_GLOAMWOOD_ESSENCE`: `CHARTED`, `NONE`, no label, progress false.
  - `CHANNEL_GLOAMWOOD_SOLDIER_SOULS`: `UNKNOWN`, `COMMON`, `Common source`, progress false.
  - `CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS`: `UNKNOWN`, `UNCOMMON`, `Uncommon source`, progress true.
  - `CHANNEL_BROKEN_WATCH_ESSENCE`: `CHARTED`, `NONE`, no label, progress false.
  - `CHANNEL_BROKEN_WATCH_PROVISIONS`: `UNKNOWN`, `COMMON`, `Common source`, progress false.
  - `CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS`: `UNKNOWN`, `UNCOMMON`, `Uncommon source`, progress true.
- Open `content/forms/FORM_MAN_AT_ARMS.tres` and `content/forms/FORM_SCRIBE.tres`; confirm stable Trait IDs `TRAIT_OLD_DRILL` and `TRAIT_UNCLOSED_LEDGER`, editable Trait names/descriptions, localization-key fields, and typed rate/modifier fields. Confirm Old Drill's returned-soul modifier has condition values `TAG_SETTLEMENT`, `TAG_MARTIAL`, and its Retinue modifier has `MARTIAL`. Confirm Unclosed Ledger is `DISCOVERY_RATE ×2.0` and `FORECAST_UNCERTAINTY ×0.50`.
- Open `content/retinues/RET_SOLDIER_COMPANY.tres`; confirm exactly twelve `SOUL_CALLING_SOLDIER`, support item `STORE_RATIONS`, one Ration per `300000` ms, reduced support floor `0.50`, slot category `MARTIAL`, and the own-contribution modifier condition value `MARTIAL`.
- Open `content/recollections/REC_NAMES_KEPT.tres`; confirm the modifier is `OUTPUT_CHANNEL_RATE`, `MULTIPLY`, scope `OUTPUT_CHANNEL`, condition `OUTPUT_KIND`, condition value `WHOLE_SOUL`, and value `1.10`.
- Open `content/halls/HALL_ARCHIVE.tres`, `content/halls/HALL_LARDER.tres`, and `content/recipes/RECIPE_LARDER_PROVISIONS_TO_RATIONS.tres`; confirm typed costs and recipe `10` Provisions to `10` Rations over `120000` ms with default target `50`.
- Open all six milestones; confirm exact mapping:
  - `MS_GLOAMWOOD_REAPING_1000`: guarantees `GUA_SOLDIER_SOULS_12`, `GUA_MUSTER_COST_FLOOR`.
  - `MS_GLOAMWOOD_REAPING_2500`: no prerequisite, guarantees `GUA_SCRIBE_SOUL_1`, `GUA_SCRIBE_AWAKENING_COST_FLOOR`.
  - `MS_GLOAMWOOD_REAPING_5000`: no guarantee, required awakened Form `FORM_SCRIBE`, resonance `RESONANCE_GLOAMWOOD_5000_MINOR`.
  - `MS_REGION_REAPING_10000`: resonance `RESONANCE_REGION_10000`, no Scribe guarantees.
  - `MS_REGION_REAPING_25000`: enabled scaffold with no mandatory reward.
  - `MS_THRESHOLD_FIRST_SETTLEMENT`: empty subject means first eligible Threshold; no artificial Gloamwood prerequisite.
- Open all six guarantees; confirm fixed guarantees use `minimum_amount`, while derived guarantees use `source_definition_ids`:
  - Archive/Weave sources: `HALL_ARCHIVE`, `REC_WEAVE_REMEMBERED`.
  - Muster source: `REC_MUSTER_REMEMBERED`.
  - Scribe awakening source: `FORM_SCRIBE`.
  - Provisions onboarding sources: `HALL_LARDER`, `RECIPE_LARDER_PROVISIONS_TO_RATIONS`, policy `LARDER_RESTORE_PLUS_FIRST_BATCH_AND_BUFFER`, buffer `1.20`.
- Dynamic derived-preview check: do not expect a guarantee `.tres` file to mutate automatically. Instead, run the M03 trace or a copied catalog fixture after temporarily changing `REC_MUSTER_REMEMBERED` Essence cost from `25` to `30`; the rebuilt registry should report `GUA_MUSTER_COST_FLOOR` preview `30`. Revert the local edit afterward and do not commit it.
- Open both Resonances; confirm `RESONANCE_GLOAMWOOD_5000_MINOR` has separate effects `RECORD_RESONANCE -> RESONANCE_GLOAMWOOD_5000_MINOR`, `UNLOCK_THRESHOLD -> THR_BROKEN_WATCH`, and `ADD_COMMAND_TETHERS -> 1`. Confirm `RESONANCE_REGION_10000` grants `50 RES_ESSENCE`, records itself, and exposes `REC_QUICKER_RECKONING`, `REC_NAMES_KEPT`, and `REC_OPEN_LEDGERS`.
- Open all five Recollections: `REC_WEAVE_REMEMBERED`, `REC_MUSTER_REMEMBERED`, `REC_QUICKER_RECKONING`, `REC_NAMES_KEPT`, `REC_OPEN_LEDGERS`; confirm editable names are independent of IDs.
- Open milestone, guarantee, resonance, tutorial, and narrative folders; confirm exact approved IDs and no replacement IDs such as `MILESTONE_...`, `GUARANTEE_...`, `TUT_OPENING`, or `RECIPE_PROVISIONS_TO_RATIONS` remain.
- Open `content/terminology/core_terms.tres`; confirm all twenty `TERM_...` entries expose `singular_display_name`, `plural_display_name`, `singular_localization_key`, `plural_localization_key`, and `notes`. Confirm `TERM_THRESHOLD` singular/plural text is editable without changing `THR_...` IDs.
- Confirm Essence-only naming: `RES_ESSENCE`, `CHANNEL_GLOAMWOOD_ESSENCE`, `CHANNEL_BROKEN_WATCH_ESSENCE`, and `TERM_ESSENCE`; no Corrupted Essence production identity or display term.
- Edit one provisional numeric field in the Inspector (do not save the branch) and confirm it is a typed field, not a dictionary key.
- Confirm the Output/Debugger panel has no new parser, import, or Resource errors.

## Result block

Select and report one result for the corrected PR head:

```text
Owner verification: PASS|FAIL — PR head <sha> — M03 Windows automation and Godot Inspector content review — YYYY-MM-DD.
Log: <filename>
Checklist: PASS|FAIL
Observed warnings or failures: <none or concise description>
```
