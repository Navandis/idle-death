extends SceneTree

## Deterministic headless M04A trace using real file-backed save storage.
##
## The trace uses the supplied isolated `--save-root` only. It proves typed state
## validation, deep-clone isolation, exact v2 save/load, immutable v1 fixture
## migration, envelope preservation, backup retention, and no-repeat rewrite.

const V1_FIXTURE := "res://tests/fixtures/saves/schema_v1_foundation.json"
const V2_FIXTURE := "res://tests/fixtures/saves/schema_v2_m04a_representative.json"

func _init() -> void:
	var root := _read_save_root()
	if root.begins_with("user://"):
		_fail("save_root_required", {"ok": false, "root": root})
	var registry := ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
	if not registry.ready:
		_fail("content_registry", {"ok": false, "diagnostics": registry.diagnostics})
	var storage := FileSaveStorage.new()
	var files := SaveFileSet.new(root, "m04a_trace")
	_cleanup(files, storage)
	var service := SaveService.new(storage, files)
	var coordinator := GameStatePersistenceCoordinator.new(service, registry)
	var representative := _fixture(V2_FIXTURE)
	var runtime := SaveSchemaMapper.snapshot_to_runtime(representative)
	if not runtime.ok:
		_fail("representative_runtime", runtime)
	# The historical v2 fixture predates current output-access completeness. Normalize
	# only the fixture's current-valid state before exercising the v4 persistence path;
	# the migration assertions below still load the original v1 bytes unchanged.
	runtime.game_state.progression = GameState.ProgressionState.new(runtime.game_state.progression.command_tether_capacity, [&"SOUL_CALLING_SOLDIER"])
	var domain := GameStateValidator.validate(runtime.game_state, registry)
	if not domain.ok:
		_fail("representative_domain", domain)
	if not runtime.game_state.report_state.value_equals(ReportState.empty_at_cursor(runtime.game_state.simulation_time_msec)):
		_fail("representative_report_state", {"ok": false})
	_assert_clone_isolated(runtime.game_state)
	print("TRACE M04A typed_state_and_clone=PASS")
	var save := coordinator.save_runtime(runtime.game_state, runtime.time_authority_state, 30)
	if not save.ok:
		_fail("v2_save", save)
	var loaded_v2 := coordinator.load_runtime()
	if not loaded_v2.ok:
		_fail("v2_load", loaded_v2)
	_assert_runtime_equal(runtime.game_state, loaded_v2.game_state, "v2_round_trip")
	print("TRACE M04A v2_round_trip=PASS")
	var v1 := _fixture(V1_FIXTURE)
	_write_snapshot(storage, files.primary_path, v1)
	var upgraded := coordinator.load_runtime()
	if not upgraded.ok or upgraded.save_revision != 13:
		_fail("upgrade", upgraded)
	_assert_disk_revision(files.primary_path, "4", "13", storage, "upgraded_primary")
	_assert_disk_revision(files.backup_path, "1", "12", storage, "historical_backup")
	var primary := _decode_path(storage, files.primary_path)
	if primary.content_revision != v1.content_revision or primary.time_authority != v1.time_authority or primary.metadata != v1.metadata or primary.last_offline_resolution_id != v1.last_offline_resolution_id:
		_fail("v1_authority_preserved", primary)
	if primary.game_state.simulation_time_msec != v1.game_state.simulation_time_msec or primary.game_state.inventory != {"entries": {}} or not primary.game_state.forms.is_empty() or not primary.game_state.thresholds.is_empty() or not primary.game_state.reapings.is_empty():
		_fail("v1_empty_gameplay", primary.game_state)
	print("TRACE M04A v1_upgrade_preserved_authority=PASS")
	var primary_bytes_before: PackedByteArray = storage.read_bytes(files.primary_path).bytes
	var backup_bytes_before: PackedByteArray = storage.read_bytes(files.backup_path).bytes
	var again := coordinator.load_runtime()
	if not again.ok or again.migration_persisted or again.save_revision != 13:
		_fail("no_repeat", again)
	if storage.read_bytes(files.primary_path).bytes != primary_bytes_before:
		_fail("primary_rewritten", {"ok": false})
	if storage.read_bytes(files.backup_path).bytes != backup_bytes_before:
		_fail("backup_rotated", {"ok": false})
	print("TRACE M04A file_primary_schema=4_save_revision=13")
	print("TRACE M04A file_backup_schema=1_save_revision=12")
	print("TRACE M04A no_repeat_rewrite=PASS")
	quit(0)

