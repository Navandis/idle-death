extends SceneTree

## Isolated M04E2A2 report-state/schema trace.
##
## The trace owns only files below the caller-provided existing `--work-root`.
## It exercises the real mapper, primitive validators, codec, migration
## registry, coordinator, and file storage. It never touches normal `user://`
## saves, reads a clock, or mutates production report state through a service.

const EXPECTED_MARKERS := [
	"TRACE M04E2A2 empty_report_state_at_cursor=PASS",
	"TRACE M04E2A2 populated_report_state_contract=PASS",
	"TRACE M04E2A2 deep_clone_copy_isolation=PASS",
	"TRACE M04E2A2 schema_v4_exact_keys=PASS",
	"TRACE M04E2A2 canonical_int64_wire=PASS",
	"TRACE M04E2A2 v3_to_v4_prospective_cursor=PASS",
	"TRACE M04E2A2 sequential_v1_v2_v3_v4=PASS",
	"TRACE M04E2A2 frozen_v1_v2_v3_unchanged=PASS",
	"TRACE M04E2A2 populated_v4_round_trip=PASS",
	"TRACE M04E2A2 current_v4_no_rewrite=PASS",
	"TRACE M04E2A2 malformed_report_matrix_rejected=PASS",
	"TRACE M04E2A2 content_relationship_validation=PASS",
	"TRACE M04E2A2 upgrade_failure_preserves_source=PASS",
	"TRACE M04E2A2 no_report_ingestion_or_reads=PASS",
	"TRACE M04E2A2 schema_v4_content_r2=PASS",
]

var _work_root := ""
var _markers: Array[String] = []
var _registry: ContentRegistry

func _init() -> void:
	_work_root = _argument_value("--work-root")
	if _work_root.is_empty() or not DirAccess.dir_exists_absolute(_work_root):
		_fail("M04E2A2 requires an existing isolated --work-root.")
		return
	_registry = ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
	if not _registry.ready:
		_fail("M04E2A2 content registry failed.")
		return
	var success := _run()
	_cleanup()
	if not success or _markers != EXPECTED_MARKERS:
		_fail("M04E2A2 marker sequence is incomplete or reordered.")
		return
	quit(0)

