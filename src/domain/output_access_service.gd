class_name OutputAccessService
extends RefCounted

## Owns M04D1 output-item access commands and source reconciliation.
##
## Access is global by canonical output item ID and is stored in
## `ProgressionState.unlocked_output_item_ids`. Source-specific acquisition work
## is still owned by the matching Threshold's `channel_acquisition` map. Commands
## use cloned candidates, typed bounded results, and primitive event payloads.
## They never read clocks, advance simulation, grant inventory, or backfill work.

const OK := "OK"
const ERR_STATE_INVALID := "OUTPUT_ACCESS_STATE_INVALID"
const ERR_ITEM_NOT_FOUND := "OUTPUT_ACCESS_ITEM_NOT_FOUND"
const ERR_ITEM_DISABLED := "OUTPUT_ACCESS_ITEM_DISABLED"
const ERR_NO_AUTHORED_SOURCE := "OUTPUT_ACCESS_NO_AUTHORED_SOURCE"
const ERR_CHANNEL_INVALID := "OUTPUT_ACCESS_CHANNEL_INVALID"
const ERR_CHANNEL_OWNERSHIP_INVALID := "OUTPUT_ACCESS_CHANNEL_OWNERSHIP_INVALID"
const ERR_ESSENCE_EXCLUDED := "OUTPUT_ACCESS_ESSENCE_EXCLUDED"
const ERR_MIGRATION_FINALIZATION_FAILED := "OUTPUT_ACCESS_MIGRATION_FINALIZATION_FAILED"
const EVENT_ITEM_UNLOCKED := "OUTPUT_ITEM_UNLOCKED"
const EVENT_SOURCE_IDENTIFIED := "OUTPUT_SOURCE_IDENTIFIED"
const ESSENCE_ID := "RES_ESSENCE"

class AccessChangeSummary:
	extends RefCounted
	var output_item_id: String = ""
	var access_added: bool = false
	var already_unlocked: bool = false
	var initialized_source_channel_ids: Array[String] = []
	var identified_threshold_ids: Array[String] = []
	var simulation_time_msec: int = 0

	func _init(item_id := "", added := false, already := false, channels: Array[String] = [], thresholds: Array[String] = [], time_msec := 0) -> void:
		output_item_id = item_id
		access_added = added
		already_unlocked = already
		initialized_source_channel_ids = channels.duplicate()
		identified_threshold_ids = thresholds.duplicate()
		initialized_source_channel_ids.sort()
		identified_threshold_ids.sort()
		simulation_time_msec = time_msec

class AccessEvent:
	extends RefCounted
	var event_type: String = ""
	var occurred_simulation_msec: int = 0
	var priority: int = 0
	var subject_id: String = ""
	var source_id: String = ""
	var payload: Dictionary = {}
	var reportable: bool = true
	var tutorial_relevant: bool = true

	func _init(type := "", time_msec := 0, priority_value := 0, subject := "", source := "", payload_value: Dictionary = {}) -> void:
		event_type = type
		occurred_simulation_msec = time_msec
		priority = priority_value
		subject_id = subject
		source_id = source
		payload = payload_value.duplicate(true)

class AccessActionResult:
	extends RefCounted
	var success: bool = false
	var error_code: String = ""
	var player_message: String = ""
	var developer_details: String = ""
	var change_summary: AccessChangeSummary = null
	var events: Array[AccessEvent] = []
	var save_checkpoint_requested: bool = false

var registry: ContentRegistry

func _init(content_registry: ContentRegistry) -> void:
	registry = content_registry

func unlock_output_item(state: GameState, output_item_id: StringName) -> AccessActionResult:
	var validation := GameStateValidator.validate(state, registry, false)
	if not validation.ok: return _failure(ERR_STATE_INVALID, str(validation))
	var item_check := _validate_item_id(str(output_item_id))
	if not item_check.ok: return _failure(item_check.code, item_check.get("developer_details", ""))
	var channels_result := _authored_channels_for_item(str(output_item_id), true)
	if not channels_result.ok: return _failure(channels_result.code, channels_result.get("developer_details", ""))
	var channels: Array = channels_result.channels
	if channels.is_empty(): return _failure(ERR_NO_AUTHORED_SOURCE, "No valid authored non-Essence source channel outputs %s." % output_item_id)
	if state.progression.unlocked_output_item_ids.has(output_item_id):
		return _success(AccessChangeSummary.new(str(output_item_id), false, true, [], [], state.simulation_time_msec), [], false)
	var candidate := state.deep_clone()
	candidate.progression.unlocked_output_item_ids.append(output_item_id)
	candidate.progression.unlocked_output_item_ids.sort()
	var source_events := _initialize_available_sources(candidate, channels, state.simulation_time_msec)
	var candidate_validation := GameStateValidator.validate(candidate, registry, true)
	if not candidate_validation.ok: return _failure(ERR_STATE_INVALID, str(candidate_validation))
	state.copy_from(candidate)
	var events: Array[AccessEvent] = [_event(EVENT_ITEM_UNLOCKED, state.simulation_time_msec, 0, str(output_item_id), str(output_item_id), {"output_item_id": str(output_item_id)})]
	events.append_array(source_events)
	events.sort_custom(_event_less)
	return _success(_summary(str(output_item_id), true, false, source_events, state.simulation_time_msec), events, true)

