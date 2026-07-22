class_name SimulationEngine
extends RefCounted

## Deterministic M04C/M04D2 elapsed-production resolver for one active Reaping.
##
## The engine owns online/offline/forecast-compatible arithmetic for the current
## single-Reaping slice only, including already-initialized eligible non-Essence
## Threshold channels. It mutates a deep-cloned GameState candidate,
## validates that candidate, and then replaces the live aggregate once so every
## failure preserves exact caller state. It does not own clocks, frame callbacks,
## Nodes, file I/O, Retinue effects, later presentation summaries, milestones, Writ transitions,
## discovery, tutorial state, offline trust, access/source initialization, output
## channel modifiers, ETA queries, or multi-Reaping concurrency. All
## elapsed input is explicit integer milliseconds; all fractional production uses
## FixedPoint.SCALE subunits and integer floor arithmetic.

const OK := &""
const ERR_NEGATIVE_ELAPSED := &"SIM_NEGATIVE_ELAPSED"
const ERR_STATE_INVALID := &"SIM_STATE_INVALID"
const ERR_UNSUPPORTED_CONCURRENCY := &"SIM_UNSUPPORTED_CONCURRENCY"
const ERR_UNSUPPORTED_RETINUE := &"SIM_UNSUPPORTED_RETINUE"
const ERR_UNSUPPORTED_FLOW := &"SIM_UNSUPPORTED_FLOW"
const ERR_CONTENT := &"SIM_CONTENT_INVALID"
const ERR_UNSUPPORTED_MODIFIER := &"SIM_UNSUPPORTED_MODIFIER"
const ERR_OVERFLOW := &"SIM_OVERFLOW"
const ERR_ZERO_BOUNDARY := &"SIM_ZERO_BOUNDARY"
const ERR_RESULT_INVALID := &"SIM_RESULT_INVALID"

const LIFECYCLE_OVERDUE := &"OVERDUE"
const LIFECYCLE_SETTLED := &"SETTLED"

const EVENT_THRESHOLD_SETTLED := &"THRESHOLD_SETTLED"
const EVENT_OUTPUT_CHANNEL_BANKED := &"OUTPUT_CHANNEL_BANKED"
const EVENT_PRIORITY_CHANNEL_GAIN := 100
const EVENT_PRIORITY_LIFECYCLE := 200
const SIMULATION_ENGINE_SOURCE_ID := &"SIMULATION_ENGINE"

const ACTIVE_CHANGE_SUMMARY_KEYS := [
	"Essence_delta",
	"Mastery_delta_subunits",
	"backlog_delta",
	"channel_deltas",
	"completed_cycles_delta",
	"lifecycle_after",
	"lifecycle_before",
	"operation_id",
	"returned_souls_delta",
	"simulation_time_delta_msec",
	"threshold_id",
]
const TIMELINE_CHANGE_SUMMARY_KEYS := ["simulation_time_delta_msec"]
const OUTPUT_CHANNEL_EVENT_PAYLOAD_KEYS := [
	"lifecycle_state",
	"output_item_id",
	"progress_subunits_after",
	"quantity",
	"total_banked_units",
]
const THRESHOLD_SETTLED_EVENT_PAYLOAD_KEYS := [
	"lifecycle_state",
	"persistent_returns_total",
	"remaining_backlog",
]

const FLOW_CORE_RETURNS_PROGRESS_SUBUNITS := CoreFlowKeys.RETURNS_PROGRESS
const FLOW_CORE_RETURNS_RATE_CARRY_UNITS := CoreFlowKeys.RETURNS_CARRY
const FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS := CoreFlowKeys.ESSENCE_PROGRESS
const FLOW_CORE_ESSENCE_RATE_CARRY_UNITS := CoreFlowKeys.ESSENCE_CARRY
const FLOW_CORE_MASTERY_RATE_CARRY_UNITS := CoreFlowKeys.MASTERY_CARRY
const CORE_FLOW_KEYS := CoreFlowKeys.ORDERED_KEYS

var registry: ContentRegistry
var rate_context: ReapingRateContextService

func _init(content_registry: ContentRegistry) -> void:
	registry = content_registry
	rate_context = ReapingRateContextService.new(content_registry)

## Resolves explicit elapsed milliseconds and commits only a fully validated candidate.
func resolve_elapsed(state: GameState, elapsed_msec: int) -> SimulationResult:
	if elapsed_msec < 0:
		return SimulationResult.failure(ERR_NEGATIVE_ELAPSED, elapsed_msec, "Elapsed milliseconds must be non-negative.")
	if elapsed_msec == 0:
		return SimulationResult.success_empty(elapsed_msec)
	var validation := GameStateValidator.validate(state, registry, true)
	if not validation.ok:
		return SimulationResult.failure(ERR_STATE_INVALID, elapsed_msec, str(validation))
	var active_ids := _active_reaping_ids(state)
	if active_ids.size() > 1:
		return SimulationResult.failure(ERR_UNSUPPORTED_CONCURRENCY, elapsed_msec, "M04C supports at most one active Reaping.")

	var candidate := state.deep_clone()
	var result := SimulationResult.new(true, OK, "", elapsed_msec)
	if active_ids.is_empty():
		var timeline := candidate.advance_simulation_time(elapsed_msec)
		if not timeline.ok: return SimulationResult.failure(ERR_OVERFLOW, elapsed_msec, str(timeline))
		result.committed_elapsed_msec = elapsed_msec
		result.change_summary["simulation_time_delta_msec"] = elapsed_msec
		return _commit_if_valid(state, candidate, result)

	var active_id: StringName = active_ids[0]
	var reaping: GameState.ReapingState = candidate.reapings[active_id]
	if not reaping.retinue_ids.is_empty():
		return SimulationResult.failure(ERR_UNSUPPORTED_RETINUE, elapsed_msec, "Retinues are deferred until after M04C.")
	var flow_check := _validate_core_flows(reaping)
	if not flow_check.ok:
		return SimulationResult.failure(StringName(flow_check.code), elapsed_msec, flow_check.details)

	var cursor := candidate.simulation_time_msec
	var remaining := elapsed_msec
	var transition_guard := 0
	while remaining > 0:
		transition_guard += 1
		if transition_guard > 2:
			return SimulationResult.failure(ERR_ZERO_BOUNDARY, elapsed_msec, "Exceeded bounded M04C settlement segmentation.")
		var threshold: GameState.ThresholdState = candidate.thresholds[active_id]
		var segment_msec := remaining
		var will_settle := false
		if str(threshold.lifecycle_state) == "OVERDUE" and threshold.remaining_backlog > 0:
			var boundary := _msec_to_next_return(reaping, active_id, threshold.remaining_backlog)
			if not boundary.ok: return SimulationResult.failure(StringName(boundary.code), elapsed_msec, boundary.details)
			if boundary.elapsed_msec <= 0: return SimulationResult.failure(ERR_ZERO_BOUNDARY, elapsed_msec, "Settlement boundary cannot advance time.")
			if boundary.elapsed_msec <= remaining:
				segment_msec = boundary.elapsed_msec
				will_settle = true
		var segment_end_msec := cursor + segment_msec
		var applied := _apply_segment(candidate, reaping, active_id, segment_msec, segment_end_msec)
		if not applied.ok: return SimulationResult.failure(StringName(applied.code), elapsed_msec, applied.details)
		cursor = segment_end_msec
		remaining -= segment_msec
		result.segments.append(SimulationSegmentResult.new(active_id, reaping.assignment_revision, reaping.form_id, reaping.writ_id, reaping.retinue_ids, StringName(applied.lifecycle), cursor - segment_msec, cursor, segment_msec, applied.returned_souls_delta, applied.backlog_reduced, applied.essence_delta, applied.mastery_delta_subunits, applied.completed_cycles_delta, applied.channel_deltas))
		for event in applied.events:
			result.events.append(event)
		if will_settle:
			threshold = candidate.thresholds[active_id]
			threshold.remaining_backlog = 0
			threshold.lifecycle_state = &"SETTLED"
			result.events.append(SimulationEvent.threshold_settled(cursor, active_id, threshold.persistent_returns_total))
	var timeline2 := candidate.advance_simulation_time(elapsed_msec)
	if not timeline2.ok: return SimulationResult.failure(ERR_OVERFLOW, elapsed_msec, str(timeline2))
	for event in result.events:
		if event.event_type == EVENT_THRESHOLD_SETTLED:
			event.payload["persistent_returns_total"] = candidate.thresholds[active_id].persistent_returns_total
	result.committed_elapsed_msec = elapsed_msec
	result.change_summary = _summary(state, candidate, active_id)
	result.events.sort_custom(_event_less)
	return _commit_if_valid(state, candidate, result)

