extends GutTest

const HOUR := 3600000

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func _engine() -> SimulationEngine:
	return SimulationEngine.new(_registry())

func _run_service() -> SimulationRunService:
	return SimulationRunService.new(_registry())

func _canonical(state: GameState) -> Dictionary:
	return SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION).game_state

func _prepared_state(backlog := 1000000, item_ids: Array[StringName] = [&"SOUL_CALLING_SOLDIER"], active := true) -> GameState:
	var state := GameState.new(0)
	state.progression.command_tether_capacity = 1
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
	state.forms[&"FORM_SCRIBE"] = GameState.FormState.new(true, true, 0, &"TEST")
	var threshold := GameState.ThresholdState.new()
	threshold.knowledge_state = &"CHARTED"
	threshold.availability_state = &"AVAILABLE"
	threshold.lifecycle_state = &"SETTLED" if backlog == 0 else &"OVERDUE"
	threshold.remaining_backlog = backlog
	state.thresholds[&"THR_GLOAMWOOD"] = threshold
	if active:
		var reaping := GameState.ReapingState.new()
		reaping.threshold_id = &"THR_GLOAMWOOD"
		reaping.is_active = true
		reaping.form_id = &"FORM_MAN_AT_ARMS"
		reaping.writ_id = &"WRIT_STANDARD"
		reaping.assignment_revision = 1
		state.reapings[&"THR_GLOAMWOOD"] = reaping
	var access := OutputAccessService.new(_registry())
	for item_id in item_ids:
		assert_true(access.unlock_output_item(state, item_id).success)
	assert_true(access.reconcile_available_sources(state).success)
	return state

func _delta(channel_id: StringName = &"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", output_item_id: StringName = &"SOUL_CALLING_SOLDIER", banked := 1, progress_before := 0, progress_after := 100, carry_before := 0, carry_after := 1, total_before := 0, total_after := 1) -> SimulationEngine.SimulationChannelDeltaResult:
	return SimulationEngine.SimulationChannelDeltaResult.new(channel_id, output_item_id, banked, progress_before, progress_after, carry_before, carry_after, total_before, total_after)

func _segment(start := 0, end := 1000, lifecycle: StringName = &"OVERDUE", revision := 1, form_id: StringName = &"FORM_MAN_AT_ARMS", writ_id: StringName = &"WRIT_STANDARD", threshold_id: StringName = &"THR_GLOAMWOOD", retinues: Array[StringName] = [], returned := 1, backlog_reduced := 1, essence := 0, mastery := 100, cycles := 0, deltas: Array[SimulationEngine.SimulationChannelDeltaResult] = []) -> SimulationEngine.SimulationSegmentResult:
	return SimulationEngine.SimulationSegmentResult.new(threshold_id, revision, form_id, writ_id, retinues, lifecycle, start, end, end - start, returned, backlog_reduced, essence, mastery, cycles, deltas)

func _aggregate_channel_deltas(segments: Array[SimulationEngine.SimulationSegmentResult]) -> Array:
	var by_channel := {}
	var order: Array[StringName] = []
	for segment in segments:
		for delta in segment.channel_deltas:
			if not by_channel.has(delta.channel_id):
				order.append(delta.channel_id)
				by_channel[delta.channel_id] = delta.detached_copy()
			else:
				var aggregate: SimulationEngine.SimulationChannelDeltaResult = by_channel[delta.channel_id]
				aggregate.banked_units_delta += delta.banked_units_delta
				aggregate.progress_subunits_after = delta.progress_subunits_after
				aggregate.rate_carry_units_after = delta.rate_carry_units_after
				aggregate.total_banked_units_after = delta.total_banked_units_after
	order.sort_custom(func(a, b): return str(a) < str(b))
	var result: Array = []
	for channel_id in order:
		result.append(by_channel[channel_id])
	return result

