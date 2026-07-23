class_name SaveSchemaMapper
extends RefCounted

## Explicit mapper between M04A runtime objects and primitive save snapshots.
##
## The mapper owns no bytes, files, content Resources, or live state. It writes
## only the current schema, can still read historical v1-v3 through migration callers, and
## converts every authoritative integer to the canonical decimal string required
## at the JSON boundary.

const OK := "OK"
const ERR_SCHEMA := "SAVE_SCHEMA_INVALID"

static func runtime_to_snapshot(game_state: GameState, time_state: TimeAuthorityState, save_revision: int, content_revision: String) -> Dictionary:
	var has_anchor := time_state.has_anchor()
	return {
		"codec_id": SaveEnvelope.CODEC_JSON_V1,
		"schema_version": SaveInt64.format(SaveEnvelope.CURRENT_SCHEMA_VERSION),
		"save_revision": SaveInt64.format(save_revision),
		"content_revision": content_revision,
		"last_offline_resolution_id": "",
		"metadata": {},
		"game_state": _game_to_v2(game_state),
		"time_authority": {
			"has_trusted_anchor": has_anchor,
			"trusted_anchor_utc_msec": SaveInt64.format(time_state.trusted_anchor_utc_msec if has_anchor else 0),
			"trusted_source_id": time_state.trusted_source_id if has_anchor else "",
			"foreground_credited_since_anchor_msec": SaveInt64.format(time_state.foreground_credited_since_anchor_msec if has_anchor else 0),
			"pending_trusted_reconciliation": time_state.pending_trusted_reconciliation,
			"last_sample_diagnostic_code": time_state.last_sample_diagnostic_code,
		},
	}

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
	game.report_state = _report_state_from_snapshot(g.report_state) if g.has("report_state") else ReportState.empty_at_cursor(validation.simulation_time_msec)
	var time := _map_time(snapshot.time_authority, validation)
	return {"ok": true, "code": OK, "game_state": game, "time_authority_state": time, "save_revision": validation.save_revision, "content_revision": snapshot.content_revision}

static func _game_to_v2(game_state: GameState) -> Dictionary:
	return {
		"simulation_time_msec": SaveInt64.format(game_state.simulation_time_msec),
		"inventory": _inventory_to_snapshot(game_state.inventory),
		"forms": _forms_to_snapshot(game_state.forms),
		"thresholds": _thresholds_to_snapshot(game_state.thresholds),
		"reapings": _reapings_to_snapshot(game_state.reapings),
		"progression": _progression_to_snapshot(game_state.progression),
		"report_state": _report_state_to_snapshot(game_state.report_state),
	}

static func _report_state_to_snapshot(report_state: ReportState) -> Dictionary:
	var history := []
	for record in report_state.history:
		history.append(_report_record_to_snapshot(record))
	return {
		"ingested_through_simulation_msec": SaveInt64.format(report_state.ingested_through_simulation_msec),
		"next_report_sequence": SaveInt64.format(report_state.next_report_sequence),
		"next_event_sequence": SaveInt64.format(report_state.next_event_sequence),
		"dropped_history_count": SaveInt64.format(report_state.dropped_history_count),
		"live": _report_accumulator_to_snapshot(report_state.live),
		"history": history,
	}

static func _report_accumulator_to_snapshot(accumulator: ReportAccumulatorState) -> Dictionary:
	var modes := {}
	for key in _sorted_keys(accumulator.committed_mode_counts): modes[str(key)] = SaveInt64.format(accumulator.committed_mode_counts[key])
	var slices := {}
	for key in _sorted_keys(accumulator.attribution_slices): slices[str(key)] = _report_slice_to_snapshot(accumulator.attribution_slices[key])
	var event_counts := {}
	for key in _sorted_keys(accumulator.event_type_counts): event_counts[str(key)] = SaveInt64.format(accumulator.event_type_counts[key])
	var events := []
	for event in accumulator.recent_events: events.append(_report_event_to_snapshot(event))
	return {
		"window_started_simulation_msec": SaveInt64.format(accumulator.window_started_simulation_msec),
		"window_ended_simulation_msec": SaveInt64.format(accumulator.window_ended_simulation_msec),
		"ingested_run_count": SaveInt64.format(accumulator.ingested_run_count),
		"committed_mode_counts": modes,
		"attribution_slices": slices,
		"event_type_counts": event_counts,
		"recent_events": events,
		"omitted_event_count": SaveInt64.format(accumulator.omitted_event_count),
	}