func _apply_segment(state: GameState, reaping: GameState.ReapingState, threshold_id: StringName, elapsed_msec: int, segment_end_msec: int) -> Dictionary:
	var threshold: GameState.ThresholdState = state.thresholds[threshold_id]
	var form: GameState.FormState = state.forms[reaping.form_id]
	var before_returns: int = threshold.persistent_returns_total
	var before_backlog: int = threshold.remaining_backlog
	var before_essence: int = state.inventory.entries.get(&"RES_ESSENCE", GameState.InventoryEntryState.new()).total
	var before_mastery: int = form.mastery_subunits
	var before_cycles: int = reaping.completed_cycle_count
	var form_record: Dictionary = registry.get_record(str(reaping.form_id)).record
	var threshold_record: Dictionary = registry.get_record(str(threshold_id)).record
	var return_rate := _scaled_rate(form_record.base_returned_souls_rate, form_record.traits, threshold_record, "SOULS_RETURNED_RATE", str(threshold.lifecycle_state) == "SETTLED")
	if not return_rate.ok: return return_rate
	var essence_rate := _essence_rate(threshold_id, str(threshold.lifecycle_state) == "SETTLED", form_record.traits, threshold_record)
	if not essence_rate.ok: return essence_rate
	var mastery_rate := _scaled_rate(form_record.active_mastery_rate, form_record.traits, threshold_record, "MASTERY_RATE", false)
	if not mastery_rate.ok: return mastery_rate

	var returns := _accumulate_flow(reaping, FLOW_CORE_RETURNS_PROGRESS_SUBUNITS, FLOW_CORE_RETURNS_RATE_CARRY_UNITS, return_rate.rate, return_rate.period, elapsed_msec)
	if not returns.ok: return returns
	var whole_returns: int = returns.whole
	if threshold.persistent_returns_total > FixedPoint.INT64_MAX - whole_returns: return _fail(ERR_OVERFLOW, "persistent_returns_total")
	threshold.persistent_returns_total += whole_returns
	if str(threshold.lifecycle_state) == "OVERDUE":
		threshold.remaining_backlog = max(0, threshold.remaining_backlog - whole_returns)

	var essence := _accumulate_flow(reaping, FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS, FLOW_CORE_ESSENCE_RATE_CARRY_UNITS, essence_rate.rate, essence_rate.period, elapsed_msec)
	if not essence.ok: return essence
	var entry: GameState.InventoryEntryState = state.inventory.entries.get(&"RES_ESSENCE", GameState.InventoryEntryState.new())
	if entry.total > FixedPoint.INT64_MAX - int(essence.whole): return _fail(ERR_OVERFLOW, "RES_ESSENCE")
	entry.total += int(essence.whole)
	state.inventory.entries[&"RES_ESSENCE"] = entry

	var mastery := FixedPoint.accumulate_for_elapsed_msec(mastery_rate.rate, mastery_rate.period, elapsed_msec, int(reaping.flow_carry_units.get(FLOW_CORE_MASTERY_RATE_CARRY_UNITS, 0)))
	if not mastery.ok: return _fail(ERR_OVERFLOW, "mastery")
	if form.mastery_subunits > FixedPoint.INT64_MAX - int(mastery.produced_subunits): return _fail(ERR_OVERFLOW, "mastery")
	form.mastery_subunits += int(mastery.produced_subunits)
	reaping.flow_carry_units[FLOW_CORE_MASTERY_RATE_CARRY_UNITS] = int(mastery.carry_units)
	if form_record.cycle_duration_msec <= 0: return _fail(ERR_CONTENT, "cycle_duration_msec")
	if reaping.cycle_phase_msec > FixedPoint.INT64_MAX - elapsed_msec: return _fail(ERR_OVERFLOW, "cycle_phase_msec")
	var phase_total := reaping.cycle_phase_msec + elapsed_msec
	var completed := phase_total / int(form_record.cycle_duration_msec)
	if reaping.completed_cycle_count > FixedPoint.INT64_MAX - completed: return _fail(ERR_OVERFLOW, "completed_cycle_count")
	reaping.completed_cycle_count += completed
	reaping.cycle_phase_msec = phase_total % int(form_record.cycle_duration_msec)
	var channel_result := _apply_output_channels(state, threshold_id, reaping.form_id, reaping.writ_id, reaping.retinue_ids, elapsed_msec, segment_end_msec, str(threshold.lifecycle_state))
	if not channel_result.ok: return channel_result
	return {"ok": true, "lifecycle": str(threshold.lifecycle_state), "returned_souls_delta": threshold.persistent_returns_total - before_returns, "backlog_reduced": before_backlog - threshold.remaining_backlog, "essence_delta": state.inventory.entries.get(&"RES_ESSENCE", GameState.InventoryEntryState.new()).total - before_essence, "mastery_delta_subunits": form.mastery_subunits - before_mastery, "completed_cycles_delta": reaping.completed_cycle_count - before_cycles, "channel_deltas": channel_result.channel_deltas, "events": channel_result.events}


func _apply_output_channels(state: GameState, threshold_id: StringName, form_id: StringName, writ_id: StringName, retinue_ids: Array[StringName], elapsed_msec: int, segment_end_msec: int, lifecycle_state: String) -> Dictionary:
	var channels := _eligible_output_channels(state, threshold_id)
	if not channels.ok: return channels
	var deltas: Array[SimulationChannelDeltaResult] = []
	var events: Array[SimulationEvent] = []
	for channel in channels.channels:
		var acq: GameState.ThresholdAcquisitionState = state.thresholds[threshold_id].channel_acquisition[StringName(channel.id)]
		var before_progress := acq.progress_subunits
		var before_carry := acq.rate_carry_units
		var before_banked := acq.total_banked_units
		var rate := rate_context.output_channel_rate_plan(threshold_id, form_id, StringName(channel.id), lifecycle_state, writ_id, retinue_ids)
		if not rate.ok: return _fail(StringName(rate.code), rate.get("details", "channel rate"))
		var acc := FixedPoint.accumulate_for_elapsed_msec(int(rate.rate_subunits_per_period), int(rate.period_msec), elapsed_msec, acq.rate_carry_units)
		if not acc.ok: return _fail(ERR_OVERFLOW, "channel accumulation %s" % channel.id)
		var added := FixedPoint.add_subunits(acq.progress_subunits, int(acc.produced_subunits))
		if not added.ok: return _fail(ERR_OVERFLOW, "channel progress %s" % channel.id)
		var extracted := FixedPoint.extract_whole(int(added.subunits))
		var whole := int(extracted.whole_units)
		acq.progress_subunits = int(extracted.remaining_subunits)
		acq.rate_carry_units = int(acc.carry_units)
		if whole > 0:
			if acq.total_banked_units > FixedPoint.INT64_MAX - whole: return _fail(ERR_OVERFLOW, "channel total_banked_units %s" % channel.id)
			acq.total_banked_units += whole
			var item_id := StringName(channel.output_item_id)
			var entry: GameState.InventoryEntryState = state.inventory.entries.get(item_id, GameState.InventoryEntryState.new())
			if entry.total > FixedPoint.INT64_MAX - whole: return _fail(ERR_OVERFLOW, "inventory %s" % item_id)
			# Only the owned total changes. Reservation ledgers remain attached to the
			# same entry so banking cannot free or consume reserved Soldier Souls.
			entry.total += whole
			state.inventory.entries[item_id] = entry
		if before_progress != acq.progress_subunits or before_carry != acq.rate_carry_units or whole > 0:
			var delta := SimulationChannelDeltaResult.new(StringName(channel.id), StringName(channel.output_item_id), whole, before_progress, acq.progress_subunits, before_carry, acq.rate_carry_units, before_banked, acq.total_banked_units)
			deltas.append(delta)
			if whole > 0:
				# GameState.simulation_time_msec advances only after the transaction commits.
				# Use the loop's segment-end cursor so banked events in a post-Settlement
				# segment cannot sort before the Settlement event that enabled that segment.
				events.append(SimulationEvent.output_channel_banked(segment_end_msec, threshold_id, StringName(channel.id), delta, lifecycle_state))
	deltas.sort_custom(func(a, b): return str(a.channel_id) < str(b.channel_id))
	events.sort_custom(_event_less)
	return {"ok": true, "channel_deltas": deltas, "events": events}

func _eligible_output_channels(state: GameState, threshold_id: StringName) -> Dictionary:
	var threshold: GameState.ThresholdState = state.thresholds[threshold_id]
	var threshold_record: Dictionary = registry.get_record(str(threshold_id)).record
	var channels: Array = []
	# M04D2 deliberately consumes only source records that M04D1 already created.
	# Locked gated channels therefore have no residual to advance, and an eligible
	# missing source is rejected by strict GameState validation before this helper.
	for channel_id in threshold_record.channel_ids:
		var relationship := OutputAccessService.validate_channel_relationship(registry, str(channel_id), "", str(threshold_id))
		if not relationship.ok: continue # Essence is owned by the core flow path.
		var channel: Dictionary = relationship.channel
		if channel.progression_required and not state.progression.unlocked_output_item_ids.has(StringName(channel.output_item_id)):
			continue
		if threshold.channel_acquisition.has(StringName(channel.id)):
			channels.append(channel)
	channels.sort_custom(func(a, b): return str(a.id) < str(b.id))
	return {"ok": true, "channels": channels}

func _channel_rate(channel: Dictionary, lifecycle_state: String) -> Dictionary:
	var value := int(channel.rate.rate_subunits_per_period)
	if lifecycle_state == "SETTLED":
		# Channel Settlement is independent from the Threshold core multiplier. M04D3
		# will add prospective loadout modifiers; M04D2 uses authored baseline only.
		var settled := FixedPoint.multiply_scaled_floor(value, int(channel.settled_multiplier_subunits))
		if not settled.ok: return _fail(ERR_OVERFLOW, "channel settled multiplier %s" % channel.id)
		value = int(settled.subunits)
	return {"ok": true, "rate": value}

func _accumulate_flow(reaping: GameState.ReapingState, progress_key: StringName, carry_key: StringName, rate: int, period: int, elapsed_msec: int) -> Dictionary:
	var acc := FixedPoint.accumulate_for_elapsed_msec(rate, period, elapsed_msec, int(reaping.flow_carry_units.get(carry_key, 0)))
	if not acc.ok: return _fail(ERR_OVERFLOW, str(acc))
	var progress := int(reaping.flow_carry_units.get(progress_key, 0))
	var added := FixedPoint.add_subunits(progress, int(acc.produced_subunits))
	if not added.ok: return _fail(ERR_OVERFLOW, progress_key)
	var extracted := FixedPoint.extract_whole(int(added.subunits))
	reaping.flow_carry_units[progress_key] = int(extracted.remaining_subunits)
	reaping.flow_carry_units[carry_key] = int(acc.carry_units)
	return {"ok": true, "whole": int(extracted.whole_units)}

func _msec_to_next_return(reaping: GameState.ReapingState, threshold_id: StringName, needed_returns: int) -> Dictionary:
	var form_record: Dictionary = registry.get_record(str(reaping.form_id)).record
	var threshold_record: Dictionary = registry.get_record(str(threshold_id)).record
	var rate := _scaled_rate(form_record.base_returned_souls_rate, form_record.traits, threshold_record, "SOULS_RETURNED_RATE", false)
	if not rate.ok: return rate
	return _search_return_boundary(reaping, needed_returns, int(rate.rate), int(rate.period))

func _scaled_rate(rate: Dictionary, traits: Array, threshold_record: Dictionary, metric: String, apply_settled: bool) -> Dictionary:
	var value := int(rate.rate_subunits_per_period)
	var modified := _apply_trait_multipliers(value, traits, threshold_record, metric)
	if not modified.ok: return modified
	value = int(modified.rate)
	if apply_settled:
		var settled := FixedPoint.multiply_scaled_floor(value, int(threshold_record.settled_multiplier_subunits))
		if not settled.ok: return _fail(ERR_OVERFLOW, "settled multiplier")
		value = int(settled.subunits)
	return {"ok": true, "rate": value, "period": int(rate.period_msec)}

func _apply_trait_multipliers(base_rate: int, traits: Array, threshold_record: Dictionary, metric: String) -> Dictionary:
	var value := base_rate
	for trait_record in traits:
		for modifier in trait_record.modifiers:
			if modifier.metric != metric: continue
			if modifier.operation != "MULTIPLY" or modifier.scope != "REAPING_TOTAL": return _fail(ERR_UNSUPPORTED_MODIFIER, str(modifier))
			match modifier.condition:
				"ALWAYS":
					var always_scaled := FixedPoint.multiply_scaled_floor(value, int(modifier.value_subunits))
					if not always_scaled.ok: return _fail(ERR_OVERFLOW, "trait multiplier")
					value = int(always_scaled.subunits)
				"THRESHOLD_HAS_ANY_TAG":
					if _has_any(threshold_record.tags, modifier.condition_values):
						var tag_scaled := FixedPoint.multiply_scaled_floor(value, int(modifier.value_subunits))
						if not tag_scaled.ok: return _fail(ERR_OVERFLOW, "trait multiplier")
						value = int(tag_scaled.subunits)
				_:
					return _fail(ERR_UNSUPPORTED_MODIFIER, str(modifier))
	return {"ok": true, "rate": value}

