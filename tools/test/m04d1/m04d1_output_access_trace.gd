extends SceneTree

const V1_FIXTURE := "res://tests/fixtures/saves/schema_v1_foundation.json"
const V2_FIXTURE := "res://tests/fixtures/saves/schema_v2_m04a_representative.json"
const MARKERS := [
	"TRACE M04D1 schema_v2_to_v3_empty_unlocks=PASS",
	"TRACE M04D1 legacy_acquisition_preserved_and_item_unlocked=PASS",
	"TRACE M04D1 item_unlock_global=SOUL_FORM_SCRIBE",
	"TRACE M04D1 available_sources_initialized=1",
	"TRACE M04D1 unavailable_threshold_not_disclosed=PASS",
	"TRACE M04D1 future_available_source_reconciled=PASS",
	"TRACE M04D1 unlock_starts_from_zero=PASS",
	"TRACE M04D1 no_retroactive_inventory_or_progress=PASS",
	"TRACE M04D1 repeated_unlock_idempotent=PASS",
	"TRACE M04D1 access_knowledge_insight_separated=PASS",
	"TRACE M04D1 schema_v3_round_trip=PASS",
	"TRACE M04D1 no_clock_or_production_sources=PASS",
]

var _failures: Array[String] = []
var _earned := {}
var _save_root := ""

func _initialize() -> void:
	_save_root = _parse_save_root()
	if _save_root == "": quit(2); return
	DirAccess.make_dir_recursive_absolute(_save_root)
	_run_trace()
	for marker in MARKERS:
		if _earned.has(marker): print(marker)
		else: _fail("Marker was not earned: %s" % marker)
	if _failures.is_empty():
		quit(0)
		return
	for failure in _failures: push_error(failure)
	quit(1)

func _parse_save_root() -> String:
	var args := OS.get_cmdline_user_args()
	for i in range(args.size() - 1):
		if args[i] == "--save-root":
			var root := String(args[i + 1]).strip_edges()
			if root == "" or root.begins_with("user://"):
				push_error("--save-root must be a non-empty disposable filesystem path outside user://")
				return ""
			return root
	push_error("--save-root is required")
	return ""

