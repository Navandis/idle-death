class_name SaveSchemaValidator
extends RefCounted

## Validates primitive schema dictionaries before runtime construction or commit.
##
## Validation deliberately happens outside the byte codec.  The codec proves that
## bytes are JSON and primitive values; this class proves those primitives match
## Death Idle's schema, integer-string rules, and cross-field invariants.

const OK := "OK"
const ERR_NOT_DICTIONARY := "SAVE_SCHEMA_NOT_DICTIONARY"
const ERR_KEY_SET := "SAVE_SCHEMA_KEY_SET"
const ERR_CODEC := "SAVE_SCHEMA_UNSUPPORTED_CODEC"
const ERR_SCHEMA_VERSION := "SAVE_SCHEMA_UNSUPPORTED_VERSION"
const ERR_CONTENT_REVISION := "SAVE_SCHEMA_CONTENT_REVISION"
const ERR_TYPE := "SAVE_SCHEMA_TYPE"
const ERR_CROSS_FIELD := "SAVE_SCHEMA_CROSS_FIELD"
const ERR_RANGE := "SAVE_SCHEMA_RANGE"
const ERR_ABSOLUTE_PATH := "SAVE_SCHEMA_ABSOLUTE_PATH"

static func validate_v1(snapshot: Variant) -> Dictionary:
	if typeof(snapshot) != TYPE_DICTIONARY:
		return _err(ERR_NOT_DICTIONARY, "")
	var data: Dictionary = snapshot
	var keys_result := _require_keys(data, SaveEnvelope.TOP_LEVEL_KEYS, "")
	if not keys_result.ok:
		return keys_result
	if data.codec_id != SaveEnvelope.CODEC_JSON_V1:
		return _err(ERR_CODEC, "codec_id")
	var schema := SaveInt64.parse(data.schema_version, false, "schema_version")
	if not schema.ok:
		return schema
	if schema.value != SaveEnvelope.SCHEMA_VERSION_V1:
		return _err(ERR_SCHEMA_VERSION, "schema_version")
	var revision := SaveInt64.parse(data.save_revision, false, "save_revision")
	if not revision.ok:
		return revision
	if typeof(data.content_revision) != TYPE_STRING or (data.content_revision as String).is_empty():
		return _err(ERR_CONTENT_REVISION, "content_revision")
	if _looks_like_absolute_path(data.content_revision):
		return _err(ERR_ABSOLUTE_PATH, "content_revision")
	if typeof(data.last_offline_resolution_id) != TYPE_STRING or _looks_like_absolute_path(data.last_offline_resolution_id):
		return _err(ERR_TYPE, "last_offline_resolution_id")
	if typeof(data.metadata) != TYPE_DICTIONARY:
		return _err(ERR_TYPE, "metadata")
	if typeof(data.game_state) != TYPE_DICTIONARY:
		return _err(ERR_TYPE, "game_state")
	var game_keys := _require_keys(data.game_state, SaveEnvelope.GAME_KEYS_V1, "game_state")
	if not game_keys.ok:
		return game_keys
	var sim := SaveInt64.parse(data.game_state.simulation_time_msec, false, "game_state.simulation_time_msec")
	if not sim.ok:
		return sim
	if typeof(data.time_authority) != TYPE_DICTIONARY:
		return _err(ERR_TYPE, "time_authority")
	var time_keys := _require_keys(data.time_authority, SaveEnvelope.TIME_AUTHORITY_KEYS, "time_authority")
	if not time_keys.ok:
		return time_keys
	var t: Dictionary = data.time_authority
	if typeof(t.has_trusted_anchor) != TYPE_BOOL or typeof(t.trusted_source_id) != TYPE_STRING or typeof(t.pending_trusted_reconciliation) != TYPE_BOOL or typeof(t.last_sample_diagnostic_code) != TYPE_STRING:
		return _err(ERR_TYPE, "time_authority")
	if t.last_sample_diagnostic_code.is_empty() or _looks_like_absolute_path(t.last_sample_diagnostic_code):
		return _err(ERR_TYPE, "time_authority.last_sample_diagnostic_code")
	var anchor := SaveInt64.parse(t.trusted_anchor_utc_msec, false, "time_authority.trusted_anchor_utc_msec")
	if not anchor.ok:
		return anchor
	var foreground := SaveInt64.parse(t.foreground_credited_since_anchor_msec, false, "time_authority.foreground_credited_since_anchor_msec")
	if not foreground.ok:
		return foreground
	if t.has_trusted_anchor:
		if t.trusted_source_id.is_empty():
			return _err(ERR_CROSS_FIELD, "time_authority.trusted_source_id")
	else:
		if anchor.value != 0 or foreground.value != 0 or not t.trusted_source_id.is_empty():
			return _err(ERR_CROSS_FIELD, "time_authority")
	return {"ok": true, "code": OK, "save_revision": revision.value, "simulation_time_msec": sim.value, "trusted_anchor_utc_msec": anchor.value, "foreground_credited_since_anchor_msec": foreground.value}


