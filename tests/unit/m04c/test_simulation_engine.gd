extends GutTest

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func _engine() -> SimulationEngine:
	return SimulationEngine.new(_registry())

func _state(backlog := 1000000, active := true) -> GameState:
	var state := GameState.new(0)
	state.progression.command_tether_capacity = 1
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
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
	reaping.assignment_revision = 1
	state.reapings[&"THR_GLOAMWOOD"] = reaping
	return state

func test_overdue_sixty_second_fixture() -> void:
	var state := _state()
	var result := _engine().resolve_elapsed(state, 60000)
	assert_true(result.success, result.developer_details)
	assert_eq(state.simulation_time_msec, 60000)
	assert_eq(state.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total, 69)
	assert_eq(state.thresholds[&"THR_GLOAMWOOD"].remaining_backlog, 999931)
	assert_eq(state.inventory.entries[&"RES_ESSENCE"].total, 6)
	assert_eq(state.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits, 1000000)
	assert_eq(state.reapings[&"THR_GLOAMWOOD"].completed_cycle_count, 1)
	assert_eq(state.reapings[&"THR_GLOAMWOOD"].cycle_phase_msec, 0)

func test_equivalent_chunks_match_one_shot() -> void:
	var one := _state()
	var chunks := _state()
	assert_true(_engine().resolve_elapsed(one, 60000).success)
	for elapsed in [10000, 7777, 22223, 20000]:
		assert_true(_engine().resolve_elapsed(chunks, elapsed).success)
	assert_eq(chunks.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total, one.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total)
	assert_eq(chunks.inventory.entries[&"RES_ESSENCE"].total, one.inventory.entries[&"RES_ESSENCE"].total)
	assert_eq(chunks.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits, one.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits)

func test_settlement_boundary_and_ten_second_fixture() -> void:
	var early := _state(1)
	assert_true(_engine().resolve_elapsed(early, 869).success)
	assert_eq(early.thresholds[&"THR_GLOAMWOOD"].remaining_backlog, 1)
	var state := _state(1)
	var result := _engine().resolve_elapsed(state, 10000)
	assert_true(result.success, result.developer_details)
	assert_eq(result.events.size(), 1)
	assert_eq(result.events[0].event_type, SimulationEvent.EVENT_THRESHOLD_SETTLED)
	assert_eq(result.events[0].occurred_simulation_msec, 870)
	assert_eq(state.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total, 3)
	assert_eq(state.thresholds[&"THR_GLOAMWOOD"].remaining_backlog, 0)
	assert_eq(str(state.thresholds[&"THR_GLOAMWOOD"].lifecycle_state), "SETTLED")
	assert_eq(state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[SimulationEngine.FLOW_CORE_RETURNS_PROGRESS_SUBUNITS], 625375)
	assert_eq(state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[SimulationEngine.FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS], 315250)
	assert_eq(state.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits, 166666)
	assert_eq(state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[SimulationEngine.FLOW_CORE_MASTERY_RATE_CARRY_UNITS], 40000)
	assert_eq(state.reapings[&"THR_GLOAMWOOD"].cycle_phase_msec, 10000)

func test_failures_do_not_mutate_and_idle_advances_timeline() -> void:
	var idle := GameState.new(0)
	idle.progression.command_tether_capacity = 1
	assert_true(_engine().resolve_elapsed(idle, 5000).success)
	assert_eq(idle.simulation_time_msec, 5000)
	var state := _state()
	state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[&"UNKNOWN"] = 1
	var before := state.deep_clone()
	var result := _engine().resolve_elapsed(state, 1000)
	assert_false(result.success)
	assert_eq(result.error_code, SimulationEngine.ERR_UNSUPPORTED_FLOW)
	assert_eq(state.simulation_time_msec, before.simulation_time_msec)
	assert_eq(state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[&"UNKNOWN"], 1)

