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
	var rows := []
	var continuation_root := _two_continuation_ledger()
	assert_true(ReportLedgerValidator.validate(continuation_root).ok, "continuation root baseline validates")
	continuation_root.threshold_continuations[1] = continuation_root.threshold_continuations[0]
	rows.append(["continuation root", continuation_root])

	var continuation_channel := _two_continuation_ledger()
	assert_true(ReportLedgerValidator.validate(continuation_channel).ok, "continuation channel baseline validates")
	continuation_channel.threshold_continuations[1].channels[0] = continuation_channel.threshold_continuations[0].channels[0]
	rows.append(["continuation channel", continuation_channel])

	var record_root := _two_record_ledger()
	assert_true(ReportLedgerValidator.validate(record_root).ok, "record root baseline validates")
	record_root.retained_records[1] = record_root.retained_records[0]
	rows.append(["record root", record_root])

	var slice_root := _childless_slice_ledger()
	assert_true(ReportLedgerValidator.validate(slice_root).ok, "slice root baseline validates")
	slice_root.slices[1] = slice_root.slices[0]
	rows.append(["slice root", slice_root])

	var slice_channel := _two_channel_slice_ledger()
	assert_true(ReportLedgerValidator.validate(slice_channel).ok, "slice channel baseline validates")
	slice_channel.slices[1].channels[0] = slice_channel.slices[0].channels[0]
	rows.append(["slice channel", slice_channel])

	var settlement_event := _detail_ledger()
	assert_true(ReportLedgerValidator.validate(settlement_event).ok, "Settlement event baseline validates")
	settlement_event.settlement_events.append(settlement_event.settlement_events[0])
	rows.append(["Settlement event", settlement_event])

	var live_to_retained := _retained_live_childless_slice_ledger()
	assert_true(ReportLedgerValidator.validate(live_to_retained).ok, "live-to-retained baseline validates")
	live_to_retained.retained_records[0].slices[0] = live_to_retained.slices[0]
	rows.append(["live-to-retained slice", live_to_retained])

	for row in rows:
		var failure := ReportLedgerValidator.validate(row[1])
		assert_false(failure.ok, "%s reuse rejects" % row[0])
		assert_eq(failure.code, ReportLedgerValidator.FAILURE, "%s reports the identity failure code" % row[0])
		assert_eq(failure.details, "Ledger-owned mutable report node is reused.", "%s reports the identity failure details" % row[0])
	assert_true(ReportLedgerValidator.validate(_retained_live_childless_slice_ledger()).ok, "fully detached graph validates")

func _continuation_ledger(lifecycle: StringName, backlog: int, settled: bool) -> ReportLedger:
	var ledger := ReportLedger.create_empty(0)
	ledger.threshold_continuations.append(_continuation(&"T", lifecycle, backlog, settled))
	return ledger

func _continuation(id: StringName, lifecycle: StringName = &"OVERDUE", backlog: int = 1, settled: bool = false, channel_id: StringName = &"C") -> ReportThresholdContinuation:
	var continuation := ReportThresholdContinuation.new()
	continuation.threshold_id = id
	continuation.latest_assignment_revision = 1
	continuation.form_id = &"F"
	continuation.writ_id = &"W"
	continuation.lifecycle_state = lifecycle
	continuation.remaining_backlog = backlog
	continuation.has_settled = settled
	if not str(channel_id).is_empty():
		var channel := ReportChannelContinuation.new()
		channel.channel_id = channel_id
		channel.output_item_id = &"SOUL"
		channel.rate_period_msec = 1000
		continuation.channels.append(channel)
	return continuation

func _two_continuation_ledger() -> ReportLedger:
	var ledger := ReportLedger.create_empty(0)
	ledger.threshold_continuations = [_continuation(&"A"), _continuation(&"B")]
	return ledger

func _two_record_ledger() -> ReportLedger:
	var ledger := ReportLedger.create_empty(0)
	ledger.retained_records = [_record(1, 0, 10), _record(2, 10, 20)]
	ledger.next_record_sequence = 3
	ledger.window_start_simulation_msec = 20
	ledger.ingested_through_simulation_msec = 20
	return ledger

func _childless_slice_ledger() -> ReportLedger:
	var ledger := ReportLedger.create_empty(0)
	ledger.ingested_through_simulation_msec = 20
	ledger.foreground_elapsed_msec = 20
	ledger.slices = [_slice(&"A", 0, 10), _slice(&"B", 10, 20)]
	ledger.threshold_continuations = [_continuation(&"A", &"OVERDUE", 1, false, &""), _continuation(&"B", &"OVERDUE", 1, false, &"")]
	return ledger

func _two_channel_slice_ledger() -> ReportLedger:
	var ledger := ReportLedger.create_empty(0)
	ledger.ingested_through_simulation_msec = 20
	ledger.foreground_elapsed_msec = 20
	ledger.slices = [_slice(&"A", 0, 10, &"CA"), _slice(&"B", 10, 20, &"CB")]
	ledger.threshold_continuations = [_continuation(&"A", &"OVERDUE", 1, false, &"CA"), _continuation(&"B", &"OVERDUE", 1, false, &"CB")]
	return ledger

func _retained_live_childless_slice_ledger() -> ReportLedger:
	var ledger := ReportLedger.create_empty(0)
	var record := _record(1, 0, 10)
	record.slices.append(_slice(&"T", 0, 10))
	ledger.retained_records = [record]
	ledger.next_record_sequence = 2
	ledger.window_start_simulation_msec = 10
	ledger.ingested_through_simulation_msec = 20
	ledger.foreground_elapsed_msec = 10
	ledger.slices = [_slice(&"T", 10, 20)]
	ledger.threshold_continuations = [_continuation(&"T", &"OVERDUE", 1, false, &"")]
	return ledger

func _slice(threshold_id: StringName, start: int, finish: int, channel_id: StringName = &"") -> ReportLedgerSlice:
	var slice := ReportLedgerSlice.new()
	slice.run_mode = SimulationRunService.MODE_FOREGROUND_SUPPLIED
	slice.content_revision = "r"
	slice.threshold_id = threshold_id
	slice.assignment_revision = 1
	slice.form_id = &"F"
	slice.writ_id = &"W"
	slice.lifecycle_state = &"OVERDUE"
	slice.start_simulation_msec = start
	slice.end_simulation_msec = finish
	slice.remaining_backlog_before = 1
	slice.remaining_backlog_after = 1
	if not str(channel_id).is_empty():
		var channel := ReportLedgerChannel.new()
		channel.channel_id = channel_id
		channel.output_item_id = &"SOUL"
		channel.start_simulation_msec = start
		channel.end_simulation_msec = finish
		channel.rate_period_msec = 1000
		slice.channels.append(channel)
	return slice

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