func _essence_rate(threshold_id: StringName, settled: bool, traits: Array, threshold_record: Dictionary) -> Dictionary:
	var essence_channel := CoreFlowKeys.find_single_essence_channel(registry, threshold_id, threshold_record)
	if not essence_channel.ok: return _fail(ERR_CONTENT, essence_channel.get("field_path", "RES_ESSENCE"))
	var channel: Dictionary = essence_channel.channel
	var value := int(channel.rate.rate_subunits_per_period)
	var modified := _apply_trait_multipliers(value, traits, threshold_record, "ESSENCE_YIELD")
	if not modified.ok: return modified
	value = int(modified.rate)
	if settled:
		var settled_value := FixedPoint.multiply_scaled_floor(value, int(channel.settled_multiplier_subunits))
		if not settled_value.ok: return _fail(ERR_OVERFLOW, "essence settled multiplier")
		value = int(settled_value.subunits)
	return {"ok": true, "rate": value, "period": int(channel.rate.period_msec)}

func _search_return_boundary(reaping: GameState.ReapingState, needed_returns: int, rate: int, period: int) -> Dictionary:
	if needed_returns <= 0:
		return {"ok": true, "elapsed_msec": 1}
	if rate <= 0 or period <= 0:
		return _fail(ERR_ZERO_BOUNDARY, "non-positive return rate")
	var high := 1
	while true:
		var produced := _whole_returns_after_elapsed(reaping, rate, period, high)
		if not produced.ok: return produced
		if int(produced.whole) >= needed_returns: break
		if high > FixedPoint.INT64_MAX / 2: return _fail(ERR_OVERFLOW, "settlement boundary search")
		high *= 2
	var low := 0
	while high - low > 1:
		var mid := low + ((high - low) / 2)
		var mid_produced := _whole_returns_after_elapsed(reaping, rate, period, mid)
		if not mid_produced.ok: return mid_produced
		if int(mid_produced.whole) >= needed_returns:
			high = mid
		else:
			low = mid
	return {"ok": true, "elapsed_msec": high}

func _whole_returns_after_elapsed(reaping: GameState.ReapingState, rate: int, period: int, elapsed_msec: int) -> Dictionary:
	var acc := FixedPoint.accumulate_for_elapsed_msec(rate, period, elapsed_msec, int(reaping.flow_carry_units.get(FLOW_CORE_RETURNS_RATE_CARRY_UNITS, 0)))
	if not acc.ok: return _fail(ERR_OVERFLOW, "return boundary accumulation")
	var added := FixedPoint.add_subunits(int(reaping.flow_carry_units.get(FLOW_CORE_RETURNS_PROGRESS_SUBUNITS, 0)), int(acc.produced_subunits))
	if not added.ok: return _fail(ERR_OVERFLOW, "return boundary progress")
	var extracted := FixedPoint.extract_whole(int(added.subunits))
	return {"ok": true, "whole": int(extracted.whole_units)}

func _validate_core_flows(reaping: GameState.ReapingState) -> Dictionary:
	for key in reaping.flow_carry_units.keys():
		if not CORE_FLOW_KEYS.has(key) and int(reaping.flow_carry_units[key]) != 0:
			return _fail(ERR_UNSUPPORTED_FLOW, "Unknown nonzero flow key: %s" % key)
	return {"ok": true}

func _commit_if_valid(live: GameState, candidate: GameState, result: SimulationResult) -> SimulationResult:
	var result_validation: Dictionary = validate_result(result, live.simulation_time_msec, candidate.simulation_time_msec, result.requested_elapsed_msec, not _active_reaping_ids(candidate).is_empty())
	if not result_validation["ok"]: return SimulationResult.failure(ERR_RESULT_INVALID, result.requested_elapsed_msec, result_validation["details"])
	var coherence: Dictionary = _validate_result_transition_coherence(live, candidate, result)
	if not coherence["ok"]: return SimulationResult.failure(ERR_RESULT_INVALID, result.requested_elapsed_msec, coherence["details"])
	var validation := GameStateValidator.validate(candidate, registry, true)
	if not validation.ok: return SimulationResult.failure(ERR_STATE_INVALID, result.requested_elapsed_msec, str(validation))
	live.copy_from(candidate)
	return result

func _active_reaping_ids(state: GameState) -> Array[StringName]:
	var ids: Array[StringName] = []
	for id in state.reapings.keys():
		if state.reapings[id].is_active: ids.append(id)
	ids.sort_custom(func(a, b): return str(a) < str(b))
	return ids

func _summary(before: GameState, after: GameState, threshold_id: StringName) -> Dictionary:
	var before_threshold: GameState.ThresholdState = before.thresholds[threshold_id]
	var after_threshold: GameState.ThresholdState = after.thresholds[threshold_id]
	var form_id: StringName = after.reapings[threshold_id].form_id
	var channel_deltas := _overall_channel_deltas(before_threshold, after_threshold)
	return {"threshold_id": str(threshold_id), "operation_id": str(threshold_id), "simulation_time_delta_msec": after.simulation_time_msec - before.simulation_time_msec, "returned_souls_delta": after_threshold.persistent_returns_total - before_threshold.persistent_returns_total, "backlog_delta": after_threshold.remaining_backlog - before_threshold.remaining_backlog, "Essence_delta": after.inventory.entries.get(&"RES_ESSENCE", GameState.InventoryEntryState.new()).total - before.inventory.entries.get(&"RES_ESSENCE", GameState.InventoryEntryState.new()).total, "Mastery_delta_subunits": after.forms[form_id].mastery_subunits - before.forms[form_id].mastery_subunits, "completed_cycles_delta": after.reapings[threshold_id].completed_cycle_count - before.reapings[threshold_id].completed_cycle_count, "lifecycle_before": str(before_threshold.lifecycle_state), "lifecycle_after": str(after_threshold.lifecycle_state), "channel_deltas": channel_deltas}


func _overall_channel_deltas(before_threshold: GameState.ThresholdState, after_threshold: GameState.ThresholdState) -> Array:
	var deltas: Array = []
	var ids := after_threshold.channel_acquisition.keys()
	ids.sort_custom(func(a, b): return str(a) < str(b))
	for channel_id in ids:
		if not before_threshold.channel_acquisition.has(channel_id): continue
		var before: GameState.ThresholdAcquisitionState = before_threshold.channel_acquisition[channel_id]
		var after: GameState.ThresholdAcquisitionState = after_threshold.channel_acquisition[channel_id]
		var banked_delta := after.total_banked_units - before.total_banked_units
		if before.progress_subunits == after.progress_subunits and before.rate_carry_units == after.rate_carry_units and banked_delta == 0:
			continue
		var channel: Dictionary = registry.get_record(str(channel_id)).record
		deltas.append(SimulationChannelDeltaResult.new(channel_id, StringName(channel.output_item_id), banked_delta, before.progress_subunits, after.progress_subunits, before.rate_carry_units, after.rate_carry_units, before.total_banked_units, after.total_banked_units))
	return deltas

func _event_less(a: SimulationEvent, b: SimulationEvent) -> bool:
	if a.occurred_simulation_msec != b.occurred_simulation_msec: return a.occurred_simulation_msec < b.occurred_simulation_msec
	if a.priority != b.priority: return a.priority < b.priority
	if str(a.subject_id) != str(b.subject_id): return str(a.subject_id) < str(b.subject_id)
	return str(a.source_id) < str(b.source_id)

func _has_any(left: Array, right: Array) -> bool:
	for value in right:
		if left.has(value): return true
	return false

func _fail(code: StringName, details: String) -> Dictionary:
	return {"ok": false, "code": code, "details": details}

func validate_result(result: SimulationResult, baseline_simulation_time_msec: int, result_simulation_time_msec: int, requested_elapsed_msec: int, active_candidate_resolved: bool = false) -> Dictionary:
	if result == null: return _fail(ERR_RESULT_INVALID, "SimulationResult is null.")
	if result.requested_elapsed_msec != requested_elapsed_msec:
		return _fail(ERR_RESULT_INVALID, "SimulationResult requested_elapsed_msec must match the validator request.")
	if not result.success:
		return _validate_failed_result_shape(result)
	if result.error_code != OK:
		return _fail(ERR_RESULT_INVALID, "Successful results must carry the OK error code.")
	if requested_elapsed_msec < 0:
		return _fail(ERR_RESULT_INVALID, "Successful results cannot carry negative requested elapsed.")
	if requested_elapsed_msec == 0:
		return _validate_zero_duration_result_shape(result, baseline_simulation_time_msec, result_simulation_time_msec)
	if result.committed_elapsed_msec != requested_elapsed_msec:
		return _fail(ERR_RESULT_INVALID, "Committed elapsed must equal requested elapsed.")
	var cursor_delta := _checked_non_negative_difference(result_simulation_time_msec, baseline_simulation_time_msec, "result cursor delta")
	if not cursor_delta["ok"]: return cursor_delta
	if int(cursor_delta.value) != requested_elapsed_msec:
		return _fail(ERR_RESULT_INVALID, "Result cursor does not match requested elapsed.")
	if result.segments.is_empty():
		if active_candidate_resolved:
			return _fail(ERR_RESULT_INVALID, "Active committed results must include typed segments.")
		return _validate_timeline_only_result(result, requested_elapsed_msec)
	if not active_candidate_resolved:
		return _fail(ERR_RESULT_INVALID, "Positive segment-bearing results require an active candidate operation.")
	var segment_check := _validate_active_segment_grammar(result.segments, baseline_simulation_time_msec, result_simulation_time_msec, requested_elapsed_msec)
	if not segment_check["ok"]: return segment_check
	var events_check := _validate_events_for_segments(result.segments, result.events)
	if not events_check["ok"]: return events_check
	return _validate_active_change_summary(result, requested_elapsed_msec)

func _validate_timeline_only_result(result: SimulationResult, requested_elapsed_msec: int) -> Dictionary:
	if result.committed_elapsed_msec != requested_elapsed_msec:
		return _fail(ERR_RESULT_INVALID, "Timeline-only committed elapsed must equal requested elapsed.")
	if not result.events.is_empty():
		return _fail(ERR_RESULT_INVALID, "Timeline-only results cannot carry events.")
	if not _dictionary_has_exact_keys(result.change_summary, TIMELINE_CHANGE_SUMMARY_KEYS):
		return _fail(ERR_RESULT_INVALID, "Timeline-only summary must contain exactly simulation_time_delta_msec.")
	if typeof(result.change_summary.simulation_time_delta_msec) != TYPE_INT:
		return _fail(ERR_RESULT_INVALID, "Timeline-only simulation_time_delta_msec must be an int.")
	if int(result.change_summary.simulation_time_delta_msec) != requested_elapsed_msec:
		return _fail(ERR_RESULT_INVALID, "Timeline-only summary must contain the exact simulation-time delta.")
	return {"ok": true}

