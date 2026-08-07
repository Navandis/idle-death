extends GutTest

func test_factory_and_validator_result_grammar() -> void:
	assert_null(ReportLedger.create_empty(-1), "negative cursor is rejected")
	for cursor in [0, 7]:
		var ledger := ReportLedger.create_empty(cursor)
		var result := ReportLedgerValidator.validate(ledger)
		assert_true(result.ok, "create_empty %d validates" % cursor)
		assert_eq(result.keys().size(), 3, "success has three keys")
		assert_eq(result, {"ok": true, "code": &"", "details": ""}, "success grammar")
	var failure := ReportLedgerValidator.validate(null)
	assert_eq(failure.keys().size(), 3, "failure has three keys")
	assert_false(failure.ok, "failure ok")
	assert_eq(failure.code, ReportLedgerValidator.FAILURE, "failure code")
	assert_ne(failure.details, "", "failure details")

func test_all_42_clone_and_value_equality_fields_are_independent() -> void:
	for row in _equality_rows():
		var source := _canonical()
		var snapshot := source.deep_clone()
		var copy := source.deep_clone()
		assert_true(copy.value_equals(source), "%s initial equality" % row[0])
		_mutate(copy, row[1], row[2])
		assert_false(copy.value_equals(source), "%s detects only clone mutation" % row[0])
		assert_true(source.value_equals(snapshot), "%s source is unchanged" % row[0])

func test_complete_validator_grammar_matrix() -> void:
	for row in _validator_rows():
		var baseline := _baseline(String(row[1]))
		assert_true(ReportLedgerValidator.validate(baseline).ok, "%s baseline validates" % row[0])
		var invalid := _break_row(baseline, String(row[0]))
		var result := ReportLedgerValidator.validate(invalid)
		assert_false(result.ok, "%s rejects" % row[0])
		assert_eq(result.code, ReportLedgerValidator.FAILURE, "%s failure code" % row[0])
		assert_ne(result.details, "", "%s failure details" % row[0])

func test_contained_partial_channel_interval_remains_valid() -> void:
	var ledger := _base()
	ledger.slices[0].channels[0].end_simulation_msec = 5
	assert_true(ReportLedgerValidator.validate(ledger).ok, "contained partial channel interval")

func _equality_rows() -> Array:
	return [
		["EQ-R01", "window_start_simulation_msec", 1], ["EQ-R02", "ingested_through_simulation_msec", 11],
		["EQ-R03", "foreground_elapsed_msec", 9], ["EQ-R04", "offline_elapsed_msec", 1],
		["EQ-R05", "debug_elapsed_msec", 1], ["EQ-R06", "next_event_sequence", 3],
		["EQ-R07", "slices", null], ["EQ-R08", "settlement_events", null],
		["EQ-S01", "slice.run_mode", &"DEBUG"], ["EQ-S02", "slice.content_revision", "other"],
		["EQ-S03", "slice.threshold_id", &"X"], ["EQ-S04", "slice.assignment_revision", 2],
		["EQ-S05", "slice.form_id", &"X"], ["EQ-S06", "slice.writ_id", &"X"],
		["EQ-S07", "slice.ordered_retinue_ids", null], ["EQ-S08", "slice.lifecycle_state", &"SETTLED"],
		["EQ-S09", "slice.start_simulation_msec", 1], ["EQ-S10", "slice.end_simulation_msec", 9],
		["EQ-S11", "slice.returned_souls_delta", 9], ["EQ-S12", "slice.remaining_backlog_before", 8],
		["EQ-S13", "slice.remaining_backlog_after", 1], ["EQ-S14", "slice.essence_delta", 9],
		["EQ-S15", "slice.mastery_delta_subunits", 9], ["EQ-S16", "slice.completed_cycles_delta", 9],
		["EQ-S17", "slice.channels", null], ["EQ-C01", "channel.channel_id", &"X"],
		["EQ-C02", "channel.output_item_id", &"X"], ["EQ-C03", "channel.start_simulation_msec", 1],
		["EQ-C04", "channel.end_simulation_msec", 9], ["EQ-C05", "channel.progress_subunits_before", 3],
		["EQ-C06", "channel.progress_subunits_after", 4], ["EQ-C07", "channel.rate_period_msec", 999],
		["EQ-C08", "channel.rate_carry_units_before", 1], ["EQ-C09", "channel.rate_carry_units_after", 2],
		["EQ-C10", "channel.total_banked_units_before", 1], ["EQ-C11", "channel.total_banked_units_after", 2],
		["EQ-E01", "event.event_sequence", 9], ["EQ-E02", "event.content_revision", "other"],
		["EQ-E03", "event.threshold_id", &"X"], ["EQ-E04", "event.assignment_revision", 2],
		["EQ-E05", "event.occurred_simulation_msec", 9], ["EQ-E06", "event.persistent_returns_total", 9]
	]