func _active_result(segments: Array[SimulationEngine.SimulationSegmentResult], elapsed := 1000, lifecycle_before := "OVERDUE", lifecycle_after := "OVERDUE") -> SimulationEngine.SimulationResult:
	var result := SimulationEngine.SimulationResult.new(true, SimulationEngine.OK, "", elapsed)
	result.committed_elapsed_msec = elapsed
	for segment in segments:
		result.segments.append(segment.detached_copy())
	var returned := 0
	var backlog_reduced := 0
	var essence := 0
	var mastery := 0
	var cycles := 0
	for segment in result.segments:
		returned += segment.returned_souls_delta
		backlog_reduced += segment.backlog_reduced
		essence += segment.essence_delta
		mastery += segment.mastery_delta_subunits
		cycles += segment.completed_cycles_delta
	result.change_summary = {
		"threshold_id": "THR_GLOAMWOOD",
		"operation_id": "THR_GLOAMWOOD",
		"simulation_time_delta_msec": elapsed,
		"returned_souls_delta": returned,
		"backlog_delta": -backlog_reduced,
		"Essence_delta": essence,
		"Mastery_delta_subunits": mastery,
		"completed_cycles_delta": cycles,
		"lifecycle_before": lifecycle_before,
		"lifecycle_after": lifecycle_after,
		"channel_deltas": _aggregate_channel_deltas(result.segments),
	}
	return result

func _timeline_result(elapsed := 1000) -> SimulationEngine.SimulationResult:
	var result := SimulationEngine.SimulationResult.new(true, SimulationEngine.OK, "", elapsed)
	result.committed_elapsed_msec = elapsed
	result.change_summary = {"simulation_time_delta_msec": elapsed}
	return result

func _failed_result(requested := 1, code: StringName = SimulationEngine.ERR_RESULT_INVALID, details := "bad") -> SimulationEngine.SimulationResult:
	return SimulationEngine.SimulationResult.failure(code, requested, details)

func _bank_event(segment: SimulationEngine.SimulationSegmentResult, delta: SimulationEngine.SimulationChannelDeltaResult, reportable := true, tutorial_relevant := true, priority := SimulationEngine.EVENT_PRIORITY_CHANNEL_GAIN, occurred := -1) -> SimulationEngine.SimulationEvent:
	var event := SimulationEngine.SimulationEvent.output_channel_banked(segment.end_simulation_msec if occurred < 0 else occurred, segment.threshold_id, delta.channel_id, delta, str(segment.lifecycle_state))
	event.reportable = reportable
	event.tutorial_relevant = tutorial_relevant
	event.priority = priority
	return event

func _settlement_event(segment: SimulationEngine.SimulationSegmentResult, persistent_returns_total := 1, reportable := true, tutorial_relevant := true, priority := SimulationEngine.EVENT_PRIORITY_LIFECYCLE, occurred := -1) -> SimulationEngine.SimulationEvent:
	var event := SimulationEngine.SimulationEvent.threshold_settled(segment.end_simulation_msec if occurred < 0 else occurred, segment.threshold_id, persistent_returns_total)
	event.reportable = reportable
	event.tutorial_relevant = tutorial_relevant
	event.priority = priority
	return event

func _copy_event(event: SimulationEngine.SimulationEvent) -> SimulationEngine.SimulationEvent:
	var copied := SimulationEngine.SimulationEvent.new(event.event_type, event.occurred_simulation_msec, event.priority, event.subject_id, event.source_id, event.payload.duplicate(true))
	copied.reportable = event.reportable
	copied.tutorial_relevant = event.tutorial_relevant
	return copied

func _copy_result(result: SimulationEngine.SimulationResult) -> SimulationEngine.SimulationResult:
	var copied := SimulationEngine.SimulationResult.new(result.success, result.error_code, result.developer_details, result.requested_elapsed_msec)
	copied.committed_elapsed_msec = result.committed_elapsed_msec
	copied.change_summary = result.change_summary.duplicate(true)
	for segment in result.segments:
		copied.segments.append(segment.detached_copy())
	for event in result.events:
		copied.events.append(_copy_event(event))
	return copied

func _assert_commit_rejected_without_mutation(live: GameState, candidate: GameState, result: SimulationEngine.SimulationResult) -> void:
	var before := _canonical(live)
	var commit := _engine()._commit_if_valid(live, candidate, result)
	assert_false(commit.success)
	assert_eq(commit.error_code, SimulationEngine.ERR_RESULT_INVALID)
	assert_eq(_canonical(live), before)