func _validate_failed_result_shape(result: SimulationResult) -> Dictionary:
	if result.error_code == OK or str(result.error_code).is_empty():
		return _fail(ERR_RESULT_INVALID, "Failed results must carry a non-empty non-OK error code.")
	if result.developer_details.strip_edges().is_empty():
		return _fail(ERR_RESULT_INVALID, "Failed results must carry stable developer_details.")
	if result.committed_elapsed_msec != 0:
		return _fail(ERR_RESULT_INVALID, "Failed results cannot carry committed elapsed authority.")
	if not result.segments.is_empty() or not result.events.is_empty():
		return _fail(ERR_RESULT_INVALID, "Failed results cannot carry committed segment or event authority.")
	if not result.change_summary.is_empty():
		return _fail(ERR_RESULT_INVALID, "Failed results cannot carry diagnostic summary authority.")
	return {"ok": true}

func _validate_zero_duration_result_shape(result: SimulationResult, baseline_simulation_time_msec: int, result_simulation_time_msec: int) -> Dictionary:
	if result.committed_elapsed_msec != 0:
		return _fail(ERR_RESULT_INVALID, "Zero-duration success must commit zero elapsed.")
	if baseline_simulation_time_msec != result_simulation_time_msec:
		return _fail(ERR_RESULT_INVALID, "Zero-duration success cannot advance the simulation cursor.")
	if not result.segments.is_empty() or not result.events.is_empty():
		return _fail(ERR_RESULT_INVALID, "Zero-duration success cannot carry segment or event authority.")
	if not result.change_summary.is_empty():
		return _fail(ERR_RESULT_INVALID, "Zero-duration success cannot carry change_summary authority.")
	return {"ok": true}

func _validate_active_segment_grammar(segments: Array[SimulationSegmentResult], baseline_simulation_time_msec: int, result_simulation_time_msec: int, requested_elapsed_msec: int) -> Dictionary:
	if segments.size() > 2:
		return _fail(ERR_RESULT_INVALID, "Active results may contain at most two segments under the current one-Reaping engine.")
	var first: SimulationSegmentResult = segments[0]
	if first == null:
		return _fail(ERR_RESULT_INVALID, "Segments cannot contain null entries.")
	var sum := 0
	var expected_start := baseline_simulation_time_msec
	for i in range(segments.size()):
		var segment: SimulationSegmentResult = segments[i]
		if segment == null:
			return _fail(ERR_RESULT_INVALID, "Segments cannot contain null entries.")
		var identity_check := _validate_segment_content_identity(segment)
		if not identity_check["ok"]: return identity_check
		var contract_check := _channel_contracts_for_segment(segment)
		if not contract_check["ok"]: return contract_check
		var local: Dictionary = segment.validate(contract_check.contracts)
		if not local["ok"]: return local
		if segment.start_simulation_msec != expected_start:
			return _fail(ERR_RESULT_INVALID, "Segments must be ordered and contiguous from the baseline cursor.")
		if segment.threshold_id != first.threshold_id or segment.assignment_revision != first.assignment_revision or segment.form_id != first.form_id or segment.writ_id != first.writ_id or segment.ordered_retinue_ids != first.ordered_retinue_ids:
			return _fail(ERR_RESULT_INVALID, "Assignment identity changed inside one committed run.")
		if i == 1 and (segments[0].lifecycle_state != LIFECYCLE_OVERDUE or segment.lifecycle_state != LIFECYCLE_SETTLED):
			return _fail(ERR_RESULT_INVALID, "Two-segment active results must be OVERDUE followed by SETTLED.")
		var elapsed_sum := _checked_add_non_negative(sum, segment.elapsed_msec, "segment elapsed sum")
		if not elapsed_sum["ok"]: return elapsed_sum
		sum = int(elapsed_sum.value)
		expected_start = segment.end_simulation_msec
		if i > 0:
			var continuity := _validate_cross_segment_channel_continuity(segments[i - 1], segment)
			if not continuity["ok"]: return continuity
	if segments.size() == 1 and segments[0].lifecycle_state != LIFECYCLE_OVERDUE and segments[0].lifecycle_state != LIFECYCLE_SETTLED:
		return _fail(ERR_RESULT_INVALID, "Single-segment active results must be OVERDUE or SETTLED.")
	if expected_start != result_simulation_time_msec:
		return _fail(ERR_RESULT_INVALID, "Final segment end must equal the committed result cursor.")
	if sum != requested_elapsed_msec:
		return _fail(ERR_RESULT_INVALID, "Segment elapsed sum must equal the committed elapsed duration.")
	return {"ok": true}

func _validate_segment_content_identity(segment: SimulationSegmentResult) -> Dictionary:
	var threshold_record := _get_enabled_content_record(segment.threshold_id, "threshold", "segment Threshold")
	if not threshold_record["ok"]: return threshold_record
	var form_record := _get_enabled_content_record(segment.form_id, "form", "segment Form")
	if not form_record["ok"]: return form_record
	var writ_record := _get_enabled_content_record(segment.writ_id, "writ", "segment Writ")
	if not writ_record["ok"]: return writ_record
	for retinue_id in segment.ordered_retinue_ids:
		var retinue_record := _get_enabled_content_record(retinue_id, "retinue", "segment Retinue")
		if not retinue_record["ok"]: return retinue_record
	var threshold_channels: Array = threshold_record.record.channel_ids
	for delta in segment.channel_deltas:
		if delta == null:
			return _fail(ERR_RESULT_INVALID, "Segment channel deltas cannot contain null entries.")
		if not threshold_channels.has(str(delta.channel_id)):
			return _fail(ERR_RESULT_INVALID, "Segment channel must be authored on the owning Threshold.")
		var channel_record := _get_enabled_content_record(delta.channel_id, "channel", "segment channel")
		if not channel_record["ok"]: return channel_record
		if str(channel_record.record.source_threshold_id) != str(segment.threshold_id):
			return _fail(ERR_RESULT_INVALID, "Segment channel source Threshold must match the segment Threshold.")
		var output_item_record := _get_enabled_content_record(delta.output_item_id, "item", "segment channel output item")
		if not output_item_record["ok"]: return output_item_record
		if StringName(channel_record.record.output_item_id) != delta.output_item_id:
			return _fail(ERR_RESULT_INVALID, "Segment channel output item must match the authored channel output.")
	return {"ok": true}

func _validate_events_for_segments(segments: Array[SimulationSegmentResult], events: Array[SimulationEvent]) -> Dictionary:
	var previous: SimulationEvent = null
	var bank_event_counts := {}
	var settlement_segment_index := -1
	var settlement_count := 0
	for event in events:
		if event == null:
			return _fail(ERR_RESULT_INVALID, "Simulation events cannot contain null entries.")
		var event_check: Dictionary = event.validate()
		if not event_check["ok"]: return event_check
		if previous != null and _event_less(event, previous):
			return _fail(ERR_RESULT_INVALID, "Events must be in stable simulation-time, priority, subject, source order.")
		previous = event
		var owning_index := _owning_segment_index(segments, event)
		if event.reportable and owning_index < 0:
			return _fail(ERR_RESULT_INVALID, "Event marked reportable must belong to exactly one segment.")
		if not event.reportable:
			var diagnostic_shape := _validate_known_event_shape(event)
			if not diagnostic_shape["ok"]: return diagnostic_shape
			continue
		var owning: SimulationSegmentResult = segments[owning_index]
		var coherence := _validate_event_matches_segment(owning, event)
		if not coherence["ok"]: return coherence
		match event.event_type:
			EVENT_OUTPUT_CHANNEL_BANKED:
				var bank_key := _segment_event_key(owning_index, event.source_id)
				bank_event_counts[bank_key] = int(bank_event_counts.get(bank_key, 0)) + 1
				if int(bank_event_counts[bank_key]) > 1:
					return _fail(ERR_RESULT_INVALID, "Positive channel banking may emit only one bank event per segment/channel delta.")
			EVENT_THRESHOLD_SETTLED:
				settlement_count += 1
				if settlement_count > 1:
					return _fail(ERR_RESULT_INVALID, "A committed result may emit at most one Settlement event.")
				settlement_segment_index = owning_index
	for segment_index in range(segments.size()):
		var segment: SimulationSegmentResult = segments[segment_index]
		for delta in segment.channel_deltas:
			var bank_count := int(bank_event_counts.get(_segment_event_key(segment_index, delta.channel_id), 0))
			if delta.banked_units_delta > 0 and bank_count != 1:
				return _fail(ERR_RESULT_INVALID, "Every positive-banking channel delta must emit exactly one OUTPUT_CHANNEL_BANKED event.")
			if delta.banked_units_delta == 0 and bank_count != 0:
				return _fail(ERR_RESULT_INVALID, "Progress-only channel deltas cannot emit bank events.")
	if segments.size() == 2:
		if settlement_count != 1 or settlement_segment_index != 0:
			return _fail(ERR_RESULT_INVALID, "Two-segment OVERDUE->SETTLED runs require exactly one Settlement event at the Overdue segment end.")
	elif segments[0].lifecycle_state == LIFECYCLE_SETTLED and settlement_count != 0:
		return _fail(ERR_RESULT_INVALID, "Already-settled single-segment runs cannot emit Settlement events.")
	return {"ok": true}

func _owning_segment_index(segments: Array[SimulationSegmentResult], event: SimulationEvent) -> int:
	var owned_index := -1
	for i in range(segments.size()):
		var segment: SimulationSegmentResult = segments[i]
		if segment.start_simulation_msec < event.occurred_simulation_msec and event.occurred_simulation_msec <= segment.end_simulation_msec:
			if owned_index != -1:
				return -1
			owned_index = i
	return owned_index

