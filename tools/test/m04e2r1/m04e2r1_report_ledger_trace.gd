extends SceneTree

## Deterministic owner evidence for the R1 ledger boundary.  Each marker is
## emitted only after its complete assertion group has earned it.

var _failures := 0

func _init() -> void:
	_check_apply_duplicate_and_gap()
	_check_source_continuity()
	_check_active_chunk_invariance()
	_check_timeline_chunk_invariance()
	_check_settlement_chunk_invariance()
	_check_channel_banking_chunk_invariance()
	_check_settlement_and_bank_normalization()
	_check_persistence_exclusion()
	_check_merge_overflow()
	quit(1 if _failures > 0 else 0)

func _check_apply_duplicate_and_gap() -> void:
	var source := ReportLedger.create_empty(0)
	var source_before := source.deep_clone()
	var run := _timeline_run(0, 100)
	var applied := ReportLedgerIngestor.ingest_committed_run(source, run)
	var apply_ok: bool = applied.success and applied.changed and applied.outcome == ReportLedgerIngestResult.APPLIED \
		and applied.candidate_ledger != null and applied.candidate_ledger != source \
		and ReportLedgerValidator.validate(applied.candidate_ledger).ok and source.value_equals(source_before)
	_marker("apply", apply_ok, "exact-new application must return a detached valid candidate without source mutation")
	var candidate_before := applied.candidate_ledger.deep_clone() if apply_ok else null
	var duplicate: ReportLedgerIngestResult = null
	var gap: ReportLedgerIngestResult = null
	if apply_ok:
		duplicate = ReportLedgerIngestor.ingest_committed_run(applied.candidate_ledger, run)
		gap = ReportLedgerIngestor.ingest_committed_run(applied.candidate_ledger, _timeline_run(101, 111))
	_marker("duplicate_no_op", apply_ok and duplicate.success and not duplicate.changed and duplicate.outcome == ReportLedgerIngestResult.DUPLICATE_NO_OP \
		and duplicate.candidate_ledger == null and applied.candidate_ledger.value_equals(candidate_before), "redelivery must be a no-candidate no-op without mutation")
	_marker("forward_gap_reject", apply_ok and _rejected(gap, ReportLedgerIngestor.ERR_GAP) and applied.candidate_ledger.value_equals(candidate_before), "forward gap must reject with the stable grammar and preserve source")

func _check_source_continuity() -> void:
	var first := _ingest_or_null(ReportLedger.create_empty(0), _active_run([_segment(0, 100, 10, 9, 1, 0, 0, 0, 0, 0)]))
	var continued_result := ReportLedgerIngestor.ingest_committed_run(first, _active_run([_segment(100, 200, 9, 8, 1, 0, 0, 0, 0, 0)]))
	var continued: ReportLedger = continued_result.candidate_ledger
	var continued_before := continued.deep_clone() if continued != null else null
	var backlog_broken := ReportLedgerIngestor.ingest_committed_run(continued, _active_run([_segment(200, 300, 7, 6, 1, 0, 0, 0, 0, 0)]))
	var channel_broken := ReportLedgerIngestor.ingest_committed_run(continued, _active_run([_segment(200, 300, 8, 7, 1, 1, 1, 0, 0, 0)]))
	_marker("source_continuity_and_rejection_no_mutation", first != null and continued_result.success and continued != null \
		and continued.slices.size() == 1 and _rejected(backlog_broken, ReportLedgerIngestor.ERR_SLICE) \
		and _rejected(channel_broken, ReportLedgerIngestor.ERR_CHANNEL) and continued.value_equals(continued_before), "continuation must normalize; broken backlog/channel endpoints must reject without source mutation")

func _check_active_chunk_invariance() -> void:
	var one_shot := _ingest_or_null(ReportLedger.create_empty(0), _active_run([_segment(0, 1000, 10, 8, 2, 0, 0, 0, 0, 0)]))
	var chunked := _ingest_or_null(ReportLedger.create_empty(0), _active_run([_segment(0, 500, 10, 9, 1, 0, 0, 0, 0, 0)]))
	chunked = _ingest_or_null(chunked, _active_run([_segment(500, 1000, 9, 8, 1, 0, 0, 0, 0, 0)]))
	_marker("active_one_shot_equals_chunks", one_shot != null and chunked != null and one_shot.value_equals(chunked), "same-mode active one-shot and chunks must normalize to equal ledgers")

