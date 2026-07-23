extends GutTest

const HOUR := 3600000

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func _engine() -> SimulationEngine:
	return SimulationEngine.new(_registry())

func _state(backlog: int = 1000000, active: bool = true) -> GameState:
	var state := GameState.new(0)
	state.progression.command_tether_capacity = 1
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"T2_TEST")
	var threshold := GameState.ThresholdState.new()
	threshold.knowledge_state = &"CHARTED"
	threshold.availability_state = &"AVAILABLE"
	threshold.lifecycle_state = &"SETTLED" if backlog == 0 else &"OVERDUE"
	threshold.remaining_backlog = backlog
	state.thresholds[&"THR_GLOAMWOOD"] = threshold
	var reaping := GameState.ReapingState.new()
	reaping.threshold_id = &"THR_GLOAMWOOD"
	reaping.is_active = active
	reaping.form_id = &"FORM_MAN_AT_ARMS"
	reaping.writ_id = &"WRIT_STANDARD"
	reaping.assignment_revision = 11
	state.reapings[&"THR_GLOAMWOOD"] = reaping
	return state

func _unlock_soldier_and_scribe(state: GameState) -> void:
	var access := OutputAccessService.new(_registry())
	assert_true(access.unlock_output_item(state, &"SOUL_CALLING_SOLDIER").success)
	assert_true(access.unlock_output_item(state, &"SOUL_FORM_SCRIBE").success)
	assert_true(access.reconcile_available_sources(state).success)

func test_four_result_shapes_and_typed_child_arrays() -> void:
	var failure := _engine().resolve_elapsed(_state(), -1)
	assert_eq(failure.result_kind, SimulationResult.KIND_FAILURE)
	assert_false(failure.success)
	assert_eq(failure.committed_elapsed_msec, 0)
	assert_eq(failure.baseline_simulation_time_msec, failure.result_simulation_time_msec)
	assert_true(failure.segments.is_empty())
	assert_true(failure.events.is_empty())

	var zero_state := _state()
	var zero := _engine().resolve_elapsed(zero_state, 0)
	assert_eq(zero.result_kind, SimulationResult.KIND_ZERO_DURATION)
	assert_true(zero.success)
	assert_eq(zero.requested_elapsed_msec, 0)
	assert_eq(zero.baseline_simulation_time_msec, zero.result_simulation_time_msec)

	var timeline := _engine().resolve_elapsed(_state(100, false), 1234)
	assert_eq(timeline.result_kind, SimulationResult.KIND_TIMELINE_ONLY)
	assert_eq(timeline.committed_elapsed_msec, 1234)
	assert_eq(timeline.result_simulation_time_msec - timeline.baseline_simulation_time_msec, 1234)
	assert_true(timeline.segments.is_empty())
	assert_true(timeline.events.is_empty())

	var active := _engine().resolve_elapsed(_state(), 1000)
	assert_eq(active.result_kind, SimulationResult.KIND_ACTIVE_REAPING)
	assert_true(active.success)
	assert_false(active.segments.is_empty())
	for segment in active.segments:
		assert_true(segment is SimulationSegmentResult)
		for channel in segment.channel_deltas: assert_true(channel is SimulationChannelDeltaResult)
	for event in active.events: assert_true(event is SimulationChannelBankedEvent or event is SimulationThresholdSettledEvent)

func test_detachment_and_value_equality_ignore_refcounted_identity() -> void:
	var state := _state()
	_unlock_soldier_and_scribe(state)
	var result := _engine().resolve_elapsed(state, HOUR)
	var copy := result.detached_copy()
	assert_true(result.value_equals(copy))
	assert_ne(result, copy)
	var retained_segments := result.segments
	var retained_events := result.events
	assert_false(retained_segments.is_empty())
	retained_segments.clear()
	retained_events.clear()
	assert_false(result.segments.is_empty())
	assert_eq(result.events.size(), copy.events.size())
	var retained_segment := result.segments[0]
	var retinues := retained_segment.ordered_retinue_ids
	retinues.append(&"RET_MUTATION")
	assert_false(retained_segment.ordered_retinue_ids.has(&"RET_MUTATION"))
	var channels := retained_segment.channel_deltas
	if not channels.is_empty():
		assert_true(channels[0].value_equals(channels[0].detached_copy()))

func test_historical_identity_survives_same_timestamp_reconfiguration() -> void:
	var state := _state()
	var first := _engine().resolve_elapsed(state, HOUR)
	var retained := first.segments[0]
	var retained_identity := [retained.threshold_id, retained.assignment_revision, retained.form_id, retained.writ_id, retained.ordered_retinue_ids]
	state.reapings[&"THR_GLOAMWOOD"].is_active = false
	state.reapings[&"THR_GLOAMWOOD"].assignment_revision = 99
	state.reapings[&"THR_GLOAMWOOD"].form_id = &"FORM_SCRIBE"
	assert_eq([retained.threshold_id, retained.assignment_revision, retained.form_id, retained.writ_id, retained.ordered_retinue_ids], retained_identity)
	assert_true(first.value_equals(first.detached_copy()))

