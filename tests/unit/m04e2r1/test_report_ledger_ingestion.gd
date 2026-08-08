extends GutTest

const CONTINUITY_IDS := ["I-CONT-01", "I-CONT-02", "I-CONT-03", "I-CONT-04", "I-CONT-05", "I-CONT-06", "I-CONT-07", "I-CONT-08", "I-CONT-09", "I-CONT-10", "I-CONT-11", "I-CONT-12", "I-CONT-13", "I-CONT-14", "I-CONT-15", "I-CONT-16", "I-CONT-17", "I-CONT-18"]
const CHUNK_IDS := ["I-CHUNK-01", "I-CHUNK-02", "I-CHUNK-03", "I-CHUNK-04"]
const LEDGER_FIELDS := ["window_start_simulation_msec", "ingested_through_simulation_msec", "foreground_elapsed_msec", "offline_elapsed_msec", "debug_elapsed_msec", "next_event_sequence", "slices", "settlement_events"]
const SLICE_FIELDS := ["run_mode", "content_revision", "threshold_id", "assignment_revision", "form_id", "writ_id", "ordered_retinue_ids", "lifecycle_state", "start_simulation_msec", "end_simulation_msec", "returned_souls_delta", "remaining_backlog_before", "remaining_backlog_after", "essence_delta", "mastery_delta_subunits", "completed_cycles_delta", "channels"]
const CHANNEL_FIELDS := ["channel_id", "output_item_id", "start_simulation_msec", "end_simulation_msec", "progress_subunits_before", "progress_subunits_after", "rate_period_msec", "rate_carry_units_before", "rate_carry_units_after", "total_banked_units_before", "total_banked_units_after"]
const SETTLEMENT_FIELDS := ["event_sequence", "content_revision", "threshold_id", "assignment_revision", "occurred_simulation_msec", "persistent_returns_total"]

func test_public_continuity_matrix_uses_boundary_specific_scenarios() -> void:
	var rows := [
		_cont("I-CONT-01", _i_cont_01(), ReportLedgerIngestResult.APPLIED),
		_cont("I-CONT-02", _i_cont_02(), ReportLedgerIngestResult.APPLIED),
		_cont("I-CONT-03", _i_cont_03(), ReportLedgerIngestResult.APPLIED),
		_cont("I-CONT-04", _i_cont_04(), ReportLedgerIngestor.ERR_SLICE),
		_cont("I-CONT-05", _i_cont_05(), ReportLedgerIngestResult.APPLIED),
		_cont("I-CONT-06", _i_cont_06(), ReportLedgerIngestor.ERR_IDENTITY),
		_cont("I-CONT-07", _i_cont_07(), ReportLedgerIngestResult.APPLIED),
		_cont("I-CONT-08", _i_cont_08(), ReportLedgerIngestResult.APPLIED),
		_cont("I-CONT-09", _i_cont_09(), ReportLedgerIngestResult.APPLIED),
		_cont("I-CONT-10", _i_cont_10(), ReportLedgerIngestResult.APPLIED),
		_cont("I-CONT-11", _i_cont_11(), ReportLedgerIngestResult.APPLIED),
		_cont("I-CONT-12", _i_cont_12(), ReportLedgerIngestor.ERR_CHANNEL),
		_cont("I-CONT-13", _i_cont_13(), ReportLedgerIngestor.ERR_CHANNEL),
		_cont("I-CONT-14", _i_cont_14(), ReportLedgerIngestor.ERR_CHANNEL),
		_cont("I-CONT-15", _i_cont_15(), ReportLedgerIngestor.ERR_CHANNEL),
		_cont("I-CONT-16", _i_cont_16(), ReportLedgerIngestor.ERR_CHANNEL),
		_cont("I-CONT-17", _i_cont_17(), ReportLedgerIngestor.ERR_CHANNEL),
		_cont("I-CONT-18", _i_cont_18(), ReportLedgerIngestor.ERR_SLICE)
	]
	var actual: Array[String] = []
	for row in rows:
		actual.append(row.id)
		assert_true(row.scenario.probe.call(), "%s boundary precondition" % row.id)
		var source: ReportLedger = row.scenario.source
		var snapshot := source.deep_clone()
		var run: SimulationRunService.SimulationRunResult = row.scenario.run
		var wrapper_snapshot := _wrapper_snapshot(run)
		var inner_snapshot := run.simulation_result.detached_copy()
		var result := ReportLedgerIngestor.ingest_committed_run(source, run)
		if row.expected == ReportLedgerIngestResult.APPLIED:
			_assert_applied(result, source, snapshot, run, wrapper_snapshot, inner_snapshot, row.id)
			assert_true(_ledger_matches_witness(result.candidate_ledger, row.scenario.expected_ledger), "%s complete literal candidate witness" % row.id)
		else:
			_assert_rejected(result, row.expected, source, snapshot, run, wrapper_snapshot, inner_snapshot, row.id)
	assert_eq(actual, CONTINUITY_IDS, "exact public continuity ID set")
	assert_true(_unique(actual), "no duplicate continuity row")

func test_real_channel_gap_regression_preserves_both_channel_intervals() -> void:
	var source := _apply(ReportLedger.create_empty(0), _active(0, 10, [_segment(0, 10, 10, 9, &"T", 1, &"F", [&"A"], "r", [_input_channel(&"C", 0, 0, 0, 0)])]))
	source.slices[0].channels[0].end_simulation_msec = 5
	var snapshot := source.deep_clone()
	assert_true(ReportLedgerValidator.validate(source).ok, "gap source validates")
	var result := ReportLedgerIngestor.ingest_committed_run(source, _wrapper(_active(10, 20, [_segment(10, 20, 9, 8, &"T", 1, &"F", [&"A"], "content-next", [_input_channel(&"C", 0, 0, 0, 0)])])))
	assert_true(result.success, "gap ingestion succeeds")
	assert_eq(result.outcome, ReportLedgerIngestResult.APPLIED, "gap ingestion is APPLIED")
	var candidate := result.candidate_ledger
	assert_eq(candidate.slices.size(), 2, "content split keeps source and new slices")
	assert_eq(candidate.slices[0].channels[0].end_simulation_msec, 5, "first channel interval stays [0,5)")
	assert_eq(candidate.slices[1].channels[0].start_simulation_msec, 10, "second channel interval starts at 10")
	assert_true(ReportLedgerValidator.validate(candidate).ok, "gap candidate validates")
	assert_true(source.value_equals(snapshot), "gap source remains value-unchanged")