static func _require_keys(data: Dictionary, expected: Array, field_path: String) -> Dictionary:
	var actual := data.keys()
	actual.sort()
	var sorted_expected := expected.duplicate()
	sorted_expected.sort()
	if actual != sorted_expected:
		return _err(ERR_KEY_SET, field_path)
	return {"ok": true, "code": OK}


static func _looks_like_absolute_path(value: String) -> bool:
	return value.begins_with("/") or value.begins_with("\\") or (value.length() >= 3 and value[1] == ":" and (value[2] == "\\" or value[2] == "/"))


static func _err(code: String, field_path: String) -> Dictionary:
	return {"ok": false, "code": code, "field_path": field_path}


static func validate_current(snapshot: Variant) -> Dictionary:
	var version := get_schema_version(snapshot)
	if not version.ok:
		return version
	if version.value == SaveEnvelope.SCHEMA_VERSION_V1:
		return validate_v1(snapshot)
	if version.value == SaveEnvelope.SCHEMA_VERSION_V2:
		return validate_v2(snapshot)
	if version.value == SaveEnvelope.SCHEMA_VERSION_V3:
		return validate_v3(snapshot)
	if version.value == SaveEnvelope.SCHEMA_VERSION_V4:
		return validate_v4(snapshot)
	return _err(ERR_SCHEMA_VERSION, "schema_version")


static func get_schema_version(snapshot: Variant) -> Dictionary:
	if typeof(snapshot) != TYPE_DICTIONARY:
		return _err(ERR_NOT_DICTIONARY, "")
	return SaveInt64.parse((snapshot as Dictionary).get("schema_version", ""), false, "schema_version")


static func validate_v4(snapshot: Variant) -> Dictionary:
	var base := _validate_v2_or_v3(snapshot, SaveEnvelope.SCHEMA_VERSION_V4, ["command_tether_capacity", "unlocked_output_item_ids"], SaveEnvelope.GAME_KEYS_V4)
	if not base.ok: return base
	var rs = (snapshot as Dictionary).game_state.report_state
	if typeof(rs) != TYPE_DICTIONARY: return _err(ERR_TYPE, "game_state.report_state")
	var k := _require_keys(rs, ["dropped_history_record_count", "history", "live", "next_event_sequence", "next_report_sequence", "report_cursor_msec"], "game_state.report_state"); if not k.ok: return k
	for ik in ["report_cursor_msec", "next_report_sequence", "next_event_sequence", "dropped_history_record_count"]:
		var pi := SaveInt64.parse(rs[ik], false, "game_state.report_state.%s" % ik); if not pi.ok: return pi
	for sequence_key in ["next_report_sequence", "next_event_sequence"]:
		var sequence_value := SaveInt64.parse(rs[sequence_key], false, "game_state.report_state.%s" % sequence_key)
		if not sequence_value.ok: return sequence_value
		if sequence_value.value <= 0: return _err(ERR_RANGE, "game_state.report_state.%s" % sequence_key)
	var report_cursor := SaveInt64.parse(rs.report_cursor_msec, false, "game_state.report_state.report_cursor_msec")
	if not report_cursor.ok: return report_cursor
	if report_cursor.value > base.simulation_time_msec: return _err(ERR_CROSS_FIELD, "game_state.report_state.report_cursor_msec")
	if typeof(rs.history) != TYPE_ARRAY: return _err(ERR_TYPE, "game_state.report_state.history")
	if rs.history.size() > ReportState.MAX_HISTORY_RECORDS: return _err(ERR_RANGE, "game_state.report_state.history")
	var lw := _validate_report_window(rs.live, "game_state.report_state.live"); if not lw.ok: return lw
	for i in range(rs.history.size()):
		if typeof(rs.history[i]) != TYPE_DICTIONARY: return _err(ERR_TYPE, "game_state.report_state.history.%d" % i)
		var rk := _require_keys(rs.history[i], ["report_sequence", "snapshot_reason", "window"], "game_state.report_state.history.%d" % i); if not rk.ok: return rk
		var seq := SaveInt64.parse(rs.history[i].report_sequence, false, "game_state.report_state.history.%d.report_sequence" % i); if not seq.ok: return seq
		if typeof(rs.history[i].snapshot_reason) != TYPE_STRING: return _err(ERR_TYPE, "game_state.report_state.history.%d.snapshot_reason" % i)
		if not ReportState.VALID_REASONS.has(StringName(rs.history[i].snapshot_reason)): return _err(ERR_RANGE, "game_state.report_state.history.%d.snapshot_reason" % i)
		var hw := _validate_report_window(rs.history[i].window, "game_state.report_state.history.%d.window" % i); if not hw.ok: return hw
	return base

