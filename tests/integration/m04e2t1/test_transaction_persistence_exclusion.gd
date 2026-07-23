extends GutTest

## Integration proof that M04E2T1 remains runtime-only evidence and does not
## change the schema-v3 production snapshot or save/load authority.

const HOUR := 3600000

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func test_transaction_and_result_artifacts_are_excluded_from_schema_v3_snapshot() -> void:
	var registry := _registry()
	var state := GameState.new(0)
	state.progression.command_tether_capacity = 1
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
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
	var result := SimulationRunService.new(registry).run_committed(state, HOUR, SimulationRunService.MODE_FOREGROUND_SUPPLIED)
	assert_true(result.success, result.developer_details)
	var mapped := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION)
	assert_eq(mapped.schema_version, SaveInt64.format(4))
	assert_eq(mapped.content_revision, ContentRegistry.CURRENT_REVISION)
	var snapshot_text := JSON.stringify(mapped)
	for forbidden in ["SimulationRunContext", "SimulationTransaction", "SimulationFactJournal", "transaction", "journal", "simulation_result", "forecast"]:
		assert_false(snapshot_text.contains(forbidden), forbidden)
