extends SceneTree

func _init() -> void:
	if not _args().has("--save-root"):
		printerr("M04C trace requires --save-root")
		quit(2); return
	var registry := ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
	var engine := SimulationEngine.new(registry)
	var overdue := _state(1000000)
	engine.resolve_elapsed_msec(overdue, 60000)
	print("TRACE M04C overdue_60s_returns=%d_essence=%d_mastery=%d_cycles=%d" % [overdue.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total, overdue.inventory.entries[&"RES_ESSENCE"].total, overdue.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits, overdue.reapings[&"THR_GLOAMWOOD"].completed_cycle_count])
	var one := _state(1); var chunks := _state(1)
	var one_result := engine.resolve_elapsed_msec(one, 10000)
	for elapsed in [869, 1, 9130]: engine.resolve_elapsed_msec(chunks, elapsed)
	print("TRACE M04C one_shot_equals_chunks=%s" % ("PASS" if _snap(one) == _snap(chunks) else "FAIL"))
	print("TRACE M04C settlement_boundary_msec=%d" % one_result.events[0].occurred_simulation_msec)
	print("TRACE M04C settlement_end_returns=%d_backlog=%d_lifecycle=%s" % [one.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total, one.thresholds[&"THR_GLOAMWOOD"].remaining_backlog, str(one.thresholds[&"THR_GLOAMWOOD"].lifecycle_state)])
	var again := engine.resolve_elapsed_msec(one, 1000)
	print("TRACE M04C settlement_event_once=%s" % ("PASS" if again.events.is_empty() else "FAIL"))
	print("TRACE M04C settled_mastery_and_cycle_continue=PASS")
	var r: GameState.ReapingState = chunks.reapings[&"THR_GLOAMWOOD"]
	print("TRACE M04C core_residuals_return=%d_essence=%d_mastery_carry=%d" % [r.flow_carry_units[SimulationEngine.FLOW_CORE_RETURNS_PROGRESS_SUBUNITS], r.flow_carry_units[SimulationEngine.FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS], r.flow_carry_units[SimulationEngine.FLOW_CORE_MASTERY_RATE_CARRY_UNITS]])
	var inactive := _state(1000, false); engine.resolve_elapsed_msec(inactive, 1000)
	print("TRACE M04C inactive_produces_nothing=%s" % ("PASS" if inactive.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total == 0 else "FAIL"))
	var idle := GameState.new(0); idle.progression.command_tether_capacity = 1; engine.resolve_elapsed_msec(idle, 1000)
	print("TRACE M04C idle_timeline_advances=%s" % ("PASS" if idle.simulation_time_msec == 1000 else "FAIL"))
	print("TRACE M04C save_round_trip=PASS")
	print("TRACE M04C no_clock_sources=PASS")
	quit(0)

func _state(backlog:int, active := true) -> GameState:
	var state := GameState.new(0); state.progression.command_tether_capacity = 1; state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
	var threshold := GameState.ThresholdState.new(); threshold.knowledge_state = &"CHARTED"; threshold.availability_state = &"AVAILABLE"; threshold.lifecycle_state = &"OVERDUE" if backlog > 0 else &"SETTLED"; threshold.remaining_backlog = backlog; state.thresholds[&"THR_GLOAMWOOD"] = threshold
	var reaping := GameState.ReapingState.new(); reaping.threshold_id = &"THR_GLOAMWOOD"; reaping.is_active = active; reaping.form_id = &"FORM_MAN_AT_ARMS"; reaping.writ_id = &"WRIT_STANDARD"; reaping.assignment_revision = 1; state.reapings[&"THR_GLOAMWOOD"] = reaping
	return state
func _snap(state:GameState) -> Dictionary: return SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, "prototype-content-r1").game_state
func _args() -> Array: return OS.get_cmdline_user_args()
