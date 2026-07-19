class_name ReportService
extends RefCounted

## Sole scene-independent owner for report ingestion, pure peeks, and snapshots.
##
## The service consumes successful committed SimulationRunService results after
## gameplay has already been applied. It never calls SimulationEngine, reads
## clocks, touches files, inspects UI, or grants output. Mutating operations use a
## cloned candidate and commit only after validation so failures preserve gameplay
## and report authority exactly.

const OK := &""
const ERR_INVALID_RESULT := &"REPORT_INVALID_RESULT"
const ERR_FORECAST := &"REPORT_FORECAST_REJECTED"
const ERR_GAP := &"REPORT_FORWARD_GAP"
const ERR_OVERLAP := &"REPORT_PARTIAL_OVERLAP"
const ERR_STALE_SEQUENCE := &"REPORT_STALE_SEQUENCE"
const ERR_BAD_REASON := &"REPORT_BAD_REASON"
const ERR_OFFLINE_PURITY := &"REPORT_OFFLINE_PURITY"
const ERR_INCOMPLETE_CURSOR := &"REPORT_INCOMPLETE_CURSOR"
const ERR_STATE_INVALID := &"REPORT_STATE_INVALID"

func ingest_committed_run(state: GameState, run_result: SimulationRunService.SimulationRunResult) -> ReportResult:
	var pre := _validate_ingest_request(state, run_result)
	if not pre.ok: return ReportResult.err_result(StringName(pre.code), pre.get("details", ""), state.report_state.report_cursor_msec if state and state.report_state else 0)
	var cursor := state.report_state.report_cursor_msec
	if run_result.result_simulation_time_msec <= cursor:
		return ReportResult.ok_result(false, true, false, cursor, "covered")
	if run_result.baseline_simulation_time_msec < cursor:
		return ReportResult.err_result(ERR_OVERLAP, "partial overlap", cursor)
	if run_result.baseline_simulation_time_msec > cursor:
		return ReportResult.err_result(ERR_GAP, "forward gap", cursor)
	if run_result.requested_elapsed_msec == 0 or run_result.result_simulation_time_msec == run_result.baseline_simulation_time_msec:
		return ReportResult.ok_result(false, false, false, cursor, "zero")
	var candidate := state.deep_clone()
	var rs := candidate.report_state
	_record_run_window(rs.live, run_result)
	if run_result.simulation_result.change_summary.has("threshold_id"):
		var reaping: GameState.ReapingState = candidate.reapings[StringName(run_result.simulation_result.change_summary.threshold_id)]
		for segment in run_result.simulation_result.segments:
			_upsert_segment(rs.live, reaping, segment)
	for event in run_result.simulation_result.events:
		if event.reportable:
			_ingest_event(rs, event)
	rs.report_cursor_msec = run_result.result_simulation_time_msec
	if _validate_report_state(rs, candidate.simulation_time_msec).ok:
		state.copy_from(candidate)
		return ReportResult.ok_result(true, false, true, state.report_state.report_cursor_msec, "ingested")
	return ReportResult.err_result(ERR_STATE_INVALID, "candidate failed validation", cursor)

func peek_live_global(state: GameState) -> Dictionary:
	return _view_for_window(state.report_state.live, &"", 0)

func peek_live_threshold(state: GameState, threshold_id: StringName) -> Dictionary:
	return _view_for_window(state.report_state.live, threshold_id, 0)

func peek_live_assignment(state: GameState, threshold_id: StringName, assignment_revision: int) -> Dictionary:
	return _view_for_window(state.report_state.live, threshold_id, assignment_revision)

func get_report_record(state: GameState, report_sequence: int) -> Dictionary:
	for record in state.report_state.history:
		if record.report_sequence == report_sequence:
			var view := _view_for_window(record.window, &"", 0)
			view["report_sequence"] = report_sequence; view["snapshot_reason"] = str(record.snapshot_reason)
			return view
	return {"ok": false, "code": "REPORT_RECORD_NOT_FOUND"}