func test_channel_endpoints_period_and_progress_only_are_self_interpretable() -> void:
	var state := _state()
	_unlock_soldier_and_scribe(state)
	var result := _engine().resolve_elapsed(state, HOUR)
	var saw_channel := false
	for segment in result.segments:
		for channel in segment.channel_deltas:
			saw_channel = true
			assert_gt(channel.rate_period_msec, 0)
			assert_gte(channel.progress_subunits_before, 0)
			assert_lt(channel.progress_subunits_before, FixedPoint.SCALE)
			assert_gte(channel.progress_subunits_after, 0)
			assert_lt(channel.progress_subunits_after, FixedPoint.SCALE)
			assert_gte(channel.rate_carry_units_before, 0)
			assert_lt(channel.rate_carry_units_before, channel.rate_period_msec)
			assert_gte(channel.rate_carry_units_after, 0)
			assert_lt(channel.rate_carry_units_after, channel.rate_period_msec)
			assert_eq(channel.total_banked_units_after - channel.total_banked_units_before, channel.banked_units_delta)
	assert_true(saw_channel)
	var progress_state := _state()
	assert_true(OutputAccessService.new(_registry()).unlock_output_item(progress_state, &"SOUL_FORM_SCRIBE").success)
	assert_true(OutputAccessService.new(_registry()).reconcile_available_sources(progress_state).success)
	var progress_result := _engine().resolve_elapsed(progress_state, 2 * HOUR)
	var progress_delta: SimulationChannelDeltaResult = progress_result.segments[0].channel_deltas[0]
	assert_eq(progress_delta.banked_units_delta, 0)
	assert_eq(progress_result.events.size(), 0)

func test_closed_events_have_exact_fields_order_and_boundary_ownership() -> void:
	var state := _state(1)
	_unlock_soldier_and_scribe(state)
	var result := _engine().resolve_elapsed(state, 10000)
	assert_true(result.success, result.developer_details)
	assert_eq(result.events.size(), 1)
	var settlement_count := 0
	for event in result.events:
		assert_true(event is SimulationChannelBankedEvent or event is SimulationThresholdSettledEvent)
		var owner: SimulationSegmentResult = result.segments[event.segment_index]
		assert_gt(event.occurred_simulation_msec, owner.start_simulation_msec)
		assert_lte(event.occurred_simulation_msec, owner.end_simulation_msec)
		if event is SimulationThresholdSettledEvent:
			settlement_count += 1
			assert_eq(event.occurred_simulation_msec, 870)
			assert_eq(event.lifecycle_before, &"OVERDUE")
			assert_eq(event.lifecycle_after, &"SETTLED")
			assert_eq(event.remaining_backlog_after, 0)
		else:
			assert_gt(event.quantity, 0)
			assert_eq(event.occurred_simulation_msec, owner.end_simulation_msec)
	assert_eq(settlement_count, 1)
	var base_event := SimulationEvent.new(&"OUTPUT_CHANNEL_BANKED", 1, 100, 0, &"THR_GLOAMWOOD", &"CHANNEL_X")
	var invalid := SimulationResult.active_reaping(1000, 0, 1000, ContentRegistry.CURRENT_REVISION, result.segments, [base_event])
	assert_false(SimulationResultProjector.validate(invalid).ok)

func test_structural_validation_rejects_gap_duplicate_channel_and_endpoint_mismatch() -> void:
	var channel := SimulationChannelDeltaResult.new(&"CHANNEL_TEST", &"SOUL_TEST", 2, 0, 0, 1000, 0, 0, 1, 2)
	assert_false(SimulationResultProjector.validate(_active_with_channel(channel)).ok)
	var valid_channel := SimulationChannelDeltaResult.new(&"CHANNEL_TEST", &"SOUL_TEST", 1, 0, 0, 1000, 0, 0, 0, 1)
	var first := _segment(0, 0, 500, valid_channel)
	var gap := _segment(1, 501, 1000, valid_channel)
	var result := SimulationResult.active_reaping(1000, 0, 1000, ContentRegistry.CURRENT_REVISION, [first, gap], [])
	assert_false(SimulationResultProjector.validate(result).ok)
	var bad_carry := SimulationChannelDeltaResult.new(&"CHANNEL_TEST", &"SOUL_TEST", 0, 0, 0, 1000, 1000, 0, 0, 0)
	assert_false(SimulationResultProjector.validate(_active_with_channel(bad_carry)).ok)

func test_projector_requires_frozen_journal_and_preserves_timeline_shape() -> void:
	var context := SimulationRunContext.new(25, 1234, false, &"", 0, &"", &"", [], &"", ContentRegistry.CURRENT_REVISION)
	var journal := SimulationFactJournal.new(25, 1234)
	assert_true(journal.record_timeline(25, 1259).ok)
	assert_false(SimulationResultProjector.project(context, journal).ok)
	assert_true(journal.freeze().ok)
	var projected := SimulationResultProjector.project(context, journal)
	assert_true(projected.ok, str(projected))
	assert_eq(projected.result.result_kind, SimulationResult.KIND_TIMELINE_ONLY)
	assert_eq(projected.result.baseline_simulation_time_msec, 25)
	assert_eq(projected.result.result_simulation_time_msec, 1259)

func _segment(index: int, start: int, end: int, channel: SimulationChannelDeltaResult) -> SimulationSegmentResult:
	return SimulationSegmentResult.new(index, &"THR_TEST", 1, &"FORM_TEST", &"WRIT_TEST", [], &"OVERDUE", start, end, end - start, 1, 0, 0, 0, 0, [channel])

func _active_with_channel(channel: SimulationChannelDeltaResult) -> SimulationResult:
	var segment := _segment(0, 0, 1000, channel)
	return SimulationResult.active_reaping(1000, 0, 1000, ContentRegistry.CURRENT_REVISION, [segment], [])
