extends GutTest

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func _representative_state() -> GameState:
	var s := GameState.new(12000)
	s.inventory.entries[&"RES_ESSENCE"] = GameState.InventoryEntryState.new(250, {&"REC_WEAVE_REMEMBERED": 25})
	s.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 1000, &"M04A_FIXTURE")
	var t := GameState.ThresholdState.new()
	t.knowledge_state = &"CHARTED"; t.availability_state = &"AVAILABLE"; t.lifecycle_state = &"OVERDUE"
	t.remaining_backlog = 4900; t.persistent_returns_total = 100; t.familiarity_subunits = 500
	t.channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"] = GameState.ThresholdAcquisitionState.new(250000, 10, 1)
	s.thresholds[&"THR_GLOAMWOOD"] = t
	var r := GameState.ReapingState.new()
	r.threshold_id = &"THR_GLOAMWOOD"; r.is_active = true; r.form_id = &"FORM_MAN_AT_ARMS"; r.writ_id = &"WRIT_STANDARD"
	r.retinue_ids = [&"RET_SOLDIER_COMPANY"]; r.assignment_revision = 1; r.cycle_phase_msec = 2; r.completed_cycle_count = 3
	r.flow_carry_units[&"FLOW_TEST"] = 4; r.started_simulation_msec = 1; r.last_configuration_change_simulation_msec = 2
	s.reapings[&"THR_GLOAMWOOD"] = r
	s.progression.command_tether_capacity = 1
	s.progression.unlocked_output_item_ids = [&"SOUL_CALLING_SOLDIER"]
	return s

func _assert_invalid(mutator: Callable, expected_code: String) -> void:
	var state := _representative_state()
	mutator.call(state)
	var result := GameStateValidator.validate(state, _registry())
	assert_false(result.ok)
	assert_eq(result.code, expected_code)

func test_representative_state_validates_and_clone_is_deep() -> void:
	var state := _representative_state()
	assert_true(GameStateValidator.validate(state, _registry()).ok)
	var clone := state.deep_clone()
	clone.inventory.entries[&"RES_ESSENCE"].reservations[&"REC_WEAVE_REMEMBERED"] = 1
	clone.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits = 2
	clone.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].progress_subunits = 1
	clone.reapings[&"THR_GLOAMWOOD"].retinue_ids.clear()
	clone.reapings[&"THR_GLOAMWOOD"].flow_carry_units[&"FLOW_TEST"] = 0
	clone.progression.command_tether_capacity = 9
	assert_eq(state.inventory.entries[&"RES_ESSENCE"].reservations[&"REC_WEAVE_REMEMBERED"], 25)
	assert_eq(state.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits, 1000)
	assert_eq(state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].progress_subunits, 250000)
	assert_eq(state.reapings[&"THR_GLOAMWOOD"].retinue_ids, [&"RET_SOLDIER_COMPANY"])
	assert_eq(state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[&"FLOW_TEST"], 4)
	assert_eq(state.progression.command_tether_capacity, 1)

func test_nonzero_constructor_initializes_report_cursor_to_game_cursor() -> void:
	var state := GameState.new(12345)
	assert_eq(state.simulation_time_msec, 12345)
	assert_eq(state.report_state.report_cursor_msec, 12345)
	assert_eq(state.report_state.live.start_simulation_msec, 12345)
	assert_eq(state.report_state.live.end_simulation_msec, 12345)

func test_inventory_validation_matrix() -> void:
	_assert_invalid(func(s): s.inventory.entries[&"RES_ESSENCE"].total = -1, GameStateValidator.ERR_RANGE)
	_assert_invalid(func(s): s.inventory.entries[&"RES_ESSENCE"].reservations[&"REC_WEAVE_REMEMBERED"] = -1, GameStateValidator.ERR_RANGE)
	_assert_invalid(func(s): s.inventory.entries[&"RES_ESSENCE"].reservations[&"too_much"] = 9999, GameStateValidator.ERR_CROSS_FIELD)
	_assert_invalid(func(s): s.inventory.entries[&"RES_ESSENCE"].reservations = {&"a": FixedPoint.INT64_MAX, &"b": 1}, GameStateValidator.ERR_RANGE)
	_assert_invalid(func(s): s.inventory.entries[&"ITEM_UNKNOWN"] = GameState.InventoryEntryState.new(1), GameStateValidator.ERR_CONTENT)
	_assert_invalid(func(s): s.inventory.entries[&"FORM_MAN_AT_ARMS"] = GameState.InventoryEntryState.new(1), GameStateValidator.ERR_CONTENT)

