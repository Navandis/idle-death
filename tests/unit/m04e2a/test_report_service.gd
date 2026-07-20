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


func test_snapshot_invalid_candidate_rejects_without_clearing_live() -> void:
	var service := ReportService.new()
	var state := _state(&"THR_GLOAMWOOD", 1000000)
	var run := SimulationRunService.new(_registry()).run_committed(state, 1000, SimulationRunService.MODE_DEBUG)
	assert_true(run.success, run.developer_details)
	assert_true(service.ingest_committed_run(state, run).success)
	state.report_state.live.end_simulation_msec = state.report_state.report_cursor_msec - 1
	var before := state.deep_clone()

	var result := service.snapshot_live(state, 1, ReportState.REASON_SYSTEM_BOUNDARY)
	assert_false(result.success)
	assert_eq(result.error_code, ReportService.ERR_STATE_INVALID)
	assert_eq(state.report_state.live.end_simulation_msec, before.report_state.live.end_simulation_msec)
	assert_eq(state.report_state.live.run_count, before.report_state.live.run_count)
	assert_eq(state.report_state.history.size(), before.report_state.history.size())
	assert_eq(state.report_state.next_report_sequence, before.report_state.next_report_sequence)


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

func _state_digest(state: GameState) -> String:
	var snapshot := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION)
	assert_true(snapshot.ok if snapshot.has("ok") else true)
	return JSON.stringify(snapshot)

func _assert_state_unchanged(before: String, state: GameState) -> void:
	assert_eq(_state_digest(state), before)

func _make_active_run(backlog := 1000000, elapsed := 1000) -> Array:
	var state := _state(&"THR_GLOAMWOOD", backlog)
	_unlock(state, [&"SOUL_CALLING_SOLDIER"])
	var run := SimulationRunService.new(_registry()).run_committed(state, elapsed, SimulationRunService.MODE_DEBUG)
	assert_true(run.success, run.developer_details)
	return [state, run]

func _make_slice_from_segment(segment: Dictionary) -> ReportState.AttributionSlice:
	var slice := ReportState.AttributionSlice.new()
	slice.threshold_id = StringName(str(segment.threshold_id))
	slice.assignment_revision = int(segment.assignment_revision)
	slice.lifecycle_state = StringName(str(segment.lifecycle))
	slice.form_id = StringName(str(segment.form_id))
	slice.writ_id = StringName(str(segment.writ_id))
	slice.retinue_ids = []
	slice.start_simulation_msec = 0
	slice.end_simulation_msec = 0
	return slice

func _install_live_slice_at_cursor(state: GameState, segment: Dictionary, slice: ReportState.AttributionSlice) -> void:
	state.report_state.live.start_simulation_msec = state.report_state.report_cursor_msec
	state.report_state.live.end_simulation_msec = state.report_state.report_cursor_msec
	state.report_state.live.run_count = 1
	state.report_state.live.mode_counts[str(SimulationRunService.MODE_DEBUG)] = 1
	state.report_state.live.slices[ReportService.canonical_slice_key(slice.threshold_id, slice.assignment_revision, slice.lifecycle_state)] = slice

