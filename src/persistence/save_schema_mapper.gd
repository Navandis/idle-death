class_name SaveSchemaMapper
extends RefCounted

## Explicit mapper between M04A runtime objects and primitive save snapshots.
##
## The mapper owns no bytes, files, content Resources, or live state. It writes
## only schema v3, can still read historical v1 through migration callers, and
## converts every authoritative integer to the canonical decimal string required
## at the JSON boundary.

const OK := "OK"
const ERR_SCHEMA := "SAVE_SCHEMA_INVALID"
const ERR_REPORT_RUNTIME := "SAVE_RUNTIME_REPORT_STATE_INVALID"

static func runtime_to_snapshot(game_state: GameState, time_state: TimeAuthorityState, save_revision: int, content_revision: String) -> Dictionary:
	var report_validation: Dictionary = validate_runtime_report_state(game_state)
	if not report_validation.ok: return report_validation
	var has_anchor := time_state.has_anchor()
	return {
		"codec_id": SaveEnvelope.CODEC_JSON_V1,
		"schema_version": SaveInt64.format(SaveEnvelope.CURRENT_SCHEMA_VERSION),
		"save_revision": SaveInt64.format(save_revision),
		"content_revision": content_revision,
		"last_offline_resolution_id": "",
		"metadata": {},
		"game_state": _game_to_v4(game_state),
		"time_authority": {
			"has_trusted_anchor": has_anchor,
			"trusted_anchor_utc_msec": SaveInt64.format(time_state.trusted_anchor_utc_msec if has_anchor else 0),
			"trusted_source_id": time_state.trusted_source_id if has_anchor else "",
			"foreground_credited_since_anchor_msec": SaveInt64.format(time_state.foreground_credited_since_anchor_msec if has_anchor else 0),
			"pending_trusted_reconciliation": time_state.pending_trusted_reconciliation,
			"last_sample_diagnostic_code": time_state.last_sample_diagnostic_code,
		},
	}

static func validate_runtime_report_state(game_state: GameState) -> Dictionary:
	if game_state == null or game_state.report_state == null or not (game_state.report_state is ReportState):
		return _runtime_report_err("game_state.report_state")
	var rs: ReportState = game_state.report_state
	if rs.report_cursor_msec < 0 or rs.report_cursor_msec > game_state.simulation_time_msec:
		return _runtime_report_err("game_state.report_state.report_cursor_msec")
	if rs.next_report_sequence <= 0:
		return _runtime_report_err("game_state.report_state.next_report_sequence")
	if rs.next_event_sequence <= 0:
		return _runtime_report_err("game_state.report_state.next_event_sequence")
	if rs.dropped_history_record_count < 0:
		return _runtime_report_err("game_state.report_state.dropped_history_record_count")
	if rs.history.size() > ReportState.MAX_HISTORY_RECORDS:
		return _runtime_report_err("game_state.report_state.history")
	var live_result := _validate_runtime_report_window(rs.live, "game_state.report_state.live")
	if not live_result.ok: return live_result
	for i in range(rs.history.size()):
		var record = rs.history[i]
		if record == null or not (record is ReportState.ReportRecord):
			return _runtime_report_err("game_state.report_state.history.%d" % i)
		if record.report_sequence <= 0:
			return _runtime_report_err("game_state.report_state.history.%d.report_sequence" % i)
		if not ReportState.VALID_REASONS.has(record.snapshot_reason):
			return _runtime_report_err("game_state.report_state.history.%d.snapshot_reason" % i)
		var window_result := _validate_runtime_report_window(record.window, "game_state.report_state.history.%d.window" % i)
		if not window_result.ok: return window_result
	return {"ok": true, "code": OK}