func test_four_genuine_one_shot_and_chunked_wrapper_arrays() -> void:
	var rows := [
		_chunk("I-CHUNK-01", [_wrapper(_active(0, 20, [_segment(0, 20, 10, 8, &"T", 1, &"F", [&"A"], "r", [], {"essence_delta": 11, "mastery_delta_subunits": 13, "completed_cycles_delta": 17})]))], [_wrapper(_active(0, 10, [_segment(0, 10, 10, 9, &"T", 1, &"F", [&"A"], "r", [], {"essence_delta": 2, "mastery_delta_subunits": 3, "completed_cycles_delta": 5})])), _wrapper(_active(10, 20, [_segment(10, 20, 9, 8, &"T", 1, &"F", [&"A"], "r", [], {"essence_delta": 9, "mastery_delta_subunits": 10, "completed_cycles_delta": 12})]))], func(one, chunks): return one.slices.size() == 1 and chunks.slices.size() == 1, func(one_shot, chunked): return _core_deltas_match(one_shot[0].simulation_result.segments[0], 11, 13, 17) and _core_deltas_match(chunked[0].simulation_result.segments[0], 2, 3, 5) and _core_deltas_match(chunked[1].simulation_result.segments[0], 9, 10, 12), _chunk_01_witness()),
		_chunk("I-CHUNK-02", [_wrapper(_timeline(0, 20))], [_wrapper(_timeline(0, 10)), _wrapper(_timeline(10, 20))], func(one, chunks): return one.slices.is_empty() and chunks.slices.is_empty(), func(one_shot, chunked): return one_shot[0].simulation_result.result_kind == SimulationResult.KIND_TIMELINE_ONLY and chunked[0].simulation_result.result_kind == SimulationResult.KIND_TIMELINE_ONLY and one_shot[0].result_simulation_time_msec == chunked[1].result_simulation_time_msec, _chunk_02_witness()),
		_chunk("I-CHUNK-03", [_wrapper(_settlement_run(0, 20, 2, 0))], [_wrapper(_active(0, 10, [_segment(0, 10, 2, 1)])), _wrapper(_settlement_run(10, 20, 1, 0))], func(one, chunks): return one.settlement_events.size() == 1 and chunks.settlement_events.size() == 1, func(one_shot, chunked): return _settlement_count(one_shot[0].simulation_result) == 1 and _settlement_count(chunked[0].simulation_result) + _settlement_count(chunked[1].simulation_result) == 1 and _settlement_input_is_exact(one_shot[0].simulation_result) and _settlement_input_is_exact(chunked[1].simulation_result), _chunk_03_witness()),
		_chunk("I-CHUNK-04", [_wrapper(_bank_run(0, 20, 2, 7, 2, 7, 2, 7))], [_wrapper(_bank_run(0, 10, 2, 4, 2, 5, 2, 5)), _wrapper(_bank_run(10, 20, 4, 7, 5, 7, 5, 7))], func(one, chunks): return one.slices[0].channels[0].rate_carry_units_before == 2 and one.slices[0].channels[0].rate_carry_units_after == 7 and chunks.slices[0].channels[0].total_banked_units_after == 7 and one.settlement_events.is_empty() and chunks.settlement_events.is_empty(), func(one_shot, chunked): return _bank_count(one_shot[0].simulation_result) == 1 and _bank_count(chunked[0].simulation_result) + _bank_count(chunked[1].simulation_result) == 2 and one_shot[0].simulation_result.events.size() != chunked[0].simulation_result.events.size() + chunked[1].simulation_result.events.size() and one_shot[0].simulation_result.segments[0].channel_deltas[0].progress_subunits_before == 2 and one_shot[0].simulation_result.segments[0].channel_deltas[0].progress_subunits_after == 7 and chunked[0].simulation_result.segments[0].channel_deltas[0].progress_subunits_after == chunked[1].simulation_result.segments[0].channel_deltas[0].progress_subunits_before and chunked[0].simulation_result.segments[0].channel_deltas[0].rate_carry_units_before == 2 and chunked[0].simulation_result.segments[0].channel_deltas[0].rate_carry_units_after == 5 and chunked[1].simulation_result.segments[0].channel_deltas[0].rate_carry_units_before == 5 and chunked[1].simulation_result.segments[0].channel_deltas[0].rate_carry_units_after == 7 and chunked[0].simulation_result.segments[0].channel_deltas[0].total_banked_units_after == chunked[1].simulation_result.segments[0].channel_deltas[0].total_banked_units_before and _bank_input_matches_channel(one_shot[0].simulation_result) and _bank_input_matches_channel(chunked[0].simulation_result) and _bank_input_matches_channel(chunked[1].simulation_result), _chunk_04_witness())
	]
	var actual: Array[String] = []
	for row in rows:
		actual.append(row.id)
		assert_eq(row.one_shot.size(), 1, "%s one-shot has one wrapper" % row.id)
		assert_gte(row.chunked.size(), 2, "%s chunks have multiple wrappers" % row.id)
		assert_true(row.input_probe.call(row.one_shot, row.chunked), "%s committed wrapper input facts" % row.id)
		assert_true(_same_wrapper_interval(row.one_shot, row.chunked), "%s wrapper sequences cover same interval" % row.id)
		assert_true(_same_wrapper_mode(row.one_shot, row.chunked), "%s wrapper modes are equivalent" % row.id)
		var one_source := ReportLedger.create_empty(0)
		var chunk_source := ReportLedger.create_empty(0)
		var one_source_snapshot := one_source.deep_clone()
		var chunk_source_snapshot := chunk_source.deep_clone()
		var one_inputs := _runs_snapshot(row.one_shot)
		var chunk_inputs := _runs_snapshot(row.chunked)
		var one := _apply_committed_wrappers(one_source, row.one_shot)
		var chunks := _apply_committed_wrappers(chunk_source, row.chunked)
		assert_true(one_source.value_equals(one_source_snapshot), "%s one-shot source unchanged" % row.id)
		assert_true(chunk_source.value_equals(chunk_source_snapshot), "%s chunked source unchanged" % row.id)
		_assert_runs_unchanged(row.one_shot, one_inputs, "%s one-shot wrapper inputs unchanged" % row.id)
		_assert_runs_unchanged(row.chunked, chunk_inputs, "%s chunked wrapper inputs unchanged" % row.id)
		assert_true(ReportLedgerValidator.validate(one).ok and ReportLedgerValidator.validate(chunks).ok, "%s candidates validate" % row.id)
		assert_true(row.probe.call(one, chunks), "%s typed boundary facts retained" % row.id)
		assert_true(_ledger_matches_witness(one, row.expected_ledger), "%s one-shot complete literal witness" % row.id)
		assert_true(_ledger_matches_witness(chunks, row.expected_ledger), "%s chunked complete literal witness" % row.id)
		assert_true(one.value_equals(chunks), "%s one-shot/chunks value equal" % row.id)
	assert_eq(actual, CHUNK_IDS, "exact chunk ID set")
	assert_true(_unique(actual), "no duplicate chunk row")
	assert_true(_has_exact_keys(_ledger_witness({}), LEDGER_FIELDS) and _has_exact_keys(_slice_witness({}), SLICE_FIELDS) and _has_exact_keys(_channel_witness({}), CHANNEL_FIELDS) and _has_exact_keys(_settlement_witness({}), SETTLEMENT_FIELDS), "named witness constructors preserve each exact declared field map")
	assert_true(_ledger_witness({"unknown": true}).is_empty() and _slice_witness({"unknown": true}).is_empty() and _channel_witness({"unknown": true}).is_empty() and _settlement_witness({"unknown": true}).is_empty(), "named witness constructors reject unknown override keys")
	var non_zero_sentinel := _slice_witness({"essence_delta": 11, "mastery_delta_subunits": 13, "completed_cycles_delta": 17})
	assert_true(non_zero_sentinel.essence_delta == 11 and non_zero_sentinel.mastery_delta_subunits == 13 and non_zero_sentinel.completed_cycles_delta == 17, "named witness construction retains the non-zero core sentinel")
	assert_null(_segment(0, 1, 1, 0, &"T", 1, &"F", [&"A"], "r", [], {"unknown": 1}), "segment fixture rejects unknown core-delta keys")

