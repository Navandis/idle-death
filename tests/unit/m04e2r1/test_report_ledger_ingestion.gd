extends GutTest

func test_source_channel_continuity_and_transactional_rejection() -> void:
	var first := _apply(ReportLedger.create_empty(0), _segment(0, 10, 10, 9, 0, 1))
	for row in [["component identity", _segment(10, 20, 9, 8, 1, 2, &"OTHER") , ReportLedgerIngestor.ERR_IDENTITY], ["ordered Retinue", _segment(10, 20, 9, 8, 1, 2, &"F", [&"B", &"A"]), ReportLedgerIngestor.ERR_IDENTITY], ["backlog", _segment(10, 20, 8, 7, 1, 2), ReportLedgerIngestor.ERR_SLICE], ["output", _segment(10, 20, 9, 8, 1, 2, &"F", [&"A"], &"OTHER"), ReportLedgerIngestor.ERR_CHANNEL], ["period", _segment(10, 20, 9, 8, 1, 2, &"F", [&"A"], &"SOUL", 999), ReportLedgerIngestor.ERR_CHANNEL], ["progress", _segment(10, 20, 9, 8, 0, 2), ReportLedgerIngestor.ERR_CHANNEL], ["carry", _segment(10, 20, 9, 8, 1, 2, &"F", [&"A"], &"SOUL", 1000, 1), ReportLedgerIngestor.ERR_CHANNEL], ["total", _segment(10, 20, 9, 8, 1, 2), ReportLedgerIngestor.ERR_CHANNEL]]:
		if row[0] == "total": first.slices[0].channels[0].total_banked_units_after = 1
		var before := first.deep_clone(); var result := _ingest(first, row[1])
		assert_eq(result.error_code, row[2], row[0]); assert_true(first.value_equals(before), "source unchanged %s" % row[0]); assert_null(result.candidate_ledger, row[0])

func test_chunking_settlement_and_bank_events_normalize() -> void:
	var one_shot := _apply(ReportLedger.create_empty(0), _segment(0, 20, 10, 8, 0, 2))
	var chunked := _apply(_apply(ReportLedger.create_empty(0), _segment(0, 10, 10, 9, 0, 1)), _segment(10, 20, 9, 8, 1, 2))
	assert_true(one_shot.value_equals(chunked), "active one-shot equals chunks")
	assert_eq(chunked.slices.size(), 1, "merge-compatible chunks normalize")
	var settlement := SimulationThresholdSettledEvent.new(10, 0, &"T", 7, 0, 0, &"OVERDUE", &"SETTLED")
	var inner := SimulationResult.active_reaping(10, 0, 10, "r", [_segment(0, 10, 1, 0, 0, 1)], [settlement])
	var settled := ReportLedgerIngestor.ingest_committed_run(ReportLedger.create_empty(0), _wrapper(inner))
	assert_true(settled.success, "Settlement at ledger endpoint applies"); assert_eq(settled.candidate_ledger.settlement_events.size(), 1, "one Settlement per Threshold"); assert_eq(settled.candidate_ledger.settlement_events[0].occurred_simulation_msec, 10, "Settlement ownership time")

func test_overflow_and_malformed_source_reject_without_candidate() -> void:
	var source := _apply(ReportLedger.create_empty(0), _segment(0, 10, 10, 9, 0, 1))
	source.slices[0].returned_souls_delta = FixedPoint.INT64_MAX
	var before := source.deep_clone(); var overflow := _ingest(source, _segment(10, 20, 9, 8, 1, 2))
	assert_eq(overflow.error_code, ReportLedgerIngestor.ERR_OVERFLOW, "core merge overflow"); assert_true(source.value_equals(before), "overflow source unchanged"); assert_null(overflow.candidate_ledger, "overflow no candidate")
	source.next_event_sequence = FixedPoint.INT64_MAX
	assert_eq(_ingest(source, _segment(10, 20, 9, 8, 1, 2)).error_code, ReportLedgerIngestor.ERR_LEDGER_INVALID, "malformed event overflow source validates first")

func test_timeline_chunks_and_no_op_result_shapes() -> void:
	var one_shot := ReportLedgerIngestor.ingest_committed_run(ReportLedger.create_empty(0), _wrapper(SimulationResult.timeline_only(20, 0, 20, "r"))).candidate_ledger
	var chunked := ReportLedgerIngestor.ingest_committed_run(ReportLedgerIngestor.ingest_committed_run(ReportLedger.create_empty(0), _wrapper(SimulationResult.timeline_only(10, 0, 10, "r"))).candidate_ledger, _wrapper(SimulationResult.timeline_only(10, 10, 20, "r"))).candidate_ledger
	assert_true(one_shot.value_equals(chunked), "timeline-only one-shot equals chunks")
	var duplicate := ReportLedgerIngestor.ingest_committed_run(one_shot, _wrapper(SimulationResult.timeline_only(10, 0, 10, "r")))
	assert_true(duplicate.success, "no-op success"); assert_false(duplicate.changed, "no-op unchanged"); assert_eq(duplicate.error_code, &"", "no-op empty error"); assert_eq(duplicate.developer_details, "", "no-op empty details"); assert_null(duplicate.candidate_ledger, "no-op no candidate")

func _ingest(source: ReportLedger, segment: SimulationSegmentResult) -> ReportLedgerIngestResult:
	var inner := SimulationResult.active_reaping(segment.elapsed_msec, segment.start_simulation_msec, segment.end_simulation_msec, "r", [segment], [])
	return ReportLedgerIngestor.ingest_committed_run(source, _wrapper(inner))

func _apply(source: ReportLedger, segment: SimulationSegmentResult) -> ReportLedger:
	var result := _ingest(source, segment)
	assert_true(result.success, "fixture applies")
	return result.candidate_ledger

func _wrapper(inner: SimulationResult) -> SimulationRunService.SimulationRunResult:
	return SimulationRunService.SimulationRunResult.new(true, SimulationRunService.MODE_FOREGROUND_SUPPLIED, &"", "", inner.requested_elapsed_msec, inner.baseline_simulation_time_msec, inner.result_simulation_time_msec, inner, null)

func _segment(start: int, finish: int, before: int, after: int, progress_before: int, progress_after: int, form: StringName = &"F", retinue: Array[StringName] = [&"A"], output: StringName = &"SOUL", period: int = 1000, carry_before: int = 0, carry_after: int = 0, total_after: int = 0) -> SimulationSegmentResult:
	var channel := SimulationChannelDeltaResult.new(&"C", output, total_after, progress_before, progress_after, period, carry_before, carry_after, 0, total_after)
	return SimulationSegmentResult.new(0, &"T", 1, form, &"W", retinue, &"OVERDUE", start, finish, finish - start, before - after, before - after, before, after, 0, 0, 0, [channel])
