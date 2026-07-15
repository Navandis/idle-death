# M03 owner verification checklist

Run this checklist in Godot 4.7 against the same PR head used for `tools/test/owner/run_m03_owner_verification.ps1`.

## Root catalog

- Open `content/prototype_content_catalog.tres`.
- Confirm `content_revision = prototype-content-r1`.
- Confirm `compatible_save_revisions = [prototype-content-r1, prototype-m02]`.
- Confirm the Inspector shows typed groups (`items`, `forms`, `thresholds`, `output_channels`, `writs`, `retinues`, `halls`, `recipes`, `recollections`, `milestones`, `guarantees`, `resonances`, `tutorial_steps`, `narrative_identities`) rather than a generic definition array.

## Typed content spot checks

- Open `content/forms/FORM_MAN_AT_ARMS.tres` and `content/forms/FORM_SCRIBE.tres`; confirm stable Trait IDs `TRAIT_OLD_DRILL` and `TRAIT_UNCLOSED_LEDGER`, editable Trait names/descriptions, localization-key fields, and typed rate/modifier fields.
- Open `content/thresholds/THR_GLOAMWOOD.tres` and `content/thresholds/THR_BROKEN_WATCH.tres`; confirm exact IDs, tags, backlog, Settled multiplier, discovery state, and channel references.
- Open representative channels: `content/channels/CHANNEL_GLOAMWOOD_ESSENCE.tres`, `content/channels/CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS.tres`, and `content/channels/CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS.tres`; confirm typed source Threshold, output item, period, and progress-display fields.
- Open `content/retinues/RET_SOLDIER_COMPANY.tres`; confirm exactly twelve `SOUL_CALLING_SOLDIER`, support item `STORE_RATIONS`, and typed support/modifier fields.
- Open `content/halls/HALL_ARCHIVE.tres`, `content/halls/HALL_LARDER.tres`, and `content/recipes/RECIPE_LARDER_PROVISIONS_TO_RATIONS.tres`; confirm typed costs and recipe `10` Provisions to `10` Rations over `120000` ms with default target `50`.
- Open all five Recollections: `REC_WEAVE_REMEMBERED`, `REC_MUSTER_REMEMBERED`, `REC_QUICKER_RECKONING`, `REC_NAMES_KEPT`, `REC_OPEN_LEDGERS`; confirm editable names are independent of IDs.
- Open milestone, guarantee, resonance, tutorial, and narrative folders; confirm exact approved IDs and no replacement IDs such as `MILESTONE_...`, `GUARANTEE_...`, `TUT_OPENING`, or `RECIPE_PROVISIONS_TO_RATIONS` remain.
- Open `content/terminology/core_terms.tres`; confirm all twenty `TERM_...` entries, including editable `TERM_THRESHOLD`, `TERM_RECOLLECTION`, and `TERM_ESSENCE`.
- Confirm Essence-only naming: `RES_ESSENCE`, `CHANNEL_GLOAMWOOD_ESSENCE`, `CHANNEL_BROKEN_WATCH_ESSENCE`, and `TERM_ESSENCE`; no Corrupted Essence production identity or display term.
- Edit one provisional numeric field in the Inspector (do not save the branch) and confirm it is a typed field, not a dictionary key.
- Confirm the Output/Debugger panel has no new parser, import, or Resource errors.

## Result block

```text
Owner verification: PASS|FAIL — PR head <sha> — M03 Windows automation and Godot Inspector content review — YYYY-MM-DD.
Log: <filename>
Checklist: PASS|FAIL
Observed warnings or failures: <none or concise description>
```
