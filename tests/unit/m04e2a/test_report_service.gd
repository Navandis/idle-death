extends GutTest

const HOUR := 3600000

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
func _state(threshold_id: StringName = &"THR_GLOAMWOOD", backlog := 1000000) -> GameState:
	var state := GameState.new(0); state.progression.command_tether_capacity = 1
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST"); state.forms[&"FORM_SCRIBE"] = GameState.FormState.new(true, true, 0, &"TEST")
	var t := GameState.ThresholdState.new(); t.knowledge_state = &"CHARTED"; t.availability_state = &"AVAILABLE"; t.lifecycle_state = &"SETTLED" if backlog == 0 else &"OVERDUE"; t.remaining_backlog = backlog; state.thresholds[threshold_id] = t
	var r := GameState.ReapingState.new(); r.threshold_id = threshold_id; r.is_active = true; r.form_id = &"FORM_MAN_AT_ARMS" if threshold_id == &"THR_GLOAMWOOD" else &"FORM_SCRIBE"; r.writ_id = &"WRIT_STANDARD"; r.assignment_revision = 1; state.reapings[threshold_id] = r
	return state
func _unlock(state: GameState, ids: Array[StringName]) -> void:
	var svc := OutputAccessService.new(_registry()); for id in ids: assert_true(svc.unlock_output_item(state, id).success); assert_true(svc.reconcile_available_sources(state).success)

func test_one_hour_ingestion_views_and_duplicate() -> void:
	var state := _state(); _unlock(state, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	var run := SimulationRunService.new(_registry()).run_committed(state, HOUR, SimulationRunService.MODE_FOREGROUND_SUPPLIED)
	assert_true(run.success)
	var result := ReportService.new().ingest_committed_run(state, run)
	assert_true(result.success); assert_true(result.changed); assert_eq(result.cursor_msec, HOUR)
	var view := ReportService.new().peek_live_global(state)
	assert_eq(view.totals.returned_souls_delta, 4140); assert_eq(view.totals.inventory_gains.RES_ESSENCE, 360); assert_eq(view.totals.inventory_gains.SOUL_CALLING_SOLDIER, 12); assert_eq(view.totals.mastery_gains.FORM_MAN_AT_ARMS, 60000000)
	assert_eq(ReportService.new().peek_live_threshold(state, &"THR_GLOAMWOOD").slices.size(), 1)
	assert_true(ReportService.new().ingest_committed_run(state, run).duplicate)

func test_gap_overlap_forecast_snapshot_and_offline_purity() -> void:
	var service := ReportService.new(); var state := _state(); _unlock(state, [&"SOUL_CALLING_SOLDIER"])
	var forecast := SimulationRunService.new(_registry()).forecast(state, HOUR)
	assert_eq(service.ingest_committed_run(state, forecast).error_code, ReportService.ERR_FORECAST)
	var run := SimulationRunService.new(_registry()).run_committed(state, HOUR, SimulationRunService.MODE_FOREGROUND_SUPPLIED); assert_true(service.ingest_committed_run(state, run).success)
	assert_eq(service.snapshot_live(state, 1, ReportState.REASON_OFFLINE_RETURN).error_code, ReportService.ERR_OFFLINE_PURITY)
	assert_true(service.snapshot_live(state, 1, ReportState.REASON_MANUAL_REVIEW).checkpoint_requested); assert_eq(state.report_state.history.size(), 1)
	var off := SimulationRunService.new(_registry()).run_committed(state, HOUR, SimulationRunService.MODE_OFFLINE_FIXTURE); assert_true(service.ingest_committed_run(state, off).success); assert_true(service.snapshot_live(state, 2, ReportState.REASON_OFFLINE_RETURN).success)

func test_assignment_revision_and_retention() -> void:
	var service := ReportService.new(); var state := _state(); _unlock(state, [&"SOUL_CALLING_SOLDIER"])
	for rev in [1, 2, 3]:
		state.reapings[&"THR_GLOAMWOOD"].assignment_revision = rev
		var run := SimulationRunService.new(_registry()).run_committed(state, 60000, SimulationRunService.MODE_DEBUG); assert_true(run.success); assert_true(service.ingest_committed_run(state, run).success)
	assert_eq(service.peek_live_global(state).slices.size(), 3)
	for i in range(25):
		assert_true(service.snapshot_live(state, state.report_state.next_report_sequence, ReportState.REASON_SYSTEM_BOUNDARY).success)
		var run2 := SimulationRunService.new(_registry()).run_committed(state, 1, SimulationRunService.MODE_DEBUG); assert_true(run2.success); assert_true(service.ingest_committed_run(state, run2).success)
	assert_eq(state.report_state.history.size(), 20); assert_eq(state.report_state.dropped_history_record_count, 5)