static func validate_v3(snapshot: Variant) -> Dictionary:
	return _validate_v2_or_v3(snapshot, SaveEnvelope.SCHEMA_VERSION_V3, ["command_tether_capacity", "unlocked_output_item_ids"])

static func validate_v2(snapshot: Variant) -> Dictionary:
	return _validate_v2_or_v3(snapshot, SaveEnvelope.SCHEMA_VERSION_V2, ["command_tether_capacity"])

static func _validate_v2_or_v3(snapshot: Variant, expected_version: int, progression_keys: Array, game_keys: Array = []) -> Dictionary:
	var base := _validate_common_envelope(snapshot, expected_version, SaveEnvelope.GAME_KEYS_V2 if game_keys.is_empty() else game_keys)
	if not base.ok:
		return base
	var g: Dictionary = (snapshot as Dictionary).game_state
	if typeof(g.inventory) != TYPE_DICTIONARY or not _require_keys(g.inventory, ["entries"], "game_state.inventory").ok:
		return _err(ERR_TYPE, "game_state.inventory")
	if typeof(g.inventory.entries) != TYPE_DICTIONARY or typeof(g.forms) != TYPE_DICTIONARY or typeof(g.thresholds) != TYPE_DICTIONARY or typeof(g.reapings) != TYPE_DICTIONARY:
		return _err(ERR_TYPE, "game_state")
	if typeof(g.progression) != TYPE_DICTIONARY:
		return _err(ERR_TYPE, "game_state.progression")
	var pkeys := _require_keys(g.progression, progression_keys, "game_state.progression")
	if not pkeys.ok:
		return pkeys
	var tether := SaveInt64.parse(g.progression.command_tether_capacity, false, "game_state.progression.command_tether_capacity")
	if not tether.ok:
		return tether
	var nested := _validate_v2_nested(g)
	if not nested.ok:
		return nested
	base["command_tether_capacity"] = tether.value
	base["unlocked_output_item_ids"] = []
	if expected_version == SaveEnvelope.SCHEMA_VERSION_V3 or expected_version == SaveEnvelope.SCHEMA_VERSION_V4:
		if typeof(g.progression.unlocked_output_item_ids) != TYPE_ARRAY: return _err(ERR_TYPE, "game_state.progression.unlocked_output_item_ids")
		var previous := ""
		for i in range(g.progression.unlocked_output_item_ids.size()):
			var value = g.progression.unlocked_output_item_ids[i]
			if typeof(value) != TYPE_STRING or value == "" or (i > 0 and String(value) <= previous): return _err(ERR_CROSS_FIELD, "game_state.progression.unlocked_output_item_ids")
			previous = value
			base.unlocked_output_item_ids.append(value)
	return base


