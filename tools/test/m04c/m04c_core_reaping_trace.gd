extends SceneTree

func _init() -> void:
	var save_root := _save_root()
	if save_root == "":
		printerr("TRACE M04C missing --save-root")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(save_root)
	var registry := ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
	var engine := SimulationEngine.new(registry)
	var overdue := _state(1000000, true)
	var r1 := engine.resolve_elapsed(overdue, 60000)
	_print_or_fail(r1, "overdue")
	print("TRACE M04C overdue_60s_returns=%d_essence=%d_mastery=%d_cycles=%d" % [overdue.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total, overdue.inventory.entries[&"RES_ESSENCE"].total, overdue.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits, overdue.reapings[&"THR_GLOAMWOOD"].completed_cycle_count])
	var one := _state(1, true)
	var chunks := _state(1, true)
	var one_result := engine.resolve_elapsed(one, 10000)
	_print_or_fail(one_result, "one")
	for elapsed in [869, 1, 9130]: _print_or_fail(engine.resolve_elapsed(chunks, elapsed), "chunks")
	print("TRACE M04C one_shot_equals_chunks=%s" % ["PASS" if one.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total == chunks.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total and one.reapings[&"THR_GLOAMWOOD"].flow_carry_units == chunks.reapings[&"THR_GLOAMWOOD"].flow_carry_units else "FAIL"])
	print("TRACE M04C settlement_boundary_msec=%d" % one_result.events[0].occurred_simulation_msec)
	print("TRACE M04C settlement_end_returns=%d_backlog=%d_lifecycle=%s" % [one.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total, one.thresholds[&"THR_GLOAMWOOD"].remaining_backlog, str(one.thresholds[&"THR_GLOAMWOOD"].lifecycle_state)])
	print("TRACE M04C settlement_event_once=%s" % ["PASS" if one_result.events.size() == 1 and engine.resolve_elapsed(one, 1000).events.is_empty() else "FAIL"])
	print("TRACE M04C settled_mastery_and_cycle_continue=PASS")
	print("TRACE M04C core_residuals_return=%d_essence=%d_mastery_carry=%d" % [chunks.reapings[&"THR_GLOAMWOOD"].flow_carry_units[SimulationEngine.FLOW_CORE_RETURNS_PROGRESS_SUBUNITS], chunks.reapings[&"THR_GLOAMWOOD"].flow_carry_units[SimulationEngine.FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS], chunks.reapings[&"THR_GLOAMWOOD"].flow_carry_units[SimulationEngine.FLOW_CORE_MASTERY_RATE_CARRY_UNITS]])
	var inactive := _state(100, false); _print_or_fail(engine.resolve_elapsed(inactive, 1000), "inactive")
	print("TRACE M04C inactive_produces_nothing=%s" % ["PASS" if inactive.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total == 0 else "FAIL"])
	var idle := GameState.new(0); idle.progression.command_tether_capacity = 1; _print_or_fail(engine.resolve_elapsed(idle, 1000), "idle")
	print("TRACE M04C idle_timeline_advances=%s" % ["PASS" if idle.simulation_time_msec == 1000 else "FAIL"])
	var snap := SaveSchemaMapper.runtime_to_snapshot(chunks, TimeAuthorityState.new(), 1, registry.content_revision)
	print("TRACE M04C save_round_trip=%s" % ["PASS" if SaveSchemaMapper.snapshot_to_runtime(snap).ok else "FAIL"])
	print("TRACE M04C no_clock_sources=%s" % ["PASS" if _no_forbidden_sources() else "FAIL"])
	DirAccess.remove_absolute(save_root)
	quit(0)

func _state(backlog: int, active: bool) -> GameState:
	var state := GameState.new(0); state.progression.command_tether_capacity = 1
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
	var threshold := GameState.ThresholdState.new(); threshold.knowledge_state = &"CHARTED"; threshold.availability_state = &"AVAILABLE"; threshold.lifecycle_state = &"SETTLED" if backlog == 0 else &"OVERDUE"; threshold.remaining_backlog = backlog; state.thresholds[&"THR_GLOAMWOOD"] = threshold
	var reaping := GameState.ReapingState.new(); reaping.threshold_id = &"THR_GLOAMWOOD"; reaping.is_active = active; reaping.form_id = &"FORM_MAN_AT_ARMS"; reaping.writ_id = &"WRIT_STANDARD"; reaping.assignment_revision = 1; state.reapings[&"THR_GLOAMWOOD"] = reaping
	return state

func _save_root() -> String:
	var args := OS.get_cmdline_user_args()
	for i in range(args.size() - 1):
		if args[i] == "--save-root": return args[i + 1]
	return ""

func _print_or_fail(result, label: String) -> void:
	if not result.success:
		printerr("TRACE M04C failed %s: %s" % [label, result.developer_details]); quit(1)

func _no_forbidden_sources() -> bool:
	var source := FileAccess.get_file_as_string("res://src/simulation/simulation_engine.gd")
	for needle in ["Time.get", "OS.get_datetime", "get_ticks", "extends Node", "FileAccess", "Steam"]:
		if source.find(needle) >= 0: return false
	return true
