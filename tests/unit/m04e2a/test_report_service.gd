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
	var scribe_channel: Dictionary = view.slices[0].channel_summaries.CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS
	assert_true(scribe_channel.has("first_rate_carry_units_before"))
	assert_true(scribe_channel.has("latest_rate_carry_units_after"))
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

func test_positive_no_reaping_interval_advances_report_cursor_and_snapshots() -> void:
	var state := GameState.new(0)
	var service := ReportService.new()
	var run := SimulationRunService.new(_registry()).run_committed(state, HOUR, SimulationRunService.MODE_DEBUG)
	assert_true(run.success, run.developer_details)
	var ingest := service.ingest_committed_run(state, run)
	assert_true(ingest.success, ingest.developer_details)
	assert_true(ingest.changed)
	assert_eq(state.report_state.report_cursor_msec, HOUR)
	var live := service.peek_live_global(state)
	assert_eq(live.run_count, 1)
	assert_eq(live.slices.size(), 0)
	assert_eq(live.totals.returned_souls_delta, 0)
	assert_true(service.snapshot_live(state, 1, ReportState.REASON_SYSTEM_BOUNDARY).success)

func test_stale_committed_run_rejects_when_gameplay_advanced_past_result() -> void:
	var state := GameState.new(0)
	var run_one := SimulationRunService.new(_registry()).run_committed(state, 1000, SimulationRunService.MODE_DEBUG)
	assert_true(run_one.success, run_one.developer_details)
	var run_two := SimulationRunService.new(_registry()).run_committed(state, 1000, SimulationRunService.MODE_DEBUG)
	assert_true(run_two.success, run_two.developer_details)
	var before_cursor := state.report_state.report_cursor_msec
	var result := ReportService.new().ingest_committed_run(state, run_one)
	assert_false(result.success)
	assert_eq(result.error_code, ReportService.ERR_INVALID_RESULT)
	assert_eq(state.simulation_time_msec, 2000)
	assert_eq(state.report_state.report_cursor_msec, before_cursor)

func test_global_peek_marks_no_slice_run_window_as_pending() -> void:
	var state := GameState.new(0)
	var run := SimulationRunService.new(_registry()).run_committed(state, 1000, SimulationRunService.MODE_DEBUG)
	assert_true(run.success, run.developer_details)
	assert_true(ReportService.new().ingest_committed_run(state, run).success)
	var live := ReportService.new().peek_live_global(state)
	assert_false(live.is_empty)
	assert_eq(live.run_count, 1)
	assert_eq(live.slices.size(), 0)


func test_scoped_meaningful_event_filters_by_assignment_window() -> void:
	var service := ReportService.new()
	var state := _state(&"THR_GLOAMWOOD", 1)
	_unlock(state, [&"SOUL_CALLING_SOLDIER"])

	var first_result := SimulationRunService.new(_registry()).run_committed(state, 10000, SimulationRunService.MODE_DEBUG)
	assert_true(first_result.success, first_result.developer_details)
	assert_true(service.ingest_committed_run(state, first_result).success)

	state.reapings[&"THR_GLOAMWOOD"].assignment_revision = 2
	var second_result := SimulationRunService.new(_registry()).run_committed(state, 1000, SimulationRunService.MODE_DEBUG)
	assert_true(second_result.success, second_result.developer_details)
	assert_true(service.ingest_committed_run(state, second_result).success)

	assert_true(service.peek_live_global(state).meaningful_event)
	assert_true(service.peek_live_threshold(state, &"THR_GLOAMWOOD").meaningful_event)
	assert_true(service.peek_live_assignment(state, &"THR_GLOAMWOOD", 1).meaningful_event)
	assert_false(service.peek_live_assignment(state, &"THR_GLOAMWOOD", 2).meaningful_event)



func test_public_views_expose_event_details_and_counts() -> void:
	var service := ReportService.new()
	var state := _state(&"THR_GLOAMWOOD", 1)
	_unlock(state, [&"SOUL_CALLING_SOLDIER"])

	var run := SimulationRunService.new(_registry()).run_committed(state, 10000, SimulationRunService.MODE_DEBUG)
	assert_true(run.success, run.developer_details)
	assert_true(service.ingest_committed_run(state, run).success)

	var global := service.peek_live_global(state)
	assert_true(global.events_by_type.has("THRESHOLD_SETTLED"))
	assert_gt(global.event_details.size(), 0)
	assert_eq(global.omitted_oldest_event_detail_count, 0)
	assert_eq(global.event_details[0].event_type, "THRESHOLD_SETTLED")
	assert_eq(global.event_details[0].subject_id, "THR_GLOAMWOOD")

	var threshold := service.peek_live_threshold(state, &"THR_GLOAMWOOD")
	assert_true(threshold.events_by_type.has("THRESHOLD_SETTLED"))
	assert_eq(threshold.event_details.size(), global.event_details.size())

	var other_threshold := service.peek_live_threshold(state, &"THR_BROKEN_WATCH")
	assert_true(other_threshold.events_by_type.is_empty())
	assert_eq(other_threshold.event_details.size(), 0)

	assert_true(service.snapshot_live(state, 1, ReportState.REASON_MANUAL_REVIEW).success)
	var record := service.get_report_record(state, 1)
	assert_eq(record.report_sequence, 1)
	assert_eq(record.snapshot_reason, "MANUAL_REVIEW")
	assert_eq(record.snapshot_simulation_msec, state.report_state.history[0].window.end_simulation_msec)
	assert_true(record.events_by_type.has("THRESHOLD_SETTLED"))
	assert_eq(record.event_details[0].event_sequence, global.event_details[0].event_sequence)

