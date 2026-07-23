extends GutTest

const HOUR := 3600000

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func test_forecast_loaded_schema_v3_state_preserves_production_save_files_and_snapshot() -> void:
	var registry := _registry()
	var root := OS.get_temp_dir().path_join("death_idle_m04e1_persistence_%s" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(root)
	var file_set := SaveFileSet.new(root, "m04e1")
	var coordinator := GameStatePersistenceCoordinator.new(SaveService.new(FileSaveStorage.new(), file_set), registry)
	var state := _state()
	_unlock_and_init(state, registry, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	var canonical_before := _canonical(state)
	assert_true(coordinator.save_runtime(state, TimeAuthorityState.new(), 7).ok)
	assert_true(coordinator.save_runtime(state, TimeAuthorityState.new(), 8).ok)
	var primary_before := FileAccess.get_file_as_bytes(file_set.primary_path)
	var backup_before := FileAccess.get_file_as_bytes(file_set.backup_path)
	assert_gt(primary_before.size(), 0)
	assert_gt(backup_before.size(), 0)
	var loaded := coordinator.load_runtime()
	assert_true(loaded.ok, str(loaded))
	assert_false(loaded.migration_persisted)
	assert_eq(loaded.save_revision, 8)
	assert_eq(_canonical(loaded.game_state), canonical_before)
	var forecast := SimulationRunService.new(registry).forecast(loaded.game_state, HOUR)
	assert_true(forecast.success, forecast.developer_details)
	assert_eq(forecast.mode, SimulationRunService.MODE_FORECAST)
	assert_eq(forecast.baseline_simulation_time_msec, 0)
	assert_eq(forecast.result_simulation_time_msec, HOUR)
	assert_not_null(forecast.simulation_result)
	assert_not_null(forecast.projected_state)
	assert_ne(forecast.projected_state, loaded.game_state)
	assert_true(GameStateValidator.validate(forecast.projected_state, registry).ok)
	assert_eq(_canonical(loaded.game_state), canonical_before)
	assert_eq(FileAccess.get_file_as_bytes(file_set.primary_path), primary_before)
	assert_eq(FileAccess.get_file_as_bytes(file_set.backup_path), backup_before)
	assert_false(FileAccess.file_exists(file_set.temporary_path))
	var snapshot := SaveService.new(FileSaveStorage.new(), file_set).load_snapshot()
	assert_true(snapshot.ok, str(snapshot))
	var snapshot_text := JSON.stringify(snapshot.snapshot)
	for forbidden in ["run_result", "projection", "projected_state", "simulation_result", "comparison", "forecast", "baseline_simulation_time_msec", "result_simulation_time_msec"]:
		assert_false(snapshot_text.contains(forbidden), forbidden)
	_remove_root(root)

func _state() -> GameState:
	var state := GameState.new(0)
	state.progression.command_tether_capacity = 1
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
	state.forms[&"FORM_SCRIBE"] = GameState.FormState.new(true, true, 0, &"TEST")
	var threshold := GameState.ThresholdState.new()
	threshold.knowledge_state = &"CHARTED"
	threshold.availability_state = &"AVAILABLE"
	threshold.lifecycle_state = &"OVERDUE"
	threshold.remaining_backlog = 1000000
	state.thresholds[&"THR_GLOAMWOOD"] = threshold
	var reaping := GameState.ReapingState.new()
	reaping.threshold_id = &"THR_GLOAMWOOD"
	reaping.is_active = true
	reaping.form_id = &"FORM_MAN_AT_ARMS"
	reaping.writ_id = &"WRIT_STANDARD"
	reaping.assignment_revision = 1
	state.reapings[&"THR_GLOAMWOOD"] = reaping
	return state

func _unlock_and_init(state: GameState, registry: ContentRegistry, item_ids: Array[StringName]) -> void:
	var access := OutputAccessService.new(registry)
	for item_id in item_ids:
		assert_true(access.unlock_output_item(state, item_id).success)
	assert_true(access.reconcile_available_sources(state).success)

func _canonical(state: GameState) -> Dictionary:
	return SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION).game_state

func _remove_root(path: String) -> void:
	if DirAccess.dir_exists_absolute(path):
		for file in DirAccess.get_files_at(path):
			DirAccess.remove_absolute(path.path_join(file))
		DirAccess.remove_absolute(path)