static func _validate_runtime_report_window(window, path: String) -> Dictionary:
	if window == null or not (window is ReportState.ReportWindow):
		return _runtime_report_err(path)
	if window.start_simulation_msec < 0 or window.end_simulation_msec < 0 or window.end_simulation_msec < window.start_simulation_msec:
		return _runtime_report_err(path)
	if window.run_count < 0 or window.omitted_oldest_event_detail_count < 0:
		return _runtime_report_err(path)
	if window.event_details.size() > ReportState.MAX_EVENT_DETAILS:
		return _runtime_report_err("%s.event_details" % path)
	for key in window.mode_counts.keys():
		if int(window.mode_counts[key]) < 0: return _runtime_report_err("%s.mode_counts.%s" % [path, key])
	for key in window.events_by_type.keys():
		if int(window.events_by_type[key]) < 0: return _runtime_report_err("%s.events_by_type.%s" % [path, key])
	for key in window.slices.keys():
		var slice = window.slices[key]
		if slice == null or not (slice is ReportState.AttributionSlice): return _runtime_report_err("%s.slices.%s" % [path, key])
		if slice.threshold_id == &"" or slice.lifecycle_state == &"" or slice.form_id == &"" or slice.writ_id == &"": return _runtime_report_err("%s.slices.%s" % [path, key])
		if slice.assignment_revision <= 0 or slice.start_simulation_msec < 0 or slice.end_simulation_msec < slice.start_simulation_msec or slice.elapsed_msec < 0 or slice.returned_souls_delta < 0 or slice.completed_cycles_delta < 0:
			return _runtime_report_err("%s.slices.%s" % [path, key])
		for value in slice.inventory_gains.values():
			if int(value) < 0: return _runtime_report_err("%s.slices.%s.inventory_gains" % [path, key])
		for value in slice.mastery_gains.values():
			if int(value) < 0: return _runtime_report_err("%s.slices.%s.mastery_gains" % [path, key])
		for channel_key in slice.channel_summaries.keys():
			var channel = slice.channel_summaries[channel_key]
			if channel == null or not (channel is ReportState.ChannelSummary): return _runtime_report_err("%s.slices.%s.channel_summaries.%s" % [path, key, channel_key])
			if channel.channel_id == &"" or channel.output_item_id == &"": return _runtime_report_err("%s.slices.%s.channel_summaries.%s" % [path, key, channel_key])
			if channel.banked_units_delta < 0 or channel.first_progress_subunits_before < 0 or channel.latest_progress_subunits_after < 0 or channel.first_rate_carry_units_before < 0 or channel.latest_rate_carry_units_after < 0 or channel.first_total_banked_units_before < 0 or channel.latest_total_banked_units_after < 0:
				return _runtime_report_err("%s.slices.%s.channel_summaries.%s" % [path, key, channel_key])
	for i in range(window.event_details.size()):
		var event = window.event_details[i]
		if event == null or not (event is ReportState.ReportEventDetail): return _runtime_report_err("%s.event_details.%d" % [path, i])
		if event.event_sequence <= 0 or event.event_type == &"" or event.occurred_simulation_msec < 0 or event.priority < 0 or event.subject_id == &"":
			return _runtime_report_err("%s.event_details.%d" % [path, i])
	return {"ok": true, "code": OK}

static func _runtime_report_err(field_path: String) -> Dictionary:
	return {"ok": false, "code": ERR_REPORT_RUNTIME, "field_path": field_path}