func _read_save_root() -> String:
	var args := OS.get_cmdline_user_args()
	for index in range(args.size()):
		if args[index] == "--save-root" and index + 1 < args.size():
			return args[index + 1]
	return "user://m04a_trace"

func _fixture(path: String) -> Dictionary:
	var decoded := JsonSaveCodec.new().decode(FileAccess.get_file_as_bytes(path))
	if not decoded.ok:
		_fail("fixture_decode", decoded)
	return decoded.snapshot

func _write_snapshot(storage: SaveStorage, path: String, snapshot: Dictionary) -> void:
	var encoded := JsonSaveCodec.new().encode(snapshot)
	if not encoded.ok:
		_fail("fixture_encode", encoded)
	var write := storage.write_bytes(path, encoded.bytes)
	if not write.ok:
		_fail("fixture_write", write)

func _decode_path(storage: SaveStorage, path: String) -> Dictionary:
	var read := storage.read_bytes(path)
	if not read.ok:
		_fail("read_path", read)
	var decoded := JsonSaveCodec.new().decode(read.bytes)
	if not decoded.ok:
		_fail("decode_path", decoded)
	return decoded.snapshot

func _assert_clone_isolated(state: GameState) -> void:
	var clone := state.deep_clone()
	clone.inventory.entries["RES_ESSENCE"].reservations["REC_WEAVE_REMEMBERED"] = 1
	clone.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits = 1
	clone.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].progress_subunits = 1
	clone.reapings[&"THR_GLOAMWOOD"].flow_carry_units["FLOW_TEST"] = 1
	clone.progression.command_tether_capacity = 99
	if state.inventory.entries["RES_ESSENCE"].reservations["REC_WEAVE_REMEMBERED"] != 25 or state.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits != 1000 or state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].progress_subunits != 250000 or state.reapings[&"THR_GLOAMWOOD"].flow_carry_units["FLOW_TEST"] != 4 or state.progression.command_tether_capacity != 1:
		_fail("clone_isolation", {"ok": false})

func _assert_runtime_equal(expected: GameState, actual: GameState, label: String) -> void:
	if actual.simulation_time_msec != expected.simulation_time_msec:
		_fail(label, {"field": "simulation_time_msec"})
	if actual.inventory.entries["RES_ESSENCE"].total != expected.inventory.entries["RES_ESSENCE"].total:
		_fail(label, {"field": "inventory"})
	if actual.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits != expected.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits:
		_fail(label, {"field": "forms"})
	if actual.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].progress_subunits != expected.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].progress_subunits:
		_fail(label, {"field": "thresholds"})
	if actual.reapings[&"THR_GLOAMWOOD"].flow_carry_units["FLOW_TEST"] != expected.reapings[&"THR_GLOAMWOOD"].flow_carry_units["FLOW_TEST"]:
		_fail(label, {"field": "reapings"})
	if actual.progression.command_tether_capacity != expected.progression.command_tether_capacity:
		_fail(label, {"field": "progression"})
	if not actual.report_state.value_equals(expected.report_state):
		_fail(label, {"field": "report_state"})

func _assert_disk_revision(path: String, expected_schema: String, expected_revision: String, storage: SaveStorage, label: String) -> void:
	if not storage.exists(path):
		_fail(label, {"ok": false, "code": "TRACE_FILE_MISSING", "path": path})
	var decoded := _decode_path(storage, path)
	if decoded.schema_version != expected_schema or decoded.save_revision != expected_revision:
		_fail(label, {"ok": false, "schema_version": decoded.schema_version, "save_revision": decoded.save_revision})

func _cleanup(files: SaveFileSet, storage: SaveStorage) -> void:
	storage.remove(files.temporary_path)
	storage.remove(files.primary_path)
	storage.remove(files.backup_path)
	for counter in range(0, 10):
		storage.remove(files.suspect_path(0, counter))

func _fail(label: String, data: Dictionary) -> void:
	printerr("TRACE M04A %s=FAIL %s" % [label, str(data)])
	quit(1)