func test_inactive_produces_nothing_and_settled_continues_without_repeat_event() -> void:
	var inactive := _state(100, false)
	assert_true(_engine().resolve_elapsed(inactive, 60000).success)
	assert_eq(inactive.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total, 0)
	var settled := _state(0)
	var result := _engine().resolve_elapsed(settled, 60000)
	assert_true(result.success, result.developer_details)
	assert_eq(result.events.size(), 0)
	assert_eq(settled.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total, 17)
	assert_eq(settled.inventory.entries[&"RES_ESSENCE"].total, 1)
	assert_eq(settled.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits, 1000000)

func test_supported_always_and_essence_yield_trait_multipliers_apply() -> void:
	var engine := _engine()
	var threshold: Dictionary = _registry().get_record("THR_GLOAMWOOD").record
	var always_traits := [{"modifiers": [{"metric": "SOULS_RETURNED_RATE", "operation": "MULTIPLY", "scope": "REAPING_TOTAL", "condition": "ALWAYS", "condition_values": [], "value_subunits": 1500000}]}]
	var returned := engine._scaled_rate({"rate_subunits_per_period": 1000000, "period_msec": 1000}, always_traits, threshold, "SOULS_RETURNED_RATE", false)
	assert_true(returned.ok, str(returned))
	assert_eq(returned.rate, 1500000)
	var mastery_traits := [{"modifiers": [{"metric": "MASTERY_RATE", "operation": "MULTIPLY", "scope": "REAPING_TOTAL", "condition": "ALWAYS", "condition_values": [], "value_subunits": 1250000}]}]
	var mastery := engine._scaled_rate({"rate_subunits_per_period": 1000000, "period_msec": 60000}, mastery_traits, threshold, "MASTERY_RATE", false)
	assert_true(mastery.ok, str(mastery))
	assert_eq(mastery.rate, 1250000)
	var essence_traits := [{"modifiers": [{"metric": "ESSENCE_YIELD", "operation": "MULTIPLY", "scope": "REAPING_TOTAL", "condition": "ALWAYS", "condition_values": [], "value_subunits": 2000000}]}]
	var essence := engine._essence_rate(&"THR_GLOAMWOOD", false, essence_traits, threshold)
	assert_true(essence.ok, str(essence))
	assert_eq(essence.rate, 2000000)

func test_result_segments_summary_and_source_ownership_contract() -> void:
	var state := _state(1)
	var result := _engine().resolve_elapsed(state, 10000)
	assert_true(result.success, result.developer_details)
	assert_eq(result.segments.size(), 2)
	assert_eq(result.result_kind, SimulationResult.KIND_ACTIVE_REAPING)
	assert_eq(result.baseline_simulation_time_msec, 0)
	assert_eq(result.result_simulation_time_msec, 10000)
	assert_eq(result.segments[0].threshold_id, &"THR_GLOAMWOOD")
	assert_eq(result.segments[0].assignment_revision, 1)
	assert_eq(result.segments[0].form_id, &"FORM_MAN_AT_ARMS")
	assert_eq(result.segments[0].writ_id, &"WRIT_STANDARD")
	assert_eq(result.segments[0].returned_souls_delta + result.segments[1].returned_souls_delta, 3)
	assert_eq(result.segments[0].backlog_reduced + result.segments[1].backlog_reduced, 1)
	assert_eq(result.segments[0].essence_delta + result.segments[1].essence_delta, 0)
	assert_eq(result.segments[0].mastery_delta_subunits + result.segments[1].mastery_delta_subunits, 166666)
	assert_eq(result.segments[0].completed_cycles_delta + result.segments[1].completed_cycles_delta, 0)
	assert_eq(result.segments[0].start_simulation_msec, 0)
	assert_eq(result.segments[0].end_simulation_msec, 870)
	assert_eq(result.segments[0].returned_souls_delta, 1)
	assert_eq(result.segments[1].start_simulation_msec, 870)
	assert_eq(result.segments[1].end_simulation_msec, 10000)
	assert_eq(result.events[0].priority, SimulationEvent.EVENT_PRIORITY_LIFECYCLE)
	assert_eq(result.events[0].source_id, &"SIMULATION_ENGINE")
	assert_true(result.events[0].reportable)
	assert_true(result.events[0].tutorial_relevant)
	var source := FileAccess.get_file_as_string("res://src/simulation/simulation_engine.gd") + FileAccess.get_file_as_string("res://src/debug/m04c_debug_advance.gd")
	for needle in ["Time.get", "OS.get_datetime", "get_ticks", "extends Node", "Steam", "Forecast", "Report"]:
		assert_eq(source.find(needle), -1, "forbidden ownership token: %s" % needle)