func reconcile_available_sources(state: GameState) -> AccessActionResult:
	var validation := GameStateValidator.validate(state, registry, false)
	if not validation.ok: return _failure(ERR_STATE_INVALID, str(validation))
	var candidate := state.deep_clone()
	var channels_result := _reconcilable_channels(candidate)
	if not channels_result.ok: return _failure(channels_result.code, channels_result.get("developer_details", ""))
	var events := _initialize_available_sources(candidate, channels_result.channels, state.simulation_time_msec)
	if events.is_empty():
		return _success(AccessChangeSummary.new("", false, false, [], [], state.simulation_time_msec), [], false)
	var candidate_validation := GameStateValidator.validate(candidate, registry, true)
	if not candidate_validation.ok: return _failure(ERR_STATE_INVALID, str(candidate_validation))
	state.copy_from(candidate)
	events.sort_custom(_event_less)
	return _success(_summary("", false, false, events, state.simulation_time_msec), events, true)

func effective_source_identification(state: GameState, output_item_id: StringName) -> Array:
	var out: Array = []
	var channels_result := _authored_channels_for_item(str(output_item_id), false)
	if not channels_result.ok: return out
	for channel in channels_result.channels:
		if channel.progression_required and not state.progression.unlocked_output_item_ids.has(output_item_id): continue
		var tid := StringName(channel.source_threshold_id)
		if not state.thresholds.has(tid): continue
		var threshold = state.thresholds[tid]
		if str(threshold.availability_state) != "AVAILABLE" or not threshold.channel_acquisition.has(StringName(channel.id)): continue
		out.append({"threshold_id": channel.source_threshold_id, "channel_id": channel.id, "discovery_state": "CHARTED" if channel.initial_discovery_state == "CHARTED" else "IDENTIFIED"})
	out.sort_custom(func(a, b): return a.channel_id < b.channel_id)
	return out

static func validate_channel_relationship(content_registry: ContentRegistry, channel_id: String, expected_output_item_id := "", expected_source_threshold_id := "") -> Dictionary:
	var rec := content_registry.get_record(channel_id)
	if not rec.ok or rec.record.type != "channel": return _static_fail(ERR_CHANNEL_INVALID, "Channel is missing or is not a channel: %s" % channel_id)
	var channel: Dictionary = rec.record
	if not channel.enabled: return _static_fail(ERR_CHANNEL_INVALID, "Channel is disabled: %s" % channel_id)
	if expected_output_item_id != "" and channel.output_item_id != expected_output_item_id: return _static_fail(ERR_CHANNEL_INVALID, "Channel output does not match requested item: %s" % channel_id)
	var item := content_registry.get_record(channel.output_item_id)
	if not item.ok or item.record.type != "item": return _static_fail(ERR_ITEM_NOT_FOUND, "Channel output item is invalid: %s" % channel.output_item_id)
	if not item.record.enabled: return _static_fail(ERR_ITEM_DISABLED, "Channel output item is disabled: %s" % channel.output_item_id)
	if channel.output_item_id == ESSENCE_ID: return _static_fail(ERR_ESSENCE_EXCLUDED, "Essence channel is excluded from M04D1 access: %s" % channel_id)
	var threshold := content_registry.get_record(channel.source_threshold_id)
	if not threshold.ok or threshold.record.type != "threshold" or not threshold.record.enabled: return _static_fail(ERR_CHANNEL_OWNERSHIP_INVALID, "Source Threshold is invalid or disabled for channel: %s" % channel_id)
	if expected_source_threshold_id != "" and channel.source_threshold_id != expected_source_threshold_id: return _static_fail(ERR_CHANNEL_OWNERSHIP_INVALID, "Channel source_threshold_id does not match owner: %s" % channel_id)
	if not threshold.record.channel_ids.has(channel_id): return _static_fail(ERR_CHANNEL_OWNERSHIP_INVALID, "Source Threshold does not list channel: %s" % channel_id)
	return {"ok": true, "code": OK, "channel": channel}