static func snapshot_to_runtime(snapshot: Dictionary) -> Dictionary:
	var validation := SaveSchemaValidator.validate_current(snapshot)
	if not validation.ok: return validation
	var game := GameState.new(validation.simulation_time_msec)
	var g: Dictionary = snapshot.game_state
	for item_id in _sorted_keys(g.inventory.entries):
		var e: Dictionary = g.inventory.entries[item_id]
		var entry := GameState.InventoryEntryState.new(SaveInt64.parse(e.total, false, "").value)
		for rid in _sorted_keys(e.reservations): entry.reservations[rid] = SaveInt64.parse(e.reservations[rid], false, "").value
		game.inventory.entries[item_id] = entry
	for form_id in _sorted_keys(g.forms):
		var f: Dictionary = g.forms[form_id]
		game.forms[StringName(form_id)] = GameState.FormState.new(f.revealed, f.awakened, SaveInt64.parse(f.mastery_subunits, false, "").value, StringName(f.awakened_by))
	for threshold_id in _sorted_keys(g.thresholds):
		var t: Dictionary = g.thresholds[threshold_id]
		var threshold := GameState.ThresholdState.new()
		threshold.knowledge_state = StringName(t.knowledge_state); threshold.availability_state = StringName(t.availability_state); threshold.lifecycle_state = StringName(t.lifecycle_state)
		threshold.remaining_backlog = SaveInt64.parse(t.remaining_backlog, false, "").value; threshold.persistent_returns_total = SaveInt64.parse(t.persistent_returns_total, false, "").value; threshold.familiarity_subunits = SaveInt64.parse(t.familiarity_subunits, false, "").value
		for cid in _sorted_keys(t.channel_acquisition):
			var a: Dictionary = t.channel_acquisition[cid]
			threshold.channel_acquisition[StringName(cid)] = GameState.ThresholdAcquisitionState.new(SaveInt64.parse(a.progress_subunits, false, "").value, SaveInt64.parse(a.rate_carry_units, false, "").value, SaveInt64.parse(a.total_banked_units, false, "").value)
		game.thresholds[StringName(threshold_id)] = threshold
	for reaping_id in _sorted_keys(g.reapings):
		var r: Dictionary = g.reapings[reaping_id]
		var reaping := GameState.ReapingState.new()
		reaping.threshold_id = StringName(r.threshold_id); reaping.is_active = r.is_active; reaping.form_id = StringName(r.form_id); reaping.writ_id = StringName(r.writ_id)
		for retinue_id in r.retinue_ids: reaping.retinue_ids.append(StringName(retinue_id))
		reaping.assignment_revision = SaveInt64.parse(r.assignment_revision, false, "").value; reaping.cycle_phase_msec = SaveInt64.parse(r.cycle_phase_msec, false, "").value; reaping.completed_cycle_count = SaveInt64.parse(r.completed_cycle_count, false, "").value
		for flow in _sorted_keys(r.flow_carry_units): reaping.flow_carry_units[flow] = SaveInt64.parse(r.flow_carry_units[flow], false, "").value
		reaping.started_simulation_msec = SaveInt64.parse(r.started_simulation_msec, false, "").value; reaping.last_configuration_change_simulation_msec = SaveInt64.parse(r.last_configuration_change_simulation_msec, false, "").value
		game.reapings[StringName(reaping_id)] = reaping
	game.progression.command_tether_capacity = validation.command_tether_capacity
	for item_id in validation.get("unlocked_output_item_ids", []):
		game.progression.unlocked_output_item_ids.append(StringName(item_id))
	game.progression.unlocked_output_item_ids.sort()
	if g.has("report_state"):
		game.report_state = _report_from_snapshot(g.report_state)
	else:
		game.report_state = ReportState.new(game.simulation_time_msec)
	var time := _map_time(snapshot.time_authority, validation)
	return {"ok": true, "code": OK, "game_state": game, "time_authority_state": time, "save_revision": validation.save_revision, "content_revision": snapshot.content_revision}

static func _game_to_v4(game_state: GameState) -> Dictionary:
	var data := _game_to_v2(game_state)
	data["report_state"] = _report_to_snapshot(game_state.report_state)
	return data

static func _game_to_v2(game_state: GameState) -> Dictionary:
	return {
		"simulation_time_msec": SaveInt64.format(game_state.simulation_time_msec),
		"inventory": _inventory_to_snapshot(game_state.inventory),
		"forms": _forms_to_snapshot(game_state.forms),
		"thresholds": _thresholds_to_snapshot(game_state.thresholds),
		"reapings": _reapings_to_snapshot(game_state.reapings),
		"progression": _progression_to_snapshot(game_state.progression),
	}

static func _report_to_snapshot(rs: ReportState) -> Dictionary:
	return {"report_cursor_msec": SaveInt64.format(rs.report_cursor_msec), "next_report_sequence": SaveInt64.format(rs.next_report_sequence), "next_event_sequence": SaveInt64.format(rs.next_event_sequence), "dropped_history_record_count": SaveInt64.format(rs.dropped_history_record_count), "live": _report_window_to_snapshot(rs.live), "history": _report_history_to_snapshot(rs.history)}