func _assert_candidate_shape_rejected_without_mutation(live: GameState, candidate: GameState, result: SimulationEngine.SimulationResult) -> void:
	var before := _canonical(live)
	var commit := _engine()._commit_if_valid(live, candidate, result)
	assert_false(commit.success)
	assert_eq(commit.error_code, SimulationEngine.ERR_STATE_INVALID)
	assert_eq(_canonical(live), before)

func test_complete_result_shape_union_accepts_every_valid_shape() -> void:
	var failed := _failed_result(1)
	assert_true(_engine().validate_result(failed, 10, 10, 1).ok)

	var zero := SimulationEngine.SimulationResult.success_empty(0)
	assert_true(_engine().validate_result(zero, 10, 10, 0).ok)

	var timeline := _timeline_result(5)
	assert_true(_engine().validate_result(timeline, 10, 15, 5).ok)

	var overdue_segment := _segment(0, 1000, &"OVERDUE", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", &"THR_GLOAMWOOD", [], 1, 1, 0, 100, 0, [_delta()])
	var active := _active_result([overdue_segment], 1000, "OVERDUE", "OVERDUE")
	active.events.append(_bank_event(active.segments[0], active.segments[0].channel_deltas[0]))
	assert_true(_engine().validate_result(active, 0, 1000, 1000, true).ok)

func test_active_segment_grammar_accepts_only_allowed_forms() -> void:
	var overdue_only := _segment(0, 1000, &"OVERDUE", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", &"THR_GLOAMWOOD", [], 1, 1, 0, 100, 0, [_delta()])
	var overdue_result := _active_result([overdue_only], 1000, "OVERDUE", "OVERDUE")
	overdue_result.events.append(_bank_event(overdue_result.segments[0], overdue_result.segments[0].channel_deltas[0]))
	assert_true(_engine().validate_result(overdue_result, 0, 1000, 1000, true).ok)

	var overdue_settle := _segment(0, 1000, &"OVERDUE", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", &"THR_GLOAMWOOD", [], 1, 1, 0, 100, 0, [_delta()])
	var overdue_settle_result := _active_result([overdue_settle], 1000, "OVERDUE", "SETTLED")
	overdue_settle_result.events.append(_bank_event(overdue_settle_result.segments[0], overdue_settle_result.segments[0].channel_deltas[0]))
	overdue_settle_result.events.append(_settlement_event(overdue_settle_result.segments[0]))
	overdue_settle_result.events.sort_custom(func(a, b): return _engine()._event_less(a, b))
	assert_true(_engine().validate_result(overdue_settle_result, 0, 1000, 1000, true).ok)

	var settled_only := _segment(0, 1000, &"SETTLED", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", &"THR_GLOAMWOOD", [], 1, 0, 0, 100, 0, [_delta()])
	var settled_result := _active_result([settled_only], 1000, "SETTLED", "SETTLED")
	settled_result.events.append(_bank_event(settled_result.segments[0], settled_result.segments[0].channel_deltas[0]))
	assert_true(_engine().validate_result(settled_result, 0, 1000, 1000, true).ok)

	var first := _segment(0, 500, &"OVERDUE", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", &"THR_GLOAMWOOD", [], 1, 1, 0, 50, 0, [_delta(&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", &"SOUL_CALLING_SOLDIER", 1, 0, 100, 0, 1, 0, 1)])
	var second := _segment(500, 1000, &"SETTLED", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", &"THR_GLOAMWOOD", [], 1, 0, 0, 50, 0, [_delta(&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", &"SOUL_CALLING_SOLDIER", 1, 100, 200, 1, 2, 1, 2)])
	var two_segment_result := _active_result([first, second], 1000, "OVERDUE", "SETTLED")
	two_segment_result.events.append(_bank_event(two_segment_result.segments[0], two_segment_result.segments[0].channel_deltas[0]))
	two_segment_result.events.append(_bank_event(two_segment_result.segments[1], two_segment_result.segments[1].channel_deltas[0]))
	two_segment_result.events.append(_settlement_event(two_segment_result.segments[0], 2))
	two_segment_result.events.sort_custom(func(a, b): return _engine()._event_less(a, b))
	assert_true(_engine().validate_result(two_segment_result, 0, 1000, 1000, true).ok)