func _run() -> bool:
	var empty := GameState.new(12345)
	if not _assert(empty.report_state.ingested_through_simulation_msec == 12345 and empty.report_state.live.window_ended_simulation_msec == 12345 and GameStateValidator.validate(empty, _registry).ok, "empty state at cursor"): return false
	_pass("empty_report_state_at_cursor")

	var populated_snapshot := _read_fixture("res://tests/fixtures/saves/schema_v4_populated_report.json")
	if not _assert(SaveSchemaValidator.validate_v4(populated_snapshot).ok, "populated primitive contract"): return false
	var populated_runtime := SaveSchemaMapper.snapshot_to_runtime(populated_snapshot)
	if not _assert(populated_runtime.ok and GameStateValidator.validate(populated_runtime.game_state, _registry).ok, "populated runtime contract"): return false
	_pass("populated_report_state_contract")

	var clone: GameState = populated_runtime.game_state.deep_clone()
	clone.report_state.live.event_type_counts[&"THRESHOLD_SETTLED"] = 2
	clone.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].loadout_identity.ordered_retinue_ids.append(&"RET_SOLDIER_COMPANY")
	if not _assert(populated_runtime.game_state.report_state.live.event_type_counts[&"THRESHOLD_SETTLED"] == 1 and populated_runtime.game_state.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].loadout_identity.ordered_retinue_ids.is_empty(), "clone isolation"): return false
	var copied := GameState.new()
	copied.copy_from(populated_runtime.game_state)
	copied.report_state.live.event_type_counts[&"THRESHOLD_SETTLED"] = 3
	if not _assert(populated_runtime.game_state.report_state.live.event_type_counts[&"THRESHOLD_SETTLED"] == 1, "copy isolation"): return false
	_pass("deep_clone_copy_isolation")

	var game_keys: Array = populated_snapshot.game_state.keys(); game_keys.sort()
	var expected_keys: Array = SaveEnvelope.GAME_KEYS_V4.duplicate(); expected_keys.sort()
	if not _assert(game_keys == expected_keys and SaveSchemaValidator.validate_v4(populated_snapshot).ok, "exact v4 keys"): return false
	_pass("schema_v4_exact_keys")
	if not _assert(typeof(populated_snapshot.game_state.report_state.next_event_sequence) == TYPE_STRING and typeof(populated_snapshot.game_state.report_state.live.ingested_run_count) == TYPE_STRING and typeof(populated_snapshot.game_state.report_state.history[0].window.recent_events[0].priority) == TYPE_STRING, "canonical wire integers"): return false
	_pass("canonical_int64_wire")

	var v3 := _read_fixture("res://tests/fixtures/saves/schema_v3_m04d1_access.json")
	var v3_migrated := SaveMigrationRegistry.new().migrate(v3, SaveEnvelope.SCHEMA_VERSION_V3, SaveEnvelope.SCHEMA_VERSION_V4)
	if not _assert(v3_migrated.ok and v3_migrated.snapshot.game_state.report_state.ingested_through_simulation_msec == v3.game_state.simulation_time_msec and v3_migrated.snapshot.game_state.report_state.history.is_empty(), "prospective v3 migration"): return false
	_pass("v3_to_v4_prospective_cursor")
	var v1_to_v4 := SaveMigrationRegistry.new().migrate(_read_fixture("res://tests/fixtures/saves/schema_v1_foundation.json"), SaveEnvelope.SCHEMA_VERSION_V1, SaveEnvelope.SCHEMA_VERSION_V4)
	if not _assert(v1_to_v4.ok and v1_to_v4.snapshot.schema_version == "4", "sequential migration"): return false
	_pass("sequential_v1_v2_v3_v4")
	var historical_bytes := []
	for path in ["res://tests/fixtures/saves/schema_v1_foundation.json", "res://tests/fixtures/saves/schema_v2_m04a_representative.json", "res://tests/fixtures/saves/schema_v3_m04d1_access.json"]:
		historical_bytes.append(FileAccess.get_file_as_bytes(path))
	var after_historical_bytes := []
	for path in ["res://tests/fixtures/saves/schema_v1_foundation.json", "res://tests/fixtures/saves/schema_v2_m04a_representative.json", "res://tests/fixtures/saves/schema_v3_m04d1_access.json"]:
		after_historical_bytes.append(FileAccess.get_file_as_bytes(path))
	if not _assert(historical_bytes == after_historical_bytes, "frozen fixture bytes"): return false
	_pass("frozen_v1_v2_v3_unchanged")

	var encoded := JsonSaveCodec.new().encode(populated_snapshot)
	var decoded := JsonSaveCodec.new().decode(encoded.bytes)
	var round_trip := SaveSchemaMapper.snapshot_to_runtime(decoded.snapshot)
	if not _assert(encoded.ok and decoded.ok and round_trip.ok and populated_runtime.game_state.report_state.value_equals(round_trip.game_state.report_state), "populated round trip"): return false
	_pass("populated_v4_round_trip")

	var real_root := _work_root.path_join("current")
	var real_files := SaveFileSet.new(real_root, "save")
	var real_storage := FileSaveStorage.new()
	var real_service := SaveService.new(real_storage, real_files)
	if not _assert(real_service.save_snapshot(populated_snapshot).ok, "current v4 write"): return false
	var before := FileAccess.get_file_as_bytes(real_files.primary_path)
	var real_coordinator := GameStatePersistenceCoordinator.new(real_service, _registry)
	var current := real_coordinator.load_runtime()
	if not _assert(current.ok and not current.migration_persisted and FileAccess.get_file_as_bytes(real_files.primary_path) == before and not FileAccess.file_exists(real_files.backup_path), "current v4 no rewrite"): return false
	_pass("current_v4_no_rewrite")

	var malformed := populated_snapshot.duplicate(true)
	malformed.game_state.report_state.live.erase("omitted_event_count")
	if not _assert(not SaveSchemaValidator.validate_v4(malformed).ok, "missing key rejection"): return false
	malformed = populated_snapshot.duplicate(true)
	malformed.game_state.report_state.next_event_sequence = "01"
	if not _assert(not SaveSchemaValidator.validate_v4(malformed).ok, "noncanonical integer rejection"): return false
	_pass("malformed_report_matrix_rejected")
	var content_bad: GameState = populated_runtime.game_state.deep_clone()
	content_bad.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].channel_summaries_by_channel_id[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].output_item_id = &"RES_ESSENCE"
	if not _assert(not GameStateValidator.validate(content_bad, _registry).ok, "content relationship rejection"): return false
	_pass("content_relationship_validation")

	var failure_storage := MemorySaveStorage.new()
	var failure_files := SaveFileSet.new("memory://m04e2a2-trace", "save")
	var source_bytes := FileAccess.get_file_as_bytes("res://tests/fixtures/saves/schema_v3_m04d1_access.json")
	failure_storage.files[failure_files.primary_path] = source_bytes.duplicate()
	failure_storage.fail_once("write")
	var failed := GameStatePersistenceCoordinator.new(SaveService.new(failure_storage, failure_files), _registry).load_runtime()
	if not _assert(not failed.ok and failure_storage.files[failure_files.primary_path] == source_bytes and not failed.has("game_state"), "upgrade failure preservation"): return false
	_pass("upgrade_failure_preserves_source")

	var report_files := ["res://src/domain/reports/report_state.gd", "res://src/persistence/report_schema_validator.gd"]
	var no_service := true
	for path in report_files:
		var source := FileAccess.get_file_as_string(path)
		if source.contains("ReportService") or source.contains("ingest_committed_run") or source.contains("snapshot_live"): no_service = false
	if not _assert(no_service, "report service exclusion"): return false
	_pass("no_report_ingestion_or_reads")
	if not _assert(SaveEnvelope.CURRENT_SCHEMA_VERSION == SaveEnvelope.SCHEMA_VERSION_V4 and ContentRegistry.CURRENT_REVISION == "prototype-content-r2" and populated_snapshot.content_revision == ContentRegistry.CURRENT_REVISION, "schema/content revision"): return false
	_pass("schema_v4_content_r2")
	return true

func _read_fixture(path: String) -> Dictionary:
	return JsonSaveCodec.new().decode(FileAccess.get_file_as_bytes(path)).snapshot

func _argument_value(name: String) -> String:
	var args := OS.get_cmdline_user_args()
	for index in range(args.size() - 1):
		if args[index] == name: return str(args[index + 1])
	return ""

func _cleanup() -> void:
	var root := _work_root.path_join("current")
	if DirAccess.dir_exists_absolute(root):
		for path in [root.path_join("save.json"), root.path_join("save.tmp"), root.path_join("save.bak.json")]:
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
		DirAccess.remove_absolute(root)

func _assert(condition: bool, detail: String) -> bool:
	if condition: return true
	push_error("M04E2A2 trace failure: " + detail)
	return false

func _pass(name: String) -> void:
	var marker := "TRACE M04E2A2 %s=PASS" % name
	_markers.append(marker)
	print(marker)

func _fail(detail: String) -> void:
	push_error(detail)
	quit(1)