func _validator_rows() -> Array:
	var rows: Array = []
	for id in ["V-ROOT-01", "V-ROOT-02", "V-ROOT-03", "V-ROOT-04", "V-ROOT-05", "V-ROOT-06", "V-ROOT-07"]: rows.append([id, "base"])
	for id in ["V-SLICE-01", "V-SLICE-02", "V-SLICE-03", "V-SLICE-04", "V-SLICE-05", "V-SLICE-06", "V-SLICE-07", "V-SLICE-08", "V-SLICE-09", "V-SLICE-10", "V-SLICE-11", "V-SLICE-12", "V-SLICE-13", "V-SLICE-14", "V-SLICE-15", "V-SLICE-16", "V-SLICE-17", "V-SLICE-18", "V-SLICE-19", "V-SLICE-20", "V-SLICE-21", "V-SLICE-22", "V-SLICE-23", "V-SLICE-24", "V-SLICE-25", "V-SLICE-26"]: rows.append([id, "split" if id in ["V-SLICE-12", "V-SLICE-25", "V-SLICE-26"] else "base"])
	for id in ["V-CHAN-01", "V-CHAN-02", "V-CHAN-03", "V-CHAN-04", "V-CHAN-05", "V-CHAN-06", "V-CHAN-07", "V-CHAN-08", "V-CHAN-09", "V-CHAN-10", "V-CHAN-11", "V-CHAN-12", "V-CHAN-13", "V-CHAN-14", "V-CHAN-15", "V-CHAN-16", "V-CHAN-17", "V-CHAN-18", "V-CHAN-19"]: rows.append([id, "base"])
	for id in ["V-EVT-01", "V-EVT-02", "V-EVT-03", "V-EVT-04", "V-EVT-05", "V-EVT-06", "V-EVT-07", "V-EVT-08", "V-EVT-09", "V-EVT-10", "V-EVT-11", "V-EVT-12", "V-EVT-13", "V-EVT-14", "V-EVT-15", "V-EVT-16", "V-EVT-17"]: rows.append([id, "settled"])
	for id in ["V-CONT-01", "V-CONT-02", "V-CONT-03", "V-CONT-04", "V-CONT-05", "V-CONT-06", "V-CONT-07", "V-CONT-08", "V-CONT-09", "V-CONT-10"]: rows.append([id, "split"])
	rows.append(["V-CONT-11", "events"])
	return rows

func _mutate(ledger: ReportLedger, path: String, value: Variant) -> void:
	if path == "slices": ledger.slices.clear()
	elif path == "settlement_events": ledger.settlement_events.clear()
	elif path == "slice.ordered_retinue_ids": ledger.slices[0].ordered_retinue_ids.reverse()
	elif path == "slice.channels": ledger.slices[0].channels.clear()
	elif path.begins_with("slice."): ledger.slices[0].set(path.trim_prefix("slice."), value)
	elif path.begins_with("channel."): ledger.slices[0].channels[0].set(path.trim_prefix("channel."), value)
	elif path.begins_with("event."): ledger.settlement_events[0].set(path.trim_prefix("event."), value)
	else: ledger.set(path, value)

