extends GutTest

func test_schema_v3_round_trips_channel_accumulation_without_result_artifacts() -> void:
	var registry := ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
	var state := GameState.new(0)
	state.progression.command_tether_capacity = 1
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
	var threshold := GameState.ThresholdState.new()
	threshold.knowledge_state = &"CHARTED"; threshold.availability_state = &"AVAILABLE"; threshold.lifecycle_state = &"OVERDUE"; threshold.remaining_backlog = 1000000
	state.thresholds[&"THR_GLOAMWOOD"] = threshold
	var reaping := GameState.ReapingState.new()
	reaping.threshold_id = &"THR_GLOAMWOOD"; reaping.is_active = true; reaping.form_id = &"FORM_MAN_AT_ARMS"; reaping.writ_id = &"WRIT_STANDARD"; reaping.assignment_revision = 1
	state.reapings[&"THR_GLOAMWOOD"] = reaping
	var access := OutputAccessService.new(registry)
	assert_true(access.unlock_output_item(state, &"SOUL_CALLING_SOLDIER").success)
	assert_true(access.unlock_output_item(state, &"SOUL_FORM_SCRIBE").success)
	var result := SimulationEngine.new(registry).resolve_elapsed(state, 7200000)
	assert_true(result.success, result.developer_details)
	var storage := MemorySaveStorage.new()
	var files := SaveFileSet.new("user://ignored", "m04d2")
	var service := SaveService.new(storage, files)
	assert_true(service.save_runtime(state, TimeAuthorityState.new(), 3, registry.content_revision).ok)
	var decoded := JsonSaveCodec.new().decode(storage.files[files.primary_path])
	assert_true(decoded.ok)
	assert_eq(decoded.snapshot.schema_version, "4")
	assert_eq(decoded.snapshot.content_revision, "prototype-content-r2")
	assert_false(str(decoded.snapshot).find("OUTPUT_CHANNEL_BANKED") >= 0)
	assert_false(str(decoded.snapshot).find("channel_deltas") >= 0)
	var loaded := service.load_runtime()
	assert_true(loaded.ok)
	assert_eq(SaveSchemaMapper.runtime_to_snapshot(loaded.game_state, loaded.time_authority_state, loaded.save_revision, registry.content_revision).game_state, SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 3, registry.content_revision).game_state)

func test_revision_one_save_fixture_remains_compatible_under_revision_two_registry() -> void:
	var registry := ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
	assert_true(registry.is_save_revision_compatible("prototype-content-r1"))
	assert_true(registry.is_save_revision_compatible("prototype-content-r2"))
	assert_true(registry.is_save_revision_compatible("prototype-m02"))