func test_form_validation_matrix() -> void:
	_assert_invalid(func(s): s.forms[&"FORM_UNKNOWN"] = GameState.FormState.new(), GameStateValidator.ERR_CONTENT)
	_assert_invalid(func(s): s.forms[&"RES_ESSENCE"] = GameState.FormState.new(), GameStateValidator.ERR_CONTENT)
	_assert_invalid(func(s): s.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits = -1, GameStateValidator.ERR_RANGE)
	_assert_invalid(func(s): s.forms[&"FORM_MAN_AT_ARMS"].revealed = false, GameStateValidator.ERR_CROSS_FIELD)
	_assert_invalid(func(s): s.forms[&"FORM_MAN_AT_ARMS"].awakened_by = &"", GameStateValidator.ERR_CROSS_FIELD)
	_assert_invalid(func(s): s.forms[&"FORM_MAN_AT_ARMS"].awakened = false, GameStateValidator.ERR_CROSS_FIELD)

func test_threshold_and_acquisition_validation_matrix() -> void:
	_assert_invalid(func(s): s.thresholds[&"THR_GLOAMWOOD"].knowledge_state = &"BAD", GameStateValidator.ERR_RANGE)
	_assert_invalid(func(s): s.thresholds[&"THR_GLOAMWOOD"].availability_state = &"BAD", GameStateValidator.ERR_RANGE)
	_assert_invalid(func(s): s.thresholds[&"THR_GLOAMWOOD"].lifecycle_state = &"BAD", GameStateValidator.ERR_RANGE)
	_assert_invalid(func(s): s.thresholds[&"THR_GLOAMWOOD"].remaining_backlog = -1, GameStateValidator.ERR_RANGE)
	_assert_invalid(func(s): s.thresholds[&"THR_GLOAMWOOD"].remaining_backlog = 1000001, GameStateValidator.ERR_RANGE)
	_assert_invalid(func(s): s.thresholds[&"THR_GLOAMWOOD"].remaining_backlog = 0, GameStateValidator.ERR_CROSS_FIELD)
	_assert_invalid(func(s): s.thresholds[&"THR_GLOAMWOOD"].lifecycle_state = &"SETTLED", GameStateValidator.ERR_CROSS_FIELD)
	_assert_invalid(func(s): s.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total = -1, GameStateValidator.ERR_RANGE)
	_assert_invalid(func(s): s.thresholds[&"THR_GLOAMWOOD"].familiarity_subunits = -1, GameStateValidator.ERR_RANGE)
	_assert_invalid(func(s): s.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_UNKNOWN"] = GameState.ThresholdAcquisitionState.new(), GameStateValidator.ERR_CONTENT)
	_assert_invalid(func(s): s.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_BROKEN_WATCH_ESSENCE"] = GameState.ThresholdAcquisitionState.new(), GameStateValidator.ERR_CONTENT)
	_assert_invalid(func(s): s.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].progress_subunits = -1, GameStateValidator.ERR_RANGE)
	_assert_invalid(func(s): s.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].progress_subunits = FixedPoint.SCALE, GameStateValidator.ERR_RANGE)
	_assert_invalid(func(s): s.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].rate_carry_units = -1, GameStateValidator.ERR_RANGE)
	_assert_invalid(func(s): s.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].rate_carry_units = 300000, GameStateValidator.ERR_RANGE)
	_assert_invalid(func(s): s.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].total_banked_units = -1, GameStateValidator.ERR_RANGE)

