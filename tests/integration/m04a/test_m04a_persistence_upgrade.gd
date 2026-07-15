extends GutTest

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func test_v1_upgrade_persists_once_and_current_load_does_not_rewrite() -> void:
	var storage := MemorySaveStorage.new()
	var files := SaveFileSet.new("memory://m04a", "save")
	var service := SaveService.new(storage, files)
	var v1 := SaveSchemaMapper.runtime_to_snapshot(GameState.new(99), TimeAuthorityState.new(), 7, "prototype-content-r1")
	v1.schema_version = "1"
	v1.game_state = {"simulation_time_msec": "99"}
	storage.write_bytes(files.primary_path, JsonSaveCodec.new().encode(v1).bytes)
	var coordinator := GameStatePersistenceCoordinator.new(service, _registry())
	var loaded := coordinator.load_runtime()
	assert_true(loaded.ok)
	assert_eq(loaded.save_revision, 8)
	assert_true(storage.exists(files.backup_path))
	var second := coordinator.load_runtime()
	assert_true(second.ok)
	assert_eq(second.save_revision, 8)
	assert_false(second.migration_persisted)

func test_upgrade_write_failure_exposes_no_runtime() -> void:
	var storage := MemorySaveStorage.new()
	var files := SaveFileSet.new("memory://m04a_fail", "save")
	var service := SaveService.new(storage, files)
	var v1 := SaveSchemaMapper.runtime_to_snapshot(GameState.new(), TimeAuthorityState.new(), 1, "prototype-content-r1")
	v1.schema_version = "1"
	v1.game_state = {"simulation_time_msec": "0"}
	storage.write_bytes(files.primary_path, JsonSaveCodec.new().encode(v1).bytes)
	storage.fail_once("write")
	var result := GameStatePersistenceCoordinator.new(service, _registry()).load_runtime()
	assert_false(result.ok)
	var decoded: Dictionary = JsonSaveCodec.new().decode(storage.files[files.primary_path]).snapshot
	assert_eq(decoded.schema_version, "1")