func _check_timeline_chunk_invariance() -> void:
	var one_shot := _ingest_or_null(ReportLedger.create_empty(0), _timeline_run(0, 1000))
	var chunked := _ingest_or_null(ReportLedger.create_empty(0), _timeline_run(0, 400))
	chunked = _ingest_or_null(chunked, _timeline_run(400, 1000))
	_marker("timeline_one_shot_equals_chunks", one_shot != null and chunked != null and one_shot.value_equals(chunked), "positive timeline-only one-shot and chunks must be value-equal")

func _check_settlement_chunk_invariance() -> void:
	var overdue := _segment(0, 500, 1, 0, 1, 0, 0, 0, 0, 0)
	var settled := _settled_segment(500, 1000, 1)
	var one_shot := _ingest_or_null(ReportLedger.create_empty(0), _active_run([overdue, settled], true))
	var chunked := _ingest_or_null(ReportLedger.create_empty(0), _active_run([overdue], true))
	chunked = _ingest_or_null(chunked, _active_run([_settled_segment(500, 1000, 0)]))
	_marker("settlement_crossing_one_shot_equals_chunks", one_shot != null and chunked != null and one_shot.value_equals(chunked) \
		and one_shot.settlement_events.size() == 1 and one_shot.settlement_events[0].occurred_simulation_msec == 500, "Settlement-crossing one-shot and chunks must retain one equal normalized Settlement")

func _check_channel_banking_chunk_invariance() -> void:
	var one_shot := _ingest_or_null(ReportLedger.create_empty(0), _active_run([_segment(0, 1000, 10, 10, 0, 100, 900, 0, 0, 1)]))
	var chunked := _ingest_or_null(ReportLedger.create_empty(0), _active_run([_segment(0, 500, 10, 10, 0, 100, 500, 0, 0, 0)]))
	chunked = _ingest_or_null(chunked, _active_run([_segment(500, 1000, 10, 10, 0, 500, 900, 0, 0, 1)]))
	_marker("channel_progress_banking_one_shot_equals_chunks", one_shot != null and chunked != null and one_shot.value_equals(chunked) \
		and one_shot.slices.size() == 1 and one_shot.slices[0].channels[0].total_banked_units_after == 1, "channel progress and bank endpoints must be chunk-invariant")

func _check_settlement_and_bank_normalization() -> void:
	var segment := _segment(0, 1000, 1, 0, 1, 50, 950, 0, 0, 1)
	var ledger := _ingest_or_null(ReportLedger.create_empty(0), _active_run([segment], true))
	_marker("settlement_once_bank_events_folded", ledger != null and ledger.settlement_events.size() == 1 \
		and ledger.next_event_sequence == 2 and ledger.slices.size() == 1 and ledger.slices[0].channels.size() == 1 \
		and ledger.slices[0].channels[0].total_banked_units_before == 0 and ledger.slices[0].channels[0].total_banked_units_after == 1, "Settlement must remain once while validated bank events fold into channel endpoints")

func _check_persistence_exclusion() -> void:
	var ledger := ReportLedger.create_empty(0)
	var state := GameState.new(0)
	var snapshot := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION)
	var serialized := JSON.stringify(snapshot)
	var excluded := true
	for forbidden in ["ReportLedger", "report_ledger", "settlement_events", "ReportLedgerIngestor"]:
		excluded = excluded and not serialized.contains(forbidden)
	_marker("persistence_exclusion", ReportLedgerValidator.validate(ledger).ok and snapshot.schema_version == SaveInt64.format(3) and excluded, "real schema-v3 in-memory snapshot must exclude R1 ledger symbols")

func _check_merge_overflow() -> void:
	var max_value := FixedPoint.INT64_MAX
	var source := _ingest_or_null(ReportLedger.create_empty(0), _active_run([_segment(0, 10, 2, 2, 0, 0, 0, max_value, 0, 0)]))
	var source_before := source.deep_clone() if source != null else null
	var overflow := ReportLedgerIngestor.ingest_committed_run(source, _active_run([_segment(10, 20, 2, 2, 0, 0, 0, 1, 0, 0)]))
	_marker("overflow_rejected_without_mutation", source != null and _rejected(overflow, ReportLedgerIngestor.ERR_OVERFLOW) and source.value_equals(source_before), "compatible-slice core-delta merge overflow must reject without source mutation")

