extends GutTest

func test_retained_continuation_supports_post_rollover_ingestion() -> void:
	var source := ReportLedger.create_empty(0)
	var first := SimulationResult.active_reaping(10, 0, 10, "r", [_segment(0, 10, 2, 1)], [])
	source = ReportLedgerIngestor.ingest_committed_run(source, _run(first)).candidate_ledger
	var rolled := ReportLedgerSnapshotter.rollover(source, 10).candidate_ledger
	var second := SimulationResult.active_reaping(10, 10, 20, "r", [_segment(10, 20, 1, 1)], [])
	var result := ReportLedgerIngestor.ingest_committed_run(rolled, _run(second))
	assert_eq(result.outcome, ReportLedgerIngestResult.APPLIED, "continuation validates next endpoint: %s" % result.developer_details)
	assert_true(ReportLedgerValidator.validate(result.candidate_ledger).ok, "full ledger remains valid")

func test_pruned_continuation_preserves_rejection_floor() -> void:
	var source := ReportLedger.create_empty(0)
	var first := SimulationResult.active_reaping(10, 0, 10, "r", [_segment(0, 10, 2, 1, 2)], [])
	source = ReportLedgerIngestor.ingest_committed_run(source, _run(first)).candidate_ledger
	source = ReportLedgerSnapshotter.rollover(source, 10).candidate_ledger
	for index in range(8):
		var start := 10 + index * 10
		var finish := start + 10
		var timeline := SimulationResult.timeline_only(10, start, finish, "r")
		source = ReportLedgerIngestor.ingest_committed_run(source, _run(timeline)).candidate_ledger
		source = ReportLedgerSnapshotter.rollover(source, finish).candidate_ledger
	assert_eq(source.retained_records.size(), ReportLedger.MAX_RETAINED_RECORDS, "only the retained suffix remains")
	assert_true(source.slices.is_empty() and source.settlement_events.is_empty(), "live window is empty after rollover")
	assert_true(ReportLedgerValidator.validate(source).ok, "continuation-only baseline validates after pruning detail")
	var cases := [
		[_segment(90, 100, 1, 1, 1), ReportLedgerIngestor.ERR_IDENTITY, "lower assignment revision"],
		[_segment(90, 100, 2, 1, 2), ReportLedgerIngestor.ERR_SLICE, "backlog reset"],
		[_segment(90, 100, 1, 1, 2, 1), ReportLedgerIngestor.ERR_CHANNEL, "channel endpoint discontinuity"]
	]
	for row in cases:
		var inner := SimulationResult.active_reaping(10, 90, 100, "r", [row[0]], [])
		var result := ReportLedgerIngestor.ingest_committed_run(source, _run(inner))
		assert_eq(result.error_code, row[1], "%s rejects from continuation-only baseline: %s" % [row[2], result.developer_details])
	var settled_source := ReportLedger.create_empty(0)
	var settlement := SimulationThresholdSettledEvent.new(10, 0, &"T", 2, 0, 0, &"OVERDUE", &"SETTLED")
	settled_source = ReportLedgerIngestor.ingest_committed_run(settled_source, _run(SimulationResult.active_reaping(10, 0, 10, "r", [_segment(0, 10, 2, 0, 2)], [settlement]))).candidate_ledger
	settled_source = ReportLedgerSnapshotter.rollover(settled_source, 10).candidate_ledger
	for index in range(8):
		var start := 10 + index * 10
		var finish := start + 10
		settled_source = ReportLedgerIngestor.ingest_committed_run(settled_source, _run(SimulationResult.timeline_only(10, start, finish, "r"))).candidate_ledger
		settled_source = ReportLedgerSnapshotter.rollover(settled_source, finish).candidate_ledger
	var settled_before := settled_source.deep_clone()
	var duplicate := SimulationThresholdSettledEvent.new(100, 0, &"T", 2, 0, 0, &"OVERDUE", &"SETTLED")
	var duplicate_result := ReportLedgerIngestor.ingest_committed_run(settled_source, _run(SimulationResult.active_reaping(10, 90, 100, "r", [_segment(90, 100, 1, 0, 2)], [duplicate])))
	assert_eq(duplicate_result.error_code, ReportLedgerIngestor.ERR_SLICE, "duplicate Settlement rejects after its introducing detail was pruned")
	assert_true(settled_source.value_equals(settled_before), "duplicate Settlement rejection preserves the continuation-only source")
	assert_true(source.value_equals(source.deep_clone()), "continuation-only rejection baseline remains value-stable")

func _segment(start: int, finish: int, before: int, after: int, revision: int = 1, progress_before: int = 0) -> SimulationSegmentResult:
	var channel := SimulationChannelDeltaResult.new(&"C", &"SOUL", 0, progress_before, 0, 1000, 0, 0, 0, 0)
	return SimulationSegmentResult.new(0, &"T", revision, &"F", &"W", [&"A"], &"OVERDUE", start, finish, finish - start, before - after, before - after, before, after, 0, 0, 0, [channel])

func _run(inner: SimulationResult) -> SimulationRunService.SimulationRunResult:
	return SimulationRunService.SimulationRunResult.new(true, SimulationRunService.MODE_FOREGROUND_SUPPLIED, &"", "", inner.requested_elapsed_msec, inner.baseline_simulation_time_msec, inner.result_simulation_time_msec, inner, null)