func test_stage2_interval_decision_table_rejects_and_duplicates_before_mutation() -> void:
	var service := ReportService.new()

	var zero_state := GameState.new(0)
	var zero := SimulationRunService.new(_registry()).run_committed(zero_state, 0, SimulationRunService.MODE_DEBUG)
	var zero_result := service.ingest_committed_run(zero_state, zero)
	assert_true(zero_result.success)
	assert_false(zero_result.changed)
	assert_false(zero_result.duplicate)
	assert_eq(zero_state.report_state.report_cursor_msec, 0)

	var represented := GameState.new(0)
	var run_one := SimulationRunService.new(_registry()).run_committed(represented, 1000, SimulationRunService.MODE_DEBUG)
	assert_true(service.ingest_committed_run(represented, run_one).success)
	var covered_zero := SimulationRunService.SimulationRunResult.new(true, SimulationRunService.MODE_DEBUG, &"", "", 0, 0, 0, SimulationEngine.SimulationResult.success_empty(0), null)
	assert_true(service.ingest_committed_run(represented, covered_zero).duplicate)

	var run_two := SimulationRunService.new(_registry()).run_committed(represented, 1000, SimulationRunService.MODE_DEBUG)
	assert_true(service.ingest_committed_run(represented, run_two).success)
	var covered := service.ingest_committed_run(represented, run_one)
	assert_true(covered.success)
	assert_true(covered.duplicate)
	assert_false(covered.changed)

	var forecast_state := GameState.new(0)
	var forecast := SimulationRunService.new(_registry()).forecast(forecast_state, 1000)
	var committed := SimulationRunService.new(_registry()).run_committed(forecast_state, 1000, SimulationRunService.MODE_DEBUG)
	assert_true(service.ingest_committed_run(forecast_state, committed).success)
	assert_eq(service.ingest_committed_run(forecast_state, forecast).error_code, ReportService.ERR_FORECAST)
	committed.simulation_result.committed_elapsed_msec = 999
	assert_eq(service.ingest_committed_run(forecast_state, committed).error_code, ReportService.ERR_INVALID_RESULT)

	var overlap_source := GameState.new(0)
	var overlap_run := SimulationRunService.new(_registry()).run_committed(overlap_source, 2000, SimulationRunService.MODE_DEBUG)
	var overlap_target := GameState.new(0)
	var first := SimulationRunService.new(_registry()).run_committed(overlap_target, 1000, SimulationRunService.MODE_DEBUG)
	assert_true(service.ingest_committed_run(overlap_target, first).success)
	assert_eq(service.ingest_committed_run(overlap_target, overlap_run).error_code, ReportService.ERR_OVERLAP)

	var gap_source := GameState.new(1000)
	var gap_run := SimulationRunService.new(_registry()).run_committed(gap_source, 1000, SimulationRunService.MODE_DEBUG)
	assert_eq(service.ingest_committed_run(GameState.new(0), gap_run).error_code, ReportService.ERR_GAP)

	var stale_late := GameState.new(0)
	var stale_one := SimulationRunService.new(_registry()).run_committed(stale_late, 1000, SimulationRunService.MODE_DEBUG)
	assert_true(SimulationRunService.new(_registry()).run_committed(stale_late, 1000, SimulationRunService.MODE_DEBUG).success)
	assert_eq(service.ingest_committed_run(stale_late, stale_one).error_code, ReportService.ERR_INVALID_RESULT)

	var run_owner := GameState.new(0)
	var future_run := SimulationRunService.new(_registry()).run_committed(run_owner, 1000, SimulationRunService.MODE_DEBUG)
	assert_eq(service.ingest_committed_run(GameState.new(0), future_run).error_code, ReportService.ERR_INVALID_RESULT)

	var nonzero := GameState.new(5000)
	var nz_run := SimulationRunService.new(_registry()).run_committed(nonzero, 1000, SimulationRunService.MODE_DEBUG)
	assert_true(service.ingest_committed_run(nonzero, nz_run).success)
	assert_eq(nonzero.report_state.report_cursor_msec, 6000)

