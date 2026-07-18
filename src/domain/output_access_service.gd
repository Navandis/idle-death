class_name OutputAccessService
extends RefCounted

## Owns M04D1 output-item access commands and source reconciliation.
##
## Access is global by canonical output item ID and is stored in
## `ProgressionState.unlocked_output_item_ids`. Source-specific acquisition work
## is still owned by the matching Threshold's `channel_acquisition` map. This
## service bridges those two facts transactionally: it clones the state, adds or
## reconciles zeroed source records only for currently available Thresholds, and
## commits the candidate only after content-aware validation succeeds. It never
## reads clocks, advances simulation, grants inventory, or backfills progress.

const OK := "OK"
const ERR_STATE_INVALID := "OUTPUT_ACCESS_STATE_INVALID"
const ERR_ITEM_NOT_FOUND := "OUTPUT_ACCESS_ITEM_NOT_FOUND"
const ERR_ITEM_DISABLED := "OUTPUT_ACCESS_ITEM_DISABLED"
const ERR_NO_AUTHORED_SOURCE := "OUTPUT_ACCESS_NO_AUTHORED_SOURCE"
const ERR_CHANNEL_INVALID := "OUTPUT_ACCESS_CHANNEL_INVALID"
const ERR_CHANNEL_OWNERSHIP_INVALID := "OUTPUT_ACCESS_CHANNEL_OWNERSHIP_INVALID"
const ERR_ESSENCE_EXCLUDED := "OUTPUT_ACCESS_ESSENCE_EXCLUDED"
const EVENT_ITEM_UNLOCKED := "OUTPUT_ITEM_UNLOCKED"
const EVENT_SOURCE_IDENTIFIED := "OUTPUT_SOURCE_IDENTIFIED"
const ESSENCE_ID := "RES_ESSENCE"

var registry: ContentRegistry

func _init(content_registry: ContentRegistry) -> void:
	registry = content_registry

func unlock_output_item(state: GameState, output_item_id: StringName) -> Dictionary:
	var validation := GameStateValidator.validate(state, registry)
	if not validation.ok: return _fail(ERR_STATE_INVALID, validation)
	var item_check := _validate_item_id(str(output_item_id))
	if not item_check.ok: return item_check
	var channels := _authored_channels_for_item(str(output_item_id))
	if channels.is_empty(): return _fail(ERR_NO_AUTHORED_SOURCE)
	if state.progression.unlocked_output_item_ids.has(output_item_id):
		return _success([], [], false)
	var candidate := state.deep_clone()
	candidate.progression.unlocked_output_item_ids.append(output_item_id)
	candidate.progression.unlocked_output_item_ids.sort()
	var source_events := _initialize_available_sources(candidate, channels)
	var candidate_validation := GameStateValidator.validate(candidate, registry)
	if not candidate_validation.ok: return _fail(ERR_STATE_INVALID, candidate_validation)
	state.copy_from(candidate)
	var events := [{"event_id": EVENT_ITEM_UNLOCKED, "output_item_id": str(output_item_id)}]
	events.append_array(source_events)
	return _success(events, source_events, true)

func reconcile_available_sources(state: GameState) -> Dictionary:
	var validation := GameStateValidator.validate(state, registry)
	if not validation.ok: return _fail(ERR_STATE_INVALID, validation)
	var candidate := state.deep_clone()
	var events: Array = []
	for item_id in candidate.progression.unlocked_output_item_ids:
		events.append_array(_initialize_available_sources(candidate, _authored_channels_for_item(str(item_id))))
	if events.is_empty(): return _success([], [], false)
	var candidate_validation := GameStateValidator.validate(candidate, registry)
	if not candidate_validation.ok: return _fail(ERR_STATE_INVALID, candidate_validation)
	state.copy_from(candidate)
	return _success(events, events, true)

func effective_source_identification(state: GameState, output_item_id: StringName) -> Array:
	var out: Array = []
	if not state.progression.unlocked_output_item_ids.has(output_item_id): return out
	for channel in _authored_channels_for_item(str(output_item_id)):
		var tid := StringName(channel.source_threshold_id)
		if not state.thresholds.has(tid): continue
		var threshold = state.thresholds[tid]
		if str(threshold.availability_state) != "AVAILABLE" or not threshold.channel_acquisition.has(StringName(channel.id)): continue
		out.append({"threshold_id": channel.source_threshold_id, "channel_id": channel.id, "discovery_state": "CHARTED" if channel.initial_discovery_state == "CHARTED" else "IDENTIFIED"})
	out.sort_custom(func(a, b): return a.channel_id < b.channel_id)
	return out

func _validate_item_id(item_id: String) -> Dictionary:
	if item_id == ESSENCE_ID: return _fail(ERR_ESSENCE_EXCLUDED)
	var rec := registry.get_record(item_id)
	if not rec.ok or rec.record.type != "item": return _fail(ERR_ITEM_NOT_FOUND)
	if rec.record.has("enabled") and not rec.record.enabled: return _fail(ERR_ITEM_DISABLED)
	return {"ok": true, "code": OK}

func _authored_channels_for_item(item_id: String) -> Array:
	var channels: Array = []
	for id in registry.ids():
		var rec := registry.get_record(id)
		if rec.ok and rec.record.type == "channel" and rec.record.output_item_id == item_id and rec.record.output_item_id != ESSENCE_ID:
			channels.append(rec.record)
	channels.sort_custom(func(a, b): return a.id < b.id)
	return channels

func _initialize_available_sources(candidate: GameState, channels: Array) -> Array:
	var events: Array = []
	for channel in channels:
		var threshold_id := StringName(channel.source_threshold_id)
		var channel_id := StringName(channel.id)
		if not candidate.thresholds.has(threshold_id): continue
		var threshold = candidate.thresholds[threshold_id]
		if str(threshold.availability_state) != "AVAILABLE" or threshold.channel_acquisition.has(channel_id): continue
		threshold.channel_acquisition[channel_id] = GameState.ThresholdAcquisitionState.new(0, 0, 0)
		events.append({"event_id": EVENT_SOURCE_IDENTIFIED, "output_item_id": channel.output_item_id, "threshold_id": channel.source_threshold_id, "channel_id": channel.id})
	return events

func _success(events: Array, sources: Array, checkpoint: bool) -> Dictionary:
	return {"ok": true, "code": OK, "events": events, "summary": {"source_count": sources.size()}, "checkpoint_requested": checkpoint}

func _fail(code: String, diagnostic: Dictionary = {}) -> Dictionary:
	return {"ok": false, "code": code, "diagnostic": diagnostic, "events": [], "checkpoint_requested": false}
