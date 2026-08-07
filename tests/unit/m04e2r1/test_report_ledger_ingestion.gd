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

func test_i_cont_01_through_i_cont_18_public_grammar_uses_fresh_sources() -> void:
	for row in [["I-CONT-01", "applied", ReportLedgerIngestResult.APPLIED], ["I-CONT-02", "applied", ReportLedgerIngestResult.APPLIED], ["I-CONT-03", "applied", ReportLedgerIngestResult.APPLIED], ["I-CONT-04", "slice", ReportLedgerIngestor.ERR_SLICE], ["I-CONT-05", "applied", ReportLedgerIngestResult.APPLIED], ["I-CONT-06", "identity", ReportLedgerIngestor.ERR_IDENTITY], ["I-CONT-07", "applied", ReportLedgerIngestResult.APPLIED], ["I-CONT-08", "applied", ReportLedgerIngestResult.APPLIED], ["I-CONT-09", "applied", ReportLedgerIngestResult.APPLIED], ["I-CONT-10", "applied", ReportLedgerIngestResult.APPLIED], ["I-CONT-11", "applied", ReportLedgerIngestResult.APPLIED], ["I-CONT-12", "channel", ReportLedgerIngestor.ERR_CHANNEL], ["I-CONT-13", "channel", ReportLedgerIngestor.ERR_CHANNEL], ["I-CONT-14", "channel", ReportLedgerIngestor.ERR_CHANNEL], ["I-CONT-15", "channel", ReportLedgerIngestor.ERR_CHANNEL], ["I-CONT-16", "channel", ReportLedgerIngestor.ERR_CHANNEL], ["I-CONT-17", "channel", ReportLedgerIngestor.ERR_CHANNEL], ["I-CONT-18", "slice", ReportLedgerIngestor.ERR_SLICE]]:
		var source := _apply(ReportLedger.create_empty(0), _segment(0, 10, 10, 9, 0, 1))
		var before := source.deep_clone()
		var segment := _continuity_input(row[1])
		var input := segment.detached_copy()
		var result := _ingest(source, segment)
		if row[1] == "applied":
			assert_eq(result.outcome, ReportLedgerIngestResult.APPLIED, "%s applies" % row[0])
			assert_true(result.success and result.changed, "%s applied grammar" % row[0])
			assert_eq(result.error_code, &"", "%s empty error" % row[0])
			assert_eq(result.developer_details, "", "%s empty details" % row[0])
			assert_not_null(result.candidate_ledger, "%s candidate" % row[0])
			assert_true(ReportLedgerValidator.validate(result.candidate_ledger).ok, "%s candidate validates" % row[0])
			assert_ne(result.candidate_ledger, source, "%s candidate detached" % row[0])
		else:
			assert_eq(result.outcome, ReportLedgerIngestResult.REJECTED, "%s rejects" % row[0])
			assert_false(result.success or result.changed, "%s rejected grammar" % row[0])
			assert_eq(result.error_code, row[2], "%s exact code" % row[0])
			assert_ne(result.developer_details, "", "%s details" % row[0])
			assert_null(result.candidate_ledger, "%s no candidate" % row[0])
		assert_true(source.value_equals(before), "%s source unchanged" % row[0])
		assert_true(segment.value_equals(input), "%s input unchanged" % row[0])

func test_i_chunk_03_and_i_chunk_04_use_typed_settlement_and_bank_events() -> void:
	var settlement := SimulationThresholdSettledEvent.new(10, 0, &"T", 7, 0, 0, &"OVERDUE", &"SETTLED")
	var bank := SimulationChannelBankedEvent.new(10, 0, &"T", &"C", &"SOUL", 1, &"OVERDUE", 1, 1)
	var one := SimulationResult.active_reaping(10, 0, 10, "r", [_segment(0, 10, 1, 0, 0, 1, &"F", [&"A"], &"SOUL", 1000, 0, 0, 1)], [bank, settlement])
	var chunk := SimulationResult.active_reaping(10, 0, 10, "r", [_segment(0, 10, 1, 0, 0, 1, &"F", [&"A"], &"SOUL", 1000, 0, 0, 1)], [SimulationChannelBankedEvent.new(10, 0, &"T", &"C", &"SOUL", 1, &"OVERDUE", 1, 1), SimulationThresholdSettledEvent.new(10, 0, &"T", 7, 0, 0, &"OVERDUE", &"SETTLED")])
	var left := ReportLedgerIngestor.ingest_committed_run(ReportLedger.create_empty(0), _wrapper(one))
	var right := ReportLedgerIngestor.ingest_committed_run(ReportLedger.create_empty(0), _wrapper(chunk))
	assert_true(left.success and right.success, "typed event candidates apply")
	assert_true(left.candidate_ledger.value_equals(right.candidate_ledger), "typed-event chunk candidates equal")
	assert_eq(left.candidate_ledger.settlement_events.size(), 1, "one normalized Settlement")
	assert_true(ReportLedgerValidator.validate(left.candidate_ledger).ok, "typed-event candidate validates")

func _continuity_input(kind: String) -> SimulationSegmentResult:
	if kind == "identity": return _segment(10, 20, 9, 8, 1, 2, &"OTHER")
	if kind == "slice": return _segment(10, 20, 8, 7, 1, 2)
	if kind == "channel": return _segment(10, 20, 9, 8, 0, 2)
	return _segment(10, 20, 9, 8, 1, 2)

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