static func _validate_common_envelope(snapshot: Variant, expected_version: int, game_keys: Array) -> Dictionary:
	if typeof(snapshot) != TYPE_DICTIONARY:
		return _err(ERR_NOT_DICTIONARY, "")
	var data: Dictionary = snapshot
	var keys_result := _require_keys(data, SaveEnvelope.TOP_LEVEL_KEYS, "")
	if not keys_result.ok:
		return keys_result
	if data.codec_id != SaveEnvelope.CODEC_JSON_V1:
		return _err(ERR_CODEC, "codec_id")
	var schema := SaveInt64.parse(data.schema_version, false, "schema_version")
	if not schema.ok or schema.value != expected_version:
		return _err(ERR_SCHEMA_VERSION, "schema_version")
	var revision := SaveInt64.parse(data.save_revision, false, "save_revision")
	if not revision.ok:
		return revision
	if typeof(data.content_revision) != TYPE_STRING or (data.content_revision as String).is_empty():
		return _err(ERR_CONTENT_REVISION, "content_revision")
	if _looks_like_absolute_path(data.content_revision):
		return _err(ERR_ABSOLUTE_PATH, "content_revision")
	if typeof(data.last_offline_resolution_id) != TYPE_STRING or _looks_like_absolute_path(data.last_offline_resolution_id):
		return _err(ERR_TYPE, "last_offline_resolution_id")
	if typeof(data.metadata) != TYPE_DICTIONARY or typeof(data.game_state) != TYPE_DICTIONARY:
		return _err(ERR_TYPE, "metadata")
	var game_keys_result := _require_keys(data.game_state, game_keys, "game_state")
	if not game_keys_result.ok:
		return game_keys_result
	var sim := SaveInt64.parse(data.game_state.simulation_time_msec, false, "game_state.simulation_time_msec")
	if not sim.ok:
		return sim
	if typeof(data.time_authority) != TYPE_DICTIONARY:
		return _err(ERR_TYPE, "time_authority")
	var time_keys := _require_keys(data.time_authority, SaveEnvelope.TIME_AUTHORITY_KEYS, "time_authority")
	if not time_keys.ok:
		return time_keys
	var t: Dictionary = data.time_authority
	if typeof(t.has_trusted_anchor) != TYPE_BOOL or typeof(t.trusted_source_id) != TYPE_STRING or typeof(t.pending_trusted_reconciliation) != TYPE_BOOL or typeof(t.last_sample_diagnostic_code) != TYPE_STRING:
		return _err(ERR_TYPE, "time_authority")
	if t.last_sample_diagnostic_code.is_empty() or _looks_like_absolute_path(t.last_sample_diagnostic_code):
		return _err(ERR_TYPE, "time_authority.last_sample_diagnostic_code")
	var anchor := SaveInt64.parse(t.trusted_anchor_utc_msec, false, "time_authority.trusted_anchor_utc_msec")
	if not anchor.ok:
		return anchor
	var foreground := SaveInt64.parse(t.foreground_credited_since_anchor_msec, false, "time_authority.foreground_credited_since_anchor_msec")
	if not foreground.ok:
		return foreground
	if t.has_trusted_anchor:
		if t.trusted_source_id.is_empty(): return _err(ERR_CROSS_FIELD, "time_authority.trusted_source_id")
	else:
		if anchor.value != 0 or foreground.value != 0 or not t.trusted_source_id.is_empty(): return _err(ERR_CROSS_FIELD, "time_authority")
	return {"ok": true, "code": OK, "save_revision": revision.value, "simulation_time_msec": sim.value, "trusted_anchor_utc_msec": anchor.value, "foreground_credited_since_anchor_msec": foreground.value}

