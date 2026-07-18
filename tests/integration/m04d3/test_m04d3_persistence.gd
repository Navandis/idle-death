extends GutTest

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func test_schema_v3_round_trip_excludes_rate_context_query_artifacts() -> void:
	var registry := _registry()
	var state := GameState.new(0)
	state.progression.command_tether_capacity = 1
	state.progression.unlocked_output_item_ids = [&"SOUL_FORM_SCRIBE"]
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
	var threshold := GameState.ThresholdState.new()
	threshold.knowledge_state = &"CHARTED"
	threshold.availability_state = &"AVAILABLE"
	threshold.lifecycle_state = &"OVERDUE"
	threshold.remaining_backlog = 1000000
	threshold.channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"] = GameState.ThresholdAcquisitionState.new(500000, 0, 0)
	state.thresholds[&"THR_GLOAMWOOD"] = threshold
	var reaping := GameState.ReapingState.new()
	reaping.threshold_id = &"THR_GLOAMWOOD"
	reaping.is_active = true
	reaping.form_id = &"FORM_MAN_AT_ARMS"
	reaping.writ_id = &"WRIT_STANDARD"
	reaping.assignment_revision = 1
	state.reapings[&"THR_GLOAMWOOD"] = reaping
	var query := ReapingRateContextService.new(registry).query_acquisition(state, &"THR_GLOAMWOOD", &"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS")
	assert_true(query.ok)
	var snapshot := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION)
	var text := JSON.stringify(snapshot)
	assert_false(text.contains("eta_msec"))
	assert_false(text.contains("rate_plan"))
	assert_false(text.contains("percent_tenths"))
	assert_true(SaveSchemaValidator.validate_v3(snapshot).ok)