func _break_row(ledger: ReportLedger, id: String) -> ReportLedger:
	var number := int(id.right(2))
	if id.begins_with("V-ROOT"):
		if number == 1: return null
		var root := [["window_start_simulation_msec", -1], ["ingested_through_simulation_msec", -1], ["foreground_elapsed_msec", -1], ["debug_elapsed_msec", 1], ["foreground_elapsed_msec", FixedPoint.INT64_MAX], ["next_event_sequence", 0]]
		ledger.set(root[number - 2][0], root[number - 2][1])
	if id.begins_with("V-SLICE"):
		if number == 1: ledger.slices[0] = null
		elif number == 8: ledger.slices[0].ordered_retinue_ids[0] = &""
		elif number == 9: ledger.slices[0].ordered_retinue_ids[1] = &"A"
		elif number == 12: ledger.slices[1].start_simulation_msec = 9
		elif number == 25 or number == 26: ledger.slices[1].run_mode = SimulationRunService.MODE_FOREGROUND_SUPPLIED
		else:
			var slice := [["run_mode", &"BAD"], ["content_revision", ""], ["threshold_id", &""], ["assignment_revision", 0], ["form_id", &""], ["writ_id", &""], ["lifecycle_state", &"BAD"], ["start_simulation_msec", -1], ["end_simulation_msec", 0], ["end_simulation_msec", 11], ["returned_souls_delta", -1], ["remaining_backlog_before", -1], ["remaining_backlog_after", -1], ["remaining_backlog_after", 11], ["essence_delta", -1], ["mastery_delta_subunits", -1], ["completed_cycles_delta", -1], ["remaining_backlog_before", 0], ["lifecycle_state", &"SETTLED"], ["lifecycle_state", &"SETTLED"], ["lifecycle_state", &"SETTLED"]]
			ledger.slices[0].set(slice[number - 2 if number < 8 else number - 4][0], slice[number - 2 if number < 8 else number - 4][1])
	if id.begins_with("V-CHAN"):
		if number == 1: ledger.slices[0].channels[0] = null
		elif number == 4 or number == 5: ledger.slices[0].channels[1].channel_id = &"A"
		else:
			var channel := [["channel_id", &""], ["output_item_id", &""], ["start_simulation_msec", -1], ["end_simulation_msec", 0], ["end_simulation_msec", 11], ["progress_subunits_before", -1], ["progress_subunits_before", FixedPoint.SCALE], ["progress_subunits_after", -1], ["progress_subunits_after", FixedPoint.SCALE], ["rate_period_msec", 0], ["rate_carry_units_before", -1], ["rate_carry_units_before", 1000], ["rate_carry_units_after", -1], ["rate_carry_units_after", 1000], ["total_banked_units_before", -1], ["total_banked_units_after", -1]]
			var channel_index := number - 2 if number < 4 else number - 4
			ledger.slices[0].channels[0].set(channel[channel_index][0], channel[channel_index][1])
	if id.begins_with("V-EVT"):
		if number == 1: ledger.settlement_events[0] = null
		elif number == 11: ledger.settlement_events.append(ledger.settlement_events[0].deep_clone())
		elif number == 16: ledger.settlement_events.clear()
		else:
			var event := [["event_sequence", 2], ["event_sequence", ledger.next_event_sequence], ["content_revision", ""], ["threshold_id", &""], ["assignment_revision", 0], ["occurred_simulation_msec", 0], ["occurred_simulation_msec", 11], ["occurred_simulation_msec", 0], ["persistent_returns_total", -1], ["threshold_id", &"X"], ["content_revision", "bad"], ["assignment_revision", 2], ["occurred_simulation_msec", 9], ["next_event_sequence", 1]]
			var event_index := number - 2 if number < 11 else (number - 4 if number == 17 else number - 3)
			if event[event_index][0] == "next_event_sequence": ledger.next_event_sequence = event[event_index][1]
			else: ledger.settlement_events[0].set(event[event_index][0], event[event_index][1])
	if id.begins_with("V-CONT"):
		var continuity := [["form_id", &"X"], ["ordered_retinue_ids", null], ["remaining_backlog_before", 8], ["lifecycle_state", &"SETTLED"], ["channels", null], ["output_item_id", &"X"], ["rate_period_msec", 999], ["progress_subunits_before", 9], ["rate_carry_units_before", 9], ["total_banked_units_before", 9], ["threshold_id", ledger.slices[0].threshold_id]]
		if number == 2: ledger.slices[1].ordered_retinue_ids.reverse()
		elif number == 4: ledger.slices[0].lifecycle_state = &"SETTLED"
		elif number == 5: ledger.slices[1].channels.clear()
		elif number >= 6 and number <= 10: ledger.slices[1].channels[0].set(continuity[number - 1][0], continuity[number - 1][1])
		else: ledger.slices[1].set(continuity[number - 1][0], continuity[number - 1][1])
	return ledger

