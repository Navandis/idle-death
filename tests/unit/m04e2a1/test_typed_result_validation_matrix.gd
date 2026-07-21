extends GutTest

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func _engine() -> SimulationEngine:
	return SimulationEngine.new(_registry())

func _delta(channel_id: StringName = &"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", banked := 0, total_before := 0, total_after := 0) -> SimulationEngine.SimulationChannelDeltaResult:
	return SimulationEngine.SimulationChannelDeltaResult.new(channel_id, &"SOUL_CALLING_SOLDIER", banked, 0, 100, 0, 1, total_before, total_after)

func _segment(start := 0, end := 1000, lifecycle: StringName = &"OVERDUE", revision := 1, form_id: StringName = &"FORM_MAN_AT_ARMS", writ_id: StringName = &"WRIT_STANDARD", threshold_id: StringName = &"THR_GLOAMWOOD", retinues: Array[StringName] = []) -> SimulationEngine.SimulationSegmentResult:
	return SimulationEngine.SimulationSegmentResult.new(threshold_id, revision, form_id, writ_id, retinues, lifecycle, start, end, end - start, 1, 1, 0, 100, 0, [_delta()])

func _result(segments: Array[SimulationEngine.SimulationSegmentResult], elapsed := 1000) -> SimulationEngine.SimulationResult:
	var result := SimulationEngine.SimulationResult.new(true, SimulationEngine.OK, "", elapsed)
	result.committed_elapsed_msec = elapsed
	for segment in segments: result.segments.append(segment)
	result.change_summary["simulation_time_delta_msec"] = elapsed
	return result