func test_review_regression_authority_in_failure_zero_and_request_shapes() -> void:
	var failure_with_summary := _failed_result(1)
	failure_with_summary.change_summary["simulation_time_delta_msec"] = 1
	assert_false(_engine().validate_result(failure_with_summary, 10, 10, 1).ok)

	var zero_with_summary := SimulationEngine.SimulationResult.success_empty(0)
	zero_with_summary.change_summary["simulation_time_delta_msec"] = 0
	assert_false(_engine().validate_result(zero_with_summary, 10, 10, 0).ok)

	var requested_mismatch := _timeline_result(5)
	requested_mismatch.requested_elapsed_msec = 6
	assert_false(_engine().validate_result(requested_mismatch, 10, 15, 5).ok)

	var negative_success := _timeline_result(-1)
	negative_success.committed_elapsed_msec = -1
	assert_false(_engine().validate_result(negative_success, 10, 9, -1).ok)

	var success_with_failure_code := _timeline_result(5)
	success_with_failure_code.error_code = SimulationEngine.ERR_RESULT_INVALID
	assert_false(_engine().validate_result(success_with_failure_code, 10, 15, 5).ok)

	var failure_with_ok := _failed_result(1, SimulationEngine.OK, "bad")
	assert_false(_engine().validate_result(failure_with_ok, 10, 10, 1).ok)

func test_review_regression_complete_change_summary_overlap_rejects() -> void:
	var segment := _segment(0, 1000, &"OVERDUE", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", &"THR_GLOAMWOOD", [], 1, 1, 0, 100, 0, [_delta()])
	var result := _active_result([segment], 1000, "OVERDUE", "OVERDUE")
	result.events.append(_bank_event(result.segments[0], result.segments[0].channel_deltas[0]))
	assert_true(_engine().validate_result(result, 0, 1000, 1000, true).ok)

	var missing_key := _copy_result(result)
	missing_key.change_summary.erase("channel_deltas")
	assert_false(_engine().validate_result(missing_key, 0, 1000, 1000, true).ok)

	var extra_key := _copy_result(result)
	extra_key.change_summary["unexpected"] = 1
	assert_false(_engine().validate_result(extra_key, 0, 1000, 1000, true).ok)

	var wrong_value := _copy_result(result)
	wrong_value.change_summary["returned_souls_delta"] = int(wrong_value.change_summary["returned_souls_delta"]) + 1
	assert_false(_engine().validate_result(wrong_value, 0, 1000, 1000, true).ok)

	var wrong_channel_value := _copy_result(result)
	var wrong_channel_deltas: Array = wrong_channel_value.change_summary["channel_deltas"]
	wrong_channel_deltas[0].total_banked_units_after += 1
	assert_false(_engine().validate_result(wrong_channel_value, 0, 1000, 1000, true).ok)

func test_review_regression_segmentless_active_commit_rejects() -> void:
	var timeline := _timeline_result(1000)
	assert_false(_engine().validate_result(timeline, 0, 1000, 1000, true).ok)

func test_closed_segment_grammar_rejects_invalid_forms_and_continuity() -> void:
	var one := _segment(0, 333, &"OVERDUE", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", &"THR_GLOAMWOOD", [], 1, 1, 0, 33, 0, [_delta()])
	var two := _segment(333, 666, &"SETTLED", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", &"THR_GLOAMWOOD", [], 1, 0, 0, 33, 0, [_delta(&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", &"SOUL_CALLING_SOLDIER", 1, 100, 200, 1, 2, 1, 2)])
	var three := _segment(666, 1000, &"SETTLED", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", &"THR_GLOAMWOOD", [], 1, 0, 0, 34, 0, [_delta(&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", &"SOUL_CALLING_SOLDIER", 1, 200, 300, 2, 3, 2, 3)])
	var three_segment_result := _active_result([one, two, three], 1000, "OVERDUE", "SETTLED")
	three_segment_result.events.append(_bank_event(three_segment_result.segments[0], three_segment_result.segments[0].channel_deltas[0]))
	three_segment_result.events.append(_bank_event(three_segment_result.segments[1], three_segment_result.segments[1].channel_deltas[0]))
	three_segment_result.events.append(_bank_event(three_segment_result.segments[2], three_segment_result.segments[2].channel_deltas[0]))
	three_segment_result.events.append(_settlement_event(three_segment_result.segments[0], 3))
	three_segment_result.events.sort_custom(func(a, b): return _engine()._event_less(a, b))
	assert_false(_engine().validate_result(three_segment_result, 0, 1000, 1000, true).ok)

	var overdue_then_overdue := _active_result([_segment(0, 500), _segment(500, 1000, &"OVERDUE")], 1000, "OVERDUE", "OVERDUE")
	assert_false(_engine().validate_result(overdue_then_overdue, 0, 1000, 1000, true).ok)

	var broken_continuity_first := _segment(0, 500, &"OVERDUE", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", &"THR_GLOAMWOOD", [], 1, 1, 0, 50, 0, [_delta(&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", &"SOUL_CALLING_SOLDIER", 0, 0, 100, 0, 1, 0, 0)])
	var broken_continuity_second := _segment(500, 1000, &"SETTLED", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", &"THR_GLOAMWOOD", [], 1, 0, 0, 50, 0, [_delta(&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", &"SOUL_CALLING_SOLDIER", 1, 999, 200, 1, 2, 0, 1)])
	var broken_continuity_result := _active_result([broken_continuity_first, broken_continuity_second], 1000, "OVERDUE", "SETTLED")
	broken_continuity_result.events.append(_settlement_event(broken_continuity_result.segments[0], 2))
	broken_continuity_result.events.append(_bank_event(broken_continuity_result.segments[1], broken_continuity_result.segments[1].channel_deltas[0]))
	broken_continuity_result.events.sort_custom(func(a, b): return _engine()._event_less(a, b))
	assert_false(_engine().validate_result(broken_continuity_result, 0, 1000, 1000, true).ok)