func test_debug_adapter_matches_direct_engine() -> void:
	var registry := _registry()
	var direct := _state()
	var debug := _state()
	var direct_result := SimulationEngine.new(registry).resolve_elapsed(direct, 60000)
	var debug_result := M04CDebugAdvance.new(registry).advance_msec(debug, 60000)
	assert_true(direct_result.success)
	assert_true(debug_result.success)
	assert_eq(_canonical_state_for_unit(debug), _canonical_state_for_unit(direct))

func _canonical_state_for_unit(state: GameState) -> Dictionary:
	return SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION).game_state

func test_duration_configuration_and_failure_results_preserve_state() -> void:
	var negative := _engine().resolve_elapsed(_state(), -1)
	_assert_failure_result(negative, SimulationEngine.ERR_NEGATIVE_ELAPSED, -1, null)
	var zero := _state()
	var zero_before := _canonical_state_for_unit(zero)
	var zero_result := _engine().resolve_elapsed(zero, 0)
	assert_true(zero_result.success)
	assert_eq(zero_result.committed_elapsed_msec, 0)
	assert_eq(_canonical_state_for_unit(zero), zero_before)
	var invalid_registry_engine := SimulationEngine.new(ContentRegistry.new())
	var invalid_state := _state()
	var invalid_before := _canonical_state_for_unit(invalid_state)
	_assert_failure_result(invalid_registry_engine.resolve_elapsed(invalid_state, 1000), SimulationEngine.ERR_STATE_INVALID, 1000, invalid_before, invalid_state)
	_assert_failure_result(_engine().resolve_elapsed(null, 1000), SimulationEngine.ERR_STATE_INVALID, 1000, null)
	var two_active := _state(1000, true)
	two_active.progression.command_tether_capacity = 2
	two_active.forms[&"FORM_SCRIBE"] = GameState.FormState.new(true, true, 0, &"TEST")
	var watch := GameState.ThresholdState.new(); watch.knowledge_state = &"CHARTED"; watch.availability_state = &"AVAILABLE"; watch.lifecycle_state = &"OVERDUE"; watch.remaining_backlog = 1000; watch.channel_acquisition[&"CHANNEL_BROKEN_WATCH_PROVISIONS"] = GameState.ThresholdAcquisitionState.new(); two_active.thresholds[&"THR_BROKEN_WATCH"] = watch
	var second := GameState.ReapingState.new(); second.threshold_id = &"THR_BROKEN_WATCH"; second.is_active = true; second.form_id = &"FORM_SCRIBE"; second.writ_id = &"WRIT_STANDARD"; second.assignment_revision = 1; two_active.reapings[&"THR_BROKEN_WATCH"] = second
	_assert_failure_result(_engine().resolve_elapsed(two_active, 1000), SimulationEngine.ERR_UNSUPPORTED_CONCURRENCY, 1000, _canonical_state_for_unit(two_active), two_active)
	var retinue := _state(); retinue.reapings[&"THR_GLOAMWOOD"].retinue_ids.append(&"RET_SOLDIER_COMPANY")
	_assert_failure_result(_engine().resolve_elapsed(retinue, 1000), SimulationEngine.ERR_UNSUPPORTED_RETINUE, 1000, _canonical_state_for_unit(retinue), retinue)
	var unknown_zero := _state(); unknown_zero.reapings[&"THR_GLOAMWOOD"].flow_carry_units[&"UNKNOWN_COMPAT"] = 0
	assert_true(_engine().resolve_elapsed(unknown_zero, 1000).success)
	assert_eq(unknown_zero.reapings[&"THR_GLOAMWOOD"].flow_carry_units[&"UNKNOWN_COMPAT"], 0)