func snapshot_live(state: GameState, expected_next_report_sequence: int, snapshot_reason: StringName) -> ReportResult:
	if not ReportState.VALID_REASONS.has(snapshot_reason): return ReportResult.err_result(ERR_BAD_REASON, "bad reason", state.report_state.report_cursor_msec)
	if state.report_state.next_report_sequence != expected_next_report_sequence: return ReportResult.err_result(ERR_STALE_SEQUENCE, "stale sequence", state.report_state.report_cursor_msec)
	if state.report_state.report_cursor_msec != state.simulation_time_msec: return ReportResult.err_result(ERR_INCOMPLETE_CURSOR, "report cursor trails simulation", state.report_state.report_cursor_msec)
	if state.report_state.live.is_empty(): return ReportResult.ok_result(false, false, false, state.report_state.report_cursor_msec, "empty")
	if snapshot_reason == ReportState.REASON_OFFLINE_RETURN and not _offline_only(state.report_state.live): return ReportResult.err_result(ERR_OFFLINE_PURITY, "offline return requires offline-only window", state.report_state.report_cursor_msec)
	var candidate := state.deep_clone()
	var record := ReportState.ReportRecord.new()
	record.report_sequence = candidate.report_state.next_report_sequence
	record.snapshot_reason = snapshot_reason
	record.window = candidate.report_state.live.deep_clone()
	candidate.report_state.history.append(record)
	candidate.report_state.next_report_sequence += 1
	while candidate.report_state.history.size() > ReportState.MAX_HISTORY_RECORDS:
		candidate.report_state.history.pop_front(); candidate.report_state.dropped_history_record_count += 1
	candidate.report_state.reset_live_at_cursor()
	state.copy_from(candidate)
	return ReportResult.ok_result(true, false, true, state.report_state.report_cursor_msec, "snapshotted")

func _validate_ingest_request(state: GameState, run_result: SimulationRunService.SimulationRunResult) -> Dictionary:
	if state == null or state.report_state == null: return {"ok": false, "code": ERR_STATE_INVALID}
	if run_result == null or run_result.mode == SimulationRunService.MODE_FORECAST: return {"ok": false, "code": ERR_FORECAST}
	if not SimulationRunService.COMMITTED_MODES.has(run_result.mode): return {"ok": false, "code": ERR_INVALID_RESULT}
	if not run_result.success or run_result.projected_state != null or run_result.simulation_result == null or not run_result.simulation_result.success: return {"ok": false, "code": ERR_INVALID_RESULT}
	if run_result.requested_elapsed_msec != run_result.result_simulation_time_msec - run_result.baseline_simulation_time_msec: return {"ok": false, "code": ERR_INVALID_RESULT}
	if state.simulation_time_msec != run_result.result_simulation_time_msec: return {"ok": false, "code": ERR_INVALID_RESULT}
	if run_result.simulation_result.committed_elapsed_msec != run_result.requested_elapsed_msec: return {"ok": false, "code": ERR_INVALID_RESULT}
	if run_result.simulation_result.change_summary.has("threshold_id") and not state.reapings.has(StringName(run_result.simulation_result.change_summary.threshold_id)): return {"ok": false, "code": ERR_INVALID_RESULT}
	return {"ok": true}

func _record_run_window(window: ReportState.ReportWindow, run_result: SimulationRunService.SimulationRunResult) -> void:
	window.start_simulation_msec = min(window.start_simulation_msec, run_result.baseline_simulation_time_msec) if window.run_count > 0 else run_result.baseline_simulation_time_msec
	window.end_simulation_msec = run_result.result_simulation_time_msec
	window.run_count += 1
	window.mode_counts[str(run_result.mode)] = int(window.mode_counts.get(str(run_result.mode), 0)) + 1

