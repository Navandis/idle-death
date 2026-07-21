extends GutTest

const HOUR := 3600000

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func _state() -> GameState:
	var state := GameState.new(0)
	state.progression.command_tether_capacity = 1
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
	var threshold := GameState.ThresholdState.new()
	threshold.knowledge_state = &"CHARTED"; threshold.availability_state = &"AVAILABLE"; threshold.lifecycle_state = &"OVERDUE"; threshold.remaining_backlog = 1000000
	state.thresholds[&"THR_GLOAMWOOD"] = threshold
	var reaping := GameState.ReapingState.new()
	reaping.threshold_id = &"THR_GLOAMWOOD"; reaping.is_active = true; reaping.form_id = &"FORM_MAN_AT_ARMS"; reaping.writ_id = &"WRIT_STANDARD"; reaping.assignment_revision = 1
	state.reapings[&"THR_GLOAMWOOD"] = reaping
	var access := OutputAccessService.new(_registry())
	assert_true(access.unlock_output_item(state, &"SOUL_CALLING_SOLDIER").success)
	assert_true(access.unlock_output_item(state, &"SOUL_FORM_SCRIBE").success)
	assert_true(access.reconcile_available_sources(state).success)
	return state

func test_run_service_debug_and_persistence_exclude_typed_results() -> void:
	var registry := _registry()
	var state := _state()
	var run := SimulationRunService.new(registry).run_committed(state, HOUR, SimulationRunService.MODE_FOREGROUND_SUPPLIED)
	assert_true(run.success, run.developer_details)
	assert_gt(run.simulation_result.segments.size(), 0)
	assert_true(run.simulation_result.segments[0] is SimulationEngine.SimulationSegmentResult)
	assert_true(run.simulation_result.change_summary.channel_deltas[0] is SimulationEngine.SimulationChannelDeltaResult)
	var debug_state := _state()
	var debug := M04CDebugAdvance.new(registry).advance_msec(debug_state, HOUR)
	assert_true(debug.success, debug.developer_details)
	assert_true(debug.segments[0] is SimulationEngine.SimulationSegmentResult)
	var snapshot := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 7, ContentRegistry.CURRENT_REVISION)
	var encoded := JsonSaveCodec.new().encode(snapshot)
	assert_true(encoded.ok, str(encoded))
	var text: String = encoded.bytes.get_string_from_utf8()
	for needle in ["SimulationRunResult", "SimulationResult", "SimulationSegmentResult", "SimulationChannelDeltaResult", "SimulationEvent", "validation", "forecast", "projection", "report_state"]:
		assert_eq(text.find(needle), -1, needle)
	assert_eq(SaveEnvelope.CURRENT_SCHEMA_VERSION, SaveEnvelope.SCHEMA_VERSION_V3)
	assert_eq(ContentRegistry.CURRENT_REVISION, "prototype-content-r2")

func test_forecast_result_is_typed_and_projection_detached() -> void:
	var state := _state()
	var before: Dictionary = SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION).game_state
	var forecast := SimulationRunService.new(_registry()).forecast(state, 8 * HOUR)
	assert_true(forecast.success, forecast.developer_details)
	assert_true(forecast.simulation_result.segments[0] is SimulationEngine.SimulationSegmentResult)
	assert_true(forecast.simulation_result.change_summary.channel_deltas[0] is SimulationEngine.SimulationChannelDeltaResult)
	forecast.projected_state.inventory.entries[&"RES_ESSENCE"].total += 1
	var after: Dictionary = SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION).game_state
	assert_eq(after, before)
