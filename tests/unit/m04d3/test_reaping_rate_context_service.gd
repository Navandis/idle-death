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


func test_signature_mismatch_matrix_and_no_mutation() -> void:
	var base_state := _state(false)
	var form_fields := {
		"returned_soul_period_msec": func(reg): reg._records["FORM_SCRIBE"].base_returned_souls_rate.period_msec = 2000,
		"mastery_period_msec": func(reg): reg._records["FORM_SCRIBE"].active_mastery_rate.period_msec = 120000,
		"cycle_duration_msec": func(reg): reg._records["FORM_SCRIBE"].cycle_duration_msec = 120000,
	}
	for field in form_fields.keys():
		var registry := _registry()
		form_fields[field].call(registry)
		var state := base_state.deep_clone()
		var before := _canonical(state)
		var result := ReapingAssignmentService.new(registry).redispatch(state, &"THR_GLOAMWOOD", &"FORM_SCRIBE", &"WRIT_STANDARD", 1)
		assert_false(result.success, field)
		assert_eq(result.error_code, ReapingAssignmentService.REAPING_RATE_CONTEXT_NORMALIZATION_REQUIRED)
		assert_true(result.developer_details.contains(field), result.developer_details)
		assert_eq(_canonical(state), before, field)
	var service := ReapingRateContextService.new(_registry())
	var old_sig := {"returned_soul_period_msec": 1000, "mastery_period_msec": 60000, "cycle_duration_msec": 60000, "essence_period_msec": 1000, "initialized_non_essence_channel_period_msec_by_channel_id": {"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS": 28800000}}
	var essence_sig := old_sig.duplicate(true); essence_sig.essence_period_msec = 2000
	assert_eq(service._signature_mismatches(old_sig, essence_sig), ["essence_period_msec"])
	var channel_sig := old_sig.duplicate(true); channel_sig.initialized_non_essence_channel_period_msec_by_channel_id.CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS = 14400000
	assert_eq(service._signature_mismatches(old_sig, channel_sig), ["channel_period_msec.CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"])

func test_modifier_fixture_matrix_and_query_uses_shared_plan() -> void:
	var registry := _registry_with_scribe_output_modifier("ALWAYS", [], 1200000)
	registry._records["CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].rate.period_msec = 14400000
	var service := ReapingRateContextService.new(registry)
	var plan := service.output_channel_rate_plan(&"THR_GLOAMWOOD", &"FORM_SCRIBE", &"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS", "OVERDUE")
	assert_true(plan.success, str(plan))
	assert_eq(plan.baseline_rate_subunits_per_period, 1000000)
	assert_eq(plan.effective_rate_subunits_per_period, 1200000)
	assert_eq(plan.applied_modifiers.size(), 1)
	assert_eq(plan.applied_modifiers[0].rate_before_subunits_per_period, 1000000)
	assert_eq(plan.applied_modifiers[0].rate_after_subunits_per_period, 1200000)
	var state := _state(true)
	state.reapings[&"THR_GLOAMWOOD"].form_id = &"FORM_SCRIBE"
	state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].progress_subunits = 500000
	var query := service.query_acquisition(state, &"THR_GLOAMWOOD", &"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS")
	assert_true(query.success, str(query))
	assert_eq(query.rate_plan, plan)
	assert_eq(query.current_context_eta_msec, 6000000)
	assert_eq(query.progress_subunits, 500000)

	var cases := [
		["OUTPUT_ITEM", ["SOUL_FORM_SCRIBE"], 1200000],
		["OUTPUT_ITEM", ["SOUL_CALLING_SOLDIER"], 1000000],
		["OUTPUT_KIND", ["WHOLE_ITEM"], 1200000],
		["OUTPUT_KIND", ["RESOURCE"], 1000000],
		["THRESHOLD_HAS_ANY_TAG", ["TAG_FOREST"], 1200000],
		["THRESHOLD_HAS_ANY_TAG", ["TAG_ROAD"], 1000000],
		["THRESHOLD_LIFECYCLE", ["OVERDUE"], 1200000],
		["THRESHOLD_LIFECYCLE", ["SETTLED"], 1000000],
	]
	for case in cases:
		var reg := _registry_with_scribe_output_modifier(case[0], case[1], 1200000)
		var p := ReapingRateContextService.new(reg).output_channel_rate_plan(&"THR_GLOAMWOOD", &"FORM_SCRIBE", &"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS", "OVERDUE")
		assert_true(p.success, str(case) + str(p))
		assert_eq(p.effective_rate_subunits_per_period, case[2], str(case))

