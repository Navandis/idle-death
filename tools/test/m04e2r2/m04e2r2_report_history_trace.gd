extends SceneTree

## Deterministic M04E2R2 evidence trace. Each marker is earned by the public
## report operations below; no marker is a spelling check for an error constant.

func _init() -> void:
	var applied_source := ReportLedger.create_empty(0)
	var applied_ingest := ReportLedgerIngestor.ingest_committed_run(applied_source, _active_run(0, 10, 2, 1, 0, 1, 0, 1, 0, 0))
	var applied_rollover := ReportLedgerSnapshotter.rollover(applied_ingest.candidate_ledger, 10)
	if not _check(
		applied_ingest.outcome == ReportLedgerIngestResult.APPLIED
		and applied_rollover.outcome == ReportLedgerSnapshotResult.APPLIED
		and applied_rollover.candidate_ledger.retained_records.size() == 1
		and applied_rollover.candidate_ledger.retained_records[0].slices.size() == 1
		and _empty_live_window(applied_rollover.candidate_ledger),
		"apply"
	): return

	var retained := applied_rollover.candidate_ledger
	for finish in range(20, 110, 10):
		var timeline := ReportLedgerIngestor.ingest_committed_run(retained, _timeline_run(finish - 10, finish))
		if timeline.outcome != ReportLedgerIngestResult.APPLIED: _fail("retention"); return
		var rollover := ReportLedgerSnapshotter.rollover(timeline.candidate_ledger, finish)
		if rollover.outcome != ReportLedgerSnapshotResult.APPLIED: _fail("retention"); return
		retained = rollover.candidate_ledger
	if not _check(retained.retained_records.size() == 8 and retained.retained_records[0].record_sequence == 3 and retained.retained_records[-1].record_sequence == 10, "retention"): return
	if not _check(retained.retained_records[0].window_start_simulation_msec == 20 and retained.window_start_simulation_msec == 100 and _empty_live_window(retained), "pruning"): return
	if not _check(ReportLedgerSnapshotter.rollover(retained, 100).outcome == ReportLedgerSnapshotResult.EMPTY_NO_OP, "no_op"): return
	var history := ReportLedgerReader.read_history(retained)
	var live := ReportLedgerReader.read_live_window(retained)
	if not _check(history.ok and history.records.size() == 8 and history.records[0].record_sequence == 3 and live.ok and live.window.record_sequence == 0 and _empty_record(live.window), "reads"): return

	var settled := _settled_baseline(true)
	if settled == null: return
	var settled_before := settled.deep_clone()
	var duplicate_event := SimulationThresholdSettledEvent.new(100, 0, &"T", 2, 0, 0, &"OVERDUE", &"SETTLED")
	var duplicate := ReportLedgerIngestor.ingest_committed_run(settled, _active_run(90, 100, 1, 0, 1, 2, 1, 2, 0, 0, [duplicate_event]))
	if not _check(duplicate.outcome == ReportLedgerIngestResult.REJECTED and duplicate.error_code == ReportLedgerIngestor.ERR_SLICE and duplicate.candidate_ledger == null and settled.value_equals(settled_before), "settlement"): return

	var continuity_source := _normal_baseline(false)
	if continuity_source == null: return
	var continuity_before := continuity_source.deep_clone()
	var discontinuity := ReportLedgerIngestor.ingest_committed_run(continuity_source, _active_run(10, 20, 1, 1, 99, 100, 1, 2, 0, 0))
	if not _check(discontinuity.outcome == ReportLedgerIngestResult.REJECTED and discontinuity.error_code == ReportLedgerIngestor.ERR_CHANNEL and discontinuity.candidate_ledger == null and continuity_source.value_equals(continuity_before), "continuity"): return

	var one_shot_source := ReportLedger.create_empty(0)
	var one_shot := ReportLedgerIngestor.ingest_committed_run(one_shot_source, _active_run(0, 20, 3, 1, 0, 2, 0, 2, 0, 0))
	var chunked_source := ReportLedger.create_empty(0)
	var first_chunk := ReportLedgerIngestor.ingest_committed_run(chunked_source, _active_run(0, 10, 3, 2, 0, 1, 0, 1, 0, 0))
	var second_chunk := ReportLedgerIngestor.ingest_committed_run(first_chunk.candidate_ledger, _active_run(10, 20, 2, 1, 1, 2, 1, 2, 0, 0))
	var one_shot_rollover := ReportLedgerSnapshotter.rollover(one_shot.candidate_ledger, 20)
	var chunked_rollover := ReportLedgerSnapshotter.rollover(second_chunk.candidate_ledger, 20)
	if not _check(one_shot.outcome == ReportLedgerIngestResult.APPLIED and first_chunk.outcome == ReportLedgerIngestResult.APPLIED and second_chunk.outcome == ReportLedgerIngestResult.APPLIED and one_shot_rollover.outcome == ReportLedgerSnapshotResult.APPLIED and chunked_rollover.outcome == ReportLedgerSnapshotResult.APPLIED and one_shot_rollover.candidate_ledger.retained_records[0].value_equals(chunked_rollover.candidate_ledger.retained_records[0]), "equivalence"): return

	var overflow := ReportLedger.create_empty(0)
	overflow.next_record_sequence = FixedPoint.INT64_MAX
	for index in range(8):
		var record := ReportWindowRecord.new()
		record.record_sequence = FixedPoint.INT64_MAX - 8 + index
		record.window_start_simulation_msec = index
		record.window_end_simulation_msec = index + 1
		record.foreground_elapsed_msec = 1
		overflow.retained_records.append(record)
	overflow.window_start_simulation_msec = 8
	overflow.ingested_through_simulation_msec = 9
	overflow.foreground_elapsed_msec = 1
	var overflow_result := ReportLedgerSnapshotter.rollover(overflow, 9)
	if not _check(overflow_result.outcome == ReportLedgerSnapshotResult.REJECTED and overflow_result.error_code == ReportLedgerSnapshotter.ERR_SEQUENCE_OVERFLOW, "overflow"): return
	if not _check(GameState.new(0).get("report_ledger") == null, "exclusion"): return
	print("TRACE M04E2R2 complete=PASS")
	quit(0)