func _run_trace() -> void:
	var registry := ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
	_assert(registry.ready, "content registry ready")
	var v2 := _fixture(V2_FIXTURE)
	var before_v2 := v2.duplicate(true)
	var pure := SaveMigrationRegistry.new().migrate(v2, SaveEnvelope.SCHEMA_VERSION_V2, SaveEnvelope.SCHEMA_VERSION_V3)
	_assert(pure.ok, "pure v2->v3 migration ok")
	_assert(pure.snapshot.game_state.progression.unlocked_output_item_ids == [], "pure migration empty access")
	_assert(v2 == before_v2, "pure migration deep-copy isolation")
	_earn("TRACE M04D1 schema_v2_to_v3_empty_unlocks=PASS")

	var storage := FileSaveStorage.new()
	var files := SaveFileSet.new(_save_root.path_join("legacy"), "save")
	_assert(storage.write_bytes(files.primary_path, FileAccess.get_file_as_bytes(V2_FIXTURE)).ok, "write v2 fixture")
	var coordinator := GameStatePersistenceCoordinator.new(SaveService.new(storage, files), registry)
	var loaded := coordinator.load_runtime()
	_assert(loaded.ok and loaded.migration_persisted, "v2 coordinator upgrade persisted")
	var acq = loaded.game_state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"]
	_assert(acq.progress_subunits == 250000 and acq.rate_carry_units == 10 and acq.total_banked_units == 1, "legacy acquisition exact")
	_assert(loaded.game_state.progression.unlocked_output_item_ids == [&"SOUL_CALLING_SOLDIER"], "legacy access derived")
	var persisted: Dictionary = JsonSaveCodec.new().decode(storage.read_bytes(files.primary_path).bytes).snapshot
	_assert(persisted.game_state.progression.unlocked_output_item_ids == ["SOUL_CALLING_SOLDIER"], "derived access persisted")
	var bytes_after_upgrade: PackedByteArray = storage.read_bytes(files.primary_path).bytes
	var backup_after_upgrade: PackedByteArray = storage.read_bytes(files.backup_path).bytes
	var revision_after_upgrade: int = loaded.save_revision
	var reloaded := coordinator.load_runtime()
	_assert(reloaded.ok and not reloaded.migration_persisted, "current v3 reload no migration")
	_assert(reloaded.save_revision == revision_after_upgrade, "current v3 reload no revision change")
	_assert(storage.read_bytes(files.primary_path).bytes == bytes_after_upgrade, "current v3 no rewrite")
	_assert(storage.read_bytes(files.backup_path).bytes == backup_after_upgrade, "current v3 no rotation")
	_earn("TRACE M04D1 legacy_acquisition_preserved_and_item_unlocked=PASS")

	var state := _access_state()
	var baseline_before_unlock := _state_no_backfill_signature(state)
	var service := OutputAccessService.new(registry)
	var unlock := service.unlock_output_item(state, &"SOUL_FORM_SCRIBE")
	_assert(unlock.success and unlock.save_checkpoint_requested, "scribe unlock succeeds")
	_assert(unlock.events.size() == 2, "unlock event count")
	_assert(state.progression.unlocked_output_item_ids == [&"SOUL_FORM_SCRIBE"], "scribe globally unlocked")
	_earn("TRACE M04D1 item_unlock_global=SOUL_FORM_SCRIBE")
	_assert(unlock.change_summary.initialized_source_channel_ids == ["CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"], "one available source initialized")
	_earn("TRACE M04D1 available_sources_initialized=1")
	var scribe_acq = state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"]
	_assert(scribe_acq.progress_subunits == 0 and scribe_acq.rate_carry_units == 0 and scribe_acq.total_banked_units == 0, "unlock starts source at zero")
	_earn("TRACE M04D1 unlock_starts_from_zero=PASS")
	var disclosed := service.effective_source_identification(state, &"SOUL_FORM_SCRIBE")
	_assert(disclosed.size() == 1 and disclosed[0].threshold_id == "THR_GLOAMWOOD", "only available source disclosed")
	_assert(str(disclosed).find("THR_BROKEN_WATCH") == -1 and str(disclosed).find("CHANNEL_BROKEN_WATCH") == -1, "unavailable source undisclosed")
	_earn("TRACE M04D1 unavailable_threshold_not_disclosed=PASS")
	state.thresholds[&"THR_BROKEN_WATCH"].availability_state = &"AVAILABLE"
	var baseline_before_reconcile := _state_no_backfill_signature(state)
	var reconcile := service.reconcile_available_sources(state)
	_assert(reconcile.success and state.thresholds[&"THR_BROKEN_WATCH"].channel_acquisition.has(&"CHANNEL_BROKEN_WATCH_PROVISIONS"), "future non-gated source reconciled")
	_earn("TRACE M04D1 future_available_source_reconciled=PASS")
	_assert(_same_no_backfill_facts(baseline_before_unlock, _state_no_backfill_signature(state)), "unlock/reconcile no canonical backfill")
	_assert(_same_no_backfill_facts(baseline_before_reconcile, _state_no_backfill_signature(state)), "reconcile no canonical backfill")
	for threshold in state.thresholds.values():
		for channel_id in threshold.channel_acquisition.keys():
			var a = threshold.channel_acquisition[channel_id]
			_assert(a.progress_subunits == 0 and a.rate_carry_units == 0 and a.total_banked_units == 0, "new source zero progress/carry/banked")
	_earn("TRACE M04D1 no_retroactive_inventory_or_progress=PASS")
	_assert(not service.unlock_output_item(state, &"SOUL_FORM_SCRIBE").save_checkpoint_requested, "repeat unlock no checkpoint")
	_assert(not service.reconcile_available_sources(state).save_checkpoint_requested, "repeat reconcile no checkpoint")
	_earn("TRACE M04D1 repeated_unlock_idempotent=PASS")
	var provisions := service.effective_source_identification(state, &"RES_PROVISIONS")
	var v3_files := SaveFileSet.new(_save_root.path_join("v3"), "save")
	var v3_service := SaveService.new(storage, v3_files)
	_assert(v3_service.save_runtime(state, TimeAuthorityState.new(), 5, registry.content_revision).ok, "v3 save")
	var v3_snapshot: Dictionary = JsonSaveCodec.new().decode(storage.read_bytes(v3_files.primary_path).bytes).snapshot
	_assert(not state.progression.unlocked_output_item_ids.has(&"RES_PROVISIONS") and provisions.size() == 1 and not v3_snapshot.game_state.progression.has("insight"), "access knowledge insight separate")
	_earn("TRACE M04D1 access_knowledge_insight_separated=PASS")
	var v3_loaded := v3_service.load_runtime()
	_assert(v3_loaded.ok and SaveSchemaMapper.runtime_to_snapshot(v3_loaded.game_state, v3_loaded.time_authority_state, v3_loaded.save_revision, registry.content_revision).schema_version == "4", "v4 round trip")
	_earn("TRACE M04D1 schema_v3_round_trip=PASS")
	_assert(_source_ownership_audit(), "source ownership audit")
	_earn("TRACE M04D1 no_clock_or_production_sources=PASS")

