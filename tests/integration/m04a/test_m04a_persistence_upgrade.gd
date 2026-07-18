extends GutTest

const V1_FIXTURE := "res://tests/fixtures/saves/schema_v1_foundation.json"
const V2_FIXTURE := "res://tests/fixtures/saves/schema_v2_m04a_representative.json"

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func _fixture(path: String) -> Dictionary:
	return JsonSaveCodec.new().decode(FileAccess.get_file_as_bytes(path)).snapshot

func _write_snapshot(storage: MemorySaveStorage, path: String, snapshot: Dictionary) -> void:
	storage.write_bytes(path, JsonSaveCodec.new().encode(snapshot).bytes)

func _decode_storage(storage: MemorySaveStorage, path: String) -> Dictionary:
	return JsonSaveCodec.new().decode(storage.files[path]).snapshot

func test_v1_upgrade_persists_once_preserves_envelope_and_current_load_does_not_rewrite() -> void:
	var storage := MemorySaveStorage.new()
	var files := SaveFileSet.new("memory://m04a", "save")
	var service := SaveService.new(storage, files)
	var v1 := _fixture(V1_FIXTURE)
	_write_snapshot(storage, files.primary_path, v1)
	var coordinator := GameStatePersistenceCoordinator.new(service, _registry())
	var loaded := coordinator.load_runtime()
	assert_true(loaded.ok)
	assert_eq(loaded.save_revision, 13)
	assert_true(storage.exists(files.backup_path))
	var primary := _decode_storage(storage, files.primary_path)
	assert_eq(primary.schema_version, "3")
	assert_eq(primary.save_revision, "13")
	assert_eq(primary.content_revision, v1.content_revision)
	assert_eq(primary.time_authority, v1.time_authority)
	assert_eq(primary.last_offline_resolution_id, "offline-resolution-v1-fixture")
	assert_eq(primary.metadata, v1.metadata)
	assert_eq(primary.game_state.inventory, {"entries": {}})
	var backup := _decode_storage(storage, files.backup_path)
	assert_eq(backup.schema_version, "1")
	assert_eq(backup.save_revision, "12")
	var primary_bytes: PackedByteArray = storage.files[files.primary_path].duplicate()
	var backup_bytes: PackedByteArray = storage.files[files.backup_path].duplicate()
	var second := coordinator.load_runtime()
	assert_true(second.ok)
	assert_eq(second.save_revision, 13)
	assert_false(second.migration_persisted)
	assert_eq(storage.files[files.primary_path], primary_bytes)
	assert_eq(storage.files[files.backup_path], backup_bytes)

func test_upgrade_write_failure_exposes_no_runtime_and_preserves_v1() -> void:
	var storage := MemorySaveStorage.new()
	var files := SaveFileSet.new("memory://m04a_fail", "save")
	var service := SaveService.new(storage, files)
	var v1 := _fixture(V1_FIXTURE)
	_write_snapshot(storage, files.primary_path, v1)
	storage.fail_once("write")
	var result := GameStatePersistenceCoordinator.new(service, _registry()).load_runtime()
	assert_false(result.ok)
	var decoded := _decode_storage(storage, files.primary_path)
	assert_eq(decoded.schema_version, "1")
	assert_eq(decoded.metadata, v1.metadata)

func test_incompatible_content_future_schema_and_revision_overflow_do_not_write() -> void:
	var storage := MemorySaveStorage.new()
	var files := SaveFileSet.new("memory://m04a_negative", "save")
	var service := SaveService.new(storage, files)
	var v1 := _fixture(V1_FIXTURE)
	v1.content_revision = "unknown-content"
	_write_snapshot(storage, files.primary_path, v1)
	assert_false(GameStatePersistenceCoordinator.new(service, _registry()).load_runtime().ok)
	assert_eq(_decode_storage(storage, files.primary_path).schema_version, "1")
	v1 = _fixture(V1_FIXTURE)
	v1.schema_version = "99"
	_write_snapshot(storage, files.primary_path, v1)
	assert_eq(GameStatePersistenceCoordinator.new(service, _registry()).load_runtime().code, SaveService.ERR_NO_VALID_SAVE)
	v1 = _fixture(V1_FIXTURE)
	v1.save_revision = SaveInt64.format(FixedPoint.INT64_MAX)
	_write_snapshot(storage, files.primary_path, v1)
	assert_eq(GameStatePersistenceCoordinator.new(service, _registry()).load_runtime().code, GameStatePersistenceCoordinator.ERR_REVISION_OVERFLOW)
	assert_eq(_decode_storage(storage, files.primary_path).schema_version, "1")

func test_corrupt_primary_valid_v1_backup_and_both_invalid_cases() -> void:
	var storage := MemorySaveStorage.new()
	var files := SaveFileSet.new("memory://m04a_fallback", "save")
	var service := SaveService.new(storage, files)
	storage.files[files.primary_path] = "not-json".to_utf8_buffer()
	_write_snapshot(storage, files.backup_path, _fixture(V1_FIXTURE))
	var result := GameStatePersistenceCoordinator.new(service, _registry()).load_runtime()
	assert_true(result.ok)
	assert_eq(result.selected_role, "backup")
	assert_eq(_decode_storage(storage, files.primary_path).schema_version, "3")
	assert_true(storage.exists(files.suspect_path(0, 0)))
	storage = MemorySaveStorage.new()
	files = SaveFileSet.new("memory://m04a_both_bad", "save")
	service = SaveService.new(storage, files)
	storage.files[files.primary_path] = PackedByteArray([1, 2])
	storage.files[files.backup_path] = PackedByteArray([3, 4])
	assert_false(GameStatePersistenceCoordinator.new(service, _registry()).load_runtime().ok)

func test_new_save_writes_v2_current_revision_and_v2_fixture_load_does_not_rotate() -> void:
	var storage := MemorySaveStorage.new()
	var files := SaveFileSet.new("memory://m04a_v2", "save")
	var service := SaveService.new(storage, files)
	var coordinator := GameStatePersistenceCoordinator.new(service, _registry())
	var runtime := SaveSchemaMapper.snapshot_to_runtime(_fixture(V2_FIXTURE))
	runtime.game_state.progression.unlocked_output_item_ids.append(&"SOUL_CALLING_SOLDIER")
	assert_true(coordinator.save_runtime(runtime.game_state, TimeAuthorityState.new(), 1).ok)
	var saved := _decode_storage(storage, files.primary_path)
	assert_eq(saved.schema_version, "3")
	assert_eq(saved.content_revision, ContentRegistry.CURRENT_REVISION)
	_write_snapshot(storage, files.primary_path, _fixture(V2_FIXTURE))
	var before: PackedByteArray = storage.files[files.primary_path].duplicate()
	var loaded := coordinator.load_runtime()
	assert_true(loaded.ok)
	assert_true(loaded.migration_persisted)
	assert_ne(storage.files[files.primary_path], before)
	assert_true(storage.exists(files.backup_path))
