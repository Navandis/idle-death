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
	assert_eq(decoded.snapshot.schema_version, "3")
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
