extends GutTest

func _state() -> GameState:
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
	reaping.threshold_id = &"THR_GLOAMWOOD"
	reaping.is_active = true
	reaping.form_id = &"FORM_MAN_AT_ARMS"
	reaping.writ_id = &"WRIT_STANDARD"
	reaping.assignment_revision = 1
	state.reapings[&"THR_GLOAMWOOD"] = reaping
	return state

func test_schema_v2_round_trips_core_residuals_after_settlement() -> void:
	var registry := ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
	var state := _state()
	var result := SimulationEngine.new(registry).resolve_elapsed(state, 10000)
	assert_true(result.success, result.developer_details)
	var snapshot := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 7, registry.content_revision)
	var mapped := SaveSchemaMapper.snapshot_to_runtime(snapshot)
	assert_true(mapped.ok, str(mapped))
	var round: GameState = mapped.game_state
	assert_eq(round.simulation_time_msec, 10000)
	assert_eq(round.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total, 3)
	assert_eq(round.thresholds[&"THR_GLOAMWOOD"].remaining_backlog, 0)
	assert_eq(str(round.thresholds[&"THR_GLOAMWOOD"].lifecycle_state), "SETTLED")
	assert_eq(round.reapings[&"THR_GLOAMWOOD"].flow_carry_units[SimulationEngine.FLOW_CORE_RETURNS_PROGRESS_SUBUNITS], 625375)
	assert_eq(round.reapings[&"THR_GLOAMWOOD"].flow_carry_units[SimulationEngine.FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS], 315250)
	assert_eq(round.reapings[&"THR_GLOAMWOOD"].flow_carry_units[SimulationEngine.FLOW_CORE_MASTERY_RATE_CARRY_UNITS], 40000)
