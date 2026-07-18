extends GutTest

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func _state() -> GameState:
	var state := GameState.new(99999)
	state.progression.command_tether_capacity = 0
	var gloamwood := GameState.ThresholdState.new()
	gloamwood.knowledge_state = &"CHARTED"; gloamwood.availability_state = &"AVAILABLE"; gloamwood.lifecycle_state = &"OVERDUE"; gloamwood.remaining_backlog = 5000
	state.thresholds[&"THR_GLOAMWOOD"] = gloamwood
	var watch := GameState.ThresholdState.new()
	watch.knowledge_state = &"DETECTED"; watch.availability_state = &"LOCKED"; watch.lifecycle_state = &"OVERDUE"; watch.remaining_backlog = 5000
	state.thresholds[&"THR_BROKEN_WATCH"] = watch
	return state

func test_unlock_initializes_available_sources_only_from_zero_and_is_idempotent() -> void:
	var state := _state()
	var service := OutputAccessService.new(_registry())
	var result := service.unlock_output_item(state, &"SOUL_FORM_SCRIBE")
	assert_true(result.success)
	assert_true(result.save_checkpoint_requested)
	assert_eq(state.simulation_time_msec, 99999)
	assert_eq(state.progression.unlocked_output_item_ids, [&"SOUL_FORM_SCRIBE"])
	assert_true(state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition.has(&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"))
	var acquisition = state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"]
	assert_eq(acquisition.progress_subunits, 0)
	assert_eq(acquisition.rate_carry_units, 0)
	assert_eq(acquisition.total_banked_units, 0)
	assert_false(state.thresholds[&"THR_BROKEN_WATCH"].channel_acquisition.has(&"CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS"))
	assert_eq(service.unlock_output_item(state, &"SOUL_FORM_SCRIBE").save_checkpoint_requested, false)

func test_reconcile_later_available_source_and_query_identification() -> void:
	var state := _state()
	var service := OutputAccessService.new(_registry())
	assert_true(service.unlock_output_item(state, &"SOUL_FORM_MAN_AT_ARMS").success)
	state.thresholds[&"THR_BROKEN_WATCH"].availability_state = &"AVAILABLE"
	var reconciled := service.reconcile_available_sources(state)
	assert_true(reconciled.success)
	assert_true(state.thresholds[&"THR_BROKEN_WATCH"].channel_acquisition.has(&"CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS"))
	assert_true(state.thresholds[&"THR_BROKEN_WATCH"].channel_acquisition.has(&"CHANNEL_BROKEN_WATCH_PROVISIONS"))
	assert_false(state.progression.unlocked_output_item_ids.has(&"RES_PROVISIONS"))
	assert_eq(service.reconcile_available_sources(state).save_checkpoint_requested, false)
	var provisions_sources := service.effective_source_identification(state, &"RES_PROVISIONS")
	assert_eq(provisions_sources.size(), 1)
	assert_eq(provisions_sources[0].channel_id, "CHANNEL_BROKEN_WATCH_PROVISIONS")
	var identified := service.effective_source_identification(state, &"SOUL_FORM_MAN_AT_ARMS")
	assert_eq(identified.size(), 1)
	assert_eq(identified[0].discovery_state, "IDENTIFIED")

func test_invalid_and_essence_items_reject_without_mutation() -> void:
	var state := _state()
	var before := state.deep_clone()
	var service := OutputAccessService.new(_registry())
	assert_eq(service.unlock_output_item(state, &"RES_ESSENCE").error_code, OutputAccessService.ERR_ESSENCE_EXCLUDED)
	assert_eq(service.unlock_output_item(state, &"NOPE").error_code, OutputAccessService.ERR_ITEM_NOT_FOUND)
	assert_eq(state.progression.unlocked_output_item_ids, before.progression.unlocked_output_item_ids)


func test_typed_result_summary_and_event_contract() -> void:
	var state := _state()
	var service := OutputAccessService.new(_registry())
	var result := service.unlock_output_item(state, &"SOUL_FORM_SCRIBE")
	assert_true(result.success)
	assert_eq(result.error_code, OutputAccessService.OK)
	assert_not_null(result.change_summary)
	assert_eq(result.change_summary.output_item_id, "SOUL_FORM_SCRIBE")
	assert_true(result.change_summary.access_added)
	assert_false(result.change_summary.already_unlocked)
	assert_eq(result.change_summary.initialized_source_channel_ids, ["CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"])
	assert_eq(result.change_summary.identified_threshold_ids, ["THR_GLOAMWOOD"])
	assert_eq(result.change_summary.simulation_time_msec, state.simulation_time_msec)
	assert_eq(result.events.size(), 2)
	for event in result.events:
		assert_false(event.event_type.is_empty())
		assert_eq(event.occurred_simulation_msec, state.simulation_time_msec)
		assert_false(event.subject_id.is_empty())
		assert_false(event.source_id.is_empty())
		assert_eq(typeof(event.payload), TYPE_DICTIONARY)
		assert_true(event.reportable)
		assert_true(event.tutorial_relevant)
	var failure := service.unlock_output_item(state, &"RES_ESSENCE")
	assert_false(failure.success)
	assert_null(failure.change_summary)
	assert_true(failure.events.is_empty())
	assert_false(failure.save_checkpoint_requested)


func test_access_set_validation_rejects_invalid_ids_and_requires_authored_source() -> void:
	var registry := _registry()
	var cases := [
		{"item_id": &"NOPE", "label": "missing"},
		{"item_id": &"FORM_SCRIBE", "label": "non-item"},
		{"item_id": &"RES_ESSENCE", "label": "Essence"},
		{"item_id": &"STORE_RATIONS", "label": "item with no source"},
	]
	for c in cases:
		var state := _state()
		state.progression.unlocked_output_item_ids = [c.item_id]
		assert_false(GameStateValidator.validate(state, registry).ok, c.label)
	var disabled_registry := _registry()
	disabled_registry._records["SOUL_FORM_SCRIBE"].enabled = false
	var disabled_state := _state()
	disabled_state.progression.unlocked_output_item_ids = [&"SOUL_FORM_SCRIBE"]
	assert_false(GameStateValidator.validate(disabled_state, disabled_registry).ok, "disabled access item")
	var unsorted := _state()
	unsorted.progression.unlocked_output_item_ids = [&"SOUL_FORM_SCRIBE", &"SOUL_CALLING_SOLDIER"]
	assert_false(GameStateValidator.validate(unsorted, registry).ok, "unsorted access")
	var duplicate := _state()
	duplicate.progression.unlocked_output_item_ids = [&"SOUL_CALLING_SOLDIER", &"SOUL_CALLING_SOLDIER"]
	assert_false(GameStateValidator.validate(duplicate, registry).ok, "duplicate access")
	var unavailable_only := _state()
	unavailable_only.progression.unlocked_output_item_ids = [&"SOUL_FORM_MAN_AT_ARMS"]
	assert_true(GameStateValidator.validate(unavailable_only, registry).ok, "valid unlock with only unavailable source")
	var clone := unavailable_only.deep_clone()
	clone.progression.unlocked_output_item_ids.append(&"SOUL_FORM_SCRIBE")
	assert_eq(unavailable_only.progression.unlocked_output_item_ids, [&"SOUL_FORM_MAN_AT_ARMS"])

func test_access_source_consistency_complete_and_transitional_modes() -> void:
	var registry := _registry()
	var missing_non_gated := _state()
	missing_non_gated.thresholds[&"THR_BROKEN_WATCH"].availability_state = &"AVAILABLE"
	assert_false(GameStateValidator.validate(missing_non_gated, registry, true).ok, "strict requires available non-gated Provisions")
	assert_true(GameStateValidator.validate(missing_non_gated, registry, false).ok, "pre-reconcile mode accepts missing source")
	var reconciled := OutputAccessService.new(registry).reconcile_available_sources(missing_non_gated)
	assert_true(reconciled.success)
	assert_true(missing_non_gated.thresholds[&"THR_BROKEN_WATCH"].channel_acquisition.has(&"CHANNEL_BROKEN_WATCH_PROVISIONS"))
	assert_false(missing_non_gated.progression.unlocked_output_item_ids.has(&"RES_PROVISIONS"))
	assert_true(GameStateValidator.validate(missing_non_gated, registry, true).ok)
	var gated_without_access := _state()
	gated_without_access.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"] = GameState.ThresholdAcquisitionState.new(0, 0, 0)
	assert_false(GameStateValidator.validate(gated_without_access, registry, true).ok, "gated acquisition requires access")
	var unavailable_acq := _state()
	unavailable_acq.progression.unlocked_output_item_ids = [&"SOUL_FORM_MAN_AT_ARMS"]
	unavailable_acq.thresholds[&"THR_BROKEN_WATCH"].channel_acquisition[&"CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS"] = GameState.ThresholdAcquisitionState.new(0, 0, 0)
	assert_false(GameStateValidator.validate(unavailable_acq, registry, true).ok, "strict rejects acquisition on unavailable Threshold")
	var missing_gated := _state()
	missing_gated.progression.unlocked_output_item_ids = [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"]
	missing_gated.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"] = GameState.ThresholdAcquisitionState.new(250000, 10, 1)
	assert_false(GameStateValidator.validate(missing_gated, registry, true).ok, "strict requires unlocked available gated source")

func test_command_failures_preserve_canonical_state_and_contract() -> void:
	var registry := _registry()
	var cases := [
		{"item_id": &"NOPE", "code": OutputAccessService.ERR_ITEM_NOT_FOUND, "registry": registry, "state": _state()},
		{"item_id": &"FORM_SCRIBE", "code": OutputAccessService.ERR_ITEM_NOT_FOUND, "registry": registry, "state": _state()},
		{"item_id": &"RES_ESSENCE", "code": OutputAccessService.ERR_ESSENCE_EXCLUDED, "registry": registry, "state": _state()},
		{"item_id": &"STORE_RATIONS", "code": OutputAccessService.ERR_NO_AUTHORED_SOURCE, "registry": registry, "state": _state()},
	]
	var disabled_registry := _registry()
	disabled_registry._records["SOUL_FORM_SCRIBE"].enabled = false
	cases.append({"item_id": &"SOUL_FORM_SCRIBE", "code": OutputAccessService.ERR_ITEM_DISABLED, "registry": disabled_registry, "state": _state()})
	var disabled_channel_registry := _registry()
	disabled_channel_registry._records["CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].enabled = false
	cases.append({"item_id": &"SOUL_FORM_SCRIBE", "code": OutputAccessService.ERR_CHANNEL_INVALID, "registry": disabled_channel_registry, "state": _state()})
	var misowned_registry := _registry()
	misowned_registry._records["CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].source_threshold_id = "THR_BROKEN_WATCH"
	cases.append({"item_id": &"SOUL_FORM_SCRIBE", "code": OutputAccessService.ERR_CHANNEL_OWNERSHIP_INVALID, "registry": misowned_registry, "state": _state()})
	var invalid_state := _state()
	invalid_state.progression.command_tether_capacity = -1
	cases.append({"item_id": &"SOUL_FORM_SCRIBE", "code": OutputAccessService.ERR_STATE_INVALID, "registry": registry, "state": invalid_state})
	for c in cases:
		var before := _canonical_snapshot(c.state, c.registry)
		var result := OutputAccessService.new(c.registry).unlock_output_item(c.state, c.item_id)
		assert_false(result.success, "failure expected for %s" % c.item_id)
		assert_eq(result.error_code, c.code)
		assert_ne(result.developer_details, "")
		assert_null(result.change_summary)
		assert_true(result.events.is_empty())
		assert_false(result.save_checkpoint_requested)
		assert_eq(_canonical_snapshot(c.state, c.registry), before)
	var null_result := OutputAccessService.new(registry).unlock_output_item(null, &"SOUL_FORM_SCRIBE")
	assert_false(null_result.success)
	assert_eq(null_result.error_code, OutputAccessService.ERR_STATE_INVALID)
	var unready := ContentRegistry.new()
	var unready_result := OutputAccessService.new(unready).unlock_output_item(_state(), &"SOUL_FORM_SCRIBE")
	assert_false(unready_result.success)
	assert_eq(unready_result.error_code, OutputAccessService.ERR_STATE_INVALID)

func test_success_zero_and_multiple_source_order_query_and_idempotency() -> void:
	var registry := _registry()
	var zero_source := _state()
	zero_source.thresholds[&"THR_GLOAMWOOD"].availability_state = &"LOCKED"
	var zero_result := OutputAccessService.new(registry).unlock_output_item(zero_source, &"SOUL_FORM_SCRIBE")
	assert_true(zero_result.success)
	assert_true(zero_result.change_summary.initialized_source_channel_ids.is_empty())
	assert_true(zero_result.change_summary.identified_threshold_ids.is_empty())
	assert_eq(zero_result.events.size(), 1)
	assert_true(OutputAccessService.new(registry).effective_source_identification(zero_source, &"SOUL_FORM_SCRIBE").is_empty())
	var multi := _state()
	multi.thresholds[&"THR_BROKEN_WATCH"].availability_state = &"AVAILABLE"
	multi.progression.unlocked_output_item_ids = [&"SOUL_CALLING_SOLDIER"]
	var before_progress := GameState.ThresholdAcquisitionState.new(250000, 10, 1)
	multi.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"] = before_progress
	var unlock := OutputAccessService.new(registry).unlock_output_item(multi, &"SOUL_FORM_MAN_AT_ARMS")
	assert_true(unlock.success)
	assert_eq(unlock.change_summary.initialized_source_channel_ids, ["CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS", "CHANNEL_BROKEN_WATCH_PROVISIONS"])
	assert_eq(unlock.change_summary.identified_threshold_ids, ["THR_BROKEN_WATCH"])
	var reconcile := OutputAccessService.new(registry).reconcile_available_sources(multi)
	assert_true(reconcile.success)
	assert_true(reconcile.change_summary.initialized_source_channel_ids.is_empty())
	assert_eq(multi.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].progress_subunits, 250000)
	assert_eq(multi.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].rate_carry_units, 10)
	assert_eq(multi.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].total_banked_units, 1)
	assert_false(OutputAccessService.new(registry).reconcile_available_sources(multi).save_checkpoint_requested)

func _canonical_snapshot(state: GameState, registry: ContentRegistry) -> Dictionary:
	if state == null:
		return {}
	return SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, registry.content_revision).game_state
