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
	if loaded.get("migration_required", false) and loaded.get("migration_from_version", SaveEnvelope.CURRENT_SCHEMA_VERSION) <= SaveEnvelope.SCHEMA_VERSION_V2:
		var finalized := _finalize_legacy_access(runtime.game_state)
		if not finalized.ok: return finalized
	var domain := GameStateValidator.validate(runtime.game_state, registry)
	if not domain.ok:
		if loaded.get("migration_required", false) and loaded.get("migration_from_version", SaveEnvelope.CURRENT_SCHEMA_VERSION) <= SaveEnvelope.SCHEMA_VERSION_V2:
			return {"ok": false, "code": OutputAccessService.ERR_MIGRATION_FINALIZATION_FAILED, "diagnostic": domain.get("field_path", "")}
		return domain
	if loaded.get("migration_required", false):
		if loaded.save_revision == FixedPoint.INT64_MAX: return {"ok": false, "code": ERR_REVISION_OVERFLOW}
		var upgrade_snapshot := SaveSchemaMapper.runtime_to_snapshot(runtime.game_state, runtime.time_authority_state, loaded.save_revision + 1, loaded.snapshot.content_revision)
		upgrade_snapshot.metadata = loaded.snapshot.metadata.duplicate(true)
		upgrade_snapshot.last_offline_resolution_id = loaded.snapshot.last_offline_resolution_id
		var target_validation := SaveSchemaValidator.validate_v4(upgrade_snapshot)
		if not target_validation.ok: return target_validation
		var save_result := save_service.save_snapshot(upgrade_snapshot)
		if not save_result.ok: return save_result
		runtime.save_revision = loaded.save_revision + 1
		runtime["migration_persisted"] = true
	else:
		runtime["migration_persisted"] = false
	runtime["selected_role"] = loaded.selected_role
	runtime["diagnostics"] = loaded.diagnostics
	return runtime

func _finalize_legacy_access(game_state: GameState) -> Dictionary:
	## Migration from schema v2 may contain source acquisition that predates global
	## access storage. Derive only the missing global item facts, then reconcile
	## any other currently available source at zero; existing progress/carry/banked
	## values are never rebased or backfilled.
	var service := OutputAccessService.new(registry)
	var threshold_ids: Array = game_state.thresholds.keys()
	threshold_ids.sort()
	for threshold_id in threshold_ids:
		var threshold = game_state.thresholds[threshold_id]
		var channel_ids: Array = threshold.channel_acquisition.keys()
		channel_ids.sort()
		for channel_id in channel_ids:
			var relationship := OutputAccessService.validate_channel_relationship(registry, str(channel_id), "", str(threshold_id))
			if not relationship.ok:
				return {"ok": false, "code": OutputAccessService.ERR_MIGRATION_FINALIZATION_FAILED, "diagnostic": relationship.code}
			var channel: Dictionary = relationship.channel
			var item_id := StringName(channel.output_item_id)
			if not game_state.progression.unlocked_output_item_ids.has(item_id):
				game_state.progression.unlocked_output_item_ids.append(item_id)
	game_state.progression.unlocked_output_item_ids.sort()
	var reconcile := service.reconcile_available_sources(game_state)
	return {"ok": true} if reconcile.success else {"ok": false, "code": OutputAccessService.ERR_MIGRATION_FINALIZATION_FAILED, "diagnostic": reconcile.developer_details}