static func _validate_report_window(w, path: String) -> Dictionary:
	if typeof(w) != TYPE_DICTIONARY: return _err(ERR_TYPE, path)
	var k := _require_keys(w, ["end_simulation_msec", "event_details", "events_by_type", "mode_counts", "omitted_oldest_event_detail_count", "run_count", "slices", "start_simulation_msec"], path); if not k.ok: return k
	for ik in ["start_simulation_msec", "end_simulation_msec", "run_count", "omitted_oldest_event_detail_count"]:
		var pi := SaveInt64.parse(w[ik], false, "%s.%s" % [path, ik]); if not pi.ok: return pi
	for map_key in ["mode_counts", "events_by_type"]:
		if typeof(w[map_key]) != TYPE_DICTIONARY: return _err(ERR_TYPE, "%s.%s" % [path, map_key])
		for mk in w[map_key].keys():
			var mi := SaveInt64.parse(w[map_key][mk], false, "%s.%s.%s" % [path, map_key, mk]); if not mi.ok: return mi
	if typeof(w.slices) != TYPE_DICTIONARY or typeof(w.event_details) != TYPE_ARRAY: return _err(ERR_TYPE, path)
	if w.event_details.size() > ReportState.MAX_EVENT_DETAILS: return _err(ERR_RANGE, "%s.event_details" % path)
	for sk in w.slices.keys():
		var sd = w.slices[sk]; if typeof(sd) != TYPE_DICTIONARY: return _err(ERR_TYPE, "%s.slices.%s" % [path, sk])
		for needed in ["threshold_id", "lifecycle_state", "form_id", "writ_id"]:
			if typeof(sd.get(needed, null)) != TYPE_STRING: return _err(ERR_TYPE, "%s.slices.%s.%s" % [path, sk, needed])
		for needed in ["retinue_ids"]:
			if typeof(sd.get(needed, null)) != TYPE_ARRAY: return _err(ERR_TYPE, "%s.slices.%s.%s" % [path, sk, needed])
			for rid in sd[needed]:
				if typeof(rid) != TYPE_STRING: return _err(ERR_TYPE, "%s.slices.%s.%s" % [path, sk, needed])
		for ik in ["assignment_revision", "start_simulation_msec", "end_simulation_msec", "elapsed_msec", "returned_souls_delta", "completed_cycles_delta"]:
			var si := SaveInt64.parse(sd.get(ik, ""), false, "%s.slices.%s.%s" % [path, sk, ik]); if not si.ok: return si
		var backlog_delta := SaveInt64.parse(sd.get("backlog_delta", ""), true, "%s.slices.%s.backlog_delta" % [path, sk]); if not backlog_delta.ok: return backlog_delta
		for map_key in ["inventory_gains", "mastery_gains"]:
			if typeof(sd.get(map_key, null)) != TYPE_DICTIONARY: return _err(ERR_TYPE, "%s.slices.%s.%s" % [path, sk, map_key])
			for gain_id in sd[map_key].keys():
				var gain := SaveInt64.parse(sd[map_key][gain_id], true, "%s.slices.%s.%s.%s" % [path, sk, map_key, gain_id]); if not gain.ok: return gain
		if typeof(sd.get("channel_summaries", null)) != TYPE_DICTIONARY: return _err(ERR_TYPE, "%s.slices.%s.channel_summaries" % [path, sk])
		for channel_id in sd.channel_summaries.keys():
			var channel = sd.channel_summaries[channel_id]; if typeof(channel) != TYPE_DICTIONARY: return _err(ERR_TYPE, "%s.slices.%s.channel_summaries.%s" % [path, sk, channel_id])
			var ck := _require_keys(channel, ["banked_units_delta", "channel_id", "first_progress_subunits_before", "first_rate_carry_units_before", "first_total_banked_units_before", "latest_progress_subunits_after", "latest_rate_carry_units_after", "latest_total_banked_units_after", "output_item_id"], "%s.slices.%s.channel_summaries.%s" % [path, sk, channel_id]); if not ck.ok: return ck
			if typeof(channel.channel_id) != TYPE_STRING or String(channel.channel_id).is_empty() or typeof(channel.output_item_id) != TYPE_STRING or String(channel.output_item_id).is_empty(): return _err(ERR_TYPE, "%s.slices.%s.channel_summaries.%s" % [path, sk, channel_id])
			for ikey in ["banked_units_delta", "first_progress_subunits_before", "latest_progress_subunits_after", "first_rate_carry_units_before", "latest_rate_carry_units_after", "first_total_banked_units_before", "latest_total_banked_units_after"]:
				var ci := SaveInt64.parse(channel[ikey], false, "%s.slices.%s.channel_summaries.%s.%s" % [path, sk, channel_id, ikey]); if not ci.ok: return ci
	for i in range(w.event_details.size()):
		var ed = w.event_details[i]; if typeof(ed) != TYPE_DICTIONARY: return _err(ERR_TYPE, "%s.event_details.%d" % [path, i])
		var event_path := "%s.event_details.%d" % [path, i]
		var event_keys := _require_keys(ed, ["event_sequence", "event_type", "occurred_simulation_msec", "priority", "source_id", "subject_id"], event_path); if not event_keys.ok: return event_keys
		for ik in ["event_sequence", "occurred_simulation_msec", "priority"]:
			var ei := SaveInt64.parse(ed[ik], false, "%s.%s" % [event_path, ik]); if not ei.ok: return ei
		for skey in ["event_type", "subject_id", "source_id"]:
			if typeof(ed[skey]) != TYPE_STRING or String(ed[skey]).is_empty(): return _err(ERR_TYPE, "%s.%s" % [event_path, skey])
	return {"ok": true}

