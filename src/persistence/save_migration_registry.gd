class_name SaveMigrationRegistry
extends RefCounted

## Sequential primitive-dictionary migration registry.
##
## M02 ships only schema v1.  Tests may register explicit in-memory migration
## steps to prove the seam without claiming support for a fictional production
## schema 0 or coupling migration logic to JSON bytes.

const OK := "OK"
const ERR_FUTURE_SCHEMA := "SAVE_MIGRATION_FUTURE_SCHEMA"
const ERR_MISSING_STEP := "SAVE_MIGRATION_MISSING_STEP"
const ERR_FAILED_STEP := "SAVE_MIGRATION_FAILED_STEP"
const ERR_CYCLE := "SAVE_MIGRATION_CYCLE"

var _steps := {}

func register_step(from_version: int, callable: Callable) -> void:
	_steps[from_version] = callable


func migrate(snapshot: Dictionary, from_version: int, target_version: int = SaveEnvelope.CURRENT_SCHEMA_VERSION) -> Dictionary:
	if from_version > target_version:
		return {"ok": false, "code": ERR_FUTURE_SCHEMA}
	var current := from_version
	var data := snapshot.duplicate(true)
	var guard := 0
	while current < target_version:
		guard += 1
		if guard > 32:
			return {"ok": false, "code": ERR_CYCLE}
		if not _steps.has(current):
			return {"ok": false, "code": ERR_MISSING_STEP, "from_version": current}
		var result: Dictionary = _steps[current].call(data.duplicate(true))
		if not result.get("ok", false):
			return {"ok": false, "code": ERR_FAILED_STEP, "from_version": current, "step_code": result.get("code", "")}
		data = result.snapshot
		current += 1
	return {"ok": true, "code": OK, "snapshot": data}
