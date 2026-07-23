extends SceneTree

var _failures: Array[String] = []
var _save_root := ""
var _registry: ContentRegistry
var _engine: SimulationEngine

func _init() -> void:
	_save_root = _save_root_arg()
	if _save_root.strip_edges() == "" or _save_root.begins_with("user://"):
		printerr("TRACE M04C invalid --save-root")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(_save_root)
	_registry = ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
	_engine = SimulationEngine.new(_registry)
	_run_trace()
	if _failures.is_empty():
		quit(0)
	else:
		for failure in _failures: printerr("TRACE M04C FAILURE " + failure)
		quit(1)

func _run_trace() -> void:
	var overdue := _state(1000000, true)
	_require(_engine.resolve_elapsed(overdue, 60000), "overdue_60s")
	_marker("overdue_60s_returns=69_essence=6_mastery=1000000_cycles=1", overdue.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total == 69 and overdue.inventory.entries[&"RES_ESSENCE"].total == 6 and overdue.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits == 1000000 and overdue.reapings[&"THR_GLOAMWOOD"].completed_cycle_count == 1)

	var one := _state(1, true)
	var chunks := _state(1, true)
	var one_result = _require(_engine.resolve_elapsed(one, 10000), "one_shot")
	for elapsed in [869, 1, 9130]: _require(_engine.resolve_elapsed(chunks, elapsed), "chunk_%d" % elapsed)
	_marker("one_shot_equals_chunks=PASS", _canonical(one) == _canonical(chunks))

	var early := _state(1, true); _require(_engine.resolve_elapsed(early, 869), "boundary_869")
	var exact := _state(1, true); var exact_result = _require(_engine.resolve_elapsed(exact, 870), "boundary_870")
	var boundary_ok: bool = early.thresholds[&"THR_GLOAMWOOD"].remaining_backlog == 1 and exact.thresholds[&"THR_GLOAMWOOD"].remaining_backlog == 0 and exact_result.events.size() == 1 and exact_result.events[0].occurred_simulation_msec == 870
	_marker("settlement_boundary_msec=870", boundary_ok)
	_marker("settlement_end_returns=3_backlog=0_lifecycle=SETTLED", one.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total == 3 and one.thresholds[&"THR_GLOAMWOOD"].remaining_backlog == 0 and str(one.thresholds[&"THR_GLOAMWOOD"].lifecycle_state) == "SETTLED")
	_marker("settlement_event_once=PASS", _settlement_event_ok(one_result) and _engine.resolve_elapsed(one, 1000).events.is_empty())
	_marker("settled_mastery_and_cycle_continue=PASS", one.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits > 166666 and one.reapings[&"THR_GLOAMWOOD"].cycle_phase_msec == 11000)
	_marker("core_residuals_return=625375_essence=315250_mastery_carry=40000", chunks.reapings[&"THR_GLOAMWOOD"].flow_carry_units[SimulationEngine.FLOW_CORE_RETURNS_PROGRESS_SUBUNITS] == 625375 and chunks.reapings[&"THR_GLOAMWOOD"].flow_carry_units[SimulationEngine.FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS] == 315250 and chunks.reapings[&"THR_GLOAMWOOD"].flow_carry_units[SimulationEngine.FLOW_CORE_MASTERY_RATE_CARRY_UNITS] == 40000)

	var inactive := _state(100, false); var inactive_before := _canonical(inactive); _require(_engine.resolve_elapsed(inactive, 1000), "inactive")
	_marker("inactive_produces_nothing=PASS", inactive.simulation_time_msec == 1000 and inactive.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total == 0 and inactive_before.reapings == _canonical(inactive).reapings)
	var idle := GameState.new(0); idle.progression.command_tether_capacity = 1; _require(_engine.resolve_elapsed(idle, 1000), "idle")
	_marker("idle_timeline_advances=PASS", idle.simulation_time_msec == 1000 and idle.reapings.is_empty())
	_marker("save_round_trip=PASS", _file_round_trip_ok(chunks))
	_marker("no_clock_sources=PASS", _no_forbidden_sources())

func _state(backlog: int, active: bool) -> GameState:
	var state := GameState.new(0); state.progression.command_tether_capacity = 1
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
	var threshold := GameState.ThresholdState.new(); threshold.knowledge_state = &"CHARTED"; threshold.availability_state = &"AVAILABLE"; threshold.lifecycle_state = &"SETTLED" if backlog == 0 else &"OVERDUE"; threshold.remaining_backlog = backlog; state.thresholds[&"THR_GLOAMWOOD"] = threshold
	var reaping := GameState.ReapingState.new(); reaping.threshold_id = &"THR_GLOAMWOOD"; reaping.is_active = active; reaping.form_id = &"FORM_MAN_AT_ARMS"; reaping.writ_id = &"WRIT_STANDARD"; reaping.assignment_revision = 1; state.reapings[&"THR_GLOAMWOOD"] = reaping
	return state

func _require(result, label: String):
	if not result.success: _failures.append(label + ": " + result.developer_details)
	return result

func _marker(text: String, ok: bool) -> void:
	if ok:
		print("TRACE M04C " + text)
	else:
		_failures.append("marker failed: " + text)
		print("TRACE M04C " + text.replace("PASS", "FAIL"))

func _settlement_event_ok(result) -> bool:
	return result.events.size() == 1 and result.events[0].event_type == SimulationEvent.EVENT_THRESHOLD_SETTLED and result.events[0].priority == SimulationEvent.EVENT_PRIORITY_LIFECYCLE and result.events[0].subject_id == &"THR_GLOAMWOOD" and result.events[0].source_id == &"SIMULATION_ENGINE" and result.events[0].reportable and result.events[0].tutorial_relevant

func _file_round_trip_ok(state: GameState) -> bool:
	var files := SaveFileSet.new(_save_root.path_join("save"), "m04c_trace")
	var service := SaveService.new(FileSaveStorage.new(), files)
	var coordinator := GameStatePersistenceCoordinator.new(service, _registry)
	var saved := coordinator.save_runtime(state, TimeAuthorityState.new(), 1)
	if not saved.ok: return false
	var loaded := coordinator.load_runtime()
	return loaded.ok and _canonical(loaded.game_state) == _canonical(state)

func _canonical(state: GameState) -> Dictionary:
	return SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION).game_state

func _save_root_arg() -> String:
	var args := OS.get_cmdline_user_args()
	for i in range(args.size() - 1):
		if args[i] == "--save-root": return args[i + 1]
	return ""

func _no_forbidden_sources() -> bool:
	var source := FileAccess.get_file_as_string("res://src/simulation/simulation_engine.gd") + FileAccess.get_file_as_string("res://src/debug/m04c_debug_advance.gd")
	for needle in ["Time.get", "OS.get_datetime", "get_ticks", "extends Node", "Steam", "Forecast", "Report"]:
		if source.find(needle) >= 0: return false
	return true
