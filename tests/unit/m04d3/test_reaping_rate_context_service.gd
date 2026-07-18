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

func test_public_contract_fields_and_eta_display_edges() -> void:
	var service := ReapingRateContextService.new(_registry())
	var state := _state(true)
	var query := service.query_acquisition(state, &"THR_GLOAMWOOD", &"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS")
	assert_true(query.success)
	for key in ["threshold_id", "channel_id", "output_item_id", "loadout_identity", "access_state", "disclosure_state", "is_active", "lifecycle_state", "progress_subunits", "progress_tenths_percent", "rate_plan", "eta_available", "current_context_eta_msec", "eta_basis", "eta_display"]:
		assert_true(query.has(key), "missing query key %s" % key)
	var plan: Dictionary = query.rate_plan
	for key in ["threshold_id", "channel_id", "output_item_id", "output_kind", "lifecycle_state", "baseline_rate_subunits_per_period", "effective_rate_subunits_per_period", "period_msec", "lifecycle_multiplier_subunits", "applied_modifiers"]:
		assert_true(plan.has(key), "missing rate-plan key %s" % key)
	assert_eq(service.eta_display(0).english_text, "00 hours, 00 minutes, 00 seconds")
	assert_eq(service.eta_display(1).english_text, "00 hours, 00 minutes, 01 second")
	assert_eq(service.eta_display(86400000).english_text, "01 day, 00 hours, 00 minutes")
	assert_eq(service.eta_display(100 * 86400000).english_text, "100 days, 00 hours, 00 minutes")
	assert_eq(service.eta_display(3600000).components.size(), 3)

func test_eta_validation_and_minimality() -> void:
	var service := ReapingRateContextService.new(_registry())
	assert_false(service._eta_msec_to_next_whole(-1, 0, 1, 1).ok)
	assert_false(service._eta_msec_to_next_whole(FixedPoint.SCALE, 0, 1, 1).ok)
	assert_false(service._eta_msec_to_next_whole(0, 10, 1, 10).ok)
	assert_false(service._eta_msec_to_next_whole(0, 0, 0, 10).ok)
	var eta := service._eta_msec_to_next_whole(999999, 0, 1, 10)
	assert_true(eta.ok)
	assert_eq(eta.eta_msec, 10)
	var before := FixedPoint.accumulate_for_elapsed_msec(1, 10, eta.eta_msec - 1, 0)
	var at := FixedPoint.accumulate_for_elapsed_msec(1, 10, eta.eta_msec, 0)
	assert_true(before.produced_subunits < 1)
	assert_true(at.produced_subunits >= 1)