func _timeline_run(start: int, finish: int) -> SimulationRunService.SimulationRunResult:
	var inner := SimulationResult.timeline_only(finish - start, start, finish, ContentRegistry.CURRENT_REVISION)
	return _wrapper(inner)

func _active_run(segments: Array[SimulationSegmentResult], include_settlement: bool = false) -> SimulationRunService.SimulationRunResult:
	var events: Array[SimulationEvent] = []
	for segment in segments:
		for channel in segment.channel_deltas:
			if channel.banked_units_delta > 0:
				events.append(SimulationChannelBankedEvent.new(segment.end_simulation_msec, segment.segment_index, segment.threshold_id, channel.channel_id, channel.output_item_id, channel.banked_units_delta, segment.lifecycle_state, channel.total_banked_units_after, channel.progress_subunits_after))
	if include_settlement:
		var owner: SimulationSegmentResult = segments[0]
		events.append(SimulationThresholdSettledEvent.new(owner.end_simulation_msec, owner.segment_index, owner.threshold_id, 7, owner.remaining_backlog_after, 0, &"OVERDUE", &"SETTLED"))
	events.sort_custom(func(left: SimulationEvent, right: SimulationEvent) -> bool:
		if left.occurred_simulation_msec != right.occurred_simulation_msec: return left.occurred_simulation_msec < right.occurred_simulation_msec
		return left.priority < right.priority)
	var first: SimulationSegmentResult = segments[0]
	var last: SimulationSegmentResult = segments.back()
	var inner := SimulationResult.active_reaping(last.end_simulation_msec - first.start_simulation_msec, first.start_simulation_msec, last.end_simulation_msec, ContentRegistry.CURRENT_REVISION, segments, events)
	return _wrapper(inner)

func _segment(start: int, finish: int, backlog_before: int, backlog_after: int, souls: int, progress_before: int, progress_after: int, essence: int, total_before: int, total_after: int) -> SimulationSegmentResult:
	var channel := SimulationChannelDeltaResult.new(&"CHANNEL_TRACE", &"SOUL_TRACE", total_after - total_before, progress_before, progress_after, 1000, 0, 0, total_before, total_after)
	return SimulationSegmentResult.new(0, &"THR_TRACE", 1, &"FORM_TRACE", &"WRIT_TRACE", [&"RET_TRACE"], &"OVERDUE", start, finish, finish - start, souls, backlog_before - backlog_after, backlog_before, backlog_after, essence, 0, 0, [channel])

func _settled_segment(start: int, finish: int, index: int) -> SimulationSegmentResult:
	var channel := SimulationChannelDeltaResult.new(&"CHANNEL_TRACE", &"SOUL_TRACE", 0, 0, 0, 1000, 0, 0, 0, 0)
	return SimulationSegmentResult.new(index, &"THR_TRACE", 1, &"FORM_TRACE", &"WRIT_TRACE", [&"RET_TRACE"], &"SETTLED", start, finish, finish - start, 0, 0, 0, 0, 0, 0, 0, [channel])

func _wrapper(inner: SimulationResult) -> SimulationRunService.SimulationRunResult:
	return SimulationRunService.SimulationRunResult.new(true, SimulationRunService.MODE_FOREGROUND_SUPPLIED, &"", "", inner.requested_elapsed_msec, inner.baseline_simulation_time_msec, inner.result_simulation_time_msec, inner, null)

func _ingest_or_null(source: ReportLedger, run: SimulationRunService.SimulationRunResult) -> ReportLedger:
	var result := ReportLedgerIngestor.ingest_committed_run(source, run)
	return result.candidate_ledger if result.success and result.changed else null

func _rejected(result: ReportLedgerIngestResult, code: StringName) -> bool:
	return result != null and not result.success and not result.changed and result.outcome == ReportLedgerIngestResult.REJECTED \
		and result.error_code == code and not result.developer_details.is_empty() and result.candidate_ledger == null

func _marker(name: String, passed: bool, diagnostic: String) -> void:
	if passed:
		print("TRACE M04E2R1 %s=PASS" % name)
	else:
		_failures += 1
		print("TRACE M04E2R1 %s=FAIL: %s" % [name, diagnostic])
