class_name GameStateValidator
extends RefCounted

## Content-aware validator for M04A runtime state.
##
## Schema validation proves primitive key and type shape before construction;
## this validator proves runtime gameplay invariants against the validated M03
## content registry.  It never mutates the candidate, never reads clocks or file
## metadata, and reports stable field paths so failed migrations do not expose a
## partially accepted live state.

const OK := "OK"
const ERR_TYPE := "GAME_STATE_TYPE"
const ERR_RANGE := "GAME_STATE_RANGE"
const ERR_CONTENT := "GAME_STATE_CONTENT_ID"
const ERR_CROSS_FIELD := "GAME_STATE_CROSS_FIELD"
static func validate(state: GameState, registry: ContentRegistry, require_complete_access := true) -> Dictionary:
	if state == null: return _err(ERR_TYPE, "game_state")
	if registry == null or not registry.ready: return _err(ERR_CONTENT, "content_registry")
	if state.simulation_time_msec < 0: return _err(ERR_RANGE, "simulation_time_msec")
	var result := _validate_inventory(state, registry); if not result.ok: return result
	result = _validate_forms(state, registry); if not result.ok: return result
	result = _validate_thresholds(state, registry, require_complete_access); if not result.ok: return result
	result = _validate_reapings(state, registry); if not result.ok: return result
	var report := validate_report_state(state, registry)
	if not report.ok: return report
	if state.progression.command_tether_capacity < 0: return _err(ERR_RANGE, "progression.command_tether_capacity")
	if state.progression.unlocked_output_item_ids != _sorted_unique_string_names(state.progression.unlocked_output_item_ids): return _err(ERR_CROSS_FIELD, "progression.unlocked_output_item_ids")
	for item_id in state.progression.unlocked_output_item_ids:
		var access := OutputAccessService.validate_output_item_access(registry, str(item_id))
		if not access.ok: return _err(ERR_CONTENT, "progression.unlocked_output_item_ids.%s" % item_id)
	var active := 0
	for reaping in state.reapings.values(): if reaping.is_active: active += 1
	if active > state.progression.command_tether_capacity: return _err(ERR_CROSS_FIELD, "reapings.active")
	return {"ok": true, "code": OK}


static func validate_report_state(state: GameState, registry: ContentRegistry = null) -> Dictionary:
	if state == null or state.report_state == null or not (state.report_state is ReportState):
		return _err(ERR_TYPE, "report_state")
	var rs: ReportState = state.report_state
	if rs.report_cursor_msec < 0 or rs.report_cursor_msec > state.simulation_time_msec:
		return _err(ERR_RANGE, "report_state.report_cursor_msec")
	if rs.next_report_sequence <= 0:
		return _err(ERR_RANGE, "report_state.next_report_sequence")
	if rs.next_event_sequence <= 0:
		return _err(ERR_RANGE, "report_state.next_event_sequence")
	if rs.dropped_history_record_count < 0:
		return _err(ERR_RANGE, "report_state.dropped_history_record_count")
	if rs.history.size() > ReportState.MAX_HISTORY_RECORDS:
		return _err(ERR_RANGE, "report_state.history")
	if rs.live != null and rs.live is ReportState.ReportWindow and rs.live.end_simulation_msec != rs.report_cursor_msec:
		return _err(ERR_CROSS_FIELD, "report_state.live.end_simulation_msec")
	var max_event_sequence := 0
	var live_result := _validate_report_window(rs.live, "report_state.live", rs.report_cursor_msec, registry)
	if not live_result.ok: return live_result
	max_event_sequence = max(max_event_sequence, int(live_result.max_event_sequence))
	var previous_sequence := 0
	var max_report_sequence := 0
	for i in range(rs.history.size()):
		var record = rs.history[i]
		if record == null or not (record is ReportState.ReportRecord):
			return _err(ERR_TYPE, "report_state.history.%d" % i)
		if record.report_sequence <= 0:
			return _err(ERR_RANGE, "report_state.history.%d.report_sequence" % i)
		if record.report_sequence <= previous_sequence:
			return _err(ERR_CROSS_FIELD, "report_state.history.%d.report_sequence" % i)
		previous_sequence = record.report_sequence
		max_report_sequence = max(max_report_sequence, record.report_sequence)
		if not ReportState.VALID_REASONS.has(record.snapshot_reason):
			return _err(ERR_RANGE, "report_state.history.%d.snapshot_reason" % i)
		if record.snapshot_simulation_msec < 0:
			return _err(ERR_RANGE, "report_state.history.%d.snapshot_simulation_msec" % i)
		if record.snapshot_simulation_msec > rs.report_cursor_msec:
			return _err(ERR_CROSS_FIELD, "report_state.history.%d.snapshot_simulation_msec" % i)
		var window_result := _validate_report_window(record.window, "report_state.history.%d.window" % i, rs.report_cursor_msec, registry)
		if not window_result.ok: return window_result
		if record.snapshot_simulation_msec != record.window.end_simulation_msec:
			return _err(ERR_CROSS_FIELD, "report_state.history.%d.snapshot_simulation_msec" % i)
		max_event_sequence = max(max_event_sequence, int(window_result.max_event_sequence))
	if rs.next_report_sequence <= max_report_sequence:
		return _err(ERR_CROSS_FIELD, "report_state.next_report_sequence")
	if rs.next_event_sequence <= max_event_sequence:
		return _err(ERR_CROSS_FIELD, "report_state.next_event_sequence")
	return {"ok": true}