func test_review_regression_unknown_event_types_reject_reportable_and_non_reportable() -> void:
	var segment := _segment(0, 1000, &"OVERDUE", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", &"THR_GLOAMWOOD", [], 1, 1, 0, 100, 0, [_delta()])

	var reportable_unknown := _active_result([segment], 1000, "OVERDUE", "OVERDUE")
	reportable_unknown.events.append(SimulationEngine.SimulationEvent.new(&"UNKNOWN_EVENT", 1000, SimulationEngine.EVENT_PRIORITY_CHANNEL_GAIN, &"THR_GLOAMWOOD", &"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", {}))
	assert_false(_engine().validate_result(reportable_unknown, 0, 1000, 1000, true).ok)

	var non_reportable_unknown := _active_result([segment], 1000, "OVERDUE", "OVERDUE")
	var diagnostic_unknown := SimulationEngine.SimulationEvent.new(&"UNKNOWN_EVENT", 1000, SimulationEngine.EVENT_PRIORITY_CHANNEL_GAIN, &"THR_GLOAMWOOD", &"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", {})
	diagnostic_unknown.reportable = false
	non_reportable_unknown.events.append(diagnostic_unknown)
	assert_false(_engine().validate_result(non_reportable_unknown, 0, 1000, 1000, true).ok)

func test_review_regression_event_order_and_segment_identity_rejects() -> void:
	var segment := _segment(0, 1000, &"OVERDUE", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", &"THR_GLOAMWOOD", [], 1, 1, 0, 100, 0, [_delta()])
	var result := _active_result([segment], 1000, "OVERDUE", "OVERDUE")
	result.events.append(_bank_event(result.segments[0], result.segments[0].channel_deltas[0]))
	assert_true(_engine().validate_result(result, 0, 1000, 1000, true).ok)

	var wrong_priority := _copy_result(result)
	wrong_priority.events[0].priority = 999
	assert_false(_engine().validate_result(wrong_priority, 0, 1000, 1000, true).ok)

	var wrong_flags := _copy_result(result)
	wrong_flags.events[0].reportable = false
	assert_false(_engine().validate_result(wrong_flags, 0, 1000, 1000, true).ok)

	var wrong_subject := _copy_result(result)
	wrong_subject.events[0].subject_id = &"THR_BROKEN_WATCH"
	assert_false(_engine().validate_result(wrong_subject, 0, 1000, 1000, true).ok)

	var wrong_source := _copy_result(result)
	wrong_source.events[0].source_id = &"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"
	assert_false(_engine().validate_result(wrong_source, 0, 1000, 1000, true).ok)

	var wrong_time := _copy_result(result)
	wrong_time.events[0].occurred_simulation_msec = 999
	assert_false(_engine().validate_result(wrong_time, 0, 1000, 1000, true).ok)

func test_closed_event_grammar_rejects_payload_and_count_mismatches() -> void:
	var segment := _segment(0, 1000, &"OVERDUE", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", &"THR_GLOAMWOOD", [], 1, 1, 0, 100, 0, [_delta()])
	var result := _active_result([segment], 1000, "OVERDUE", "OVERDUE")
	result.events.append(_bank_event(result.segments[0], result.segments[0].channel_deltas[0]))
	assert_true(_engine().validate_result(result, 0, 1000, 1000, true).ok)

	var missing_payload_key := _copy_result(result)
	missing_payload_key.events[0].payload.erase("progress_subunits_after")
	assert_false(_engine().validate_result(missing_payload_key, 0, 1000, 1000, true).ok)

	var extra_payload_key := _copy_result(result)
	extra_payload_key.events[0].payload["unexpected"] = 1
	assert_false(_engine().validate_result(extra_payload_key, 0, 1000, 1000, true).ok)

	var wrong_payload_type := _copy_result(result)
	wrong_payload_type.events[0].payload["quantity"] = "1"
	assert_false(_engine().validate_result(wrong_payload_type, 0, 1000, 1000, true).ok)

	var wrong_lifecycle_payload := _copy_result(result)
	wrong_lifecycle_payload.events[0].payload["lifecycle_state"] = "SETTLED"
	assert_false(_engine().validate_result(wrong_lifecycle_payload, 0, 1000, 1000, true).ok)

	var wrong_progress_payload := _copy_result(result)
	wrong_progress_payload.events[0].payload["progress_subunits_after"] = 999
	assert_false(_engine().validate_result(wrong_progress_payload, 0, 1000, 1000, true).ok)

	var duplicate_bank := _copy_result(result)
	duplicate_bank.events.append(_copy_event(duplicate_bank.events[0]))
	assert_false(_engine().validate_result(duplicate_bank, 0, 1000, 1000, true).ok)

	var missing_bank := _active_result([segment], 1000, "OVERDUE", "OVERDUE")
	assert_false(_engine().validate_result(missing_bank, 0, 1000, 1000, true).ok)

	var progress_only_segment := _segment(0, 1000, &"OVERDUE", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", &"THR_GLOAMWOOD", [], 1, 1, 0, 100, 0, [_delta(&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", &"SOUL_CALLING_SOLDIER", 0, 0, 100, 0, 1, 0, 0)])
	var progress_only := _active_result([progress_only_segment], 1000, "OVERDUE", "OVERDUE")
	progress_only.events.append(_bank_event(progress_only.segments[0], _delta(&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", &"SOUL_CALLING_SOLDIER", 1, 0, 100, 0, 1, 0, 1)))
	assert_false(_engine().validate_result(progress_only, 0, 1000, 1000, true).ok)

	var first := _segment(0, 500, &"OVERDUE", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", &"THR_GLOAMWOOD", [], 1, 1, 0, 50, 0, [_delta(&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", &"SOUL_CALLING_SOLDIER", 1, 0, 100, 0, 1, 0, 1)])
	var second := _segment(500, 1000, &"SETTLED", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", &"THR_GLOAMWOOD", [], 1, 0, 0, 50, 0, [_delta(&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", &"SOUL_CALLING_SOLDIER", 1, 100, 200, 1, 2, 1, 2)])
	var duplicate_settlement := _active_result([first, second], 1000, "OVERDUE", "SETTLED")
	duplicate_settlement.events.append(_bank_event(duplicate_settlement.segments[0], duplicate_settlement.segments[0].channel_deltas[0]))
	duplicate_settlement.events.append(_bank_event(duplicate_settlement.segments[1], duplicate_settlement.segments[1].channel_deltas[0]))
	duplicate_settlement.events.append(_settlement_event(duplicate_settlement.segments[0], 2))
	duplicate_settlement.events.append(_settlement_event(duplicate_settlement.segments[0], 2))
	duplicate_settlement.events.sort_custom(func(a, b): return _engine()._event_less(a, b))
	assert_false(_engine().validate_result(duplicate_settlement, 0, 1000, 1000, true).ok)

	var missing_settlement := _active_result([first, second], 1000, "OVERDUE", "SETTLED")
	missing_settlement.events.append(_bank_event(missing_settlement.segments[0], missing_settlement.segments[0].channel_deltas[0]))
	missing_settlement.events.append(_bank_event(missing_settlement.segments[1], missing_settlement.segments[1].channel_deltas[0]))
	missing_settlement.events.sort_custom(func(a, b): return _engine()._event_less(a, b))
	assert_false(_engine().validate_result(missing_settlement, 0, 1000, 1000, true).ok)

	var early_settlement := _active_result([first], 1000, "OVERDUE", "SETTLED")
	early_settlement.events.append(_settlement_event(early_settlement.segments[0], 1, true, true, SimulationEngine.EVENT_PRIORITY_LIFECYCLE, 499))
	assert_false(_engine().validate_result(early_settlement, 0, 1000, 1000, true).ok)

	var spurious_settlement := _active_result([_segment(0, 1000, &"SETTLED")], 1000, "SETTLED", "SETTLED")
	spurious_settlement.events.append(_settlement_event(_segment(0, 1000, &"OVERDUE"), 1))
	assert_false(_engine().validate_result(spurious_settlement, 0, 1000, 1000, true).ok)