func test_transactionality_overflow_and_no_op_input_preservation() -> void:
	var source := _apply(ReportLedger.create_empty(0), _active(0, 10, [_segment(0, 10, 10, 9)]))
	var cases := [
		["detached APPLIED candidate", _active(10, 20, [_segment(10, 20, 9, 8)]), ReportLedgerIngestResult.APPLIED],
		["duplicate no-op", _bank_run(0, 10, 0, 1, 0, 1, 0, 1), ReportLedgerIngestResult.DUPLICATE_NO_OP],
		["zero-duration no-op", SimulationResult.zero_duration(10), ReportLedgerIngestResult.ZERO_DURATION_NO_OP],
		["forward gap", _bank_run(11, 20, 0, 1, 0, 1, 0, 1), ReportLedgerIngestor.ERR_GAP],
		["partial overlap", _bank_run(9, 20, 0, 1, 0, 1, 0, 1), ReportLedgerIngestor.ERR_OVERLAP]
	]
	for row in cases:
		var before := source.deep_clone()
		var run := _wrapper(row[1])
		var wrapper := _wrapper_snapshot(run)
		var inner := run.simulation_result.detached_copy()
		var result := ReportLedgerIngestor.ingest_committed_run(source, run)
		assert_true(source.value_equals(before), "%s source unchanged" % row[0])
		_assert_run_unchanged(run, wrapper, inner, "%s complete wrapper and child preservation" % row[0])
		if row[2] == ReportLedgerIngestResult.APPLIED:
			assert_eq(result.outcome, ReportLedgerIngestResult.APPLIED, "applied outcome")
			assert_true(result.success, "applied success")
			assert_true(result.changed, "applied changed")
			assert_eq(result.error_code, &"", "applied empty error")
			assert_eq(result.developer_details, "", "applied empty details")
			assert_ne(result.candidate_ledger, source, "candidate is detached")
			assert_true(ReportLedgerValidator.validate(result.candidate_ledger).ok, "candidate validates")
			assert_true(result.candidate_ledger.value_equals(_apply(before, row[1])), "detached candidate has expected value")
		else:
			assert_eq(result.outcome if result.error_code.is_empty() else result.error_code, row[2], row[0])
			assert_false(result.changed, "%s no mutation result" % row[0])
			assert_ne(result.outcome, ReportLedgerIngestResult.APPLIED, "%s not applied" % row[0])
			if result.outcome == ReportLedgerIngestResult.REJECTED:
				assert_false(result.success, "%s rejection success false" % row[0])
				assert_ne(result.error_code, &"", "%s rejection code" % row[0])
				assert_ne(result.developer_details, "", "%s rejection details" % row[0])
			else:
				assert_true(result.success, "%s no-op success" % row[0])
				assert_eq(result.error_code, &"", "%s no-op error" % row[0])
				assert_eq(result.developer_details, "", "%s no-op details" % row[0])
			assert_null(result.candidate_ledger, "%s null candidate" % row[0])
	var overflow_source := source.deep_clone()
	overflow_source.slices[0].returned_souls_delta = FixedPoint.INT64_MAX
	var overflow_before := overflow_source.deep_clone()
	var overflow_run := _wrapper(_active(10, 20, [_segment(10, 20, 9, 8)]))
	var overflow_wrapper := _wrapper_snapshot(overflow_run)
	var overflow_inner := overflow_run.simulation_result.detached_copy()
	var overflow := ReportLedgerIngestor.ingest_committed_run(overflow_source, overflow_run)
	_assert_rejected(overflow, ReportLedgerIngestor.ERR_OVERFLOW, overflow_source, overflow_before, overflow_run, overflow_wrapper, overflow_inner, "compatible core-delta overflow")
func test_public_source_validation_precedence_for_unreachable_overflows() -> void:
	_assert_source_validation_precedence("I-OVF-01", _invalid_root_source(FixedPoint.INT64_MAX, FixedPoint.INT64_MAX, 1, 1), "Mode duration overflow.", "source duration overflow")
	_assert_source_validation_precedence("I-OVF-02", _invalid_root_source(0, 0, 0, FixedPoint.INT64_MAX), "Next event sequence is invalid", "public source-validation precedence is approved where the checked increment cannot be reached from a canonical valid source.")
func _cont(id: String, scenario: Dictionary, expected: StringName) -> Dictionary:
	return {"id": id, "scenario": scenario, "expected": expected}
func _scenario(source: ReportLedger, inner: SimulationResult, probe: Callable, mode: StringName = SimulationRunService.MODE_FOREGROUND_SUPPLIED, expected_ledger: Dictionary = {}) -> Dictionary:
	return {"source": source, "run": _wrapper(inner, mode), "probe": probe, "expected_ledger": expected_ledger}
func _i_cont_01() -> Dictionary:
	var source := _apply(ReportLedger.create_empty(0), _active(0, 10, [_segment(0, 10, 10, 9)]))
	var incoming := _active(10, 20, [_segment(10, 20, 9, 8)])
	return _scenario(source, incoming, func(): return source.slices[0].run_mode == SimulationRunService.MODE_FOREGROUND_SUPPLIED and incoming.baseline_simulation_time_msec == 10 and incoming.result_simulation_time_msec == 20 and source.slices[0].remaining_backlog_after == incoming.segments[0].remaining_backlog_before, SimulationRunService.MODE_OFFLINE_FIXTURE, _ledger_witness({"ingested_through_simulation_msec": 20, "foreground_elapsed_msec": 10, "offline_elapsed_msec": 10, "slices": [_slice_witness({"start_simulation_msec": 0, "end_simulation_msec": 10, "returned_souls_delta": 1, "remaining_backlog_before": 10, "remaining_backlog_after": 9, "channels": [_channel_witness({"start_simulation_msec": 0, "end_simulation_msec": 10})]}), _slice_witness({"run_mode": SimulationRunService.MODE_OFFLINE_FIXTURE, "start_simulation_msec": 10, "end_simulation_msec": 20, "returned_souls_delta": 1, "remaining_backlog_before": 9, "remaining_backlog_after": 8, "channels": [_channel_witness({"start_simulation_msec": 10, "end_simulation_msec": 20})]})]}))
func _i_cont_02() -> Dictionary:
	var source := _apply(ReportLedger.create_empty(0), _active(0, 10, [_segment(0, 10, 10, 9)], "content-a"))
	var incoming := _active(10, 20, [_segment(10, 20, 9, 8)], "content-b")
	return _scenario(source, incoming, func(): return source.slices[0].content_revision == "content-a" and incoming.content_revision == "content-b" and _continuity_endpoints_match(source.slices[0], incoming.segments[0]), SimulationRunService.MODE_FOREGROUND_SUPPLIED, _ledger_witness({"ingested_through_simulation_msec": 20, "foreground_elapsed_msec": 20, "slices": [_slice_witness({"content_revision": "content-a", "start_simulation_msec": 0, "end_simulation_msec": 10, "returned_souls_delta": 1, "remaining_backlog_before": 10, "remaining_backlog_after": 9, "channels": [_channel_witness({"start_simulation_msec": 0, "end_simulation_msec": 10})]}), _slice_witness({"content_revision": "content-b", "start_simulation_msec": 10, "end_simulation_msec": 20, "returned_souls_delta": 1, "remaining_backlog_before": 9, "remaining_backlog_after": 8, "channels": [_channel_witness({"start_simulation_msec": 10, "end_simulation_msec": 20})]})]}))
