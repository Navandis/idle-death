extends GutTest

const HOUR := 3600000

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func _service() -> SimulationRunService:
	return SimulationRunService.new(_registry())

func _state(threshold_id: StringName = &"THR_GLOAMWOOD", backlog := 1000000, active := true) -> GameState:
	var state := GameState.new(0)
	state.progression.command_tether_capacity = 1
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
	state.forms[&"FORM_SCRIBE"] = GameState.FormState.new(true, true, 0, &"TEST")
	var threshold := GameState.ThresholdState.new()
	threshold.knowledge_state = &"CHARTED"
	threshold.availability_state = &"AVAILABLE"
	threshold.lifecycle_state = &"SETTLED" if backlog == 0 else &"OVERDUE"
	threshold.remaining_backlog = backlog
	state.thresholds[threshold_id] = threshold
	var reaping := GameState.ReapingState.new()
	reaping.threshold_id = threshold_id
	reaping.is_active = active
	reaping.form_id = &"FORM_MAN_AT_ARMS" if threshold_id == &"THR_GLOAMWOOD" else &"FORM_SCRIBE"
	reaping.writ_id = &"WRIT_STANDARD"
	reaping.assignment_revision = 1
	state.reapings[threshold_id] = reaping
	return state

func _unlock_and_init(state: GameState, item_ids: Array[StringName]) -> void:
	var access := OutputAccessService.new(_registry())
	for item_id in item_ids:
		assert_true(access.unlock_output_item(state, item_id).success)
	assert_true(access.reconcile_available_sources(state).success)

func _canonical(state: GameState) -> Dictionary:
	return SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION).game_state