func test_reaping_and_progression_validation_matrix() -> void:
	_assert_invalid(func(s): s.reapings[&"THR_GLOAMWOOD"].threshold_id = &"THR_BROKEN_WATCH", GameStateValidator.ERR_CROSS_FIELD)
	_assert_invalid(func(s): s.thresholds.erase(&"THR_GLOAMWOOD"), GameStateValidator.ERR_CROSS_FIELD)
	_assert_invalid(func(s): s.reapings[&"THR_GLOAMWOOD"].form_id = &"FORM_UNKNOWN", GameStateValidator.ERR_CONTENT)
	_assert_invalid(func(s): s.reapings[&"THR_GLOAMWOOD"].form_id = &"RES_ESSENCE", GameStateValidator.ERR_CONTENT)
	_assert_invalid(func(s): s.reapings[&"THR_GLOAMWOOD"].writ_id = &"WRIT_UNKNOWN", GameStateValidator.ERR_CONTENT)
	_assert_invalid(func(s): s.reapings[&"THR_GLOAMWOOD"].writ_id = &"RES_ESSENCE", GameStateValidator.ERR_CONTENT)
	_assert_invalid(func(s): s.forms.erase(&"FORM_MAN_AT_ARMS"), GameStateValidator.ERR_CROSS_FIELD)
	_assert_invalid(func(s): s.forms[&"FORM_MAN_AT_ARMS"].awakened = false; s.forms[&"FORM_MAN_AT_ARMS"].awakened_by = &"", GameStateValidator.ERR_CROSS_FIELD)
	_assert_invalid(func(s): s.reapings[&"THR_GLOAMWOOD"].retinue_ids.clear(); s.reapings[&"THR_GLOAMWOOD"].retinue_ids.append(&"RET_SOLDIER_COMPANY"); s.reapings[&"THR_GLOAMWOOD"].retinue_ids.append(&"RET_SOLDIER_COMPANY"), GameStateValidator.ERR_CROSS_FIELD)
	_assert_invalid(func(s): s.reapings[&"THR_GLOAMWOOD"].retinue_ids.clear(); s.reapings[&"THR_GLOAMWOOD"].retinue_ids.append(&"RET_UNKNOWN"), GameStateValidator.ERR_CONTENT)
	_assert_invalid(func(s): s.reapings[&"THR_GLOAMWOOD"].retinue_ids.clear(); s.reapings[&"THR_GLOAMWOOD"].retinue_ids.append(&"RES_ESSENCE"), GameStateValidator.ERR_CONTENT)
	_assert_invalid(func(s): s.reapings[&"THR_GLOAMWOOD"].assignment_revision = -1, GameStateValidator.ERR_RANGE)
	_assert_invalid(func(s): s.reapings[&"THR_GLOAMWOOD"].cycle_phase_msec = -1, GameStateValidator.ERR_RANGE)
	_assert_invalid(func(s): s.reapings[&"THR_GLOAMWOOD"].completed_cycle_count = -1, GameStateValidator.ERR_RANGE)
	_assert_invalid(func(s): s.reapings[&"THR_GLOAMWOOD"].flow_carry_units[&"FLOW_TEST"] = -1, GameStateValidator.ERR_RANGE)
	_assert_invalid(func(s): s.reapings[&"THR_GLOAMWOOD"].started_simulation_msec = 999999, GameStateValidator.ERR_RANGE)
	_assert_invalid(func(s): s.reapings[&"THR_GLOAMWOOD"].last_configuration_change_simulation_msec = 999999, GameStateValidator.ERR_RANGE)
	_assert_invalid(func(s): s.reapings[&"THR_GLOAMWOOD"].last_configuration_change_simulation_msec = 0, GameStateValidator.ERR_CROSS_FIELD)
	_assert_invalid(func(s): s.progression.command_tether_capacity = 0, GameStateValidator.ERR_CROSS_FIELD)
	_assert_invalid(func(s): s.progression.command_tether_capacity = -1, GameStateValidator.ERR_RANGE)