func _i_cont_03() -> Dictionary:
	var source := _apply(ReportLedger.create_empty(0), _active(0, 10, [_segment(0, 10, 2, 1)]))
	var incoming := _settlement_run(10, 20, 1, 0)
	var expected_threshold := &"T"
	var event := incoming.events[0] as SimulationThresholdSettledEvent
	assert_eq(event.subject_id, expected_threshold, "I-CONT-03 settlement event subject is the expected Threshold")
	assert_true(event.segment_index >= 0 and event.segment_index < incoming.segments.size(), "I-CONT-03 settlement event identifies an existing segment")
	assert_eq(incoming.segments[event.segment_index].threshold_id, event.subject_id, "I-CONT-03 settlement event Threshold is owned by its referenced segment")
	return _scenario(source, incoming, func(): return source.slices[0].lifecycle_state == &"OVERDUE" and source.slices[0].remaining_backlog_after == 1 and _settlement_count(incoming) == 1 and incoming.events[0] is SimulationThresholdSettledEvent and incoming.events[0].segment_index == 0 and incoming.events[0].occurred_simulation_msec == 20 and incoming.events[0].lifecycle_before == &"OVERDUE" and incoming.events[0].lifecycle_after == &"SETTLED", SimulationRunService.MODE_FOREGROUND_SUPPLIED, _ledger_witness({"ingested_through_simulation_msec": 20, "foreground_elapsed_msec": 20, "next_event_sequence": 2, "slices": [_slice_witness({"start_simulation_msec": 0, "end_simulation_msec": 20, "returned_souls_delta": 2, "remaining_backlog_before": 2, "channels": [_channel_witness({"start_simulation_msec": 0, "end_simulation_msec": 20})]})], "settlement_events": [_settlement_witness({"occurred_simulation_msec": 20})]}))
func _i_cont_04() -> Dictionary:
	var source := _settled_source()
	var incoming := _active(10, 20, [_segment(10, 20, 1, 1)])
	# A canonical Overdue input begins with positive backlog, so this row intentionally proves the public SETTLED -> OVERDUE boundary under its unavoidable difference from the settled zero-backlog endpoint.
	return _scenario(source, incoming, func(): return source.slices[0].lifecycle_state == &"SETTLED" and source.slices[0].remaining_backlog_after == 0 and incoming.segments[0].lifecycle_state == &"OVERDUE" and incoming.segments[0].remaining_backlog_before > 0)
func _i_cont_05() -> Dictionary:
	var source := _apply(ReportLedger.create_empty(0), _active(0, 10, [_segment(0, 10, 10, 9, &"T", 1)]))
	var incoming := _active(10, 20, [_segment(10, 20, 9, 8, &"T", 2, &"F2")])
	return _scenario(source, incoming, func(): return source.slices[0].assignment_revision == 1 and incoming.segments[0].assignment_revision == 2 and source.slices[0].form_id != incoming.segments[0].form_id and source.slices[0].remaining_backlog_after == incoming.segments[0].remaining_backlog_before, SimulationRunService.MODE_FOREGROUND_SUPPLIED, _ledger_witness({"ingested_through_simulation_msec": 20, "foreground_elapsed_msec": 20, "slices": [_slice_witness({"start_simulation_msec": 0, "end_simulation_msec": 10, "returned_souls_delta": 1, "remaining_backlog_before": 10, "remaining_backlog_after": 9, "channels": [_channel_witness({"start_simulation_msec": 0, "end_simulation_msec": 10})]}), _slice_witness({"assignment_revision": 2, "form_id": &"F2", "start_simulation_msec": 10, "end_simulation_msec": 20, "returned_souls_delta": 1, "remaining_backlog_before": 9, "remaining_backlog_after": 8, "channels": [_channel_witness({"start_simulation_msec": 10, "end_simulation_msec": 20})]})]}))
func _i_cont_06() -> Dictionary:
	var source := _apply(ReportLedger.create_empty(0), _active(0, 10, [_segment(0, 10, 10, 9)]))
	var incoming := _active(10, 20, [_segment(10, 20, 9, 8, &"T", 1, &"OTHER")])
	return _scenario(source, incoming, func(): return source.slices[0].assignment_revision == incoming.segments[0].assignment_revision and source.slices[0].form_id != incoming.segments[0].form_id)
func _i_cont_07() -> Dictionary:
	var source := _apply(ReportLedger.create_empty(0), _active(0, 10, [_segment(0, 10, 10, 9)]))
	source = _apply(source, _timeline(10, 20))
	var incoming := _active(20, 30, [_segment(20, 30, 9, 8)])
	return _scenario(source, incoming, func(): return source.ingested_through_simulation_msec == 20 and source.slices[0].end_simulation_msec == 10 and incoming.baseline_simulation_time_msec == 20 and incoming.segments[0].remaining_backlog_before == source.slices[0].remaining_backlog_after, SimulationRunService.MODE_FOREGROUND_SUPPLIED, _ledger_witness({"ingested_through_simulation_msec": 30, "foreground_elapsed_msec": 30, "slices": [_slice_witness({"start_simulation_msec": 0, "end_simulation_msec": 10, "returned_souls_delta": 1, "remaining_backlog_before": 10, "remaining_backlog_after": 9, "channels": [_channel_witness({"start_simulation_msec": 0, "end_simulation_msec": 10})]}), _slice_witness({"start_simulation_msec": 20, "end_simulation_msec": 30, "returned_souls_delta": 1, "remaining_backlog_before": 9, "remaining_backlog_after": 8, "channels": [_channel_witness({"start_simulation_msec": 20, "end_simulation_msec": 30})]})]}))
func _i_cont_08() -> Dictionary:
	var source := _apply(ReportLedger.create_empty(0), _active(0, 10, [_segment(0, 10, 10, 9, &"T")]))
	source = _apply(source, _active(10, 20, [_segment(10, 20, 4, 3, &"OTHER")]))
	var incoming := _active(20, 30, [_segment(20, 30, 9, 8, &"T")])
	return _scenario(source, incoming, func(): return source.slices[1].threshold_id == &"OTHER" and source.slices[0].threshold_id == &"T" and incoming.segments[0].threshold_id == &"T" and incoming.segments[0].remaining_backlog_before == source.slices[0].remaining_backlog_after, SimulationRunService.MODE_FOREGROUND_SUPPLIED, _ledger_witness({"ingested_through_simulation_msec": 30, "foreground_elapsed_msec": 30, "slices": [_slice_witness({"start_simulation_msec": 0, "end_simulation_msec": 10, "returned_souls_delta": 1, "remaining_backlog_before": 10, "remaining_backlog_after": 9, "channels": [_channel_witness({"start_simulation_msec": 0, "end_simulation_msec": 10})]}), _slice_witness({"threshold_id": &"OTHER", "start_simulation_msec": 10, "end_simulation_msec": 20, "returned_souls_delta": 1, "remaining_backlog_before": 4, "remaining_backlog_after": 3, "channels": [_channel_witness({"start_simulation_msec": 10, "end_simulation_msec": 20})]}), _slice_witness({"start_simulation_msec": 20, "end_simulation_msec": 30, "returned_souls_delta": 1, "remaining_backlog_before": 9, "remaining_backlog_after": 8, "channels": [_channel_witness({"start_simulation_msec": 20, "end_simulation_msec": 30})]})]}))
