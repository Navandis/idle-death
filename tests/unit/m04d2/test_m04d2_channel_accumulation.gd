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

func test_channel_bank_after_settlement_uses_segment_end_cursor() -> void:
	var state := _state(&"THR_GLOAMWOOD", true, 1)
	_unlock_and_init(state, [&"SOUL_CALLING_SOLDIER"])
	state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].progress_subunits = 997099
	var result := _engine().resolve_elapsed(state, 871)
	assert_true(result.success, result.developer_details)
	assert_eq(result.events.size(), 2)
	assert_eq(result.events[0].event_type, SimulationEngine.EVENT_THRESHOLD_SETTLED)
	assert_eq(result.events[0].occurred_simulation_msec, 870)
	assert_eq(result.events[1].event_type, SimulationEngine.EVENT_OUTPUT_CHANNEL_BANKED)
	assert_eq(result.events[1].occurred_simulation_msec, 871)
	assert_eq(result.events[1].payload.lifecycle_state, "SETTLED")
	assert_eq(state.inventory.entries[&"SOUL_CALLING_SOLDIER"].total, 1)

func _canonical(state: GameState) -> Dictionary:
	return SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION).game_state

func test_strict_commit_rejects_transitional_candidate_and_preserves_live_state() -> void:
	var live := _state()
	_unlock_and_init(live, [&"SOUL_CALLING_SOLDIER"])
	var candidate := live.deep_clone()
	var hidden := GameState.ThresholdState.new()
	hidden.knowledge_state = &"CHARTED"
	hidden.availability_state = &"LOCKED"
	hidden.lifecycle_state = &"OVERDUE"
	hidden.remaining_backlog = 250000
	hidden.channel_acquisition[&"CHANNEL_BROKEN_WATCH_PROVISIONS"] = GameState.ThresholdAcquisitionState.new(0, 0, 0)
	candidate.thresholds[&"THR_BROKEN_WATCH"] = hidden
	var before := _canonical(live)
	var optimistic := SimulationEngine.SimulationResult.new(true, SimulationEngine.OK, "", 1)
	optimistic.committed_elapsed_msec = 1
	var result := _engine()._commit_if_valid(live, candidate, optimistic)
	_assert_failure_no_mutation(result, SimulationEngine.ERR_STATE_INVALID, before, live)