static func _validate_report_window(window, path: String, max_end_msec: int, registry: ContentRegistry = null) -> Dictionary:
	if window == null or not (window is ReportState.ReportWindow):
		return _err(ERR_TYPE, path)
	if window.start_simulation_msec < 0 or window.end_simulation_msec < window.start_simulation_msec or window.end_simulation_msec > max_end_msec:
		return _err(ERR_RANGE, path)
	if window.run_count < 0 or window.omitted_oldest_event_detail_count < 0:
		return _err(ERR_RANGE, path)
	if window.event_details.size() > ReportState.MAX_EVENT_DETAILS:
		return _err(ERR_RANGE, "%s.event_details" % path)
	var seen_slice_keys := {}
	var counted_modes := 0
	for key in window.mode_counts.keys():
		if str(key).is_empty() or not ReportState.VALID_MODES.has(StringName(key)):
			return _err(ERR_RANGE, "%s.mode_counts.%s" % [path, key])
		if int(window.mode_counts[key]) < 0: return _err(ERR_RANGE, "%s.mode_counts.%s" % [path, key])
		counted_modes += int(window.mode_counts[key])
	if counted_modes != window.run_count: return _err(ERR_CROSS_FIELD, "%s.mode_counts" % path)
	for key in window.events_by_type.keys():
		if str(key).is_empty() or int(window.events_by_type[key]) < 0: return _err(ERR_RANGE, "%s.events_by_type.%s" % [path, key])
	for key in window.slices.keys():
		var slice = window.slices[key]
		if slice == null or not (slice is ReportState.AttributionSlice): return _err(ERR_TYPE, "%s.slices.%s" % [path, key])
		if slice.threshold_id == &"" or slice.lifecycle_state == &"" or slice.form_id == &"" or slice.writ_id == &"": return _err(ERR_TYPE, "%s.slices.%s" % [path, key])
		if not [&"OVERDUE", &"SETTLED"].has(slice.lifecycle_state): return _err(ERR_RANGE, "%s.slices.%s.lifecycle_state" % [path, key])
		if slice.assignment_revision <= 0 or slice.start_simulation_msec < window.start_simulation_msec or slice.end_simulation_msec > window.end_simulation_msec or slice.end_simulation_msec < slice.start_simulation_msec or slice.elapsed_msec < 0 or slice.returned_souls_delta < 0 or slice.completed_cycles_delta < 0:
			return _err(ERR_RANGE, "%s.slices.%s" % [path, key])
		var canonical_key := _report_slice_key(slice.threshold_id, slice.assignment_revision, slice.lifecycle_state)
		if str(key) != canonical_key:
			return _err(ERR_CROSS_FIELD, "%s.slices.%s" % [path, key])
		if seen_slice_keys.has(canonical_key):
			return _err(ERR_CROSS_FIELD, "%s.slices.%s" % [path, key])
		seen_slice_keys[canonical_key] = true
		if slice.retinue_ids != _sorted_unique_string_names(slice.retinue_ids): return _err(ERR_CROSS_FIELD, "%s.slices.%s.retinue_ids" % [path, key])
		for retinue_id in slice.retinue_ids:
			if str(retinue_id).is_empty(): return _err(ERR_TYPE, "%s.slices.%s.retinue_ids" % [path, key])
		for value in slice.inventory_gains.values():
			if int(value) < 0: return _err(ERR_RANGE, "%s.slices.%s.inventory_gains" % [path, key])
		for value in slice.mastery_gains.values():
			if int(value) < 0: return _err(ERR_RANGE, "%s.slices.%s.mastery_gains" % [path, key])
		for channel_key in slice.channel_summaries.keys():
			var channel = slice.channel_summaries[channel_key]
			if channel == null or not (channel is ReportState.ChannelSummary): return _err(ERR_TYPE, "%s.slices.%s.channel_summaries.%s" % [path, key, channel_key])
			if channel.channel_id == &"" or channel.output_item_id == &"" or str(channel.channel_id) != str(channel_key): return _err(ERR_CROSS_FIELD, "%s.slices.%s.channel_summaries.%s" % [path, key, channel_key])
			if registry != null:
				var relationship := OutputAccessService.validate_channel_relationship(registry, str(channel.channel_id), str(channel.output_item_id), str(slice.threshold_id))
				if not relationship.ok: return _err(ERR_CONTENT, "%s.slices.%s.channel_summaries.%s" % [path, key, channel_key])
			if channel.banked_units_delta < 0 or channel.first_progress_subunits_before < 0 or channel.latest_progress_subunits_after < 0 or channel.first_rate_carry_units_before < 0 or channel.latest_rate_carry_units_after < 0 or channel.first_total_banked_units_before < 0 or channel.latest_total_banked_units_after < 0:
				return _err(ERR_RANGE, "%s.slices.%s.channel_summaries.%s" % [path, key, channel_key])
	var previous_event_sequence := 0
	var max_event_sequence := 0
	for i in range(window.event_details.size()):
		var event = window.event_details[i]
		if event == null or not (event is ReportState.ReportEventDetail): return _err(ERR_TYPE, "%s.event_details.%d" % [path, i])
		if event.event_sequence <= 0 or event.event_sequence <= previous_event_sequence or event.event_type == &"" or event.occurred_simulation_msec <= window.start_simulation_msec or event.occurred_simulation_msec > window.end_simulation_msec or event.priority < 0 or event.subject_id == &"" or event.source_id == &"":
			return _err(ERR_RANGE, "%s.event_details.%d" % [path, i])
		previous_event_sequence = event.event_sequence
		max_event_sequence = max(max_event_sequence, event.event_sequence)
	return {"ok": true, "max_event_sequence": max_event_sequence}

