extends GutTest

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func test_schema_v3_round_trip_excludes_rate_context_query_artifacts() -> void:
	var registry := _registry()
	var state := _state(true)
	var query := ReapingRateContextService.new(registry).query_acquisition(state, &"THR_GLOAMWOOD", &"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS")
	assert_true(query.ok)
	var snapshot := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION)
	var text := JSON.stringify(snapshot)
	for forbidden in ["validation_result", "loadout_identity", "rate_context_signature", "continuity_result", "rate_plan", "modifier_trace", "progress_tenths_percent", "percent_tenths", "current_context_eta_msec", "eta_msec", "eta_display"]:
		assert_false(text.contains(forbidden), forbidden)
	assert_true(SaveSchemaValidator.validate_v3(snapshot).ok)

func test_production_coordinator_round_trip_preserves_runtime_and_no_derived_views() -> void:
	var registry := _registry()
	var state := _state(false)
	state.simulation_time_msec = 5000
	var threshold: GameState.ThresholdState = state.thresholds[&"THR_GLOAMWOOD"]
	threshold.channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].progress_subunits = 345678
	threshold.channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].rate_carry_units = 12345
	state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[CoreFlowKeys.RETURNS_PROGRESS] = 111111
	state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[CoreFlowKeys.RETURNS_CARRY] = 222
	state.reapings[&"THR_GLOAMWOOD"].cycle_phase_msec = 3333
	state.reapings[&"THR_GLOAMWOOD"].started_simulation_msec = 1000
	state.reapings[&"THR_GLOAMWOOD"].last_configuration_change_simulation_msec = 5000
	var assignment := ReapingAssignmentService.new(registry)
	assert_true(assignment.redispatch(state, &"THR_GLOAMWOOD", &"FORM_SCRIBE", &"WRIT_STANDARD", 1).success)
	assert_eq(state.reapings[&"THR_GLOAMWOOD"].assignment_revision, 2)
	assert_eq(state.reapings[&"THR_GLOAMWOOD"].form_id, &"FORM_SCRIBE")
	assert_eq(state.reapings[&"THR_GLOAMWOOD"].started_simulation_msec, 1000)
	var canonical_before := _canonical(state)
	var root := OS.get_temp_dir().path_join("death_idle_m04d3_persistence_%s" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(root)
	var save := SaveService.new(FileSaveStorage.new(), SaveFileSet.new(root, "m04d3"))
	var coordinator := GameStatePersistenceCoordinator.new(save, registry)
	var saved := coordinator.save_runtime(state, TimeAuthorityState.new(), 7)
	assert_true(saved.ok, str(saved))
	var loaded := coordinator.load_runtime()
	assert_true(loaded.ok, str(loaded))
	assert_false(loaded.migration_persisted)
	assert_eq(loaded.save_revision, 7)
	assert_eq(_canonical(loaded.game_state), canonical_before)
	var snapshot_text := JSON.stringify(save.load_snapshot().snapshot)
	for forbidden in ["validation_result", "loadout_identity", "rate_context_signature", "continuity_result", "rate_plan", "modifier_trace", "progress_tenths_percent", "percent_tenths", "current_context_eta_msec", "eta_msec", "eta_display"]:
		assert_false(snapshot_text.contains(forbidden), forbidden)
	assert_true(assignment.recall(loaded.game_state, &"THR_GLOAMWOOD", 2).success)
	assert_true(assignment.redispatch(loaded.game_state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", 3).success)
	assert_eq(loaded.game_state.reapings[&"THR_GLOAMWOOD"].form_id, &"FORM_MAN_AT_ARMS")
	_remove_root(root)

func test_two_threshold_identity_isolation_survives_round_trip() -> void:
	var registry := _registry()
	var state := _two_threshold_state()
	var d1 := ReapingAssignmentService.new(registry).dispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD")
	assert_true(d1.success, d1.developer_details)
	var d2 := ReapingAssignmentService.new(registry).dispatch(state, &"THR_BROKEN_WATCH", &"FORM_SCRIBE", &"WRIT_STANDARD")
	assert_true(d2.success, d2.developer_details)
	state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].progress_subunits = 123456
	state.thresholds[&"THR_BROKEN_WATCH"].channel_acquisition[&"CHANNEL_BROKEN_WATCH_PROVISIONS"].progress_subunits = 654321
	var root := OS.get_temp_dir().path_join("death_idle_m04d3_two_threshold_%s" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(root)
	var coordinator := GameStatePersistenceCoordinator.new(SaveService.new(FileSaveStorage.new(), SaveFileSet.new(root, "m04d3_two")), registry)
	var saved := coordinator.save_runtime(state, TimeAuthorityState.new(), 3)
	assert_true(saved.ok, str(saved))
	var loaded := coordinator.load_runtime()
	assert_true(loaded.ok, str(loaded))
	assert_eq(_canonical(loaded.game_state), _canonical(state))
	assert_ne(loaded.game_state.reapings[&"THR_GLOAMWOOD"].form_id, loaded.game_state.reapings[&"THR_BROKEN_WATCH"].form_id)
	assert_eq(loaded.game_state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].progress_subunits, 123456)
	assert_eq(loaded.game_state.thresholds[&"THR_BROKEN_WATCH"].channel_acquisition[&"CHANNEL_BROKEN_WATCH_PROVISIONS"].progress_subunits, 654321)
	_remove_root(root)

func _state(active: bool) -> GameState:
	var state := GameState.new(0)
	state.progression.command_tether_capacity = 1
	state.progression.unlocked_output_item_ids = [&"SOUL_FORM_SCRIBE"]
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
	state.forms[&"FORM_SCRIBE"] = GameState.FormState.new(true, true, 0, &"TEST")
	var threshold := GameState.ThresholdState.new()
	threshold.knowledge_state = &"CHARTED"
	threshold.availability_state = &"AVAILABLE"
	threshold.lifecycle_state = &"OVERDUE"
	threshold.remaining_backlog = 1000000
	threshold.channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"] = GameState.ThresholdAcquisitionState.new(500000, 0, 0)
	state.thresholds[&"THR_GLOAMWOOD"] = threshold
	var reaping := GameState.ReapingState.new()
	reaping.threshold_id = &"THR_GLOAMWOOD"
	reaping.is_active = active
	reaping.form_id = &"FORM_MAN_AT_ARMS"
	reaping.writ_id = &"WRIT_STANDARD"
	reaping.assignment_revision = 1
	state.reapings[&"THR_GLOAMWOOD"] = reaping
	return state

func _two_threshold_state() -> GameState:
	var state := _state(false)
	state.progression.command_tether_capacity = 2
	state.progression.unlocked_output_item_ids = [&"RES_PROVISIONS", &"SOUL_FORM_SCRIBE"]
	var watch := GameState.ThresholdState.new()
	watch.knowledge_state = &"CHARTED"
	watch.availability_state = &"AVAILABLE"
	watch.lifecycle_state = &"OVERDUE"
	watch.remaining_backlog = 250000
	watch.channel_acquisition[&"CHANNEL_BROKEN_WATCH_PROVISIONS"] = GameState.ThresholdAcquisitionState.new(0, 0, 0)
	state.thresholds[&"THR_BROKEN_WATCH"] = watch
	state.reapings.clear()
	return state

func _canonical(state: GameState) -> Dictionary:
	return SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION).game_state

func _remove_root(path: String) -> void:
	if DirAccess.dir_exists_absolute(path):
		for file in DirAccess.get_files_at(path):
			DirAccess.remove_absolute(path.path_join(file))
		DirAccess.remove_absolute(path)
