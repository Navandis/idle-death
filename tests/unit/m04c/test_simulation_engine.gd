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
