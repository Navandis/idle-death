extends GutTest

func test_wrapper_precedence_and_result_grammar() -> void:
	var source := ReportLedger.create_empty(10)
	for row in [
		["null ledger", null, null, ReportLedgerIngestor.ERR_LEDGER_REQUIRED],
		["invalid ledger", _invalid_ledger(), _run(SimulationRunService.MODE_DEBUG, _timeline(10, 10)), ReportLedgerIngestor.ERR_LEDGER_INVALID],
		["null run", source, null, ReportLedgerIngestor.ERR_RUN_REQUIRED],
		["forecast", source, _run(SimulationRunService.MODE_FORECAST, _timeline(10, 10)), ReportLedgerIngestor.ERR_MODE_REJECTED],
		["unknown mode", source, _run(&"UNKNOWN", _timeline(10, 10)), ReportLedgerIngestor.ERR_MODE_REJECTED],
		["failed committed", source, SimulationRunService.SimulationRunResult.new(false, SimulationRunService.MODE_DEBUG, &"E", "", 0, 10, 10, null, null), ReportLedgerIngestor.ERR_RUN_FAILED],
		["projected", source, _run(SimulationRunService.MODE_DEBUG, _timeline(10, 10), GameState.new(0)), ReportLedgerIngestor.ERR_PROJECTED],
		["null inner", source, _run(SimulationRunService.MODE_DEBUG, null), ReportLedgerIngestor.ERR_WRAPPER],
		["requested parity", source, _run(SimulationRunService.MODE_DEBUG, _timeline(10, 10), null, 1), ReportLedgerIngestor.ERR_WRAPPER],
		["result grammar", source, _run(SimulationRunService.MODE_DEBUG, SimulationResult.timeline_only(1, -1, 0, "r")), ReportLedgerIngestor.ERR_RESULT_INVALID]
	]:
		var result := ReportLedgerIngestor.ingest_committed_run(row[1], row[2])
		assert_eq(result.error_code, row[3], row[0])
		assert_eq(result.outcome, ReportLedgerIngestResult.REJECTED, row[0])
		assert_false(result.success, row[0])
		assert_false(result.changed, row[0])
		assert_null(result.candidate_ledger, row[0])
		assert_ne(result.developer_details, "", row[0])

func test_all_committed_modes_and_complete_interval_matrix_are_transactional() -> void:
	for mode in SimulationRunService.COMMITTED_MODES:
		var applied := ReportLedgerIngestor.ingest_committed_run(ReportLedger.create_empty(0), _run(mode, _timeline(0, 10)))
		assert_eq(applied.outcome, ReportLedgerIngestResult.APPLIED, "committed mode %s" % mode)
		assert_eq(applied.candidate_ledger.get({&"FOREGROUND_SUPPLIED": "foreground_elapsed_msec", &"OFFLINE_FIXTURE": "offline_elapsed_msec", &"DEBUG": "debug_elapsed_msec"}[mode]), 10, "mode coverage %s" % mode)
	var source := ReportLedger.create_empty(10)
	var before := source.deep_clone()
	var intervals := [
		["zero at", 10, 10, ReportLedgerIngestResult.ZERO_DURATION_NO_OP],
		["zero behind", 9, 9, ReportLedgerIngestResult.DUPLICATE_NO_OP],
		["zero ahead", 11, 11, ReportLedgerIngestor.ERR_GAP],
		["covered positive", 0, 10, ReportLedgerIngestResult.DUPLICATE_NO_OP],
		["partial overlap", 9, 11, ReportLedgerIngestor.ERR_OVERLAP],
		["forward gap", 11, 20, ReportLedgerIngestor.ERR_GAP],
		["exact new", 10, 20, ReportLedgerIngestResult.APPLIED]
	]
	for row in intervals:
		var result := ReportLedgerIngestor.ingest_committed_run(source, _run(SimulationRunService.MODE_FOREGROUND_SUPPLIED, _timeline(row[1], row[2])))
		assert_eq(result.outcome if result.error_code.is_empty() else result.error_code, row[3], row[0])
		assert_true(source.value_equals(before), "source unchanged %s" % row[0])

func test_each_wrapper_parity_mismatch_and_malformed_covered_input_reject_first() -> void:
	for row in [["baseline", func(run): run.baseline_simulation_time_msec = 9], ["result cursor", func(run): run.result_simulation_time_msec = 21], ["requested", func(run): run.requested_elapsed_msec = 9]]:
		var run := _run(SimulationRunService.MODE_DEBUG, _timeline(10, 20))
		row[1].call(run)
		assert_eq(ReportLedgerIngestor.ingest_committed_run(ReportLedger.create_empty(20), run).error_code, ReportLedgerIngestor.ERR_WRAPPER, row[0])
	var malformed := SimulationResult.timeline_only(10, -1, 9, "r")
	assert_eq(ReportLedgerIngestor.ingest_committed_run(ReportLedger.create_empty(20), _run(SimulationRunService.MODE_DEBUG, malformed)).error_code, ReportLedgerIngestor.ERR_RESULT_INVALID, "malformed covered input precedes duplicate")