func _access_state() -> GameState:
	var state := GameState.new(777777)
	var gloamwood := GameState.ThresholdState.new()
	gloamwood.knowledge_state = &"CHARTED"; gloamwood.availability_state = &"AVAILABLE"; gloamwood.lifecycle_state = &"OVERDUE"; gloamwood.remaining_backlog = 5000
	state.thresholds[&"THR_GLOAMWOOD"] = gloamwood
	var watch := GameState.ThresholdState.new()
	watch.knowledge_state = &"DETECTED"; watch.availability_state = &"LOCKED"; watch.lifecycle_state = &"OVERDUE"; watch.remaining_backlog = 5000
	state.thresholds[&"THR_BROKEN_WATCH"] = watch
	return state

func _source_ownership_audit() -> bool:
	var audited_paths := [
		"res://src/domain/output_access_service.gd",
		"res://src/domain/game_state_validator.gd",
		"res://src/persistence/game_state_persistence_coordinator.gd",
		"res://tools/test/m04d1/m04d1_output_access_trace.gd",
	]
	var forbidden_tokens := [
		"Ti" + "me.",
		"get_unix_" + "time",
		"get_date" + "time",
		"get_modified_" + "time",
		"Simulation" + "Engine",
		"inventory" + ".add",
		"_process" + "(",
		"Ste" + "am",
	]
	for path in audited_paths:
		var text := FileAccess.get_file_as_string(path)
		if text.is_empty():
			_fail("source ownership audit could not read %s" % path)
			return false
		for token in forbidden_tokens:
			if text.find(token) != -1:
				_fail("source ownership audit found %s in %s" % [token, path])
				return false
	return true

func _state_no_backfill_signature(state: GameState) -> Dictionary:
	var snapshot: Dictionary = SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION).game_state
	var thresholds := {}
	for threshold_id in snapshot.thresholds.keys():
		var threshold: Dictionary = snapshot.thresholds[threshold_id]
		var acquisitions := {}
		for channel_id in threshold.channel_acquisition.keys():
			var acq: Dictionary = threshold.channel_acquisition[channel_id]
			# Only pre-existing nonzero work is part of the no-backfill signature. M04D1
			# may add new zero records, but it must never add earned work or banked units.
			if acq.progress_subunits != "0" or acq.rate_carry_units != "0" or acq.total_banked_units != "0":
				acquisitions[channel_id] = acq
		thresholds[threshold_id] = {"knowledge_state": threshold.knowledge_state, "lifecycle_state": threshold.lifecycle_state, "remaining_backlog": threshold.remaining_backlog, "persistent_returns_total": threshold.persistent_returns_total, "familiarity_subunits": threshold.familiarity_subunits, "nonzero_acquisition": acquisitions}
	return {"simulation_time_msec": snapshot.simulation_time_msec, "inventory": snapshot.inventory, "forms": snapshot.forms, "reapings": snapshot.reapings, "thresholds": thresholds, "command_tether_capacity": snapshot.progression.command_tether_capacity}

func _same_no_backfill_facts(a: Dictionary, b: Dictionary) -> bool:
	return a == b

func _fixture(path: String) -> Dictionary:
	var decoded := JsonSaveCodec.new().decode(FileAccess.get_file_as_bytes(path))
	_assert(decoded.ok, "fixture decodes %s" % path)
	return decoded.snapshot

func _earn(marker: String) -> void:
	_earned[marker] = true

func _assert(condition: bool, label: String) -> void:
	if not condition: _fail(label)

func _fail(message: String) -> void:
	_failures.append(message)