func test_review_regression_result_content_identities_and_channel_output_identity_reject() -> void:
	var wrong_form_type := _active_result([_segment(0, 1000, &"OVERDUE", 1, &"THR_GLOAMWOOD")], 1000, "OVERDUE", "OVERDUE")
	assert_false(_engine().validate_result(wrong_form_type, 0, 1000, 1000, true).ok)

	var wrong_writ_type := _active_result([_segment(0, 1000, &"OVERDUE", 1, &"FORM_MAN_AT_ARMS", &"SOUL_CALLING_SOLDIER")], 1000, "OVERDUE", "OVERDUE")
	assert_false(_engine().validate_result(wrong_writ_type, 0, 1000, 1000, true).ok)

	var wrong_threshold_type := _active_result([_segment(0, 1000, &"OVERDUE", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", &"FORM_SCRIBE")], 1000, "OVERDUE", "OVERDUE")
	assert_false(_engine().validate_result(wrong_threshold_type, 0, 1000, 1000, true).ok)

	var wrong_retinue_type := _active_result([_segment(0, 1000, &"OVERDUE", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", &"THR_GLOAMWOOD", [&"FORM_SCRIBE"], 1, 1, 0, 100, 0, [_delta()])], 1000, "OVERDUE", "OVERDUE")
	assert_false(_engine().validate_result(wrong_retinue_type, 0, 1000, 1000, true).ok)

	var wrong_channel_type := _active_result([_segment(0, 1000, &"OVERDUE", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", &"THR_GLOAMWOOD", [], 1, 1, 0, 100, 0, [_delta(&"WRIT_STANDARD")])], 1000, "OVERDUE", "OVERDUE")
	assert_false(_engine().validate_result(wrong_channel_type, 0, 1000, 1000, true).ok)

	var wrong_output_item := _active_result([_segment(0, 1000, &"OVERDUE", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", &"THR_GLOAMWOOD", [], 1, 1, 0, 100, 0, [_delta(&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", &"SOUL_FORM_SCRIBE")])], 1000, "OVERDUE", "OVERDUE")
	assert_false(_engine().validate_result(wrong_output_item, 0, 1000, 1000, true).ok)

	var channel_output_event_mismatch := _active_result([_segment(0, 1000, &"OVERDUE", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", &"THR_GLOAMWOOD", [], 1, 1, 0, 100, 0, [_delta()])], 1000, "OVERDUE", "OVERDUE")
	channel_output_event_mismatch.events.append(_bank_event(channel_output_event_mismatch.segments[0], channel_output_event_mismatch.segments[0].channel_deltas[0]))
	channel_output_event_mismatch.events[0].payload["output_item_id"] = &"SOUL_FORM_SCRIBE"
	assert_false(_engine().validate_result(channel_output_event_mismatch, 0, 1000, 1000, true).ok)

func test_review_regression_transition_coherence_rejects_assignment_lifecycle_numeric_and_timeline_mismatches_without_mutation() -> void:
	var live := _prepared_state(1000000, [&"SOUL_CALLING_SOLDIER"])
	var forecast := _run_service().forecast(live, HOUR)
	assert_true(forecast.success, forecast.developer_details)

	var form_mismatch_result := _copy_result(forecast.simulation_result)
	form_mismatch_result.segments[0].form_id = &"FORM_SCRIBE"
	_assert_commit_rejected_without_mutation(live.deep_clone(), forecast.projected_state.deep_clone(), form_mismatch_result)

	var lifecycle_mismatch_result := _copy_result(forecast.simulation_result)
	lifecycle_mismatch_result.segments[0].lifecycle_state = &"SETTLED"
	lifecycle_mismatch_result.change_summary["lifecycle_before"] = "SETTLED"
	lifecycle_mismatch_result.change_summary["lifecycle_after"] = "SETTLED"
	_assert_commit_rejected_without_mutation(live.deep_clone(), forecast.projected_state.deep_clone(), lifecycle_mismatch_result)

	var numeric_mismatch_result := _copy_result(forecast.simulation_result)
	numeric_mismatch_result.segments[0].returned_souls_delta += 1
	numeric_mismatch_result.segments[0].backlog_reduced += 1
	numeric_mismatch_result.change_summary["returned_souls_delta"] = int(numeric_mismatch_result.change_summary["returned_souls_delta"]) + 1
	numeric_mismatch_result.change_summary["backlog_delta"] = int(numeric_mismatch_result.change_summary["backlog_delta"]) - 1
	_assert_commit_rejected_without_mutation(live.deep_clone(), forecast.projected_state.deep_clone(), numeric_mismatch_result)

	var timeline_live := _prepared_state(1000000, [], false)
	var timeline_forecast := _run_service().forecast(timeline_live, 1000)
	assert_true(timeline_forecast.success, timeline_forecast.developer_details)
	timeline_forecast.projected_state.inventory.entries[&"RES_ESSENCE"] = GameState.InventoryEntryState.new(1)
	_assert_commit_rejected_without_mutation(timeline_live, timeline_forecast.projected_state, timeline_forecast.simulation_result)

	var zero_live := _prepared_state(1000000, [], false)
	var zero_candidate := zero_live.deep_clone()
	zero_candidate.progression.command_tether_capacity = 99
	_assert_commit_rejected_without_mutation(zero_live, zero_candidate, SimulationEngine.SimulationResult.success_empty(0))

func test_review_regression_candidate_shape_is_validated_before_coherence_dereferences() -> void:
	var live := _prepared_state(1000000, [&"SOUL_CALLING_SOLDIER"])
	var forecast := _run_service().forecast(live, HOUR)
	assert_true(forecast.success, forecast.developer_details)

	var missing_threshold_candidate := forecast.projected_state.deep_clone()
	missing_threshold_candidate.thresholds.erase(&"THR_GLOAMWOOD")
	_assert_candidate_shape_rejected_without_mutation(live.deep_clone(), missing_threshold_candidate, forecast.simulation_result)

	var missing_form_candidate := forecast.projected_state.deep_clone()
	missing_form_candidate.forms.erase(&"FORM_MAN_AT_ARMS")
	_assert_candidate_shape_rejected_without_mutation(live.deep_clone(), missing_form_candidate, forecast.simulation_result)

func test_review_regression_settlement_event_keeps_owning_boundary_total() -> void:
	var state := _prepared_state(1, [&"SOUL_CALLING_SOLDIER"])
	var result := _engine().resolve_elapsed(state, 100000)
	assert_true(result.success, result.developer_details)
	assert_eq(result.events.size(), 1)
	assert_eq(result.events[0].event_type, SimulationEngine.EVENT_THRESHOLD_SETTLED)
	assert_eq(result.events[0].occurred_simulation_msec, 870)
	assert_eq(result.segments.size(), 2)
	assert_eq(result.segments[0].returned_souls_delta, 1)
	assert_eq(result.events[0].payload.persistent_returns_total, 1)
	assert_gt(state.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total, result.events[0].payload.persistent_returns_total)