func test_no_active_and_inactive_summaries_are_timeline_only() -> void:
	var idle := GameState.new(25); idle.progression.command_tether_capacity = 1
	var idle_result := _engine().resolve_elapsed(idle, 75)
	assert_true(idle_result.success)
	assert_eq(idle_result.result_kind, SimulationResult.KIND_TIMELINE_ONLY)
	assert_eq(idle_result.committed_elapsed_msec, 75)
	assert_eq(idle_result.result_simulation_time_msec - idle_result.baseline_simulation_time_msec, 75)
	assert_eq(idle.reapings.size(), 0)
	var inactive := _state(100, false)
	var before := _canonical_state_for_unit(inactive)
	var result := _engine().resolve_elapsed(inactive, 1000)
	assert_true(result.success)
	assert_eq(result.committed_elapsed_msec, 1000)
	var after := _canonical_state_for_unit(inactive)
	assert_eq(after.reapings, before.reapings)
	assert_eq(after.thresholds, before.thresholds)
	assert_eq(after.forms, before.forms)
	assert_eq(after.inventory, before.inventory)
	assert_eq(after.simulation_time_msec, "1000")

func test_core_rate_plan_modifier_matrix() -> void:
	var engine := _engine()
	var registry := _registry()
	var gloamwood: Dictionary = registry.get_record("THR_GLOAMWOOD").record
	var watch: Dictionary = registry.get_record("THR_BROKEN_WATCH").record
	var maa: Dictionary = registry.get_record("FORM_MAN_AT_ARMS").record
	var scribe: Dictionary = registry.get_record("FORM_SCRIBE").record
	assert_eq(engine._scaled_rate(maa.base_returned_souls_rate, maa.traits, gloamwood, "SOULS_RETURNED_RATE", false).rate, 1150000)
	assert_eq(engine._scaled_rate(maa.base_returned_souls_rate, maa.traits, {"tags": []}, "SOULS_RETURNED_RATE", false).rate, 1000000)
	assert_true(engine._scaled_rate(scribe.base_returned_souls_rate, scribe.traits, gloamwood, "SOULS_RETURNED_RATE", false).ok)
	var two_floor := [{"modifiers": [_modifier("SOULS_RETURNED_RATE", "MULTIPLY", "REAPING_TOTAL", "ALWAYS", 1333333), _modifier("SOULS_RETURNED_RATE", "MULTIPLY", "REAPING_TOTAL", "ALWAYS", 1333333)]}]
	assert_eq(engine._scaled_rate({"rate_subunits_per_period": 1000000, "period_msec": 1000}, two_floor, gloamwood, "SOULS_RETURNED_RATE", false).rate, 1777776)
	var essence_tag := [{"modifiers": [_modifier("ESSENCE_YIELD", "MULTIPLY", "REAPING_TOTAL", "THRESHOLD_HAS_ANY_TAG", 1500000, ["TAG_SETTLEMENT"])]}]
	assert_eq(engine._essence_rate(&"THR_GLOAMWOOD", false, essence_tag, gloamwood).rate, 1500000)
	var mastery_tag := [{"modifiers": [_modifier("MASTERY_RATE", "MULTIPLY", "REAPING_TOTAL", "THRESHOLD_HAS_ANY_TAG", 1500000, ["TAG_MARTIAL"])]}]
	assert_eq(engine._scaled_rate({"rate_subunits_per_period": 1000000, "period_msec": 1000}, mastery_tag, watch, "MASTERY_RATE", false).rate, 1500000)
	assert_eq(engine._scaled_rate({"rate_subunits_per_period": 1000000, "period_msec": 1000}, [{"modifiers": [_modifier("DISCOVERY_RATE", "MULTIPLY", "REAPING_TOTAL", "ALWAYS", 9000000), _modifier("FORECAST_UNCERTAINTY", "MULTIPLY", "REAPING_TOTAL", "ALWAYS", 9000000)]}], gloamwood, "SOULS_RETURNED_RATE", false).rate, 1000000)
	for bad in [_modifier("SOULS_RETURNED_RATE", "ADD", "REAPING_TOTAL", "ALWAYS", 1000000), _modifier("SOULS_RETURNED_RATE", "MULTIPLY", "OUTPUT_CHANNEL", "ALWAYS", 1000000), _modifier("SOULS_RETURNED_RATE", "MULTIPLY", "REAPING_TOTAL", "OUTPUT_ITEM", 1000000), _modifier("SOULS_RETURNED_RATE", "MULTIPLY", "REAPING_TOTAL", "ALWAYS", -1)]:
		assert_false(engine._scaled_rate({"rate_subunits_per_period": 1000000, "period_msec": 1000}, [{"modifiers": [bad]}], gloamwood, "SOULS_RETURNED_RATE", false).ok)

