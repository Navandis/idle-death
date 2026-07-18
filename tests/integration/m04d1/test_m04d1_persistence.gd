extends GutTest

const V2_FIXTURE := "res://tests/fixtures/saves/schema_v2_m04a_representative.json"
const V3_FIXTURE := "res://tests/fixtures/saves/schema_v3_m04d1_access.json"

func test_v2_to_v3_migration_preserves_legacy_acquisition_and_derives_access() -> void:
	var bytes := FileAccess.get_file_as_bytes(V2_FIXTURE)
	var storage := MemorySaveStorage.new()
	var files := SaveFileSet.new("user://m04d1")
	assert_true(storage.write_bytes(files.primary_path, bytes).ok)
	var coordinator := GameStatePersistenceCoordinator.new(SaveService.new(storage, files), ContentRegistry.build(load("res://content/prototype_content_catalog.tres")))
	var loaded := coordinator.load_runtime()
	assert_true(loaded.ok)
	assert_true(loaded.migration_persisted)
	assert_eq(loaded.save_revision, 22)
	assert_eq(loaded.game_state.progression.unlocked_output_item_ids, [&"SOUL_CALLING_SOLDIER"])
	var acq = loaded.game_state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"]
	assert_eq(acq.progress_subunits, 250000)
	assert_eq(acq.rate_carry_units, 10)
	assert_eq(acq.total_banked_units, 1)

func test_schema_v3_fixture_round_trips_without_rewrite() -> void:
	var decoded := JsonSaveCodec.new().decode(FileAccess.get_file_as_bytes(V3_FIXTURE))
	assert_true(SaveSchemaValidator.validate_v3(decoded.snapshot).ok)
	var runtime := SaveSchemaMapper.snapshot_to_runtime(decoded.snapshot)
	assert_true(runtime.ok)
	assert_true(GameStateValidator.validate(runtime.game_state, ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))).ok)
	assert_eq(SaveSchemaMapper.runtime_to_snapshot(runtime.game_state, runtime.time_authority_state, runtime.save_revision, runtime.content_revision).schema_version, "3")