func _upsert_segment(window: ReportState.ReportWindow, reaping: GameState.ReapingState, segment: Dictionary) -> void:
	var key := "%s|%d|%s" % [reaping.threshold_id, reaping.assignment_revision, segment.lifecycle]
	var slice: ReportState.AttributionSlice = window.slices.get(key, null)
	if slice == null:
		slice = ReportState.AttributionSlice.new(); slice.threshold_id = reaping.threshold_id; slice.assignment_revision = reaping.assignment_revision; slice.lifecycle_state = StringName(segment.lifecycle)
		slice.form_id = reaping.form_id; slice.writ_id = reaping.writ_id; slice.retinue_ids = reaping.retinue_ids.duplicate(); slice.start_simulation_msec = segment.start_simulation_msec
		window.slices[key] = slice
	slice.end_simulation_msec = segment.end_simulation_msec; slice.elapsed_msec += int(segment.elapsed_msec)
	slice.returned_souls_delta += int(segment.returned_souls_delta); slice.backlog_delta += int(segment.backlog_delta); slice.completed_cycles_delta += int(segment.completed_cycles_delta)
	_add_map(slice.inventory_gains, &"RES_ESSENCE", int(segment.Essence_delta)); _add_map(slice.mastery_gains, reaping.form_id, int(segment.Mastery_delta_subunits))
	for delta in segment.channel_deltas:
		var cid := StringName(delta.channel_id); var summary: ReportState.ChannelSummary = slice.channel_summaries.get(cid, null)
		if summary == null:
			summary = ReportState.ChannelSummary.new(); summary.channel_id = cid; summary.output_item_id = StringName(delta.output_item_id)
			summary.first_progress_subunits_before = int(delta.progress_subunits_before); summary.first_rate_carry_units_before = int(delta.rate_carry_units_before); summary.first_total_banked_units_before = int(delta.total_banked_units_before); slice.channel_summaries[cid] = summary
		summary.banked_units_delta += int(delta.banked_units_delta); summary.latest_progress_subunits_after = int(delta.progress_subunits_after); summary.latest_rate_carry_units_after = int(delta.rate_carry_units_after); summary.latest_total_banked_units_after = int(delta.total_banked_units_after)
		_add_map(slice.inventory_gains, summary.output_item_id, int(delta.banked_units_delta))

func _ingest_event(rs: ReportState, event: SimulationEngine.SimulationEvent) -> void:
	rs.live.events_by_type[str(event.event_type)] = int(rs.live.events_by_type.get(str(event.event_type), 0)) + 1
	var detail := ReportState.ReportEventDetail.new(); detail.event_sequence = rs.next_event_sequence; rs.next_event_sequence += 1
	detail.event_type = event.event_type; detail.occurred_simulation_msec = event.occurred_simulation_msec; detail.priority = event.priority; detail.subject_id = event.subject_id; detail.source_id = event.source_id
	rs.live.event_details.append(detail)
	while rs.live.event_details.size() > ReportState.MAX_EVENT_DETAILS:
		rs.live.event_details.pop_front(); rs.live.omitted_oldest_event_detail_count += 1

func _view_for_window(window: ReportState.ReportWindow, threshold_id: StringName, assignment_revision: int) -> Dictionary:
	var out := {"ok": true, "start_simulation_msec": window.start_simulation_msec, "end_simulation_msec": window.end_simulation_msec, "run_count": window.run_count, "mode_counts": window.mode_counts.duplicate(true), "slices": [], "totals": {"returned_souls_delta": 0, "backlog_delta": 0, "completed_cycles_delta": 0, "inventory_gains": {}, "mastery_gains": {}, "channel_summaries": {}}}
	var keys := window.slices.keys(); keys.sort()
	for key in keys:
		var s: ReportState.AttributionSlice = window.slices[key]
		if threshold_id != &"" and s.threshold_id != threshold_id: continue
		if assignment_revision > 0 and s.assignment_revision != assignment_revision: continue
		var d := _slice_dict(s); out.slices.append(d); _rollup(out.totals, s)
	out["is_empty"] = out.slices.is_empty(); out["whole_gain"] = int(out.totals.returned_souls_delta) > 0 or not out.totals.inventory_gains.is_empty(); out["progress_change"] = int(out.totals.backlog_delta) != 0 or not out.totals.mastery_gains.is_empty(); out["meaningful_event"] = not window.events_by_type.is_empty()
	return out

