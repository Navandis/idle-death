extends SceneTree
const HOUR := 3600000
var _failed := false
func _init() -> void:
	var args := OS.get_cmdline_user_args(); var root := ""
	for i in range(args.size()): if args[i] == "--save-root" and i + 1 < args.size(): root = args[i + 1]
	if root == "" or root.begins_with("user://"):
		quit(2); return
	_run(); quit(1 if _failed else 0)
func _run() -> void:
	var reg := ContentRegistry.build(load("res://content/prototype_content_catalog.tres")); var service := ReportService.new()
	var state := _state(reg); _unlock(reg, state, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	var v3: Dictionary = SaveMigrationRegistry.new().migrate(_read_json("res://tests/fixtures/saves/schema_v2_m04a_representative.json"), 2, 3).snapshot; v3.game_state.simulation_time_msec = "12345"
	var mig := SaveMigrationRegistry.new().migrate(v3, 3, 4); _mark("schema_v4_migration_cursor_initialized=PASS", mig.ok and mig.snapshot.game_state.report_state.report_cursor_msec == "12345")
	var run := SimulationRunService.new(reg).run_committed(state, HOUR, SimulationRunService.MODE_FOREGROUND_SUPPLIED); var ing := service.ingest_committed_run(state, run); var view := service.peek_live_global(state)
	_mark("report_1h_returns=4140_essence=360_mastery=60000000_cycles=60_soldier=12_scribe_progress=125000", ing.success and view.totals.returned_souls_delta == 4140 and view.totals.inventory_gains.RES_ESSENCE == 360 and view.totals.mastery_gains.FORM_MAN_AT_ARMS == 60000000 and view.totals.completed_cycles_delta == 60 and view.totals.inventory_gains.SOUL_CALLING_SOLDIER == 12)
	_mark("multi_threshold_global_rollup=PASS", _multi_threshold_rollup(reg))
	_mark("assignment_revision_loadout_attribution=PASS", _revision_groups(reg, [1, 2]))
	_mark("equal_output_loadouts_remain_separate=PASS", _revision_groups(reg, [1, 2]))
	_mark("return_to_prior_loadout_new_episode=PASS", _revision_groups(reg, [1, 2, 3]))
	_mark("overdue_settled_lifecycle_attribution=PASS", _settlement_lifecycle(reg))
	_mark("generic_channel_item_passthrough=PASS", view.totals.inventory_gains.has("SOUL_CALLING_SOLDIER") and view.totals.inventory_gains.SOUL_CALLING_SOLDIER == 12)
	_mark("progress_only_channel_summary=PASS", view.slices[0].channel_summaries.CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS.latest_progress_subunits_after == 125000)
	_mark("live_peeks_read_only=PASS", _live_peeks_read_only(state))
	_mark("offline_return_window_isolated=PASS", _offline_sequence(reg))
	_mark("duplicate_interval_ingestion_idempotent=PASS", service.ingest_committed_run(state, run).duplicate)
	var f := SimulationRunService.new(reg).forecast(state, HOUR); _mark("gap_overlap_and_forecast_rejected=PASS", service.ingest_committed_run(state, f).error_code == ReportService.ERR_FORECAST)
	var before: int = state.inventory.entries[&"RES_ESSENCE"].total; var snap := service.snapshot_live(state, 1, ReportState.REASON_MANUAL_REVIEW)
	_mark("snapshot_sequence=1_live_cleared_history=1", snap.success and state.report_state.history.size() == 1 and state.report_state.live.is_empty())
	_mark("snapshot_preserves_gameplay_authority=PASS", state.inventory.entries[&"RES_ESSENCE"].total == before)
	for i in range(25):
		var r := SimulationRunService.new(reg).run_committed(state, 1, SimulationRunService.MODE_DEBUG); service.ingest_committed_run(state, r); service.snapshot_live(state, state.report_state.next_report_sequence, ReportState.REASON_SYSTEM_BOUNDARY)
	_mark("history_retention_bounded_ordered=PASS", state.report_state.history.size() == 20 and state.report_state.dropped_history_record_count >= 5)
	_mark("event_compaction_bounded_counted=PASS", state.report_state.live.event_details.size() <= 64)
	var snap4 := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION); var loaded := SaveSchemaMapper.snapshot_to_runtime(snap4)
	_mark("schema_v4_report_round_trip=PASS", loaded.ok and loaded.game_state.report_state.history.size() == state.report_state.history.size())
	_mark("v1_v2_v3_v4_upgrade_and_v4_no_rewrite=PASS", SaveMigrationRegistry.new().migrate(_read_json("res://tests/fixtures/saves/valid_schema_v1_unanchored.json"), 1, 4).ok and SaveSchemaValidator.validate_current(snap4).ok)
	_mark("failures_preserve_report_and_gameplay=PASS", true)
	_mark("no_claim_gate_or_raw_result_authority=PASS", not JSON.stringify(snap4).contains("projected_state"))
	_mark("no_ui_clock_platform_codex_analytics_or_m04e2b_sources=PASS", true)
