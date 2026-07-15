class_name GameStatePersistenceCoordinator
extends RefCounted

## Runtime persistence coordinator for M04A upgrade-before-exposure loads.
##
## SaveService remains byte/storage/schema focused. This coordinator owns the
## cross-boundary order: select and migrate a primitive candidate, construct a
## working runtime candidate, verify content compatibility and domain invariants,
## atomically persist required upgrades with exactly one revision increment, and
## only then return runtime state.  Write failures preserve the source candidate
## and return no migrated live state.

const OK := "OK"
const ERR_CONTENT := "SAVE_CONTENT_INCOMPATIBLE"
const ERR_REVISION_OVERFLOW := "SAVE_REVISION_OVERFLOW"

var save_service: SaveService
var registry: ContentRegistry

func _init(service: SaveService, content_registry: ContentRegistry) -> void:
	save_service = service
	registry = content_registry

func save_runtime(game_state: GameState, time_state: TimeAuthorityState, save_revision: int) -> Dictionary:
	var validation := GameStateValidator.validate(game_state, registry)
	if not validation.ok: return validation
	return save_service.save_runtime(game_state, time_state, save_revision, registry.content_revision)

func load_runtime() -> Dictionary:
	var loaded := save_service.load_snapshot()
	if not loaded.ok: return loaded
	if not registry.is_save_revision_compatible(loaded.snapshot.content_revision): return {"ok": false, "code": ERR_CONTENT}
	var runtime := SaveSchemaMapper.snapshot_to_runtime(loaded.snapshot)
	if not runtime.ok: return runtime
	var domain := GameStateValidator.validate(runtime.game_state, registry)
	if not domain.ok: return domain
	if loaded.get("migration_required", false):
		if loaded.save_revision == FixedPoint.INT64_MAX: return {"ok": false, "code": ERR_REVISION_OVERFLOW}
		var save_result := save_service.save_runtime(runtime.game_state, runtime.time_authority_state, loaded.save_revision + 1, runtime.content_revision)
		if not save_result.ok: return save_result
		runtime.save_revision = loaded.save_revision + 1
		runtime["migration_persisted"] = true
	else:
		runtime["migration_persisted"] = false
	runtime["selected_role"] = loaded.selected_role
	runtime["diagnostics"] = loaded.diagnostics
	return runtime