static func _validate_v2_nested(g: Dictionary) -> Dictionary:
	for item_id in g.inventory.entries.keys():
		var entry = g.inventory.entries[item_id]
		if typeof(entry) != TYPE_DICTIONARY: return _err(ERR_TYPE, "game_state.inventory.entries.%s" % item_id)
		var k := _require_keys(entry, ["reservations", "total"], "game_state.inventory.entries.%s" % item_id); if not k.ok: return k
		var total := SaveInt64.parse(entry.total, false, "game_state.inventory.entries.%s.total" % item_id); if not total.ok: return total
		if typeof(entry.reservations) != TYPE_DICTIONARY: return _err(ERR_TYPE, "game_state.inventory.entries.%s.reservations" % item_id)
		for rid in entry.reservations.keys():
			var amount := SaveInt64.parse(entry.reservations[rid], false, "game_state.inventory.entries.%s.reservations.%s" % [item_id, rid]); if not amount.ok: return amount
	for form_id in g.forms.keys():
		var f = g.forms[form_id]; if typeof(f) != TYPE_DICTIONARY: return _err(ERR_TYPE, "game_state.forms.%s" % form_id)
		var kf := _require_keys(f, ["awakened", "awakened_by", "mastery_subunits", "revealed"], "game_state.forms.%s" % form_id); if not kf.ok: return kf
		if typeof(f.revealed) != TYPE_BOOL or typeof(f.awakened) != TYPE_BOOL or typeof(f.awakened_by) != TYPE_STRING: return _err(ERR_TYPE, "game_state.forms.%s" % form_id)
		var m := SaveInt64.parse(f.mastery_subunits, false, "game_state.forms.%s.mastery_subunits" % form_id); if not m.ok: return m
	for tid in g.thresholds.keys():
		var t = g.thresholds[tid]; if typeof(t) != TYPE_DICTIONARY: return _err(ERR_TYPE, "game_state.thresholds.%s" % tid)
		var kt := _require_keys(t, ["availability_state", "channel_acquisition", "familiarity_subunits", "knowledge_state", "lifecycle_state", "persistent_returns_total", "remaining_backlog"], "game_state.thresholds.%s" % tid); if not kt.ok: return kt
		for fkey in ["knowledge_state", "availability_state", "lifecycle_state"]:
			if typeof(t[fkey]) != TYPE_STRING: return _err(ERR_TYPE, "game_state.thresholds.%s.%s" % [tid, fkey])
		for ikey in ["remaining_backlog", "persistent_returns_total", "familiarity_subunits"]:
			var pi := SaveInt64.parse(t[ikey], false, "game_state.thresholds.%s.%s" % [tid, ikey]); if not pi.ok: return pi
		if typeof(t.channel_acquisition) != TYPE_DICTIONARY: return _err(ERR_TYPE, "game_state.thresholds.%s.channel_acquisition" % tid)
		for cid in t.channel_acquisition.keys():
			var a = t.channel_acquisition[cid]; if typeof(a) != TYPE_DICTIONARY: return _err(ERR_TYPE, "game_state.thresholds.%s.channel_acquisition.%s" % [tid, cid])
			var ka := _require_keys(a, ["progress_subunits", "rate_carry_units", "total_banked_units"], "game_state.thresholds.%s.channel_acquisition.%s" % [tid, cid]); if not ka.ok: return ka
			for akey in ["progress_subunits", "rate_carry_units", "total_banked_units"]:
				var ai := SaveInt64.parse(a[akey], false, "game_state.thresholds.%s.channel_acquisition.%s.%s" % [tid, cid, akey]); if not ai.ok: return ai
	for rid in g.reapings.keys():
		var r = g.reapings[rid]; if typeof(r) != TYPE_DICTIONARY: return _err(ERR_TYPE, "game_state.reapings.%s" % rid)
		var kr := _require_keys(r, ["assignment_revision", "completed_cycle_count", "cycle_phase_msec", "flow_carry_units", "form_id", "is_active", "last_configuration_change_simulation_msec", "retinue_ids", "started_simulation_msec", "threshold_id", "writ_id"], "game_state.reapings.%s" % rid); if not kr.ok: return kr
		if typeof(r.threshold_id) != TYPE_STRING or typeof(r.form_id) != TYPE_STRING or typeof(r.writ_id) != TYPE_STRING or typeof(r.is_active) != TYPE_BOOL or typeof(r.retinue_ids) != TYPE_ARRAY or typeof(r.flow_carry_units) != TYPE_DICTIONARY: return _err(ERR_TYPE, "game_state.reapings.%s" % rid)
		for ikey in ["assignment_revision", "cycle_phase_msec", "completed_cycle_count", "started_simulation_msec", "last_configuration_change_simulation_msec"]:
			var ri := SaveInt64.parse(r[ikey], false, "game_state.reapings.%s.%s" % [rid, ikey]); if not ri.ok: return ri
		for flow in r.flow_carry_units.keys():
			var fi := SaveInt64.parse(r.flow_carry_units[flow], false, "game_state.reapings.%s.flow_carry_units.%s" % [rid, flow]); if not fi.ok: return fi
	return {"ok": true}