static func _report_record_to_snapshot(record: ReportRecord) -> Dictionary:
	return {"report_sequence": SaveInt64.format(record.report_sequence), "snapshot_reason": str(record.snapshot_reason), "snapshot_simulation_msec": SaveInt64.format(record.snapshot_simulation_msec), "window": _report_accumulator_to_snapshot(record.window)}

static func _report_slice_to_snapshot(slice: ReportAttributionSlice) -> Dictionary:
	var inventory := {}; for key in _sorted_keys(slice.inventory_gains_by_item_id): inventory[str(key)] = SaveInt64.format(slice.inventory_gains_by_item_id[key])
	var mastery := {}; for key in _sorted_keys(slice.mastery_gains_subunits_by_form_id): mastery[str(key)] = SaveInt64.format(slice.mastery_gains_subunits_by_form_id[key])
	var channels := {}; for key in _sorted_keys(slice.channel_summaries_by_channel_id): channels[str(key)] = _report_channel_to_snapshot(slice.channel_summaries_by_channel_id[key])
	return {
		"threshold_id": str(slice.threshold_id), "assignment_revision": SaveInt64.format(slice.assignment_revision), "lifecycle_state": str(slice.lifecycle_state),
		"loadout_identity": {"form_id": str(slice.loadout_identity.form_id), "writ_id": str(slice.loadout_identity.writ_id), "ordered_retinue_ids": _string_array(slice.loadout_identity.ordered_retinue_ids)},
		"window_started_simulation_msec": SaveInt64.format(slice.window_started_simulation_msec), "window_ended_simulation_msec": SaveInt64.format(slice.window_ended_simulation_msec), "elapsed_msec": SaveInt64.format(slice.elapsed_msec),
		"returned_souls_delta": SaveInt64.format(slice.returned_souls_delta), "backlog_reduced": SaveInt64.format(slice.backlog_reduced), "completed_cycles_delta": SaveInt64.format(slice.completed_cycles_delta),
		"inventory_gains_by_item_id": inventory, "mastery_gains_subunits_by_form_id": mastery, "channel_summaries_by_channel_id": channels,
	}

static func _report_channel_to_snapshot(channel: ReportChannelSummary) -> Dictionary:
	return {"threshold_id": str(channel.threshold_id), "channel_id": str(channel.channel_id), "output_item_id": str(channel.output_item_id), "elapsed_msec": SaveInt64.format(channel.elapsed_msec), "banked_units_delta": SaveInt64.format(channel.banked_units_delta), "progress_subunits_start": SaveInt64.format(channel.progress_subunits_start), "progress_subunits_end": SaveInt64.format(channel.progress_subunits_end), "rate_carry_units_start": SaveInt64.format(channel.rate_carry_units_start), "rate_carry_units_end": SaveInt64.format(channel.rate_carry_units_end), "total_banked_units_start": SaveInt64.format(channel.total_banked_units_start), "total_banked_units_end": SaveInt64.format(channel.total_banked_units_end)}

static func _report_event_to_snapshot(event: ReportEventRecord) -> Dictionary:
	return {"event_sequence": SaveInt64.format(event.event_sequence), "event_type": str(event.event_type), "occurred_simulation_msec": SaveInt64.format(event.occurred_simulation_msec), "priority": SaveInt64.format(event.priority), "subject_id": str(event.subject_id), "source_id": str(event.source_id)}

static func _report_state_from_snapshot(data: Dictionary) -> ReportState:
	var state := ReportState.new(SaveInt64.parse(data.ingested_through_simulation_msec, false, "").value)
	state.next_report_sequence = SaveInt64.parse(data.next_report_sequence, false, "").value
	state.next_event_sequence = SaveInt64.parse(data.next_event_sequence, false, "").value
	state.dropped_history_count = SaveInt64.parse(data.dropped_history_count, false, "").value
	state.live = _report_accumulator_from_snapshot(data.live)
	for record_data in data.history: state.history.append(_report_record_from_snapshot(record_data))
	return state