func _validate_event_matches_segment(segment: SimulationSegmentResult, event: SimulationEvent) -> Dictionary:
	match event.event_type:
		EVENT_OUTPUT_CHANNEL_BANKED:
			if not event.reportable or not event.tutorial_relevant:
				return _fail(ERR_RESULT_INVALID, "OUTPUT_CHANNEL_BANKED must use the canonical reportable/tutorial flags.")
			if event.priority != EVENT_PRIORITY_CHANNEL_GAIN:
				return _fail(ERR_RESULT_INVALID, "OUTPUT_CHANNEL_BANKED must use the canonical channel-gain priority.")
			if event.subject_id != segment.threshold_id:
				return _fail(ERR_RESULT_INVALID, "Output-channel event subject must match owning segment Threshold.")
			if event.occurred_simulation_msec != segment.end_simulation_msec:
				return _fail(ERR_RESULT_INVALID, "Output-channel events must occur at the owning segment end.")
			var payload_check := _validate_output_channel_event_payload(event.payload)
			if not payload_check["ok"]: return payload_check
			for delta in segment.channel_deltas:
				if delta.channel_id != event.source_id:
					continue
				if delta.banked_units_delta <= 0:
					return _fail(ERR_RESULT_INVALID, "Output-channel event cannot reference a progress-only delta.")
				if event.payload.get("output_item_id", &"") != delta.output_item_id:
					return _fail(ERR_RESULT_INVALID, "Output-channel event output item must match the channel delta.")
				if int(event.payload.get("quantity", -1)) != delta.banked_units_delta:
					return _fail(ERR_RESULT_INVALID, "Output-channel event quantity must match the channel delta.")
				if str(event.payload.get("lifecycle_state", "")) != str(segment.lifecycle_state):
					return _fail(ERR_RESULT_INVALID, "Output-channel event lifecycle_state must match the owning segment lifecycle.")
				if int(event.payload.get("total_banked_units", -1)) != delta.total_banked_units_after:
					return _fail(ERR_RESULT_INVALID, "Output-channel event total must match the channel delta endpoint.")
				if int(event.payload.get("progress_subunits_after", -1)) != delta.progress_subunits_after:
					return _fail(ERR_RESULT_INVALID, "Output-channel event progress endpoint must match the channel delta endpoint.")
				return {"ok": true}
			return _fail(ERR_RESULT_INVALID, "Output-channel event source must match a banked channel delta in its segment.")
		EVENT_THRESHOLD_SETTLED:
			if not event.reportable or not event.tutorial_relevant:
				return _fail(ERR_RESULT_INVALID, "THRESHOLD_SETTLED must use the canonical reportable/tutorial flags.")
			if event.priority != EVENT_PRIORITY_LIFECYCLE:
				return _fail(ERR_RESULT_INVALID, "THRESHOLD_SETTLED must use the canonical lifecycle priority.")
			if segment.lifecycle_state != LIFECYCLE_OVERDUE:
				return _fail(ERR_RESULT_INVALID, "Settlement events must belong to an OVERDUE segment.")
			if event.subject_id != segment.threshold_id or event.source_id != SIMULATION_ENGINE_SOURCE_ID:
				return _fail(ERR_RESULT_INVALID, "Settlement event identity must match owning segment Threshold.")
			if event.occurred_simulation_msec != segment.end_simulation_msec:
				return _fail(ERR_RESULT_INVALID, "Settlement event must occur at the owning segment end.")
			var payload_shape := _validate_threshold_settled_event_payload(event.payload)
			if not payload_shape["ok"]: return payload_shape
			if str(event.payload.get("lifecycle_state", "")) != "SETTLED" or int(event.payload.get("remaining_backlog", -1)) != 0:
				return _fail(ERR_RESULT_INVALID, "Settlement event payload must describe the Settled endpoint.")
			return {"ok": true}
		_:
			return _fail(ERR_RESULT_INVALID, "Unknown simulation event types are not allowed in the committed result grammar.")

func _validate_active_change_summary(result: SimulationResult, requested_elapsed_msec: int) -> Dictionary:
	var summary := result.change_summary
	if not _dictionary_has_exact_keys(summary, ACTIVE_CHANGE_SUMMARY_KEYS):
		return _fail(ERR_RESULT_INVALID, "Active results must use the exact active change_summary key set.")
	if typeof(summary.threshold_id) != TYPE_STRING or summary.threshold_id == "":
		return _fail(ERR_RESULT_INVALID, "Active summary threshold_id must be a non-empty String.")
	if typeof(summary.operation_id) != TYPE_STRING or summary.operation_id == "":
		return _fail(ERR_RESULT_INVALID, "Active summary operation_id must be a non-empty String.")
	if typeof(summary.lifecycle_before) != TYPE_STRING or typeof(summary.lifecycle_after) != TYPE_STRING:
		return _fail(ERR_RESULT_INVALID, "Active summary lifecycle fields must be Strings.")
	for key in ["simulation_time_delta_msec", "returned_souls_delta", "backlog_delta", "Essence_delta", "Mastery_delta_subunits", "completed_cycles_delta"]:
		if typeof(summary[key]) != TYPE_INT:
			return _fail(ERR_RESULT_INVALID, "Active summary %s must be an int." % key)
	if not (summary.channel_deltas is Array):
		return _fail(ERR_RESULT_INVALID, "Active summary channel_deltas must be an Array.")
	if int(summary.simulation_time_delta_msec) != requested_elapsed_msec:
		return _fail(ERR_RESULT_INVALID, "Summary simulation-time delta mismatch.")
	var totals := _aggregate_segments(result.segments)
	if not totals["ok"]: return totals
	for key in ["returned_souls_delta", "Essence_delta", "Mastery_delta_subunits", "completed_cycles_delta"]:
		if summary.has(key) and int(summary[key]) != int(totals[key]):
			return _fail(ERR_RESULT_INVALID, "Summary %s mismatch." % key)
	if summary.has("backlog_delta") and int(summary.backlog_delta) != -int(totals.backlog_reduced):
		return _fail(ERR_RESULT_INVALID, "Summary backlog_delta mismatch.")
	if str(summary.threshold_id) != str(result.segments[0].threshold_id) or str(summary.operation_id) != str(result.segments[0].threshold_id):
		return _fail(ERR_RESULT_INVALID, "Active summary threshold and operation IDs must match the owning Threshold.")
	if summary.has("lifecycle_before") and str(summary.lifecycle_before) != str(result.segments[0].lifecycle_state):
		return _fail(ERR_RESULT_INVALID, "Summary lifecycle_before mismatch.")
	if summary.has("lifecycle_after") and str(summary.lifecycle_after) != str(_result_lifecycle_after(result)):
		return _fail(ERR_RESULT_INVALID, "Summary lifecycle_after mismatch.")
	if summary.has("channel_deltas"):
		var summary_channels: Array = summary.channel_deltas
		var aggregate_channels: Array[SimulationChannelDeltaResult] = totals.channel_deltas
		if summary_channels.size() != aggregate_channels.size():
			return _fail(ERR_RESULT_INVALID, "Summary channel_deltas size mismatch.")
		for i in range(summary_channels.size()):
			if summary_channels[i] == null or not (summary_channels[i] is SimulationChannelDeltaResult):
				return _fail(ERR_RESULT_INVALID, "Active summary channel_deltas must contain SimulationChannelDeltaResult values.")
			if not _channel_delta_fields_equal(summary_channels[i], aggregate_channels[i]):
				return _fail(ERR_RESULT_INVALID, "Summary channel_deltas mismatch.")
	return {"ok": true}

func _result_lifecycle_after(result: SimulationResult) -> StringName:
	var last: SimulationSegmentResult = result.segments[result.segments.size() - 1]
	for event in result.events:
		if event.event_type == EVENT_THRESHOLD_SETTLED and event.subject_id == last.threshold_id and event.occurred_simulation_msec == last.end_simulation_msec:
			return LIFECYCLE_SETTLED
	return last.lifecycle_state

func _aggregate_segments(segments: Array[SimulationSegmentResult]) -> Dictionary:
	var totals := {"ok": true, "returned_souls_delta": 0, "backlog_reduced": 0, "Essence_delta": 0, "Mastery_delta_subunits": 0, "completed_cycles_delta": 0, "channel_deltas": []}
	var channel_accumulator := {}
	var channel_order: Array[StringName] = []
	for segment in segments:
		for aggregate_key in [
			["returned_souls_delta", segment.returned_souls_delta],
			["backlog_reduced", segment.backlog_reduced],
			["Essence_delta", segment.essence_delta],
			["Mastery_delta_subunits", segment.mastery_delta_subunits],
			["completed_cycles_delta", segment.completed_cycles_delta],
		]:
			var aggregate_total := _checked_add_non_negative(int(totals[aggregate_key[0]]), int(aggregate_key[1]), "segment aggregate %s" % aggregate_key[0])
			if not aggregate_total["ok"]: return aggregate_total
			totals[aggregate_key[0]] = int(aggregate_total.value)
		for delta in segment.channel_deltas:
			if not channel_accumulator.has(delta.channel_id):
				channel_order.append(delta.channel_id)
				channel_accumulator[delta.channel_id] = delta.detached_copy()
			else:
				var accumulated: SimulationChannelDeltaResult = channel_accumulator[delta.channel_id]
				var banked_total := _checked_add_non_negative(accumulated.banked_units_delta, delta.banked_units_delta, "channel banked aggregate")
				if not banked_total["ok"]: return banked_total
				accumulated.banked_units_delta = int(banked_total.value)
				accumulated.progress_subunits_after = delta.progress_subunits_after
				accumulated.rate_carry_units_after = delta.rate_carry_units_after
				accumulated.total_banked_units_after = delta.total_banked_units_after
	channel_order.sort_custom(func(a, b): return str(a) < str(b))
	var deltas: Array[SimulationChannelDeltaResult] = []
	for channel_id in channel_order:
		deltas.append(channel_accumulator[channel_id])
	totals.channel_deltas = deltas
	return totals

func _channel_delta_fields_equal(left: SimulationChannelDeltaResult, right: SimulationChannelDeltaResult) -> bool:
	return left.channel_id == right.channel_id \
		and left.output_item_id == right.output_item_id \
		and left.banked_units_delta == right.banked_units_delta \
		and left.progress_subunits_before == right.progress_subunits_before \
		and left.progress_subunits_after == right.progress_subunits_after \
		and left.rate_carry_units_before == right.rate_carry_units_before \
		and left.rate_carry_units_after == right.rate_carry_units_after \
		and left.total_banked_units_before == right.total_banked_units_before \
		and left.total_banked_units_after == right.total_banked_units_after

func _channel_contracts_for_segment(segment: SimulationSegmentResult) -> Dictionary:
	var contracts := {}
	for delta in segment.channel_deltas:
		if delta == null:
			return _fail(ERR_RESULT_INVALID, "Segment channel deltas cannot contain null entries.")
		var record := _get_enabled_content_record(delta.channel_id, "channel", "segment channel")
		if not record["ok"]: return record
		contracts[delta.channel_id] = {"period_msec": int(record.record.rate.period_msec), "output_item_id": StringName(record.record.output_item_id)}
	return {"ok": true, "contracts": contracts}

func _validate_result_transition_coherence(source: GameState, candidate: GameState, result: SimulationResult) -> Dictionary:
	if not result.success:
		return _validate_exact_state_match(source, candidate, 0, "Failed results")
	if result.requested_elapsed_msec == 0:
		return _validate_exact_state_match(source, candidate, 0, "Zero-duration success")
	if result.segments.is_empty():
		return _validate_timeline_only_transition(source, candidate, result)
	return _validate_active_transition(source, candidate, result)

func _validate_timeline_only_transition(source: GameState, candidate: GameState, result: SimulationResult) -> Dictionary:
	if not _active_reaping_ids(source).is_empty() or not _active_reaping_ids(candidate).is_empty():
		return _fail(ERR_RESULT_INVALID, "Timeline-only committed results require no active Reaping in source or candidate.")
	return _validate_exact_state_match(source, candidate, result.requested_elapsed_msec, "Timeline-only committed results")

