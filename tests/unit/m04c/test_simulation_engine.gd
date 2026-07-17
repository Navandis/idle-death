extends GutTest

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func _state(backlog := 1000000, active := true, form_id := &"FORM_MAN_AT_ARMS") -> GameState:
	var state := GameState.new(0)
	state.progression.command_tether_capacity = 1
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
	state.forms[&"FORM_SCRIBE"] = GameState.FormState.new(true, true, 0, &"TEST")
	var threshold := GameState.ThresholdState.new()
	threshold.knowledge_state = &"CHARTED"; threshold.availability_state = &"AVAILABLE"; threshold.lifecycle_state = &"OVERDUE" if backlog > 0 else &"SETTLED"; threshold.remaining_backlog = backlog
	state.thresholds[&"THR_GLOAMWOOD"] = threshold
	var reaping := GameState.ReapingState.new()
	reaping.threshold_id = &"THR_GLOAMWOOD"; reaping.is_active = active; reaping.form_id = form_id; reaping.writ_id = &"WRIT_STANDARD"; reaping.assignment_revision = 1
	state.reapings[&"THR_GLOAMWOOD"] = reaping
	return state

func _engine(registry: ContentRegistry = null) -> SimulationEngine:
	return SimulationEngine.new(registry if registry != null else _registry())

func test_rate_plan_production_scribe_and_supported_modifiers() -> void:
	var maa := _state()
	assert_true(_engine().resolve_elapsed_msec(maa, 60000).success)
	assert_eq(maa.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total, 69)
	var scribe := _state(1000000, true, &"FORM_SCRIBE")
	assert_true(_engine().resolve_elapsed_msec(scribe, 60000).success)
	assert_eq(scribe.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total, 60)
	var reg := _registry()
	_add_modifier(reg, "FORM_SCRIBE", "ESSENCE_YIELD", "MULTIPLY", "REAPING_TOTAL", "ALWAYS", [], 2000000)
	_add_modifier(reg, "FORM_SCRIBE", "MASTERY_RATE", "MULTIPLY", "REAPING_TOTAL", "THRESHOLD_HAS_ANY_TAG", ["TAG_SETTLEMENT"], 1500000)
	var boosted := _state(1000000, true, &"FORM_SCRIBE")
	assert_true(_engine(reg).resolve_elapsed_msec(boosted, 60000).success)
	assert_eq(boosted.inventory.entries[&"RES_ESSENCE"].total, 12)
	assert_eq(boosted.forms[&"FORM_SCRIBE"].mastery_subunits, 1500000)

func test_irrelevant_and_unsupported_modifiers_and_essence_channel_errors() -> void:
	var irrelevant := _registry()
	_add_modifier(irrelevant, "FORM_MAN_AT_ARMS", "OUTPUT_CHANNEL_RATE", "MULTIPLY", "OUTPUT_CHANNEL", "ALWAYS", [], 9000000)
	assert_true(_engine(irrelevant).resolve_elapsed_msec(_state(), 1000).success)
	for field in ["operation", "scope", "condition", "operands"]:
		var reg := _registry()
		if field == "operation": _add_modifier(reg, "FORM_MAN_AT_ARMS", "MASTERY_RATE", "ADD", "REAPING_TOTAL", "ALWAYS", [], 1000000)
		elif field == "scope": _add_modifier(reg, "FORM_MAN_AT_ARMS", "MASTERY_RATE", "MULTIPLY", "OUTPUT_CHANNEL", "ALWAYS", [], 1000000)
		elif field == "condition": _add_modifier(reg, "FORM_MAN_AT_ARMS", "MASTERY_RATE", "MULTIPLY", "REAPING_TOTAL", "OUTPUT_ITEM", ["RES_ESSENCE"], 1000000)
		else: _add_modifier(reg, "FORM_MAN_AT_ARMS", "MASTERY_RATE", "MULTIPLY", "REAPING_TOTAL", "ALWAYS", ["BAD"], 1000000)
		var state := _state(); var before := _snapshot(state)
		var failed := _engine(reg).resolve_elapsed_msec(state, 1000)
		assert_eq(failed.error_code, SimulationEngine.ERR_UNSUPPORTED_MODIFIER)
		assert_eq(_snapshot(state), before)
	var missing := _registry(); missing._records["CHANNEL_GLOAMWOOD_ESSENCE"].enabled = false
	assert_eq(_engine(missing).resolve_elapsed_msec(_state(), 1000).error_code, SimulationEngine.ERR_INVALID_CONTENT)
	var ambiguous := _registry(); ambiguous._records["CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].output_item_id = "RES_ESSENCE"; ambiguous._records["CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].enabled = true
	assert_eq(_engine(ambiguous).resolve_elapsed_msec(_state(), 1000).error_code, SimulationEngine.ERR_INVALID_CONTENT)

