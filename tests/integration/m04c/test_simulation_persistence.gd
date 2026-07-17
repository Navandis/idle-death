extends GutTest

func test_boundary_crossing_state_round_trips_schema_v2() -> void:
	var registry := ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
	var state := GameState.new(0)
	state.progression.command_tether_capacity = 1
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
	var threshold := GameState.ThresholdState.new()
	threshold.knowledge_state = &"CHARTED"
	threshold.availability_state = &"AVAILABLE"
	threshold.lifecycle_state = &"OVERDUE"
	threshold.remaining_backlog = 1
	state.thresholds[&"THR_GLOAMWOOD"] = threshold
	var reaping := GameState.ReapingState.new()
	reaping.threshold_id = &"THR_GLOAMWOOD"; reaping.is_active = true; reaping.form_id = &"FORM_MAN_AT_ARMS"; reaping.writ_id = &"WRIT_STANDARD"; reaping.assignment_revision = 1
	state.reapings[&"THR_GLOAMWOOD"] = reaping
	assert_true(SimulationEngine.new(registry).resolve_elapsed_msec(state, 10000).success)
	var storage := MemorySaveStorage.new()
	var save_service := SaveService.new(storage, SaveFileSet.new("user://m04c_memory", "save"))
	var coordinator := GameStatePersistenceCoordinator.new(save_service, registry)
	assert_true(coordinator.save_runtime(state, TimeAuthorityState.new(), 1).ok)
	var loaded := coordinator.load_runtime()
	assert_true(loaded.ok)
	var loaded_reaping: GameState.ReapingState = loaded.game_state.reapings[&"THR_GLOAMWOOD"]
	assert_eq(loaded.game_state.thresholds[&"THR_GLOAMWOOD"].lifecycle_state, &"SETTLED")
	assert_eq(loaded_reaping.flow_carry_units[SimulationEngine.FLOW_CORE_RETURNS_PROGRESS_SUBUNITS], 625375)
	assert_eq(loaded_reaping.flow_carry_units[SimulationEngine.FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS], 315250)
	assert_eq(loaded_reaping.flow_carry_units[SimulationEngine.FLOW_CORE_MASTERY_RATE_CARRY_UNITS], 40000)
