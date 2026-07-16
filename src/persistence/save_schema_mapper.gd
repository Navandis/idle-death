class_name SaveSchemaMapper
extends RefCounted

## Explicit mapper between M04A runtime objects and primitive save snapshots.
##
## The mapper owns no bytes, files, content Resources, or live state. It writes
## only schema v2, can still read historical v1 through migration callers, and
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
	var validation := SaveSchemaValidator.validate_v2(snapshot)
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
	var time := _map_time(snapshot.time_authority, validation)
	return {"ok": true, "code": OK, "game_state": game, "time_authority_state": time, "save_revision": validation.save_revision, "content_revision": snapshot.content_revision}

static func _game_to_v2(game_state: GameState) -> Dictionary:
	return {
		"simulation_time_msec": SaveInt64.format(game_state.simulation_time_msec),
		"inventory": _inventory_to_snapshot(game_state.inventory),
		"forms": _forms_to_snapshot(game_state.forms),
		"thresholds": _thresholds_to_snapshot(game_state.thresholds),
		"reapings": _reapings_to_snapshot(game_state.reapings),
		"progression": {"command_tether_capacity": SaveInt64.format(game_state.progression.command_tether_capacity)},
	}

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