static func _report_slice_key(threshold_id: StringName, assignment_revision: int, lifecycle_state: StringName) -> String:
	return "%s|%d|%s" % [threshold_id, assignment_revision, lifecycle_state]

static func _validate_inventory(state: GameState, registry: ContentRegistry) -> Dictionary:
	for item_id in _sorted_keys(state.inventory.entries):
		var rec := registry.get_record(str(item_id))
		if not rec.ok or rec.record.type != "item": return _err(ERR_CONTENT, "inventory.entries.%s" % item_id)
		var entry = state.inventory.entries[item_id]
		if not entry is GameState.InventoryEntryState: return _err(ERR_TYPE, "inventory.entries.%s" % item_id)
		if entry.total < 0: return _err(ERR_RANGE, "inventory.entries.%s.total" % item_id)
		var reserved := 0
		for reservation_id in _sorted_keys(entry.reservations):
			var amount: int = entry.reservations[reservation_id]
			if amount < 0: return _err(ERR_RANGE, "inventory.entries.%s.reservations.%s" % [item_id, reservation_id])
			if reserved > FixedPoint.INT64_MAX - amount: return _err(ERR_RANGE, "inventory.entries.%s.reservations" % item_id)
			reserved += amount
		if reserved > entry.total: return _err(ERR_CROSS_FIELD, "inventory.entries.%s.reservations" % item_id)
	return {"ok": true}

static func _validate_forms(state: GameState, registry: ContentRegistry) -> Dictionary:
	for form_id in _sorted_keys(state.forms):
		var rec := registry.get_record(str(form_id))
		if not rec.ok or rec.record.type != "form": return _err(ERR_CONTENT, "forms.%s" % form_id)
		var form = state.forms[form_id]
		if not form is GameState.FormState: return _err(ERR_TYPE, "forms.%s" % form_id)
		if form.mastery_subunits < 0: return _err(ERR_RANGE, "forms.%s.mastery_subunits" % form_id)
		if form.awakened and not form.revealed: return _err(ERR_CROSS_FIELD, "forms.%s.revealed" % form_id)
		if form.awakened and str(form.awakened_by).is_empty(): return _err(ERR_CROSS_FIELD, "forms.%s.awakened_by" % form_id)
		if not form.awakened and not str(form.awakened_by).is_empty(): return _err(ERR_CROSS_FIELD, "forms.%s.awakened_by" % form_id)
	return {"ok": true}

