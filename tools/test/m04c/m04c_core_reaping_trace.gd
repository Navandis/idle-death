extends SceneTree

var failures: Array[String] = []
var save_root := ""

func _init() -> void:
	save_root = _parse_save_root()
	if save_root.strip_edges() == "" or save_root.begins_with("user://"):
		printerr("M04C trace requires a nonblank non-user:// --save-root value.")
		quit(2); return
	var registry := ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
	var engine := SimulationEngine.new(registry)
	var overdue := _state(1000000)
	var overdue_result := engine.resolve_elapsed_msec(overdue, 60000)
	_check(overdue_result.success, "overdue result")
	_check(overdue.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total == 69, "overdue returns")
	_check(overdue.inventory.entries[&"RES_ESSENCE"].total == 6, "overdue essence")
	_check(overdue.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits == 1000000, "overdue mastery")
	_check(overdue.reapings[&"THR_GLOAMWOOD"].completed_cycle_count == 1, "overdue cycle")
	_emit_exact("TRACE M04C overdue_60s_returns=69_essence=6_mastery=1000000_cycles=1")

	var pre := _state(1)
	_check(engine.resolve_elapsed_msec(pre, 869).success, "869 result")
	_check(pre.thresholds[&"THR_GLOAMWOOD"].remaining_backlog == 1 and pre.thresholds[&"THR_GLOAMWOOD"].lifecycle_state == &"OVERDUE", "869 non settlement")
	var one := _state(1); var chunks := _state(1)
	var one_result := engine.resolve_elapsed_msec(one, 10000)
	_check(one_result.success, "one shot")
	for elapsed in [869, 1, 9130]: _check(engine.resolve_elapsed_msec(chunks, elapsed).success, "chunk %d" % elapsed)
	_check(_snap(one) == _snap(chunks), "chunk equality")
	_emit_exact("TRACE M04C one_shot_equals_chunks=PASS")
	_check(one_result.events.size() == 1 and one_result.events[0].occurred_simulation_msec == 870 and one_result.events[0].event_type == SimulationEngine.EVENT_THRESHOLD_SETTLED and one_result.events[0].reportable and one_result.events[0].tutorial_relevant, "settlement event")
	_emit_exact("TRACE M04C settlement_boundary_msec=870")
	_check(one.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total == 3 and one.thresholds[&"THR_GLOAMWOOD"].remaining_backlog == 0 and one.thresholds[&"THR_GLOAMWOOD"].lifecycle_state == &"SETTLED", "settlement end")
	_emit_exact("TRACE M04C settlement_end_returns=3_backlog=0_lifecycle=SETTLED")
	var before_settled_mastery: int = one.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits
	var again := engine.resolve_elapsed_msec(one, 1000)
	_check(again.success and again.events.is_empty(), "settled repeat")
	_emit_exact("TRACE M04C settlement_event_once=PASS")
	_check(one.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits > before_settled_mastery and one.reapings[&"THR_GLOAMWOOD"].cycle_phase_msec == 11000, "settled mastery cycle")
	_emit_exact("TRACE M04C settled_mastery_and_cycle_continue=PASS")
	var r: GameState.ReapingState = chunks.reapings[&"THR_GLOAMWOOD"]
	_check(r.flow_carry_units[SimulationEngine.FLOW_CORE_RETURNS_PROGRESS_SUBUNITS] == 625375 and r.flow_carry_units[SimulationEngine.FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS] == 315250 and r.flow_carry_units[SimulationEngine.FLOW_CORE_MASTERY_RATE_CARRY_UNITS] == 40000, "residuals")
	_emit_exact("TRACE M04C core_residuals_return=625375_essence=315250_mastery_carry=40000")
	var inactive := _state(1000, false); var inactive_before := _snap(inactive)
	_check(engine.resolve_elapsed_msec(inactive, 1000).success, "inactive result")
	_check(inactive.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total == 0 and inactive.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits == 0 and inactive.reapings[&"THR_GLOAMWOOD"].cycle_phase_msec == 0, "inactive no production")
	_emit_exact("TRACE M04C inactive_produces_nothing=PASS")
	var idle := GameState.new(0); idle.progression.command_tether_capacity = 1; _check(engine.resolve_elapsed_msec(idle, 1000).success and idle.simulation_time_msec == 1000, "idle timeline")
	_emit_exact("TRACE M04C idle_timeline_advances=PASS")
	_check(_file_round_trip(one, registry), "file save round trip")
	_emit_exact("TRACE M04C save_round_trip=PASS")
	_check(_source_audit_ok(), "source audit")
	_emit_exact("TRACE M04C no_clock_sources=PASS")
	if failures.is_empty():
		quit(0); return
	for failure in failures: printerr("TRACE M04C FAILURE: %s" % failure)
	quit(1)

func _parse_save_root() -> String:
	var args := OS.get_cmdline_user_args()
	for i in range(args.size()):
		if args[i] == "--save-root" and i + 1 < args.size(): return str(args[i + 1]).strip_edges()
		if str(args[i]).begins_with("--save-root="): return str(args[i]).substr("--save-root=".length()).strip_edges()
	return ""

func _file_round_trip(state: GameState, registry: ContentRegistry) -> bool:
	var files := SaveFileSet.new(save_root.path_join("m04c-save"), "trace")
	var coordinator := GameStatePersistenceCoordinator.new(SaveService.new(FileSaveStorage.new(), files), registry)
	var saved := coordinator.save_runtime(state, TimeAuthorityState.new(), 1)
	if not saved.ok: return false
	var loaded := coordinator.load_runtime()
	return loaded.ok and _snap(loaded.game_state) == _snap(state)

func _source_audit_ok() -> bool:
	for path in ["res://src/simulation/simulation_engine.gd", "res://src/debug/simulation_debug_advance.gd"]:
		var text := FileAccess.get_file_as_string(path)
		for raw_line in text.split("\n"):
			var line := raw_line.strip_edges()
			if line.begins_with("#") or line.begins_with("##"): continue
			for token in ["Time.", "get_ticks", "Steam", "GodotSteam", "FileAccess", "DirAccess", "extends Node", "_process", "_physics_process"]:
				if line.find(token) >= 0: return false
	return true

func _emit_exact(marker: String) -> void:
	if failures.is_empty(): print(marker)

func _check(condition: bool, label: String) -> void:
	if not condition: failures.append(label)

func _state(backlog:int, active := true) -> GameState:
	var state := GameState.new(0); state.progression.command_tether_capacity = 1; state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
	var threshold := GameState.ThresholdState.new(); threshold.knowledge_state = &"CHARTED"; threshold.availability_state = &"AVAILABLE"; threshold.lifecycle_state = &"OVERDUE" if backlog > 0 else &"SETTLED"; threshold.remaining_backlog = backlog; state.thresholds[&"THR_GLOAMWOOD"] = threshold
	var reaping := GameState.ReapingState.new(); reaping.threshold_id = &"THR_GLOAMWOOD"; reaping.is_active = active; reaping.form_id = &"FORM_MAN_AT_ARMS"; reaping.writ_id = &"WRIT_STANDARD"; reaping.assignment_revision = 1; state.reapings[&"THR_GLOAMWOOD"] = reaping
	return state
func _snap(state:GameState) -> Dictionary: return SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, "prototype-content-r1").game_state