func test_exact_six_wrapper_parity_truth_vectors_preserve_every_input() -> void:
	var rows := [
		_parity("P-01", [false, true, true, true, true, true], 10, 9, 10, 10, 10, 20, 20, true, true),
		_parity("P-02", [true, false, true, true, true, true], 10, 10, 9, 10, 10, 19, 19, true, true),
		_parity("P-03", [true, true, false, true, true, true], 10, 10, 10, 9, 10, 19, 19, true, true),
		_parity("P-04", [true, true, true, false, true, true], 10, 10, 10, 10, 10, 20, 19, true, true),
		_parity("P-05", [true, true, true, true, false, true], 10, 10, 10, 10, 10, 20, 20, true, false),
		_parity("P-06", [true, true, true, true, true, false], 10, 10, 10, 10, 10, 19, 19, true, true)
	]
	var ids: Array[String] = []
	for row in rows:
		ids.append(row.id)
		var inner := _raw_inner(row.inner_requested, row.inner_committed, row.inner_baseline, row.inner_result, row.inner_success)
		var run := SimulationRunService.SimulationRunResult.new(row.run_success, SimulationRunService.MODE_DEBUG, &"", "", row.run_requested, row.run_baseline, row.run_result, inner, null)
		var predicates := _parity_predicates(run, inner)
		assert_eq(predicates, row.expected, "%s exact truth vector" % row.id)
		assert_eq(predicates.count(false), 1, "%s exactly one false predicate" % row.id)
		var source := ReportLedger.create_empty(10)
		var source_snapshot := source.deep_clone()
		var wrapper_snapshot := _wrapper_snapshot(run)
		var inner_snapshot := inner.detached_copy()
		var result := ReportLedgerIngestor.ingest_committed_run(source, run)
		assert_eq(result.outcome, ReportLedgerIngestResult.REJECTED, "%s rejected outcome" % row.id)
		assert_false(result.success, "%s rejected success" % row.id)
		assert_false(result.changed, "%s rejected changed" % row.id)
		assert_eq(result.error_code, ReportLedgerIngestor.ERR_WRAPPER, "%s rejects wrapper" % row.id)
		assert_ne(result.developer_details, "", "%s rejected details" % row.id)
		assert_null(result.candidate_ledger, "%s rejected candidate" % row.id)
		assert_true(_is_rejected_shape(result), "%s rejected grammar" % row.id)
		assert_true(source.value_equals(source_snapshot), "%s source unchanged" % row.id)
		assert_eq(_wrapper_snapshot(run), wrapper_snapshot, "%s every wrapper field unchanged" % row.id)
		assert_eq(run.simulation_result, wrapper_snapshot.simulation_result, "%s inner reference unchanged" % row.id)
		assert_eq(run.projected_state, wrapper_snapshot.projected_state, "%s projection reference unchanged" % row.id)
		assert_true(inner.value_equals(inner_snapshot), "%s inner, segments, channels, events unchanged" % row.id)
	assert_eq(ids, ["P-01", "P-02", "P-03", "P-04", "P-05", "P-06"], "exact parity ID set")

func test_result_shape_predicate_and_empty_rejection_details() -> void:
	var rejected := ReportLedgerIngestor.ingest_committed_run(ReportLedger.create_empty(0), null)
	assert_true(_is_rejected_shape(rejected), "real rejected result passes shape predicate")
	var error_code := rejected.error_code
	var rejected_outcome := rejected.outcome
	var success := rejected.success
	var changed := rejected.changed
	var candidate := rejected.candidate_ledger
	rejected.developer_details = ""
	assert_false(_is_rejected_shape(rejected), "clearing only details fails rejected shape")
	assert_eq(rejected.error_code, error_code, "only details changed code")
	assert_eq(rejected.outcome, rejected_outcome, "only details changed outcome")
	assert_eq(rejected.success, success, "only details changed success")
	assert_eq(rejected.changed, changed, "only details changed changed")
	assert_eq(rejected.candidate_ledger, candidate, "only details changed candidate")
	var applied := ReportLedgerIngestResult.applied(ReportLedger.create_empty(0))
	assert_true(applied.success, "APPLIED succeeds")
	assert_true(applied.changed, "APPLIED changes")
	assert_eq(applied.outcome, ReportLedgerIngestResult.APPLIED, "APPLIED outcome")
	assert_true(applied.error_code.is_empty(), "APPLIED has empty error")
	assert_true(applied.developer_details.is_empty(), "APPLIED has empty details")
	assert_not_null(applied.candidate_ledger, "APPLIED has candidate")
	for outcome in [ReportLedgerIngestResult.DUPLICATE_NO_OP, ReportLedgerIngestResult.ZERO_DURATION_NO_OP]:
		var no_op := ReportLedgerIngestResult.no_op(outcome)
		assert_true(no_op.success, "%s no-op succeeds" % outcome)
		assert_false(no_op.changed, "%s no-op unchanged" % outcome)
		assert_eq(no_op.outcome, outcome, "%s no-op outcome" % outcome)
		assert_true(no_op.error_code.is_empty(), "%s no-op error" % outcome)
		assert_true(no_op.developer_details.is_empty(), "%s no-op details" % outcome)
		assert_null(no_op.candidate_ledger, "%s no-op candidate" % outcome)

