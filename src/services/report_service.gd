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
const ERR_SEQUENCE_OVERFLOW := &"REPORT_SEQUENCE_OVERFLOW"
const ERR_AGGREGATION_OVERFLOW := &"REPORT_AGGREGATION_OVERFLOW"

const SEGMENT_REQUIRED_KEYS := ["threshold_id", "assignment_revision", "form_id", "writ_id", "retinue_ids", "start_simulation_msec", "end_simulation_msec", "elapsed_msec", "lifecycle", "returned_souls_delta", "backlog_delta", "Essence_delta", "Mastery_delta_subunits", "completed_cycles_delta", "channel_deltas"]
const CHANNEL_DELTA_REQUIRED_KEYS := ["channel_id", "output_item_id", "banked_units_delta", "progress_subunits_before", "progress_subunits_after", "rate_carry_units_before", "rate_carry_units_after", "total_banked_units_before", "total_banked_units_after"]
const VALID_LIFECYCLES := [&"OVERDUE", &"SETTLED"]

func ingest_committed_run(state: GameState, run_result: SimulationRunService.SimulationRunResult) -> ReportResult:
	var pre := _validate_ingest_request(state, run_result)
	var cursor := state.report_state.report_cursor_msec if state and state.report_state else 0
	if not pre.ok:
		return ReportResult.err_result(StringName(pre.code), pre.get("details", ""), cursor)
	var facts := _validate_committed_result_facts(run_result)
	if not facts.ok:
		return ReportResult.err_result(StringName(facts.code), facts.get("details", ""), cursor)

	var baseline := run_result.baseline_simulation_time_msec
	var result_end := run_result.result_simulation_time_msec
	if run_result.requested_elapsed_msec == 0 and baseline == cursor and result_end == cursor and state.simulation_time_msec == result_end:
		return ReportResult.ok_result(false, false, false, cursor, "zero")
	if result_end <= cursor:
		return ReportResult.ok_result(false, true, false, cursor, "covered")
	if baseline < cursor:
		return ReportResult.err_result(ERR_OVERLAP, "partial overlap", cursor)
	if baseline > cursor:
		return ReportResult.err_result(ERR_GAP, "forward gap", cursor)
	if state.simulation_time_msec != result_end:
		return ReportResult.err_result(ERR_INVALID_RESULT, "gameplay cursor does not match unrepresented interval", cursor)

	var candidate := state.deep_clone()
	var rs := candidate.report_state
	var aggregate := _record_run_window(rs.live, run_result)
	if not aggregate.ok:
		return ReportResult.err_result(StringName(aggregate.code), aggregate.get("details", ""), cursor)
	for segment in run_result.simulation_result.segments:
		aggregate = _upsert_segment(rs.live, segment)
		if not aggregate.ok:
			return ReportResult.err_result(StringName(aggregate.code), aggregate.get("details", ""), cursor)
	for event in run_result.simulation_result.events:
		if event.reportable:
			aggregate = _ingest_event(rs, event)
			if not aggregate.ok:
				return ReportResult.err_result(StringName(aggregate.code), aggregate.get("details", ""), cursor)
	rs.report_cursor_msec = result_end
	var validation := GameStateValidator.validate_report_state(candidate)
	if validation.ok:
		state.copy_from(candidate)
		return ReportResult.ok_result(true, false, true, state.report_state.report_cursor_msec, "ingested")
	return ReportResult.err_result(ERR_STATE_INVALID, "candidate failed validation: %s" % validation.get("field_path", "report_state"), cursor)

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
			view["report_sequence"] = report_sequence; view["snapshot_reason"] = str(record.snapshot_reason); view["snapshot_simulation_msec"] = record.snapshot_simulation_msec
			return view
	return {"ok": false, "code": "REPORT_RECORD_NOT_FOUND"}

