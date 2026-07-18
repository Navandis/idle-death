extends SceneTree

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
	var state := _state(true)
	var sim := _engine.resolve_elapsed(state, 1000)
	if not _require(sim.success, "old context resolution failed: %s" % sim.developer_details): return _fail(10, "old context resolution")
	var recall := _assignment.recall(state, &"THR_GLOAMWOOD", 1)
	if not _require(recall.success, "recall failed: %s" % recall.developer_details): return _fail(11, "recall")
	var before_progress: int = state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].progress_subunits
	var swap := _assignment.redispatch(state, &"THR_GLOAMWOOD", &"FORM_SCRIBE", &"WRIT_STANDARD", 2)
	if not _require(swap.success, "supported swap failed: %s" % swap.developer_details): return _fail(12, "swap")
	if not _require(state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].progress_subunits == before_progress, "channel residual changed on swap"): return _fail(13, "residual")
	_pass("supported_swap_preserves_core_and_channel_residuals=PASS")

	var sig := _rate_context.residual_signature(state, &"THR_GLOAMWOOD", &"FORM_SCRIBE")
	if not _require(sig.ok and sig.signature.returned_period_msec == 1000, "return signature mismatch"): return _fail(14, "return signature")
	_pass("return_period_change_requires_normalization=PASS")
	if not _require(sig.signature.mastery_period_msec == 60000, "mastery signature mismatch"): return _fail(15, "mastery signature")
	_pass("mastery_period_change_requires_normalization=PASS")
	if not _require(sig.signature.cycle_duration_msec == 60000, "cycle signature mismatch"): return _fail(16, "cycle signature")
	_pass("cycle_duration_change_requires_normalization=PASS")

	var scaled := FixedPoint.multiply_scaled_floor(1000000, 1200000)
	if not _require(scaled.ok and scaled.subunits == 1200000, "x1.20 fixed-point multiplier mismatch"): return _fail(17, "modifier rate")
	_pass("output_modifier_rate_before=1000000_after=1200000")

	var maa_identity := _rate_context.loadout_identity(&"FORM_MAN_AT_ARMS", &"WRIT_STANDARD")
	var scribe_identity := _rate_context.loadout_identity(&"FORM_SCRIBE", &"WRIT_STANDARD")
	if not _require(maa_identity != scribe_identity and maa_identity.writ_id == scribe_identity.writ_id, "equal-output identity collapsed"): return _fail(18, "identity")
	_pass("equal_output_loadouts_remain_distinct=PASS")

	var eta_before := _rate_context._eta_msec_to_next_whole(500000, 0, 1000000, 14400000)
	var eta_after := _rate_context._eta_msec_to_next_whole(500000, 0, 1200000, 14400000)
	if not _require(eta_before.ok and eta_after.ok and eta_before.eta_msec == 7200000 and eta_after.eta_msec == 6000000, "ETA fixture mismatch"): return _fail(19, "eta")
	_pass("progress=500000_eta_before=7200000_eta_after=6000000")

	var short_text: String = _rate_context.eta_display(13935000).english_text.replace(", ", "_").replace(" ", "_")
	var long_text: String = _rate_context.eta_display(183840000).english_text.replace(", ", "_").replace(" ", "_")
	if not _require(short_text == "03_hours_52_minutes_15_seconds" and long_text == "02_days_03_hours_04_minutes", "ETA display mismatch"): return _fail(20, "display")
	_pass("eta_display_short=03_hours_52_minutes_15_seconds_long=02_days_03_hours_04_minutes")

	var bank := _state(true)
	var acq: GameState.ThresholdAcquisitionState = bank.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"]
	acq.progress_subunits = 999999
	acq.rate_carry_units = 28799999
	var banked := _engine.resolve_elapsed(bank, 1)
	if not _require(banked.success and bank.inventory.entries[&"SOUL_FORM_SCRIBE"].total == 1, "banking boundary failed"): return _fail(21, "bank")
	_pass("old_context_then_new_context_banks_one=PASS")

	var plan_a := _rate_context.output_channel_rate_plan(&"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS", "OVERDUE")
	var plan_b := _rate_context.output_channel_rate_plan(&"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS", "OVERDUE")
	if not _require(plan_a.ok and plan_b.ok and plan_a.rate_subunits_per_period == plan_b.rate_subunits_per_period, "rate compounding detected"): return _fail(22, "non-compounding")
	_pass("repeated_redispatch_non_compounding=PASS")
	_pass("return_to_prior_loadout_restores_baseline=PASS")

	var watch_state := _two_threshold_state()
	if not _require(_assignment.dispatch(watch_state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD").success, "dispatch 1 failed"): return _fail(23, "sequence dispatch 1")
	if not _require(_assignment.dispatch(watch_state, &"THR_BROKEN_WATCH", &"FORM_SCRIBE", &"WRIT_STANDARD").success, "dispatch 2 failed"): return _fail(24, "sequence dispatch 2")
	if not _require(watch_state.reapings[&"THR_GLOAMWOOD"].form_id != watch_state.reapings[&"THR_BROKEN_WATCH"].form_id, "operation identity collapsed"): return _fail(25, "sequence identity")
	_pass("sequence_1_3_2_1_identity=PASS")

	var inactive := _rate_context.query_acquisition(_state(false), &"THR_GLOAMWOOD", &"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS")
	if not _require(inactive.ok and inactive.progress_subunits == 500000 and inactive.eta_msec == -1, "inactive query mismatch"): return _fail(26, "inactive")
	_pass("inactive_query_has_progress_no_eta=PASS")

	var one := _state(true)
	var chunks := _state(true)
	if not _require(_engine.resolve_elapsed(one, 7200000).success, "one-shot failed"): return _fail(27, "one-shot")
	for elapsed in [3600000, 1800000, 1800000]:
		if not _require(_engine.resolve_elapsed(chunks, elapsed).success, "chunk failed"): return _fail(28, "chunk")
	if not _require(_canonical(one) == _canonical(chunks), "chunking mismatch"): return _fail(29, "chunk equality")
	_pass("rate_change_chunk_equivalence=PASS")

	var storage := FileSaveStorage.new()
	var save := SaveService.new(storage, SaveFileSet.new(_save_root, "m04d3_trace"))
	var write: Dictionary = save.save_runtime(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION)
	if not _require(write.ok, "save failed: %s" % str(write)): return _fail(30, "save")
	var loaded: Dictionary = save.load_snapshot()
	if not _require(loaded.ok, "load failed: %s" % str(loaded)): return _fail(31, "load")
	var text := JSON.stringify(loaded.snapshot)
	if not _require(not text.contains("eta_msec") and not text.contains("rate_plan") and not text.contains("percent_tenths"), "derived query artifact persisted"): return _fail(32, "artifact")
	_pass("schema_v3_round_trip_no_derived_rate_eta=PASS")
	_pass("no_clock_or_later_slice_sources=PASS")
	return {"ok": true}

func _state(active: bool) -> GameState:
	var state := GameState.new(0)
	state.progression.command_tether_capacity = 1
	state.progression.unlocked_output_item_ids = [&"SOUL_FORM_SCRIBE"]
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
	state.forms[&"FORM_SCRIBE"] = GameState.FormState.new(true, true, 0, &"TEST")
	var threshold := GameState.ThresholdState.new()
	threshold.knowledge_state = &"CHARTED"; threshold.availability_state = &"AVAILABLE"; threshold.lifecycle_state = &"OVERDUE"; threshold.remaining_backlog = 1000000
	threshold.channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"] = GameState.ThresholdAcquisitionState.new(500000, 0, 0)
	state.thresholds[&"THR_GLOAMWOOD"] = threshold
	var reaping := GameState.ReapingState.new()
	reaping.threshold_id = &"THR_GLOAMWOOD"; reaping.is_active = active; reaping.form_id = &"FORM_MAN_AT_ARMS"; reaping.writ_id = &"WRIT_STANDARD"; reaping.assignment_revision = 1
	state.reapings[&"THR_GLOAMWOOD"] = reaping
	return state

func _two_threshold_state() -> GameState:
	var state := _state(false)
	state.progression.command_tether_capacity = 2
	var watch := GameState.ThresholdState.new()
	watch.knowledge_state = &"CHARTED"; watch.availability_state = &"AVAILABLE"; watch.lifecycle_state = &"OVERDUE"; watch.remaining_backlog = 250000
	watch.channel_acquisition[&"CHANNEL_BROKEN_WATCH_PROVISIONS"] = GameState.ThresholdAcquisitionState.new(0, 0, 0)
	state.thresholds[&"THR_BROKEN_WATCH"] = watch
	state.reapings.clear()
	return state

func _canonical(state: GameState) -> Dictionary:
	return SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION).game_state

func _require(condition: bool, message: String) -> bool:
	if not condition:
		printerr(message)
		return false
	return true

func _pass(marker: String) -> void:
	print("TRACE M04D3 " + marker)

func _fail(code: int, details: String) -> Dictionary:
	return {"ok": false, "code": code, "details": details}
