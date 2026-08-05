# Slice M04E2R1: Normalized live report ledger and committed-run ingestion

**Packet version/date:** v0.3 — 2026-08-05
**Status:** Owner-approved executable packet
**Baseline:** `main` at `6d2e9247322798cb040659bc9c98b650d24ab69e`
**Branch:** `codex/m04e2r1-normalized-live-report-ledger`

Implement exactly one typed caller-owned non-persisted `ReportLedger` and stateless ingestion boundary. The principal transition is a validated source ledger plus one finalized committed run becoming a complete detached normalized candidate, or a transactional no-op/rejection. Schema remains v3.

The exact API is `ReportLedger.create_empty`, `deep_clone`, `value_equals`, `ReportLedgerValidator.validate`, and `ReportLedgerIngestor.ingest_committed_run`. The wrapper validation order, half-open interval table, stable `REPORT_INGEST_*` errors, stored field lists, canonical maximality, source/channel continuity, folded bank events, unique normalized Settlement events, checked arithmetic, no-alias transactionality, and chunk invariance are defined by `M04E2R1_PLANNING.md` and `DEC-0046`.

The exact allowed changed-path set is the five maintained codex documents, this packet, `M04E2R1_PLANNING.md`, seven `src/reports` scripts with UID companions, three unit suites with UID companions, one integration suite with UID companion, one trace with UID companion, and `tools/test/owner/run_m04e2r1_owner_verification.ps1`: 32 paths total. Do not add `GameState`, persistence, read/history, UI, service/global, simulation, or coordinator paths.

Acceptance requires focused/full GUT, import, smoke, deterministic trace, artifact/diff audit, schema-v3 exclusion proof, exact-head CI, and the pending exact-head Windows owner runner. Publish one non-force PR and stop without merge or owner administration.