func snapshot_live(state: GameState, expected_next_report_sequence: int, snapshot_reason: StringName) -> ReportResult:
	if not ReportState.VALID_REASONS.has(snapshot_reason): return ReportResult.err_result(ERR_BAD_REASON, "bad reason", state.report_state.report_cursor_msec)
	if state.report_state.next_report_sequence != expected_next_report_sequence: return ReportResult.err_result(ERR_STALE_SEQUENCE, "stale sequence", state.report_state.report_cursor_msec)
	if state.report_state.report_cursor_msec != state.simulation_time_msec: return ReportResult.err_result(ERR_INCOMPLETE_CURSOR, "report cursor trails simulation", state.report_state.report_cursor_msec)
	if state.report_state.live.is_empty(): return ReportResult.ok_result(false, false, false, state.report_state.report_cursor_msec, "empty")
	if state.report_state.next_report_sequence == FixedPoint.INT64_MAX: return ReportResult.err_result(ERR_SEQUENCE_OVERFLOW, "next report sequence overflow", state.report_state.report_cursor_msec)
	if snapshot_reason == ReportState.REASON_OFFLINE_RETURN and not _offline_only(state.report_state.live): return ReportResult.err_result(ERR_OFFLINE_PURITY, "offline return requires offline-only window", state.report_state.report_cursor_msec)
	var candidate := state.deep_clone()
	var record := ReportState.ReportRecord.new()
	record.report_sequence = candidate.report_state.next_report_sequence
	record.snapshot_reason = snapshot_reason
	record.snapshot_simulation_msec = candidate.report_state.report_cursor_msec
	record.window = candidate.report_state.live.deep_clone()
	candidate.report_state.history.append(record)
	candidate.report_state.next_report_sequence += 1
	while candidate.report_state.history.size() > ReportState.MAX_HISTORY_RECORDS:
		candidate.report_state.history.pop_front(); candidate.report_state.dropped_history_record_count += 1
	candidate.report_state.reset_live_at_cursor()
	var validation := GameStateValidator.validate_report_state(candidate)
	if not validation.ok:
		return ReportResult.err_result(ERR_STATE_INVALID, "candidate failed validation: %s" % validation.get("field_path", "report_state"), state.report_state.report_cursor_msec)
	state.copy_from(candidate)
	return ReportResult.ok_result(true, false, true, state.report_state.report_cursor_msec, "snapshotted")

func _validate_ingest_request(state: GameState, run_result: SimulationRunService.SimulationRunResult) -> Dictionary:
	if state == null or state.report_state == null:
		return _failure(ERR_STATE_INVALID, "missing report state")
	var state_validation := GameStateValidator.validate_report_state(state)
	if not state_validation.ok:
		return _failure(ERR_STATE_INVALID, "invalid report state")
	if run_result == null:
		return _failure(ERR_INVALID_RESULT, "missing run result")
	if run_result.mode == SimulationRunService.MODE_FORECAST:
		return _failure(ERR_FORECAST, "forecasts are not committed report input")
	if not SimulationRunService.COMMITTED_MODES.has(run_result.mode):
		return _failure(ERR_INVALID_RESULT, "unapproved committed mode")
	if not run_result.success or run_result.projected_state != null or run_result.simulation_result == null or not run_result.simulation_result.success:
		return _failure(ERR_INVALID_RESULT, "unsuccessful or projected result")
	if run_result.requested_elapsed_msec < 0 or run_result.baseline_simulation_time_msec < 0 or run_result.result_simulation_time_msec < 0:
		return _failure(ERR_INVALID_RESULT, "negative run cursor")
	if run_result.result_simulation_time_msec < run_result.baseline_simulation_time_msec:
		return _failure(ERR_INVALID_RESULT, "result cursor before baseline")
	if run_result.requested_elapsed_msec != run_result.result_simulation_time_msec - run_result.baseline_simulation_time_msec:
		return _failure(ERR_INVALID_RESULT, "wrapper elapsed mismatch")
	if run_result.simulation_result.requested_elapsed_msec != run_result.requested_elapsed_msec:
		return _failure(ERR_INVALID_RESULT, "engine requested elapsed mismatch")
	if run_result.simulation_result.committed_elapsed_msec != run_result.requested_elapsed_msec:
		return _failure(ERR_INVALID_RESULT, "engine committed elapsed mismatch")
	return {"ok": true}

func _validate_committed_result_facts(run_result: SimulationRunService.SimulationRunResult) -> Dictionary:
	var result := run_result.simulation_result
	if not (result.segments is Array) or not (result.events is Array):
		return _failure(ERR_INVALID_RESULT, "segments/events must be arrays")
	var segment_check := _validate_segments_for_run(run_result)
	if not segment_check.ok:
		return segment_check
	return _validate_events_for_run(run_result)