func test_forecast_is_detached_and_matches_committed_clone() -> void:
	var baseline := _state()
	_unlock_and_init(baseline, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	var before := _canonical(baseline)
	var forecast := _service().forecast(baseline, HOUR)
	assert_true(forecast.success, forecast.developer_details)
	assert_eq(forecast.mode, SimulationRunService.MODE_FORECAST)
	assert_not_null(forecast.projected_state)
	assert_eq(_canonical(baseline), before)
	var committed := baseline.deep_clone()
	var committed_result := _service().run_committed(committed, HOUR, SimulationRunService.MODE_FOREGROUND_SUPPLIED)
	assert_true(committed_result.success, committed_result.developer_details)
	assert_null(committed_result.projected_state)
	assert_eq(_canonical(forecast.projected_state), _canonical(committed))
	forecast.projected_state.inventory.entries[&"RES_ESSENCE"].total += 1
	assert_eq(_canonical(baseline), before)
	baseline.inventory.entries[&"RES_ESSENCE"] = GameState.InventoryEntryState.new(999)
	assert_ne(forecast.projected_state.inventory.entries[&"RES_ESSENCE"].total, 999)

func test_eight_hour_forecast_preserves_complete_core_and_generic_channels() -> void:
	var state := _state()
	_unlock_and_init(state, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	var result := _service().forecast(state, 8 * HOUR)
	assert_true(result.success, result.developer_details)
	var projected: GameState = result.projected_state
	assert_eq(projected.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total, 33120)
	assert_eq(projected.inventory.entries[&"RES_ESSENCE"].total, 2880)
	assert_eq(projected.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits, 480000000)
	assert_eq(projected.reapings[&"THR_GLOAMWOOD"].completed_cycle_count, 480)
	assert_eq(projected.inventory.entries[&"SOUL_CALLING_SOLDIER"].total, 96)
	assert_eq(projected.inventory.entries[&"SOUL_FORM_SCRIBE"].total, 1)
	assert_eq(projected.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].progress_subunits, 0)
	var delta_ids := []
	for delta in result.engine_result.change_summary.channel_deltas:
		delta_ids.append(delta.channel_id)
	delta_ids.sort()
	assert_eq(delta_ids, ["CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS", "CHANNEL_GLOAMWOOD_SOLDIER_SOULS"])

func test_broken_watch_channel_kinds_pass_through_without_forecast_branch() -> void:
	var forecast_state := _state(&"THR_BROKEN_WATCH", 250000)
	_unlock_and_init(forecast_state, [&"RES_PROVISIONS", &"SOUL_FORM_MAN_AT_ARMS"])
	var commit_state := forecast_state.deep_clone()
	var forecast := _service().forecast(forecast_state, 24 * HOUR)
	var committed := _service().run_committed(commit_state, 24 * HOUR, SimulationRunService.MODE_OFFLINE_FIXTURE)
	assert_true(forecast.success, forecast.developer_details)
	assert_true(committed.success, committed.developer_details)
	assert_eq(_canonical(forecast.projected_state), _canonical(commit_state))
	assert_eq(forecast.projected_state.inventory.entries[&"RES_PROVISIONS"].total, 2880)
	assert_eq(forecast.projected_state.inventory.entries[&"SOUL_FORM_MAN_AT_ARMS"].total, 1)
	assert_eq(forecast.engine_result.change_summary.channel_deltas.size(), 2)

func test_settlement_modes_and_chunking_are_canonically_equal() -> void:
	var service := _service()
	var modes := [SimulationRunService.MODE_FOREGROUND_SUPPLIED, SimulationRunService.MODE_OFFLINE_FIXTURE, SimulationRunService.MODE_DEBUG]
	var snapshots := []
	for mode in modes:
		var state := _state(&"THR_GLOAMWOOD", 1)
		_unlock_and_init(state, [&"SOUL_CALLING_SOLDIER"])
		var result := service.run_committed(state, 10000, mode)
		assert_true(result.success, result.developer_details)
		assert_eq(result.engine_result.events[0].event_type, SimulationEngine.EVENT_THRESHOLD_SETTLED)
		snapshots.append(_canonical(state))
	assert_eq(snapshots[0], snapshots[1])
	assert_eq(snapshots[1], snapshots[2])
	var one_shot := _state(); _unlock_and_init(one_shot, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	var regular := one_shot.deep_clone()
	var irregular := one_shot.deep_clone()
	assert_true(service.run_committed(one_shot, HOUR, SimulationRunService.MODE_FOREGROUND_SUPPLIED).success)
	for _i in range(60): assert_true(service.run_committed(regular, 60000, SimulationRunService.MODE_FOREGROUND_SUPPLIED).success)
	for elapsed in [1, 999, 1234567, 2364433, 0]: assert_true(service.run_committed(irregular, elapsed, SimulationRunService.MODE_FOREGROUND_SUPPLIED).success)
	assert_eq(_canonical(one_shot), _canonical(regular))
	assert_eq(_canonical(one_shot), _canonical(irregular))

func test_zero_negative_invalid_and_method_mode_failures_do_not_mutate() -> void:
	var service := _service()
	var state := _state()
	_unlock_and_init(state, [&"SOUL_CALLING_SOLDIER"])
	var before := _canonical(state)
	var zero := service.forecast(state, 0)
	assert_true(zero.success)
	assert_not_null(zero.projected_state)
	assert_eq(_canonical(zero.projected_state), before)
	assert_ne(zero.projected_state, state)
	var negative := service.forecast(state, -1)
	assert_false(negative.success)
	assert_eq(negative.error_code, SimulationRunService.ERR_NEGATIVE_ELAPSED)
	assert_null(negative.projected_state)
	assert_eq(_canonical(state), before)
	var wrong_mode := service.run_committed(state, 1, SimulationRunService.MODE_FORECAST)
	assert_false(wrong_mode.success)
	assert_eq(wrong_mode.error_code, SimulationRunService.ERR_INVALID_MODE)
	assert_eq(_canonical(state), before)
	state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[&"UNKNOWN"] = 1
	var invalid_before := _canonical(state)
	var unsupported := service.forecast(state, 1000)
	assert_false(unsupported.success)
	assert_eq(unsupported.error_code, SimulationEngine.ERR_UNSUPPORTED_FLOW)
	assert_null(unsupported.projected_state)
	assert_eq(_canonical(state), invalid_before)

func test_debug_adapter_delegates_through_run_service() -> void:
	var registry := _registry()
	var direct := _state(); _unlock_and_init(direct, [&"SOUL_CALLING_SOLDIER"])
	var debug := direct.deep_clone()
	assert_true(SimulationRunService.new(registry).run_committed(direct, 60000, SimulationRunService.MODE_DEBUG).success)
	assert_true(M04CDebugAdvance.new(registry).advance_msec(debug, 60000).success)
	assert_eq(_canonical(direct), _canonical(debug))

func test_run_service_source_ownership_audit() -> void:
	var source := FileAccess.get_file_as_string("res://src/simulation/simulation_run_service.gd")
	for needle in ["Time.", "OS.", "FileAccess", "Save", "Report", "Tutorial", "extends Node", "CHANNEL_", "SOUL_", "RES_", "THR_"]:
		assert_eq(source.find(needle), -1, "forbidden run-service token: %s" % needle)