static func _validate_thresholds(state: GameState, registry: ContentRegistry, require_complete_access: bool) -> Dictionary:
	for threshold_id in _sorted_keys(state.thresholds):
		var rec := registry.get_record(str(threshold_id))
		if not rec.ok or rec.record.type != "threshold": return _err(ERR_CONTENT, "thresholds.%s" % threshold_id)
		var threshold = state.thresholds[threshold_id]
		if not threshold is GameState.ThresholdState: return _err(ERR_TYPE, "thresholds.%s" % threshold_id)
		if not ["UNKNOWN", "DETECTED", "CHARTED"].has(str(threshold.knowledge_state)): return _err(ERR_RANGE, "thresholds.%s.knowledge_state" % threshold_id)
		if not ["LOCKED", "AVAILABLE"].has(str(threshold.availability_state)): return _err(ERR_RANGE, "thresholds.%s.availability_state" % threshold_id)
		if not ["OVERDUE", "SETTLED"].has(str(threshold.lifecycle_state)): return _err(ERR_RANGE, "thresholds.%s.lifecycle_state" % threshold_id)
		if threshold.remaining_backlog < 0 or threshold.remaining_backlog > int(rec.record.standing_backlog): return _err(ERR_RANGE, "thresholds.%s.remaining_backlog" % threshold_id)
		if threshold.remaining_backlog == 0 and str(threshold.lifecycle_state) != "SETTLED": return _err(ERR_CROSS_FIELD, "thresholds.%s.lifecycle_state" % threshold_id)
		if threshold.remaining_backlog > 0 and str(threshold.lifecycle_state) != "OVERDUE": return _err(ERR_CROSS_FIELD, "thresholds.%s.lifecycle_state" % threshold_id)
		if threshold.persistent_returns_total < 0 or threshold.familiarity_subunits < 0: return _err(ERR_RANGE, "thresholds.%s" % threshold_id)
		for channel_id in _sorted_keys(threshold.channel_acquisition):
			var relationship := OutputAccessService.validate_channel_relationship(registry, str(channel_id), "", str(threshold_id))
			if not relationship.ok: return _err(ERR_CONTENT, "thresholds.%s.channel_acquisition.%s" % [threshold_id, channel_id])
			var channel: Dictionary = relationship.channel
			if channel.progression_required and not state.progression.unlocked_output_item_ids.has(StringName(channel.output_item_id)): return _err(ERR_CROSS_FIELD, "thresholds.%s.channel_acquisition.%s" % [threshold_id, channel_id])
			if require_complete_access and str(threshold.availability_state) != "AVAILABLE": return _err(ERR_CROSS_FIELD, "thresholds.%s.channel_acquisition.%s" % [threshold_id, channel_id])
			var acq = threshold.channel_acquisition[channel_id]
			if not acq is GameState.ThresholdAcquisitionState: return _err(ERR_TYPE, "thresholds.%s.channel_acquisition.%s" % [threshold_id, channel_id])
			if acq.progress_subunits < 0 or acq.progress_subunits >= FixedPoint.SCALE: return _err(ERR_RANGE, "thresholds.%s.channel_acquisition.%s.progress_subunits" % [threshold_id, channel_id])
			if acq.rate_carry_units < 0 or acq.rate_carry_units >= int(channel.rate.period_msec): return _err(ERR_RANGE, "thresholds.%s.channel_acquisition.%s.rate_carry_units" % [threshold_id, channel_id])
			if acq.total_banked_units < 0: return _err(ERR_RANGE, "thresholds.%s.channel_acquisition.%s.total_banked_units" % [threshold_id, channel_id])
		if require_complete_access and str(threshold.availability_state) == "AVAILABLE":
			for authored_channel_id in rec.record.channel_ids:
				var authored := OutputAccessService.validate_channel_relationship(registry, str(authored_channel_id), "", str(threshold_id))
				if not authored.ok:
					continue
				var authored_channel: Dictionary = authored.channel
				if authored_channel.progression_required and not state.progression.unlocked_output_item_ids.has(StringName(authored_channel.output_item_id)):
					continue
				if not threshold.channel_acquisition.has(StringName(authored_channel.id)):
					return _err(ERR_CROSS_FIELD, "thresholds.%s.channel_acquisition.%s" % [threshold_id, authored_channel.id])
	return {"ok": true}

