extends GutTest

const V3_FIXTURE := "res://tests/fixtures/saves/schema_v3_m04d1_access.json"
const V4_FIXTURE := "res://tests/fixtures/saves/schema_v4_populated_report.json"

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func _snapshot(path: String) -> Dictionary:
	return JsonSaveCodec.new().decode(FileAccess.get_file_as_bytes(path)).snapshot

func test_new_save_is_v4_and_current_v4_load_does_not_rewrite() -> void:
	var storage := MemorySaveStorage.new()
	var files := SaveFileSet.new("memory://m04e2a2-current", "save")
	var service := SaveService.new(storage, files)
	var coordinator := GameStatePersistenceCoordinator.new(service, _registry())
	var runtime := SaveSchemaMapper.snapshot_to_runtime(_snapshot(V4_FIXTURE))
	assert_true(runtime.ok)
	assert_true(coordinator.save_runtime(runtime.game_state, runtime.time_authority_state, 32).ok)
	var before: PackedByteArray = storage.files[files.primary_path].duplicate()
	var loaded := coordinator.load_runtime()
	assert_true(loaded.ok, str(loaded))
	assert_false(loaded.migration_persisted)
	assert_eq(loaded.save_revision, 32)
	assert_eq(storage.files[files.primary_path], before)
	assert_false(storage.files.has(files.backup_path))

func test_v3_upgrade_persists_v4_once_and_failure_preserves_source() -> void:
	var storage := MemorySaveStorage.new()
	var files := SaveFileSet.new("memory://m04e2a2-upgrade", "save")
	var source: PackedByteArray = FileAccess.get_file_as_bytes(V3_FIXTURE)
	storage.files[files.primary_path] = source.duplicate()
	var coordinator := GameStatePersistenceCoordinator.new(SaveService.new(storage, files), _registry())
	var loaded := coordinator.load_runtime()
	assert_true(loaded.ok, str(loaded))
	assert_true(loaded.migration_persisted)
	assert_eq(loaded.save_revision, 22)
	var upgraded: Dictionary = JsonSaveCodec.new().decode(storage.files[files.primary_path]).snapshot
	assert_eq(upgraded.schema_version, "4")
	assert_eq(upgraded.save_revision, "22")
	assert_eq(upgraded.game_state.report_state.ingested_through_simulation_msec, "12000")
	var failed_storage := MemorySaveStorage.new()
	var failed_files := SaveFileSet.new("memory://m04e2a2-failure", "save")
	failed_storage.files[failed_files.primary_path] = source.duplicate()
	failed_storage.fail_once("write")
	var failed := GameStatePersistenceCoordinator.new(SaveService.new(failed_storage, failed_files), _registry()).load_runtime()
	assert_false(failed.ok)
	assert_eq(failed_storage.files[failed_files.primary_path], source)
	assert_false(failed.has("game_state"))

func test_populated_report_maps_through_isolated_file_storage_contract() -> void:
	var storage := MemorySaveStorage.new()
	var files := SaveFileSet.new("memory://m04e2a2-populated", "save")
	var snapshot := _snapshot(V4_FIXTURE)
	assert_true(SaveService.new(storage, files).save_snapshot(snapshot).ok)
	var loaded := SaveService.new(storage, files).load_runtime()
	assert_true(loaded.ok, str(loaded))
	assert_true(loaded.game_state.report_state.value_equals(SaveSchemaMapper.snapshot_to_runtime(snapshot).game_state.report_state))
