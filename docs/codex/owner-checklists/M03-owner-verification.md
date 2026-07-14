# M03 owner verification checklist

Inspect these resources in Godot 4.7 and confirm typed exported fields are editable without parser/import errors:

- `content/prototype_content_catalog.tres`: `content_revision = prototype-content-r1`, compatible revisions `prototype-content-r1`, `prototype-m02`, explicit definition groups.
- `content/forms/FORM_MAN_AT_ARMS.tres` and `content/forms/FORM_SCRIBE.tres`: stable `TRAIT_OLD_DRILL` / `TRAIT_UNCLOSED_LEDGER`, editable names, localization key fields.
- `content/thresholds/THR_GLOAMWOOD_HAMLET.tres` and `content/thresholds/THR_BROKEN_WATCH.tres`: tags, backlog, channel IDs.
- `content/channels/CHANNEL_GLOAMWOOD_ESSENCE.tres`, `content/channels/CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS.tres`, `content/channels/CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS.tres`: item references and periods.
- `content/retinues/RET_SOLDIER_COMPANY.tres`: exactly 12 Soldier Souls.
- `content/halls/HALL_ARCHIVE.tres`, `content/halls/HALL_LARDER.tres`, `content/recipes/RECIPE_PROVISIONS_TO_RATIONS.tres`.
- `content/recollections/REC_FIRST_SEAL_RESONANCE.tres` and `content/recollections/REC_LEDGER_MARGINALIA.tres`: editable display names independent of IDs.
- `content/terminology/core_terms.tres`: `TERM_THRESHOLD`, `TERM_RECOLLECTION`, `TERM_ESSENCE`.
- `content/milestones/`, `content/guarantees/`, `content/resonances/`, `content/tutorial_states/`, and `content/narrative_identitys/` definitions.
- Output/Debugger has no new import, parser, or Resource errors.

Result block:

```text
Owner verification: PASS|FAIL — PR head <sha> — M03 Windows automation and Godot Inspector content review — YYYY-MM-DD.
Log: <filename>
Checklist: PASS|FAIL
Observed warnings or failures: <none or concise description>
```