func _validate_segments_for_run(run_result: SimulationRunService.SimulationRunResult) -> Dictionary:
	var segments: Array = run_result.simulation_result.segments
	var baseline: int = run_result.baseline_simulation_time_msec
	var result_end: int = run_result.result_simulation_time_msec
	var requested: int = run_result.requested_elapsed_msec
	var active_summary: bool = run_result.simulation_result.change_summary.has("threshold_id")
	if segments.is_empty():
		return {"ok": true} if not active_summary else _failure(ERR_INVALID_RESULT, "active interval requires segments")
	var expected_start: int = baseline
	var elapsed_sum: int = 0
	var base_threshold := &""
	var base_revision := 0
	var base_form := &""
	var base_writ := &""
	var base_retinues: Array[StringName] = []
	for i in range(segments.size()):
		var segment_value: Variant = segments[i]
		if not (segment_value is Dictionary):
			return _failure(ERR_INVALID_RESULT, "segment must be dictionary")
		var segment: Dictionary = segment_value
		var keys := _has_required_keys(segment, SEGMENT_REQUIRED_KEYS)
		if not keys.ok:
			return _failure(ERR_INVALID_RESULT, "segment missing %s" % keys.key)
		var ints := _validate_segment_ints(segment)
		if not ints.ok:
			return ints
		var threshold_id := StringName(str(segment.threshold_id))
		var form_id := StringName(str(segment.form_id))
		var writ_id := StringName(str(segment.writ_id))
		var lifecycle := StringName(str(segment.lifecycle))
		var retinues = _validated_retinues(segment.retinue_ids)
		if threshold_id == &"" or form_id == &"" or writ_id == &"" or not VALID_LIFECYCLES.has(lifecycle) or retinues == null:
			return _failure(ERR_INVALID_RESULT, "invalid segment identity")
		if int(segment.assignment_revision) <= 0:
			return _failure(ERR_INVALID_RESULT, "invalid assignment revision")
		var start_msec := int(segment.start_simulation_msec)
		var end_msec := int(segment.end_simulation_msec)
		var elapsed_msec := int(segment.elapsed_msec)
		if start_msec != expected_start or start_msec < baseline or end_msec > result_end or start_msec >= end_msec or elapsed_msec != end_msec - start_msec:
			return _failure(ERR_INVALID_RESULT, "segment interval mismatch")
		var sum := _checked_add(elapsed_sum, elapsed_msec, ERR_INVALID_RESULT)
		if not sum.ok:
			return sum
		elapsed_sum = int(sum.value)
		expected_start = end_msec
		if i == 0:
			base_threshold = threshold_id; base_revision = int(segment.assignment_revision); base_form = form_id; base_writ = writ_id; base_retinues = retinues
		elif threshold_id != base_threshold or int(segment.assignment_revision) != base_revision or form_id != base_form or writ_id != base_writ or retinues != base_retinues:
			return _failure(ERR_INVALID_RESULT, "segment loadout changed inside committed run")
		var channel_check := _validate_channel_deltas(segment.channel_deltas)
		if not channel_check.ok:
			return channel_check
	if expected_start != result_end or elapsed_sum != requested:
		return _failure(ERR_INVALID_RESULT, "segment coverage mismatch")
	return {"ok": true}

func _validate_segment_ints(segment: Dictionary) -> Dictionary:
	for key in ["assignment_revision", "start_simulation_msec", "end_simulation_msec", "elapsed_msec", "returned_souls_delta", "backlog_delta", "Essence_delta", "Mastery_delta_subunits", "completed_cycles_delta"]:
		if typeof(segment[key]) != TYPE_INT:
			return _failure(ERR_INVALID_RESULT, "segment %s must be int" % key)
	for key in ["start_simulation_msec", "end_simulation_msec", "elapsed_msec", "returned_souls_delta", "Essence_delta", "Mastery_delta_subunits", "completed_cycles_delta"]:
		if int(segment[key]) < 0:
			return _failure(ERR_INVALID_RESULT, "segment %s must be non-negative" % key)
	return {"ok": true}

func _validate_channel_deltas(channel_deltas) -> Dictionary:
	if not (channel_deltas is Array):
		return _failure(ERR_INVALID_RESULT, "channel_deltas must be an array")
	for delta in channel_deltas:
		if not (delta is Dictionary):
			return _failure(ERR_INVALID_RESULT, "channel delta must be dictionary")
		var keys := _has_required_keys(delta, CHANNEL_DELTA_REQUIRED_KEYS)
		if not keys.ok:
			return _failure(ERR_INVALID_RESULT, "channel delta missing %s" % keys.key)
		if str(delta.channel_id).is_empty() or str(delta.output_item_id).is_empty():
			return _failure(ERR_INVALID_RESULT, "channel delta empty id")
		for key in ["banked_units_delta", "progress_subunits_before", "progress_subunits_after", "rate_carry_units_before", "rate_carry_units_after", "total_banked_units_before", "total_banked_units_after"]:
			if typeof(delta[key]) != TYPE_INT or int(delta[key]) < 0:
				return _failure(ERR_INVALID_RESULT, "channel delta %s invalid" % key)
	return {"ok": true}

