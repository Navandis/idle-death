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
	var persisted: Dictionary = JsonSaveCodec.new().decode(storage.files[files.primary_path]).snapshot
	assert_eq(persisted.game_state.progression.unlocked_output_item_ids, ["SOUL_CALLING_SOLDIER"])
	var service := SaveService.new(storage, files)
	var reloaded := GameStatePersistenceCoordinator.new(service, ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))).load_runtime()
	assert_true(reloaded.ok)
	assert_false(reloaded.migration_persisted)

func test_schema_v3_fixture_round_trips_without_rewrite() -> void:
	var decoded: Dictionary = JsonSaveCodec.new().decode(FileAccess.get_file_as_bytes(V3_FIXTURE))
	assert_true(SaveSchemaValidator.validate_v3(decoded.snapshot).ok)
	var runtime := SaveSchemaMapper.snapshot_to_runtime(decoded.snapshot)
	assert_true(runtime.ok)
	assert_true(GameStateValidator.validate(runtime.game_state, ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))).ok)
	assert_eq(SaveSchemaMapper.runtime_to_snapshot(runtime.game_state, runtime.time_authority_state, runtime.save_revision, runtime.content_revision).schema_version, "3")


const V1_FIXTURE := "res://tests/fixtures/saves/schema_v1_foundation.json"

func test_pure_migration_deep_copy_and_sequential_upgrade() -> void:
	var v2: Dictionary = JsonSaveCodec.new().decode(FileAccess.get_file_as_bytes(V2_FIXTURE)).snapshot
	var before: Dictionary = v2.duplicate(true)
	var migrated := SaveMigrationRegistry.new().migrate(v2, SaveEnvelope.SCHEMA_VERSION_V2, SaveEnvelope.SCHEMA_VERSION_V3)
	assert_true(migrated.ok)
	assert_eq(v2, before)
	var comparable: Dictionary = migrated.snapshot.duplicate(true)
	comparable.schema_version = before.schema_version
	comparable.game_state.progression.erase("unlocked_output_item_ids")
	assert_eq(comparable, before)
	assert_eq(migrated.snapshot.game_state.progression.unlocked_output_item_ids, [])
	var v1: Dictionary = JsonSaveCodec.new().decode(FileAccess.get_file_as_bytes(V1_FIXTURE)).snapshot
	var migrated_v1 := SaveMigrationRegistry.new().migrate(v1, SaveEnvelope.SCHEMA_VERSION_V1, SaveEnvelope.SCHEMA_VERSION_V3)
	assert_true(migrated_v1.ok)
	assert_eq(migrated_v1.snapshot.schema_version, "3")
	assert_eq(migrated_v1.snapshot.game_state.progression.unlocked_output_item_ids, [])

func test_current_v3_no_rewrite_and_new_save_round_trip() -> void:
	var storage := MemorySaveStorage.new()
	var files := SaveFileSet.new("user://m04d1-current")
	var v3_bytes := FileAccess.get_file_as_bytes(V3_FIXTURE)
	assert_true(storage.write_bytes(files.primary_path, v3_bytes).ok)
	var coordinator := GameStatePersistenceCoordinator.new(SaveService.new(storage, files), ContentRegistry.build(load("res://content/prototype_content_catalog.tres")))
	var loaded := coordinator.load_runtime()
	assert_true(loaded.ok)
	assert_false(loaded.migration_persisted)
	assert_eq(storage.files[files.primary_path], v3_bytes)
	assert_false(storage.files.has(files.backup_path))
	var new_files := SaveFileSet.new("user://m04d1-new")
	var state := GameState.new(12345)
	var threshold := GameState.ThresholdState.new()
	threshold.knowledge_state = &"CHARTED"; threshold.availability_state = &"AVAILABLE"; threshold.lifecycle_state = &"OVERDUE"; threshold.remaining_backlog = 5000
	state.thresholds[&"THR_GLOAMWOOD"] = threshold
	var save := SaveService.new(storage, new_files).save_runtime(state, TimeAuthorityState.new(), 7, ContentRegistry.CURRENT_REVISION)
	assert_true(save.ok)
	var decoded: Dictionary = JsonSaveCodec.new().decode(storage.files[new_files.primary_path]).snapshot
	assert_eq(decoded.schema_version, "3")
	assert_eq(decoded.content_revision, ContentRegistry.CURRENT_REVISION)

func test_upgrade_failure_preserves_source_and_exposes_no_runtime() -> void:
	for operation in ["write", "copy", "rename"]:
		var storage := MemorySaveStorage.new()
		var files := SaveFileSet.new("user://m04d1-fail-%s" % operation)
		var original := FileAccess.get_file_as_bytes(V2_FIXTURE)
		assert_true(storage.write_bytes(files.primary_path, original).ok)
		storage.fail_once(operation)
		var loaded := GameStatePersistenceCoordinator.new(SaveService.new(storage, files), ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))).load_runtime()
		assert_false(loaded.ok, operation)
		assert_false(loaded.has("game_state"), operation)
		assert_eq(storage.files[files.primary_path], original, operation)

func test_invalid_legacy_finalization_and_non_persisted_result_artifacts() -> void:
	var storage := MemorySaveStorage.new()
	var files := SaveFileSet.new("user://m04d1-invalid")
	var snapshot: Dictionary = JsonSaveCodec.new().decode(FileAccess.get_file_as_bytes(V2_FIXTURE)).snapshot
	snapshot.game_state.thresholds.THR_GLOAMWOOD.channel_acquisition["CHANNEL_BROKEN_WATCH_PROVISIONS"] = {"progress_subunits": "0", "rate_carry_units": "0", "total_banked_units": "0"}
	assert_true(storage.write_bytes(files.primary_path, JsonSaveCodec.new().encode(snapshot).bytes).ok)
	var loaded := GameStatePersistenceCoordinator.new(SaveService.new(storage, files), ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))).load_runtime()
	assert_false(loaded.ok)
	assert_eq(loaded.code, OutputAccessService.ERR_MIGRATION_FINALIZATION_FAILED)
	var valid_storage := MemorySaveStorage.new()
	var valid_files := SaveFileSet.new("user://m04d1-artifacts")
	var state := GameState.new(1)
	var threshold := GameState.ThresholdState.new()
	threshold.knowledge_state = &"CHARTED"; threshold.availability_state = &"AVAILABLE"; threshold.lifecycle_state = &"OVERDUE"; threshold.remaining_backlog = 5000
	state.thresholds[&"THR_GLOAMWOOD"] = threshold
	assert_true(OutputAccessService.new(ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))).unlock_output_item(state, &"SOUL_FORM_SCRIBE").success)
	assert_true(SaveService.new(valid_storage, valid_files).save_runtime(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION).ok)
	var persisted: Dictionary = JsonSaveCodec.new().decode(valid_storage.files[valid_files.primary_path]).snapshot
	assert_false(persisted.game_state.has("events"))
	assert_false(persisted.game_state.has("change_summary"))
	assert_false(persisted.game_state.progression.has("insight"))
