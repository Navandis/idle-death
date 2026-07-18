extends GutTest

const HOUR := 3600000

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func _engine() -> SimulationEngine:
	return SimulationEngine.new(_registry())

func _state(threshold_id: StringName = &"THR_GLOAMWOOD", active := true, backlog := 1000000) -> GameState:
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
	var service := OutputAccessService.new(_registry())
	for item_id in item_ids:
		assert_true(service.unlock_output_item(state, item_id).success)
	assert_true(service.reconcile_available_sources(state).success)

func test_content_revision_and_settled_multipliers() -> void:
	var registry := _registry()
	assert_eq(registry.content_revision, "prototype-content-r2")
	assert_eq(registry.compatible_save_revisions, ["prototype-content-r1", "prototype-content-r2", "prototype-m02"])
	for id in ["CHANNEL_GLOAMWOOD_SOLDIER_SOULS", "CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS", "CHANNEL_BROKEN_WATCH_PROVISIONS", "CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS"]:
		assert_eq(registry.get_record(id).record.settled_multiplier_subunits, FixedPoint.SCALE, id)
	assert_eq(registry.get_record("CHANNEL_GLOAMWOOD_ESSENCE").record.settled_multiplier_subunits, 250000)
	assert_eq(registry.get_record("THR_GLOAMWOOD").record.settled_multiplier_subunits, 250000)

func test_gloamwood_exact_fixtures_and_result_contract() -> void:
	var two := _state()
	_unlock_and_init(two, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	two.inventory.entries[&"SOUL_CALLING_SOLDIER"] = GameState.InventoryEntryState.new(0, {&"RET_TEST": 0})
	var result := _engine().resolve_elapsed(two, 2 * HOUR)
	assert_true(result.success, result.developer_details)
	assert_eq(two.inventory.entries[&"SOUL_CALLING_SOLDIER"].total, 24)
	assert_eq(two.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].progress_subunits, 250000)
	assert_eq(result.change_summary.channel_deltas.size(), 2)
	assert_eq(result.events[0].event_type, SimulationEngine.EVENT_OUTPUT_CHANNEL_BANKED)
	assert_eq(result.events[0].payload.quantity, 24)
	var eight := _state()
	_unlock_and_init(eight, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	assert_true(_engine().resolve_elapsed(eight, 8 * HOUR).success)
	assert_eq(eight.inventory.entries[&"SOUL_CALLING_SOLDIER"].total, 96)
	assert_eq(eight.inventory.entries[&"SOUL_FORM_SCRIBE"].total, 1)
	assert_eq(eight.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].progress_subunits, 0)
	assert_eq(eight.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].total_banked_units, 1)

func test_broken_watch_exact_fixtures() -> void:
	var six := _state(&"THR_BROKEN_WATCH", true, 250000)
	_unlock_and_init(six, [&"SOUL_FORM_MAN_AT_ARMS"])
	assert_true(_engine().resolve_elapsed(six, 6 * HOUR).success)
	assert_eq(six.inventory.entries[&"RES_PROVISIONS"].total, 720)
	assert_eq(six.thresholds[&"THR_BROKEN_WATCH"].channel_acquisition[&"CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS"].progress_subunits, 250000)
	var full := _state(&"THR_BROKEN_WATCH", true, 250000)
	_unlock_and_init(full, [&"SOUL_FORM_MAN_AT_ARMS"])
	assert_true(_engine().resolve_elapsed(full, 24 * HOUR).success)
	assert_eq(full.inventory.entries[&"RES_PROVISIONS"].total, 2880)
	assert_eq(full.inventory.entries[&"SOUL_FORM_MAN_AT_ARMS"].total, 1)

func test_locked_missing_inactive_chunk_and_late_unlock_behaviors() -> void:
	var locked := _state()
	_unlock_and_init(locked, [&"SOUL_CALLING_SOLDIER"])
	assert_true(_engine().resolve_elapsed(locked, 6 * HOUR).success)
	assert_false(locked.thresholds[&"THR_GLOAMWOOD"].channel_acquisition.has(&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"))
	assert_false(locked.inventory.entries.has(&"SOUL_FORM_SCRIBE"))
	var missing := _state(&"THR_BROKEN_WATCH", true, 250000)
	var before := _canonical(missing)
	var fail := _engine().resolve_elapsed(missing, 1000)
	assert_false(fail.success)
	assert_eq(fail.error_code, SimulationEngine.ERR_STATE_INVALID)
	assert_eq(_canonical(missing), before)
	var late := _state()
	_unlock_and_init(late, [&"SOUL_CALLING_SOLDIER"])
	assert_true(_engine().resolve_elapsed(late, 6 * HOUR).success)
	assert_true(OutputAccessService.new(_registry()).unlock_output_item(late, &"SOUL_FORM_SCRIBE").success)
	assert_true(_engine().resolve_elapsed(late, 2 * HOUR).success)
	assert_false(late.inventory.entries.has(&"SOUL_FORM_SCRIBE"))
	assert_eq(late.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].progress_subunits, 250000)
	var one := _state(); _unlock_and_init(one, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	var chunks := _state(); _unlock_and_init(chunks, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	assert_true(_engine().resolve_elapsed(one, 8 * HOUR).success)
	for elapsed in [1 * HOUR, 1234567, 2 * HOUR, 4 * HOUR, 2365433]: assert_true(_engine().resolve_elapsed(chunks, elapsed).success)
	assert_eq(_canonical(chunks), _canonical(one))

func test_recall_freezes_and_same_loadout_resumes() -> void:
	var state := _state()
	_unlock_and_init(state, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	assert_true(_engine().resolve_elapsed(state, 2 * HOUR).success)
	state.reapings[&"THR_GLOAMWOOD"].is_active = false
	var frozen := _canonical(state)
	assert_true(_engine().resolve_elapsed(state, 6 * HOUR).success)
	assert_eq(_canonical(state).thresholds, frozen.thresholds)
	state.reapings[&"THR_GLOAMWOOD"].is_active = true
	state.reapings[&"THR_GLOAMWOOD"].assignment_revision += 1
	assert_true(_engine().resolve_elapsed(state, 6 * HOUR).success)
	assert_eq(state.inventory.entries[&"SOUL_FORM_SCRIBE"].total, 1)

func _canonical(state: GameState) -> Dictionary:
	return SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION).game_state