static func _report_history_to_snapshot(history: Array) -> Array:
	var out := []
	for record in history:
		out.append({"report_sequence": SaveInt64.format(record.report_sequence), "snapshot_reason": str(record.snapshot_reason), "window": _report_window_to_snapshot(record.window)})
	return out

static func _report_window_to_snapshot(w: ReportState.ReportWindow) -> Dictionary:
	var slices := {}
	for key in _sorted_keys(w.slices):
		var s = w.slices[key]; var channels := {}
		for cid in _sorted_keys(s.channel_summaries):
			var c = s.channel_summaries[cid]
			channels[str(cid)] = {"channel_id": str(c.channel_id), "output_item_id": str(c.output_item_id), "banked_units_delta": SaveInt64.format(c.banked_units_delta), "first_progress_subunits_before": SaveInt64.format(c.first_progress_subunits_before), "latest_progress_subunits_after": SaveInt64.format(c.latest_progress_subunits_after), "first_rate_carry_units_before": SaveInt64.format(c.first_rate_carry_units_before), "latest_rate_carry_units_after": SaveInt64.format(c.latest_rate_carry_units_after), "first_total_banked_units_before": SaveInt64.format(c.first_total_banked_units_before), "latest_total_banked_units_after": SaveInt64.format(c.latest_total_banked_units_after)}
		slices[str(key)] = {"threshold_id": str(s.threshold_id), "assignment_revision": SaveInt64.format(s.assignment_revision), "lifecycle_state": str(s.lifecycle_state), "form_id": str(s.form_id), "writ_id": str(s.writ_id), "retinue_ids": _string_array(s.retinue_ids), "start_simulation_msec": SaveInt64.format(s.start_simulation_msec), "end_simulation_msec": SaveInt64.format(s.end_simulation_msec), "elapsed_msec": SaveInt64.format(s.elapsed_msec), "returned_souls_delta": SaveInt64.format(s.returned_souls_delta), "backlog_delta": SaveInt64.format(s.backlog_delta), "completed_cycles_delta": SaveInt64.format(s.completed_cycles_delta), "inventory_gains": _int_map(s.inventory_gains), "mastery_gains": _int_map(s.mastery_gains), "channel_summaries": channels}
	var events := []
	for e in w.event_details:
		events.append({"event_sequence": SaveInt64.format(e.event_sequence), "event_type": str(e.event_type), "occurred_simulation_msec": SaveInt64.format(e.occurred_simulation_msec), "priority": SaveInt64.format(e.priority), "subject_id": str(e.subject_id), "source_id": str(e.source_id)})
	return {"start_simulation_msec": SaveInt64.format(w.start_simulation_msec), "end_simulation_msec": SaveInt64.format(w.end_simulation_msec), "run_count": SaveInt64.format(w.run_count), "mode_counts": _int_map(w.mode_counts), "slices": slices, "events_by_type": _int_map(w.events_by_type), "event_details": events, "omitted_oldest_event_detail_count": SaveInt64.format(w.omitted_oldest_event_detail_count)}

static func _report_from_snapshot(data: Dictionary) -> ReportState:
	var rs := ReportState.new(SaveInt64.parse(data.report_cursor_msec, false, "").value)
	rs.next_report_sequence = SaveInt64.parse(data.next_report_sequence, false, "").value; rs.next_event_sequence = SaveInt64.parse(data.next_event_sequence, false, "").value; rs.dropped_history_record_count = SaveInt64.parse(data.dropped_history_record_count, false, "").value
	rs.live = _report_window_from_snapshot(data.live)
	rs.history.clear()
	for rec in data.history:
		var r := ReportState.ReportRecord.new(); r.report_sequence = SaveInt64.parse(rec.report_sequence, false, "").value; r.snapshot_reason = StringName(rec.snapshot_reason); r.window = _report_window_from_snapshot(rec.window); rs.history.append(r)
	return rs

