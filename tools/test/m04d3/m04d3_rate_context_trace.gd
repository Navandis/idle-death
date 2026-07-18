extends SceneTree

const CHANNEL := &"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"

var _registry: ContentRegistry
var _rate_context: ReapingRateContextService
var _assignment: ReapingAssignmentService
var _engine: SimulationEngine
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
		if args[i] == "--save-root" and i + 1 < args.size():
			_save_root = args[i + 1]
	if _save_root.strip_edges() == "" or _save_root.begins_with("user://"):
		return {"ok": false, "code": 2, "details": "M04D3 trace requires explicit non-user --save-root"}
	_registry = ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
	if not _registry.ready:
		return {"ok": false, "code": 3, "details": str(_registry.diagnostics)}
	_rate_context = ReapingRateContextService.new(_registry)
	_assignment = ReapingAssignmentService.new(_registry)
	_engine = SimulationEngine.new(_registry)
	DirAccess.make_dir_recursive_absolute(_save_root)
	return {"ok": true}

func _run_trace() -> Dictionary:
	if not _supported_swap_marker(): return _fail(10, "supported swap")
	if not _normalization_marker("returned_soul_period_msec", func(reg): reg._records["FORM_SCRIBE"].base_returned_souls_rate.period_msec = 2000): return _fail(11, "return normalization")
	_pass("return_period_change_requires_normalization=PASS")
	if not _normalization_marker("mastery_period_msec", func(reg): reg._records["FORM_SCRIBE"].active_mastery_rate.period_msec = 120000): return _fail(12, "mastery normalization")
	_pass("mastery_period_change_requires_normalization=PASS")
	if not _normalization_marker("cycle_duration_msec", func(reg): reg._records["FORM_SCRIBE"].cycle_duration_msec = 120000): return _fail(13, "cycle normalization")
	_pass("cycle_duration_change_requires_normalization=PASS")
	if not _modifier_and_eta_markers(): return _fail(14, "modifier and eta")
	if not _old_new_bank_marker(): return _fail(15, "old/new bank")
	if not _redispatch_markers(): return _fail(16, "redispatch markers")
	if not _sequence_marker(): return _fail(17, "sequence")
	if not _inactive_marker(): return _fail(18, "inactive")
	if not _chunk_marker(): return _fail(19, "chunk")
	if not _persistence_marker(): return _fail(20, "persistence")
	if not _source_audit_marker(): return _fail(21, "source audit")
	return {"ok": true}

func _supported_swap_marker() -> bool:
	var state := _state(true)
	state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[CoreFlowKeys.RETURNS_PROGRESS] = 111111
	state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[CoreFlowKeys.RETURNS_CARRY] = 222
	state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[CoreFlowKeys.ESSENCE_PROGRESS] = 333333
	state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[CoreFlowKeys.ESSENCE_CARRY] = 444
	state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[CoreFlowKeys.MASTERY_CARRY] = 555
	state.reapings[&"THR_GLOAMWOOD"].cycle_phase_msec = 1000
	state.reapings[&"THR_GLOAMWOOD"].completed_cycle_count = 2
	state.reapings[&"THR_GLOAMWOOD"].started_simulation_msec = 0
	if not _engine.resolve_elapsed(state, 1000).success: return false
	var before := _canonical(state)
	if not _assignment.recall(state, &"THR_GLOAMWOOD", 1).success: return false
	if not _assignment.redispatch(state, &"THR_GLOAMWOOD", &"FORM_SCRIBE", &"WRIT_STANDARD", 2).success: return false
	var after := _canonical(state)
	for key in ["flow_carry_units", "cycle_phase_msec", "completed_cycle_count", "started_simulation_msec"]:
		if before.reapings.THR_GLOAMWOOD[key] != after.reapings.THR_GLOAMWOOD[key]: return false
	if before.thresholds != after.thresholds or before.inventory != after.inventory: return false
	if after.reapings.THR_GLOAMWOOD.form_id != "FORM_SCRIBE" or after.reapings.THR_GLOAMWOOD.assignment_revision != "3": return false
	_pass("supported_swap_preserves_core_and_channel_residuals=PASS")
	return true

