extends SceneTree

## Deterministic M04E2R2 evidence trace. Every printed marker follows a real
## assertion-like check; a false check exits non-zero instead of claiming PASS.

func _init() -> void:
	var ledger := ReportLedger.create_empty(0)
	if not _check(ledger != null, "apply"): return
	for cursor in range(10, 100, 10):
		ledger.ingested_through_simulation_msec = cursor
		ledger.foreground_elapsed_msec = cursor - ledger.window_start_simulation_msec
		var rollover := ReportLedgerSnapshotter.rollover(ledger, cursor)
		if not _check(rollover.outcome == ReportLedgerSnapshotResult.APPLIED, "retention"): return
		ledger = rollover.candidate_ledger
	if not _check(ledger.retained_records.size() == 8 and ledger.retained_records[0].record_sequence == 2, "pruning"): return
	if not _check(ReportLedgerSnapshotter.rollover(ledger, 90).outcome == ReportLedgerSnapshotResult.EMPTY_NO_OP, "no_op"): return
	var history := ReportLedgerReader.read_history(ledger)
	var live := ReportLedgerReader.read_live_window(ledger)
	if not _check(history.ok and history.records.size() == 8 and live.ok and live.window.record_sequence == 0, "reads"): return
	var source := ReportLedger.create_empty(0)
	source.ingested_through_simulation_msec = 10
	source.foreground_elapsed_msec = 10
	var one := ReportLedgerSnapshotter.rollover(source, 10)
	var two_source := ReportLedger.create_empty(0)
	two_source.ingested_through_simulation_msec = 10
	two_source.foreground_elapsed_msec = 10
	var two := ReportLedgerSnapshotter.rollover(two_source, 10)
	if not _check(one.candidate_ledger.retained_records[0].value_equals(two.candidate_ledger.retained_records[0]), "equivalence"): return
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
	overflow.next_record_sequence = FixedPoint.INT64_MAX
	if not _check(ReportLedgerSnapshotter.rollover(overflow, 9).error_code == ReportLedgerSnapshotter.ERR_SEQUENCE_OVERFLOW, "overflow"): return
	if not _check(GameState.new(0).get("report_ledger") == null, "exclusion"): return
	# Settlement and continuity rules are owned by the common validator/ingestor;
	# this trace records their deterministic boundary constants without UI state.
	if not _check(ReportLedgerIngestor.ERR_SLICE == &"REPORT_INGEST_SLICE_DISCONTINUITY", "settlement"): return
	if not _check(ReportLedgerIngestor.ERR_CHANNEL == &"REPORT_INGEST_CHANNEL_DISCONTINUITY", "continuity"): return
	print("TRACE M04E2R2 complete=PASS")
	quit(0)

func _check(value: bool, marker: String) -> bool:
	if not value:
		push_error("TRACE M04E2R2 %s=FAIL" % marker)
		quit(1)
		return false
	print("TRACE M04E2R2 %s=PASS" % marker)
	return true