func test_channel_local_validation_full_matrix() -> void:
	assert_false(SimulationEngine.SimulationChannelDeltaResult.new(&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", &"SOUL_CALLING_SOLDIER", -1, 0, 0, 0, 0, 0, 0).validate(900000).ok)
	assert_false(SimulationEngine.SimulationChannelDeltaResult.new(&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", &"SOUL_CALLING_SOLDIER", 0, 0, 0, 900000, 0, 0, 0).validate(900000).ok)
	assert_false(SimulationEngine.SimulationChannelDeltaResult.new(&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", &"SOUL_CALLING_SOLDIER", 0, 0, 0, 0, 900000, 0, 0).validate(900000).ok)
	assert_false(SimulationEngine.SimulationChannelDeltaResult.new(&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", &"SOUL_CALLING_SOLDIER", 0, 0, 0, 0, 0, 2, 1).validate(900000).ok)
	assert_false(SimulationEngine.SimulationChannelDeltaResult.new(&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", &"SOUL_CALLING_SOLDIER", 2, 0, 0, 0, 0, 0, 1).validate(900000).ok)

func test_segment_local_validation_full_matrix() -> void:
	assert_false(SimulationEngine.SimulationSegmentResult.new(&"", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", [], &"OVERDUE", 0, 1, 1, 0, 0, 0, 0, 0, []).validate({}).ok)
	assert_false(SimulationEngine.SimulationSegmentResult.new(&"THR_GLOAMWOOD", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", [], &"OVERDUE", 5, 5, 0, 0, 0, 0, 0, 0, []).validate({}).ok)
	assert_false(SimulationEngine.SimulationSegmentResult.new(&"THR_GLOAMWOOD", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", [], &"OVERDUE", 0, 5, 4, 0, 0, 0, 0, 0, []).validate({}).ok)
	assert_false(SimulationEngine.SimulationSegmentResult.new(&"THR_GLOAMWOOD", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", [], &"OVERDUE", 0, 5, 5, -1, 0, 0, 0, 0, []).validate({}).ok)
	assert_false(SimulationEngine.SimulationSegmentResult.new(&"THR_GLOAMWOOD", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", [&"RET_A", &"RET_A"], &"OVERDUE", 0, 5, 5, 0, 0, 0, 0, 0, []).validate({}).ok)
	var unsorted_channels: Array[SimulationEngine.SimulationChannelDeltaResult] = [_delta(&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"), _delta(&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS")]
	var periods := {&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS": 28800000, &"CHANNEL_GLOAMWOOD_SOLDIER_SOULS": 900000}
	assert_false(SimulationEngine.SimulationSegmentResult.new(&"THR_GLOAMWOOD", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", [], &"OVERDUE", 0, 5, 5, 0, 0, 0, 0, 0, unsorted_channels).validate(periods).ok)

func test_complete_result_validation_matrix() -> void:
	var missing_segments := SimulationEngine.SimulationResult.new(true, SimulationEngine.OK, "", 1000)
	missing_segments.committed_elapsed_msec = 1000
	assert_false(_engine().validate_result(missing_segments, 0, 1000, 1000).ok)
	missing_segments.change_summary["simulation_time_delta_msec"] = 1000
	assert_true(_engine().validate_result(missing_segments, 0, 1000, 1000).ok)
	assert_false(_engine().validate_result(missing_segments, 0, 1000, 1000, true).ok)
	assert_false(_engine().validate_result(_result([_segment(0, 1000, &"OVERDUE", 1, &"FORM_DOES_NOT_EXIST")], 1000), 0, 1000, 1000).ok)
	assert_false(_engine().validate_result(_result([_segment(0, 1000, &"OVERDUE", 1, &"FORM_MAN_AT_ARMS", &"WRIT_DOES_NOT_EXIST")], 1000), 0, 1000, 1000).ok)
	assert_false(_engine().validate_result(_result([_segment(0, 1000, &"OVERDUE", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", &"THR_DOES_NOT_EXIST")], 1000), 0, 1000, 1000).ok)
	var wrong_threshold_channel := _result([_segment()], 1000)
	wrong_threshold_channel.segments[0].channel_deltas.clear()
	wrong_threshold_channel.segments[0].channel_deltas.append(_delta(&"CHANNEL_BROKEN_WATCH_PROVISIONS"))
	assert_false(_engine().validate_result(wrong_threshold_channel, 0, 1000, 1000).ok)
	assert_false(_engine().validate_result(_result([_segment(1, 1000)], 999), 0, 999, 999).ok)
	assert_false(_engine().validate_result(_result([_segment(0, 900)], 900), 0, 1000, 900).ok)
	assert_false(_engine().validate_result(_result([_segment(0, 400), _segment(500, 1000)], 1000), 0, 1000, 1000).ok)
	assert_false(_engine().validate_result(_result([_segment(0, 600), _segment(500, 1000)], 1100), 0, 1000, 1100).ok)
	assert_false(_engine().validate_result(_result([_segment(0, 500), _segment(500, 1000, &"OVERDUE", 2)], 1000), 0, 1000, 1000).ok)
	assert_false(_engine().validate_result(_result([_segment(0, 500), _segment(500, 1000, &"OVERDUE", 1, &"FORM_SCRIBE")], 1000), 0, 1000, 1000).ok)
	assert_false(_engine().validate_result(_result([_segment(0, 500), _segment(500, 1000, &"OVERDUE", 1, &"FORM_MAN_AT_ARMS", &"WRIT_EMERGENCY")], 1000), 0, 1000, 1000).ok)
	assert_false(_engine().validate_result(_result([_segment(0, 500), _segment(500, 1000, &"OVERDUE", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", &"THR_BROKEN_WATCH")], 1000), 0, 1000, 1000).ok)
	assert_true(_engine().validate_result(_result([_segment(0, 500), _segment(500, 1000, &"SETTLED")], 1000), 0, 1000, 1000).ok)

func test_event_order_and_boundary_matrix() -> void:
	var result := _result([_segment(0, 500), _segment(500, 1000, &"SETTLED")], 1000)
	result.segments[0].channel_deltas.clear()
	result.segments[0].channel_deltas.append(_delta(&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", 1, 0, 1))
	result.events.append(SimulationEngine.SimulationEvent.output_channel_banked(500, &"THR_GLOAMWOOD", &"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", _delta(&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", 1, 0, 1), "OVERDUE"))
	result.events.append(SimulationEngine.SimulationEvent.threshold_settled(500, &"THR_GLOAMWOOD", 1))
	result.events.sort_custom(_event_less)
	assert_eq(result.events[0].priority, SimulationEngine.EVENT_PRIORITY_CHANNEL_GAIN)
	assert_true(_engine().validate_result(result, 0, 1000, 1000).ok)
	result.events[0].occurred_simulation_msec = 1001
	assert_false(_engine().validate_result(result, 0, 1000, 1000).ok)
	result.events[0].occurred_simulation_msec = 0
	assert_false(_engine().validate_result(result, 0, 1000, 1000).ok)
	result.events[0].reportable = false
	assert_true(_engine().validate_result(result, 0, 1000, 1000).ok)

func test_review_regression_mismatched_channel_output_event_and_summary_reject() -> void:
	var bad_channel := _result([_segment()], 1000)
	bad_channel.segments[0].channel_deltas[0].output_item_id = &"SOUL_FORM_SCRIBE"
	assert_false(_engine().validate_result(bad_channel, 0, 1000, 1000).ok)

	var out_of_order := _result([_segment(0, 500), _segment(500, 1000, &"SETTLED")], 1000)
	out_of_order.events.append(SimulationEngine.SimulationEvent.threshold_settled(500, &"THR_GLOAMWOOD", 1))
	out_of_order.events.append(SimulationEngine.SimulationEvent.output_channel_banked(500, &"THR_GLOAMWOOD", &"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", _delta(&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", 1, 0, 1), "OVERDUE"))
	assert_false(_engine().validate_result(out_of_order, 0, 1000, 1000).ok)

	var wrong_event_subject := _result([_segment()], 1000)
	wrong_event_subject.events.append(SimulationEngine.SimulationEvent.output_channel_banked(1000, &"THR_BROKEN_WATCH", &"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", _delta(&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", 1, 0, 1), "OVERDUE"))
	assert_false(_engine().validate_result(wrong_event_subject, 0, 1000, 1000).ok)

	var wrong_event_channel := _result([_segment()], 1000)
	wrong_event_channel.events.append(SimulationEngine.SimulationEvent.output_channel_banked(1000, &"THR_GLOAMWOOD", &"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS", _delta(&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", 1, 0, 1), "OVERDUE"))
	assert_false(_engine().validate_result(wrong_event_channel, 0, 1000, 1000).ok)

	var stale_summary := _result([_segment()], 1000)
	stale_summary.change_summary["returned_souls_delta"] = 999
	assert_false(_engine().validate_result(stale_summary, 0, 1000, 1000).ok)

	var stale_channel_summary := _result([_segment()], 1000)
	stale_channel_summary.change_summary["channel_deltas"] = [_delta(&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", 1, 0, 1)]
	assert_false(_engine().validate_result(stale_channel_summary, 0, 1000, 1000).ok)

func _event_less(a: SimulationEngine.SimulationEvent, b: SimulationEngine.SimulationEvent) -> bool:
	if a.occurred_simulation_msec != b.occurred_simulation_msec: return a.occurred_simulation_msec < b.occurred_simulation_msec
	if a.priority != b.priority: return a.priority < b.priority
	if str(a.subject_id) != str(b.subject_id): return str(a.subject_id) < str(b.subject_id)
	return str(a.source_id) < str(b.source_id)
