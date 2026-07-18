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
static func validate(state: GameState, registry: ContentRegistry) -> Dictionary:
	if state == null: return _err(ERR_TYPE, "game_state")
	if registry == null or not registry.ready: return _err(ERR_CONTENT, "content_registry")
	if state.simulation_time_msec < 0: return _err(ERR_RANGE, "simulation_time_msec")
	var result := _validate_inventory(state, registry); if not result.ok: return result
	result = _validate_forms(state, registry); if not result.ok: return result
	result = _validate_thresholds(state, registry); if not result.ok: return result
	result = _validate_reapings(state, registry); if not result.ok: return result
	if state.progression.command_tether_capacity < 0: return _err(ERR_RANGE, "progression.command_tether_capacity")
	if state.progression.unlocked_output_item_ids != _sorted_unique_string_names(state.progression.unlocked_output_item_ids): return _err(ERR_CROSS_FIELD, "progression.unlocked_output_item_ids")
	for item_id in state.progression.unlocked_output_item_ids:
		var item := registry.get_record(str(item_id))
		if not item.ok or item.record.type != "item" or str(item_id) == "RES_ESSENCE": return _err(ERR_CONTENT, "progression.unlocked_output_item_ids.%s" % item_id)
	var active := 0
	for reaping in state.reapings.values(): if reaping.is_active: active += 1
	if active > state.progression.command_tether_capacity: return _err(ERR_CROSS_FIELD, "reapings.active")
	return {"ok": true, "code": OK}

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

static func _validate_thresholds(state: GameState, registry: ContentRegistry) -> Dictionary:
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
			var channel := registry.get_record(str(channel_id))
			if not channel.ok or channel.record.type != "channel" or channel.record.source_threshold_id != str(threshold_id): return _err(ERR_CONTENT, "thresholds.%s.channel_acquisition.%s" % [threshold_id, channel_id])
			if channel.record.output_item_id == "RES_ESSENCE": return _err(ERR_CROSS_FIELD, "thresholds.%s.channel_acquisition.%s" % [threshold_id, channel_id])
			if channel.record.progression_required and not state.progression.unlocked_output_item_ids.has(StringName(channel.record.output_item_id)): return _err(ERR_CROSS_FIELD, "thresholds.%s.channel_acquisition.%s" % [threshold_id, channel_id])
			var acq = threshold.channel_acquisition[channel_id]
			if not acq is GameState.ThresholdAcquisitionState: return _err(ERR_TYPE, "thresholds.%s.channel_acquisition.%s" % [threshold_id, channel_id])
			if acq.progress_subunits < 0 or acq.progress_subunits >= FixedPoint.SCALE: return _err(ERR_RANGE, "thresholds.%s.channel_acquisition.%s.progress_subunits" % [threshold_id, channel_id])
			if acq.rate_carry_units < 0 or acq.rate_carry_units >= int(channel.record.rate.period_msec): return _err(ERR_RANGE, "thresholds.%s.channel_acquisition.%s.rate_carry_units" % [threshold_id, channel_id])
			if acq.total_banked_units < 0: return _err(ERR_RANGE, "thresholds.%s.channel_acquisition.%s.total_banked_units" % [threshold_id, channel_id])
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
