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

func test_failure_cursor_provenance_and_zero_duration_prevalidation_order() -> void:
	var source := _state()
	source.simulation_time_msec = 777
	var negative := _engine().resolve_elapsed(source, -1)
	assert_eq(negative.result_kind, SimulationResult.KIND_FAILURE)
	assert_eq(negative.baseline_simulation_time_msec, 777)
	assert_eq(negative.result_simulation_time_msec, 777)
	assert_eq(source.simulation_time_msec, 777)

	var invalid_source := _state()
	invalid_source.simulation_time_msec = 888
	invalid_source.forms.erase(&"FORM_MAN_AT_ARMS")
	var invalid := _engine().resolve_elapsed(invalid_source, 1000)
	assert_eq(invalid.result_kind, SimulationResult.KIND_FAILURE)
	assert_eq(invalid.baseline_simulation_time_msec, 888)
	assert_eq(invalid.result_simulation_time_msec, 888)
	var overflow_source := _state()
	overflow_source.simulation_time_msec = FixedPoint.INT64_MAX
	var overflow := _engine().resolve_elapsed(overflow_source, 1)
	assert_eq(overflow.result_kind, SimulationResult.KIND_FAILURE)
	assert_eq(overflow.error_code, SimulationEngine.ERR_OVERFLOW)
	assert_eq(overflow.baseline_simulation_time_msec, FixedPoint.INT64_MAX)
	var zero_invalid := _engine().resolve_elapsed(invalid_source, 0)
	assert_eq(zero_invalid.result_kind, SimulationResult.KIND_ZERO_DURATION)
	assert_eq(zero_invalid.baseline_simulation_time_msec, 888)
	var null_zero := _engine().resolve_elapsed(null, 0)
	assert_eq(null_zero.result_kind, SimulationResult.KIND_ZERO_DURATION)
	assert_eq(null_zero.baseline_simulation_time_msec, 0)

func test_result_kind_and_envelope_malformed_combinations_reject() -> void:
	var invalid_results: Array[SimulationResult] = [
		SimulationResult.new(SimulationResult.KIND_FAILURE, true, &"ERR", "", 1000, 0, 7, 7, ""),
		SimulationResult.new(SimulationResult.KIND_FAILURE, false, &"ERR", "", 1000, 1, 7, 7, ""),
		SimulationResult.new(SimulationResult.KIND_ZERO_DURATION, true, &"", "", 1, 0, 7, 7, ""),
		SimulationResult.new(SimulationResult.KIND_TIMELINE_ONLY, true, &"", "", 1000, 999, 7, 1006, ContentRegistry.CURRENT_REVISION),
		SimulationResult.new(SimulationResult.KIND_ACTIVE_REAPING, true, &"", "", 1000, 1000, 7, 1007, ContentRegistry.CURRENT_REVISION),
	]
	for invalid in invalid_results:
		assert_false(SimulationResultProjector.validate(invalid).ok)

func test_context_and_frozen_journal_snapshots_are_detached() -> void:
	var context := SimulationRunContext.new(25, 1234, true, &"THR_TEST", 4, &"FORM_TEST", &"WRIT_TEST", [&"RET_A"], &"OVERDUE", ContentRegistry.CURRENT_REVISION)
	var context_ids := context.ordered_retinue_ids
	context_ids.append(&"RET_MUTATION")
	assert_eq(context.ordered_retinue_ids, [&"RET_A"])
	var journal := SimulationFactJournal.new(25, 1234)
	assert_true(journal.record_timeline(25, 1259).ok)
	assert_true(journal.freeze().ok)
	var facts := journal.facts_snapshot()
	facts[0]["after_time"] = 9999
	assert_eq(journal.facts_snapshot()[0].after_time, 1259)
	assert_false(journal.record_timeline(25, 1259).ok)

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
	var detached_event := result.events[0].detached_copy()
	assert_ne(detached_event, result.events[0])
	assert_true(detached_event.value_equals(result.events[0]))

