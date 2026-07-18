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
	assert_true(result.ok)
	assert_true(result.checkpoint_requested)
	assert_eq(state.simulation_time_msec, 99999)
	assert_eq(state.progression.unlocked_output_item_ids, [&"SOUL_FORM_SCRIBE"])
	assert_true(state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition.has(&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"))
	var acquisition = state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"]
	assert_eq(acquisition.progress_subunits, 0)
	assert_eq(acquisition.rate_carry_units, 0)
	assert_eq(acquisition.total_banked_units, 0)
	assert_false(state.thresholds[&"THR_BROKEN_WATCH"].channel_acquisition.has(&"CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS"))
	assert_eq(service.unlock_output_item(state, &"SOUL_FORM_SCRIBE").checkpoint_requested, false)

func test_reconcile_later_available_source_and_query_identification() -> void:
	var state := _state()
	var service := OutputAccessService.new(_registry())
	assert_true(service.unlock_output_item(state, &"SOUL_FORM_MAN_AT_ARMS").ok)
	state.thresholds[&"THR_BROKEN_WATCH"].availability_state = &"AVAILABLE"
	var reconciled := service.reconcile_available_sources(state)
	assert_true(reconciled.ok)
	assert_true(state.thresholds[&"THR_BROKEN_WATCH"].channel_acquisition.has(&"CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS"))
	assert_eq(service.reconcile_available_sources(state).checkpoint_requested, false)
	var identified := service.effective_source_identification(state, &"SOUL_FORM_MAN_AT_ARMS")
	assert_eq(identified.size(), 1)
	assert_eq(identified[0].discovery_state, "IDENTIFIED")

func test_invalid_and_essence_items_reject_without_mutation() -> void:
	var state := _state()
	var before := state.deep_clone()
	var service := OutputAccessService.new(_registry())
	assert_eq(service.unlock_output_item(state, &"RES_ESSENCE").code, OutputAccessService.ERR_ESSENCE_EXCLUDED)
	assert_eq(service.unlock_output_item(state, &"NOPE").code, OutputAccessService.ERR_ITEM_NOT_FOUND)
	assert_eq(state.progression.unlocked_output_item_ids, before.progression.unlocked_output_item_ids)