func _baseline(kind: String) -> ReportLedger:
	if kind == "settled": return _settled()
	if kind == "split": return _split()
	if kind == "events": return _events_split()
	return _base()

func _base() -> ReportLedger:
	var ledger := ReportLedger.create_empty(0)
	ledger.ingested_through_simulation_msec = 10
	ledger.foreground_elapsed_msec = 10
	ledger.slices.append(_slice(0, 10, 10, 9))
	return ledger

func _settled() -> ReportLedger:
	var ledger := _base()
	ledger.slices[0].remaining_backlog_after = 0
	var event := ReportSettlementEvent.new()
	event.event_sequence = 1
	event.content_revision = "r"
	event.threshold_id = &"T"
	event.assignment_revision = 1
	event.occurred_simulation_msec = 10
	event.persistent_returns_total = 4
	ledger.settlement_events.append(event)
	ledger.next_event_sequence = 2
	return ledger

func _canonical() -> ReportLedger:
	return _settled()

func _split() -> ReportLedger:
	var ledger := _base()
	var second := _slice(10, 20, 9, 8)
	second.run_mode = SimulationRunService.MODE_OFFLINE_FIXTURE
	ledger.slices.append(second)
	ledger.ingested_through_simulation_msec = 20
	ledger.foreground_elapsed_msec = 10
	ledger.offline_elapsed_msec = 10
	for index in range(second.channels.size()):
		second.channels[index].progress_subunits_before = ledger.slices[0].channels[index].progress_subunits_after
		second.channels[index].rate_carry_units_before = ledger.slices[0].channels[index].rate_carry_units_after
		second.channels[index].total_banked_units_before = ledger.slices[0].channels[index].total_banked_units_after
	return ledger

func _events_split() -> ReportLedger:
	var ledger := _split()
	ledger.slices[0].threshold_id = &"A"
	ledger.slices[0].remaining_backlog_after = 0
	ledger.slices[1].threshold_id = &"B"
	ledger.slices[1].assignment_revision = 2
	ledger.slices[1].remaining_backlog_after = 0
	for index in range(2):
		var event := ReportSettlementEvent.new()
		event.event_sequence = index + 1
		event.content_revision = "r"
		event.threshold_id = ledger.slices[index].threshold_id
		event.assignment_revision = ledger.slices[index].assignment_revision
		event.occurred_simulation_msec = ledger.slices[index].end_simulation_msec
		ledger.settlement_events.append(event)
	ledger.next_event_sequence = 3
	return ledger

func _slice(start: int, finish: int, before: int, after: int) -> ReportLedgerSlice:
	var slice := ReportLedgerSlice.new()
	slice.run_mode = SimulationRunService.MODE_FOREGROUND_SUPPLIED
	slice.content_revision = "r"
	slice.threshold_id = &"T"
	slice.assignment_revision = 1
	slice.form_id = &"F"
	slice.writ_id = &"W"
	slice.ordered_retinue_ids = [&"A", &"B"]
	slice.lifecycle_state = &"OVERDUE"
	slice.start_simulation_msec = start
	slice.end_simulation_msec = finish
	slice.returned_souls_delta = 1
	slice.remaining_backlog_before = before
	slice.remaining_backlog_after = after
	slice.essence_delta = 2
	slice.mastery_delta_subunits = 3
	slice.completed_cycles_delta = 4
	for id in [&"C", &"D"]:
		var channel := ReportLedgerChannel.new()
		channel.channel_id = id
		channel.output_item_id = &"SOUL"
		channel.start_simulation_msec = start
		channel.end_simulation_msec = finish
		channel.progress_subunits_before = 1
		channel.progress_subunits_after = 2
		channel.rate_period_msec = 1000
		channel.rate_carry_units_before = 3
		channel.rate_carry_units_after = 4
		channel.total_banked_units_before = 5
		channel.total_banked_units_after = 6
		slice.channels.append(channel)
	return slice