func test_event_subtype_fields_and_settlement_cardinality_reject_mismatches() -> void:
	var settlement_result := _engine().resolve_elapsed(_state(1), 10000)
	var settlement: SimulationThresholdSettledEvent = settlement_result.events[0]
	var bad_returns := SimulationThresholdSettledEvent.new(settlement.occurred_simulation_msec, settlement.segment_index, settlement.subject_id, -1, settlement.remaining_backlog_before, settlement.remaining_backlog_after, settlement.lifecycle_before, settlement.lifecycle_after)
	var bad_returns_result := SimulationResult.active_reaping(settlement_result.requested_elapsed_msec, settlement_result.baseline_simulation_time_msec, settlement_result.result_simulation_time_msec, settlement_result.content_revision, settlement_result.segments, [bad_returns])
	assert_false(SimulationResultProjector.validate(bad_returns_result, true).ok)
	var missing_settlement := SimulationResult.active_reaping(settlement_result.requested_elapsed_msec, settlement_result.baseline_simulation_time_msec, settlement_result.result_simulation_time_msec, settlement_result.content_revision, settlement_result.segments, [])
	assert_false(SimulationResultProjector.validate(missing_settlement).ok)
	assert_false(SimulationResultProjector.validate(missing_settlement, true).ok)
	var duplicate_settlement: Array[SimulationEvent] = [settlement, settlement]
	var duplicate_result := SimulationResult.active_reaping(settlement_result.requested_elapsed_msec, settlement_result.baseline_simulation_time_msec, settlement_result.result_simulation_time_msec, settlement_result.content_revision, settlement_result.segments, duplicate_settlement)
	assert_false(SimulationResultProjector.validate(duplicate_result, true).ok)
	var incomplete := _engine().resolve_elapsed(_state(1000000), 1000)
	assert_true(incomplete.events.is_empty())
	assert_true(SimulationResultProjector.validate(incomplete).ok)
	var already_settled := _engine().resolve_elapsed(_state(0), 1000)
	assert_true(already_settled.events.is_empty())
	assert_true(SimulationResultProjector.validate(already_settled).ok)

	var channel_state := _state()
	_unlock_soldier_and_scribe(channel_state)
	var channel_result := _engine().resolve_elapsed(channel_state, HOUR)
	var bank_event: SimulationChannelBankedEvent = null
	for event in channel_result.events:
		if event is SimulationChannelBankedEvent:
			bank_event = event
			break
	assert_not_null(bank_event)
	var bad_quantity := SimulationChannelBankedEvent.new(bank_event.occurred_simulation_msec, bank_event.segment_index, bank_event.subject_id, bank_event.source_id, bank_event.output_item_id, bank_event.quantity + 1, bank_event.lifecycle_state, bank_event.total_banked_units_after, bank_event.progress_subunits_after)
	var bad_channel_result := SimulationResult.active_reaping(channel_result.requested_elapsed_msec, channel_result.baseline_simulation_time_msec, channel_result.result_simulation_time_msec, channel_result.content_revision, channel_result.segments, [bad_quantity])
	assert_false(SimulationResultProjector.validate(bad_channel_result).ok)

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
	var invalid_channels: Array[SimulationChannelDeltaResult] = [
		SimulationChannelDeltaResult.new(&"CHANNEL_TEST", &"SOUL_TEST", 0, 0, 0, 0, 0, 0, 0, 0),
		SimulationChannelDeltaResult.new(&"CHANNEL_TEST", &"SOUL_TEST", 0, -1, 0, 1000, 0, 0, 0, 0),
		SimulationChannelDeltaResult.new(&"CHANNEL_TEST", &"SOUL_TEST", 0, FixedPoint.SCALE, 0, 1000, 0, 0, 0, 0),
		SimulationChannelDeltaResult.new(&"CHANNEL_TEST", &"SOUL_TEST", 0, 0, -1, 1000, 0, 0, 0, 0),
		SimulationChannelDeltaResult.new(&"CHANNEL_TEST", &"SOUL_TEST", 0, 0, FixedPoint.SCALE, 1000, 0, 0, 0, 0),
		SimulationChannelDeltaResult.new(&"CHANNEL_TEST", &"SOUL_TEST", 0, 0, 0, 1000, 1000, 0, 0, 0),
		SimulationChannelDeltaResult.new(&"CHANNEL_TEST", &"SOUL_TEST", 0, 0, 0, 1000, 0, 1000, 0, 0),
		SimulationChannelDeltaResult.new(&"CHANNEL_TEST", &"SOUL_TEST", 0, 0, 0, 1000, 0, 0, -1, 0),
		SimulationChannelDeltaResult.new(&"CHANNEL_TEST", &"SOUL_TEST", 0, 0, 0, 1000, 0, 0, 2, 1),
	]
	for invalid_channel in invalid_channels:
		assert_false(SimulationResultProjector.validate(_active_with_channel(invalid_channel)).ok)

	var duplicate_retinues := SimulationSegmentResult.new(0, &"THR_TEST", 1, &"FORM_TEST", &"WRIT_TEST", [&"RET_A", &"RET_A"], &"OVERDUE", 0, 1000, 1000, 0, 0, 0, 0, 0, [])
	var duplicate_result := SimulationResult.active_reaping(1000, 0, 1000, ContentRegistry.CURRENT_REVISION, [duplicate_retinues], [])
	assert_false(SimulationResultProjector.validate(duplicate_result).ok)
	var selected_order := SimulationSegmentResult.new(0, &"THR_TEST", 1, &"FORM_TEST", &"WRIT_TEST", [&"RET_B", &"RET_A"], &"OVERDUE", 0, 1000, 1000, 0, 0, 0, 0, 0, [])
	var selected_order_result := SimulationResult.active_reaping(1000, 0, 1000, ContentRegistry.CURRENT_REVISION, [selected_order], [])
	assert_true(SimulationResultProjector.validate(selected_order_result).ok)
	var bad_index := _segment(1, 0, 1000, null)
	assert_false(SimulationResultProjector.validate(SimulationResult.active_reaping(1000, 0, 1000, ContentRegistry.CURRENT_REVISION, [bad_index], [])).ok)
	var bad_elapsed := SimulationSegmentResult.new(0, &"THR_TEST", 1, &"FORM_TEST", &"WRIT_TEST", [], &"OVERDUE", 0, 1000, 999, 0, 0, 0, 0, 0, [])
	assert_false(SimulationResultProjector.validate(SimulationResult.active_reaping(1000, 0, 1000, ContentRegistry.CURRENT_REVISION, [bad_elapsed], [])).ok)
	var overlap := _segment(0, 0, 1000, null)
	var overlap_next := _segment(1, 999, 1001, null)
	assert_false(SimulationResultProjector.validate(SimulationResult.active_reaping(1001, 0, 1001, ContentRegistry.CURRENT_REVISION, [overlap, overlap_next], [])).ok)
	var unsupported_lifecycle := SimulationSegmentResult.new(0, &"THR_TEST", 1, &"FORM_TEST", &"WRIT_TEST", [], &"BROKEN", 0, 1000, 1000, 0, 0, 0, 0, 0, [])
	assert_false(SimulationResultProjector.validate(SimulationResult.active_reaping(1000, 0, 1000, ContentRegistry.CURRENT_REVISION, [unsupported_lifecycle], [])).ok)

