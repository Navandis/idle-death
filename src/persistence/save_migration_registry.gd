class_name SaveMigrationRegistry
extends RefCounted

## Sequential primitive-dictionary migration registry.
##
## Production registers the real M04A v1-to-v2 step.  Each step receives a deep
## copied working candidate and returns a primitive snapshot; source validation
## remains version-specific so corrupt historical data is rejected before any
## upgrade can be persisted or exposed.

const OK := "OK"
const ERR_FUTURE_SCHEMA := "SAVE_MIGRATION_FUTURE_SCHEMA"
const ERR_MISSING_STEP := "SAVE_MIGRATION_MISSING_STEP"
const ERR_FAILED_STEP := "SAVE_MIGRATION_FAILED_STEP"
const ERR_CYCLE := "SAVE_MIGRATION_CYCLE"
const ERR_SOURCE_INVALID := "SAVE_MIGRATION_SOURCE_INVALID"

var _steps := {}

func _init() -> void:
	register_step(SaveEnvelope.SCHEMA_VERSION_V1, Callable(self, "_migrate_v1_to_v2"))
	register_step(SaveEnvelope.SCHEMA_VERSION_V2, Callable(self, "_migrate_v2_to_v3"))
	register_step(SaveEnvelope.SCHEMA_VERSION_V3, Callable(self, "_migrate_v3_to_v4"))

func register_step(from_version: int, callable: Callable) -> void:
	_steps[from_version] = callable

func migrate(snapshot: Dictionary, from_version: int, target_version: int = SaveEnvelope.CURRENT_SCHEMA_VERSION) -> Dictionary:
	if from_version > target_version: return {"ok": false, "code": ERR_FUTURE_SCHEMA}
	var current := from_version
	var data := snapshot.duplicate(true)
	var guard := 0
	while current < target_version:
		guard += 1
		if guard > 32: return {"ok": false, "code": ERR_CYCLE}
		if not _steps.has(current): return {"ok": false, "code": ERR_MISSING_STEP, "from_version": current}
		var result: Dictionary = _steps[current].call(data.duplicate(true))
		if not result.get("ok", false): return {"ok": false, "code": ERR_FAILED_STEP, "from_version": current, "step_code": result.get("code", "")}
		data = result.snapshot
		current += 1
	return {"ok": true, "code": OK, "snapshot": data, "migrated": from_version != target_version}

func _migrate_v1_to_v2(snapshot: Dictionary) -> Dictionary:
	var source := SaveSchemaValidator.validate_v1(snapshot)
	if not source.ok: return {"ok": false, "code": ERR_SOURCE_INVALID, "source_code": source.code}
	var migrated := snapshot.duplicate(true)
	migrated.schema_version = SaveInt64.format(SaveEnvelope.SCHEMA_VERSION_V2)
	migrated.game_state["inventory"] = {"entries": {}}
	migrated.game_state["forms"] = {}
	migrated.game_state["thresholds"] = {}
	migrated.game_state["reapings"] = {}
	migrated.game_state["progression"] = {"command_tether_capacity": "0"}
	return {"ok": true, "code": OK, "snapshot": migrated}

func _migrate_v2_to_v3(snapshot: Dictionary) -> Dictionary:
	var source := SaveSchemaValidator.validate_v2(snapshot)
	if not source.ok: return {"ok": false, "code": ERR_SOURCE_INVALID, "source_code": source.code}
	var migrated := snapshot.duplicate(true)
	migrated.schema_version = SaveInt64.format(SaveEnvelope.SCHEMA_VERSION_V3)
	migrated.game_state.progression["unlocked_output_item_ids"] = []
	return {"ok": true, "code": OK, "snapshot": migrated}


func _migrate_v3_to_v4(snapshot: Dictionary) -> Dictionary:
	var source := SaveSchemaValidator.validate_v3(snapshot)
	if not source.ok: return {"ok": false, "code": ERR_SOURCE_INVALID, "source_code": source.code}
	var migrated := snapshot.duplicate(true)
	migrated.schema_version = SaveInt64.format(SaveEnvelope.SCHEMA_VERSION_V4)
	var cursor: String = migrated.game_state.simulation_time_msec
	migrated.game_state["report_state"] = {
		"report_cursor_msec": cursor,
		"next_report_sequence": "1",
		"next_event_sequence": "1",
		"dropped_history_record_count": "0",
		"live": _empty_report_window(cursor),
		"history": [],
	}
	return {"ok": true, "code": OK, "snapshot": migrated}

func _empty_report_window(cursor: String) -> Dictionary:
	return {"start_simulation_msec": cursor, "end_simulation_msec": cursor, "run_count": "0", "mode_counts": {}, "slices": {}, "events_by_type": {}, "event_details": [], "omitted_oldest_event_detail_count": "0"}