func test_modifier_order_floor_lifecycle_and_failure_matrix() -> void:
	var registry := _registry_with_scribe_output_modifier("ALWAYS", [], 1500000)
	registry._records["FORM_SCRIBE"].traits[0].modifiers.append(_output_modifier("ALWAYS", [], 1333333))
	registry._records["CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].settled_multiplier_subunits = 500000
	var plan := ReapingRateContextService.new(registry).output_channel_rate_plan(&"THR_GLOAMWOOD", &"FORM_SCRIBE", &"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS", "SETTLED")
	assert_true(plan.success, str(plan))
	assert_eq(plan.applied_modifiers.size(), 2)
	assert_eq(plan.applied_modifiers[0].rate_after_subunits_per_period, 1500000)
	assert_eq(plan.applied_modifiers[1].rate_before_subunits_per_period, 1500000)
	assert_eq(plan.applied_modifiers[1].rate_after_subunits_per_period, 1999999)
	assert_eq(plan.effective_rate_subunits_per_period, 999999)
	var ignored := _registry()
	ignored._records["FORM_SCRIBE"].traits[0].modifiers.append({"metric": "DISCOVERY_RATE", "operation": "MULTIPLY", "scope": "OUTPUT_CHANNEL", "condition": "ALWAYS", "condition_values": [], "value_subunits": 5000000})
	assert_eq(ReapingRateContextService.new(ignored).output_channel_rate_plan(&"THR_GLOAMWOOD", &"FORM_SCRIBE", &"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS", "OVERDUE").effective_rate_subunits_per_period, 1000000)
	var failures := [
		func(reg): reg._records["FORM_SCRIBE"].traits[0].modifiers[0].operation = "ADD",
		func(reg): reg._records["FORM_SCRIBE"].traits[0].modifiers[0].scope = "REAPING_TOTAL",
		func(reg): reg._records["FORM_SCRIBE"].traits[0].modifiers[0].condition = "SUPPORT_STATE",
		func(reg): reg._records["FORM_SCRIBE"].traits[0].modifiers[0].condition = "OUTPUT_ITEM"; reg._records["FORM_SCRIBE"].traits[0].modifiers[0].condition_values = [],
		func(reg): reg._records["FORM_SCRIBE"].traits[0].modifiers[0].condition = "OUTPUT_ITEM"; reg._records["FORM_SCRIBE"].traits[0].modifiers[0].condition_values = ["NOPE"],
		func(reg): reg._records["FORM_SCRIBE"].traits[0].modifiers[0].value_subunits = 0,
	]
	for failure in failures:
		var reg := _registry_with_scribe_output_modifier("ALWAYS", [], 1200000)
		failure.call(reg)
		var failed := ReapingRateContextService.new(reg).output_channel_rate_plan(&"THR_GLOAMWOOD", &"FORM_SCRIBE", &"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS", "OVERDUE")
		assert_false(failed.success, str(failed))
		assert_eq(failed.error_code, ReapingRateContextService.ERR_CONTENT)

func test_query_state_matrix_and_percentage_cap() -> void:
	var service := ReapingRateContextService.new(_registry())
	var inactive_state := _state(false)
	inactive_state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].progress_subunits = 999999
	var inactive := service.query_acquisition(inactive_state, &"THR_GLOAMWOOD", &"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS")
	assert_true(inactive.success)
	assert_eq(inactive.access_state, "INITIALIZED")
	assert_false(inactive.eta_available)
	assert_eq(inactive.progress_tenths_percent, 999)
	var locked_state := _state(false)
	locked_state.progression.unlocked_output_item_ids = []
	locked_state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition.erase(&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS")
	var locked := service.query_acquisition(locked_state, &"THR_GLOAMWOOD", &"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS")
	assert_true(locked.success)
	assert_eq(locked.access_state, "LOCKED")
	assert_false(locked.eta_available)
	var unavailable_state := _state(false)
	unavailable_state.thresholds[&"THR_GLOAMWOOD"].availability_state = &"LOCKED"
	unavailable_state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition.clear()
	var unavailable := service.query_acquisition(unavailable_state, &"THR_GLOAMWOOD", &"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS")
	assert_true(unavailable.success)
	assert_eq(unavailable.access_state, "UNAVAILABLE")
	assert_false(service.query_acquisition(_state(true), &"THR_GLOAMWOOD", &"CHANNEL_GLOAMWOOD_ESSENCE").success)
	assert_false(service.query_acquisition(_state(true), &"THR_GLOAMWOOD", &"CHANNEL_BROKEN_WATCH_PROVISIONS").success)
	assert_false(service.query_acquisition(_state(true), &"THR_GLOAMWOOD", &"NOPE").success)

func test_equal_identity_non_compounding_return_and_chunk_sequence() -> void:
	var registry := _registry_with_scribe_output_modifier("ALWAYS", [], 1200000)
	var service := ReapingRateContextService.new(registry)
	var assignment := ReapingAssignmentService.new(registry)
	var a_identity := service.loadout_identity(&"FORM_MAN_AT_ARMS", &"WRIT_STANDARD")
	var b_identity := service.loadout_identity(&"FORM_SCRIBE", &"WRIT_STANDARD")
	var a_plan := service.output_channel_rate_plan(&"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS", "OVERDUE")
	assert_ne(a_identity, b_identity)
	assert_true(a_plan.success)
	var state := _state(false)
	var before := _canonical(state)
	assert_true(assignment.redispatch(state, &"THR_GLOAMWOOD", &"FORM_SCRIBE", &"WRIT_STANDARD", 1).success)
	var b_plan := service.output_channel_rate_plan(&"THR_GLOAMWOOD", &"FORM_SCRIBE", &"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS", "OVERDUE")
	assert_eq(b_plan.effective_rate_subunits_per_period, 1200000)
	assert_true(assignment.recall(state, &"THR_GLOAMWOOD", 2).success)
	assert_true(assignment.redispatch(state, &"THR_GLOAMWOOD", &"FORM_SCRIBE", &"WRIT_STANDARD", 3).success)
	assert_eq(service.output_channel_rate_plan(&"THR_GLOAMWOOD", &"FORM_SCRIBE", &"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS", "OVERDUE").effective_rate_subunits_per_period, 1200000)
	assert_true(assignment.recall(state, &"THR_GLOAMWOOD", 4).success)
	assert_true(assignment.redispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", 5).success)
	assert_eq(service.output_channel_rate_plan(&"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS", "OVERDUE").effective_rate_subunits_per_period, a_plan.effective_rate_subunits_per_period)
	assert_eq(state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].progress_subunits, before.thresholds.THR_GLOAMWOOD.channel_acquisition.CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS.progress_subunits.to_int())

func _registry_with_scribe_output_modifier(condition: String, values: Array, multiplier: int) -> ContentRegistry:
	var registry := _registry()
	registry._records["FORM_SCRIBE"].traits[0].modifiers = [_output_modifier(condition, values, multiplier)]
	return registry

func _output_modifier(condition: String, values: Array, multiplier: int) -> Dictionary:
	return {"metric": "OUTPUT_CHANNEL_RATE", "operation": "MULTIPLY", "scope": "OUTPUT_CHANNEL", "condition": condition, "condition_values": values.duplicate(), "value_subunits": multiplier}

func _canonical(state: GameState) -> Dictionary:
	return SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION).game_state

