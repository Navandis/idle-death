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
	var continuation_root := ReportLedger.create_empty(0)
	continuation_root.threshold_continuations = [
		_continuation(&"A", &"OVERDUE", 1, false, &""),
		_continuation(&"B", &"OVERDUE", 1, false, &"")
	]
	assert_true(ReportLedgerValidator.validate(continuation_root).ok, "continuation root baseline validates")
	assert_ne(continuation_root.threshold_continuations[0], continuation_root.threshold_continuations[1], "continuation roots are independently allocated")
	assert_true(continuation_root.threshold_continuations[0].channels.is_empty(), "first continuation root is childless")
	assert_true(continuation_root.threshold_continuations[1].channels.is_empty(), "second continuation root is childless")
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

func test_validator_rejects_reused_mutable_report_array_containers_across_complete_graph() -> void:
	var rows := []
	var continuation_retinue := _two_continuation_ledger()
	assert_true(ReportLedgerValidator.validate(continuation_retinue).ok, "continuation Retinue baseline validates")
	assert_false(is_same(continuation_retinue.threshold_continuations[0].ordered_retinue_ids, continuation_retinue.threshold_continuations[1].ordered_retinue_ids), "continuation Retinue containers are independently allocated")
	continuation_retinue.threshold_continuations[1].ordered_retinue_ids = continuation_retinue.threshold_continuations[0].ordered_retinue_ids
	rows.append(["continuation Retinue", continuation_retinue])

	var slice_retinue := _childless_slice_ledger()
	assert_true(ReportLedgerValidator.validate(slice_retinue).ok, "slice Retinue baseline validates")
	assert_false(is_same(slice_retinue.slices[0].ordered_retinue_ids, slice_retinue.slices[1].ordered_retinue_ids), "slice Retinue containers are independently allocated")
	slice_retinue.slices[1].ordered_retinue_ids = slice_retinue.slices[0].ordered_retinue_ids
	rows.append(["slice Retinue", slice_retinue])

	var slice_to_continuation_retinue := _childless_slice_ledger()
	assert_true(ReportLedgerValidator.validate(slice_to_continuation_retinue).ok, "slice-to-continuation Retinue baseline validates")
	assert_false(is_same(slice_to_continuation_retinue.slices[0].ordered_retinue_ids, slice_to_continuation_retinue.threshold_continuations[0].ordered_retinue_ids), "slice and continuation Retinue containers are independently allocated")
	slice_to_continuation_retinue.threshold_continuations[0].ordered_retinue_ids = slice_to_continuation_retinue.slices[0].ordered_retinue_ids
	rows.append(["slice-to-continuation Retinue", slice_to_continuation_retinue])

	var continuation_channels := ReportLedger.create_empty(0)
	continuation_channels.threshold_continuations = [_continuation(&"A", &"OVERDUE", 1, false, &""), _continuation(&"B", &"OVERDUE", 1, false, &"")]
	assert_true(ReportLedgerValidator.validate(continuation_channels).ok, "empty continuation channels baseline validates")
	assert_false(is_same(continuation_channels.threshold_continuations[0].channels, continuation_channels.threshold_continuations[1].channels), "empty continuation channel containers are independently allocated")
	continuation_channels.threshold_continuations[1].channels = continuation_channels.threshold_continuations[0].channels
	rows.append(["empty continuation channels", continuation_channels])

	var slice_channels := _childless_slice_ledger()
	assert_true(ReportLedgerValidator.validate(slice_channels).ok, "empty slice channels baseline validates")
	assert_false(is_same(slice_channels.slices[0].channels, slice_channels.slices[1].channels), "empty slice channel containers are independently allocated")
	slice_channels.slices[1].channels = slice_channels.slices[0].channels
	rows.append(["empty slice channels", slice_channels])

	var record_slices := _two_record_ledger()
	assert_true(ReportLedgerValidator.validate(record_slices).ok, "empty retained record slices baseline validates")
	assert_false(is_same(record_slices.retained_records[0].slices, record_slices.retained_records[1].slices), "empty retained record slice containers are independently allocated")
	record_slices.retained_records[1].slices = record_slices.retained_records[0].slices
	rows.append(["empty retained record slices", record_slices])

	var live_to_retained_slices := _retained_live_childless_slice_ledger()
	live_to_retained_slices.retained_records[0].slices.clear()
	live_to_retained_slices.slices.clear()
	assert_true(ReportLedgerValidator.validate(live_to_retained_slices).ok, "empty live-to-retained slices baseline validates")
	assert_false(is_same(live_to_retained_slices.retained_records[0].slices, live_to_retained_slices.slices), "empty live and retained slice containers are independently allocated")
	live_to_retained_slices.slices = live_to_retained_slices.retained_records[0].slices
	rows.append(["empty live-to-retained slices", live_to_retained_slices])

	var record_events := _two_record_ledger()
	assert_true(ReportLedgerValidator.validate(record_events).ok, "empty retained record events baseline validates")
	assert_false(is_same(record_events.retained_records[0].settlement_events, record_events.retained_records[1].settlement_events), "empty retained record event containers are independently allocated")
	record_events.retained_records[1].settlement_events = record_events.retained_records[0].settlement_events
	rows.append(["empty retained record events", record_events])

	var live_to_retained_events := _retained_live_childless_slice_ledger()
	assert_true(ReportLedgerValidator.validate(live_to_retained_events).ok, "empty live-to-retained events baseline validates")
	assert_false(is_same(live_to_retained_events.retained_records[0].settlement_events, live_to_retained_events.settlement_events), "empty live and retained event containers are independently allocated")
	live_to_retained_events.settlement_events = live_to_retained_events.retained_records[0].settlement_events
	rows.append(["empty live-to-retained events", live_to_retained_events])

	for row in rows:
		var failure := ReportLedgerValidator.validate(row[1])
		assert_false(failure.ok, "%s reuse rejects" % row[0])
		assert_eq(failure.code, ReportLedgerValidator.FAILURE, "%s reports the identity failure code" % row[0])
		assert_eq(failure.details, "Ledger-owned mutable report node is reused.", "%s reports the identity failure details" % row[0])
	var ledger_clone_source := _retained_live_childless_slice_ledger()
	var ledger_clone := ledger_clone_source.deep_clone()
	assert_false(is_same(ledger_clone.slices, ledger_clone_source.slices), "ledger clone detaches live slices")
	assert_false(is_same(ledger_clone.settlement_events, ledger_clone_source.settlement_events), "ledger clone detaches live events")
	assert_false(is_same(ledger_clone.retained_records, ledger_clone_source.retained_records), "ledger clone detaches retained records")
	assert_false(is_same(ledger_clone.threshold_continuations, ledger_clone_source.threshold_continuations), "ledger clone detaches continuations")
	var record_clone_source := _record(1, 0, 10)
	var record_clone := record_clone_source.deep_clone()
	assert_false(is_same(record_clone.slices, record_clone_source.slices), "record clone detaches slices")
	assert_false(is_same(record_clone.settlement_events, record_clone_source.settlement_events), "record clone detaches events")
	var slice_clone_source := _slice(&"T", 0, 10)
	var slice_clone := slice_clone_source.deep_clone()
	assert_false(is_same(slice_clone.ordered_retinue_ids, slice_clone_source.ordered_retinue_ids), "slice clone detaches Retinue IDs")
	assert_false(is_same(slice_clone.channels, slice_clone_source.channels), "slice clone detaches channels")
	var continuation_clone_source := _continuation(&"T", &"OVERDUE", 1, false, &"")
	var continuation_clone := continuation_clone_source.deep_clone()
	assert_false(is_same(continuation_clone.ordered_retinue_ids, continuation_clone_source.ordered_retinue_ids), "continuation clone detaches Retinue IDs")
	assert_false(is_same(continuation_clone.channels, continuation_clone_source.channels), "continuation clone detaches channels")

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