func test_eligibility_and_transaction_matrix() -> void:
	var idle := _state(&"THR_GLOAMWOOD", false, 1000000)
	idle.reapings.clear()
	_unlock_and_init(idle, [&"SOUL_CALLING_SOLDIER"])
	var idle_before := _canonical(idle)
	var idle_result := _engine().resolve_elapsed(idle, 1234)
	assert_true(idle_result.success, idle_result.developer_details)
	assert_eq(idle_result.committed_elapsed_msec, 1234)
	assert_eq(idle_result.segments, [])
	assert_eq(idle_result.events, [])
	var idle_after := _canonical(idle)
	assert_eq(idle_after.simulation_time_msec, "1234")
	idle_after.simulation_time_msec = idle_before.simulation_time_msec
	assert_eq(idle_after, idle_before)

	var inactive := _state(&"THR_GLOAMWOOD", false, 1000000)
	_unlock_and_init(inactive, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	var acq: GameState.ThresholdAcquisitionState = inactive.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"]
	acq.progress_subunits = 123456
	acq.rate_carry_units = 777
	acq.total_banked_units = 2
	inactive.inventory.entries[&"SOUL_FORM_SCRIBE"] = GameState.InventoryEntryState.new(2, {&"RET_TEST": 1})
	var frozen := _canonical(inactive)
	var inactive_result := _engine().resolve_elapsed(inactive, 5000)
	assert_true(inactive_result.success, inactive_result.developer_details)
	assert_eq(inactive_result.segments, [])
	assert_eq(inactive_result.events, [])
	var thawed := _canonical(inactive)
	assert_eq(thawed.simulation_time_msec, "5000")
	thawed.simulation_time_msec = frozen.simulation_time_msec
	assert_eq(thawed, frozen)

	var locked := _state(&"THR_GLOAMWOOD", true, 1000000)
	_unlock_and_init(locked, [&"SOUL_CALLING_SOLDIER"])
	var locked_result := _engine().resolve_elapsed(locked, 6 * HOUR)
	assert_true(locked_result.success, locked_result.developer_details)
	assert_false(locked.thresholds[&"THR_GLOAMWOOD"].channel_acquisition.has(&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"))
	assert_false(locked.inventory.entries.has(&"SOUL_FORM_SCRIBE"))
	assert_eq(locked_result.change_summary.channel_deltas.size(), 1)
	assert_eq(locked_result.events.size(), 1)

	var missing := _state(&"THR_GLOAMWOOD", true, 1000000)
	missing.progression.unlocked_output_item_ids.append(&"SOUL_CALLING_SOLDIER")
	var missing_before := _canonical(missing)
	_assert_failure_no_mutation(_engine().resolve_elapsed(missing, 1000), SimulationEngine.ERR_STATE_INVALID, missing_before, missing)

	var retinue := _state()
	_unlock_and_init(retinue, [&"SOUL_CALLING_SOLDIER"])
	retinue.reapings[&"THR_GLOAMWOOD"].retinue_ids.append(&"RET_SOLDIER_COMPANY")
	_assert_failure_no_mutation(_engine().resolve_elapsed(retinue, 1000), SimulationEngine.ERR_UNSUPPORTED_RETINUE, _canonical(retinue), retinue)

	var two_active := _state()
	_unlock_and_init(two_active, [&"SOUL_CALLING_SOLDIER"])
	two_active.progression.command_tether_capacity = 2
	var watch := GameState.ThresholdState.new()
	watch.knowledge_state = &"CHARTED"
	watch.availability_state = &"AVAILABLE"
	watch.lifecycle_state = &"OVERDUE"
	watch.remaining_backlog = 250000
	two_active.thresholds[&"THR_BROKEN_WATCH"] = watch
	two_active.forms[&"FORM_SCRIBE"] = GameState.FormState.new(true, true, 0, &"TEST")
	assert_true(OutputAccessService.new(_registry()).reconcile_available_sources(two_active).success)
	var second := GameState.ReapingState.new()
	second.threshold_id = &"THR_BROKEN_WATCH"
	second.is_active = true
	second.form_id = &"FORM_SCRIBE"
	second.writ_id = &"WRIT_STANDARD"
	second.assignment_revision = 1
	two_active.reapings[&"THR_BROKEN_WATCH"] = second
	_assert_failure_no_mutation(_engine().resolve_elapsed(two_active, 1000), SimulationEngine.ERR_UNSUPPORTED_CONCURRENCY, _canonical(two_active), two_active)

func test_accumulation_chunking_history_and_source_ownership_matrix() -> void:
	var carry := _state()
	_unlock_and_init(carry, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	var scribe: GameState.ThresholdAcquisitionState = carry.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"]
	scribe.progress_subunits = 999999
	scribe.rate_carry_units = 28799999
	var carry_result := _engine().resolve_elapsed(carry, 1)
	assert_true(carry_result.success, carry_result.developer_details)
	assert_eq(carry.inventory.entries[&"SOUL_FORM_SCRIBE"].total, 1)
	scribe = carry.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"]
	assert_eq(scribe.progress_subunits, 0)
	assert_eq(scribe.rate_carry_units, 999999)
	assert_eq(scribe.total_banked_units, 1)

	var multi := _state(&"THR_BROKEN_WATCH", true, 250000)
	_unlock_and_init(multi, [&"SOUL_FORM_MAN_AT_ARMS"])
	var multi_result := _engine().resolve_elapsed(multi, 3 * HOUR)
	assert_true(multi_result.success, multi_result.developer_details)
	assert_eq(multi.inventory.entries[&"RES_PROVISIONS"].total, 360)
	assert_eq(_events_of_type(multi_result, SimulationEngine.EVENT_OUTPUT_CHANNEL_BANKED).size(), 1)
	assert_eq(_events_of_type(multi_result, SimulationEngine.EVENT_OUTPUT_CHANNEL_BANKED)[0].payload.quantity, 360)

	var channels := _state()
	_unlock_and_init(channels, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	var channels_result := _engine().resolve_elapsed(channels, 8 * HOUR)
	assert_true(channels_result.success, channels_result.developer_details)
	assert_eq(channels.inventory.entries[&"SOUL_CALLING_SOLDIER"].total, 96)
	assert_eq(channels.inventory.entries[&"SOUL_FORM_SCRIBE"].total, 1)
	assert_eq(channels.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].total_banked_units, 96)
	assert_eq(channels.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].total_banked_units, 1)

	var one := _state()
	var regular := _state()
	var irregular := _state()
	for st in [one, regular, irregular]:
		_unlock_and_init(st, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	assert_true(_engine().resolve_elapsed(one, 8 * HOUR).success)
	for _i in range(8): assert_true(_engine().resolve_elapsed(regular, HOUR).success)
	for elapsed in [1, 999999, 1234567, 7654321, 1799999, 15308643, 1802470]: assert_true(_engine().resolve_elapsed(irregular, elapsed).success)
	assert_eq(_canonical(regular), _canonical(one))
	assert_eq(_canonical(irregular), _canonical(one))
	for acq_value in channels.thresholds[&"THR_GLOAMWOOD"].channel_acquisition.values():
		assert_lt(acq_value.progress_subunits, FixedPoint.SCALE)
		assert_gte(acq_value.progress_subunits, 0)

	assert_false(channels.thresholds[&"THR_GLOAMWOOD"].channel_acquisition.has(&"CHANNEL_GLOAMWOOD_ESSENCE"))
	assert_true(channels.reapings[&"THR_GLOAMWOOD"].flow_carry_units.has(SimulationEngine.FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS))

func test_settlement_channel_specific_rates_and_event_ordering_contracts() -> void:
	var boundary := _state(&"THR_GLOAMWOOD", true, 1)
	_unlock_and_init(boundary, [&"SOUL_CALLING_SOLDIER"])
	boundary.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].progress_subunits = 997100
	var boundary_result := _engine().resolve_elapsed(boundary, 870)
	assert_true(boundary_result.success, boundary_result.developer_details)
	assert_eq(boundary_result.events.size(), 2)
	assert_eq(boundary_result.events[0].event_type, SimulationEngine.EVENT_OUTPUT_CHANNEL_BANKED)
	assert_eq(boundary_result.events[0].occurred_simulation_msec, 870)
	assert_eq(boundary_result.events[0].priority, SimulationEngine.EVENT_PRIORITY_CHANNEL_GAIN)
	assert_eq(boundary_result.events[1].event_type, SimulationEngine.EVENT_THRESHOLD_SETTLED)
	assert_eq(boundary_result.events[1].occurred_simulation_msec, 870)

	var same_time := _state()
	_unlock_and_init(same_time, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	same_time.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].progress_subunits = 999999
	var same_scribe: GameState.ThresholdAcquisitionState = same_time.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"]
	same_scribe.progress_subunits = 999999
	same_scribe.rate_carry_units = 28799999
	var same_result := _engine().resolve_elapsed(same_time, 1)
	assert_true(same_result.success, same_result.developer_details)
	var bank_events := _events_of_type(same_result, SimulationEngine.EVENT_OUTPUT_CHANNEL_BANKED)
	assert_eq(bank_events.size(), 2)
	assert_eq(bank_events[0].subject_id, "THR_GLOAMWOOD")
	assert_eq(bank_events[0].source_id, "CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS")
	assert_eq(bank_events[1].source_id, "CHANNEL_GLOAMWOOD_SOLDIER_SOULS")
	for event in bank_events:
		assert_eq(event.event_type, SimulationEngine.EVENT_OUTPUT_CHANNEL_BANKED)
		assert_eq(event.occurred_simulation_msec, 1)
		assert_eq(event.priority, SimulationEngine.EVENT_PRIORITY_CHANNEL_GAIN)
		assert_true(event.reportable)
		assert_true(event.tutorial_relevant)
		assert_true(event.payload.has("quantity"))
		assert_true(event.payload.has("output_item_id"))
		assert_true(event.payload.has("lifecycle_state"))

	var half_registry := _copied_registry_with_channel(&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS", 1.0, 1000, 0.5)
	var half_engine := SimulationEngine.new(half_registry)
	var half_one := _state(&"THR_GLOAMWOOD", true, 1)
	_unlock_and_init_with_registry(half_one, half_registry, [&"SOUL_CALLING_SOLDIER"])
	var half_result := half_engine.resolve_elapsed(half_one, 2000)
	assert_true(half_result.success, half_result.developer_details)
	assert_eq(half_result.segments.size(), 2)
	assert_eq(half_result.segments[0].lifecycle, "OVERDUE")
	assert_eq(half_result.segments[0].elapsed_msec, 870)
	assert_eq(half_result.segments[0].channel_deltas[0].progress_subunits_after, 870000)
	assert_eq(half_result.segments[1].lifecycle, "SETTLED")
	assert_eq(half_result.segments[1].elapsed_msec, 1130)
	assert_eq(half_result.segments[1].channel_deltas[0].banked_units_delta, 1)
	var half_acq: GameState.ThresholdAcquisitionState = half_one.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"]
	assert_eq(half_one.inventory.entries[&"SOUL_CALLING_SOLDIER"].total, 1)
	assert_eq(half_acq.progress_subunits, 435000)
	assert_eq(half_acq.rate_carry_units, 0)

	var half_chunks := _state(&"THR_GLOAMWOOD", true, 1)
	_unlock_and_init_with_registry(half_chunks, half_registry, [&"SOUL_CALLING_SOLDIER"])
	assert_true(half_engine.resolve_elapsed(half_chunks, 870).success)
	assert_true(half_engine.resolve_elapsed(half_chunks, 1130).success)
	assert_eq(_canonical(half_chunks), _canonical(half_one))

func test_inventory_delta_and_failure_matrix() -> void:
	var progress_only := _state()
	_unlock_and_init(progress_only, [&"SOUL_FORM_SCRIBE"])
	var progress_result := _engine().resolve_elapsed(progress_only, 2 * HOUR)
	assert_true(progress_result.success, progress_result.developer_details)
	assert_false(progress_only.inventory.entries.has(&"SOUL_FORM_SCRIBE"))
	assert_eq(_events_of_type(progress_result, SimulationEngine.EVENT_OUTPUT_CHANNEL_BANKED).size(), 0)
	var delta: Dictionary = progress_result.change_summary.channel_deltas[0]
	for field in ["channel_id", "output_item_id", "banked_units_delta", "progress_subunits_before", "progress_subunits_after", "rate_carry_units_before", "rate_carry_units_after", "total_banked_units_before", "total_banked_units_after"]:
		assert_true(delta.has(field), field)
	assert_eq(delta.banked_units_delta, 0)

	var reserved := _state()
	_unlock_and_init(reserved, [&"SOUL_CALLING_SOLDIER"])
	reserved.inventory.entries[&"SOUL_CALLING_SOLDIER"] = GameState.InventoryEntryState.new(10, {&"RET_SOLDIER_COMPANY": 4})
	var reserved_before: Dictionary = reserved.inventory.entries[&"SOUL_CALLING_SOLDIER"].reservations.duplicate(true)
	assert_true(_engine().resolve_elapsed(reserved, HOUR).success)
	assert_eq(reserved.inventory.entries[&"SOUL_CALLING_SOLDIER"].total, 22)
	assert_eq(reserved.inventory.entries[&"SOUL_CALLING_SOLDIER"].reservations, reserved_before)

	var failures := []
	var time_overflow := _state(); _unlock_and_init(time_overflow, [&"SOUL_CALLING_SOLDIER"]); time_overflow.simulation_time_msec = FixedPoint.INT64_MAX - 10; failures.append([time_overflow, 11, SimulationEngine.ERR_OVERFLOW])
	var inventory_overflow := _state(); _unlock_and_init(inventory_overflow, [&"SOUL_CALLING_SOLDIER"]); inventory_overflow.inventory.entries[&"SOUL_CALLING_SOLDIER"] = GameState.InventoryEntryState.new(FixedPoint.INT64_MAX); inventory_overflow.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].progress_subunits = 999999; failures.append([inventory_overflow, 1, SimulationEngine.ERR_OVERFLOW])
	var banked_overflow := _state(); _unlock_and_init(banked_overflow, [&"SOUL_CALLING_SOLDIER"]); banked_overflow.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].progress_subunits = 999999; banked_overflow.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].total_banked_units = FixedPoint.INT64_MAX; failures.append([banked_overflow, 1, SimulationEngine.ERR_OVERFLOW])
	var bad_carry := _state(); _unlock_and_init(bad_carry, [&"SOUL_CALLING_SOLDIER"]); bad_carry.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].rate_carry_units = 300000; failures.append([bad_carry, 1, SimulationEngine.ERR_STATE_INVALID])
	var bad_progress := _state(); _unlock_and_init(bad_progress, [&"SOUL_CALLING_SOLDIER"]); bad_progress.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].progress_subunits = FixedPoint.SCALE; failures.append([bad_progress, 1, SimulationEngine.ERR_STATE_INVALID])
	for case in failures:
		_assert_failure_no_mutation(_engine().resolve_elapsed(case[0], case[1]), case[2], _canonical(case[0]), case[0])