func _validate_active_transition(source: GameState, candidate: GameState, result: SimulationResult) -> Dictionary:
	var source_active_ids := _active_reaping_ids(source)
	var candidate_active_ids := _active_reaping_ids(candidate)
	if source_active_ids.size() != 1 or candidate_active_ids.size() != 1 or source_active_ids[0] != candidate_active_ids[0]:
		return _fail(ERR_RESULT_INVALID, "Active committed results require exactly one matching active operation in source and candidate.")
	var threshold_id: StringName = source_active_ids[0]
	var source_reaping: GameState.ReapingState = source.reapings[threshold_id]
	var candidate_reaping: GameState.ReapingState = candidate.reapings[threshold_id]
	if source_reaping.assignment_revision != candidate_reaping.assignment_revision or source_reaping.form_id != candidate_reaping.form_id or source_reaping.writ_id != candidate_reaping.writ_id or source_reaping.retinue_ids != candidate_reaping.retinue_ids:
		return _fail(ERR_RESULT_INVALID, "Source and candidate must describe the same one active operation before commit.")
	for segment in result.segments:
		if segment.threshold_id != threshold_id or segment.assignment_revision != source_reaping.assignment_revision or segment.form_id != source_reaping.form_id or segment.writ_id != source_reaping.writ_id or segment.ordered_retinue_ids != source_reaping.retinue_ids:
			return _fail(ERR_RESULT_INVALID, "Typed segments must match the exact source/candidate assignment identity.")
	var source_threshold: GameState.ThresholdState = source.thresholds[threshold_id]
	var candidate_threshold: GameState.ThresholdState = candidate.thresholds[threshold_id]
	var lifecycle_check := _validate_transition_lifecycle_shape(source_threshold.lifecycle_state, candidate_threshold.lifecycle_state, result)
	if not lifecycle_check["ok"]: return lifecycle_check
	var totals := _aggregate_segments(result.segments)
	if not totals["ok"]: return totals
	var returned_delta := _checked_non_negative_difference(candidate_threshold.persistent_returns_total, source_threshold.persistent_returns_total, "actual returned_souls_delta")
	if not returned_delta["ok"]: return returned_delta
	if int(returned_delta.value) != int(totals.returned_souls_delta):
		return _fail(ERR_RESULT_INVALID, "Typed returned_souls_delta does not match the candidate transition.")
	var backlog_reduced := _checked_non_negative_difference(source_threshold.remaining_backlog, candidate_threshold.remaining_backlog, "actual backlog_reduced")
	if not backlog_reduced["ok"]: return backlog_reduced
	if int(backlog_reduced.value) != int(totals.backlog_reduced):
		return _fail(ERR_RESULT_INVALID, "Typed backlog_reduced does not match the candidate transition.")
	var source_essence: int = source.inventory.entries.get(&"RES_ESSENCE", GameState.InventoryEntryState.new()).total
	var candidate_essence: int = candidate.inventory.entries.get(&"RES_ESSENCE", GameState.InventoryEntryState.new()).total
	var essence_delta := _checked_non_negative_difference(candidate_essence, source_essence, "actual Essence_delta")
	if not essence_delta["ok"]: return essence_delta
	if int(essence_delta.value) != int(totals.Essence_delta):
		return _fail(ERR_RESULT_INVALID, "Typed Essence_delta does not match the candidate transition.")
	var source_form: GameState.FormState = source.forms[source_reaping.form_id]
	var candidate_form: GameState.FormState = candidate.forms[source_reaping.form_id]
	var mastery_delta := _checked_non_negative_difference(candidate_form.mastery_subunits, source_form.mastery_subunits, "actual Mastery_delta_subunits")
	if not mastery_delta["ok"]: return mastery_delta
	if int(mastery_delta.value) != int(totals.Mastery_delta_subunits):
		return _fail(ERR_RESULT_INVALID, "Typed Mastery_delta_subunits does not match the candidate transition.")
	var completed_delta := _checked_non_negative_difference(candidate_reaping.completed_cycle_count, source_reaping.completed_cycle_count, "actual completed_cycles_delta")
	if not completed_delta["ok"]: return completed_delta
	if int(completed_delta.value) != int(totals.completed_cycles_delta):
		return _fail(ERR_RESULT_INVALID, "Typed completed_cycles_delta does not match the candidate transition.")
	var actual_channels: Array = _overall_channel_deltas(source_threshold, candidate_threshold)
	if actual_channels.size() != totals.channel_deltas.size():
		return _fail(ERR_RESULT_INVALID, "Typed channel_deltas do not match the candidate transition channel count.")
	for i in range(actual_channels.size()):
		if not _channel_delta_fields_equal(actual_channels[i], totals.channel_deltas[i]):
			return _fail(ERR_RESULT_INVALID, "Typed channel_deltas do not match the candidate transition endpoints.")
	var summary_check := _validate_active_summary_against_transition(result, threshold_id, source_threshold, candidate_threshold, actual_channels)
	if not summary_check["ok"]: return summary_check
	return _validate_unrelated_active_state_stability(source, candidate, threshold_id, source_reaping.form_id, actual_channels)

func _validate_transition_lifecycle_shape(source_lifecycle: StringName, candidate_lifecycle: StringName, result: SimulationResult) -> Dictionary:
	var settlement_events := 0
	for event in result.events:
		if event.event_type == EVENT_THRESHOLD_SETTLED:
			settlement_events += 1
	if source_lifecycle == LIFECYCLE_OVERDUE and candidate_lifecycle == LIFECYCLE_OVERDUE:
		if result.segments.size() != 1 or result.segments[0].lifecycle_state != LIFECYCLE_OVERDUE or settlement_events != 0:
			return _fail(ERR_RESULT_INVALID, "Overdue-to-Overdue transitions must produce one OVERDUE segment and no Settlement event.")
		return {"ok": true}
	if source_lifecycle == LIFECYCLE_SETTLED and candidate_lifecycle == LIFECYCLE_SETTLED:
		if result.segments.size() != 1 or result.segments[0].lifecycle_state != LIFECYCLE_SETTLED or settlement_events != 0:
			return _fail(ERR_RESULT_INVALID, "Settled-to-Settled transitions must produce one SETTLED segment and no Settlement event.")
		return {"ok": true}
	if source_lifecycle == LIFECYCLE_OVERDUE and candidate_lifecycle == LIFECYCLE_SETTLED:
		if settlement_events != 1:
			return _fail(ERR_RESULT_INVALID, "Overdue-to-Settled transitions must emit exactly one Settlement event.")
		if result.segments.size() == 1 and result.segments[0].lifecycle_state == LIFECYCLE_OVERDUE:
			return {"ok": true}
		if result.segments.size() == 2 and result.segments[0].lifecycle_state == LIFECYCLE_OVERDUE and result.segments[1].lifecycle_state == LIFECYCLE_SETTLED:
			return {"ok": true}
		return _fail(ERR_RESULT_INVALID, "Overdue-to-Settled transitions must be one OVERDUE segment ending in Settlement or OVERDUE then SETTLED.")
	return _fail(ERR_RESULT_INVALID, "Committed segment lifecycle does not match the source/candidate lifecycle transition.")

func _validate_active_summary_against_transition(result: SimulationResult, threshold_id: StringName, source_threshold: GameState.ThresholdState, candidate_threshold: GameState.ThresholdState, actual_channels: Array) -> Dictionary:
	var summary := result.change_summary
	if str(summary.threshold_id) != str(threshold_id) or str(summary.operation_id) != str(threshold_id):
		return _fail(ERR_RESULT_INVALID, "Active change_summary Threshold and operation IDs must match the committed candidate operation.")
	var backlog_delta := _checked_difference(candidate_threshold.remaining_backlog, source_threshold.remaining_backlog, "actual backlog_delta")
	if not backlog_delta["ok"]: return backlog_delta
	if int(summary.backlog_delta) != int(backlog_delta.value):
		return _fail(ERR_RESULT_INVALID, "Active change_summary backlog_delta must match the candidate transition.")
	if str(summary.lifecycle_before) != str(source_threshold.lifecycle_state) or str(summary.lifecycle_after) != str(candidate_threshold.lifecycle_state):
		return _fail(ERR_RESULT_INVALID, "Active change_summary lifecycle fields must match the source/candidate transition.")
	var summary_channels: Array = summary.channel_deltas
	if summary_channels.size() != actual_channels.size():
		return _fail(ERR_RESULT_INVALID, "Active change_summary channel_deltas must match the candidate transition channel count.")
	for i in range(summary_channels.size()):
		if not _channel_delta_fields_equal(summary_channels[i], actual_channels[i]):
			return _fail(ERR_RESULT_INVALID, "Active change_summary channel_deltas must match the candidate transition endpoints.")
	for event in result.events:
		if event.event_type == EVENT_THRESHOLD_SETTLED and int(event.payload.persistent_returns_total) != candidate_threshold.persistent_returns_total:
			return _fail(ERR_RESULT_INVALID, "Settlement event persistent_returns_total must match the committed candidate endpoint.")
	return {"ok": true}

func _validate_unrelated_active_state_stability(source: GameState, candidate: GameState, active_threshold_id: StringName, active_form_id: StringName, actual_channels: Array) -> Dictionary:
	var changed_inventory_ids := {&"RES_ESSENCE": true}
	for delta in actual_channels:
		changed_inventory_ids[delta.output_item_id] = true
	var inventory_check := _validate_inventory_stability(source.inventory, candidate.inventory, changed_inventory_ids)
	if not inventory_check["ok"]: return inventory_check
	if not _sorted_keys_equal(source.forms, candidate.forms) or not _sorted_keys_equal(source.thresholds, candidate.thresholds) or not _sorted_keys_equal(source.reapings, candidate.reapings):
		return _fail(ERR_RESULT_INVALID, "Active transitions must preserve the complete source key set outside allowed field changes.")
	for form_id in source.forms.keys():
		var source_form: GameState.FormState = source.forms[form_id]
		var candidate_form: GameState.FormState = candidate.forms[form_id]
		if form_id == active_form_id:
			if source_form.revealed != candidate_form.revealed or source_form.awakened != candidate_form.awakened or source_form.awakened_by != candidate_form.awakened_by:
				return _fail(ERR_RESULT_INVALID, "Active transitions cannot mutate non-Mastery Form state.")
		elif not _forms_equal(source_form, candidate_form):
			return _fail(ERR_RESULT_INVALID, "Active transitions cannot mutate unrelated Forms.")
	for threshold_id in source.thresholds.keys():
		var source_threshold: GameState.ThresholdState = source.thresholds[threshold_id]
		var candidate_threshold: GameState.ThresholdState = candidate.thresholds[threshold_id]
		if threshold_id == active_threshold_id:
			if source_threshold.knowledge_state != candidate_threshold.knowledge_state or source_threshold.availability_state != candidate_threshold.availability_state or source_threshold.familiarity_subunits != candidate_threshold.familiarity_subunits:
				return _fail(ERR_RESULT_INVALID, "Active transitions cannot mutate unrelated Threshold fields.")
		elif not _thresholds_equal(source_threshold, candidate_threshold):
			return _fail(ERR_RESULT_INVALID, "Active transitions cannot mutate unrelated Thresholds.")
	for threshold_id in source.reapings.keys():
		var source_reaping: GameState.ReapingState = source.reapings[threshold_id]
		var candidate_reaping: GameState.ReapingState = candidate.reapings[threshold_id]
		if threshold_id == active_threshold_id:
			if source_reaping.threshold_id != candidate_reaping.threshold_id or source_reaping.is_active != candidate_reaping.is_active or source_reaping.form_id != candidate_reaping.form_id or source_reaping.writ_id != candidate_reaping.writ_id or source_reaping.retinue_ids != candidate_reaping.retinue_ids or source_reaping.assignment_revision != candidate_reaping.assignment_revision or source_reaping.started_simulation_msec != candidate_reaping.started_simulation_msec or source_reaping.last_configuration_change_simulation_msec != candidate_reaping.last_configuration_change_simulation_msec:
				return _fail(ERR_RESULT_INVALID, "Active transitions cannot mutate Reaping identity outside elapsed simulation facts.")
		elif not _reapings_equal(source_reaping, candidate_reaping):
			return _fail(ERR_RESULT_INVALID, "Active transitions cannot mutate unrelated Reapings.")
	if source.progression.command_tether_capacity != candidate.progression.command_tether_capacity or source.progression.unlocked_output_item_ids != candidate.progression.unlocked_output_item_ids:
		return _fail(ERR_RESULT_INVALID, "Active transitions cannot mutate unrelated progression state.")
	return {"ok": true}