func test_duration_transaction_debug_and_failures_preserve_state() -> void:
	var zero := _state(); var before_zero := _snapshot(zero)
	var zero_result := _engine().resolve_elapsed_msec(zero, 0)
	assert_true(zero_result.success); assert_eq(zero_result.committed_elapsed_msec, 0); assert_eq(_snapshot(zero), before_zero)
	var idle := GameState.new(5); idle.progression.command_tether_capacity = 1
	var idle_result := _engine().resolve_elapsed_msec(idle, 10)
	assert_true(idle_result.success); assert_eq(idle.simulation_time_msec, 15); assert_eq(idle_result.change_summary.simulation_time_delta_msec, 10)
	var inactive := _state(1000, false)
	assert_true(_engine().resolve_elapsed_msec(inactive, 1000).success)
	assert_eq(inactive.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total, 0)
	var unknown_zero := _state(); unknown_zero.reapings[&"THR_GLOAMWOOD"].flow_carry_units[&"FLOW_UNKNOWN"] = 0
	assert_true(_engine().resolve_elapsed_msec(unknown_zero, 1000).success)
	assert_true(unknown_zero.reapings[&"THR_GLOAMWOOD"].flow_carry_units.has(&"FLOW_UNKNOWN"))
	for mutator in [_make_unknown_nonzero, _make_retinue, _make_concurrent, _make_time_overflow]:
		var state := _state(); mutator.call(state); var before := _snapshot(state); var result := _engine().resolve_elapsed_msec(state, 1000)
		assert_false(result.success); assert_eq(result.requested_elapsed_msec, 1000); assert_eq(result.committed_elapsed_msec, 0); assert_eq(_snapshot(state), before)
	assert_eq(_engine().resolve_elapsed_msec(_state(), -1).requested_elapsed_msec, -1)
	var direct := _state(); var debug := _state()
	var direct_result := _engine().resolve_elapsed_msec(direct, 10000)
	var debug_result := SimulationDebugAdvance.new(_engine()).advance_by_msec(debug, 10000)
	assert_eq(direct_result.success, debug_result.success); assert_eq(_snapshot(direct), _snapshot(debug))

func test_exact_production_settlement_segments_events_and_chunking() -> void:
	var state := _state(1)
	assert_true(_engine().resolve_elapsed_msec(state, 869).success)
	assert_eq(state.thresholds[&"THR_GLOAMWOOD"].remaining_backlog, 1)
	state = _state(1)
	var result := _engine().resolve_elapsed_msec(state, 10000)
	assert_true(result.success); assert_eq(result.events.size(), 1); assert_eq(result.events[0].event_type, SimulationEngine.EVENT_THRESHOLD_SETTLED); assert_eq(result.events[0].occurred_simulation_msec, 870); assert_eq(result.events[0].priority, SimulationEngine.EVENT_PRIORITY_LIFECYCLE); assert_true(result.events[0].reportable); assert_true(result.events[0].tutorial_relevant)
	assert_eq(result.segments.size(), 2); assert_eq(result.segments[0].end_simulation_msec, 870); assert_eq(result.segments[0].lifecycle, "OVERDUE"); assert_eq(result.segments[1].lifecycle, "SETTLED")
	assert_eq(state.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total, 3); assert_eq(state.thresholds[&"THR_GLOAMWOOD"].remaining_backlog, 0); assert_eq(state.thresholds[&"THR_GLOAMWOOD"].lifecycle_state, &"SETTLED")
	var reaping: GameState.ReapingState = state.reapings[&"THR_GLOAMWOOD"]
	assert_eq(reaping.flow_carry_units[SimulationEngine.FLOW_CORE_RETURNS_PROGRESS_SUBUNITS], 625375); assert_eq(reaping.flow_carry_units[SimulationEngine.FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS], 315250); assert_eq(reaping.flow_carry_units[SimulationEngine.FLOW_CORE_MASTERY_RATE_CARRY_UNITS], 40000)
	assert_eq(state.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits, 166666); assert_eq(reaping.cycle_phase_msec, 10000)
	var again := _engine().resolve_elapsed_msec(state, 1000)
	assert_true(again.success); assert_eq(again.events.size(), 0); assert_eq(state.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits, 183333)
	var one := _state(1); var chunked := _state(1)
	assert_true(_engine().resolve_elapsed_msec(one, 10000).success)
	for elapsed in [500, 369, 1, 3000, 6130]: assert_true(_engine().resolve_elapsed_msec(chunked, elapsed).success)
	assert_eq(_snapshot(one), _snapshot(chunked))