func _unlock_and_init_with_registry(state: GameState, registry: ContentRegistry, item_ids: Array[StringName]) -> void:
	var service := OutputAccessService.new(registry)
	for item_id in item_ids:
		assert_true(service.unlock_output_item(state, item_id).success)
	assert_true(service.reconcile_available_sources(state).success)

func _copied_registry_with_channel(channel_id: StringName, amount_per_period: float, period_msec: int, settled_multiplier: float) -> ContentRegistry:
	var catalog: ContentCatalog = load("res://content/prototype_content_catalog.tres").duplicate(true)
	for i in range(catalog.output_channels.size()):
		if StringName(catalog.output_channels[i].id) == channel_id:
			var channel: OutputChannelDefinition = catalog.output_channels[i].duplicate(true)
			channel.rate = channel.rate.duplicate(true)
			channel.rate.amount_per_period = amount_per_period
			channel.rate.period_msec = period_msec
			channel.settled_multiplier = settled_multiplier
			catalog.output_channels[i] = channel
			break
	return ContentRegistry.build(catalog)

func _events_of_type(result: SimulationEngine.SimulationResult, event_type: String) -> Array:
	var found := []
	for event in result.events:
		if event.event_type == event_type:
			found.append(event)
	return found

func _assert_failure_no_mutation(result: SimulationEngine.SimulationResult, expected_code: String, before: Dictionary, state: GameState) -> void:
	assert_false(result.success, result.developer_details)
	assert_eq(result.error_code, expected_code)
	assert_eq(result.committed_elapsed_msec, 0)
	assert_eq(result.segments, [])
	assert_eq(result.events, [])
	assert_true(result.change_summary.is_empty())
	assert_ne(result.developer_details, "")
	assert_eq(_canonical(state), before)
