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
	deltas.sort_custom(func(a, b): return a.channel_id < b.channel_id)
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
	channels.sort_custom(func(a, b): return a.id < b.id)
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
	var result_validation: Dictionary = validate_result(result, live.simulation_time_msec, candidate.simulation_time_msec, result.requested_elapsed_msec)
	if not result_validation["ok"]: return SimulationResult.failure(ERR_RESULT_INVALID, result.requested_elapsed_msec, result_validation["details"])
	var validation := GameStateValidator.validate(candidate, registry, true)
	if not validation.ok: return SimulationResult.failure(ERR_STATE_INVALID, result.requested_elapsed_msec, str(validation))
	live.copy_from(candidate)
	return result

func _active_reaping_ids(state: GameState) -> Array[StringName]:
	var ids: Array[StringName] = []
	for id in state.reapings.keys():
		if state.reapings[id].is_active: ids.append(id)
	ids.sort()
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
	ids.sort()
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

func validate_result(result: SimulationResult, baseline_simulation_time_msec: int, result_simulation_time_msec: int, requested_elapsed_msec: int) -> Dictionary:
	if result == null: return _fail(ERR_RESULT_INVALID, "SimulationResult is null.")
	if not result.success:
		if result.segments.is_empty() and result.events.is_empty() and result.committed_elapsed_msec == 0: return {"ok": true}
		return _fail(ERR_RESULT_INVALID, "Failed result cannot carry committed authority.")
	if requested_elapsed_msec == 0:
		if result.committed_elapsed_msec == 0 and result.segments.is_empty() and result.events.is_empty(): return {"ok": true}
		return _fail(ERR_RESULT_INVALID, "Zero-duration result must be empty.")
	if result.committed_elapsed_msec != requested_elapsed_msec: return _fail(ERR_RESULT_INVALID, "Committed elapsed must equal requested elapsed.")
	if result_simulation_time_msec - baseline_simulation_time_msec != requested_elapsed_msec: return _fail(ERR_RESULT_INVALID, "Result cursor does not match requested elapsed.")
	if result.segments.is_empty():
		return _validate_timeline_only_result(result, requested_elapsed_msec)
	var sum := 0
	var expected_start := baseline_simulation_time_msec
	var first: SimulationSegmentResult = result.segments[0]
	for i in range(result.segments.size()):
		var segment: SimulationSegmentResult = result.segments[i]
		var local: Dictionary = segment.validate(_channel_periods_for_segment(segment))
		if not local["ok"]: return local
		if segment.start_simulation_msec != expected_start: return _fail(ERR_RESULT_INVALID, "Segments must be ordered and contiguous.")
		if segment.threshold_id != first.threshold_id or segment.assignment_revision != first.assignment_revision or segment.form_id != first.form_id or segment.writ_id != first.writ_id or segment.ordered_retinue_ids != first.ordered_retinue_ids:
			return _fail(ERR_RESULT_INVALID, "Assignment identity changed inside one run.")
		if i > 0 and result.segments[i - 1].lifecycle_state == LIFECYCLE_SETTLED and segment.lifecycle_state != LIFECYCLE_SETTLED:
			return _fail(ERR_RESULT_INVALID, "Lifecycle may only move from OVERDUE to SETTLED.")
		sum += segment.elapsed_msec
		expected_start = segment.end_simulation_msec
	if expected_start != result_simulation_time_msec: return _fail(ERR_RESULT_INVALID, "Final segment end must equal result cursor.")
	if sum != requested_elapsed_msec: return _fail(ERR_RESULT_INVALID, "Segment elapsed sum must equal committed elapsed.")
	for event in result.events:
		var event_check: Dictionary = event.validate()
		if not event_check["ok"]: return event_check
		if event.reportable and _owning_segment_count(result.segments, event) != 1: return _fail(ERR_RESULT_INVALID, "Event marked reportable must belong to exactly one segment.")
	if result.change_summary.has("simulation_time_delta_msec") and int(result.change_summary.simulation_time_delta_msec) != requested_elapsed_msec:
		return _fail(ERR_RESULT_INVALID, "Summary simulation-time delta mismatch.")
	return {"ok": true}

