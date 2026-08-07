extends GutTest

func test_wrapper_precedence_and_result_grammar() -> void:
	var source := ReportLedger.create_empty(10)
	for row in [
		["null ledger", null, null, ReportLedgerIngestor.ERR_LEDGER_REQUIRED], ["invalid ledger", _invalid_ledger(), _run(SimulationRunService.MODE_DEBUG, _timeline(10, 10)), ReportLedgerIngestor.ERR_LEDGER_INVALID], ["null run", source, null, ReportLedgerIngestor.ERR_RUN_REQUIRED],
		["forecast", source, _run(SimulationRunService.MODE_FORECAST, _timeline(10, 10)), ReportLedgerIngestor.ERR_MODE_REJECTED], ["unknown mode", source, _run(&"UNKNOWN", _timeline(10, 10)), ReportLedgerIngestor.ERR_MODE_REJECTED],
		["failed committed", source, SimulationRunService.SimulationRunResult.new(false, SimulationRunService.MODE_DEBUG, &"E", "", 0, 10, 10, null, null), ReportLedgerIngestor.ERR_RUN_FAILED],
		["projected", source, _run(SimulationRunService.MODE_DEBUG, _timeline(10, 10), GameState.new(0)), ReportLedgerIngestor.ERR_PROJECTED], ["null inner", source, _run(SimulationRunService.MODE_DEBUG, null), ReportLedgerIngestor.ERR_WRAPPER],
		["requested parity", source, _run(SimulationRunService.MODE_DEBUG, _timeline(10, 10), null, 1), ReportLedgerIngestor.ERR_WRAPPER], ["result grammar", source, _run(SimulationRunService.MODE_DEBUG, SimulationResult.timeline_only(1, -1, 0, "r")), ReportLedgerIngestor.ERR_RESULT_INVALID]
	]:
		var result := ReportLedgerIngestor.ingest_committed_run(row[1], row[2])
		assert_eq(result.error_code, row[3], row[0]); assert_eq(result.outcome, ReportLedgerIngestResult.REJECTED, row[0]); assert_false(result.success, row[0]); assert_false(result.changed, row[0]); assert_null(result.candidate_ledger, row[0]); assert_ne(result.developer_details, "", row[0])

func test_all_committed_modes_and_complete_interval_matrix_are_transactional() -> void:
	for mode in SimulationRunService.COMMITTED_MODES:
		var applied := ReportLedgerIngestor.ingest_committed_run(ReportLedger.create_empty(0), _run(mode, _timeline(0, 10)))
		assert_eq(applied.outcome, ReportLedgerIngestResult.APPLIED, "committed mode %s" % mode)
		assert_eq(applied.candidate_ledger.get({&"FOREGROUND_SUPPLIED": "foreground_elapsed_msec", &"OFFLINE_FIXTURE": "offline_elapsed_msec", &"DEBUG": "debug_elapsed_msec"}[mode]), 10, "mode coverage %s" % mode)
	var source := ReportLedger.create_empty(10); var before := source.deep_clone()
	for row in [["zero at", 10, 10, ReportLedgerIngestResult.ZERO_DURATION_NO_OP], ["zero behind", 9, 9, ReportLedgerIngestResult.DUPLICATE_NO_OP], ["zero ahead", 11, 11, ReportLedgerIngestor.ERR_GAP], ["covered positive", 0, 10, ReportLedgerIngestResult.DUPLICATE_NO_OP], ["partial overlap", 9, 11, ReportLedgerIngestor.ERR_OVERLAP], ["forward gap", 11, 20, ReportLedgerIngestor.ERR_GAP], ["exact new", 10, 20, ReportLedgerIngestResult.APPLIED]]:
		var result := ReportLedgerIngestor.ingest_committed_run(source, _run(SimulationRunService.MODE_FOREGROUND_SUPPLIED, _timeline(row[1], row[2])))
		assert_eq(result.outcome if result.error_code.is_empty() else result.error_code, row[3], row[0]); assert_true(source.value_equals(before), "source unchanged %s" % row[0])

func test_each_wrapper_parity_mismatch_and_malformed_covered_input_reject_first() -> void:
	for row in [["baseline", func(run): run.baseline_simulation_time_msec = 9], ["result cursor", func(run): run.result_simulation_time_msec = 21], ["requested", func(run): run.requested_elapsed_msec = 9]]:
		var run := _run(SimulationRunService.MODE_DEBUG, _timeline(10, 20)); row[1].call(run)
		assert_eq(ReportLedgerIngestor.ingest_committed_run(ReportLedger.create_empty(20), run).error_code, ReportLedgerIngestor.ERR_WRAPPER, row[0])
	var malformed := SimulationResult.timeline_only(10, -1, 9, "r")
	assert_eq(ReportLedgerIngestor.ingest_committed_run(ReportLedger.create_empty(20), _run(SimulationRunService.MODE_DEBUG, malformed)).error_code, ReportLedgerIngestor.ERR_RESULT_INVALID, "malformed covered input precedes duplicate")

func _timeline(start: int, finish: int) -> SimulationResult:
	return SimulationResult.zero_duration(start) if start == finish else SimulationResult.timeline_only(finish - start, start, finish, "r")

func _run(mode: StringName, inner: SimulationResult, projection: GameState = null, requested_override: int = -1) -> SimulationRunService.SimulationRunResult:
	var requested := requested_override if requested_override >= 0 else (0 if inner == null else inner.requested_elapsed_msec)
	var start := 10 if inner == null else inner.baseline_simulation_time_msec; var finish := 10 if inner == null else inner.result_simulation_time_msec
	return SimulationRunService.SimulationRunResult.new(true, mode, &"", "", requested, start, finish, inner, projection)

func _invalid_ledger() -> ReportLedger:
	var value := ReportLedger.create_empty(10); value.next_event_sequence = 0; return value
