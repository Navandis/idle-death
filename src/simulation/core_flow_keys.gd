class_name CoreFlowKeys
extends RefCounted

## Shared M04C ownership for stable core Reaping residual keys.
##
## The keys live in `ReapingState.flow_carry_units` so schema v2 can persist
## M04C progress without adding new save fields. This helper is the single owner
## for membership, classification, deterministic ordering, and content-derived
## range validation. It owns no production formulas and reads no clocks, files,
## scenes, UI, or platform state.

const RETURNS_PROGRESS := &"FLOW_CORE_RETURNS_PROGRESS_SUBUNITS"
const RETURNS_CARRY := &"FLOW_CORE_RETURNS_RATE_CARRY_UNITS"
const ESSENCE_PROGRESS := &"FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS"
const ESSENCE_CARRY := &"FLOW_CORE_ESSENCE_RATE_CARRY_UNITS"
const MASTERY_CARRY := &"FLOW_CORE_MASTERY_RATE_CARRY_UNITS"

const ORDERED_KEYS := [RETURNS_PROGRESS, RETURNS_CARRY, ESSENCE_PROGRESS, ESSENCE_CARRY, MASTERY_CARRY]
const PROGRESS_KEYS := [RETURNS_PROGRESS, ESSENCE_PROGRESS]

static func ordered_keys() -> Array[StringName]:
	return [RETURNS_PROGRESS, RETURNS_CARRY, ESSENCE_PROGRESS, ESSENCE_CARRY, MASTERY_CARRY]

static func is_known(key: StringName) -> bool:
	return ORDERED_KEYS.has(key)

static func is_progress_key(key: StringName) -> bool:
	return PROGRESS_KEYS.has(key)

static func validate_reaping_residuals(reaping: GameState.ReapingState, threshold_record: Dictionary, form_record: Dictionary, essence_channel: Dictionary) -> Dictionary:
	for key in reaping.flow_carry_units.keys():
		var value := int(reaping.flow_carry_units[key])
		if value < 0:
			return _err("GAME_STATE_RANGE", "flow_carry_units.%s" % key)
		if key == RETURNS_PROGRESS or key == ESSENCE_PROGRESS:
			if value >= FixedPoint.SCALE: return _err("GAME_STATE_RANGE", "flow_carry_units.%s" % key)
		elif key == RETURNS_CARRY:
			if value >= int(form_record.base_returned_souls_rate.period_msec): return _err("GAME_STATE_RANGE", "flow_carry_units.%s" % key)
		elif key == ESSENCE_CARRY:
			if value >= int(essence_channel.rate.period_msec): return _err("GAME_STATE_RANGE", "flow_carry_units.%s" % key)
		elif key == MASTERY_CARRY:
			if value >= int(form_record.active_mastery_rate.period_msec): return _err("GAME_STATE_RANGE", "flow_carry_units.%s" % key)
		# Unknown zero-valued keys are preserved for compatibility; active M04C
		# resolution still rejects unknown nonzero keys before mutation.
	return {"ok": true}

static func find_single_essence_channel(registry: ContentRegistry, threshold_id: StringName, threshold_record: Dictionary) -> Dictionary:
	var matches: Array[Dictionary] = []
	for channel_id in threshold_record.channel_ids:
		var record := registry.get_record(str(channel_id))
		if not record.ok:
			return _err("GAME_STATE_CONTENT_ID", "thresholds.%s.channel_ids.%s" % [threshold_id, channel_id])
		var channel: Dictionary = record.record
		if channel.source_threshold_id != str(threshold_id):
			return _err("GAME_STATE_CONTENT_ID", "thresholds.%s.channel_ids.%s.source_threshold_id" % [threshold_id, channel_id])
		if channel.enabled and channel.output_item_id == "RES_ESSENCE":
			if int(channel.rate.rate_subunits_per_period) < 0 or int(channel.rate.period_msec) <= 0:
				return _err("GAME_STATE_CONTENT_ID", "channels.%s.rate" % channel_id)
			matches.append(channel)
	if matches.size() != 1:
		return _err("GAME_STATE_CONTENT_ID", "thresholds.%s.RES_ESSENCE_channel_count" % threshold_id)
	return {"ok": true, "channel": matches[0]}

static func _err(code: String, field_path: String) -> Dictionary:
	return {"ok": false, "code": code, "field_path": field_path}
