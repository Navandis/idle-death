extends GutTest

const HOUR := 3600000

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func _state(active := true) -> GameState:
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

func test_candidate_identity_and_supported_swap_preserve_residuals() -> void:
	var registry := _registry()
	var assignment := ReapingAssignmentService.new(registry)
	var state := _state(false)
	var before_progress: int = state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].progress_subunits
	var candidate := assignment.validate_loadout_candidate(state, &"THR_GLOAMWOOD", &"FORM_SCRIBE", &"WRIT_STANDARD")
	assert_true(candidate.success, candidate.developer_details)
	assert_eq(candidate.loadout_identity.form_id, "FORM_SCRIBE")
	var result := assignment.redispatch(state, &"THR_GLOAMWOOD", &"FORM_SCRIBE", &"WRIT_STANDARD", 1)
	assert_true(result.success, result.developer_details)
	assert_eq(state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].progress_subunits, before_progress)

func test_query_eta_percentage_and_display() -> void:
	var service := ReapingRateContextService.new(_registry())
	var query := service.query_acquisition(_state(true), &"THR_GLOAMWOOD", &"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS")
	assert_true(query.ok, str(query))
	assert_eq(query.progress_subunits, 500000)
	assert_eq(query.percent_tenths, 500)
	assert_eq(query.eta_msec, 14400000)
	assert_eq(query.eta_basis, ReapingRateContextService.ETA_BASIS_CURRENT_RATE_CONTEXT)
	assert_eq(service.eta_display(13935000).english_text, "03 hours, 52 minutes, 15 seconds")
	assert_eq(service.eta_display(183840000).english_text, "02 days, 03 hours, 04 minutes")
	assert_eq(service.eta_display(1).english_text, "00 hours, 00 minutes, 01 second")

func test_inactive_query_has_no_eta() -> void:
	var query := ReapingRateContextService.new(_registry()).query_acquisition(_state(false), &"THR_GLOAMWOOD", &"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS")
	assert_true(query.ok)
	assert_false(query.is_active)
	assert_eq(query.eta_msec, -1)

func test_output_channel_rate_modifier_rejects_deferred_supported_conditions() -> void:
	var service := ReapingRateContextService.new(_registry())
	var threshold := {"tags": ["TAG_FOREST"]}
	var channel := {"output_item_id": "SOUL_FORM_SCRIBE", "output_kind": "WHOLE_ITEM"}
	var modifier := {"condition": "SUPPORT_STATE", "condition_values": ["FULL"]}
	var result := service._modifier_applicability(modifier, threshold, channel, "OVERDUE")
	assert_false(result.ok)
	assert_eq(result.code, ReapingRateContextService.ERR_CONTENT)
	assert_string_contains(result.details, "SUPPORT_STATE")
