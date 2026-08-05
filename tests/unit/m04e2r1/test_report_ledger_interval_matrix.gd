extends GutTest

func test_interval_decision_matrix_and_precedence() -> void:
	var source := ReportLedger.create_empty(100)
	assert_eq(ReportLedgerIngestor.ingest_committed_run(source, _timeline(100, 100)).outcome, ReportLedgerIngestResult.ZERO_DURATION_NO_OP)
	assert_eq(ReportLedgerIngestor.ingest_committed_run(source, _timeline(99, 99)).outcome, ReportLedgerIngestResult.DUPLICATE_NO_OP)
	var ahead := ReportLedgerIngestor.ingest_committed_run(source, _timeline(101, 101))
	assert_eq(ahead.error_code, ReportLedgerIngestor.ERR_GAP)
	assert_eq(ReportLedgerIngestor.ingest_committed_run(source, _timeline(90, 100)).outcome, ReportLedgerIngestResult.DUPLICATE_NO_OP)
	assert_eq(ReportLedgerIngestor.ingest_committed_run(source, _timeline(90, 110)).error_code, ReportLedgerIngestor.ERR_OVERLAP)
	assert_eq(ReportLedgerIngestor.ingest_committed_run(source, _timeline(101, 110)).error_code, ReportLedgerIngestor.ERR_GAP)
	var applied := ReportLedgerIngestor.ingest_committed_run(source, _timeline(100, 110))
	assert_true(applied.success)
	assert_eq(applied.candidate_ledger.ingested_through_simulation_msec, 110)
	assert_eq(applied.candidate_ledger.foreground_elapsed_msec, 10)
	assert_true(source.value_equals(ReportLedger.create_empty(100)))
	var failed := SimulationRunService.SimulationRunResult.new(false, SimulationRunService.MODE_FORECAST, &"ERR", "", 0, 100, 100, null, null)
	assert_eq(ReportLedgerIngestor.ingest_committed_run(source, failed).error_code, ReportLedgerIngestor.ERR_MODE_REJECTED)

func test_parity_correct_negative_baseline_uses_result_invalid_precedence() -> void:
	var source := ReportLedger.create_empty(0)
	var source_before := source.deep_clone()
	var inner := SimulationResult.timeline_only(10, -5, 5, ContentRegistry.CURRENT_REVISION)
	var run := SimulationRunService.SimulationRunResult.new(true, SimulationRunService.MODE_FOREGROUND_SUPPLIED, &"", "", 10, -5, 5, inner, null)
	var result := ReportLedgerIngestor.ingest_committed_run(source, run)
	assert_eq(result.error_code, ReportLedgerIngestor.ERR_RESULT_INVALID)
	assert_eq(result.outcome, ReportLedgerIngestResult.REJECTED)
	assert_false(result.success)
	assert_false(result.changed)
	assert_ne(result.developer_details, "")
	assert_null(result.candidate_ledger)
	assert_true(source.value_equals(source_before))

func test_rejections_have_exact_result_shape() -> void:
	var rejected := ReportLedgerIngestor.ingest_committed_run(null, null)
	assert_false(rejected.success)
	assert_false(rejected.changed)
	assert_eq(rejected.outcome, ReportLedgerIngestResult.REJECTED)
	assert_ne(rejected.error_code, &"")
	assert_ne(rejected.developer_details, "")
	assert_null(rejected.candidate_ledger)

func _timeline(start: int, finish: int) -> SimulationRunService.SimulationRunResult:
	var inner := SimulationResult.zero_duration(start) if start == finish else SimulationResult.timeline_only(finish - start, start, finish, ContentRegistry.CURRENT_REVISION)
	return SimulationRunService.SimulationRunResult.new(true, SimulationRunService.MODE_FOREGROUND_SUPPLIED, &"", "", finish - start, start, finish, inner, null)