func test_duplicate_retry_after_later_advancement_is_unchanged_success() -> void:
	var service := ReportService.new()
	var state := _state(&"THR_GLOAMWOOD", 1000000)
	var run_one := SimulationRunService.new(_registry()).run_committed(state, 1000, SimulationRunService.MODE_DEBUG)
	assert_true(run_one.success, run_one.developer_details)
	assert_true(service.ingest_committed_run(state, run_one).success)
	var run_two := SimulationRunService.new(_registry()).run_committed(state, 1000, SimulationRunService.MODE_DEBUG)
	assert_true(run_two.success, run_two.developer_details)
	assert_true(service.ingest_committed_run(state, run_two).success)

	var retry := service.ingest_committed_run(state, run_one)
	assert_true(retry.success, retry.developer_details)
	assert_true(retry.duplicate)
	assert_false(retry.changed)
	assert_eq(state.simulation_time_msec, 2000)
	assert_eq(state.report_state.report_cursor_msec, 2000)


func test_snapshot_sequence_overflow_rejects_without_mutation() -> void:
	var service := ReportService.new()
	var state := _state(&"THR_GLOAMWOOD", 1000000)
	var run := SimulationRunService.new(_registry()).run_committed(state, 1000, SimulationRunService.MODE_DEBUG)
	assert_true(run.success, run.developer_details)
	assert_true(service.ingest_committed_run(state, run).success)
	state.report_state.next_report_sequence = FixedPoint.INT64_MAX
	var before := state.deep_clone()

	var result := service.snapshot_live(state, FixedPoint.INT64_MAX, ReportState.REASON_SYSTEM_BOUNDARY)
	assert_false(result.success)
	assert_eq(result.error_code, ReportService.ERR_SEQUENCE_OVERFLOW)
	assert_eq(state.report_state.next_report_sequence, before.report_state.next_report_sequence)
	assert_eq(state.report_state.history.size(), before.report_state.history.size())
	assert_eq(state.report_state.live.run_count, before.report_state.live.run_count)


func test_assignment_boundary_event_excludes_next_slice_start() -> void:
	var state := GameState.new(0)
	var first := ReportState.AttributionSlice.new()
	first.threshold_id = &"THR_GLOAMWOOD"
	first.assignment_revision = 1
	first.lifecycle_state = &"OVERDUE"
	first.start_simulation_msec = 0
	first.end_simulation_msec = 1000
	state.report_state.live.slices["first"] = first
	var second := ReportState.AttributionSlice.new()
	second.threshold_id = &"THR_GLOAMWOOD"
	second.assignment_revision = 2
	second.lifecycle_state = &"OVERDUE"
	second.start_simulation_msec = 1000
	second.end_simulation_msec = 2000
	state.report_state.live.slices["second"] = second
	var event := ReportState.ReportEventDetail.new()
	event.event_sequence = 1
	event.event_type = &"THRESHOLD_SETTLED"
	event.subject_id = &"THR_GLOAMWOOD"
	event.occurred_simulation_msec = 1000
	state.report_state.live.event_details.append(event)
	state.report_state.live.events_by_type["THRESHOLD_SETTLED"] = 1

	assert_true(ReportService.new().peek_live_assignment(state, &"THR_GLOAMWOOD", 1).meaningful_event)
	assert_false(ReportService.new().peek_live_assignment(state, &"THR_GLOAMWOOD", 2).meaningful_event)


func test_ingest_uses_run_time_attribution_after_same_timestamp_recall() -> void:
	var service := ReportService.new()
	var state := _state(&"THR_GLOAMWOOD", 1000000)
	_unlock(state, [&"SOUL_CALLING_SOLDIER"])
	var run := SimulationRunService.new(_registry()).run_committed(state, 60000, SimulationRunService.MODE_DEBUG)
	assert_true(run.success, run.developer_details)
	assert_true(ReapingAssignmentService.new(_registry()).recall(state, &"THR_GLOAMWOOD", 1).success)
	assert_eq(state.simulation_time_msec, run.result_simulation_time_msec)
	assert_eq(state.reapings[&"THR_GLOAMWOOD"].assignment_revision, 2)

	var ingest := service.ingest_committed_run(state, run)
	assert_true(ingest.success, ingest.developer_details)
	assert_eq(service.peek_live_assignment(state, &"THR_GLOAMWOOD", 1).slices.size(), 1)
	assert_eq(service.peek_live_assignment(state, &"THR_GLOAMWOOD", 2).slices.size(), 0)
	assert_eq(service.peek_live_global(state).slices[0].form_id, "FORM_MAN_AT_ARMS")
