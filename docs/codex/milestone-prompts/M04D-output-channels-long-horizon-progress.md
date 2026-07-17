# Superseded implementation slice M04D: Output channels and long-horizon acquisition progress

**Prompt version:** v0.1  
**Prompt date:** 2026-07-17  
**Prompt status:** Superseded  
**Work item type:** Historical draft; do not execute  
**Superseded by:** M04D1, M04D2, and M04D3 under accepted `DEC-0037`

> Do not submit this prompt to Codex. Its hidden pre-unlock banking rule and single-pull-request scope were rejected during owner review.

## Supersession reason

The original draft conflated three independent concerns:

1. global mechanical access to an output item;
2. knowledge and insight about its available sources;
3. elapsed accumulation and later rate-context changes.

It also allowed Unknown progression-gated channels to accumulate before unlock, which made unlock timing economically irrelevant and could place unexplained items in inventory.

Accepted `DEC-0037` replaces that model with:

- global prospective item access;
- no pre-unlock progress or retroactive backfill;
- identification of all currently available sources at unlock;
- no disclosure of unavailable Thresholds;
- no deadlines, permanent lockouts, or late-unlock baseline penalties;
- schema version 3;
- three reviewable implementation slices.

## Replacement prompts

| Slice | Prompt |
|---|---|
| M04D1 | `docs/codex/milestone-prompts/M04D1-output-access-source-identification-foundation.md` |
| M04D2 | `docs/codex/milestone-prompts/M04D2-discrete-channel-accumulation-banking.md` — not yet drafted |
| M04D3 | `docs/codex/milestone-prompts/M04D3-compatible-rate-context-and-acquisition-queries.md` — not yet drafted |

This file is retained as historical governance evidence only.
