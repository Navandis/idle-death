extends SceneTree

const HOUR := 3600000
const TRACE_PREFIX := "TRACE M04E1 "

var _registry: ContentRegistry
var _service: SimulationRunService
var _save_root := ""
var _markers: Array[String] = []

func _initialize() -> void:
	var setup := _setup()
	if not setup.ok:
		printerr(setup.details); quit(setup.code); return
	var result := _run_trace()
	if not result.ok:
		printerr(result.details); quit(result.code); return
	quit(0)

func _setup() -> Dictionary:
	var args := OS.get_cmdline_user_args()
	for i in range(args.size()):
		if args[i] == "--save-root" and i + 1 < args.size(): _save_root = args[i + 1]
	if _save_root.strip_edges() == "" or _save_root.begins_with("user://"):
		return {"ok": false, "code": 2, "details": "M04E1 trace requires explicit non-user --save-root"}
	_registry = ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
	if not _registry.ready: return {"ok": false, "code": 3, "details": str(_registry.diagnostics)}
	_service = SimulationRunService.new(_registry)
	DirAccess.make_dir_recursive_absolute(_save_root)
	return {"ok": true}

func _run_trace() -> Dictionary:
	var state := _state(&"THR_GLOAMWOOD", 1000000)
	_unlock_and_init(state, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	var baseline_before := _canonical(state)
	var one_hour := _service.forecast(state, HOUR)
	if not one_hour.success: return _fail(10, one_hour.developer_details)
	if not _one_hour_values_match(one_hour.projected_state): return _fail(11, "one-hour fixture mismatch")
	_trace("forecast_1h_returns=4140_essence=360_mastery=60000000_cycles=60_soldier=12_scribe_progress=125000")

	var eight_hour := _service.forecast(state, 8 * HOUR)
	if not eight_hour.success: return _fail(12, eight_hour.developer_details)
	if not _eight_hour_values_match(eight_hour.projected_state): return _fail(13, "eight-hour fixture mismatch")
	_trace("forecast_8h_returns=33120_essence=2880_mastery=480000000_cycles=480_soldier=96_scribe_banked=1")

	var watch := _state(&"THR_BROKEN_WATCH", 250000)
	_unlock_and_init(watch, [&"RES_PROVISIONS", &"SOUL_FORM_MAN_AT_ARMS"])
	var watch_forecast := _service.forecast(watch, 24 * HOUR)
	if not (watch_forecast.success and watch_forecast.engine_result.change_summary.channel_deltas.size() == 2): return _fail(14, "generic channel passthrough")
	if not (watch_forecast.projected_state.inventory.entries[&"RES_PROVISIONS"].total == 2880 and watch_forecast.projected_state.inventory.entries[&"SOUL_FORM_MAN_AT_ARMS"].total == 1): return _fail(15, "Broken Watch outputs")
	_trace("generic_channel_passthrough=PASS")

	if _canonical(state) != baseline_before: return _fail(16, "forecast mutated baseline")
	eight_hour.projected_state.inventory.entries[&"RES_ESSENCE"].total += 1
	if _canonical(state) != baseline_before: return _fail(17, "projection mutation leaked to baseline")
	state.inventory.entries[&"RES_ESSENCE"] = GameState.InventoryEntryState.new(999)
	if eight_hour.projected_state.inventory.entries[&"RES_ESSENCE"].total == 999: return _fail(18, "baseline mutation leaked to projection")
	state = _state(&"THR_GLOAMWOOD", 1000000)
	_unlock_and_init(state, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	_trace("baseline_unchanged_and_projection_detached=PASS")

	# Recompute after the intentional detachment mutation above so equality proves
	# the normal forecast result rather than the mutation-probe copy.
	eight_hour = _service.forecast(state, 8 * HOUR)
	var committed := state.deep_clone()
	var committed_result := _service.run_committed(committed, 8 * HOUR, SimulationRunService.MODE_FOREGROUND_SUPPLIED)
	if not (committed_result.success and eight_hour.success and _canonical(eight_hour.projected_state) == _canonical(committed)): return _fail(19, "forecast/commit equality")
	_trace("forecast_equals_committed_clone=PASS")

	var low_forecast := _service.forecast(_prepared_state(&"THR_GLOAMWOOD", 1, [&"SOUL_CALLING_SOLDIER"]), 10000)
	var low_commit := _prepared_state(&"THR_GLOAMWOOD", 1, [&"SOUL_CALLING_SOLDIER"])
	var low_commit_result := _service.run_committed(low_commit, 10000, SimulationRunService.MODE_FOREGROUND_SUPPLIED)
	if not (low_forecast.success and low_commit_result.success and _canonical(low_forecast.projected_state) == _canonical(low_commit) and low_forecast.engine_result.events.size() > 0 and low_forecast.engine_result.events[0].event_type == SimulationEngine.EVENT_THRESHOLD_SETTLED): return _fail(20, "settlement equivalence")
	_trace("settlement_boundary_equivalence=PASS")

	var foreground := _prepared_state(&"THR_GLOAMWOOD", 1000000, [&"SOUL_CALLING_SOLDIER"])
	var offline := foreground.deep_clone()
	var debug := foreground.deep_clone()
	if not _service.run_committed(foreground, HOUR, SimulationRunService.MODE_FOREGROUND_SUPPLIED).success: return _fail(21, "foreground")
	if not _service.run_committed(offline, HOUR, SimulationRunService.MODE_OFFLINE_FIXTURE).success: return _fail(22, "offline")
	if not _service.run_committed(debug, HOUR, SimulationRunService.MODE_DEBUG).success: return _fail(23, "debug")
	if not (_canonical(foreground) == _canonical(offline) and _canonical(offline) == _canonical(debug)): return _fail(24, "mode equivalence")
	_trace("foreground_offline_fixture_debug_equivalent=PASS")

	var direct_debug := _prepared_state(&"THR_GLOAMWOOD", 1000000, [&"SOUL_CALLING_SOLDIER"])
	var adapter_debug := direct_debug.deep_clone()
	if not _service.run_committed(direct_debug, 60000, SimulationRunService.MODE_DEBUG).success: return _fail(25, "debug service")
	if not M04CDebugAdvance.new(_registry).advance_msec(adapter_debug, 60000).success: return _fail(26, "debug adapter")
	if _canonical(direct_debug) != _canonical(adapter_debug): return _fail(27, "debug adapter equality")
	_trace("debug_adapter_uses_shared_runner=PASS")

	var one_shot := _prepared_state(&"THR_GLOAMWOOD", 1000000, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	var chunks := one_shot.deep_clone()
	if not _service.run_committed(one_shot, HOUR, SimulationRunService.MODE_FOREGROUND_SUPPLIED).success: return _fail(28, "one-shot")
	for elapsed in [1, 999, 1234567, 2364433, 0]:
		if not _service.run_committed(chunks, elapsed, SimulationRunService.MODE_FOREGROUND_SUPPLIED).success: return _fail(29, "chunks")
	if _canonical(one_shot) != _canonical(chunks): return _fail(30, "chunk equality")
	_trace("one_shot_equals_chunks=PASS")

	var zero_failure := _prepared_state(&"THR_GLOAMWOOD", 1000000, [&"SOUL_CALLING_SOLDIER"])
	var zero_before := _canonical(zero_failure)
	var zero := _service.forecast(zero_failure, 0)
	var negative := _service.forecast(zero_failure, -1)
	zero_failure.reapings[&"THR_GLOAMWOOD"].flow_carry_units[&"UNKNOWN"] = 1
	var invalid_before := _canonical(zero_failure)
	var invalid := _service.forecast(zero_failure, 1000)
	if not (zero.success and _canonical(zero.projected_state) == zero_before and not negative.success and negative.projected_state == null and not invalid.success and invalid.projected_state == null and _canonical(zero_failure) == invalid_before): return _fail(31, "zero/failure no mutation")
	_trace("zero_and_failure_no_mutation=PASS")

	if not _event_and_delta_match(): return _fail(32, "events/deltas")
	_trace("events_and_deltas_match_engine=PASS")
	if SaveEnvelope.CURRENT_SCHEMA_VERSION != SaveEnvelope.SCHEMA_VERSION_V3 or ContentRegistry.CURRENT_REVISION != "prototype-content-r2": return _fail(33, "schema/content")
	_trace("schema_v3_content_r2_unchanged=PASS")
	if not _save_bytes_unchanged(baseline_before, state): return _fail(34, "save bytes")
	_trace("isolated_save_bytes_unchanged=PASS")
	if not _no_side_effect_artifacts(state): return _fail(35, "artifact fields")
	_trace("no_report_tutorial_or_checkpoint_side_effects=PASS")
	if not _source_audit(): return _fail(36, "source audit")
	_trace("no_clock_scene_platform_or_duplicate_rules=PASS")
	if _markers.size() != 15: return _fail(37, "expected 15 trace markers")
	return {"ok": true}

func _one_hour_values_match(projected: GameState) -> bool:
	return projected.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total == 4140 \
		and projected.inventory.entries[&"RES_ESSENCE"].total == 360 \
		and projected.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits == 60000000 \
		and projected.reapings[&"THR_GLOAMWOOD"].completed_cycle_count == 60 \
		and projected.inventory.entries[&"SOUL_CALLING_SOLDIER"].total == 12 \
		and projected.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].progress_subunits == 125000

func _eight_hour_values_match(projected: GameState) -> bool:
	return projected.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total == 33120 \
		and projected.inventory.entries[&"RES_ESSENCE"].total == 2880 \
		and projected.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits == 480000000 \
		and projected.reapings[&"THR_GLOAMWOOD"].completed_cycle_count == 480 \
		and projected.inventory.entries[&"SOUL_CALLING_SOLDIER"].total == 96 \
		and projected.inventory.entries[&"SOUL_FORM_SCRIBE"].total == 1

func _event_and_delta_match() -> bool:
	var forecast_state := _prepared_state(&"THR_GLOAMWOOD", 1, [&"SOUL_CALLING_SOLDIER"])
	var commit_state := forecast_state.deep_clone()
	var forecast := _service.forecast(forecast_state, 10000)
	var commit := _service.run_committed(commit_state, 10000, SimulationRunService.MODE_FOREGROUND_SUPPLIED)
	if not (forecast.success and commit.success): return false
	if forecast.engine_result.segments.size() != commit.engine_result.segments.size(): return false
	if forecast.engine_result.change_summary != commit.engine_result.change_summary: return false
	if forecast.engine_result.events.size() != commit.engine_result.events.size(): return false
	for i in range(forecast.engine_result.events.size()):
		var a: SimulationEngine.SimulationEvent = forecast.engine_result.events[i]
		var b: SimulationEngine.SimulationEvent = commit.engine_result.events[i]
		if a.event_type != b.event_type or a.occurred_simulation_msec != b.occurred_simulation_msec or a.subject_id != b.subject_id or a.source_id != b.source_id or a.payload != b.payload: return false
	return true

func _save_bytes_unchanged(_snapshot: Dictionary, state: GameState) -> bool:
	var root := _save_root.path_join("production-save-byte-proof")
	DirAccess.make_dir_recursive_absolute(root)
	var file_set := SaveFileSet.new(root, "m04e1_forecast")
	var coordinator := GameStatePersistenceCoordinator.new(SaveService.new(FileSaveStorage.new(), file_set), _registry)
	var saved := coordinator.save_runtime(state, TimeAuthorityState.new(), 41)
	if not saved.ok: return false
	var saved_again := coordinator.save_runtime(state, TimeAuthorityState.new(), 42)
	if not saved_again.ok: return false
	var loaded := coordinator.load_runtime()
	if not loaded.ok or loaded.save_revision != 42: return false
	if _canonical(loaded.game_state) != _canonical(state): return false
	if not FileAccess.file_exists(file_set.primary_path) or not FileAccess.file_exists(file_set.backup_path): return false
	var primary_before := FileAccess.get_file_as_bytes(file_set.primary_path)
	var backup_before := FileAccess.get_file_as_bytes(file_set.backup_path)
	if primary_before.is_empty() or backup_before.is_empty(): return false
	var forecast := _service.forecast(loaded.game_state, HOUR)
	if not forecast.success: return false
	var primary_after := FileAccess.get_file_as_bytes(file_set.primary_path)
	var backup_after := FileAccess.get_file_as_bytes(file_set.backup_path)
	return primary_before == primary_after and backup_before == backup_after and not FileAccess.file_exists(file_set.temporary_path)

func _no_side_effect_artifacts(state: GameState) -> bool:
	var snapshot := _canonical(state)
	var text := JSON.stringify(snapshot)
	for needle in ["report", "tutorial", "checkpoint", "forecast", "projection", "run_mode", "engine_result"]:
		if text.find(needle) != -1: return false
	return true

func _prepared_state(threshold_id: StringName, backlog: int, item_ids: Array[StringName]) -> GameState:
	var state := _state(threshold_id, backlog)
	_unlock_and_init(state, item_ids)
	return state

func _state(threshold_id: StringName, backlog: int) -> GameState:
	var state := GameState.new(0); state.progression.command_tether_capacity = 1
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
	state.forms[&"FORM_SCRIBE"] = GameState.FormState.new(true, true, 0, &"TEST")
	var threshold := GameState.ThresholdState.new(); threshold.knowledge_state = &"CHARTED"; threshold.availability_state = &"AVAILABLE"; threshold.lifecycle_state = &"SETTLED" if backlog == 0 else &"OVERDUE"; threshold.remaining_backlog = backlog
	state.thresholds[threshold_id] = threshold
	var reaping := GameState.ReapingState.new(); reaping.threshold_id = threshold_id; reaping.is_active = true; reaping.form_id = &"FORM_MAN_AT_ARMS" if threshold_id == &"THR_GLOAMWOOD" else &"FORM_SCRIBE"; reaping.writ_id = &"WRIT_STANDARD"; reaping.assignment_revision = 1
	state.reapings[threshold_id] = reaping
	return state

func _unlock_and_init(state: GameState, item_ids: Array[StringName]) -> void:
	var access := OutputAccessService.new(_registry)
	for item_id in item_ids: access.unlock_output_item(state, item_id)
	access.reconcile_available_sources(state)

func _canonical(state: GameState) -> Dictionary:
	return SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION).game_state

func _source_audit() -> bool:
	var source := FileAccess.get_file_as_string("res://src/simulation/simulation_run_service.gd")
	for needle in ["Time.", "OS.", "FileAccess", "Save", "Report", "Tutorial", "extends Node", "CHANNEL_", "SOUL_", "RES_", "THR_"]:
		if source.find(needle) != -1: return false
	return true

func _trace(marker: String) -> void:
	_markers.append(marker)
	print(TRACE_PREFIX + marker)

func _fail(code: int, details: String) -> Dictionary: return {"ok": false, "code": code, "details": details}