func _i_cont_09() -> Dictionary:
	var source := _apply(ReportLedger.create_empty(0), _active(0, 10, [_segment(0, 10, 10, 9, &"T", 1, &"A")]))
	source = _apply(source, _active(10, 20, [_segment(10, 20, 9, 8, &"T", 2, &"B")]))
	var incoming := _active(20, 30, [_segment(20, 30, 8, 7, &"T", 3, &"A")])
	return _scenario(source, incoming, func(): return source.slices[0].form_id == &"A" and source.slices[1].form_id == &"B" and incoming.segments[0].form_id == &"A" and source.slices[0].remaining_backlog_after == 9 and source.slices[1].remaining_backlog_after == 8 and incoming.segments[0].remaining_backlog_before == 8, SimulationRunService.MODE_FOREGROUND_SUPPLIED, _ledger_witness({"ingested_through_simulation_msec": 30, "foreground_elapsed_msec": 30, "slices": [_slice_witness({"form_id": &"A", "start_simulation_msec": 0, "end_simulation_msec": 10, "returned_souls_delta": 1, "remaining_backlog_before": 10, "remaining_backlog_after": 9, "channels": [_channel_witness({"start_simulation_msec": 0, "end_simulation_msec": 10})]}), _slice_witness({"assignment_revision": 2, "form_id": &"B", "start_simulation_msec": 10, "end_simulation_msec": 20, "returned_souls_delta": 1, "remaining_backlog_before": 9, "remaining_backlog_after": 8, "channels": [_channel_witness({"start_simulation_msec": 10, "end_simulation_msec": 20})]}), _slice_witness({"assignment_revision": 3, "form_id": &"A", "start_simulation_msec": 20, "end_simulation_msec": 30, "returned_souls_delta": 1, "remaining_backlog_before": 8, "remaining_backlog_after": 7, "channels": [_channel_witness({"start_simulation_msec": 20, "end_simulation_msec": 30})]})]}))
func _i_cont_10() -> Dictionary:
	var source := _apply(ReportLedger.create_empty(0), _active(0, 10, [_segment(0, 10, 10, 9, &"T", 1, &"FORM_A")]))
	var next := _active(10, 20, [_segment(10, 20, 9, 8, &"T", 2, &"FORM_B")])
	return _scenario(source, next, func(): return source.slices[0].form_id != next.segments[0].form_id and source.slices[0].channels[0].output_item_id == next.segments[0].channel_deltas[0].output_item_id, SimulationRunService.MODE_FOREGROUND_SUPPLIED, _ledger_witness({"ingested_through_simulation_msec": 20, "foreground_elapsed_msec": 20, "slices": [_slice_witness({"form_id": &"FORM_A", "start_simulation_msec": 0, "end_simulation_msec": 10, "returned_souls_delta": 1, "remaining_backlog_before": 10, "remaining_backlog_after": 9, "channels": [_channel_witness({"start_simulation_msec": 0, "end_simulation_msec": 10})]}), _slice_witness({"assignment_revision": 2, "form_id": &"FORM_B", "start_simulation_msec": 10, "end_simulation_msec": 20, "returned_souls_delta": 1, "remaining_backlog_before": 9, "remaining_backlog_after": 8, "channels": [_channel_witness({"start_simulation_msec": 10, "end_simulation_msec": 20})]})]}))
func _i_cont_11() -> Dictionary:
	var source := _apply(ReportLedger.create_empty(0), _active(0, 10, [_segment(0, 10, 10, 9)]))
	var incoming := _active(10, 20, [_segment(10, 20, 9, 8, &"T", 1, &"F", [&"A"], "r", [_input_channel(&"C", 0, 0, 0, 0), _input_channel(&"D", 3, 4, 5, 6)])])
	return _scenario(source, incoming, func(): return source.slices[0].channels.size() == 1 and incoming.segments[0].start_simulation_msec == 10 and _continuity_endpoints_match(source.slices[0], incoming.segments[0]) and _new_channel_d_has_supplied_endpoints(incoming.segments[0].channel_deltas[1]), SimulationRunService.MODE_FOREGROUND_SUPPLIED, _ledger_witness({"ingested_through_simulation_msec": 20, "foreground_elapsed_msec": 20, "slices": [_slice_witness({"start_simulation_msec": 0, "end_simulation_msec": 10, "returned_souls_delta": 1, "remaining_backlog_before": 10, "remaining_backlog_after": 9, "channels": [_channel_witness({"start_simulation_msec": 0, "end_simulation_msec": 10})]}), _slice_witness({"start_simulation_msec": 10, "end_simulation_msec": 20, "returned_souls_delta": 1, "remaining_backlog_before": 9, "remaining_backlog_after": 8, "channels": [_channel_witness({"start_simulation_msec": 10, "end_simulation_msec": 20}), _channel_witness({"channel_id": &"D", "start_simulation_msec": 10, "end_simulation_msec": 20, "progress_subunits_before": 3, "progress_subunits_after": 4, "rate_carry_units_before": 5, "rate_carry_units_after": 6})]})]}))
func _i_cont_12() -> Dictionary:
	var source := _apply(ReportLedger.create_empty(0), _active(0, 10, [_segment(0, 10, 10, 9, &"T", 1, &"F", [&"A"], "r", [_input_channel(&"C", 0, 0, 0, 0), _input_channel(&"D", 0, 0, 0, 0)])]))
	var incoming := _active(10, 20, [_segment(10, 20, 9, 8, &"T", 1, &"F", [&"A"], "r", [_input_channel(&"C", 0, 0, 0, 0)])])
	return _scenario(source, incoming, func(): return source.slices[0].channels.size() == 2 and incoming.segments[0].channel_deltas.size() == 1 and incoming.segments[0].channel_deltas[0].channel_id == &"C")
func _i_cont_13() -> Dictionary:
	var source := _apply(ReportLedger.create_empty(0), _active(0, 10, [_segment(0, 10, 10, 9)]))
	var incoming := _active(10, 20, [_segment(10, 20, 9, 8, &"T", 1, &"F", [&"A"], "r", [SimulationChannelDeltaResult.new(&"C", &"OTHER", 0, 0, 0, 1000, 0, 0, 0, 0)])])
	return _scenario(source, incoming, func(): return source.slices[0].channels[0].output_item_id == &"SOUL" and incoming.segments[0].channel_deltas[0].output_item_id == &"OTHER")
func _i_cont_14() -> Dictionary:
	var source := _apply(ReportLedger.create_empty(0), _active(0, 10, [_segment(0, 10, 10, 9)]))
	var incoming := _active(10, 20, [_segment(10, 20, 9, 8, &"T", 1, &"F", [&"A"], "r", [SimulationChannelDeltaResult.new(&"C", &"SOUL", 0, 0, 0, 999, 0, 0, 0, 0)])])
	return _scenario(source, incoming, func(): return source.slices[0].channels[0].rate_period_msec == 1000 and incoming.segments[0].channel_deltas[0].rate_period_msec == 999)
func _i_cont_15() -> Dictionary:
	var source := _apply(ReportLedger.create_empty(0), _active(0, 10, [_segment(0, 10, 10, 9)]))
	var incoming := _active(10, 20, [_segment(10, 20, 9, 8, &"T", 1, &"F", [&"A"], "r", [SimulationChannelDeltaResult.new(&"C", &"SOUL", 0, 5, 0, 1000, 0, 0, 0, 0)])])
	return _scenario(source, incoming, func(): return source.slices[0].channels[0].progress_subunits_after == 0 and incoming.segments[0].channel_deltas[0].progress_subunits_before == 5)
func _i_cont_16() -> Dictionary:
	var source := _apply(ReportLedger.create_empty(0), _active(0, 10, [_segment(0, 10, 10, 9)]))
	var incoming := _active(10, 20, [_segment(10, 20, 9, 8, &"T", 1, &"F", [&"A"], "r", [SimulationChannelDeltaResult.new(&"C", &"SOUL", 0, 0, 0, 1000, 5, 0, 0, 0)])])
	return _scenario(source, incoming, func(): return source.slices[0].channels[0].rate_carry_units_after == 0 and incoming.segments[0].channel_deltas[0].rate_carry_units_before == 5)
