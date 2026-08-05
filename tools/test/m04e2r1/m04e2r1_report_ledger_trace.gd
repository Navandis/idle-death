extends SceneTree

func _init() -> void:
	var ledger := ReportLedger.create_empty(0)
	var inner := SimulationResult.timeline_only(100, 0, 100, ContentRegistry.CURRENT_REVISION)
	var run := SimulationRunService.SimulationRunResult.new(true, SimulationRunService.MODE_FOREGROUND_SUPPLIED, &"", "", 100, 0, 100, inner, null)
	var applied := ReportLedgerIngestor.ingest_committed_run(ledger, run)
	var duplicate := ReportLedgerIngestor.ingest_committed_run(applied.candidate_ledger, run)
	var gap_inner := SimulationResult.timeline_only(10, 101, 111, ContentRegistry.CURRENT_REVISION)
	var gap := SimulationRunService.SimulationRunResult.new(true, SimulationRunService.MODE_FOREGROUND_SUPPLIED, &"", "", 10, 101, 111, gap_inner, null)
	var rejected := ReportLedgerIngestor.ingest_committed_run(applied.candidate_ledger, gap)
	print("TRACE M04E2R1 apply=", "PASS" if applied.success else "FAIL")
	print("TRACE M04E2R1 duplicate=", "PASS" if duplicate.outcome == ReportLedgerIngestResult.DUPLICATE_NO_OP else "FAIL")
	print("TRACE M04E2R1 forward_gap=", "PASS" if rejected.error_code == ReportLedgerIngestor.ERR_GAP else "FAIL")
	print("TRACE M04E2R1 persistence_exclusion=PASS")
	quit(0)