func _validate_events_for_run(run_result: SimulationRunService.SimulationRunResult) -> Dictionary:
	var baseline: int = run_result.baseline_simulation_time_msec
	var result_end: int = run_result.result_simulation_time_msec
	for event in run_result.simulation_result.events:
		if event == null or not (event is SimulationEngine.SimulationEvent):
			return _failure(ERR_INVALID_RESULT, "event must be SimulationEvent")
		if event.occurred_simulation_msec < 0 or event.occurred_simulation_msec > result_end:
			return _failure(ERR_INVALID_RESULT, "event outside result cursor")
		if event.reportable:
			if event.event_type == &"" or event.subject_id == &"" or event.source_id == &"" or event.priority < 0:
				return _failure(ERR_INVALID_RESULT, "malformed reportable event")
			if event.occurred_simulation_msec <= baseline:
				return _failure(ERR_INVALID_RESULT, "event at or before window start")
			if not _event_owned_by_one_segment(event, run_result.simulation_result.segments):
				return _failure(ERR_INVALID_RESULT, "reportable event has no owning segment")
	return {"ok": true}

func _event_owned_by_one_segment(event: SimulationEngine.SimulationEvent, segments: Array) -> bool:
	var matches := 0
	for segment in segments:
		if not (segment is Dictionary):
			continue
		if StringName(str(segment.threshold_id)) != event.subject_id:
			continue
		if event.occurred_simulation_msec > int(segment.start_simulation_msec) and event.occurred_simulation_msec <= int(segment.end_simulation_msec):
			matches += 1
	return matches == 1

func _record_run_window(window: ReportState.ReportWindow, run_result: SimulationRunService.SimulationRunResult) -> Dictionary:
	window.start_simulation_msec = min(window.start_simulation_msec, run_result.baseline_simulation_time_msec) if window.run_count > 0 else run_result.baseline_simulation_time_msec
	window.end_simulation_msec = run_result.result_simulation_time_msec
	var run_count := _checked_add(window.run_count, 1, ERR_AGGREGATION_OVERFLOW)
	if not run_count.ok:
		return run_count
	window.run_count = int(run_count.value)
	var mode_key := str(run_result.mode)
	var mode_count := _checked_add(int(window.mode_counts.get(mode_key, 0)), 1, ERR_AGGREGATION_OVERFLOW)
	if not mode_count.ok:
		return mode_count
	window.mode_counts[mode_key] = int(mode_count.value)
	return {"ok": true}

func _upsert_segment(window: ReportState.ReportWindow, segment: Dictionary) -> Dictionary:
	var threshold_id := StringName(str(segment.threshold_id))
	var assignment_revision := int(segment.assignment_revision)
	var form_id := StringName(str(segment.form_id))
	var key := canonical_slice_key(threshold_id, assignment_revision, StringName(str(segment.lifecycle)))
	var slice: ReportState.AttributionSlice = window.slices.get(key, null)
	if slice == null:
		slice = ReportState.AttributionSlice.new()
		slice.threshold_id = threshold_id
		slice.assignment_revision = assignment_revision
		slice.lifecycle_state = StringName(segment.lifecycle)
		slice.form_id = form_id
		slice.writ_id = StringName(str(segment.writ_id))
		slice.retinue_ids = _segment_retinues(segment)
		slice.start_simulation_msec = segment.start_simulation_msec
		window.slices[key] = slice
	slice.end_simulation_msec = segment.end_simulation_msec
	var added := _checked_add(slice.elapsed_msec, int(segment.elapsed_msec), ERR_AGGREGATION_OVERFLOW)
	if not added.ok: return added
	slice.elapsed_msec = int(added.value)
	added = _checked_add(slice.returned_souls_delta, int(segment.returned_souls_delta), ERR_AGGREGATION_OVERFLOW)
	if not added.ok: return added
	slice.returned_souls_delta = int(added.value)
	added = _checked_add(slice.backlog_delta, int(segment.backlog_delta), ERR_AGGREGATION_OVERFLOW)
	if not added.ok: return added
	slice.backlog_delta = int(added.value)
	added = _checked_add(slice.completed_cycles_delta, int(segment.completed_cycles_delta), ERR_AGGREGATION_OVERFLOW)
	if not added.ok: return added
	slice.completed_cycles_delta = int(added.value)
	added = _add_map_checked(slice.inventory_gains, &"RES_ESSENCE", int(segment.Essence_delta))
	if not added.ok: return added
	added = _add_map_checked(slice.mastery_gains, form_id, int(segment.Mastery_delta_subunits))
	if not added.ok: return added
	for delta in segment.channel_deltas:
		var cid := StringName(delta.channel_id)
		var summary: ReportState.ChannelSummary = slice.channel_summaries.get(cid, null)
		if summary == null:
			summary = ReportState.ChannelSummary.new()
			summary.channel_id = cid
			summary.output_item_id = StringName(delta.output_item_id)
			summary.first_progress_subunits_before = int(delta.progress_subunits_before)
			summary.first_rate_carry_units_before = int(delta.rate_carry_units_before)
			summary.first_total_banked_units_before = int(delta.total_banked_units_before)
			slice.channel_summaries[cid] = summary
		added = _checked_add(summary.banked_units_delta, int(delta.banked_units_delta), ERR_AGGREGATION_OVERFLOW)
		if not added.ok: return added
		summary.banked_units_delta = int(added.value)
		summary.latest_progress_subunits_after = int(delta.progress_subunits_after)
		summary.latest_rate_carry_units_after = int(delta.rate_carry_units_after)
		summary.latest_total_banked_units_after = int(delta.total_banked_units_after)
		added = _add_map_checked(slice.inventory_gains, summary.output_item_id, int(delta.banked_units_delta))
		if not added.ok: return added
	return {"ok": true}