func _i_cont_17() -> Dictionary:
	var source := _apply(ReportLedger.create_empty(0), _active(0, 10, [_segment(0, 10, 10, 9)]))
	var incoming := _active(10, 20, [_segment(10, 20, 9, 8, &"T", 1, &"F", [&"A"], "r", [SimulationChannelDeltaResult.new(&"C", &"SOUL", 0, 0, 0, 1000, 0, 0, 5, 5)])])
	return _scenario(source, incoming, func(): return source.slices[0].channels[0].total_banked_units_after == 0 and incoming.segments[0].channel_deltas[0].total_banked_units_before == 5)
func _i_cont_18() -> Dictionary:
	var source := _apply(ReportLedger.create_empty(0), _active(0, 10, [_segment(0, 10, 10, 9)]))
	var incoming := _active(10, 20, [_segment(10, 20, 8, 7)])
	return _scenario(source, incoming, func(): return source.slices[0].remaining_backlog_after == 9 and incoming.segments[0].remaining_backlog_before == 8 and source.slices[0].remaining_backlog_after != incoming.segments[0].remaining_backlog_before)

func _segment(start: int, finish: int, before: int, after: int, threshold: StringName = &"T", revision: int = 1, form: StringName = &"F", retinue: Array[StringName] = [&"A"], content: String = "r", channels: Array[SimulationChannelDeltaResult] = [], core_deltas: Dictionary = {}) -> SimulationSegmentResult:
	if channels.is_empty(): channels = [_input_channel(&"C", 0, 0, 0, 0)]
	var core := {"essence_delta": 0, "mastery_delta_subunits": 0, "completed_cycles_delta": 0}
	for key in core_deltas:
		if not core.has(key): return null
	core.merge(core_deltas, true)
	return SimulationSegmentResult.new(0, threshold, revision, form, &"W", retinue, &"OVERDUE", start, finish, finish - start, before - after, before - after, before, after, core.essence_delta, core.mastery_delta_subunits, core.completed_cycles_delta, channels)
func _input_channel(id: StringName, progress_before: int, progress_after: int, carry_before: int, carry_after: int, total_before: int = 0, total_after: int = 0) -> SimulationChannelDeltaResult:
	return SimulationChannelDeltaResult.new(id, &"SOUL", total_after - total_before, progress_before, progress_after, 1000, carry_before, carry_after, total_before, total_after)
func _active(start: int, finish: int, segments: Array[SimulationSegmentResult], content: String = "r", events: Array[SimulationEvent] = []) -> SimulationResult:
	return SimulationResult.active_reaping(finish - start, start, finish, content, segments, events)
func _timeline(start: int, finish: int) -> SimulationResult:
	if start == finish:
		return SimulationResult.zero_duration(start)
	return SimulationResult.timeline_only(finish - start, start, finish, "r")
func _wrapper(inner: SimulationResult, mode: StringName = SimulationRunService.MODE_FOREGROUND_SUPPLIED) -> SimulationRunService.SimulationRunResult:
	return SimulationRunService.SimulationRunResult.new(true, mode, &"", "", inner.requested_elapsed_msec, inner.baseline_simulation_time_msec, inner.result_simulation_time_msec, inner, null)
func _apply(source: ReportLedger, inner: SimulationResult) -> ReportLedger:
	var result := ReportLedgerIngestor.ingest_committed_run(source, _wrapper(inner))
	assert_eq(result.outcome, ReportLedgerIngestResult.APPLIED, "fixture applies")
	return result.candidate_ledger

func _apply_committed_wrappers(source: ReportLedger, runs: Array[SimulationRunService.SimulationRunResult]) -> ReportLedger:
	for run in runs:
		var result := ReportLedgerIngestor.ingest_committed_run(source, run)
		assert_eq(result.outcome, ReportLedgerIngestResult.APPLIED, "committed wrapper fixture applies")
		source = result.candidate_ledger
	return source
func _settlement_run(start: int, finish: int, before: int, after: int) -> SimulationResult:
	var segment := _segment(start, finish, before, after)
	var event := SimulationThresholdSettledEvent.new(finish, 0, &"T", 7, after, 0, &"OVERDUE", &"SETTLED")
	return _active(start, finish, [segment], "r", [event])
func _bank_run(start: int, finish: int, progress_before: int, progress_after: int, carry_before: int, carry_after: int, total_before: int, total_after: int) -> SimulationResult:
	var backlog_before := 10 if start == 0 else 9
	var backlog_after := 8 if start == 0 and finish == 20 else backlog_before - 1
	var segment := _segment(start, finish, backlog_before, backlog_after, &"T", 1, &"F", [&"A"], "r", [_input_channel(&"C", progress_before, progress_after, carry_before, carry_after, total_before, total_after)])
	var event := SimulationChannelBankedEvent.new(finish, 0, &"T", &"C", &"SOUL", total_after - total_before, &"OVERDUE", total_after, progress_after)
	return _active(start, finish, [segment], "r", [event])
func _settled_source() -> ReportLedger:
	var ledger := ReportLedger.create_empty(0)
	ledger.ingested_through_simulation_msec = 10
	ledger.foreground_elapsed_msec = 10
	var slice := ReportLedgerSlice.new()
	slice.run_mode = SimulationRunService.MODE_FOREGROUND_SUPPLIED
	slice.content_revision = "r"
	slice.threshold_id = &"T"
	slice.assignment_revision = 1
	slice.form_id = &"F"
	slice.writ_id = &"W"
	slice.ordered_retinue_ids = [&"A"]
	slice.lifecycle_state = &"SETTLED"
	slice.start_simulation_msec = 0
	slice.end_simulation_msec = 10
	ledger.slices.append(slice)
	assert_true(ReportLedgerValidator.validate(ledger).ok, "settled source validates")
	return ledger

func _invalid_root_source(cursor: int, foreground: int, offline: int, sequence: int) -> ReportLedger:
	var source := ReportLedger.create_empty(0)
	source.ingested_through_simulation_msec = cursor
	source.foreground_elapsed_msec = foreground
	source.offline_elapsed_msec = offline
	source.next_event_sequence = sequence
	return source

func _assert_source_validation_precedence(label: String, source: ReportLedger, expected_substring: String, note: String) -> void:
	var validation := ReportLedgerValidator.validate(source)
	assert_true(not validation.ok and validation.code == ReportLedgerValidator.FAILURE and validation.details.contains(expected_substring), "%s source validator rejects with the intended failure grammar and class" % label)
	var source_before := source.deep_clone()
	var run := _wrapper(_timeline(0, 10))
	var wrapper_before := _wrapper_snapshot(run)
	var inner_before := run.simulation_result.detached_copy()
	var result := ReportLedgerIngestor.ingest_committed_run(source, run)
	_assert_rejected(result, ReportLedgerIngestor.ERR_LEDGER_INVALID, source, source_before, run, wrapper_before, inner_before, "%s %s" % [label, note])
func _chunk(id: String, one_shot: Array[SimulationRunService.SimulationRunResult], chunked: Array[SimulationRunService.SimulationRunResult], probe: Callable, input_probe: Callable, expected_ledger: Dictionary) -> Dictionary:
	return {"id": id, "one_shot": one_shot, "chunked": chunked, "probe": probe, "input_probe": input_probe, "expected_ledger": expected_ledger}