func _validate_exact_state_match(source: GameState, candidate: GameState, expected_time_delta: int, context: String) -> Dictionary:
	var time_delta := _checked_difference(candidate.simulation_time_msec, source.simulation_time_msec, "%s simulation_time_msec" % context)
	if not time_delta["ok"]: return time_delta
	if int(time_delta.value) != expected_time_delta:
		return _fail(ERR_RESULT_INVALID, "%s must change only by the expected simulation cursor delta." % context)
	var inventory_check := _validate_inventory_stability(source.inventory, candidate.inventory, {})
	if not inventory_check["ok"]: return inventory_check
	if not _sorted_keys_equal(source.forms, candidate.forms) or not _sorted_keys_equal(source.thresholds, candidate.thresholds) or not _sorted_keys_equal(source.reapings, candidate.reapings):
		return _fail(ERR_RESULT_INVALID, "%s must preserve the complete source gameplay state." % context)
	for form_id in source.forms.keys():
		if not _forms_equal(source.forms[form_id], candidate.forms[form_id]):
			return _fail(ERR_RESULT_INVALID, "%s must preserve source Form state." % context)
	for threshold_id in source.thresholds.keys():
		if not _thresholds_equal(source.thresholds[threshold_id], candidate.thresholds[threshold_id]):
			return _fail(ERR_RESULT_INVALID, "%s must preserve source Threshold state." % context)
	for threshold_id in source.reapings.keys():
		if not _reapings_equal(source.reapings[threshold_id], candidate.reapings[threshold_id]):
			return _fail(ERR_RESULT_INVALID, "%s must preserve source Reaping state." % context)
	if source.progression.command_tether_capacity != candidate.progression.command_tether_capacity or source.progression.unlocked_output_item_ids != candidate.progression.unlocked_output_item_ids:
		return _fail(ERR_RESULT_INVALID, "%s must preserve source progression state." % context)
	return {"ok": true}

func _validate_inventory_stability(source_inventory: GameState.InventoryState, candidate_inventory: GameState.InventoryState, allowed_total_changes: Dictionary) -> Dictionary:
	var source_keys := source_inventory.entries.keys()
	var candidate_keys := candidate_inventory.entries.keys()
	for key in source_keys:
		if not candidate_inventory.entries.has(key):
			return _fail(ERR_RESULT_INVALID, "Candidate inventory must preserve the source key set.")
	for key in candidate_keys:
		if not source_inventory.entries.has(key) and not allowed_total_changes.has(key):
			return _fail(ERR_RESULT_INVALID, "Candidate inventory cannot add unrelated entries.")
	for key in candidate_keys:
		var source_entry: GameState.InventoryEntryState = source_inventory.entries.get(key, GameState.InventoryEntryState.new())
		var candidate_entry: GameState.InventoryEntryState = candidate_inventory.entries[key]
		if source_entry.reservations != candidate_entry.reservations:
			return _fail(ERR_RESULT_INVALID, "Inventory reservations cannot change during committed result validation.")
		if not allowed_total_changes.has(key) and source_entry.total != candidate_entry.total:
			return _fail(ERR_RESULT_INVALID, "Inventory totals may change only for actual simulated output items.")
	return {"ok": true}

func _forms_equal(left: GameState.FormState, right: GameState.FormState) -> bool:
	return left.revealed == right.revealed and left.awakened == right.awakened and left.mastery_subunits == right.mastery_subunits and left.awakened_by == right.awakened_by

func _thresholds_equal(left: GameState.ThresholdState, right: GameState.ThresholdState) -> bool:
	if left.knowledge_state != right.knowledge_state or left.availability_state != right.availability_state or left.lifecycle_state != right.lifecycle_state or left.remaining_backlog != right.remaining_backlog or left.persistent_returns_total != right.persistent_returns_total or left.familiarity_subunits != right.familiarity_subunits:
		return false
	if not _sorted_keys_equal(left.channel_acquisition, right.channel_acquisition):
		return false
	for channel_id in left.channel_acquisition.keys():
		var left_acq: GameState.ThresholdAcquisitionState = left.channel_acquisition[channel_id]
		var right_acq: GameState.ThresholdAcquisitionState = right.channel_acquisition[channel_id]
		if left_acq.progress_subunits != right_acq.progress_subunits or left_acq.rate_carry_units != right_acq.rate_carry_units or left_acq.total_banked_units != right_acq.total_banked_units:
			return false
	return true

func _reapings_equal(left: GameState.ReapingState, right: GameState.ReapingState) -> bool:
	return left.threshold_id == right.threshold_id and left.is_active == right.is_active and left.form_id == right.form_id and left.writ_id == right.writ_id and left.retinue_ids == right.retinue_ids and left.assignment_revision == right.assignment_revision and left.cycle_phase_msec == right.cycle_phase_msec and left.completed_cycle_count == right.completed_cycle_count and left.flow_carry_units == right.flow_carry_units and left.started_simulation_msec == right.started_simulation_msec and left.last_configuration_change_simulation_msec == right.last_configuration_change_simulation_msec

func _get_enabled_content_record(id: StringName, expected_type: String, label: String) -> Dictionary:
	if registry == null or not registry.ready:
		return _fail(ERR_RESULT_INVALID, "Content registry is not ready for committed result validation.")
	if str(id).is_empty():
		return _fail(ERR_RESULT_INVALID, "%s ID must be non-empty." % label)
	var result := registry.get_record(str(id))
	if not result.ok:
		return _fail(ERR_RESULT_INVALID, "%s must resolve in the content registry." % label)
	var record: Dictionary = result.record
	if str(record.get("type", "")) != expected_type:
		return _fail(ERR_RESULT_INVALID, "%s must resolve to content type %s." % [label, expected_type])
	if not bool(record.get("enabled", false)):
		return _fail(ERR_RESULT_INVALID, "%s must resolve to an enabled content record." % label)
	return {"ok": true, "record": record}

func _validate_known_event_shape(event: SimulationEvent) -> Dictionary:
	match event.event_type:
		EVENT_OUTPUT_CHANNEL_BANKED:
			if not event.reportable or not event.tutorial_relevant or event.priority != EVENT_PRIORITY_CHANNEL_GAIN:
				return _fail(ERR_RESULT_INVALID, "OUTPUT_CHANNEL_BANKED must use canonical flags and priority even when treated as diagnostic.")
			return _validate_output_channel_event_payload(event.payload)
		EVENT_THRESHOLD_SETTLED:
			if not event.reportable or not event.tutorial_relevant or event.priority != EVENT_PRIORITY_LIFECYCLE:
				return _fail(ERR_RESULT_INVALID, "THRESHOLD_SETTLED must use canonical flags and priority even when treated as diagnostic.")
			return _validate_threshold_settled_event_payload(event.payload)
		_:
			return _fail(ERR_RESULT_INVALID, "Unknown simulation event types are not allowed in the committed result grammar.")

func _validate_output_channel_event_payload(payload: Dictionary) -> Dictionary:
	if not _dictionary_has_exact_keys(payload, OUTPUT_CHANNEL_EVENT_PAYLOAD_KEYS):
		return _fail(ERR_RESULT_INVALID, "OUTPUT_CHANNEL_BANKED payload must use the exact required key set.")
	if typeof(payload.output_item_id) != TYPE_STRING_NAME or typeof(payload.quantity) != TYPE_INT or typeof(payload.lifecycle_state) != TYPE_STRING or typeof(payload.total_banked_units) != TYPE_INT or typeof(payload.progress_subunits_after) != TYPE_INT:
		return _fail(ERR_RESULT_INVALID, "OUTPUT_CHANNEL_BANKED payload must use the canonical primitive field types.")
	return {"ok": true}

func _validate_threshold_settled_event_payload(payload: Dictionary) -> Dictionary:
	if not _dictionary_has_exact_keys(payload, THRESHOLD_SETTLED_EVENT_PAYLOAD_KEYS):
		return _fail(ERR_RESULT_INVALID, "THRESHOLD_SETTLED payload must use the exact required key set.")
	if typeof(payload.remaining_backlog) != TYPE_INT or typeof(payload.lifecycle_state) != TYPE_STRING or typeof(payload.persistent_returns_total) != TYPE_INT:
		return _fail(ERR_RESULT_INVALID, "THRESHOLD_SETTLED payload must use the canonical primitive field types.")
	return {"ok": true}

func _dictionary_has_exact_keys(value: Dictionary, expected_keys: Array) -> bool:
	if value == null or value.size() != expected_keys.size():
		return false
	var actual_keys := value.keys()
	actual_keys.sort()
	var expected_sorted := expected_keys.duplicate()
	expected_sorted.sort()
	return actual_keys == expected_sorted

func _segment_event_key(segment_index: int, source_id: StringName) -> String:
	return "%d|%s" % [segment_index, str(source_id)]

func _validate_cross_segment_channel_continuity(previous_segment: SimulationSegmentResult, next_segment: SimulationSegmentResult) -> Dictionary:
	var previous_by_channel := {}
	for delta in previous_segment.channel_deltas:
		previous_by_channel[delta.channel_id] = delta
	for delta in next_segment.channel_deltas:
		if not previous_by_channel.has(delta.channel_id):
			continue
		var previous_delta: SimulationChannelDeltaResult = previous_by_channel[delta.channel_id]
		if previous_delta.progress_subunits_after != delta.progress_subunits_before or previous_delta.rate_carry_units_after != delta.rate_carry_units_before or previous_delta.total_banked_units_after != delta.total_banked_units_before or previous_delta.output_item_id != delta.output_item_id:
			return _fail(ERR_RESULT_INVALID, "Cross-segment channel endpoints must be continuous for the same channel.")
	return {"ok": true}

func _checked_add_non_negative(left: int, right: int, label: String) -> Dictionary:
	if left < 0 or right < 0:
		return _fail(ERR_RESULT_INVALID, "%s uses a negative value where a non-negative checked add was required." % label)
	if left > FixedPoint.INT64_MAX - right:
		return _fail(ERR_RESULT_INVALID, "%s overflowed signed 64-bit validation arithmetic." % label)
	return {"ok": true, "value": left + right}

