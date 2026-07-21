extends GutTest

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func _engine() -> SimulationEngine:
	return SimulationEngine.new(_registry())

func _periods() -> Dictionary:
	return {&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS": 900000}

func _delta() -> SimulationEngine.SimulationChannelDeltaResult:
	return SimulationEngine.SimulationChannelDeltaResult.new(&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", &"SOUL_CALLING_SOLDIER", 1, 100, 200, 0, 1, 4, 5)

func _segment() -> SimulationEngine.SimulationSegmentResult:
	return SimulationEngine.SimulationSegmentResult.new(&"THR_GLOAMWOOD", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", [], &"OVERDUE", 0, 1000, 1000, 1, 1, 0, 100, 0, [_delta()])

func test_valid_records_are_detached_and_validate() -> void:
	var source_delta := _delta()
	var source_channels: Array[SimulationEngine.SimulationChannelDeltaResult] = [source_delta]
	var source_retinues: Array[StringName] = [&"RET_A"]
	var segment := SimulationEngine.SimulationSegmentResult.new(&"THR_GLOAMWOOD", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", source_retinues, &"OVERDUE", 0, 1000, 1000, 1, 1, 0, 100, 0, source_channels)
	source_retinues[0] = &"RET_B"
	source_delta.total_banked_units_after = 99
	assert_eq(segment.ordered_retinue_ids, [&"RET_A"])
	assert_eq(segment.channel_deltas[0].total_banked_units_after, 5)
	assert_true(segment.validate(_periods()).ok)

func test_local_record_rejection_matrix() -> void:
	assert_false(SimulationEngine.SimulationChannelDeltaResult.new(&"", &"SOUL_CALLING_SOLDIER", 0, 0, 0, 0, 0, 0, 0).validate(900000).ok)
	assert_false(SimulationEngine.SimulationChannelDeltaResult.new(&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", &"SOUL_CALLING_SOLDIER", 0, FixedPoint.SCALE, 0, 0, 0, 0, 0).validate(900000).ok)
	assert_false(SimulationEngine.SimulationChannelDeltaResult.new(&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", &"SOUL_CALLING_SOLDIER", 1, 0, 0, 0, 0, 10, 10).validate(900000).ok)
	assert_false(SimulationEngine.SimulationSegmentResult.new(&"THR_GLOAMWOOD", 0, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", [], &"OVERDUE", 0, 1, 1, 0, 0, 0, 0, 0, []).validate({}).ok)
	assert_false(SimulationEngine.SimulationSegmentResult.new(&"THR_GLOAMWOOD", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", [], &"BAD", 0, 1, 1, 0, 0, 0, 0, 0, []).validate({}).ok)
	assert_false(SimulationEngine.SimulationSegmentResult.new(&"THR_GLOAMWOOD", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", [&"RET_B", &"RET_A"], &"OVERDUE", 0, 1, 1, 0, 0, 0, 0, 0, []).validate({}).ok)

func test_complete_result_shapes_and_event_boundaries() -> void:
	var result := SimulationEngine.SimulationResult.new(true, SimulationEngine.OK, "", 1000)
	result.committed_elapsed_msec = 1000
	result.segments.append(_segment())
	result.events.append(SimulationEngine.SimulationEvent.output_channel_banked(1000, &"THR_GLOAMWOOD", &"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", _delta(), "OVERDUE"))
	result.change_summary["simulation_time_delta_msec"] = 1000
	assert_true(_engine().validate_result(result, 0, 1000, 1000).ok)
	result.events[0].occurred_simulation_msec = 0
	assert_false(_engine().validate_result(result, 0, 1000, 1000).ok)

func test_timeline_zero_and_failed_shapes() -> void:
	var timeline := SimulationEngine.SimulationResult.new(true, SimulationEngine.OK, "", 5)
	timeline.committed_elapsed_msec = 5
	timeline.change_summary["simulation_time_delta_msec"] = 5
	assert_true(_engine().validate_result(timeline, 10, 15, 5).ok)
	var zero := SimulationEngine.SimulationResult.success_empty(0)
	assert_true(_engine().validate_result(zero, 10, 10, 0).ok)
	var failed := SimulationEngine.SimulationResult.failure(SimulationEngine.ERR_RESULT_INVALID, 1, "bad")
	assert_true(_engine().validate_result(failed, 10, 10, 1).ok)

func test_historical_identity_survives_same_timestamp_redispatch() -> void:
	var state := GameState.new(0)
	state.progression.command_tether_capacity = 1
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
	var threshold := GameState.ThresholdState.new()
	threshold.knowledge_state = &"CHARTED"; threshold.availability_state = &"AVAILABLE"; threshold.lifecycle_state = &"OVERDUE"; threshold.remaining_backlog = 1000000
	state.thresholds[&"THR_GLOAMWOOD"] = threshold
	var reaping := GameState.ReapingState.new()
	reaping.threshold_id = &"THR_GLOAMWOOD"; reaping.is_active = true; reaping.form_id = &"FORM_MAN_AT_ARMS"; reaping.writ_id = &"WRIT_STANDARD"; reaping.assignment_revision = 1
	state.reapings[&"THR_GLOAMWOOD"] = reaping
	var result := _engine().resolve_elapsed(state, 60000)
	assert_true(result.success, result.developer_details)
	var retained := result.segments[0]
	state.reapings[&"THR_GLOAMWOOD"].assignment_revision = 2
	state.reapings[&"THR_GLOAMWOOD"].writ_id = &"WRIT_EMERGENCY"
	assert_eq(retained.assignment_revision, 1)
	assert_eq(retained.writ_id, &"WRIT_STANDARD")