func _continuity_endpoints_match(source: ReportLedgerSlice, incoming: SimulationSegmentResult) -> bool:
	var prior := source.channels[0]
	var current := incoming.channel_deltas[0]
	return source.threshold_id == incoming.threshold_id and source.assignment_revision == incoming.assignment_revision and source.form_id == incoming.form_id and source.writ_id == incoming.writ_id and source.ordered_retinue_ids == incoming.ordered_retinue_ids and source.remaining_backlog_after == incoming.remaining_backlog_before and prior.channel_id == current.channel_id and prior.output_item_id == current.output_item_id and prior.rate_period_msec == current.rate_period_msec and prior.progress_subunits_after == current.progress_subunits_before and prior.rate_carry_units_after == current.rate_carry_units_before and prior.total_banked_units_after == current.total_banked_units_before

func _new_channel_d_has_supplied_endpoints(channel: SimulationChannelDeltaResult) -> bool:
	return channel.channel_id == &"D" and channel.output_item_id == &"SOUL" and channel.rate_period_msec == 1000 and channel.progress_subunits_before == 3 and channel.rate_carry_units_before == 5 and channel.total_banked_units_before == 0

func _chunk_01_witness() -> Dictionary:
	return _ledger_witness({"ingested_through_simulation_msec": 20, "foreground_elapsed_msec": 20, "slices": [_slice_witness({"start_simulation_msec": 0, "end_simulation_msec": 20, "returned_souls_delta": 2, "remaining_backlog_before": 10, "remaining_backlog_after": 8, "essence_delta": 11, "mastery_delta_subunits": 13, "completed_cycles_delta": 17, "channels": [_channel_witness({"start_simulation_msec": 0, "end_simulation_msec": 20})]})]})
func _chunk_02_witness() -> Dictionary:
	return _ledger_witness({"ingested_through_simulation_msec": 20, "foreground_elapsed_msec": 20})
func _chunk_03_witness() -> Dictionary:
	return _ledger_witness({"ingested_through_simulation_msec": 20, "foreground_elapsed_msec": 20, "next_event_sequence": 2, "slices": [_slice_witness({"start_simulation_msec": 0, "end_simulation_msec": 20, "returned_souls_delta": 2, "remaining_backlog_before": 2, "channels": [_channel_witness({"start_simulation_msec": 0, "end_simulation_msec": 20})]})], "settlement_events": [_settlement_witness({"occurred_simulation_msec": 20})]})
func _chunk_04_witness() -> Dictionary:
	return _ledger_witness({"ingested_through_simulation_msec": 20, "foreground_elapsed_msec": 20, "slices": [_slice_witness({"start_simulation_msec": 0, "end_simulation_msec": 20, "returned_souls_delta": 2, "remaining_backlog_before": 10, "remaining_backlog_after": 8, "channels": [_channel_witness({"start_simulation_msec": 0, "end_simulation_msec": 20, "progress_subunits_before": 2, "progress_subunits_after": 7, "rate_carry_units_before": 2, "rate_carry_units_after": 7, "total_banked_units_before": 2, "total_banked_units_after": 7})]})]})

func _ledger_witness(overrides: Dictionary) -> Dictionary:
	return _complete_witness({"window_start_simulation_msec": 0, "ingested_through_simulation_msec": 0, "foreground_elapsed_msec": 0, "offline_elapsed_msec": 0, "debug_elapsed_msec": 0, "next_event_sequence": 1, "slices": [], "settlement_events": []}, LEDGER_FIELDS, overrides)
func _slice_witness(overrides: Dictionary) -> Dictionary:
	return _complete_witness({"run_mode": SimulationRunService.MODE_FOREGROUND_SUPPLIED, "content_revision": "r", "threshold_id": &"T", "assignment_revision": 1, "form_id": &"F", "writ_id": &"W", "ordered_retinue_ids": [&"A"], "lifecycle_state": &"OVERDUE", "start_simulation_msec": 0, "end_simulation_msec": 0, "returned_souls_delta": 0, "remaining_backlog_before": 0, "remaining_backlog_after": 0, "essence_delta": 0, "mastery_delta_subunits": 0, "completed_cycles_delta": 0, "channels": []}, SLICE_FIELDS, overrides)
func _channel_witness(overrides: Dictionary) -> Dictionary:
	return _complete_witness({"channel_id": &"C", "output_item_id": &"SOUL", "start_simulation_msec": 0, "end_simulation_msec": 0, "progress_subunits_before": 0, "progress_subunits_after": 0, "rate_period_msec": 1000, "rate_carry_units_before": 0, "rate_carry_units_after": 0, "total_banked_units_before": 0, "total_banked_units_after": 0}, CHANNEL_FIELDS, overrides)
func _settlement_witness(overrides: Dictionary) -> Dictionary:
	return _complete_witness({"event_sequence": 1, "content_revision": "r", "threshold_id": &"T", "assignment_revision": 1, "occurred_simulation_msec": 0, "persistent_returns_total": 7}, SETTLEMENT_FIELDS, overrides)
func _complete_witness(fields: Dictionary, exact_fields: Array, overrides: Dictionary) -> Dictionary:
	if not _has_exact_keys(fields, exact_fields): return {}
	for key in overrides:
		if not fields.has(key): return {}
	fields.merge(overrides, true)
	return fields.duplicate(true) if _has_exact_keys(fields, exact_fields) else {}
func _ledger_matches_witness(ledger: ReportLedger, expected: Dictionary) -> bool:
	if ledger == null or not _has_exact_keys(expected, LEDGER_FIELDS) or not _fields_match(ledger, expected, LEDGER_FIELDS, ["slices", "settlement_events"]): return false
	if ledger.slices.size() != expected.slices.size() or ledger.settlement_events.size() != expected.settlement_events.size(): return false
	for index in ledger.slices.size():
		var actual: ReportLedgerSlice = ledger.slices[index]; var witness: Dictionary = expected.slices[index]
		if not _has_exact_keys(witness, SLICE_FIELDS) or not _fields_match(actual, witness, SLICE_FIELDS, ["channels"]) or actual.channels.size() != witness.channels.size(): return false
		for channel_index in actual.channels.size():
			var channel: ReportLedgerChannel = actual.channels[channel_index]; var channel_witness: Dictionary = witness.channels[channel_index]
			if not _has_exact_keys(channel_witness, CHANNEL_FIELDS) or not _fields_match(channel, channel_witness, CHANNEL_FIELDS): return false
	for index in ledger.settlement_events.size():
		var actual: ReportSettlementEvent = ledger.settlement_events[index]; var witness: Dictionary = expected.settlement_events[index]
		if not _has_exact_keys(witness, SETTLEMENT_FIELDS) or not _fields_match(actual, witness, SETTLEMENT_FIELDS): return false
	return true

func _has_exact_keys(witness: Dictionary, fields: Array) -> bool:
	if witness.size() != fields.size(): return false
	for field in fields:
		if not witness.has(field): return false
	return true

func _fields_match(actual: Object, witness: Dictionary, fields: Array, ignored: Array = []) -> bool:
	var actual_values := _field_values(actual)
	if not _has_exact_keys(actual_values, fields): return false
	for field in fields:
		if not ignored.has(field) and actual_values[field] != witness[field]: return false
	return true