func _checked_non_negative_difference(after: int, before: int, label: String) -> Dictionary:
	if after < 0 or before < 0:
		return _fail(ERR_RESULT_INVALID, "%s requires non-negative endpoints." % label)
	if after < before:
		return _fail(ERR_RESULT_INVALID, "%s cannot move backwards." % label)
	return {"ok": true, "value": after - before}

func _checked_difference(after: int, before: int, label: String) -> Dictionary:
	if after >= before:
		return _checked_non_negative_difference(after, before, label)
	var reversed := _checked_non_negative_difference(before, after, label)
	if not reversed["ok"]: return reversed
	return {"ok": true, "value": -int(reversed.value)}

func _sorted_keys_equal(left: Dictionary, right: Dictionary) -> bool:
	var left_keys := left.keys()
	var right_keys := right.keys()
	left_keys.sort_custom(func(a, b): return str(a) < str(b))
	right_keys.sort_custom(func(a, b): return str(a) < str(b))
	return left_keys == right_keys

## Detached non-persisted evidence for one Threshold output channel during a segment.
##
## The record owns copied endpoint values only; it does not own inventory,
## acquisition state, rates, formulas, saves, Resources, Nodes, or later summary state.
## Progress values use FixedPoint.SCALE subunits, carry values use the authored
## channel period's carry units, and banked values are whole inventory units.
class SimulationChannelDeltaResult:
	extends RefCounted
	var channel_id: StringName
	var output_item_id: StringName
	var banked_units_delta: int
	var progress_subunits_before: int
	var progress_subunits_after: int
	var rate_carry_units_before: int
	var rate_carry_units_after: int
	var total_banked_units_before: int
	var total_banked_units_after: int
	func _init(channel_value: StringName, output_value: StringName, banked_delta: int, progress_before: int, progress_after: int, carry_before: int, carry_after: int, total_before: int, total_after: int) -> void:
		channel_id = channel_value
		output_item_id = output_value
		banked_units_delta = banked_delta
		progress_subunits_before = progress_before
		progress_subunits_after = progress_after
		rate_carry_units_before = carry_before
		rate_carry_units_after = carry_after
		total_banked_units_before = total_before
		total_banked_units_after = total_after
	func detached_copy() -> SimulationChannelDeltaResult:
		return SimulationChannelDeltaResult.new(channel_id, output_item_id, banked_units_delta, progress_subunits_before, progress_subunits_after, rate_carry_units_before, rate_carry_units_after, total_banked_units_before, total_banked_units_after)
	func validate(period_msec: int) -> Dictionary:
		if str(channel_id).is_empty() or str(output_item_id).is_empty(): return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Channel delta IDs must be non-empty."}
		for value in [banked_units_delta, progress_subunits_before, progress_subunits_after, rate_carry_units_before, rate_carry_units_after, total_banked_units_before, total_banked_units_after]:
			if int(value) < 0: return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Channel delta values must be non-negative."}
		if progress_subunits_before >= FixedPoint.SCALE or progress_subunits_after >= FixedPoint.SCALE: return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Channel progress must be within one fixed-point whole."}
		if period_msec <= 0: return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Channel period must be positive."}
		if rate_carry_units_before >= period_msec or rate_carry_units_after >= period_msec: return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Channel carry must be below the period."}
		if total_banked_units_after < total_banked_units_before: return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Channel total banked cannot reverse."}
		if banked_units_delta != total_banked_units_after - total_banked_units_before: return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Channel banked delta must match endpoints."}
		return {"ok": true}

## Detached non-persisted evidence for one contiguous active-Reaping interval.
##
## The record owns historical assignment/loadout/lifecycle identity captured when
## production occurred plus copied numeric deltas for that interval. It does not
## own live Reaping state, inventory, formulas, clocks, save data, Nodes, or
## later summary storage. Times are authoritative simulation milliseconds; Mastery/progress use
## FixedPoint.SCALE subunits; output-channel child records are detached copies.
class SimulationSegmentResult:
	extends RefCounted
	var threshold_id: StringName
	var assignment_revision: int
	var form_id: StringName
	var writ_id: StringName
	var ordered_retinue_ids: Array[StringName] = []
	var lifecycle_state: StringName
	var start_simulation_msec: int
	var end_simulation_msec: int
	var elapsed_msec: int
	var returned_souls_delta: int
	var backlog_reduced: int
	var essence_delta: int
	var mastery_delta_subunits: int
	var completed_cycles_delta: int
	var channel_deltas: Array[SimulationChannelDeltaResult] = []
	func _init(threshold_value: StringName, revision: int, form_value: StringName, writ_value: StringName, retinues: Array[StringName], lifecycle_value: StringName, start_msec: int, end_msec: int, elapsed_value: int, returns_delta: int, backlog_value: int, essence_value: int, mastery_value: int, cycles_value: int, channel_values: Array[SimulationChannelDeltaResult]) -> void:
		threshold_id = threshold_value
		assignment_revision = revision
		form_id = form_value
		writ_id = writ_value
		ordered_retinue_ids.assign(retinues)
		lifecycle_state = lifecycle_value
		start_simulation_msec = start_msec
		end_simulation_msec = end_msec
		elapsed_msec = elapsed_value
		returned_souls_delta = returns_delta
		backlog_reduced = backlog_value
		essence_delta = essence_value
		mastery_delta_subunits = mastery_value
		completed_cycles_delta = cycles_value
		for delta in channel_values: channel_deltas.append(delta.detached_copy())
	func detached_copy() -> SimulationSegmentResult:
		return SimulationSegmentResult.new(threshold_id, assignment_revision, form_id, writ_id, ordered_retinue_ids, lifecycle_state, start_simulation_msec, end_simulation_msec, elapsed_msec, returned_souls_delta, backlog_reduced, essence_delta, mastery_delta_subunits, completed_cycles_delta, channel_deltas)
	func validate(channel_contracts: Dictionary) -> Dictionary:
		if str(threshold_id).is_empty() or str(form_id).is_empty() or str(writ_id).is_empty(): return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Segment identity IDs must be non-empty."}
		if assignment_revision <= 0: return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Assignment revision must be positive."}
		if lifecycle_state != LIFECYCLE_OVERDUE and lifecycle_state != LIFECYCLE_SETTLED: return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Invalid segment lifecycle."}
		if start_simulation_msec < 0 or start_simulation_msec >= end_simulation_msec or elapsed_msec != end_simulation_msec - start_simulation_msec: return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Segment timing is invalid."}
		for value in [returned_souls_delta, backlog_reduced, essence_delta, mastery_delta_subunits, completed_cycles_delta]:
			if int(value) < 0: return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Segment gains must be non-negative."}
		var seen_retinues := {}
		for retinue_id in ordered_retinue_ids:
			if str(retinue_id).is_empty() or seen_retinues.has(retinue_id): return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Retinue IDs must be non-empty and unique."}
			seen_retinues[retinue_id] = true
		var previous_channel := ""
		for delta in channel_deltas:
			if delta == null: return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Segment channel_deltas cannot contain null entries."}
			if not channel_contracts.has(delta.channel_id): return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Missing channel contract for delta."}
			if not previous_channel.is_empty() and previous_channel >= str(delta.channel_id): return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Channel deltas must be unique and ordered."}
			var contract_value: Variant = channel_contracts[delta.channel_id]
			if not (contract_value is Dictionary): return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Channel contracts must be exact dictionaries."}
			var contract: Dictionary = contract_value
			var contract_keys := contract.keys()
			contract_keys.sort()
			if contract_keys != ["output_item_id", "period_msec"]: return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Channel contracts must contain exactly output_item_id and period_msec."}
			if typeof(contract.period_msec) != TYPE_INT or typeof(contract.output_item_id) != TYPE_STRING_NAME: return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Channel contracts must use canonical primitive field types."}
			if delta.output_item_id != contract.output_item_id: return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Channel output item must match content."}
			var period_msec := int(contract.period_msec)
			var delta_check: Dictionary = delta.validate(period_msec)
			if not delta_check["ok"]: return delta_check
			previous_channel = str(delta.channel_id)
		return {"ok": true}

class SimulationResult:
	extends RefCounted
	var success: bool
	var error_code: StringName
	var developer_details: String
	var requested_elapsed_msec: int
	var committed_elapsed_msec: int = 0
	var change_summary: Dictionary = {}
	var segments: Array[SimulationSegmentResult] = []
	var events: Array[SimulationEvent] = []
	func _init(success_value := false, error_value: StringName = &"", details := "", requested := 0) -> void:
		success = success_value; error_code = error_value; developer_details = details; requested_elapsed_msec = requested
	static func failure(code: StringName, requested: int, details: String) -> SimulationResult:
		return SimulationResult.new(false, code, details, requested)
	static func success_empty(requested: int, _baseline_simulation_time_msec: int = 0) -> SimulationResult:
		var result := SimulationResult.new(true, OK, "", requested)
		result.committed_elapsed_msec = 0
		return result

class SimulationEvent:
	extends RefCounted
	var event_type: StringName
	var occurred_simulation_msec: int
	var priority: int
	var subject_id: StringName
	var source_id: StringName
	var payload: Dictionary
	var reportable: bool
	var tutorial_relevant: bool
	func _init(type_value: StringName, occurred: int, priority_value: int, subject: StringName, source: StringName, payload_value: Dictionary) -> void:
		event_type = type_value; occurred_simulation_msec = occurred; priority = priority_value; subject_id = subject; source_id = source; payload = payload_value; reportable = true; tutorial_relevant = true
	func validate() -> Dictionary:
		if occurred_simulation_msec < 0 or priority < 0: return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Event time and priority must be non-negative."}
		if str(event_type).is_empty() or str(subject_id).is_empty() or str(source_id).is_empty(): return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Event IDs must be non-empty."}
		if payload == null: return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Event payload must be a Dictionary."}
		return {"ok": true}
	static func threshold_settled(occurred: int, threshold_id: StringName, returns_total: int) -> SimulationEvent:
		return SimulationEvent.new(EVENT_THRESHOLD_SETTLED, occurred, EVENT_PRIORITY_LIFECYCLE, threshold_id, SIMULATION_ENGINE_SOURCE_ID, {"remaining_backlog": 0, "lifecycle_state": "SETTLED", "persistent_returns_total": returns_total})
	static func output_channel_banked(occurred: int, threshold_id: StringName, channel_id: StringName, delta: SimulationChannelDeltaResult, lifecycle_state: String) -> SimulationEvent:
		return SimulationEvent.new(EVENT_OUTPUT_CHANNEL_BANKED, occurred, EVENT_PRIORITY_CHANNEL_GAIN, threshold_id, channel_id, {"output_item_id": delta.output_item_id, "quantity": delta.banked_units_delta, "lifecycle_state": lifecycle_state, "total_banked_units": delta.total_banked_units_after, "progress_subunits_after": delta.progress_subunits_after})