func test_essence_channel_validation_matrix() -> void:
	var engine := _engine()
	var threshold: Dictionary = _registry().get_record("THR_GLOAMWOOD").record
	var no_match := threshold.duplicate(true); no_match.channel_ids = []
	assert_false(engine._essence_rate(&"THR_GLOAMWOOD", false, [], no_match).ok)
	var wrong_owner := threshold.duplicate(true); wrong_owner.channel_ids = ["CHANNEL_BROKEN_WATCH_ESSENCE"]
	assert_false(engine._essence_rate(&"THR_GLOAMWOOD", false, [], wrong_owner).ok)
	var malformed := threshold.duplicate(true); malformed.channel_ids = ["CHANNEL_GLOAMWOOD_ESSENCE", "CHANNEL_GLOAMWOOD_ESSENCE"]
	assert_false(engine._essence_rate(&"THR_GLOAMWOOD", false, [], malformed).ok)

func test_settlement_chunking_residual_and_settled_exact_matrix() -> void:
	var one := _state(1); var chunks := _state(1)
	assert_true(_engine().resolve_elapsed(one, 10000).success)
	for elapsed in [869, 1, 9130]: assert_true(_engine().resolve_elapsed(chunks, elapsed).success)
	assert_eq(_canonical_state_for_unit(chunks), _canonical_state_for_unit(one))
	var irregular_one := _state(); var irregular_chunks := _state()
	assert_true(_engine().resolve_elapsed(irregular_one, 123456).success)
	for elapsed in [1, 999, 57000, 65456]: assert_true(_engine().resolve_elapsed(irregular_chunks, elapsed).success)
	assert_eq(_canonical_state_for_unit(irregular_chunks), _canonical_state_for_unit(irregular_one))
	var large := _state(1000)
	assert_true(_engine().resolve_elapsed(large, 870000).success)
	assert_eq(str(large.thresholds[&"THR_GLOAMWOOD"].lifecycle_state), "SETTLED")
	var residual := _state(); residual.reapings[&"THR_GLOAMWOOD"].flow_carry_units[SimulationEngine.FLOW_CORE_RETURNS_PROGRESS_SUBUNITS] = 999000; residual.reapings[&"THR_GLOAMWOOD"].flow_carry_units[SimulationEngine.FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS] = 900000
	assert_true(_engine().resolve_elapsed(residual, 1000).success)
	assert_eq(residual.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total, 2)
	assert_eq(residual.inventory.entries[&"RES_ESSENCE"].total, 1)
	var settled := _state(0)
	assert_true(_engine().resolve_elapsed(settled, 60000).success)
	assert_eq(settled.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total, 17)
	assert_eq(settled.reapings[&"THR_GLOAMWOOD"].flow_carry_units[SimulationEngine.FLOW_CORE_RETURNS_PROGRESS_SUBUNITS], 250000)

