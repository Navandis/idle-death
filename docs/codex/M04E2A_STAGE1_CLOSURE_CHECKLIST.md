# M04E2A Stage 1 Closure Checklist

**Scope:** authoritative report-state persistence, schema-v4 validation, mapper parity, and full-suite recovery.

This checklist records the durable Stage 1 validation contract applied before M04E2A proceeds to later closure stages. It does not add M04E2B atomic coordination, UI, trusted time, Codex analytics, or new report features.

## Integer-domain rules

| Rule | Stage 1 requirement |
|---|---|
| Default integer domain | Non-negative unless a field is explicitly listed as signed. |
| Positive-only fields | `next_report_sequence`, `next_event_sequence`, `report_sequence`, `event_sequence`, and `assignment_revision` must be greater than zero. |
| Signed opt-in | Only `AttributionSlice.backlog_delta` is signed; it preserves the existing meaning `remaining_backlog_after - remaining_backlog_before`, so ordinary Overdue progress is negative. |
| Mapper/validator parity | The schema validator and runtime mapper must parse each persisted integer using the same signedness decision. |
| Failed parse handling | Invalid persisted source data must fail validation before runtime mapping; mappers must not silently reinterpret malformed or negative unsigned values as zero. |

## Propagation checklist for report fields

Every persisted report field must be represented in each applicable layer:

1. Runtime declaration in `ReportState`.
2. Constructor/default initialization.
3. Deep clone and `GameState.copy_from()` detachment.
4. Runtime validation through `GameStateValidator.validate_report_state()`.
5. Schema-v4 exact key set.
6. Schema-v4 primitive, enum, ordering, bound, and cross-field validation.
7. Mapper write and read parity.
8. Sequential v3 → v4 migration, when introduced by migration rather than gameplay.
9. Current-v4 load without rewrite/rotation.
10. Public read exposure where presentation/history consumers need the field.
11. Focused regression tests or table-driven mutation-matrix coverage.

## Required mutation categories

A schema-v4 mutation matrix must reject each category before runtime mapping and must preserve the invalid source bytes/state for diagnosis:

- missing key;
- extra key;
- wrong primitive type;
- null nested object;
- empty ID;
- negative unsigned field;
- zero positive-only sequence/revision;
- overflow or malformed integer string;
- unknown reason or mode token;
- non-string Retinue ID;
- malformed map value;
- malformed channel summary;
- malformed event detail;
- oversized history or event detail collection;
- report cursor beyond simulation;
- unsorted or duplicate identity where ordering is part of the persisted contract.

## Verification commands

Before Stage 1 is review-ready, run:

```bash
./tools/test/run_gut.sh -- \
  -gdir=res://tests/unit/m04a \
  -gdir=res://tests/unit/persistence \
  -gdir=res://tests/integration/m04a \
  -gdir=res://tests/integration/m04e2a \
  -gdir=res://tests/integration/save_load

./tools/test/run_gut.sh
godot --headless --path . --import
git diff --check
git status --short
```

The full suite must pass. Stage 2 is the only suggested follow-up task after this checklist is satisfied.