func test_malformed_runtime_objects_return_typed_errors() -> void:
	_assert_invalid(func(s): s.inventory.entries[&"RES_ESSENCE"] = {}, GameStateValidator.ERR_TYPE)
	_assert_invalid(func(s): s.forms[&"FORM_MAN_AT_ARMS"] = {}, GameStateValidator.ERR_TYPE)
	_assert_invalid(func(s): s.thresholds[&"THR_GLOAMWOOD"] = {}, GameStateValidator.ERR_TYPE)
	_assert_invalid(func(s): s.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"] = {}, GameStateValidator.ERR_TYPE)
	_assert_invalid(func(s): s.reapings[&"THR_GLOAMWOOD"] = {}, GameStateValidator.ERR_TYPE)

func _add_report_fixture(state: GameState) -> void:
	state.report_state = ReportState.new(state.simulation_time_msec)
	state.report_state.report_cursor_msec = state.simulation_time_msec
	state.report_state.next_report_sequence = 2
	state.report_state.next_event_sequence = 2
	var window := ReportState.ReportWindow.new()
	window.start_simulation_msec = 1000
	window.end_simulation_msec = 2000
	window.run_count = 1
	window.mode_counts["DEBUG"] = 1
	var slice := ReportState.AttributionSlice.new()
	slice.threshold_id = &"THR_GLOAMWOOD"
	slice.assignment_revision = 1
	slice.lifecycle_state = &"OVERDUE"
	slice.form_id = &"FORM_MAN_AT_ARMS"
	slice.writ_id = &"WRIT_STANDARD"
	slice.retinue_ids = [&"RET_SOLDIER_COMPANY"]
	slice.start_simulation_msec = 1000
	slice.end_simulation_msec = 2000
	slice.elapsed_msec = 1000
	slice.returned_souls_delta = 1
	slice.backlog_delta = -1
	slice.completed_cycles_delta = 1
	slice.inventory_gains[&"RES_ESSENCE"] = 1
	slice.mastery_gains[&"FORM_MAN_AT_ARMS"] = 1
	var channel := ReportState.ChannelSummary.new()
	channel.channel_id = &"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"
	channel.output_item_id = &"SOUL_CALLING_SOLDIER"
	channel.banked_units_delta = 1
	slice.channel_summaries[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"] = channel
	window.slices["THR_GLOAMWOOD|1|OVERDUE"] = slice
	window.events_by_type["THRESHOLD_SETTLED"] = 1
	var event := ReportState.ReportEventDetail.new()
	event.event_sequence = 1
	event.event_type = &"THRESHOLD_SETTLED"
	event.occurred_simulation_msec = 2000
	event.priority = 1
	event.subject_id = &"THR_GLOAMWOOD"
	event.source_id = &"SIMULATION_ENGINE"
	window.event_details.append(event)
	state.report_state.live = window.deep_clone()
	var record := ReportState.ReportRecord.new()
	record.report_sequence = 1
	record.snapshot_reason = ReportState.REASON_MANUAL_REVIEW
	record.window = window.deep_clone()
	state.report_state.history.append(record)

func test_report_state_clone_copy_and_runtime_validation_are_complete() -> void:
	var state := _representative_state()
	_add_report_fixture(state)
	assert_true(GameStateValidator.validate(state, _registry()).ok)
	var clone := state.deep_clone()
	clone.report_state.live.slices["THR_GLOAMWOOD|1|OVERDUE"].inventory_gains[&"RES_ESSENCE"] = 9
	clone.report_state.history[0].window.event_details[0].source_id = &"CHANGED"
	assert_eq(state.report_state.live.slices["THR_GLOAMWOOD|1|OVERDUE"].inventory_gains[&"RES_ESSENCE"], 1)
	assert_eq(state.report_state.history[0].window.event_details[0].source_id, &"SIMULATION_ENGINE")
	var target := GameState.new(0)
	target.copy_from(state)
	target.report_state.live.mode_counts.DEBUG = 2
	assert_eq(state.report_state.live.mode_counts.DEBUG, 1)

func test_report_runtime_validation_matrix() -> void:
	_assert_invalid(func(s): s.report_state = null, GameStateValidator.ERR_TYPE)
	_assert_invalid(func(s): s.report_state.live = null, GameStateValidator.ERR_TYPE)
	_assert_invalid(func(s): s.report_state.report_cursor_msec = s.simulation_time_msec + 1, GameStateValidator.ERR_RANGE)
	_assert_invalid(func(s): s.report_state.next_report_sequence = 0, GameStateValidator.ERR_RANGE)
	_assert_invalid(func(s): s.report_state.live.run_count = 1; s.report_state.live.mode_counts.BAD_MODE = 1, GameStateValidator.ERR_RANGE)
	_assert_invalid(func(s): _add_report_fixture(s); s.report_state.live.slices["THR_GLOAMWOOD|1|OVERDUE"].inventory_gains[&"RES_ESSENCE"] = -1, GameStateValidator.ERR_RANGE)
	_assert_invalid(func(s): _add_report_fixture(s); s.report_state.live.slices["THR_GLOAMWOOD|1|OVERDUE"].channel_summaries[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].channel_id = &"CHANNEL_OTHER", GameStateValidator.ERR_CROSS_FIELD)
	_assert_invalid(func(s): _add_report_fixture(s); s.report_state.history[0].snapshot_reason = &"UNKNOWN_REASON", GameStateValidator.ERR_RANGE)
	_assert_invalid(func(s): _add_report_fixture(s); s.report_state.live.event_details[0].source_id = &"", GameStateValidator.ERR_RANGE)