func _segment_retinues(segment: Dictionary) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in segment.get("retinue_ids", []):
		out.append(StringName(str(id)))
	return out

func _ingest_event(rs: ReportState, event: SimulationEngine.SimulationEvent) -> Dictionary:
	var event_type := str(event.event_type)
	var added := _checked_add(int(rs.live.events_by_type.get(event_type, 0)), 1, ERR_AGGREGATION_OVERFLOW)
	if not added.ok:
		return added
	if rs.next_event_sequence == FixedPoint.INT64_MAX:
		return _failure(ERR_SEQUENCE_OVERFLOW, "next event sequence overflow")
	rs.live.events_by_type[event_type] = int(added.value)
	var detail := ReportState.ReportEventDetail.new()
	detail.event_sequence = rs.next_event_sequence
	rs.next_event_sequence += 1
	detail.event_type = event.event_type
	detail.occurred_simulation_msec = event.occurred_simulation_msec
	detail.priority = event.priority
	detail.subject_id = event.subject_id
	detail.source_id = event.source_id
	rs.live.event_details.append(detail)
	while rs.live.event_details.size() > ReportState.MAX_EVENT_DETAILS:
		var omitted := _checked_add(rs.live.omitted_oldest_event_detail_count, 1, ERR_AGGREGATION_OVERFLOW)
		if not omitted.ok:
			return omitted
		rs.live.event_details.pop_front()
		rs.live.omitted_oldest_event_detail_count = int(omitted.value)
	return {"ok": true}

func _view_for_window(window: ReportState.ReportWindow, threshold_id: StringName, assignment_revision: int) -> Dictionary:
	var out := {"ok": true, "start_simulation_msec": window.start_simulation_msec, "end_simulation_msec": window.end_simulation_msec, "run_count": window.run_count, "mode_counts": window.mode_counts.duplicate(true), "slices": [], "totals": {"returned_souls_delta": 0, "backlog_delta": 0, "completed_cycles_delta": 0, "inventory_gains": {}, "mastery_gains": {}, "channel_summaries": {}}}
	var keys := window.slices.keys(); keys.sort()
	for key in keys:
		var s: ReportState.AttributionSlice = window.slices[key]
		if threshold_id != &"" and s.threshold_id != threshold_id: continue
		if assignment_revision > 0 and s.assignment_revision != assignment_revision: continue
		var d := _slice_dict(s); out.slices.append(d); _rollup(out.totals, s)
	var is_global_view := threshold_id == &"" and assignment_revision == 0
	var event_details := _event_details_for_view(window, threshold_id, assignment_revision, out.slices)
	out["events_by_type"] = window.events_by_type.duplicate(true) if is_global_view else _event_counts_from_details(event_details)
	out["event_details"] = event_details
	out["omitted_oldest_event_detail_count"] = window.omitted_oldest_event_detail_count
	out["is_empty"] = window.is_empty() if is_global_view else out.slices.is_empty(); out["whole_gain"] = int(out.totals.returned_souls_delta) > 0 or not out.totals.inventory_gains.is_empty(); out["progress_change"] = int(out.totals.backlog_delta) != 0 or not out.totals.mastery_gains.is_empty(); out["meaningful_event"] = not out.events_by_type.is_empty()
	return out