func _normalization_marker(field: String, mutate: Callable) -> bool:
	var registry := ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
	mutate.call(registry)
	var state := _state(false)
	var before := _canonical(state)
	var result := ReapingAssignmentService.new(registry).redispatch(state, &"THR_GLOAMWOOD", &"FORM_SCRIBE", &"WRIT_STANDARD", 1)
	return (not result.success and result.error_code == ReapingAssignmentService.REAPING_RATE_CONTEXT_NORMALIZATION_REQUIRED and result.developer_details.contains(field) and _canonical(state) == before)

func _modifier_and_eta_markers() -> bool:
	var registry := _registry_with_scribe_modifier()
	registry._records["CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].rate.period_msec = 14400000
	var service := ReapingRateContextService.new(registry)
	var plan := service.output_channel_rate_plan(&"THR_GLOAMWOOD", &"FORM_SCRIBE", CHANNEL, "OVERDUE")
	if not (plan.success and plan.baseline_rate_subunits_per_period == 1000000 and plan.effective_rate_subunits_per_period == 1200000): return false
	_pass("output_modifier_rate_before=1000000_after=1200000")
	var maa_identity := service.loadout_identity(&"FORM_MAN_AT_ARMS", &"WRIT_STANDARD")
	var scribe_identity := service.loadout_identity(&"FORM_SCRIBE", &"WRIT_STANDARD")
	var equal_a := _rate_context.output_channel_rate_plan(&"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", CHANNEL, "OVERDUE")
	var equal_b := _rate_context.output_channel_rate_plan(&"THR_GLOAMWOOD", &"FORM_SCRIBE", CHANNEL, "OVERDUE")
	if not (maa_identity != scribe_identity and equal_a.success and equal_b.success and equal_a.effective_rate_subunits_per_period == equal_b.effective_rate_subunits_per_period and equal_a.loadout_identity != equal_b.loadout_identity): return false
	_pass("equal_output_loadouts_remain_distinct=PASS")
	var baseline_state := _state(true)
	baseline_state.reapings[&"THR_GLOAMWOOD"].form_id = &"FORM_MAN_AT_ARMS"
	baseline_state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[CHANNEL].progress_subunits = 500000
	var modified_state := _state(true)
	modified_state.reapings[&"THR_GLOAMWOOD"].form_id = &"FORM_SCRIBE"
	modified_state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[CHANNEL].progress_subunits = 500000
	var before_q := service.query_acquisition(baseline_state, &"THR_GLOAMWOOD", CHANNEL)
	var after_q := service.query_acquisition(modified_state, &"THR_GLOAMWOOD", CHANNEL)
	if not (before_q.success and after_q.success and before_q.current_context_eta_msec == 7200000 and after_q.current_context_eta_msec == 6000000 and after_q.progress_subunits == 500000): return false
	_pass("progress=500000_eta_before=7200000_eta_after=6000000")
	var short_display := service.eta_display(13935000)
	var long_display := service.eta_display(183840000)
	if not (short_display.components.size() == 3 and long_display.components.size() == 3): return false
	var short_text: String = short_display.english_text.replace(", ", "_").replace(" ", "_")
	var long_text: String = long_display.english_text.replace(", ", "_").replace(" ", "_")
	if not (short_text == "03_hours_52_minutes_15_seconds" and long_text == "02_days_03_hours_04_minutes"): return false
	_pass("eta_display_short=03_hours_52_minutes_15_seconds_long=02_days_03_hours_04_minutes")
	return true

func _old_new_bank_marker() -> bool:
	var registry := _registry_with_scribe_modifier()
	registry._records["CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].rate.period_msec = 14400000
	var service := ReapingRateContextService.new(registry)
	var assignment := ReapingAssignmentService.new(registry)
	var engine := SimulationEngine.new(registry)
	var state := _state(true)
	var acq: GameState.ThresholdAcquisitionState = state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[CHANNEL]
	acq.progress_subunits = 0
	acq.rate_carry_units = 0
	if not engine.resolve_elapsed(state, 7200000).success: return false
	acq = state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[CHANNEL]
	if acq.progress_subunits != 500000 or acq.total_banked_units != 0: return false
	if not assignment.recall(state, &"THR_GLOAMWOOD", 1).success: return false
	var progress_before_swap: int = acq.progress_subunits
	if not assignment.redispatch(state, &"THR_GLOAMWOOD", &"FORM_SCRIBE", &"WRIT_STANDARD", 2).success: return false
	acq = state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[CHANNEL]
	if acq.progress_subunits != progress_before_swap or acq.progress_subunits != 500000: return false
	var query := service.query_acquisition(state, &"THR_GLOAMWOOD", CHANNEL)
	if not (query.success and query.current_context_eta_msec == 6000000 and query.progress_subunits == 500000): return false
	if not engine.resolve_elapsed(state, 6000000).success: return false
	acq = state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[CHANNEL]
	if state.inventory.entries.get(&"SOUL_FORM_SCRIBE", GameState.InventoryEntryState.new()).total != 1: return false
	if acq.total_banked_units != 1 or acq.progress_subunits != 0: return false
	_pass("old_context_then_new_context_banks_one=PASS")
	return true

func _redispatch_markers() -> bool:
	var registry := _registry_with_scribe_modifier()
	var service := ReapingRateContextService.new(registry)
	var assignment := ReapingAssignmentService.new(registry)
	var state := _state(false)
	if not assignment.redispatch(state, &"THR_GLOAMWOOD", &"FORM_SCRIBE", &"WRIT_STANDARD", 1).success: return false
	if service.output_channel_rate_plan(&"THR_GLOAMWOOD", &"FORM_SCRIBE", CHANNEL, "OVERDUE").effective_rate_subunits_per_period != 1200000: return false
	if not assignment.recall(state, &"THR_GLOAMWOOD", 2).success: return false
	if not assignment.redispatch(state, &"THR_GLOAMWOOD", &"FORM_SCRIBE", &"WRIT_STANDARD", 3).success: return false
	if service.output_channel_rate_plan(&"THR_GLOAMWOOD", &"FORM_SCRIBE", CHANNEL, "OVERDUE").effective_rate_subunits_per_period != 1200000: return false
	_pass("repeated_redispatch_non_compounding=PASS")
	if not assignment.recall(state, &"THR_GLOAMWOOD", 4).success: return false
	if not assignment.redispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", 5).success: return false
	if service.output_channel_rate_plan(&"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", CHANNEL, "OVERDUE").effective_rate_subunits_per_period != 1000000: return false
	_pass("return_to_prior_loadout_restores_baseline=PASS")
	return true

func _sequence_marker() -> bool:
	var registry := _registry_with_scribe_modifier()
	var service := ReapingRateContextService.new(registry)
	var assignment := ReapingAssignmentService.new(registry)
	var state := _two_threshold_state()
	state.reapings.clear()
	var loadout_a := service.loadout_identity(&"FORM_MAN_AT_ARMS", &"WRIT_STANDARD")
	var loadout_b := service.loadout_identity(&"FORM_SCRIBE", &"WRIT_STANDARD")
	if loadout_a == loadout_b: return false
	if not assignment.dispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD").success: return false
	var gloamwood_first_start: int = state.reapings[&"THR_GLOAMWOOD"].started_simulation_msec
	state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[CHANNEL].progress_subunits = 123456
	if not assignment.recall(state, &"THR_GLOAMWOOD", 1).success: return false
	if not assignment.redispatch(state, &"THR_GLOAMWOOD", &"FORM_SCRIBE", &"WRIT_STANDARD", 2).success: return false
	state.simulation_time_msec = 1000
	if not assignment.dispatch(state, &"THR_BROKEN_WATCH", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD").success: return false
	state.thresholds[&"THR_BROKEN_WATCH"].channel_acquisition[&"CHANNEL_BROKEN_WATCH_PROVISIONS"].progress_subunits = 654321
	var watch_first_start: int = state.reapings[&"THR_BROKEN_WATCH"].started_simulation_msec
	if not assignment.recall(state, &"THR_BROKEN_WATCH", 1).success: return false
	if not assignment.recall(state, &"THR_GLOAMWOOD", 3).success: return false
	if not assignment.redispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", 4).success: return false
	if state.reapings[&"THR_GLOAMWOOD"].threshold_id != &"THR_GLOAMWOOD": return false
	if state.reapings[&"THR_GLOAMWOOD"].started_simulation_msec != gloamwood_first_start: return false
	if state.reapings[&"THR_BROKEN_WATCH"].started_simulation_msec != watch_first_start: return false
	if state.reapings[&"THR_GLOAMWOOD"].assignment_revision != 5 or state.reapings[&"THR_BROKEN_WATCH"].assignment_revision != 2: return false
	if state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[CHANNEL].progress_subunits != 123456: return false
	if state.thresholds[&"THR_BROKEN_WATCH"].channel_acquisition[&"CHANNEL_BROKEN_WATCH_PROVISIONS"].progress_subunits != 654321: return false
	if service.loadout_identity(state.reapings[&"THR_GLOAMWOOD"].form_id, state.reapings[&"THR_GLOAMWOOD"].writ_id) != loadout_a: return false
	if service.output_channel_rate_plan(&"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", CHANNEL, "OVERDUE").effective_rate_subunits_per_period != 1000000: return false
	if service.output_channel_rate_plan(&"THR_GLOAMWOOD", &"FORM_SCRIBE", CHANNEL, "OVERDUE").effective_rate_subunits_per_period != 1200000: return false
	_pass("sequence_1_3_2_1_identity=PASS")
	return true

func _inactive_marker() -> bool:
	var inactive := _rate_context.query_acquisition(_state(false), &"THR_GLOAMWOOD", CHANNEL)
	if not (inactive.success and inactive.progress_subunits == 500000 and not inactive.eta_available and inactive.eta_msec == -1): return false
	_pass("inactive_query_has_progress_no_eta=PASS")
	return true

func _chunk_marker() -> bool:
	var registry := _registry_with_scribe_modifier()
	var one := _state(true)
	var chunked := _state(true)
	var engine := SimulationEngine.new(registry)
	var assignment := ReapingAssignmentService.new(registry)
	if not engine.resolve_elapsed(one, 1000).success: return false
	if not assignment.recall(one, &"THR_GLOAMWOOD", 1).success: return false
	if not assignment.redispatch(one, &"THR_GLOAMWOOD", &"FORM_SCRIBE", &"WRIT_STANDARD", 2).success: return false
	if not engine.resolve_elapsed(one, 2000).success: return false
	if not engine.resolve_elapsed(chunked, 400).success: return false
	if not engine.resolve_elapsed(chunked, 600).success: return false
	if not assignment.recall(chunked, &"THR_GLOAMWOOD", 1).success: return false
	if not assignment.redispatch(chunked, &"THR_GLOAMWOOD", &"FORM_SCRIBE", &"WRIT_STANDARD", 2).success: return false
	for elapsed in [333, 667, 1000]:
		if not engine.resolve_elapsed(chunked, elapsed).success: return false
	if _canonical(one) != _canonical(chunked): return false
	_pass("rate_change_chunk_equivalence=PASS")
	return true

func _persistence_marker() -> bool:
	var state := _state(false)
	state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[CHANNEL].progress_subunits = 345678
	if not _assignment.redispatch(state, &"THR_GLOAMWOOD", &"FORM_SCRIBE", &"WRIT_STANDARD", 1).success: return false
	var save := SaveService.new(FileSaveStorage.new(), SaveFileSet.new(_save_root, "m04d3_trace"))
	var coordinator := GameStatePersistenceCoordinator.new(save, _registry)
	if not coordinator.save_runtime(state, TimeAuthorityState.new(), 5).ok: return false
	var loaded := coordinator.load_runtime()
	if not loaded.ok: return false
	if _canonical(loaded.game_state) != _canonical(state): return false
	var text := JSON.stringify(save.load_snapshot().snapshot)
	for forbidden in ["loadout_identity", "rate_context_signature", "continuity_result", "rate_plan", "modifier_trace", "percent_tenths", "current_context_eta_msec", "eta_msec", "eta_display"]:
		if text.contains(forbidden): return false
	_pass("schema_v3_round_trip_no_derived_rate_eta=PASS")
	return true

func _source_audit_marker() -> bool:
	var files := {
		"src/domain/reaping_rate_context_service.gd": ["class_name ReapingRateContextService", "never mutates GameState", "output_channel_rate_plan", "eta_display"],
		"src/domain/reaping_assignment_service.gd": ["rate_context.compare_residual_signatures", "validate_loadout_candidate"],
		"src/simulation/simulation_engine.gd": ["rate_context.output_channel_rate_plan"],
		"tools/test/m04d3/m04d3_rate_context_trace.gd": ["TRACE M04D3", "--save-root"],
	}
	var prohibited := ["get_ticks_msec(", "get_unix_time", "get_datetime", "_process(", "Steam.", "FileAccess.open("]
	for path in files.keys():
		var text := FileAccess.get_file_as_string("res://" + path)
		for required in files[path]:
			if not text.contains(required): return false
		if path != "tools/test/m04d3/m04d3_rate_context_trace.gd":
			for token in prohibited:
				if text.contains(token): return false
	_pass("no_clock_or_later_slice_sources=PASS")
	return true

func _state(active: bool) -> GameState:
	var state := GameState.new(0)
	state.progression.command_tether_capacity = 1
	state.progression.unlocked_output_item_ids = [&"SOUL_FORM_SCRIBE"]
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
	state.forms[&"FORM_SCRIBE"] = GameState.FormState.new(true, true, 0, &"TEST")
	var threshold := GameState.ThresholdState.new()
	threshold.knowledge_state = &"CHARTED"; threshold.availability_state = &"AVAILABLE"; threshold.lifecycle_state = &"OVERDUE"; threshold.remaining_backlog = 1000000
	threshold.channel_acquisition[CHANNEL] = GameState.ThresholdAcquisitionState.new(500000, 0, 0)
	state.thresholds[&"THR_GLOAMWOOD"] = threshold
	var reaping := GameState.ReapingState.new()
	reaping.threshold_id = &"THR_GLOAMWOOD"; reaping.is_active = active; reaping.form_id = &"FORM_MAN_AT_ARMS"; reaping.writ_id = &"WRIT_STANDARD"; reaping.assignment_revision = 1
	state.reapings[&"THR_GLOAMWOOD"] = reaping
	return state

func _two_threshold_state() -> GameState:
	var state := _state(false)
	state.progression.command_tether_capacity = 2
	state.progression.unlocked_output_item_ids = [&"RES_PROVISIONS", &"SOUL_FORM_SCRIBE"]
	var watch := GameState.ThresholdState.new()
	watch.knowledge_state = &"CHARTED"; watch.availability_state = &"AVAILABLE"; watch.lifecycle_state = &"OVERDUE"; watch.remaining_backlog = 250000
	watch.channel_acquisition[&"CHANNEL_BROKEN_WATCH_PROVISIONS"] = GameState.ThresholdAcquisitionState.new(0, 0, 0)
	state.thresholds[&"THR_BROKEN_WATCH"] = watch
	state.reapings.clear()
	return state

func _registry_with_scribe_modifier() -> ContentRegistry:
	var registry := ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
	registry._records["FORM_SCRIBE"].traits[0].modifiers = [{"metric": "OUTPUT_CHANNEL_RATE", "operation": "MULTIPLY", "scope": "OUTPUT_CHANNEL", "condition": "ALWAYS", "condition_values": [], "value_subunits": 1200000}]
	return registry

func _canonical(state: GameState) -> Dictionary:
	return SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION).game_state

func _pass(marker: String) -> void:
	print("TRACE M04D3 " + marker)

func _fail(code: int, details: String) -> Dictionary:
	return {"ok": false, "code": code, "details": details}
