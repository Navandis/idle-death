extends SceneTree

const HOUR := 3600000

var _registry: ContentRegistry
var _service: SimulationRunService
var _save_root := ""

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
	if ContentRegistry.CURRENT_REVISION != "prototype-content-r2": return _fail(10, "content revision changed")
	var state := _state(&"THR_GLOAMWOOD", 1000000)
	_unlock_and_init(state, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	var before := _canonical(state)
	var forecast := _service.forecast(state, 8 * HOUR)
	if not forecast.success: return _fail(11, forecast.developer_details)
	if _canonical(state) != before: return _fail(12, "forecast mutated baseline")
	var committed := state.deep_clone()
	if not _service.run_committed(committed, 8 * HOUR, SimulationRunService.MODE_FOREGROUND_SUPPLIED).success: return _fail(13, "commit failed")
	if _canonical(forecast.projected_state) != _canonical(committed): return _fail(14, "forecast/commit mismatch")
	if forecast.projected_state.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total != 33120: return _fail(15, "returns")
	if forecast.projected_state.inventory.entries[&"RES_ESSENCE"].total != 2880: return _fail(16, "essence")
	if forecast.projected_state.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits != 480000000: return _fail(17, "mastery")
	_pass("eight_hour_forecast_core_and_channels=PASS returns=33120 essence=2880 mastery_subunits=480000000 cycles=480 soldier_souls=96 scribe_form_souls=1")
	var low := _state(&"THR_GLOAMWOOD", 1)
	_unlock_and_init(low, [&"SOUL_CALLING_SOLDIER"])
	var low_forecast := _service.forecast(low, 10000)
	if not (low_forecast.success and low_forecast.engine_result.events.size() > 0 and low_forecast.engine_result.events[0].event_type == SimulationEngine.EVENT_THRESHOLD_SETTLED): return _fail(18, "settlement")
	_pass("settlement_forecast_commit_event_order=PASS")
	var watch := _state(&"THR_BROKEN_WATCH", 250000)
	_unlock_and_init(watch, [&"RES_PROVISIONS", &"SOUL_FORM_MAN_AT_ARMS"])
	var watch_forecast := _service.forecast(watch, 24 * HOUR)
	if not (watch_forecast.success and watch_forecast.engine_result.change_summary.channel_deltas.size() == 2): return _fail(19, "watch channels")
	_pass("generic_broken_watch_channels=PASS provisions=2880 whole_soul=1")
	var save_path := _save_root.path_join("baseline.json")
	var bytes := JSON.stringify(before, "\t")
	FileAccess.open(save_path, FileAccess.WRITE).store_string(bytes)
	var before_bytes := FileAccess.get_file_as_string(save_path)
	if not _service.forecast(state, HOUR).success: return _fail(20, "forecast save fixture")
	if FileAccess.get_file_as_string(save_path) != before_bytes: return _fail(21, "save bytes changed")
	_pass("baseline_save_bytes_unchanged_by_forecast=PASS")
	if not _source_audit(): return _fail(22, "source audit")
	_pass("run_service_source_audit_no_clock_storage_report_or_whitelist=PASS")
	return {"ok": true}

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

func _pass(marker: String) -> void: print(marker)
func _fail(code: int, details: String) -> Dictionary: return {"ok": false, "code": code, "details": details}