static func _validate_reapings(state: GameState, registry: ContentRegistry) -> Dictionary:
	var active_form_thresholds := {}
	for key in _sorted_keys(state.reapings):
		var reaping = state.reapings[key]
		if not reaping is GameState.ReapingState: return _err(ERR_TYPE, "reapings.%s" % key)
		if str(reaping.threshold_id) != str(key) or not state.thresholds.has(key): return _err(ERR_CROSS_FIELD, "reapings.%s.threshold_id" % key)
		var form := registry.get_record(str(reaping.form_id)); if not form.ok or form.record.type != "form": return _err(ERR_CONTENT, "reapings.%s.form_id" % key)
		var threshold_record := registry.get_record(str(reaping.threshold_id)); if not threshold_record.ok or threshold_record.record.type != "threshold": return _err(ERR_CONTENT, "reapings.%s.threshold_id" % key)
		var writ := registry.get_record(str(reaping.writ_id)); if not writ.ok or writ.record.type != "writ": return _err(ERR_CONTENT, "reapings.%s.writ_id" % key)
		if reaping.assignment_revision <= 0: return _err(ERR_RANGE, "reapings.%s.assignment_revision" % key)
		if reaping.is_active:
			if str(state.thresholds[key].availability_state) != "AVAILABLE": return _err(ERR_CROSS_FIELD, "reapings.%s.threshold_id" % key)
			if not writ.record.enabled: return _err(ERR_CROSS_FIELD, "reapings.%s.writ_id" % key)
			if active_form_thresholds.has(reaping.form_id): return _err(ERR_CROSS_FIELD, "reapings.%s.form_id" % key)
			active_form_thresholds[reaping.form_id] = key
			if not state.forms.has(reaping.form_id) or not state.forms[reaping.form_id].awakened: return _err(ERR_CROSS_FIELD, "reapings.%s.form_id" % key)
		if reaping.retinue_ids != _sorted_unique_string_names(reaping.retinue_ids): return _err(ERR_CROSS_FIELD, "reapings.%s.retinue_ids" % key)
		for retinue_id in reaping.retinue_ids:
			var retinue := registry.get_record(str(retinue_id)); if not retinue.ok or retinue.record.type != "retinue": return _err(ERR_CONTENT, "reapings.%s.retinue_ids" % key)
		if reaping.cycle_phase_msec < 0 or reaping.completed_cycle_count < 0: return _err(ERR_RANGE, "reapings.%s" % key)
		if reaping.cycle_phase_msec >= int(form.record.cycle_duration_msec): return _err(ERR_RANGE, "reapings.%s.cycle_phase_msec" % key)
		if reaping.started_simulation_msec < 0 or reaping.started_simulation_msec > state.simulation_time_msec: return _err(ERR_RANGE, "reapings.%s.started_simulation_msec" % key)
		if reaping.last_configuration_change_simulation_msec < 0 or reaping.last_configuration_change_simulation_msec > state.simulation_time_msec: return _err(ERR_RANGE, "reapings.%s.last_configuration_change_simulation_msec" % key)
		if reaping.last_configuration_change_simulation_msec < reaping.started_simulation_msec: return _err(ERR_CROSS_FIELD, "reapings.%s.last_configuration_change_simulation_msec" % key)
		var essence_channel := CoreFlowKeys.find_single_essence_channel(registry, reaping.threshold_id, threshold_record.record)
		if not essence_channel.ok: return _err(ERR_CONTENT, "reapings.%s.flow_carry_units.%s" % [key, essence_channel.get("field_path", "RES_ESSENCE")])
		var residuals := CoreFlowKeys.validate_reaping_residuals(reaping, threshold_record.record, form.record, essence_channel.channel)
		if not residuals.ok: return _err(String(residuals.code), "reapings.%s.%s" % [key, residuals.get("field_path", "flow_carry_units")])
	return {"ok": true}

static func _sorted_keys(dict: Dictionary) -> Array:
	var keys := dict.keys(); keys.sort(); return keys
static func _sorted_unique_string_names(values: Array[StringName]) -> Array[StringName]:
	var copy := values.duplicate(); copy.sort(); var out: Array[StringName] = []
	for value in copy:
		if out.has(value): return []
		out.append(value)
	return out
static func _err(code: String, field_path: String) -> Dictionary:
	return {"ok": false, "code": code, "field_path": field_path}