func _field_values(actual: Object) -> Dictionary:
	if actual is ReportLedger:
		var ledger := actual as ReportLedger
		return {"window_start_simulation_msec": ledger.window_start_simulation_msec, "ingested_through_simulation_msec": ledger.ingested_through_simulation_msec, "foreground_elapsed_msec": ledger.foreground_elapsed_msec, "offline_elapsed_msec": ledger.offline_elapsed_msec, "debug_elapsed_msec": ledger.debug_elapsed_msec, "next_event_sequence": ledger.next_event_sequence, "slices": ledger.slices, "settlement_events": ledger.settlement_events}
	if actual is ReportLedgerSlice:
		var slice := actual as ReportLedgerSlice
		return {"run_mode": slice.run_mode, "content_revision": slice.content_revision, "threshold_id": slice.threshold_id, "assignment_revision": slice.assignment_revision, "form_id": slice.form_id, "writ_id": slice.writ_id, "ordered_retinue_ids": slice.ordered_retinue_ids, "lifecycle_state": slice.lifecycle_state, "start_simulation_msec": slice.start_simulation_msec, "end_simulation_msec": slice.end_simulation_msec, "returned_souls_delta": slice.returned_souls_delta, "remaining_backlog_before": slice.remaining_backlog_before, "remaining_backlog_after": slice.remaining_backlog_after, "essence_delta": slice.essence_delta, "mastery_delta_subunits": slice.mastery_delta_subunits, "completed_cycles_delta": slice.completed_cycles_delta, "channels": slice.channels}
	if actual is ReportLedgerChannel:
		var channel := actual as ReportLedgerChannel
		return {"channel_id": channel.channel_id, "output_item_id": channel.output_item_id, "start_simulation_msec": channel.start_simulation_msec, "end_simulation_msec": channel.end_simulation_msec, "progress_subunits_before": channel.progress_subunits_before, "progress_subunits_after": channel.progress_subunits_after, "rate_period_msec": channel.rate_period_msec, "rate_carry_units_before": channel.rate_carry_units_before, "rate_carry_units_after": channel.rate_carry_units_after, "total_banked_units_before": channel.total_banked_units_before, "total_banked_units_after": channel.total_banked_units_after}
	if actual is ReportSettlementEvent:
		var settlement := actual as ReportSettlementEvent
		return {"event_sequence": settlement.event_sequence, "content_revision": settlement.content_revision, "threshold_id": settlement.threshold_id, "assignment_revision": settlement.assignment_revision, "occurred_simulation_msec": settlement.occurred_simulation_msec, "persistent_returns_total": settlement.persistent_returns_total}
	return {}

func _wrapper_snapshot(run: SimulationRunService.SimulationRunResult) -> Dictionary:
	return {"success": run.success, "mode": run.mode, "error_code": run.error_code, "developer_details": run.developer_details, "requested_elapsed_msec": run.requested_elapsed_msec, "baseline_simulation_time_msec": run.baseline_simulation_time_msec, "result_simulation_time_msec": run.result_simulation_time_msec, "simulation_result": run.simulation_result, "projected_state": run.projected_state}

func _assert_applied(result: ReportLedgerIngestResult, source: ReportLedger, snapshot: ReportLedger, run: SimulationRunService.SimulationRunResult, wrapper: Dictionary, inner: SimulationResult, label: String) -> void:
	assert_eq(result.outcome, ReportLedgerIngestResult.APPLIED, label)
	assert_true(result.success, label)
	assert_true(result.changed, label)
	assert_eq(result.error_code, &"", label)
	assert_eq(result.developer_details, "", label)
	assert_not_null(result.candidate_ledger, label)
	assert_true(ReportLedgerValidator.validate(result.candidate_ledger).ok, label)
	assert_ne(result.candidate_ledger, source, label)
	assert_true(source.value_equals(snapshot), label)
	_assert_run_unchanged(run, wrapper, inner, label)

func _assert_rejected(result: ReportLedgerIngestResult, code: StringName, source: ReportLedger, snapshot: ReportLedger, run: SimulationRunService.SimulationRunResult, wrapper: Dictionary, inner: SimulationResult, label: String) -> void:
	assert_eq(result.outcome, ReportLedgerIngestResult.REJECTED, label)
	assert_false(result.success, label)
	assert_false(result.changed, label)
	assert_eq(result.error_code, code, label)
	assert_ne(result.developer_details, "", label)
	assert_null(result.candidate_ledger, label)
	assert_true(source.value_equals(snapshot), label)
	_assert_run_unchanged(run, wrapper, inner, label)

func _assert_run_unchanged(run: SimulationRunService.SimulationRunResult, wrapper: Dictionary, inner: SimulationResult, label: String) -> void:
	assert_eq(_wrapper_snapshot(run), wrapper, "%s wrapper scalar state unchanged" % label)
	assert_eq(run.simulation_result, wrapper.simulation_result, "%s simulation-result reference unchanged" % label)
	assert_eq(run.projected_state, wrapper.projected_state, "%s projected-state reference unchanged" % label)
	assert_true(run.simulation_result.value_equals(inner), "%s inner segment/channel/event facts unchanged" % label)

func _runs_snapshot(runs: Array[SimulationRunService.SimulationRunResult]) -> Array:
	var snapshots: Array = []
	for run in runs:
		snapshots.append({"wrapper": _wrapper_snapshot(run), "inner": run.simulation_result.detached_copy()})
	return snapshots

func _assert_runs_unchanged(runs: Array[SimulationRunService.SimulationRunResult], snapshots: Array, label: String) -> void:
	assert_eq(runs.size(), snapshots.size(), "%s snapshot cardinality" % label)
	for index in runs.size():
		_assert_run_unchanged(runs[index], snapshots[index].wrapper, snapshots[index].inner, "%s %s" % [label, index])
func _same_wrapper_interval(one_shot: Array[SimulationRunService.SimulationRunResult], chunked: Array[SimulationRunService.SimulationRunResult]) -> bool:
	return one_shot[0].baseline_simulation_time_msec == chunked[0].baseline_simulation_time_msec and one_shot[0].result_simulation_time_msec == chunked.back().result_simulation_time_msec

func _same_wrapper_mode(one_shot: Array[SimulationRunService.SimulationRunResult], chunked: Array[SimulationRunService.SimulationRunResult]) -> bool:
	for run in chunked:
		if run.mode != one_shot[0].mode:
			return false
	return true

func _settlement_count(inner: SimulationResult) -> int:
	var count := 0
	for event in inner.events:
		if event is SimulationThresholdSettledEvent:
			count += 1
	return count

func _bank_count(inner: SimulationResult) -> int:
	var count := 0
	for event in inner.events:
		if event is SimulationChannelBankedEvent:
			count += 1
	return count

func _settlement_input_is_exact(inner: SimulationResult) -> bool:
	if _settlement_count(inner) != 1:
		return false
	var event := inner.events[0]
	return event is SimulationThresholdSettledEvent and event.segment_index == 0 and event.subject_id == &"T" and event.occurred_simulation_msec == inner.result_simulation_time_msec and event.lifecycle_before == &"OVERDUE" and event.lifecycle_after == &"SETTLED"

func _bank_input_matches_channel(inner: SimulationResult) -> bool:
	if _bank_count(inner) != 1:
		return false
	var event := inner.events[0]
	var channel := inner.segments[0].channel_deltas[0]
	return event is SimulationChannelBankedEvent and event.segment_index == 0 and event.occurred_simulation_msec == inner.segments[0].end_simulation_msec and event.subject_id == inner.segments[0].threshold_id and event.source_id == channel.channel_id and event.total_banked_units_after == channel.total_banked_units_after and event.progress_subunits_after == channel.progress_subunits_after

func _core_deltas_match(segment: SimulationSegmentResult, essence: int, mastery: int, cycles: int) -> bool:
	return segment.essence_delta == essence and segment.mastery_delta_subunits == mastery and segment.completed_cycles_delta == cycles

func _unique(values: Array) -> bool:
	var seen := {}
	for value in values:
		if seen.has(value): return false
		seen[value] = true
	return true