func _validate_item_id(item_id: String) -> Dictionary:
	if item_id == ESSENCE_ID: return _static_fail(ERR_ESSENCE_EXCLUDED, "Essence is excluded from output access.")
	var rec := registry.get_record(item_id)
	if not rec.ok or rec.record.type != "item": return _static_fail(ERR_ITEM_NOT_FOUND, "Item is missing or not an item: %s" % item_id)
	if not rec.record.enabled: return _static_fail(ERR_ITEM_DISABLED, "Item is disabled: %s" % item_id)
	return {"ok": true, "code": OK}

func _authored_channels_for_item(item_id: String, strict: bool) -> Dictionary:
	var channels: Array = []
	for id in registry.ids():
		var rec := registry.get_record(id)
		if not rec.ok or rec.record.type != "channel": continue
		if rec.record.output_item_id != item_id: continue
		var valid := validate_channel_relationship(registry, id, item_id)
		if not valid.ok:
			if strict: return valid
			continue
		channels.append(valid.channel)
	channels.sort_custom(func(a, b): return a.id < b.id)
	return {"ok": true, "code": OK, "channels": channels}

func _reconcilable_channels(candidate: GameState) -> Dictionary:
	var channels: Array = []
	for id in registry.ids():
		var rec := registry.get_record(id)
		if not rec.ok or rec.record.type != "channel" or rec.record.output_item_id == ESSENCE_ID: continue
		var valid := validate_channel_relationship(registry, id)
		if not valid.ok: return valid
		var channel: Dictionary = valid.channel
		if not channel.progression_required or candidate.progression.unlocked_output_item_ids.has(StringName(channel.output_item_id)):
			channels.append(channel)
	channels.sort_custom(func(a, b): return a.id < b.id)
	return {"ok": true, "code": OK, "channels": channels}

func _initialize_available_sources(candidate: GameState, channels: Array, time_msec: int) -> Array[AccessEvent]:
	var events: Array[AccessEvent] = []
	for channel in channels:
		var threshold_id := StringName(channel.source_threshold_id)
		var channel_id := StringName(channel.id)
		if not candidate.thresholds.has(threshold_id): continue
		var threshold = candidate.thresholds[threshold_id]
		if str(threshold.availability_state) != "AVAILABLE" or threshold.channel_acquisition.has(channel_id): continue
		threshold.channel_acquisition[channel_id] = GameState.ThresholdAcquisitionState.new(0, 0, 0)
		events.append(_event(EVENT_SOURCE_IDENTIFIED, time_msec, 10, channel.output_item_id, channel.source_threshold_id, {"output_item_id": channel.output_item_id, "threshold_id": channel.source_threshold_id, "channel_id": channel.id}))
	return events

func _summary(item_id: String, access_added: bool, already_unlocked: bool, events: Array[AccessEvent], time_msec: int) -> AccessChangeSummary:
	var channels: Array[String] = []
	var thresholds: Array[String] = []
	for event in events:
		if event.event_type == EVENT_SOURCE_IDENTIFIED:
			channels.append(str(event.payload.channel_id))
			if not thresholds.has(str(event.payload.threshold_id)): thresholds.append(str(event.payload.threshold_id))
	return AccessChangeSummary.new(item_id, access_added, already_unlocked, channels, thresholds, time_msec)

func _event(type: String, time_msec: int, priority_value: int, subject: String, source: String, payload_value: Dictionary) -> AccessEvent:
	return AccessEvent.new(type, time_msec, priority_value, subject, source, payload_value)

func _success(summary: AccessChangeSummary, result_events: Array[AccessEvent], checkpoint: bool) -> AccessActionResult:
	var result := AccessActionResult.new()
	result.success = true
	result.error_code = OK
	result.player_message = ""
	result.developer_details = ""
	result.change_summary = summary
	result.events = result_events.duplicate()
	result.save_checkpoint_requested = checkpoint
	return result

func _failure(code: String, details: String) -> AccessActionResult:
	var result := AccessActionResult.new()
	result.success = false
	result.error_code = code
	result.player_message = "The output access request could not be completed."
	result.developer_details = details
	result.change_summary = null
	result.events = []
	result.save_checkpoint_requested = false
	return result

static func _event_less(a: AccessEvent, b: AccessEvent) -> bool:
	if a.occurred_simulation_msec != b.occurred_simulation_msec: return a.occurred_simulation_msec < b.occurred_simulation_msec
	if a.priority != b.priority: return a.priority < b.priority
	if a.source_id != b.source_id: return a.source_id < b.source_id
	return str(a.payload.get("channel_id", "")) < str(b.payload.get("channel_id", ""))

static func _static_fail(code: String, details: String) -> Dictionary:
	return {"ok": false, "code": code, "developer_details": details}