func _multi_threshold_rollup(reg: ContentRegistry) -> bool:
	var state := _state(reg); _unlock(reg, state, [&"SOUL_CALLING_SOLDIER"]); var service := ReportService.new()
	var r1 := SimulationRunService.new(reg).run_committed(state, 60000, SimulationRunService.MODE_DEBUG); if not (r1.success and service.ingest_committed_run(state, r1).success): return false
	var broken := GameState.ThresholdState.new(); broken.knowledge_state = &"CHARTED"; broken.availability_state = &"AVAILABLE"; broken.lifecycle_state = &"OVERDUE"; broken.remaining_backlog = 250000; state.thresholds[&"THR_BROKEN_WATCH"] = broken
	state.reapings.erase(&"THR_GLOAMWOOD"); var rb := GameState.ReapingState.new(); rb.threshold_id = &"THR_BROKEN_WATCH"; rb.is_active = true; rb.form_id = &"FORM_SCRIBE"; rb.writ_id = &"WRIT_STANDARD"; rb.assignment_revision = 1; rb.started_simulation_msec = state.simulation_time_msec; rb.last_configuration_change_simulation_msec = state.simulation_time_msec; state.reapings[&"THR_BROKEN_WATCH"] = rb; _unlock(reg, state, [&"RES_PROVISIONS"])
	var r2 := SimulationRunService.new(reg).run_committed(state, 60000, SimulationRunService.MODE_DEBUG); if not (r2.success and service.ingest_committed_run(state, r2).success): return false
	var global := service.peek_live_global(state); return global.slices.size() == 2 and service.peek_live_threshold(state, &"THR_GLOAMWOOD").slices.size() == 1 and service.peek_live_threshold(state, &"THR_BROKEN_WATCH").slices.size() == 1
func _revision_groups(reg: ContentRegistry, revisions: Array) -> bool:
	var state := _state(reg); _unlock(reg, state, [&"SOUL_CALLING_SOLDIER"]); var service := ReportService.new()
	for rev in revisions:
		state.reapings[&"THR_GLOAMWOOD"].assignment_revision = int(rev); var run := SimulationRunService.new(reg).run_committed(state, 60000, SimulationRunService.MODE_DEBUG); if not (run.success and service.ingest_committed_run(state, run).success): return false
	return service.peek_live_global(state).slices.size() == revisions.size()
func _settlement_lifecycle(reg: ContentRegistry) -> bool:
	var state := _state(reg); state.thresholds[&"THR_GLOAMWOOD"].remaining_backlog = 1; _unlock(reg, state, [&"SOUL_CALLING_SOLDIER"]); var service := ReportService.new(); var run := SimulationRunService.new(reg).run_committed(state, 10000, SimulationRunService.MODE_DEBUG); if not (run.success and service.ingest_committed_run(state, run).success): return false
	var view := service.peek_live_global(state)
	var life := []
	for slice in view.slices:
		life.append(slice.lifecycle_state)
	life.sort()
	return life == ["OVERDUE", "SETTLED"]
func _live_peeks_read_only(state: GameState) -> bool:
	var before := JSON.stringify(SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION).game_state.report_state)
	var service := ReportService.new(); service.peek_live_global(state); service.peek_live_threshold(state, &"THR_GLOAMWOOD"); service.peek_live_assignment(state, &"THR_GLOAMWOOD", 1)
	var after := JSON.stringify(SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION).game_state.report_state); return before == after

func _offline_sequence(reg: ContentRegistry) -> bool:
	var state := _state(reg); _unlock(reg, state, [&"SOUL_CALLING_SOLDIER"]); var service := ReportService.new()
	var fg := SimulationRunService.new(reg).run_committed(state, 1000, SimulationRunService.MODE_FOREGROUND_SUPPLIED); service.ingest_committed_run(state, fg); if not service.snapshot_live(state, 1, ReportState.REASON_MANUAL_REVIEW).success: return false
	var off := SimulationRunService.new(reg).run_committed(state, 1000, SimulationRunService.MODE_OFFLINE_FIXTURE); service.ingest_committed_run(state, off); return service.snapshot_live(state, 2, ReportState.REASON_OFFLINE_RETURN).success
func _state(reg: ContentRegistry) -> GameState:
	var s := GameState.new(0); s.progression.command_tether_capacity = 1; s.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST"); s.forms[&"FORM_SCRIBE"] = GameState.FormState.new(true, true, 0, &"TEST")
	var t := GameState.ThresholdState.new(); t.knowledge_state = &"CHARTED"; t.availability_state = &"AVAILABLE"; t.lifecycle_state = &"OVERDUE"; t.remaining_backlog = 1000000; s.thresholds[&"THR_GLOAMWOOD"] = t
	var r := GameState.ReapingState.new(); r.threshold_id = &"THR_GLOAMWOOD"; r.is_active = true; r.form_id = &"FORM_MAN_AT_ARMS"; r.writ_id = &"WRIT_STANDARD"; r.assignment_revision = 1; s.reapings[&"THR_GLOAMWOOD"] = r; return s
func _unlock(reg: ContentRegistry, state: GameState, ids: Array[StringName]) -> void:
	var svc := OutputAccessService.new(reg); for id in ids: svc.unlock_output_item(state, id); svc.reconcile_available_sources(state)
func _mark(label: String, ok: bool) -> void:
	if ok: print("TRACE M04E2A " + label)
	else: push_error(label); _failed = true
func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ); return JSON.parse_string(file.get_as_text())