func _normal_baseline(pruned: bool) -> ReportLedger:
	var source := ReportLedger.create_empty(0)
	var first := ReportLedgerIngestor.ingest_committed_run(source, _active_run(0, 10, 2, 1, 0, 1, 0, 1, 0, 0))
	if first == null:
		_fail("continuity")
		return null
	if first.outcome != ReportLedgerIngestResult.APPLIED:
		_fail("continuity")
		return null
	if first.candidate_ledger == null:
		_fail("continuity")
		return null
	var rollover := ReportLedgerSnapshotter.rollover(first.candidate_ledger, 10)
	if rollover == null:
		_fail("continuity")
		return null
	if rollover.outcome != ReportLedgerSnapshotResult.APPLIED:
		_fail("continuity")
		return null
	if rollover.candidate_ledger == null:
		_fail("continuity")
		return null
	return _prune(rollover.candidate_ledger, "continuity") if pruned else rollover.candidate_ledger

func _settled_baseline(pruned: bool) -> ReportLedger:
	var source := ReportLedger.create_empty(0)
	var event := SimulationThresholdSettledEvent.new(10, 0, &"T", 2, 0, 0, &"OVERDUE", &"SETTLED")
	var first := ReportLedgerIngestor.ingest_committed_run(source, _active_run(0, 10, 1, 0, 0, 1, 0, 1, 0, 0, [event]))
	if first == null:
		_fail("settlement")
		return null
	if first.outcome != ReportLedgerIngestResult.APPLIED:
		_fail("settlement")
		return null
	if first.candidate_ledger == null:
		_fail("settlement")
		return null
	var rollover := ReportLedgerSnapshotter.rollover(first.candidate_ledger, 10)
	if rollover == null:
		_fail("settlement")
		return null
	if rollover.outcome != ReportLedgerSnapshotResult.APPLIED:
		_fail("settlement")
		return null
	if rollover.candidate_ledger == null:
		_fail("settlement")
		return null
	return _prune(rollover.candidate_ledger, "settlement") if pruned else rollover.candidate_ledger

func _prune(source: ReportLedger, marker: String) -> ReportLedger:
	if source == null:
		_fail(marker)
		return null
	var current := source
	for finish in range(source.ingested_through_simulation_msec + 10, source.ingested_through_simulation_msec + 90, 10):
		var ingested := ReportLedgerIngestor.ingest_committed_run(current, _timeline_run(finish - 10, finish))
		if ingested == null:
			_fail(marker)
			return null
		if ingested.outcome != ReportLedgerIngestResult.APPLIED:
			_fail(marker)
			return null
		if ingested.candidate_ledger == null:
			_fail(marker)
			return null
		var rolled := ReportLedgerSnapshotter.rollover(ingested.candidate_ledger, finish)
		if rolled == null:
			_fail(marker)
			return null
		if rolled.outcome != ReportLedgerSnapshotResult.APPLIED:
			_fail(marker)
			return null
		if rolled.candidate_ledger == null:
			_fail(marker)
			return null
		current = rolled.candidate_ledger
	return current

func _active_run(start: int, finish: int, backlog_before: int, backlog_after: int, progress_before: int, progress_after: int, carry_before: int, carry_after: int, total_before: int, total_after: int, events: Array[SimulationEvent] = []) -> SimulationRunService.SimulationRunResult:
	var channel := SimulationChannelDeltaResult.new(&"C", &"SOUL", total_after - total_before, progress_before, progress_after, 1000, carry_before, carry_after, total_before, total_after)
	var segment := SimulationSegmentResult.new(0, &"T", 1, &"F", &"W", [&"A"], &"OVERDUE", start, finish, finish - start, backlog_before - backlog_after, backlog_before - backlog_after, backlog_before, backlog_after, 0, 0, 0, [channel])
	return _run(SimulationResult.active_reaping(finish - start, start, finish, "trace", [segment], events))

func _timeline_run(start: int, finish: int) -> SimulationRunService.SimulationRunResult:
	return _run(SimulationResult.timeline_only(finish - start, start, finish, "trace"))

func _run(inner: SimulationResult) -> SimulationRunService.SimulationRunResult:
	return SimulationRunService.SimulationRunResult.new(true, SimulationRunService.MODE_FOREGROUND_SUPPLIED, &"", "", inner.requested_elapsed_msec, inner.baseline_simulation_time_msec, inner.result_simulation_time_msec, inner, null)

func _empty_live_window(ledger: ReportLedger) -> bool:
	return ledger.slices.is_empty() and ledger.settlement_events.is_empty() and ledger.foreground_elapsed_msec == 0 and ledger.offline_elapsed_msec == 0 and ledger.debug_elapsed_msec == 0 and ledger.window_start_simulation_msec == ledger.ingested_through_simulation_msec

func _empty_record(record: ReportWindowRecord) -> bool:
	return record.slices.is_empty() and record.settlement_events.is_empty() and record.foreground_elapsed_msec == 0 and record.offline_elapsed_msec == 0 and record.debug_elapsed_msec == 0

func _check(value: bool, marker: String) -> bool:
	if not value:
		_fail(marker)
		return false
	print("TRACE M04E2R2 %s=PASS" % marker)
	return true

func _fail(marker: String) -> void:
	push_error("TRACE M04E2R2 %s=FAIL" % marker)
	quit(1)