static func _report_accumulator_from_snapshot(data: Dictionary) -> ReportAccumulatorState:
	var accumulator := ReportAccumulatorState.new(SaveInt64.parse(data.window_ended_simulation_msec, false, "").value)
	accumulator.window_started_simulation_msec = SaveInt64.parse(data.window_started_simulation_msec, false, "").value
	accumulator.ingested_run_count = SaveInt64.parse(data.ingested_run_count, false, "").value
	accumulator.omitted_event_count = SaveInt64.parse(data.omitted_event_count, false, "").value
	for key in _sorted_keys(data.committed_mode_counts): accumulator.committed_mode_counts[StringName(key)] = SaveInt64.parse(data.committed_mode_counts[key], false, "").value
	for key in _sorted_keys(data.attribution_slices): accumulator.attribution_slices[key] = _report_slice_from_snapshot(data.attribution_slices[key])
	for key in _sorted_keys(data.event_type_counts): accumulator.event_type_counts[StringName(key)] = SaveInt64.parse(data.event_type_counts[key], false, "").value
	for event_data in data.recent_events: accumulator.recent_events.append(_report_event_from_snapshot(event_data))
	return accumulator

static func _report_record_from_snapshot(data: Dictionary) -> ReportRecord:
	return ReportRecord.new(SaveInt64.parse(data.report_sequence, false, "").value, StringName(data.snapshot_reason), SaveInt64.parse(data.snapshot_simulation_msec, false, "").value, _report_accumulator_from_snapshot(data.window))

static func _report_slice_from_snapshot(data: Dictionary) -> ReportAttributionSlice:
	var identity_data: Dictionary = data.loadout_identity
	var retinues: Array[StringName] = []; for retinue_id in identity_data.ordered_retinue_ids: retinues.append(StringName(retinue_id))
	var slice := ReportAttributionSlice.new(StringName(data.threshold_id), SaveInt64.parse(data.assignment_revision, false, "").value, StringName(data.lifecycle_state), ReportLoadoutIdentity.new(StringName(identity_data.form_id), StringName(identity_data.writ_id), retinues), SaveInt64.parse(data.window_started_simulation_msec, false, "").value, SaveInt64.parse(data.window_ended_simulation_msec, false, "").value, SaveInt64.parse(data.elapsed_msec, false, "").value, SaveInt64.parse(data.returned_souls_delta, false, "").value, SaveInt64.parse(data.backlog_reduced, false, "").value, SaveInt64.parse(data.completed_cycles_delta, false, "").value)
	for key in _sorted_keys(data.inventory_gains_by_item_id): slice.inventory_gains_by_item_id[StringName(key)] = SaveInt64.parse(data.inventory_gains_by_item_id[key], false, "").value
	for key in _sorted_keys(data.mastery_gains_subunits_by_form_id): slice.mastery_gains_subunits_by_form_id[StringName(key)] = SaveInt64.parse(data.mastery_gains_subunits_by_form_id[key], false, "").value
	for key in _sorted_keys(data.channel_summaries_by_channel_id): slice.channel_summaries_by_channel_id[StringName(key)] = _report_channel_from_snapshot(data.channel_summaries_by_channel_id[key])
	return slice

static func _report_channel_from_snapshot(data: Dictionary) -> ReportChannelSummary:
	return ReportChannelSummary.new(StringName(data.threshold_id), StringName(data.channel_id), StringName(data.output_item_id), SaveInt64.parse(data.elapsed_msec, false, "").value, SaveInt64.parse(data.banked_units_delta, false, "").value, SaveInt64.parse(data.progress_subunits_start, false, "").value, SaveInt64.parse(data.progress_subunits_end, false, "").value, SaveInt64.parse(data.rate_carry_units_start, false, "").value, SaveInt64.parse(data.rate_carry_units_end, false, "").value, SaveInt64.parse(data.total_banked_units_start, false, "").value, SaveInt64.parse(data.total_banked_units_end, false, "").value)

static func _report_event_from_snapshot(data: Dictionary) -> ReportEventRecord:
	return ReportEventRecord.new(SaveInt64.parse(data.event_sequence, false, "").value, StringName(data.event_type), SaveInt64.parse(data.occurred_simulation_msec, false, "").value, SaveInt64.parse(data.priority, false, "").value, StringName(data.subject_id), StringName(data.source_id))

static func _string_array(values: Array[StringName]) -> Array[String]:
	var out: Array[String] = []
	for value in values:
		out.append(str(value))
	return out

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
