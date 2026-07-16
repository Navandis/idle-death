extends SceneTree

## Deterministic headless M04A trace using real file-backed save storage.
##
## Owner verification passes an isolated disposable directory as `--save-root`.
## This trace intentionally uses FileSaveStorage so it proves the same temporary,
## primary, backup, and promotion behavior that Windows owner verification must
## exercise; it does not rely on in-memory test doubles.

func _init() -> void:
	var root := _read_save_root()
	var registry := ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
	if not registry.ready:
		_fail("content_registry", {"ok": false, "diagnostics": registry.diagnostics})
	var storage := FileSaveStorage.new()
	var files := SaveFileSet.new(root, "m04a_trace")
	_cleanup(files, storage)
	var service := SaveService.new(storage, files)
	var coordinator := GameStatePersistenceCoordinator.new(service, registry)
	var save := coordinator.save_runtime(GameState.new(1234), TimeAuthorityState.new(), 1)
	if not save.ok:
		_fail("v2_save", save)
	_assert_disk_revision(files.primary_path, "2", "1", storage, "initial_v2_primary")
	print("TRACE M04A v2_round_trip=PASS")
	var v1 := SaveSchemaMapper.runtime_to_snapshot(GameState.new(77), TimeAuthorityState.new(), 3, "prototype-content-r1")
	v1.schema_version = "1"
	v1.game_state = {"simulation_time_msec": "77"}
	var encoded := JsonSaveCodec.new().encode(v1)
	if not encoded.ok:
		_fail("encode_v1", encoded)
	var write_v1 := storage.write_bytes(files.primary_path, encoded.bytes)
	if not write_v1.ok:
		_fail("write_v1_primary", write_v1)
	var upgraded := coordinator.load_runtime()
	if not upgraded.ok or upgraded.save_revision != 4:
		_fail("upgrade", upgraded)
	_assert_disk_revision(files.primary_path, "2", "4", storage, "upgraded_primary")
	_assert_disk_revision(files.backup_path, "1", "3", storage, "historical_backup")
	print("TRACE M04A v1_upgrade_revision=4")
	var primary_bytes_before: PackedByteArray = storage.read_bytes(files.primary_path).bytes
	var backup_bytes_before: PackedByteArray = storage.read_bytes(files.backup_path).bytes
	var again := coordinator.load_runtime()
	if not again.ok or again.migration_persisted:
		_fail("no_repeat", again)
	if storage.read_bytes(files.primary_path).bytes != primary_bytes_before:
		_fail("primary_rewritten", {"ok": false})
	if storage.read_bytes(files.backup_path).bytes != backup_bytes_before:
		_fail("backup_rotated", {"ok": false})
	print("TRACE M04A file_primary_schema=2_save_revision=4")
	print("TRACE M04A file_backup_schema=1_save_revision=3")
	print("TRACE M04A no_repeat_rewrite=PASS")
	quit(0)

func _read_save_root() -> String:
	var args := OS.get_cmdline_user_args()
	for index in range(args.size()):
		if args[index] == "--save-root" and index + 1 < args.size():
			return args[index + 1]
	return "user://m04a_trace"

func _assert_disk_revision(path: String, expected_schema: String, expected_revision: String, storage: SaveStorage, label: String) -> void:
	if not storage.exists(path):
		_fail(label, {"ok": false, "code": "TRACE_FILE_MISSING", "path": path})
	var read := storage.read_bytes(path)
	if not read.ok:
		_fail(label, read)
	var decoded := JsonSaveCodec.new().decode(read.bytes)
	if not decoded.ok:
		_fail(label, decoded)
	if decoded.snapshot.schema_version != expected_schema or decoded.snapshot.save_revision != expected_revision:
		_fail(label, {"ok": false, "schema_version": decoded.snapshot.schema_version, "save_revision": decoded.snapshot.save_revision})

func _cleanup(files: SaveFileSet, storage: SaveStorage) -> void:
	storage.remove(files.temporary_path)
	storage.remove(files.primary_path)
	storage.remove(files.backup_path)
	for counter in range(0, 10):
		storage.remove(files.suspect_path(0, counter))

func _fail(label: String, data: Dictionary) -> void:
	printerr("TRACE M04A %s=FAIL %s" % [label, str(data)])
	quit(1)