func test_coordinator_round_trips_produced_boundary_settled_inactive_and_reservations() -> void:
	var registry := ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
	var scenarios := []
	var overdue := _m04d2_state(&"THR_GLOAMWOOD", true, 1000000)
	_unlock_with_registry(overdue, registry, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	assert_true(SimulationEngine.new(registry).resolve_elapsed(overdue, 7200000).success)
	scenarios.append(overdue)
	var boundary := _m04d2_state(&"THR_GLOAMWOOD", true, 1)
	_unlock_with_registry(boundary, registry, [&"SOUL_CALLING_SOLDIER"])
	boundary.inventory.entries[&"SOUL_CALLING_SOLDIER"] = GameState.InventoryEntryState.new(5, {&"RET_SOLDIER_COMPANY": 3})
	assert_true(SimulationEngine.new(registry).resolve_elapsed(boundary, 871).success)
	scenarios.append(boundary)
	var settled := _m04d2_state(&"THR_GLOAMWOOD", true, 0)
	_unlock_with_registry(settled, registry, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	assert_true(SimulationEngine.new(registry).resolve_elapsed(settled, 28800000).success)
	scenarios.append(settled)
	var inactive := _m04d2_state(&"THR_GLOAMWOOD", false, 1000000)
	_unlock_with_registry(inactive, registry, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	inactive.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].progress_subunits = 123456
	inactive.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].rate_carry_units = 777
	inactive.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].total_banked_units = 4
	inactive.inventory.entries[&"SOUL_FORM_SCRIBE"] = GameState.InventoryEntryState.new(4, {&"RET_SOLDIER_COMPANY": 2})
	assert_true(SimulationEngine.new(registry).resolve_elapsed(inactive, 12345).success)
	scenarios.append(inactive)
	for i in range(scenarios.size()):
		scenarios[i].progression.unlocked_output_item_ids.sort()
		var storage := MemorySaveStorage.new()
		var files := SaveFileSet.new("user://ignored", "m04d2-coordinator-%s" % i)
		var coordinator := GameStatePersistenceCoordinator.new(SaveService.new(storage, files), registry)
		var save_result := coordinator.save_runtime(scenarios[i], TimeAuthorityState.new(), 3)
		assert_true(save_result.ok, str(save_result))
		var decoded := JsonSaveCodec.new().decode(storage.files[files.primary_path])
		assert_true(decoded.ok)
		assert_eq(decoded.snapshot.schema_version, "4")
		assert_eq(decoded.snapshot.content_revision, "prototype-content-r2")
		assert_false(str(decoded.snapshot).find("OUTPUT_CHANNEL_BANKED") >= 0)
		assert_false(str(decoded.snapshot).find("channel_deltas") >= 0)
		assert_false(str(decoded.snapshot).find("effective_rate") >= 0)
		assert_false(str(decoded.snapshot).find("eta_") >= 0)
		var loaded := coordinator.load_runtime()
		assert_true(loaded.ok, str(loaded))
		assert_eq(_canonical_runtime(loaded.game_state, registry), _canonical_runtime(scenarios[i], registry))

func test_real_revision_one_fixture_loads_under_revision_two_registry_and_invalid_acquisition_rejects() -> void:
	var registry := ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
	var bytes := FileAccess.get_file_as_bytes("res://tests/fixtures/saves/schema_v3_m04d1_access.json")
	var storage := MemorySaveStorage.new()
	var files := SaveFileSet.new("user://ignored", "m04d2-rev1")
	storage.files[files.primary_path] = bytes
	var coordinator := GameStatePersistenceCoordinator.new(SaveService.new(storage, files), registry)
	var loaded := coordinator.load_runtime()
	assert_true(loaded.ok, str(loaded))
	var snapshot := SaveSchemaMapper.runtime_to_snapshot(loaded.game_state, loaded.time_authority_state, int(loaded.save_revision), registry.content_revision)
	snapshot.game_state.thresholds.THR_GLOAMWOOD.channel_acquisition.CHANNEL_GLOAMWOOD_SOLDIER_SOULS.progress_subunits = "1000000"
	var encoded := JsonSaveCodec.new().encode(snapshot)
	assert_true(encoded.ok)
	var bad_storage := MemorySaveStorage.new()
	var bad_files := SaveFileSet.new("user://ignored", "m04d2-invalid")
	bad_storage.files[bad_files.primary_path] = encoded.bytes
	var rejected := GameStatePersistenceCoordinator.new(SaveService.new(bad_storage, bad_files), registry).load_runtime()
	assert_false(rejected.ok)
	assert_eq(rejected.code, GameStateValidator.ERR_RANGE)

func _m04d2_state(threshold_id: StringName, active: bool, backlog: int) -> GameState:
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

func _unlock_with_registry(state: GameState, registry: ContentRegistry, item_ids: Array[StringName]) -> void:
	var service := OutputAccessService.new(registry)
	for item_id in item_ids:
		assert_true(service.unlock_output_item(state, item_id).success)
	assert_true(service.reconcile_available_sources(state).success)

func _canonical_runtime(state: GameState, registry: ContentRegistry) -> Dictionary:
	return SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 3, registry.content_revision).game_state