static func _report_window_from_snapshot(w: Dictionary) -> ReportState.ReportWindow:
	var out := ReportState.ReportWindow.new(); out.start_simulation_msec = SaveInt64.parse(w.start_simulation_msec, false, "").value; out.end_simulation_msec = SaveInt64.parse(w.end_simulation_msec, false, "").value; out.run_count = SaveInt64.parse(w.run_count, false, "").value
	for k in w.mode_counts: out.mode_counts[k] = SaveInt64.parse(w.mode_counts[k], false, "").value
	for k in w.events_by_type: out.events_by_type[k] = SaveInt64.parse(w.events_by_type[k], false, "").value
	out.omitted_oldest_event_detail_count = SaveInt64.parse(w.omitted_oldest_event_detail_count, false, "").value
	for key in w.slices:
		var d = w.slices[key]; var s := ReportState.AttributionSlice.new(); s.threshold_id = StringName(d.threshold_id); s.assignment_revision = SaveInt64.parse(d.assignment_revision, false, "").value; s.lifecycle_state = StringName(d.lifecycle_state); s.form_id = StringName(d.form_id); s.writ_id = StringName(d.writ_id)
		for id in d.retinue_ids: s.retinue_ids.append(StringName(id))
		s.start_simulation_msec = SaveInt64.parse(d.start_simulation_msec, false, "").value; s.end_simulation_msec = SaveInt64.parse(d.end_simulation_msec, false, "").value; s.elapsed_msec = SaveInt64.parse(d.elapsed_msec, false, "").value; s.returned_souls_delta = SaveInt64.parse(d.returned_souls_delta, false, "").value; s.backlog_delta = SaveInt64.parse(d.backlog_delta, true, "").value; s.completed_cycles_delta = SaveInt64.parse(d.completed_cycles_delta, false, "").value
		for ik in d.inventory_gains: s.inventory_gains[StringName(ik)] = SaveInt64.parse(d.inventory_gains[ik], false, "").value
		for mk in d.mastery_gains: s.mastery_gains[StringName(mk)] = SaveInt64.parse(d.mastery_gains[mk], false, "").value
		for cid in d.channel_summaries:
			var cd = d.channel_summaries[cid]; var c := ReportState.ChannelSummary.new(); c.channel_id = StringName(cd.channel_id); c.output_item_id = StringName(cd.output_item_id); c.banked_units_delta = SaveInt64.parse(cd.banked_units_delta, false, "").value; c.first_progress_subunits_before = SaveInt64.parse(cd.first_progress_subunits_before, false, "").value; c.latest_progress_subunits_after = SaveInt64.parse(cd.latest_progress_subunits_after, false, "").value; c.first_rate_carry_units_before = SaveInt64.parse(cd.first_rate_carry_units_before, false, "").value; c.latest_rate_carry_units_after = SaveInt64.parse(cd.latest_rate_carry_units_after, false, "").value; c.first_total_banked_units_before = SaveInt64.parse(cd.first_total_banked_units_before, false, "").value; c.latest_total_banked_units_after = SaveInt64.parse(cd.latest_total_banked_units_after, false, "").value; s.channel_summaries[StringName(cid)] = c
		out.slices[key] = s
	for ed in w.event_details:
		var e := ReportState.ReportEventDetail.new(); e.event_sequence = SaveInt64.parse(ed.event_sequence, false, "").value; e.event_type = StringName(ed.event_type); e.occurred_simulation_msec = SaveInt64.parse(ed.occurred_simulation_msec, false, "").value; e.priority = SaveInt64.parse(ed.priority, false, "").value; e.subject_id = StringName(ed.subject_id); e.source_id = StringName(ed.source_id); out.event_details.append(e)
	return out

static func _int_map(map: Dictionary) -> Dictionary:
	var out := {}
	for k in _sorted_keys(map): out[str(k)] = SaveInt64.format(map[k])
	return out