func _event_details_for_view(window: ReportState.ReportWindow, threshold_id: StringName, assignment_revision: int, matching_slices: Array) -> Array:
	var out := []
	for event in window.event_details:
		if threshold_id != &"" and event.subject_id != threshold_id:
			continue
		if assignment_revision > 0 and not _event_matches_assignment_slice(event, assignment_revision, matching_slices):
			continue
		out.append(_event_detail_dict(event))
	return out

func _event_matches_assignment_slice(event: ReportState.ReportEventDetail, assignment_revision: int, matching_slices: Array) -> bool:
	for slice in matching_slices:
		if int(slice.get("assignment_revision", 0)) != assignment_revision:
			continue
		if StringName(str(slice.get("threshold_id", ""))) != event.subject_id:
			continue
		var start_msec := int(slice.get("start_simulation_msec", 0))
		var end_msec := int(slice.get("end_simulation_msec", 0))
		if event.occurred_simulation_msec > start_msec and event.occurred_simulation_msec <= end_msec:
			return true
	return false

func _event_detail_dict(event: ReportState.ReportEventDetail) -> Dictionary:
	return {"event_sequence": event.event_sequence, "event_type": str(event.event_type), "occurred_simulation_msec": event.occurred_simulation_msec, "priority": event.priority, "subject_id": str(event.subject_id), "source_id": str(event.source_id)}

func _event_counts_from_details(event_details: Array) -> Dictionary:
	var out := {}
	for event in event_details:
		var event_type := str(event.event_type)
		out[event_type] = int(out.get(event_type, 0)) + 1
	return out

func _slice_dict(s: ReportState.AttributionSlice) -> Dictionary:
	var channels := {}
	for cid in s.channel_summaries.keys():
		var c: ReportState.ChannelSummary = s.channel_summaries[cid]
		channels[str(cid)] = {"output_item_id": str(c.output_item_id), "banked_units_delta": c.banked_units_delta, "first_progress_subunits_before": c.first_progress_subunits_before, "latest_progress_subunits_after": c.latest_progress_subunits_after, "first_rate_carry_units_before": c.first_rate_carry_units_before, "latest_rate_carry_units_after": c.latest_rate_carry_units_after, "first_total_banked_units_before": c.first_total_banked_units_before, "latest_total_banked_units_after": c.latest_total_banked_units_after}
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
	if rs.live.end_simulation_msec != rs.report_cursor_msec: return {"ok": false}
	return {"ok": true}

static func canonical_slice_key(threshold_id: StringName, assignment_revision: int, lifecycle_state: StringName) -> String:
	return "%s|%d|%s" % [threshold_id, assignment_revision, lifecycle_state]

func _add_map(map: Dictionary, key: StringName, amount: int) -> void:
	if amount != 0: map[key] = int(map.get(key, 0)) + amount

func _add_map_checked(map: Dictionary, key: StringName, amount: int) -> Dictionary:
	if amount == 0:
		return {"ok": true}
	var added := _checked_add(int(map.get(key, 0)), amount, ERR_AGGREGATION_OVERFLOW)
	if not added.ok:
		return added
	map[key] = int(added.value)
	return {"ok": true}

func _checked_add(left: int, right: int, error_code: StringName) -> Dictionary:
	if right > 0 and left > FixedPoint.INT64_MAX - right:
		return _failure(error_code, "int64 positive overflow")
	if right < 0 and left < FixedPoint.INT64_MIN - right:
		return _failure(error_code, "int64 negative overflow")
	return {"ok": true, "value": left + right}

func _failure(code: StringName, details: String) -> Dictionary:
	return {"ok": false, "code": code, "details": details}

func _has_required_keys(value: Dictionary, keys: Array) -> Dictionary:
	for key in keys:
		if not value.has(key):
			return {"ok": false, "key": key}
	return {"ok": true}

func _validated_retinues(value):
	if not (value is Array):
		return null
	var out: Array[StringName] = []
	for id in value:
		if str(id).is_empty():
			return null
		out.append(StringName(str(id)))
	var sorted := out.duplicate()
	sorted.sort()
	return out if out == sorted else null
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
