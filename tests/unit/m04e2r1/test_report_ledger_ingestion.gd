extends GutTest

func test_same_mode_chunks_normalize_to_one_shot_value() -> void:
	var one_shot := ReportLedgerIngestor.ingest_committed_run(ReportLedger.create_empty(0), _run(_segment(0, 1000, 10, 8, 2, 0, 0))).candidate_ledger
	var first := ReportLedgerIngestor.ingest_committed_run(ReportLedger.create_empty(0), _run(_segment(0, 500, 10, 9, 1, 0, 0))).candidate_ledger
	var chunked := ReportLedgerIngestor.ingest_committed_run(first, _run(_segment(500, 1000, 9, 8, 1, 0, 0))).candidate_ledger
	assert_true(one_shot.value_equals(chunked))
	assert_eq(chunked.slices.size(), 1)

func test_channel_continuity_and_settlement_normalization() -> void:
	var first := ReportLedgerIngestor.ingest_committed_run(ReportLedger.create_empty(0), _run(_segment(0, 500, 3, 2, 1, 0, 0))).candidate_ledger
	var broken := ReportLedgerIngestor.ingest_committed_run(first, _run(_segment(500, 1000, 2, 1, 1, 2, 0)))
	assert_eq(broken.error_code, ReportLedgerIngestor.ERR_CHANNEL)
	var settling_segment := _segment(0, 1000, 1, 0, 1, 0, 0)
	var settlement := SimulationThresholdSettledEvent.new(1000, 0, &"THR_TEST", 7, 0, 0, &"OVERDUE", &"SETTLED")
	var inner := SimulationResult.active_reaping(1000, 0, 1000, ContentRegistry.CURRENT_REVISION, [settling_segment], [settlement])
	var result := ReportLedgerIngestor.ingest_committed_run(ReportLedger.create_empty(0), _wrapper(inner))
	assert_true(result.success)
	assert_eq(result.candidate_ledger.settlement_events.size(), 1)
	assert_eq(result.candidate_ledger.settlement_events[0].persistent_returns_total, 7)

func test_channel_time_gap_preserves_separate_slices() -> void:
	var source := ReportLedgerIngestor.ingest_committed_run(ReportLedger.create_empty(0), _run(_segment(0, 10, 10, 9, 1, 0, 1))).candidate_ledger
	source.slices[0].channels[0].end_simulation_msec = 5
	var source_before := source.deep_clone()
	assert_true(ReportLedgerValidator.validate(source).ok)
	var result := ReportLedgerIngestor.ingest_committed_run(source, _run(_segment(10, 20, 9, 8, 1, 1, 2)))
	assert_true(result.success)
	assert_eq(result.outcome, ReportLedgerIngestResult.APPLIED)
	assert_eq(result.candidate_ledger.slices.size(), 2)
	assert_eq(result.candidate_ledger.slices[0].channels[0].end_simulation_msec, 5)
	assert_eq(result.candidate_ledger.slices[1].channels[0].start_simulation_msec, 10)
	assert_true(ReportLedgerValidator.validate(result.candidate_ledger).ok)
	assert_true(source.value_equals(source_before))

func _segment(start: int, finish: int, before: int, after: int, souls: int, progress_before: int, progress_after: int) -> SimulationSegmentResult:
	var channel := SimulationChannelDeltaResult.new(&"CHANNEL_TEST", &"SOUL_TEST", 0, progress_before, progress_after, 1000, 0, 0, 0, 0)
	return SimulationSegmentResult.new(0, &"THR_TEST", 1, &"FORM_TEST", &"WRIT_TEST", [&"RET_A"], &"OVERDUE", start, finish, finish - start, souls, souls, before, after, 0, 0, 0, [channel])

func _run(segment: SimulationSegmentResult) -> SimulationRunService.SimulationRunResult:
	return _wrapper(SimulationResult.active_reaping(segment.elapsed_msec, segment.start_simulation_msec, segment.end_simulation_msec, ContentRegistry.CURRENT_REVISION, [segment], []))

func _wrapper(inner: SimulationResult) -> SimulationRunService.SimulationRunResult:
	return SimulationRunService.SimulationRunResult.new(true, SimulationRunService.MODE_FOREGROUND_SUPPLIED, &"", "", inner.requested_elapsed_msec, inner.baseline_simulation_time_msec, inner.result_simulation_time_msec, inner, null)