func _slice_dict(s: ReportState.AttributionSlice) -> Dictionary:
	var channels := {}
	for cid in s.channel_summaries.keys():
		var c: ReportState.ChannelSummary = s.channel_summaries[cid]
		channels[str(cid)] = {"output_item_id": str(c.output_item_id), "banked_units_delta": c.banked_units_delta, "first_progress_subunits_before": c.first_progress_subunits_before, "latest_progress_subunits_after": c.latest_progress_subunits_after, "first_total_banked_units_before": c.first_total_banked_units_before, "latest_total_banked_units_after": c.latest_total_banked_units_after}
	return {"threshold_id": str(s.threshold_id), "assignment_revision": s.assignment_revision, "lifecycle_state": str(s.lifecycle_state), "form_id": str(s.form_id), "writ_id": str(s.writ_id), "retinue_ids": _strings(s.retinue_ids), "loadout_key": s.loadout_key(), "start_simulation_msec": s.start_simulation_msec, "end_simulation_msec": s.end_simulation_msec, "elapsed_msec": s.elapsed_msec, "returned_souls_delta": s.returned_souls_delta, "backlog_delta": s.backlog_delta, "completed_cycles_delta": s.completed_cycles_delta, "inventory_gains": _string_keyed(s.inventory_gains), "mastery_gains": _string_keyed(s.mastery_gains), "channel_summaries": channels}

func _rollup(totals: Dictionary, s: ReportState.AttributionSlice) -> void:
	totals.returned_souls_delta += s.returned_souls_delta; totals.backlog_delta += s.backlog_delta; totals.completed_cycles_delta += s.completed_cycles_delta
	for k in s.inventory_gains: _add_map(totals.inventory_gains, k, s.inventory_gains[k])
	for k in s.mastery_gains: _add_map(totals.mastery_gains, k, s.mastery_gains[k])
	for k in s.channel_summaries: totals.channel_summaries[str(k)] = true

func _offline_only(window: ReportState.ReportWindow) -> bool:
	return window.run_count > 0 and int(window.mode_counts.get(str(SimulationRunService.MODE_OFFLINE_FIXTURE), 0)) == window.run_count and window.mode_counts.size() == 1

func _validate_report_state(rs: ReportState, simulation_time_msec: int) -> Dictionary:
	if rs.report_cursor_msec < 0 or rs.report_cursor_msec > simulation_time_msec: return {"ok": false}
	if rs.next_report_sequence <= 0 or rs.next_event_sequence <= 0 or rs.history.size() > ReportState.MAX_HISTORY_RECORDS or rs.live.event_details.size() > ReportState.MAX_EVENT_DETAILS: return {"ok": false}
	return {"ok": true}

func _add_map(map: Dictionary, key: StringName, amount: int) -> void:
	if amount != 0: map[key] = int(map.get(key, 0)) + amount
func _strings(values: Array[StringName]) -> Array:
	var out := []
	for v in values:
		out.append(str(v))
	return out
func _string_keyed(map: Dictionary) -> Dictionary:
	var out := {}
	for k in map.keys():
		out[str(k)] = map[k]
	return out

class ReportResult:
	extends RefCounted
	var success := false; var error_code: StringName = &""; var developer_details := ""; var changed := false; var duplicate := false; var checkpoint_requested := false; var cursor_msec := 0
	static func ok_result(changed_value: bool, duplicate_value: bool, checkpoint_value: bool, cursor_value: int, details := "") -> ReportResult:
		var r := ReportResult.new(); r.success = true; r.changed = changed_value; r.duplicate = duplicate_value; r.checkpoint_requested = checkpoint_value; r.cursor_msec = cursor_value; r.developer_details = details; return r
	static func err_result(code: StringName, details: String, cursor_value: int) -> ReportResult:
		var r := ReportResult.new(); r.success = false; r.error_code = code; r.developer_details = details; r.cursor_msec = cursor_value; return r
