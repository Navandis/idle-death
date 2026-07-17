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
	assert_eq(result.events[0].event_type, SimulationEngine.EVENT_THRESHOLD_SETTLED)
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
	assert_eq(result.change_summary.threshold_id, "THR_GLOAMWOOD")
	assert_eq(result.change_summary.simulation_time_delta_msec, 10000)
	assert_eq(result.change_summary.returned_souls_delta, 3)
	assert_eq(result.change_summary.backlog_delta, -1)
	assert_eq(result.change_summary.Essence_delta, 0)
	assert_eq(result.change_summary.Mastery_delta_subunits, 166666)
	assert_eq(result.change_summary.completed_cycles_delta, 0)
	assert_eq(result.change_summary.lifecycle_before, "OVERDUE")
	assert_eq(result.change_summary.lifecycle_after, "SETTLED")
	assert_eq(result.segments.size(), 2)
	assert_eq(result.segments[0].start_simulation_msec, 0)
	assert_eq(result.segments[0].end_simulation_msec, 870)
	assert_eq(result.segments[0].returned_souls_delta, 1)
	assert_eq(result.segments[1].start_simulation_msec, 870)
	assert_eq(result.segments[1].end_simulation_msec, 10000)
	assert_eq(result.events[0].priority, SimulationEngine.EVENT_PRIORITY_LIFECYCLE)
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