func test_nonzero_carry_eta_query_uses_persisted_carry_without_mutation() -> void:
	var registry := _registry()
	registry._records["CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].rate.period_msec = 14400000
	var service := ReapingRateContextService.new(registry)
	var state := _state(true)
	var acq: GameState.ThresholdAcquisitionState = state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"]
	acq.progress_subunits = 500000
	acq.rate_carry_units = 7200000
	var before := _canonical(state)
	var query := service.query_acquisition(state, &"THR_GLOAMWOOD", &"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS")
	assert_true(query.success, str(query))
	assert_eq(query.eta_basis, ReapingRateContextService.ETA_BASIS_CURRENT_RATE_CONTEXT)
	assert_eq(query.current_context_eta_msec, 7199993)
	assert_eq(_canonical(state), before)
	var insufficient := FixedPoint.accumulate_for_elapsed_msec(1000000, 14400000, query.current_context_eta_msec - 1, 7200000)
	var sufficient := FixedPoint.accumulate_for_elapsed_msec(1000000, 14400000, query.current_context_eta_msec, 7200000)
	assert_true(insufficient.produced_subunits < 500000)
	assert_true(sufficient.produced_subunits >= 500000)
	assert_false(service._eta_msec_to_next_whole(500000, 14400000, 1000000, 14400000).success)
	assert_eq(service._eta_msec_to_next_whole(0, 0, FixedPoint.INT64_MAX, FixedPoint.INT64_MAX).error_code, ReapingRateContextService.ERR_OVERFLOW)

func test_stale_candidate_commit_revalidation_rejects_without_mutation() -> void:
	var registry := _registry()
	var assignment := ReapingAssignmentService.new(registry)
	var state := _two_threshold_state_for_m04d3()
	var candidate := assignment.validate_loadout_candidate(state, &"THR_GLOAMWOOD", &"FORM_SCRIBE", &"WRIT_STANDARD", [], &"THR_GLOAMWOOD")
	assert_true(candidate.success, candidate.developer_details)
	var broken := GameState.ReapingState.new()
	broken.threshold_id = &"THR_BROKEN_WATCH"
	broken.is_active = true
	broken.form_id = &"FORM_SCRIBE"
	broken.writ_id = &"WRIT_STANDARD"
	broken.assignment_revision = 1
	state.reapings[&"THR_BROKEN_WATCH"] = broken
	var before := _canonical(state)
	var result := assignment.redispatch(state, &"THR_GLOAMWOOD", &"FORM_SCRIBE", &"WRIT_STANDARD", 1)
	assert_false(result.success)
	assert_eq(result.error_code, ReapingAssignmentService.REAPING_FORM_ALREADY_ASSIGNED)
	assert_eq(_canonical(state), before)

func test_exact_sequence_1_3_2_1_preserves_operation_identity() -> void:
	var registry := _registry_with_scribe_output_modifier("ALWAYS", [], 1200000)
	var assignment := ReapingAssignmentService.new(registry)
	var service := ReapingRateContextService.new(registry)
	var state := _two_threshold_state_for_m04d3()
	state.reapings.clear()
	var loadout_a := service.loadout_identity(&"FORM_MAN_AT_ARMS", &"WRIT_STANDARD")
	var loadout_b := service.loadout_identity(&"FORM_SCRIBE", &"WRIT_STANDARD")
	assert_ne(loadout_a, loadout_b)
	assert_true(assignment.dispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD").success)
	var gloamwood_first_start: int = state.reapings[&"THR_GLOAMWOOD"].started_simulation_msec
	state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].progress_subunits = 123456
	assert_true(assignment.recall(state, &"THR_GLOAMWOOD", 1).success)
	assert_true(assignment.redispatch(state, &"THR_GLOAMWOOD", &"FORM_SCRIBE", &"WRIT_STANDARD", 2).success)
	state.simulation_time_msec = 1000
	assert_true(assignment.dispatch(state, &"THR_BROKEN_WATCH", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD").success)
	state.thresholds[&"THR_BROKEN_WATCH"].channel_acquisition[&"CHANNEL_BROKEN_WATCH_PROVISIONS"].progress_subunits = 654321
	var watch_first_start: int = state.reapings[&"THR_BROKEN_WATCH"].started_simulation_msec
	assert_true(assignment.recall(state, &"THR_BROKEN_WATCH", 1).success)
	assert_true(assignment.recall(state, &"THR_GLOAMWOOD", 3).success)
	assert_true(assignment.redispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", 4).success)
	assert_eq(state.reapings[&"THR_GLOAMWOOD"].threshold_id, &"THR_GLOAMWOOD")
	assert_eq(state.reapings[&"THR_GLOAMWOOD"].started_simulation_msec, gloamwood_first_start)
	assert_eq(state.reapings[&"THR_BROKEN_WATCH"].started_simulation_msec, watch_first_start)
	assert_eq(state.reapings[&"THR_GLOAMWOOD"].assignment_revision, 5)
	assert_eq(state.reapings[&"THR_BROKEN_WATCH"].assignment_revision, 2)
	assert_eq(state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].progress_subunits, 123456)
	assert_eq(state.thresholds[&"THR_BROKEN_WATCH"].channel_acquisition[&"CHANNEL_BROKEN_WATCH_PROVISIONS"].progress_subunits, 654321)
	assert_eq(service.loadout_identity(state.reapings[&"THR_GLOAMWOOD"].form_id, state.reapings[&"THR_GLOAMWOOD"].writ_id), loadout_a)
	assert_eq(service.output_channel_rate_plan(&"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS", "OVERDUE").effective_rate_subunits_per_period, 1000000)
	assert_eq(service.output_channel_rate_plan(&"THR_GLOAMWOOD", &"FORM_SCRIBE", &"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS", "OVERDUE").effective_rate_subunits_per_period, 1200000)

func _two_threshold_state_for_m04d3() -> GameState:
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
	state.reapings[&"THR_GLOAMWOOD"].is_active = false
	return state
