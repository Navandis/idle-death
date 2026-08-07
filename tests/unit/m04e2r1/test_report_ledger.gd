extends GutTest

func test_factory_clone_value_equality_and_full_field_isolation() -> void:
	assert_null(ReportLedger.create_empty(-1), "negative factory cursor")
	var ledger := _ledger(10)
	var event := ReportSettlementEvent.new()
	event.event_sequence = 1; event.content_revision = "r"; event.threshold_id = &"T"; event.assignment_revision = 1; event.occurred_simulation_msec = 10; event.persistent_returns_total = 4
	ledger.slices[0].remaining_backlog_after = 0; ledger.settlement_events.append(event); ledger.next_event_sequence = 2
	var copy := ledger.deep_clone()
	assert_true(copy.value_equals(ledger), "deep clone value equality")
	assert_ne(copy, ledger, "root detached")
	copy.window_start_simulation_msec = 1; copy.slices[0].ordered_retinue_ids[0] = &"X"; copy.slices[0].channels[0].rate_carry_units_after = 2; copy.settlement_events[0].persistent_returns_total = 9
	assert_eq(ledger.window_start_simulation_msec, 0, "root isolation")
	assert_eq(ledger.slices[0].ordered_retinue_ids[0], &"A", "retinue-array isolation")
	assert_eq(ledger.slices[0].channels[0].rate_carry_units_after, 0, "channel isolation")
	assert_eq(ledger.settlement_events[0].persistent_returns_total, 4, "Settlement isolation")

func test_validator_root_slice_channel_and_event_grammar() -> void:
	for row in [
		["null ledger", func(l): return null], ["negative root cursor", func(l): l.window_start_simulation_msec = -1], ["inverted root cursors", func(l): l.ingested_through_simulation_msec = -1],
		["negative mode duration", func(l): l.foreground_elapsed_msec = -1], ["mode sum mismatch", func(l): l.debug_elapsed_msec = 1], ["mode sum overflow", func(l): l.foreground_elapsed_msec = FixedPoint.INT64_MAX; l.offline_elapsed_msec = 1],
		["invalid next event sequence", func(l): l.next_event_sequence = 0], ["malformed slice identity", func(l): l.slices[0].threshold_id = &""], ["malformed lifecycle", func(l): l.slices[0].lifecycle_state = &"BAD"],
		["slice timing", func(l): l.slices[0].end_simulation_msec = 0], ["slice overlap/order", func(l): l.slices.append(_slice(5, 10, 9, 8))], ["nonmaximal adjacency", func(l): l.slices.append(_slice(10, 20, 9, 8)); l.ingested_through_simulation_msec = 20; l.foreground_elapsed_msec = 20],
		["mode coverage exceeds root", func(l): l.foreground_elapsed_msec = 5], ["channel identity", func(l): l.slices[0].channels[0].channel_id = &""], ["channel containment", func(l): l.slices[0].channels[0].end_simulation_msec = 11],
		["channel progress", func(l): l.slices[0].channels[0].progress_subunits_after = FixedPoint.SCALE], ["channel period", func(l): l.slices[0].channels[0].rate_period_msec = 0], ["channel carry", func(l): l.slices[0].channels[0].rate_carry_units_after = 1000], ["channel total", func(l): l.slices[0].channels[0].total_banked_units_after = -1]
	]:
		var value: ReportLedger = _ledger(10)
		value = row[1].call(value)
		var result := ReportLedgerValidator.validate(value)
		assert_false(result.ok, row[0]); assert_eq(result.code, ReportLedgerValidator.FAILURE, row[0]); assert_ne(result.details, "", row[0])

func test_validator_settlement_and_continuity_grammar() -> void:
	for row in [
		["missing Settlement", func(l): l.settlement_events.clear(); l.next_event_sequence = 1], ["Settlement sequence", func(l): _settle(l).event_sequence = 2], ["Settlement time", func(l): _settle(l).occurred_simulation_msec = 0],
		["Settlement owner", func(l): _settle(l).assignment_revision = 2], ["duplicate Settlement", func(l): l.settlement_events.append(_settle(l)); l.next_event_sequence = 3], ["unmatched Settlement", func(l): _settle(l).threshold_id = &"OTHER"]
	]:
		var value := _settled_ledger()
		row[1].call(value)
		assert_false(ReportLedgerValidator.validate(value).ok, row[0])