func _validate_timeline_only_result(result: SimulationResult, requested_elapsed_msec: int) -> Dictionary:
	if not result.events.is_empty(): return _fail(ERR_RESULT_INVALID, "Timeline-only result cannot carry events.")
	if result.change_summary.size() != 1 or not result.change_summary.has("simulation_time_delta_msec") or int(result.change_summary.simulation_time_delta_msec) != requested_elapsed_msec:
		return _fail(ERR_RESULT_INVALID, "Timeline-only summary must contain only the exact simulation-time delta.")
	return {"ok": true}

func _owning_segment_count(segments: Array[SimulationSegmentResult], event: SimulationEvent) -> int:
	var count := 0
	for segment in segments:
		if segment.start_simulation_msec < event.occurred_simulation_msec and event.occurred_simulation_msec <= segment.end_simulation_msec:
			count += 1
	return count

func _channel_periods_for_segment(segment: SimulationSegmentResult) -> Dictionary:
	var periods := {}
	for delta in segment.channel_deltas:
		var record := registry.get_record(str(delta.channel_id))
		if not record.ok: continue
		periods[delta.channel_id] = int(record.record.rate.period_msec)
	return periods

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
	func validate(channel_periods: Dictionary) -> Dictionary:
		if str(threshold_id).is_empty() or str(form_id).is_empty() or str(writ_id).is_empty(): return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Segment identity IDs must be non-empty."}
		if assignment_revision <= 0: return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Assignment revision must be positive."}
		if lifecycle_state != LIFECYCLE_OVERDUE and lifecycle_state != LIFECYCLE_SETTLED: return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Invalid segment lifecycle."}
		if start_simulation_msec < 0 or start_simulation_msec >= end_simulation_msec or elapsed_msec != end_simulation_msec - start_simulation_msec: return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Segment timing is invalid."}
		for value in [returned_souls_delta, backlog_reduced, essence_delta, mastery_delta_subunits, completed_cycles_delta]:
			if int(value) < 0: return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Segment gains must be non-negative."}
		var seen_retinues := {}
		var previous_retinue := ""
		for retinue_id in ordered_retinue_ids:
			if str(retinue_id).is_empty() or seen_retinues.has(retinue_id) or (not previous_retinue.is_empty() and previous_retinue > str(retinue_id)): return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Retinue IDs must be non-empty, unique, and ordered."}
			seen_retinues[retinue_id] = true
			previous_retinue = str(retinue_id)
		var previous_channel := ""
		for delta in channel_deltas:
			if not channel_periods.has(delta.channel_id): return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Missing channel period for delta."}
			if not previous_channel.is_empty() and previous_channel >= str(delta.channel_id): return {"ok": false, "code": ERR_RESULT_INVALID, "details": "Channel deltas must be unique and ordered."}
			var delta_check: Dictionary = delta.validate(int(channel_periods[delta.channel_id]))
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
		return {"ok": true}
	static func threshold_settled(occurred: int, threshold_id: StringName, returns_total: int) -> SimulationEvent:
		return SimulationEvent.new(EVENT_THRESHOLD_SETTLED, occurred, EVENT_PRIORITY_LIFECYCLE, threshold_id, &"SIMULATION_ENGINE", {"remaining_backlog": 0, "lifecycle_state": "SETTLED", "persistent_returns_total": returns_total})
	static func output_channel_banked(occurred: int, threshold_id: StringName, channel_id: StringName, delta: SimulationChannelDeltaResult, lifecycle_state: String) -> SimulationEvent:
		return SimulationEvent.new(EVENT_OUTPUT_CHANNEL_BANKED, occurred, EVENT_PRIORITY_CHANNEL_GAIN, threshold_id, channel_id, {"output_item_id": delta.output_item_id, "quantity": delta.banked_units_delta, "lifecycle_state": lifecycle_state, "total_banked_units": delta.total_banked_units_after, "progress_subunits_after": delta.progress_subunits_after})
