class_name SimulationEngine
extends RefCounted

## Deterministic M04C elapsed-production resolver for one active Reaping.
##
## The engine owns online/offline/forecast-compatible arithmetic for the current
## single-Reaping slice only. It mutates a deep-cloned GameState candidate,
## validates that candidate, and then replaces the live aggregate once so every
## failure preserves exact caller state. It does not own clocks, frame callbacks,
## Nodes, file I/O, Retinue effects, reports, milestones, Writ transitions,
## discovery, tutorial state, offline trust, or multi-Reaping concurrency. All
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

const EVENT_THRESHOLD_SETTLED := &"THRESHOLD_SETTLED"
const EVENT_PRIORITY_LIFECYCLE := 200

const FLOW_CORE_RETURNS_PROGRESS_SUBUNITS := CoreFlowKeys.RETURNS_PROGRESS
const FLOW_CORE_RETURNS_RATE_CARRY_UNITS := CoreFlowKeys.RETURNS_CARRY
const FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS := CoreFlowKeys.ESSENCE_PROGRESS
const FLOW_CORE_ESSENCE_RATE_CARRY_UNITS := CoreFlowKeys.ESSENCE_CARRY
const FLOW_CORE_MASTERY_RATE_CARRY_UNITS := CoreFlowKeys.MASTERY_CARRY
const CORE_FLOW_KEYS := CoreFlowKeys.ORDERED_KEYS

var registry: ContentRegistry

func _init(content_registry: ContentRegistry) -> void:
	registry = content_registry

## Resolves explicit elapsed milliseconds and commits only a fully validated candidate.
func resolve_elapsed(state: GameState, elapsed_msec: int) -> SimulationResult:
	if elapsed_msec < 0:
		return SimulationResult.failure(ERR_NEGATIVE_ELAPSED, elapsed_msec, "Elapsed milliseconds must be non-negative.")
	if elapsed_msec == 0:
		return SimulationResult.success_empty(elapsed_msec)
	var validation := GameStateValidator.validate(state, registry)
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
		var applied := _apply_segment(candidate, reaping, active_id, segment_msec)
		if not applied.ok: return SimulationResult.failure(StringName(applied.code), elapsed_msec, applied.details)
		cursor += segment_msec
		remaining -= segment_msec
		result.segments.append({"start_simulation_msec": cursor - segment_msec, "end_simulation_msec": cursor, "elapsed_msec": segment_msec, "lifecycle": applied.lifecycle, "returned_souls_delta": applied.returned_souls_delta, "backlog_delta": applied.backlog_delta, "Essence_delta": applied.Essence_delta, "Mastery_delta_subunits": applied.Mastery_delta_subunits, "completed_cycles_delta": applied.completed_cycles_delta})
		if will_settle:
			threshold = candidate.thresholds[active_id]
			threshold.remaining_backlog = 0
			threshold.lifecycle_state = &"SETTLED"
			result.events.append(SimulationEvent.threshold_settled(cursor, active_id, threshold.persistent_returns_total))
	var timeline2 := candidate.advance_simulation_time(elapsed_msec)
	if not timeline2.ok: return SimulationResult.failure(ERR_OVERFLOW, elapsed_msec, str(timeline2))
	result.committed_elapsed_msec = elapsed_msec
	result.change_summary = _summary(state, candidate, active_id)
	return _commit_if_valid(state, candidate, result)

func _apply_segment(state: GameState, reaping: GameState.ReapingState, threshold_id: StringName, elapsed_msec: int) -> Dictionary:
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
	return {"ok": true, "lifecycle": str(threshold.lifecycle_state), "returned_souls_delta": threshold.persistent_returns_total - before_returns, "backlog_delta": threshold.remaining_backlog - before_backlog, "Essence_delta": state.inventory.entries.get(&"RES_ESSENCE", GameState.InventoryEntryState.new()).total - before_essence, "Mastery_delta_subunits": form.mastery_subunits - before_mastery, "completed_cycles_delta": reaping.completed_cycle_count - before_cycles}

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
	var validation := GameStateValidator.validate(candidate, registry)
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
	return {"threshold_id": str(threshold_id), "operation_id": str(threshold_id), "simulation_time_delta_msec": after.simulation_time_msec - before.simulation_time_msec, "returned_souls_delta": after_threshold.persistent_returns_total - before_threshold.persistent_returns_total, "backlog_delta": after_threshold.remaining_backlog - before_threshold.remaining_backlog, "Essence_delta": after.inventory.entries.get(&"RES_ESSENCE", GameState.InventoryEntryState.new()).total - before.inventory.entries.get(&"RES_ESSENCE", GameState.InventoryEntryState.new()).total, "Mastery_delta_subunits": after.forms[form_id].mastery_subunits - before.forms[form_id].mastery_subunits, "completed_cycles_delta": after.reapings[threshold_id].completed_cycle_count - before.reapings[threshold_id].completed_cycle_count, "lifecycle_before": str(before_threshold.lifecycle_state), "lifecycle_after": str(after_threshold.lifecycle_state)}

func _has_any(left: Array, right: Array) -> bool:
	for value in right:
		if left.has(value): return true
	return false

func _fail(code: StringName, details: String) -> Dictionary:
	return {"ok": false, "code": code, "details": details}

class SimulationResult:
	extends RefCounted
	var success: bool
	var error_code: StringName
	var developer_details: String
	var requested_elapsed_msec: int
	var committed_elapsed_msec: int = 0
	var change_summary: Dictionary = {}
	var segments: Array = []
	var events: Array = []
	func _init(success_value := false, error_value: StringName = &"", details := "", requested := 0) -> void:
		success = success_value; error_code = error_value; developer_details = details; requested_elapsed_msec = requested
	static func failure(code: StringName, requested: int, details: String) -> SimulationResult:
		return SimulationResult.new(false, code, details, requested)
	static func success_empty(requested: int) -> SimulationResult:
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
	func _init(type_value: StringName, occurred: int, subject: StringName, payload_value: Dictionary) -> void:
		event_type = type_value; occurred_simulation_msec = occurred; priority = EVENT_PRIORITY_LIFECYCLE; subject_id = subject; source_id = &"SIMULATION_ENGINE"; payload = payload_value; reportable = true; tutorial_relevant = true
	static func threshold_settled(occurred: int, threshold_id: StringName, returns_total: int) -> SimulationEvent:
		return SimulationEvent.new(EVENT_THRESHOLD_SETTLED, occurred, threshold_id, {"remaining_backlog": 0, "lifecycle_state": "SETTLED", "persistent_returns_total": returns_total})
