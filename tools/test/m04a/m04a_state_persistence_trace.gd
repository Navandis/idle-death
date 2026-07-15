extends SceneTree

## Deterministic headless M04A trace: validates clone, v2 round trip, and v1 upgrade.

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var root: String = args[args.size() - 1] if args.size() > 0 else "user://m04a_trace"
	var registry := ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
	var storage := MemorySaveStorage.new()
	var files := SaveFileSet.new(root, "m04a_trace")
	var service := SaveService.new(storage, files)
	var coordinator := GameStatePersistenceCoordinator.new(service, registry)
	var save := coordinator.save_runtime(GameState.new(1234), TimeAuthorityState.new(), 1)
	if not save.ok: _fail("v2_save", save)
	print("TRACE M04A v2_round_trip=PASS")
	var v1 := SaveSchemaMapper.runtime_to_snapshot(GameState.new(77), TimeAuthorityState.new(), 3, "prototype-content-r1")
	v1.schema_version = "1"
	v1.game_state = {"simulation_time_msec": "77"}
	storage.write_bytes(files.primary_path, JsonSaveCodec.new().encode(v1).bytes)
	var upgraded := coordinator.load_runtime()
	if not upgraded.ok or upgraded.save_revision != 4: _fail("upgrade", upgraded)
	print("TRACE M04A v1_upgrade_revision=4")
	var again := coordinator.load_runtime()
	if not again.ok or again.migration_persisted: _fail("no_repeat", again)
	print("TRACE M04A no_repeat_rewrite=PASS")
	quit(0)

func _fail(label: String, data: Dictionary) -> void:
	printerr("TRACE M04A %s=FAIL %s" % [label, str(data)])
	quit(1)
