extends GutTest

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func _state() -> GameState:
	var state := GameState.new(2000)
	state.progression.command_tether_capacity = 1
	state.progression.unlocked_output_item_ids = [&"SOUL_CALLING_SOLDIER"]
	state.progression.unlocked_output_item_ids = [&"SOUL_CALLING_SOLDIER"]
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
	var threshold := GameState.ThresholdState.new()
	threshold.knowledge_state = &"CHARTED"
	threshold.availability_state = &"AVAILABLE"
	threshold.lifecycle_state = &"OVERDUE"
	threshold.remaining_backlog = 1000
	threshold.channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"] = GameState.ThresholdAcquisitionState.new(500000, 20, 3)
	state.thresholds[&"THR_GLOAMWOOD"] = threshold
	return state

func test_active_and_inactive_assignments_round_trip_through_schema_v2() -> void:
	var registry := _registry()
	var service := ReapingAssignmentService.new(registry)
	var storage := MemorySaveStorage.new()
	var save_service := SaveService.new(storage, SaveFileSet.new("user://m04b_memory", "save"))
	var coordinator := GameStatePersistenceCoordinator.new(save_service, registry)
	var state := _state()
	assert_true(service.dispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD").success)
	state.reapings[&"THR_GLOAMWOOD"].cycle_phase_msec = 9
	state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[&"FLOW_TEST"] = 4
	var time_state := TimeAuthorityState.new()
	assert_true(coordinator.save_runtime(state, time_state, 1).ok)
	var loaded_active := coordinator.load_runtime()
	assert_true(loaded_active.ok)
	_assert_reaping_equal(state.reapings[&"THR_GLOAMWOOD"], loaded_active.game_state.reapings[&"THR_GLOAMWOOD"])
	assert_true(service.recall(state, &"THR_GLOAMWOOD", 1).success)
	assert_true(coordinator.save_runtime(state, time_state, 2).ok)
	var loaded_inactive := coordinator.load_runtime()
	assert_true(loaded_inactive.ok)
	_assert_reaping_equal(state.reapings[&"THR_GLOAMWOOD"], loaded_inactive.game_state.reapings[&"THR_GLOAMWOOD"])
	assert_eq(loaded_inactive.game_state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].progress_subunits, 500000)

func _assert_reaping_equal(expected: GameState.ReapingState, actual: GameState.ReapingState) -> void:
	assert_eq(actual.threshold_id, expected.threshold_id)
	assert_eq(actual.is_active, expected.is_active)
	assert_eq(actual.form_id, expected.form_id)
	assert_eq(actual.writ_id, expected.writ_id)
	assert_eq(actual.assignment_revision, expected.assignment_revision)
	assert_eq(actual.cycle_phase_msec, expected.cycle_phase_msec)
	assert_eq(actual.flow_carry_units, expected.flow_carry_units)
	assert_eq(actual.started_simulation_msec, expected.started_simulation_msec)
	assert_eq(actual.last_configuration_change_simulation_msec, expected.last_configuration_change_simulation_msec)

func test_load_runtime_rejects_schema_valid_malformed_assignment_records() -> void:
	_assert_malformed_load_rejected(func(snapshot): snapshot.game_state.reapings.THR_GLOAMWOOD.assignment_revision = "0", "revision_zero")
	_assert_malformed_load_rejected(func(snapshot):
		snapshot.game_state.forms["FORM_SCRIBE"] = {"revealed": true, "awakened": true, "mastery_subunits": "0", "awakened_by": "TEST"}
		snapshot.game_state.thresholds["THR_BROKEN_WATCH"] = _threshold_snapshot(1000)
		snapshot.game_state.reapings["THR_BROKEN_WATCH"] = snapshot.game_state.reapings.THR_GLOAMWOOD.duplicate(true)
		snapshot.game_state.reapings.THR_BROKEN_WATCH.threshold_id = "THR_BROKEN_WATCH"
		snapshot.game_state.progression.command_tether_capacity = "2"
	, "duplicate_active_form")
	_assert_malformed_load_rejected(func(snapshot): snapshot.game_state.thresholds.THR_GLOAMWOOD.availability_state = "LOCKED", "unavailable_active_threshold")
	_assert_malformed_load_rejected(func(snapshot): snapshot.game_state.reapings.THR_GLOAMWOOD.writ_id = "WRIT_DISABLED_FOR_TEST", "invalid_active_writ")

func _assert_malformed_load_rejected(mutator: Callable, _label: String) -> void:
	var registry := _registry()
	var state := _state()
	var service := ReapingAssignmentService.new(registry)
	assert_true(service.dispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD").success)
	var snapshot := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, registry.content_revision)
	mutator.call(snapshot)
	var storage := MemorySaveStorage.new()
	var files := SaveFileSet.new("user://m04b_malformed_%s" % _label, "save")
	var save_service := SaveService.new(storage, files)
	var encoded := JsonSaveCodec.new().encode(snapshot)
	assert_true(encoded.ok)
	assert_true(storage.write_bytes(files.primary_path, encoded.bytes).ok)
	var loaded := GameStatePersistenceCoordinator.new(save_service, registry).load_runtime()
	assert_false(loaded.ok)
	assert_true([GameStateValidator.ERR_RANGE, GameStateValidator.ERR_CROSS_FIELD, GameStateValidator.ERR_CONTENT].has(loaded.code))

func _threshold_snapshot(backlog: int) -> Dictionary:
	return {"knowledge_state": "CHARTED", "availability_state": "AVAILABLE", "lifecycle_state": "OVERDUE", "remaining_backlog": str(backlog), "persistent_returns_total": "0", "familiarity_subunits": "0", "channel_acquisition": {}}