func test_overflow_and_fixed_point_failure_matrix_preserves_state() -> void:
	assert_eq(FixedPoint.multiply_scaled_floor(1500000, 1500000).subunits, 2250000)
	assert_eq(FixedPoint.multiply_scaled_floor(1000001, 1000001).subunits, 1000002)
	assert_false(FixedPoint.multiply_scaled_floor(-1, 1000000).ok)
	assert_false(FixedPoint.multiply_scaled_floor(FixedPoint.INT64_MAX, 2).ok)
	var time_overflow := _state(); time_overflow.simulation_time_msec = FixedPoint.INT64_MAX
	_assert_failure_result(_engine().resolve_elapsed(time_overflow, 1), SimulationEngine.ERR_OVERFLOW, 1, _canonical_state_for_unit(time_overflow), time_overflow)
	var returns_overflow := _state(); returns_overflow.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total = FixedPoint.INT64_MAX
	_assert_failure_result(_engine().resolve_elapsed(returns_overflow, 1000), SimulationEngine.ERR_OVERFLOW, 1000, _canonical_state_for_unit(returns_overflow), returns_overflow)
	var essence_overflow := _state(); essence_overflow.inventory.entries[&"RES_ESSENCE"] = GameState.InventoryEntryState.new(FixedPoint.INT64_MAX)
	_assert_failure_result(_engine().resolve_elapsed(essence_overflow, 10000), SimulationEngine.ERR_OVERFLOW, 10000, _canonical_state_for_unit(essence_overflow), essence_overflow)
	var mastery_overflow := _state(); mastery_overflow.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits = FixedPoint.INT64_MAX
	_assert_failure_result(_engine().resolve_elapsed(mastery_overflow, 60000), SimulationEngine.ERR_OVERFLOW, 60000, _canonical_state_for_unit(mastery_overflow), mastery_overflow)
	var cycle_overflow := _state(); cycle_overflow.reapings[&"THR_GLOAMWOOD"].cycle_phase_msec = 59999
	_assert_failure_result(_engine().resolve_elapsed(cycle_overflow, FixedPoint.INT64_MAX), SimulationEngine.ERR_OVERFLOW, FixedPoint.INT64_MAX, _canonical_state_for_unit(cycle_overflow), cycle_overflow)
	var progress_overflow := _state(); progress_overflow.reapings[&"THR_GLOAMWOOD"].flow_carry_units[SimulationEngine.FLOW_CORE_RETURNS_PROGRESS_SUBUNITS] = FixedPoint.SCALE - 1
	_assert_failure_result(_engine().resolve_elapsed(progress_overflow, FixedPoint.INT64_MAX), SimulationEngine.ERR_OVERFLOW, FixedPoint.INT64_MAX, _canonical_state_for_unit(progress_overflow), progress_overflow)
	var multiplier := [{"modifiers": [_modifier("SOULS_RETURNED_RATE", "MULTIPLY", "REAPING_TOTAL", "ALWAYS", FixedPoint.INT64_MAX)]}]
	var failed := _engine()._scaled_rate({"rate_subunits_per_period": FixedPoint.INT64_MAX, "period_msec": 1000}, multiplier, _registry().get_record("THR_GLOAMWOOD").record, "SOULS_RETURNED_RATE", false)
	assert_false(failed.ok)
	assert_eq(failed.code, SimulationEngine.ERR_OVERFLOW)

func _assert_failure_result(result, expected_code: StringName, requested: int, before = null, state = null) -> void:
	assert_false(result.success)
	assert_eq(result.error_code, expected_code)
	assert_eq(result.requested_elapsed_msec, requested)
	assert_eq(result.committed_elapsed_msec, 0)
	assert_true(result.segments.is_empty())
	assert_true(result.events.is_empty())
	if before != null and state != null:
		assert_eq(_canonical_state_for_unit(state), before)

func _modifier(metric: String, operation: String, scope: String, condition: String, value_subunits: int, condition_values: Array = []) -> Dictionary:
	return {"metric": metric, "operation": operation, "scope": scope, "condition": condition, "condition_values": condition_values, "value_subunits": value_subunits}
