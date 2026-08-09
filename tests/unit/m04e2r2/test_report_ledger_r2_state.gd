extends GutTest

func test_continuation_and_record_clone_equality_cover_owned_children() -> void:
	var channel := ReportChannelContinuation.new()
	channel.channel_id = &"C"
	channel.output_item_id = &"SOUL"
	channel.rate_period_msec = 1000
	var continuation := ReportThresholdContinuation.new()
	continuation.threshold_id = &"T"
	continuation.latest_assignment_revision = 1
	continuation.form_id = &"F"
	continuation.writ_id = &"W"
	continuation.lifecycle_state = &"OVERDUE"
	continuation.remaining_backlog = 1
	continuation.channels.append(channel)
	var copy := continuation.deep_clone()
	assert_true(copy.value_equals(continuation), "continuation clone is equal")
	copy.channels[0].rate_period_msec = 999
	assert_false(copy.value_equals(continuation), "channel endpoint participates in equality")
	assert_eq(continuation.channels[0].rate_period_msec, 1000, "channel clone is detached")

func test_validator_accepts_only_production_reachable_continuation_tuples() -> void:
	var accepted := [
		[&"OVERDUE", 1, false],
		[&"OVERDUE", 0, true],
		[&"SETTLED", 0, true]
	]
	for tuple in accepted:
		assert_true(ReportLedgerValidator.validate(_continuation_ledger(tuple[0], tuple[1], tuple[2])).ok, "authorized tuple %s/%s/%s validates" % tuple)
	var rejected := [
		[&"OVERDUE", 1, true],
		[&"OVERDUE", 0, false],
		[&"SETTLED", 1, false],
		[&"SETTLED", 1, true],
		[&"SETTLED", 0, false]
	]
	for tuple in rejected:
		assert_false(ReportLedgerValidator.validate(_continuation_ledger(tuple[0], tuple[1], tuple[2])).ok, "impossible tuple %s/%s/%s rejects" % tuple)
	assert_true(ReportLedgerValidator.validate(_continuation_ledger(&"OVERDUE", 0, true)).ok, "Settlement boundary endpoint without following SETTLED work is valid")

func test_validator_rejects_reused_mutable_report_nodes_across_complete_graph() -> void:
	var shared_child := _two_continuation_ledger()
	shared_child.threshold_continuations[1].channels[0] = shared_child.threshold_continuations[0].channels[0]
	var rows := [
		["continuation root", _reused_continuation_root()],
		["continuation child", shared_child],
		["record root", _reused_record_root()],
		["slice root", _reused_slice_root()],
		["slice channel child", _reused_slice_channel()],
		["Settlement event root", _reused_settlement_event()],
		["live-to-retained slice", _live_to_retained_slice_alias()]
	]
	for row in rows:
		assert_false(ReportLedgerValidator.validate(row[1]).ok, "%s reuse rejects" % row[0])
	assert_true(ReportLedgerValidator.validate(_two_continuation_ledger()).ok, "equivalent fully detached graph validates")

func _continuation_ledger(lifecycle: StringName, backlog: int, settled: bool) -> ReportLedger:
	var ledger := ReportLedger.create_empty(0)
	ledger.threshold_continuations.append(_continuation(&"T", lifecycle, backlog, settled))
	return ledger

func _continuation(id: StringName, lifecycle: StringName = &"OVERDUE", backlog: int = 1, settled: bool = false) -> ReportThresholdContinuation:
	var continuation := ReportThresholdContinuation.new()
	continuation.threshold_id = id
	continuation.latest_assignment_revision = 1
	continuation.form_id = &"F"
	continuation.writ_id = &"W"
	continuation.lifecycle_state = lifecycle
	continuation.remaining_backlog = backlog
	continuation.has_settled = settled
	var channel := ReportChannelContinuation.new()
	channel.channel_id = &"C"
	channel.output_item_id = &"SOUL"
	channel.rate_period_msec = 1000
	continuation.channels.append(channel)
	return continuation

func _two_continuation_ledger() -> ReportLedger:
	var ledger := ReportLedger.create_empty(0)
	ledger.threshold_continuations = [_continuation(&"A"), _continuation(&"B")]
	return ledger

func _reused_continuation_root() -> ReportLedger:
	var ledger := ReportLedger.create_empty(0)
	var continuation := _continuation(&"A")
	ledger.threshold_continuations = [continuation, continuation]
	return ledger

func _reused_record_root() -> ReportLedger:
	var ledger := ReportLedger.create_empty(0)
	var record := _record(1, 0, 10)
	ledger.retained_records = [record, record]
	ledger.next_record_sequence = 3
	ledger.window_start_simulation_msec = 10
	ledger.ingested_through_simulation_msec = 10
	return ledger

func _reused_slice_root() -> ReportLedger:
	var ledger := _detail_ledger()
	ledger.slices.append(ledger.slices[0])
	ledger.ingested_through_simulation_msec = 20
	ledger.foreground_elapsed_msec = 20
	return ledger

func _reused_slice_channel() -> ReportLedger:
	var ledger := _detail_ledger()
	ledger.slices[0].channels.append(ledger.slices[0].channels[0])
	return ledger

func _reused_settlement_event() -> ReportLedger:
	var ledger := _detail_ledger()
	ledger.settlement_events.append(ledger.settlement_events[0])
	return ledger

func _live_to_retained_slice_alias() -> ReportLedger:
	var ledger := _detail_ledger()
	var record := _record(1, 0, 10)
	record.slices.append(ledger.slices[0])
	record.settlement_events.append(ledger.settlement_events[0].deep_clone())
	ledger.retained_records.append(record)
	ledger.next_record_sequence = 2
	return ledger

func _detail_ledger() -> ReportLedger:
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
	slice.lifecycle_state = &"OVERDUE"
	slice.start_simulation_msec = 0
	slice.end_simulation_msec = 10
	slice.returned_souls_delta = 1
	slice.remaining_backlog_before = 1
	slice.remaining_backlog_after = 0
	var channel := ReportLedgerChannel.new()
	channel.channel_id = &"C"
	channel.output_item_id = &"SOUL"
	channel.start_simulation_msec = 0
	channel.end_simulation_msec = 10
	channel.rate_period_msec = 1000
	slice.channels.append(channel)
	ledger.slices.append(slice)
	var event := ReportSettlementEvent.new()
	event.event_sequence = 1
	event.content_revision = "r"
	event.threshold_id = &"T"
	event.assignment_revision = 1
	event.occurred_simulation_msec = 10
	ledger.settlement_events.append(event)
	ledger.next_event_sequence = 2
	ledger.threshold_continuations.append(_continuation(&"T", &"OVERDUE", 0, true))
	return ledger

func _record(sequence: int, start: int, finish: int) -> ReportWindowRecord:
	var record := ReportWindowRecord.new()
	record.record_sequence = sequence
	record.window_start_simulation_msec = start
	record.window_end_simulation_msec = finish
	record.foreground_elapsed_msec = finish - start
	return record