func test_residual_overflow_and_source_ownership() -> void:
	var invalid := _state(); invalid.reapings[&"THR_GLOAMWOOD"].flow_carry_units[SimulationEngine.FLOW_CORE_RETURNS_PROGRESS_SUBUNITS] = FixedPoint.SCALE
	assert_eq(_engine().resolve_elapsed_msec(invalid, 1).error_code, SimulationEngine.ERR_INVALID_RESIDUAL)
	var cycle := _state(); cycle.reapings[&"THR_GLOAMWOOD"].cycle_phase_msec = 60000
	assert_eq(_engine().resolve_elapsed_msec(cycle, 1).error_code, SimulationEngine.ERR_INVALID_RESIDUAL)
	var mastery := _state(); mastery.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits = FixedPoint.INT64_MAX
	var before := _snapshot(mastery); var failed := _engine().resolve_elapsed_msec(mastery, 60000)
	assert_eq(failed.error_code, SimulationEngine.ERR_OVERFLOW); assert_eq(_snapshot(mastery), before)
	assert_true(_source_audit_ok())

func _add_modifier(registry: ContentRegistry, form_id: String, metric: String, operation: String, scope: String, condition: String, values: Array, value_subunits: int) -> void:
	registry._records[form_id].traits[0].modifiers.append({"metric": metric, "operation": operation, "scope": scope, "condition": condition, "condition_values": values, "value_subunits": value_subunits})

func _make_unknown_nonzero(state: GameState) -> void: state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[&"FLOW_UNKNOWN"] = 1
func _make_retinue(state: GameState) -> void: state.reapings[&"THR_GLOAMWOOD"].retinue_ids.append(&"RET_SOLDIER_COMPANY")
func _make_time_overflow(state: GameState) -> void: state.simulation_time_msec = FixedPoint.INT64_MAX
func _make_concurrent(state: GameState) -> void:
	state.progression.command_tether_capacity = 2; state.thresholds[&"THR_BROKEN_WATCH"] = state.thresholds[&"THR_GLOAMWOOD"].deep_clone(); state.thresholds[&"THR_BROKEN_WATCH"].remaining_backlog = 1000
	var r: GameState.ReapingState = state.reapings[&"THR_GLOAMWOOD"].deep_clone(); r.threshold_id = &"THR_BROKEN_WATCH"; r.form_id = &"FORM_SCRIBE"; state.reapings[&"THR_BROKEN_WATCH"] = r

func _source_audit_ok() -> bool:
	for path in ["res://src/simulation/simulation_engine.gd", "res://src/debug/simulation_debug_advance.gd"]:
		var text := FileAccess.get_file_as_string(path)
		for raw_line in text.split("\n"):
			var line := raw_line.strip_edges()
			if line.begins_with("#") or line.begins_with("##"): continue
			for token in ["Time.", "get_ticks", "Steam", "GodotSteam", "FileAccess", "DirAccess", "extends Node", "_process", "_physics_process"]:
				if line.find(token) >= 0: return false
	return true

func _snapshot(state: GameState) -> Dictionary:
	return SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, _registry().content_revision).game_state
