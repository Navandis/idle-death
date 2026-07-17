extends GutTest

func test_overdue_partial_boundary_settled_idle_and_continuation_round_trip_exactly() -> void:
	for scenario in ["overdue_partial", "boundary", "settled_continuation", "idle"]:
		var state := _scenario_state(scenario)
		var loaded := _round_trip(state)
		assert_true(loaded.ok)
		assert_eq(_snapshot(loaded.game_state), _snapshot(state))
		assert_false(loaded.game_state.has_meta("segments"))

func test_invalid_known_core_residuals_and_cycle_phase_reject_on_load() -> void:
	var cases := [
		[CoreReapingFlowContract.FLOW_CORE_RETURNS_PROGRESS_SUBUNITS, FixedPoint.SCALE],
		[CoreReapingFlowContract.FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS, FixedPoint.SCALE],
		[CoreReapingFlowContract.FLOW_CORE_RETURNS_RATE_CARRY_UNITS, 1000],
		[CoreReapingFlowContract.FLOW_CORE_ESSENCE_RATE_CARRY_UNITS, 10000],
		[CoreReapingFlowContract.FLOW_CORE_MASTERY_RATE_CARRY_UNITS, 60000],
	]
	for c in cases:
		var state := _scenario_state("overdue_partial")
		state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[c[0]] = c[1]
		assert_false(_round_trip(state).ok)
	var cycle := _scenario_state("overdue_partial")
	cycle.reapings[&"THR_GLOAMWOOD"].cycle_phase_msec = 60000
	assert_false(_round_trip(cycle).ok)

func test_schema_version_content_revision_and_migration_registry_remain_current() -> void:
	var registry := _registry()
	var snapshot := SaveSchemaMapper.runtime_to_snapshot(_scenario_state("idle"), TimeAuthorityState.new(), 7, registry.content_revision)
	assert_eq(snapshot.schema_version, SaveInt64.format(SaveEnvelope.CURRENT_SCHEMA_VERSION))
	assert_eq(snapshot.content_revision, ContentRegistry.CURRENT_REVISION)
	assert_eq(SaveEnvelope.CURRENT_SCHEMA_VERSION, 2)

func _scenario_state(scenario: String) -> GameState:
	var state := _base_state()
	match scenario:
		"overdue_partial":
			var r: GameState.ReapingState = state.reapings[&"THR_GLOAMWOOD"]
			r.flow_carry_units[CoreReapingFlowContract.FLOW_CORE_RETURNS_PROGRESS_SUBUNITS] = 123456
			r.flow_carry_units[CoreReapingFlowContract.FLOW_CORE_RETURNS_RATE_CARRY_UNITS] = 12
			r.flow_carry_units[CoreReapingFlowContract.FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS] = 654321
			r.flow_carry_units[CoreReapingFlowContract.FLOW_CORE_ESSENCE_RATE_CARRY_UNITS] = 34
			r.flow_carry_units[CoreReapingFlowContract.FLOW_CORE_MASTERY_RATE_CARRY_UNITS] = 56
			r.cycle_phase_msec = 1234
		"boundary":
			state.thresholds[&"THR_GLOAMWOOD"].remaining_backlog = 1
			assert_true(SimulationEngine.new(_registry()).resolve_elapsed_msec(state, 10000).success)
		"settled_continuation":
			state.thresholds[&"THR_GLOAMWOOD"].remaining_backlog = 0
			state.thresholds[&"THR_GLOAMWOOD"].lifecycle_state = &"SETTLED"
			assert_true(SimulationEngine.new(_registry()).resolve_elapsed_msec(state, 1000).success)
		"idle":
			state.reapings.clear()
			assert_true(SimulationEngine.new(_registry()).resolve_elapsed_msec(state, 1000).success)
	return state

func _base_state() -> GameState:
	var state := GameState.new(0)
	state.progression.command_tether_capacity = 1
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
	var threshold := GameState.ThresholdState.new()
	threshold.knowledge_state = &"CHARTED"; threshold.availability_state = &"AVAILABLE"; threshold.lifecycle_state = &"OVERDUE"; threshold.remaining_backlog = 1000000
	state.thresholds[&"THR_GLOAMWOOD"] = threshold
	var reaping := GameState.ReapingState.new()
	reaping.threshold_id = &"THR_GLOAMWOOD"; reaping.is_active = true; reaping.form_id = &"FORM_MAN_AT_ARMS"; reaping.writ_id = &"WRIT_STANDARD"; reaping.assignment_revision = 1
	state.reapings[&"THR_GLOAMWOOD"] = reaping
	return state

func _round_trip(state: GameState) -> Dictionary:
	var registry := _registry()
	var storage := MemorySaveStorage.new()
	var save_service := SaveService.new(storage, SaveFileSet.new("user://m04c_memory", "save"))
	var coordinator := GameStatePersistenceCoordinator.new(save_service, registry)
	var saved := coordinator.save_runtime(state, TimeAuthorityState.new(), 1)
	if not saved.ok: return saved
	return coordinator.load_runtime()

func _snapshot(state: GameState) -> Dictionary:
	return SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, _registry().content_revision).game_state

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
