extends GutTest

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func _state(backlog := 1000000, active := true) -> GameState:
	var state := GameState.new(0)
	state.progression.command_tether_capacity = 1
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
	var threshold := GameState.ThresholdState.new()
	threshold.knowledge_state = &"CHARTED"
	threshold.availability_state = &"AVAILABLE"
	threshold.lifecycle_state = &"OVERDUE" if backlog > 0 else &"SETTLED"
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

func _engine() -> SimulationEngine:
	return SimulationEngine.new(_registry())

func test_overdue_sixty_second_fixture() -> void:
	var state := _state()
	var result := _engine().resolve_elapsed_msec(state, 60000)
	assert_true(result.success)
	assert_eq(state.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total, 69)
	assert_eq(state.inventory.entries[&"RES_ESSENCE"].total, 6)
	assert_eq(state.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits, 1000000)
	assert_eq(state.reapings[&"THR_GLOAMWOOD"].completed_cycle_count, 1)
	assert_eq(state.reapings[&"THR_GLOAMWOOD"].cycle_phase_msec, 0)

func test_equivalent_chunks_match_one_shot() -> void:
	var one := _state()
	var chunked := _state()
	assert_true(_engine().resolve_elapsed_msec(one, 10000).success)
	for elapsed in [869, 1, 9130]:
		assert_true(_engine().resolve_elapsed_msec(chunked, elapsed).success)
	assert_eq(_snapshot(one), _snapshot(chunked))

func test_settlement_boundary_and_ten_second_fixture() -> void:
	var state := _state(1)
	assert_true(_engine().resolve_elapsed_msec(state, 869).success)
	assert_eq(state.thresholds[&"THR_GLOAMWOOD"].remaining_backlog, 1)
	assert_eq(state.thresholds[&"THR_GLOAMWOOD"].lifecycle_state, &"OVERDUE")
	state = _state(1)
	var result := _engine().resolve_elapsed_msec(state, 10000)
	assert_true(result.success)
	assert_eq(result.events.size(), 1)
	assert_eq(result.events[0].occurred_simulation_msec, 870)
	assert_eq(state.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total, 3)
	assert_eq(state.thresholds[&"THR_GLOAMWOOD"].remaining_backlog, 0)
	assert_eq(state.thresholds[&"THR_GLOAMWOOD"].lifecycle_state, &"SETTLED")
	var reaping: GameState.ReapingState = state.reapings[&"THR_GLOAMWOOD"]
	assert_eq(reaping.flow_carry_units[SimulationEngine.FLOW_CORE_RETURNS_PROGRESS_SUBUNITS], 625375)
	assert_eq(reaping.flow_carry_units[SimulationEngine.FLOW_CORE_RETURNS_RATE_CARRY_UNITS], 0)
	assert_eq(state.inventory.entries.has(&"RES_ESSENCE"), false)
	assert_eq(reaping.flow_carry_units[SimulationEngine.FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS], 315250)
	assert_eq(reaping.flow_carry_units[SimulationEngine.FLOW_CORE_ESSENCE_RATE_CARRY_UNITS], 0)
	assert_eq(state.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits, 166666)
	assert_eq(reaping.flow_carry_units[SimulationEngine.FLOW_CORE_MASTERY_RATE_CARRY_UNITS], 40000)
	assert_eq(reaping.cycle_phase_msec, 10000)

func test_idle_inactive_and_failure_no_mutation() -> void:
	var idle := GameState.new(5)
	idle.progression.command_tether_capacity = 1
	var idle_result := _engine().resolve_elapsed_msec(idle, 10)
	assert_true(idle_result.success)
	assert_eq(idle.simulation_time_msec, 15)
	var inactive := _state(1000, false)
	var snap := _snapshot(inactive)
	assert_true(_engine().resolve_elapsed_msec(inactive, 1000).success)
	assert_eq(inactive.simulation_time_msec, 1000)
	assert_eq(inactive.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total, 0)
	var invalid := _state()
	invalid.reapings[&"THR_GLOAMWOOD"].flow_carry_units[&"FLOW_UNKNOWN"] = 1
	var before := _snapshot(invalid)
	var failed := _engine().resolve_elapsed_msec(invalid, 1000)
	assert_false(failed.success)
	assert_eq(failed.error_code, SimulationEngine.ERR_UNSUPPORTED_FLOW)
	assert_eq(_snapshot(invalid), before)

func test_concurrency_retinue_negative_and_settled_once_reject_or_continue() -> void:
	var concurrent := _state()
	concurrent.progression.command_tether_capacity = 2
	concurrent.forms[&"FORM_SCRIBE"] = GameState.FormState.new(true, true, 0, &"TEST")
	var watch: GameState.ThresholdState = concurrent.thresholds[&"THR_GLOAMWOOD"].deep_clone()
	watch.remaining_backlog = 1000
	concurrent.thresholds[&"THR_BROKEN_WATCH"] = watch
	var r: GameState.ReapingState = concurrent.reapings[&"THR_GLOAMWOOD"].deep_clone()
	r.threshold_id = &"THR_BROKEN_WATCH"; r.form_id = &"FORM_SCRIBE"
	concurrent.reapings[&"THR_BROKEN_WATCH"] = r
	var before := _snapshot(concurrent)
	assert_eq(_engine().resolve_elapsed_msec(concurrent, 1).error_code, SimulationEngine.ERR_UNSUPPORTED_CONCURRENCY)
	assert_eq(_snapshot(concurrent), before)
	var retinue := _state(); retinue.reapings[&"THR_GLOAMWOOD"].retinue_ids.append(&"RET_SOLDIER_COMPANY")
	assert_eq(_engine().resolve_elapsed_msec(retinue, 1).error_code, SimulationEngine.ERR_UNSUPPORTED_RETINUE)
	assert_eq(_engine().resolve_elapsed_msec(_state(), -1).error_code, SimulationEngine.ERR_NEGATIVE_ELAPSED)
	var settled := _state(0)
	var result := _engine().resolve_elapsed_msec(settled, 1000)
	assert_true(result.success)
	assert_eq(result.events.size(), 0)
	assert_eq(settled.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total, 0)
	assert_eq(settled.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits, 16666)

func _snapshot(state: GameState) -> Dictionary:
	return SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, _registry().content_revision).game_state