func test_event_order_ownership_priority_and_signed_cursor_boundary() -> void:
	var channel_a := SimulationChannelDeltaResult.new(&"CHANNEL_A", &"SOUL_A", 1, 0, 0, 1000, 0, 0, 0, 1)
	var channel_b := SimulationChannelDeltaResult.new(&"CHANNEL_B", &"SOUL_B", 1, 0, 0, 1000, 0, 0, 0, 1)
	var channel_multi := SimulationChannelDeltaResult.new(&"CHANNEL_MULTI", &"SOUL_MULTI", 3, 0, 0, 1000, 0, 0, 0, 3)
	var segment := SimulationSegmentResult.new(0, &"THR_TEST", 1, &"FORM_TEST", &"WRIT_TEST", [], &"OVERDUE", 0, 1000, 1000, 0, 0, 0, 0, 0, [channel_a, channel_b])
	var bank_a := SimulationChannelBankedEvent.new(1000, 0, &"THR_TEST", &"CHANNEL_A", &"SOUL_A", 1, &"OVERDUE", 1, 0)
	var bank_b := SimulationChannelBankedEvent.new(1000, 0, &"THR_TEST", &"CHANNEL_B", &"SOUL_B", 1, &"OVERDUE", 1, 0)
	var settlement := SimulationThresholdSettledEvent.new(1000, 0, &"THR_TEST", 0, 1, 0, &"OVERDUE", &"SETTLED")
	var ordered: Array[SimulationEvent] = [bank_a, bank_b, settlement]
	var ordered_result := SimulationResult.active_reaping(1000, 0, 1000, ContentRegistry.CURRENT_REVISION, [segment], ordered)
	assert_true(SimulationResultProjector.validate(ordered_result, true).ok)
	var reversed: Array[SimulationEvent] = [bank_b, bank_a, settlement]
	assert_false(SimulationResultProjector.validate(SimulationResult.active_reaping(1000, 0, 1000, ContentRegistry.CURRENT_REVISION, [segment], reversed), true).ok)
	var early_bank := SimulationChannelBankedEvent.new(0, 0, &"THR_TEST", &"CHANNEL_A", &"SOUL_A", 1, &"OVERDUE", 1, 0)
	assert_false(SimulationResultProjector.validate(SimulationResult.active_reaping(1000, 0, 1000, ContentRegistry.CURRENT_REVISION, [segment], [early_bank, bank_b, settlement]), true).ok)
	var max_cursor := FixedPoint.INT64_MAX
	var edge_segment := SimulationSegmentResult.new(0, &"THR_TEST", 1, &"FORM_TEST", &"WRIT_TEST", [], &"OVERDUE", max_cursor - 1000, max_cursor, 1000, 0, 0, 0, 0, 0, [channel_a])
	var edge_event := SimulationChannelBankedEvent.new(max_cursor, 0, &"THR_TEST", &"CHANNEL_A", &"SOUL_A", 1, &"OVERDUE", 1, 0)
	assert_true(SimulationResultProjector.validate(SimulationResult.active_reaping(1000, max_cursor - 1000, max_cursor, ContentRegistry.CURRENT_REVISION, [edge_segment], [edge_event])).ok)
	var multi_segment := SimulationSegmentResult.new(0, &"THR_TEST", 1, &"FORM_TEST", &"WRIT_TEST", [], &"OVERDUE", 0, 1000, 1000, 0, 0, 0, 0, 0, [channel_multi])
	var multi_event := SimulationChannelBankedEvent.new(1000, 0, &"THR_TEST", &"CHANNEL_MULTI", &"SOUL_MULTI", 3, &"OVERDUE", 3, 0)
	assert_true(SimulationResultProjector.validate(SimulationResult.active_reaping(1000, 0, 1000, ContentRegistry.CURRENT_REVISION, [multi_segment], [multi_event])).ok)

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
	var invalid_context := SimulationRunContext.new(-1, 1234, false, &"", 0, &"", &"", [], &"", ContentRegistry.CURRENT_REVISION)
	assert_false(SimulationResultProjector.project(invalid_context, journal).ok)

func _segment(index: int, start: int, end: int, channel: SimulationChannelDeltaResult) -> SimulationSegmentResult:
	var channels: Array[SimulationChannelDeltaResult] = []
	if channel != null: channels.append(channel)
	return SimulationSegmentResult.new(index, &"THR_TEST", 1, &"FORM_TEST", &"WRIT_TEST", [], &"OVERDUE", start, end, end - start, 1, 0, 0, 0, 0, channels)

func _active_with_channel(channel: SimulationChannelDeltaResult) -> SimulationResult:
	var segment := _segment(0, 0, 1000, channel)
	return SimulationResult.active_reaping(1000, 0, 1000, ContentRegistry.CURRENT_REVISION, [segment], [])