func _parity(id: String, expected: Array, run_requested: int, inner_requested: int, inner_committed: int, run_baseline: int, inner_baseline: int, run_result: int, inner_result: int, run_success: bool, inner_success: bool) -> Dictionary:
	return {"id": id, "expected": expected, "run_requested": run_requested, "inner_requested": inner_requested, "inner_committed": inner_committed, "run_baseline": run_baseline, "inner_baseline": inner_baseline, "run_result": run_result, "inner_result": inner_result, "run_success": run_success, "inner_success": inner_success}

func _raw_inner(requested: int, committed: int, baseline: int, result_time: int, successful: bool) -> SimulationResult:
	var channel := SimulationChannelDeltaResult.new(&"C", &"SOUL", 0, 0, 0, 1000, 0, 0, 0, 0)
	var segment := SimulationSegmentResult.new(0, &"T", 1, &"F", &"W", [&"A"], &"OVERDUE", 10, 20, 10, 0, 0, 1, 1, 0, 0, 0, [channel])
	var event := SimulationChannelBankedEvent.new(20, 0, &"T", &"C", &"SOUL", 1, &"OVERDUE", 1, 0)
	return SimulationResult.new(SimulationResult.KIND_ACTIVE_REAPING, successful, &"", "", requested, committed, baseline, result_time, "r", [segment], [event])

func _parity_predicates(run: SimulationRunService.SimulationRunResult, inner: SimulationResult) -> Array:
	return [run.requested_elapsed_msec == inner.requested_elapsed_msec, inner.committed_elapsed_msec == run.requested_elapsed_msec, run.baseline_simulation_time_msec == inner.baseline_simulation_time_msec, run.result_simulation_time_msec == inner.result_simulation_time_msec, run.success == inner.success, run.result_simulation_time_msec - run.baseline_simulation_time_msec == inner.committed_elapsed_msec]

func _wrapper_snapshot(run: SimulationRunService.SimulationRunResult) -> Dictionary:
	return {
		"success": run.success,
		"mode": run.mode,
		"error_code": run.error_code,
		"developer_details": run.developer_details,
		"requested_elapsed_msec": run.requested_elapsed_msec,
		"baseline_simulation_time_msec": run.baseline_simulation_time_msec,
		"result_simulation_time_msec": run.result_simulation_time_msec,
		"simulation_result": run.simulation_result,
		"projected_state": run.projected_state
	}

func _is_rejected_shape(result: ReportLedgerIngestResult) -> bool:
	var allowed := [ReportLedgerIngestor.ERR_LEDGER_REQUIRED, ReportLedgerIngestor.ERR_LEDGER_INVALID, ReportLedgerIngestor.ERR_RUN_REQUIRED, ReportLedgerIngestor.ERR_MODE_REJECTED, ReportLedgerIngestor.ERR_RUN_FAILED, ReportLedgerIngestor.ERR_PROJECTED, ReportLedgerIngestor.ERR_WRAPPER, ReportLedgerIngestor.ERR_RESULT_INVALID, ReportLedgerIngestor.ERR_GAP, ReportLedgerIngestor.ERR_OVERLAP, ReportLedgerIngestor.ERR_IDENTITY, ReportLedgerIngestor.ERR_SLICE, ReportLedgerIngestor.ERR_CHANNEL, ReportLedgerIngestor.ERR_OVERFLOW, ReportLedgerIngestor.ERR_CANDIDATE]
	return not result.success and not result.changed and result.outcome == ReportLedgerIngestResult.REJECTED and allowed.has(result.error_code) and not result.developer_details.is_empty() and result.candidate_ledger == null

func _timeline(start: int, finish: int) -> SimulationResult:
	return SimulationResult.zero_duration(start) if start == finish else SimulationResult.timeline_only(finish - start, start, finish, "r")

func _run(mode: StringName, inner: SimulationResult, projection: GameState = null, requested_override: int = -1) -> SimulationRunService.SimulationRunResult:
	var requested := requested_override if requested_override >= 0 else (0 if inner == null else inner.requested_elapsed_msec)
	var start := 10 if inner == null else inner.baseline_simulation_time_msec
	var finish := 10 if inner == null else inner.result_simulation_time_msec
	return SimulationRunService.SimulationRunResult.new(true, mode, &"", "", requested, start, finish, inner, projection)

func _invalid_ledger() -> ReportLedger:
	var value := ReportLedger.create_empty(10)
	value.next_event_sequence = 0
	return value
