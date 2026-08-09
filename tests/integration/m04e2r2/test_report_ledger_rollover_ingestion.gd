extends GutTest

func test_retained_continuation_supports_post_rollover_ingestion() -> void:
	var source := ReportLedger.create_empty(0)
	var first := SimulationResult.active_reaping(10, 0, 10, "r", [_segment(0, 10, 2, 1)], [])
	source = ReportLedgerIngestor.ingest_committed_run(source, _run(first)).candidate_ledger
	var rolled := ReportLedgerSnapshotter.rollover(source, 10).candidate_ledger
	var second := SimulationResult.active_reaping(10, 10, 20, "r", [_segment(10, 20, 1, 1)], [])
	var result := ReportLedgerIngestor.ingest_committed_run(rolled, _run(second))
	assert_eq(result.outcome, ReportLedgerIngestResult.APPLIED, "continuation validates next endpoint")
	assert_true(ReportLedgerValidator.validate(result.candidate_ledger).ok, "full ledger remains valid")

func _segment(start: int, finish: int, before: int, after: int) -> SimulationSegmentResult:
	var channel := SimulationChannelDeltaResult.new(&"C", &"SOUL", 0, 0, 0, 1000, 0, 0, 0, 0)
	return SimulationSegmentResult.new(0, &"T", 1, &"F", &"W", [&"A"], &"OVERDUE", start, finish, finish - start, before - after, before - after, before, after, 0, 0, 0, [channel])

func _run(inner: SimulationResult) -> SimulationRunService.SimulationRunResult:
	return SimulationRunService.SimulationRunResult.new(true, SimulationRunService.MODE_FOREGROUND_SUPPLIED, &"", "", inner.requested_elapsed_msec, inner.baseline_simulation_time_msec, inner.result_simulation_time_msec, inner, null)
