class_name SaveService
extends RefCounted

## Coordinates validated save/load transactions across codec and storage.
##
## The service owns candidate selection and atomic file order.  It does not own
## runtime gameplay state and never awards elapsed time itself.  Reconciliation
## transactions work on copied M01 state and expose the candidate only after the
## validated file transaction succeeds, preserving idempotency on failure.

const OK := "OK"
const ERR_NO_VALID_SAVE := "SAVE_LOAD_NO_VALID_CANDIDATE"
const ERR_TEMP_VALIDATION := "SAVE_TEMP_VALIDATION_FAILED"
const ERR_SAVE_FAILED := "SAVE_TRANSACTION_FAILED"

var codec := JsonSaveCodec.new()
var migration_registry := SaveMigrationRegistry.new()
var storage: SaveStorage
var file_set: SaveFileSet

func _init(storage_value: SaveStorage, file_set_value: SaveFileSet) -> void:
	storage = storage_value
	file_set = file_set_value

func save_runtime(game_state: GameState, time_state: TimeAuthorityState, save_revision: int, content_revision: String = SaveEnvelope.DEFAULT_CONTENT_REVISION) -> Dictionary:
	var snapshot := SaveSchemaMapper.runtime_to_snapshot(game_state, time_state, save_revision, content_revision)
	return save_snapshot(snapshot)

func save_snapshot(snapshot: Dictionary) -> Dictionary:
	var validation := SaveSchemaValidator.validate_v1(snapshot)
	if not validation.ok:
		return validation
	var encoded := codec.encode(snapshot)
	if not encoded.ok:
		return encoded
	var write_temp := storage.write_bytes(file_set.temporary_path, encoded.bytes)
	if not write_temp.ok:
		return _fail(write_temp)
	var temp_candidate := _read_candidate(file_set.temporary_path, "temporary")
	if not temp_candidate.ok:
		return _fail({"ok": false, "code": ERR_TEMP_VALIDATION, "diagnostic": temp_candidate})
	if storage.exists(file_set.primary_path):
		var existing := _read_candidate(file_set.primary_path, "primary")
		if existing.ok:
			var backup := storage.copy(file_set.primary_path, file_set.backup_path)
			if not backup.ok:
				return _fail(backup)
		else:
			var preserve := _preserve_invalid_primary(existing)
			if not preserve.ok:
				return _fail(preserve)
	var promote := storage.rename(file_set.temporary_path, file_set.primary_path)
	if not promote.ok:
		return _fail(promote)
	return {"ok": true, "code": OK, "save_revision": validation.save_revision}

func load_snapshot() -> Dictionary:
	var candidates := []
	for role in ["primary", "backup"]:
		var path := file_set.primary_path if role == "primary" else file_set.backup_path
		if storage.exists(path):
			candidates.append(_read_candidate(path, role))
	var valid := []
	var diagnostics := []
	for candidate in candidates:
		if candidate.ok:
			valid.append(candidate)
		else:
			diagnostics.append(candidate)
	if valid.is_empty():
		return {"ok": false, "code": ERR_NO_VALID_SAVE, "diagnostics": diagnostics}
	valid.sort_custom(func(a, b): return a.save_revision > b.save_revision)
	return {"ok": true, "code": OK, "snapshot": valid[0].snapshot, "save_revision": valid[0].save_revision, "selected_role": valid[0].role, "diagnostics": diagnostics}

func load_runtime() -> Dictionary:
	var loaded := load_snapshot()
	if not loaded.ok:
		return loaded
	var runtime := SaveSchemaMapper.snapshot_to_runtime(loaded.snapshot)
	if not runtime.ok:
		return runtime
	runtime["selected_role"] = loaded.selected_role
	runtime["diagnostics"] = loaded.diagnostics
	return runtime

func persist_reconciliation_candidate(game_state: GameState, time_state: TimeAuthorityState, plan: Dictionary, save_revision: int) -> Dictionary:
	var game_copy := GameState.new(game_state.simulation_time_msec)
	var time_copy := TimeAuthorityState.new()
	time_copy.trusted_anchor_utc_msec = time_state.trusted_anchor_utc_msec
	time_copy.trusted_source_id = time_state.trusted_source_id
	time_copy.foreground_credited_since_anchor_msec = time_state.foreground_credited_since_anchor_msec
	time_copy.pending_reconciliation = time_state.pending_reconciliation
	time_copy.last_diagnostic_code = time_state.last_diagnostic_code
	var commit := TimeReconciliationService.new().commit_trusted_reconciliation(game_copy, time_copy, plan)
	if not commit.ok:
		return commit
	var saved := save_runtime(game_copy, time_copy, save_revision)
	if not saved.ok:
		return saved
	return {"ok": true, "code": OK, "game_state": game_copy, "time_authority_state": time_copy, "save_revision": save_revision}

func _read_candidate(path: String, role: String) -> Dictionary:
	var read := storage.read_bytes(path)
	if not read.ok:
		return {"ok": false, "role": role, "path": path, "code": read.code}
	var decoded := codec.decode(read.bytes)
	if not decoded.ok:
		return {"ok": false, "role": role, "path": path, "code": decoded.code}
	var schema_parse := SaveInt64.parse(decoded.snapshot.get("schema_version", ""), false, "schema_version")
	if not schema_parse.ok:
		return {"ok": false, "role": role, "path": path, "code": schema_parse.code}
	var migrated := migration_registry.migrate(decoded.snapshot, schema_parse.value)
	if not migrated.ok:
		return {"ok": false, "role": role, "path": path, "code": migrated.code}
	var validation := SaveSchemaValidator.validate_v1(migrated.snapshot)
	if not validation.ok:
		return {"ok": false, "role": role, "path": path, "code": validation.code, "field_path": validation.get("field_path", "")}
	return {"ok": true, "role": role, "path": path, "snapshot": migrated.snapshot, "save_revision": validation.save_revision}

func _preserve_invalid_primary(existing: Dictionary) -> Dictionary:
	for counter in range(0, 100):
		var path := file_set.suspect_path(0, counter)
		if not storage.exists(path):
			return storage.rename(file_set.primary_path, path)
	return {"ok": false, "code": "SAVE_SUSPECT_PATH_EXHAUSTED"}

func _fail(result: Dictionary) -> Dictionary:
	return {"ok": false, "code": ERR_SAVE_FAILED, "stage_code": result.get("code", "")}