static func _string_array(values: Array[StringName]) -> Array:
	var out := []
	for v in values: out.append(str(v))
	out.sort(); return out

static func _progression_to_snapshot(progression: GameState.ProgressionState) -> Dictionary:
	var unlocked := []
	for item_id in progression.unlocked_output_item_ids:
		unlocked.append(str(item_id))
	unlocked.sort()
	return {"command_tether_capacity": SaveInt64.format(progression.command_tether_capacity), "unlocked_output_item_ids": unlocked}

static func _inventory_to_snapshot(inv) -> Dictionary:
	var entries := {}
	for id in _sorted_keys(inv.entries):
		var e = inv.entries[id]
		var reservations := {}
		for rid in _sorted_keys(e.reservations):
			reservations[str(rid)] = SaveInt64.format(e.reservations[rid])
		entries[str(id)] = {"total": SaveInt64.format(e.total), "reservations": reservations}
	return {"entries": entries}

static func _forms_to_snapshot(forms: Dictionary) -> Dictionary:
	var out := {}
	for id in _sorted_keys(forms):
		var f = forms[id]
		out[str(id)] = {"revealed": f.revealed, "awakened": f.awakened, "mastery_subunits": SaveInt64.format(f.mastery_subunits), "awakened_by": str(f.awakened_by)}
	return out

static func _thresholds_to_snapshot(thresholds: Dictionary) -> Dictionary:
	var out := {}
	for id in _sorted_keys(thresholds):
		var t = thresholds[id]
		var acq := {}
		for cid in _sorted_keys(t.channel_acquisition):
			var a = t.channel_acquisition[cid]
			acq[str(cid)] = {"progress_subunits": SaveInt64.format(a.progress_subunits), "rate_carry_units": SaveInt64.format(a.rate_carry_units), "total_banked_units": SaveInt64.format(a.total_banked_units)}
		out[str(id)] = {"knowledge_state": str(t.knowledge_state), "availability_state": str(t.availability_state), "lifecycle_state": str(t.lifecycle_state), "remaining_backlog": SaveInt64.format(t.remaining_backlog), "persistent_returns_total": SaveInt64.format(t.persistent_returns_total), "familiarity_subunits": SaveInt64.format(t.familiarity_subunits), "channel_acquisition": acq}
	return out

static func _reapings_to_snapshot(reapings: Dictionary) -> Dictionary:
	var out := {}
	for id in _sorted_keys(reapings):
		var r = reapings[id]
		var retinues := []
		for retinue in r.retinue_ids:
			retinues.append(str(retinue))
		var carries := {}
		for flow in _sorted_keys(r.flow_carry_units):
			carries[str(flow)] = SaveInt64.format(r.flow_carry_units[flow])
		out[str(id)] = {"threshold_id": str(r.threshold_id), "is_active": r.is_active, "form_id": str(r.form_id), "writ_id": str(r.writ_id), "retinue_ids": retinues, "assignment_revision": SaveInt64.format(r.assignment_revision), "cycle_phase_msec": SaveInt64.format(r.cycle_phase_msec), "completed_cycle_count": SaveInt64.format(r.completed_cycle_count), "flow_carry_units": carries, "started_simulation_msec": SaveInt64.format(r.started_simulation_msec), "last_configuration_change_simulation_msec": SaveInt64.format(r.last_configuration_change_simulation_msec)}
	return out

static func _map_time(t: Dictionary, validation: Dictionary) -> TimeAuthorityState:
	var time := TimeAuthorityState.new()
	if t.has_trusted_anchor:
		time.trusted_anchor_utc_msec = validation.trusted_anchor_utc_msec; time.trusted_source_id = t.trusted_source_id; time.foreground_credited_since_anchor_msec = validation.foreground_credited_since_anchor_msec
	time.pending_trusted_reconciliation = t.pending_trusted_reconciliation; time.last_sample_diagnostic_code = t.last_sample_diagnostic_code
	return time
static func _sorted_keys(dict: Dictionary) -> Array:
	var keys := dict.keys(); keys.sort(); return keys