func test_stage2_same_timestamp_redispatch_and_revision_episodes_use_run_segments() -> void:
	var service := ReportService.new()
	var state := _state(&"THR_GLOAMWOOD", 1000000)
	_unlock(state, [&"SOUL_CALLING_SOLDIER"])
	var assignment := ReapingAssignmentService.new(_registry())
	var run_a := SimulationRunService.new(_registry()).run_committed(state, 60000, SimulationRunService.MODE_DEBUG)
	assert_true(run_a.success, run_a.developer_details)
	assert_true(assignment.recall(state, &"THR_GLOAMWOOD", 1).success)
	assert_true(assignment.redispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", 2).success)
	assert_true(service.ingest_committed_run(state, run_a).success)
	assert_eq(service.peek_live_assignment(state, &"THR_GLOAMWOOD", 1).slices.size(), 1)
	assert_eq(service.peek_live_assignment(state, &"THR_GLOAMWOOD", 3).slices.size(), 0)

	var run_b := SimulationRunService.new(_registry()).run_committed(state, 60000, SimulationRunService.MODE_DEBUG)
	assert_true(run_b.success, run_b.developer_details)
	assert_true(assignment.recall(state, &"THR_GLOAMWOOD", 3).success)
	assert_true(assignment.redispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", 4).success)
	assert_true(service.ingest_committed_run(state, run_b).success)
	var run_c := SimulationRunService.new(_registry()).run_committed(state, 60000, SimulationRunService.MODE_DEBUG)
	assert_true(run_c.success, run_c.developer_details)
	assert_true(service.ingest_committed_run(state, run_c).success)
	var live := service.peek_live_global(state)
	assert_eq(live.slices.size(), 3)
	assert_eq(live.slices[0].assignment_revision, 1)
	assert_eq(live.slices[1].assignment_revision, 3)
	assert_eq(live.slices[2].assignment_revision, 5)

func test_stage2_malformed_segments_and_event_boundaries_reject_without_mutation() -> void:
	var service := ReportService.new()
	var pair := _make_active_run(1000000, 1000)
	var state: GameState = pair[0]
	var run: SimulationRunService.SimulationRunResult = pair[1]
	var before := _state_digest(state)
	run.simulation_result.segments[0].erase("form_id")
	assert_eq(service.ingest_committed_run(state, run).error_code, ReportService.ERR_INVALID_RESULT)
	_assert_state_unchanged(before, state)

	pair = _make_active_run(1000000, 1000)
	state = pair[0]
	run = pair[1]
	before = _state_digest(state)
	run.simulation_result.segments[0].elapsed_msec = 999
	assert_eq(service.ingest_committed_run(state, run).error_code, ReportService.ERR_INVALID_RESULT)
	_assert_state_unchanged(before, state)

	pair = _make_active_run(1000000, 2000)
	state = pair[0]
	run = pair[1]
	before = _state_digest(state)
	run.simulation_result.segments[0].end_simulation_msec = 1000
	assert_eq(service.ingest_committed_run(state, run).error_code, ReportService.ERR_INVALID_RESULT)
	_assert_state_unchanged(before, state)

	pair = _make_active_run(1, 10000)
	state = pair[0]
	run = pair[1]
	before = _state_digest(state)
	var start_event := SimulationEngine.SimulationEvent.threshold_settled(0, &"THR_GLOAMWOOD", 0)
	run.simulation_result.events.append(start_event)
	assert_eq(service.ingest_committed_run(state, run).error_code, ReportService.ERR_INVALID_RESULT)
	_assert_state_unchanged(before, state)

	pair = _make_active_run(1, 10000)
	state = pair[0]
	run = pair[1]
	before = _state_digest(state)
	run.simulation_result.events.append(SimulationEngine.SimulationEvent.threshold_settled(run.result_simulation_time_msec + 1, &"THR_GLOAMWOOD", 0))
	assert_eq(service.ingest_committed_run(state, run).error_code, ReportService.ERR_INVALID_RESULT)
	_assert_state_unchanged(before, state)

func test_stage2_event_boundaries_accept_interior_end_and_preserve_order() -> void:
	var service := ReportService.new()
	var state := _state(&"THR_GLOAMWOOD", 1)
	_unlock(state, [&"SOUL_CALLING_SOLDIER"])
	var run := SimulationRunService.new(_registry()).run_committed(state, 10000, SimulationRunService.MODE_DEBUG)
	assert_true(run.success, run.developer_details)
	var end_event := SimulationEngine.SimulationEvent.threshold_settled(run.result_simulation_time_msec, &"THR_GLOAMWOOD", 0)
	end_event.priority = 250
	run.simulation_result.events.append(end_event)
	assert_true(service.ingest_committed_run(state, run).success)
	var details: Array = service.peek_live_global(state).event_details
	assert_gte(details.size(), 2)
	assert_eq(details[0].priority, 200)
	assert_eq(details[1].priority, 250)
	assert_true(service.peek_live_assignment(state, &"THR_GLOAMWOOD", 1).meaningful_event)

func test_stage2_lifecycle_boundary_event_belongs_to_overdue_slice_only() -> void:
	var service := ReportService.new()
	var state := _state(&"THR_GLOAMWOOD", 1)
	_unlock(state, [&"SOUL_CALLING_SOLDIER"])
	var run := SimulationRunService.new(_registry()).run_committed(state, 10000, SimulationRunService.MODE_DEBUG)
	assert_true(run.success, run.developer_details)
	assert_true(service.ingest_committed_run(state, run).success)
	var slices: Array = service.peek_live_global(state).slices
	assert_eq(slices.size(), 2)
	assert_eq(slices[0].lifecycle_state, "OVERDUE")
	assert_eq(slices[1].lifecycle_state, "SETTLED")
	assert_eq(service.peek_live_global(state).event_details[0].occurred_simulation_msec, slices[0].end_simulation_msec)
	assert_eq(service.peek_live_global(state).event_details[0].occurred_simulation_msec, slices[1].start_simulation_msec)

func test_stage2_ingestion_overflows_reject_without_mutation() -> void:
	var service := ReportService.new()
	var no_reaping := GameState.new(0)
	no_reaping.report_state.live.run_count = FixedPoint.INT64_MAX
	no_reaping.report_state.live.mode_counts[str(SimulationRunService.MODE_DEBUG)] = FixedPoint.INT64_MAX
	var no_reaping_run := SimulationRunService.new(_registry()).run_committed(no_reaping, 1, SimulationRunService.MODE_DEBUG)
	var before := _state_digest(no_reaping)
	var overflow := service.ingest_committed_run(no_reaping, no_reaping_run)
	assert_eq(overflow.error_code, ReportService.ERR_AGGREGATION_OVERFLOW)
	_assert_state_unchanged(before, no_reaping)

	var pair := _make_active_run(1000000, 1000)
	var state: GameState = pair[0]
	var run: SimulationRunService.SimulationRunResult = pair[1]
	var slice := _make_slice_from_segment(run.simulation_result.segments[0])
	slice.elapsed_msec = FixedPoint.INT64_MAX
	_install_live_slice_at_cursor(state, run.simulation_result.segments[0], slice)
	before = _state_digest(state)
	assert_eq(service.ingest_committed_run(state, run).error_code, ReportService.ERR_AGGREGATION_OVERFLOW)
	_assert_state_unchanged(before, state)

	pair = _make_active_run(1000000, HOUR)
	state = pair[0]
	run = pair[1]
	slice = _make_slice_from_segment(run.simulation_result.segments[0])
	slice.returned_souls_delta = FixedPoint.INT64_MAX
	_install_live_slice_at_cursor(state, run.simulation_result.segments[0], slice)
	before = _state_digest(state)
	assert_eq(service.ingest_committed_run(state, run).error_code, ReportService.ERR_AGGREGATION_OVERFLOW)
	_assert_state_unchanged(before, state)

	pair = _make_active_run(1000000, 1000)
	state = pair[0]
	run = pair[1]
	slice = _make_slice_from_segment(run.simulation_result.segments[0])
	slice.backlog_delta = FixedPoint.INT64_MIN
	_install_live_slice_at_cursor(state, run.simulation_result.segments[0], slice)
	before = _state_digest(state)
	assert_eq(service.ingest_committed_run(state, run).error_code, ReportService.ERR_AGGREGATION_OVERFLOW)
	_assert_state_unchanged(before, state)

	pair = _make_active_run(1000000, 1000)
	state = pair[0]
	run = pair[1]
	run.simulation_result.segments[0].backlog_delta = FixedPoint.INT64_MAX
	slice = _make_slice_from_segment(run.simulation_result.segments[0])
	slice.backlog_delta = 1
	_install_live_slice_at_cursor(state, run.simulation_result.segments[0], slice)
	before = _state_digest(state)
	assert_eq(service.ingest_committed_run(state, run).error_code, ReportService.ERR_AGGREGATION_OVERFLOW)
	_assert_state_unchanged(before, state)

	pair = _make_active_run(1000000, HOUR)
	state = pair[0]
	run = pair[1]
	slice = _make_slice_from_segment(run.simulation_result.segments[0])
	slice.inventory_gains[&"RES_ESSENCE"] = FixedPoint.INT64_MAX
	_install_live_slice_at_cursor(state, run.simulation_result.segments[0], slice)
	before = _state_digest(state)
	assert_eq(service.ingest_committed_run(state, run).error_code, ReportService.ERR_AGGREGATION_OVERFLOW)
	_assert_state_unchanged(before, state)

func test_stage2_channel_event_count_and_sequence_overflows_reject_without_mutation() -> void:
	var service := ReportService.new()
	var pair := _make_active_run(1000000, HOUR)
	var state: GameState = pair[0]
	var run: SimulationRunService.SimulationRunResult = pair[1]
	var slice := _make_slice_from_segment(run.simulation_result.segments[0])
	var delta: Dictionary = run.simulation_result.segments[0].channel_deltas[0]
	var summary := ReportState.ChannelSummary.new()
	summary.channel_id = StringName(delta.channel_id)
	summary.output_item_id = StringName(delta.output_item_id)
	summary.banked_units_delta = FixedPoint.INT64_MAX
	slice.channel_summaries[summary.channel_id] = summary
	_install_live_slice_at_cursor(state, run.simulation_result.segments[0], slice)
	var before := _state_digest(state)
	assert_eq(service.ingest_committed_run(state, run).error_code, ReportService.ERR_AGGREGATION_OVERFLOW)
	_assert_state_unchanged(before, state)

	pair = _make_active_run(1, 10000)
	state = pair[0]
	run = pair[1]
	state.report_state.live.events_by_type["THRESHOLD_SETTLED"] = FixedPoint.INT64_MAX
	before = _state_digest(state)
	assert_eq(service.ingest_committed_run(state, run).error_code, ReportService.ERR_AGGREGATION_OVERFLOW)
	_assert_state_unchanged(before, state)

	pair = _make_active_run(1, 10000)
	state = pair[0]
	run = pair[1]
	state.report_state.next_event_sequence = FixedPoint.INT64_MAX
	before = _state_digest(state)
	assert_eq(service.ingest_committed_run(state, run).error_code, ReportService.ERR_SEQUENCE_OVERFLOW)
	_assert_state_unchanged(before, state)

func test_stage2_dropped_active_segments_cannot_be_reclassified_as_no_reaping() -> void:
	var service := ReportService.new()
	var pair := _make_active_run(1000000, 1000)
	var state: GameState = pair[0]
	var run: SimulationRunService.SimulationRunResult = pair[1]
	var before := _state_digest(state)
	run.simulation_result.segments.clear()
	run.simulation_result.change_summary.clear()
	var result := service.ingest_committed_run(state, run)
	assert_false(result.success)
	assert_eq(result.error_code, ReportService.ERR_INVALID_RESULT)
	_assert_state_unchanged(before, state)

func test_stage2_reordered_committed_events_reject_before_sequence_assignment() -> void:
	var service := ReportService.new()
	var pair := _make_active_run(1, 10000)
	var state: GameState = pair[0]
	var run: SimulationRunService.SimulationRunResult = pair[1]
	var before := _state_digest(state)
	var earlier_priority := SimulationEngine.SimulationEvent.threshold_settled(run.simulation_result.events[0].occurred_simulation_msec, &"THR_GLOAMWOOD", 0)
	earlier_priority.priority = SimulationEngine.EVENT_PRIORITY_CHANNEL_GAIN
	run.simulation_result.events.append(earlier_priority)
	var result := service.ingest_committed_run(state, run)
	assert_false(result.success)
	assert_eq(result.error_code, ReportService.ERR_INVALID_RESULT)
	_assert_state_unchanged(before, state)

func test_stage2_inconsistent_channel_endpoint_delta_rejects_without_mutation() -> void:
	var service := ReportService.new()
	var pair := _make_active_run(1000000, HOUR)
	var state: GameState = pair[0]
	var run: SimulationRunService.SimulationRunResult = pair[1]
	var before := _state_digest(state)
	var delta: Dictionary = run.simulation_result.segments[0].channel_deltas[0]
	delta.banked_units_delta = int(delta.banked_units_delta) + 1
	var result := service.ingest_committed_run(state, run)
	assert_false(result.success)
	assert_eq(result.error_code, ReportService.ERR_INVALID_RESULT)
	_assert_state_unchanged(before, state)

func test_stage2_existing_slice_loadout_mismatch_rejects_without_mutation() -> void:
	var service := ReportService.new()
	var state := _state(&"THR_GLOAMWOOD", 1000000)
	_unlock(state, [&"SOUL_CALLING_SOLDIER"])
	var first := SimulationRunService.new(_registry()).run_committed(state, 1000, SimulationRunService.MODE_DEBUG)
	assert_true(first.success, first.developer_details)
	assert_true(service.ingest_committed_run(state, first).success)
	var second := SimulationRunService.new(_registry()).run_committed(state, 1000, SimulationRunService.MODE_DEBUG)
	assert_true(second.success, second.developer_details)
	var before := _state_digest(state)
	second.simulation_result.segments[0].form_id = "FORM_SCRIBE"
	var result := service.ingest_committed_run(state, second)
	assert_false(result.success)
	assert_eq(result.error_code, ReportService.ERR_INVALID_RESULT)
	_assert_state_unchanged(before, state)
