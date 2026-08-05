# Death Idle G3 — M04E2R1 Planning v0.3

**Status:** Owner-approved 2026-08-05.
**Decision:** `DEC-0046` — caller-owned chunk-invariant report ledger and exact committed-run ingestion.

## Principal transition

```text
caller-owned validated ledger + finalized committed run
-> private normalized candidate
-> complete ledger validation
-> APPLIED candidate or transactional no-op/rejection
```

R1 introduces one non-persisted `ReportLedger` aggregate. It consumes only successful committed `SimulationRunService.SimulationRunResult` wrappers, retains no application/global state, and does not change schema version 3 or the current content revision.

## Runtime contract

`ReportLedger` stores window start, ingestion cursor, three mode-duration fields, next event sequence, `ReportLedgerSlice[]`, and `ReportSettlementEvent[]`.

Each slice stores mode/content/Threshold/revision/full component identity/lifecycle, half-open interval, core deltas/backlog endpoints, and `ReportLedgerChannel[]`. A channel stores its ID/output identity, interval, progress endpoints, period, carry endpoints, and total-banked endpoints. A Settlement event stores sequence/content/Threshold/revision/occurrence/persistent return total.

Only cursor/coverage/identity/endpoints/events are stored. Elapsed values, reductions, banked deltas, totals, summaries, history, retention, snapshots, read models, persistence, migration, and combined gameplay/report candidates are derived or deferred to R2/P1/B.

## API and result grammar

```text
ReportLedger.create_empty(start_simulation_msec) -> ReportLedger | null
ReportLedger.deep_clone() -> ReportLedger
ReportLedger.value_equals(other) -> bool
ReportLedgerValidator.validate(ledger) -> { ok, code, details }
ReportLedgerIngestor.ingest_committed_run(source_ledger, run) -> ReportLedgerIngestResult
```

Validator success is exactly `{ "ok": true, "code": &"", "details": "" }`; failure uses `REPORT_LEDGER_VALIDATION_FAILED`. Ingestion outcomes are `APPLIED`, `DUPLICATE_NO_OP`, `ZERO_DURATION_NO_OP`, and `REJECTED`. Only `APPLIED` returns a candidate. Stable rejection codes are the fifteen `REPORT_INGEST_*` codes approved in the packet.

## Boundary rules

The wrapper validates in this order: source required/valid, run required, committed mode, successful wrapper, no projected state, non-null/parity-correct inner result, T2 result validation, then interval classification. Exact-new positive intervals clone once, increment one mode coverage with checked arithmetic, normalize segments/events, advance the cursor, and validate the candidate.

Duplicates and zero-duration intervals do not mutate. Forward gaps and partial overlaps reject; no overlap slicing, rebasing, recovery, or interval-ID set is permitted. Active source continuity is independent of merge eligibility: component identity, backlog/lifecycle, required channel presence/output/period/endpoints, and one Settlement per Threshold continue across mode/content/revision/timeline splits. Equivalent same-mode chunking must produce value-equal ledgers.

## Explicit exclusions

R1 excludes `GameState` ownership, schema v4, mappers/migrations/fixtures/save-load, snapshots/history/retention/reads/UI, trusted-time orchestration, service/singleton/global retention, simulation changes, and atomic coordination. R2 owns snapshot/read/retention, P1 owns persistence, and B owns atomic gameplay/report application.
