extends GutTest

## Integration proof that detached simulation facts remain runtime-only and the
## existing schema-v3 snapshot contract is unchanged by public result typing.

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func test_typed_result_and_projector_artifacts_never_enter_schema_v3_save() -> void:
	var registry := _registry()
	var state := GameState.new(0)
	state.progression.command_tether_capacity = 1
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"T2_TEST")
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
	var run := SimulationRunService.new(registry).run_committed(state, 3600000, SimulationRunService.MODE_FOREGROUND_SUPPLIED)
	assert_true(run.success, run.developer_details)
	assert_true(run.simulation_result is SimulationResult)
	var mapped := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION)
	assert_eq(mapped.schema_version, SaveInt64.format(4))
	assert_eq(mapped.content_revision, ContentRegistry.CURRENT_REVISION)
	var snapshot_text := JSON.stringify(mapped)
	for forbidden in ["SimulationResult", "SimulationSegmentResult", "SimulationChannelDeltaResult", "SimulationEvent", "SimulationResultProjector", "SimulationRunContext", "SimulationTransaction", "SimulationFactJournal", "simulation_result", "segments", "channel_deltas"]:
		assert_false(snapshot_text.contains(forbidden), forbidden)