func test_validator_cross_slice_source_channel_and_settlement_rules() -> void:
	for row in [
		["component identity across mode split", func(l): l.slices[1].form_id = &"OTHER"], ["Retinue order is identity", func(l): l.slices[1].ordered_retinue_ids.reverse()], ["backlog continuity", func(l): l.slices[1].remaining_backlog_before = 8],
		["missing previously seen channel", func(l): l.slices[1].channels.clear()], ["output-item mismatch", func(l): l.slices[1].channels[0].output_item_id = &"OTHER"], ["rate-period mismatch", func(l): l.slices[1].channels[0].rate_period_msec = 999],
		["progress reset", func(l): l.slices[1].channels[0].progress_subunits_before = 1], ["carry reset", func(l): l.slices[1].channels[0].rate_carry_units_before = 1], ["total reset", func(l): l.slices[0].channels[0].total_banked_units_after = 1]
	]:
		var value := _split_ledger(); row[1].call(value)
		assert_false(ReportLedgerValidator.validate(value).ok, row[0])
	var events := _two_settled_ledger()
	for row in [["event ordering", func(l): l.settlement_events[1].occurred_simulation_msec = 9], ["event sequence", func(l): l.settlement_events[1].event_sequence = 3], ["duplicate Threshold", func(l): l.settlement_events[1].threshold_id = &"A"], ["unmatched owner", func(l): l.settlement_events[1].assignment_revision = 2]]:
		var value := events.deep_clone(); row[1].call(value)
		assert_false(ReportLedgerValidator.validate(value).ok, row[0])

func _split_ledger() -> ReportLedger:
	var ledger := _ledger(10); var second := _slice(10, 20, 9, 8)
	second.run_mode = SimulationRunService.MODE_OFFLINE_FIXTURE
	ledger.slices.append(second); ledger.ingested_through_simulation_msec = 20; ledger.foreground_elapsed_msec = 10; ledger.offline_elapsed_msec = 10
	assert_true(ReportLedgerValidator.validate(ledger).ok, "split fixture")
	return ledger

func _two_settled_ledger() -> ReportLedger:
	var ledger := _ledger(10); ledger.slices[0].threshold_id = &"A"; ledger.slices[0].remaining_backlog_after = 0
	var second := _slice(10, 20, 1, 0); second.threshold_id = &"B"; second.run_mode = SimulationRunService.MODE_OFFLINE_FIXTURE
	ledger.slices.append(second); ledger.ingested_through_simulation_msec = 20; ledger.offline_elapsed_msec = 10
	for value in [[&"A", 10], [&"B", 20]]:
		var event := ReportSettlementEvent.new(); event.event_sequence = ledger.settlement_events.size() + 1; event.content_revision = "r"; event.threshold_id = value[0]; event.assignment_revision = 1; event.occurred_simulation_msec = value[1]; ledger.settlement_events.append(event)
	ledger.next_event_sequence = 3
	assert_true(ReportLedgerValidator.validate(ledger).ok, "two Settlement fixture")
	return ledger

func _ledger(cursor: int) -> ReportLedger:
	var ledger := ReportLedger.create_empty(0)
	ledger.ingested_through_simulation_msec = cursor; ledger.foreground_elapsed_msec = cursor
	if cursor > 0: ledger.slices.append(_slice(0, cursor, 10, 9))
	return ledger

func _settled_ledger() -> ReportLedger:
	var ledger := _ledger(10)
	ledger.slices[0].remaining_backlog_after = 0
	_settle(ledger); ledger.next_event_sequence = 2
	assert_true(ReportLedgerValidator.validate(ledger).ok, "settled fixture")
	return ledger

func _settle(_ledger_value: ReportLedger) -> ReportSettlementEvent:
	var event := ReportSettlementEvent.new()
	event.event_sequence = 1; event.content_revision = "r"; event.threshold_id = &"T"; event.assignment_revision = 1; event.occurred_simulation_msec = 10
	if _ledger_value.settlement_events.is_empty(): _ledger_value.settlement_events.append(event)
	return _ledger_value.settlement_events[0]

func _slice(start: int, finish: int, before: int, after: int) -> ReportLedgerSlice:
	var slice := ReportLedgerSlice.new()
	slice.run_mode = SimulationRunService.MODE_FOREGROUND_SUPPLIED; slice.content_revision = "r"; slice.threshold_id = &"T"; slice.assignment_revision = 1; slice.form_id = &"F"; slice.writ_id = &"W"; slice.ordered_retinue_ids = [&"A", &"B"]; slice.lifecycle_state = &"OVERDUE"
	slice.start_simulation_msec = start; slice.end_simulation_msec = finish; slice.returned_souls_delta = 1; slice.remaining_backlog_before = before; slice.remaining_backlog_after = after
	var channel := ReportLedgerChannel.new()
	channel.channel_id = &"C"; channel.output_item_id = &"SOUL"; channel.start_simulation_msec = start; channel.end_simulation_msec = finish; channel.rate_period_msec = 1000
	slice.channels.append(channel)
	return slice
