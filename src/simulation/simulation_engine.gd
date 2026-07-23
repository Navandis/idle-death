class_name SimulationEngine
extends RefCounted

## Deterministic M04C/M04D2 elapsed-production resolver for one active Reaping.
##
## The engine owns online/offline/forecast-compatible arithmetic for the current
## single-Reaping slice only, including already-initialized eligible non-Essence
## Threshold channels. It calculates deterministic endpoint plans while a focused
## SimulationTransaction owns the deep-cloned candidate, validates that candidate,
## and replaces the live aggregate once so every failure preserves exact caller
## state. It does not own clocks, frame callbacks,
## Nodes, file I/O, Retinue effects, reports, milestones, Writ transitions,
## discovery, tutorial state, offline trust, access/source initialization, output
## channel modifiers, ETA queries, or multi-Reaping concurrency. All
## elapsed input is explicit integer milliseconds; all fractional production uses
## FixedPoint.SCALE subunits and integer floor arithmetic.

const OK := &""
const ERR_NEGATIVE_ELAPSED := &"SIM_NEGATIVE_ELAPSED"
const ERR_STATE_INVALID := &"SIM_STATE_INVALID"
const ERR_RESULT_INVALID := &"SIM_RESULT_INVALID"
const ERR_UNSUPPORTED_CONCURRENCY := &"SIM_UNSUPPORTED_CONCURRENCY"
const ERR_UNSUPPORTED_RETINUE := &"SIM_UNSUPPORTED_RETINUE"
const ERR_UNSUPPORTED_FLOW := &"SIM_UNSUPPORTED_FLOW"
const ERR_CONTENT := &"SIM_CONTENT_INVALID"
const ERR_UNSUPPORTED_MODIFIER := &"SIM_UNSUPPORTED_MODIFIER"
const ERR_OVERFLOW := &"SIM_OVERFLOW"
const ERR_ZERO_BOUNDARY := &"SIM_ZERO_BOUNDARY"

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
	return _resolve_elapsed_internal(state, elapsed_msec, {})

## Narrow non-persisted diagnostic seam for M04E2T1 provenance tests and traces.
## It returns the same committed result as `resolve_elapsed` plus detached context
## and journal facts; it never exposes the candidate or accepts a commit input.
func resolve_elapsed_with_trace(state: GameState, elapsed_msec: int) -> Dictionary:
	var trace := {}
	var result := _resolve_elapsed_internal(state, elapsed_msec, trace)
	return {"result": result, "transaction": trace.get("transaction", {})}

func _resolve_elapsed_internal(state: GameState, elapsed_msec: int, trace_output: Dictionary) -> SimulationResult:
	if elapsed_msec < 0:
		return SimulationResult.failure(ERR_NEGATIVE_ELAPSED, elapsed_msec, "Elapsed milliseconds must be non-negative.")
	if elapsed_msec == 0:
		return SimulationResult.zero_duration(0 if state == null else state.simulation_time_msec)
	var validation := GameStateValidator.validate(state, registry, true)
	if not validation.ok:
		return SimulationResult.failure(ERR_STATE_INVALID, elapsed_msec, str(validation))
	var active_ids := _active_reaping_ids(state)
	if active_ids.size() > 1:
		return SimulationResult.failure(ERR_UNSUPPORTED_CONCURRENCY, elapsed_msec, "M04C supports at most one active Reaping.")

	var context := _capture_run_context(state, elapsed_msec, active_ids)
	var transaction := SimulationTransaction.open(state, context, registry)
	if active_ids.is_empty():
		var timeline := transaction.advance_timeline()
		if not timeline.ok:
			return SimulationResult.failure(StringName(timeline.code), elapsed_msec, timeline.details)
		return _finalize_and_commit(state, transaction, trace_output)

	var active_id: StringName = active_ids[0]
	var initial_snapshot := transaction.calculation_snapshot()
	var reaping: GameState.ReapingState = initial_snapshot.reapings[active_id]
	if not reaping.retinue_ids.is_empty():
		return SimulationResult.failure(ERR_UNSUPPORTED_RETINUE, elapsed_msec, "Retinues are deferred until after M04C.")
	var flow_check := _validate_core_flows(reaping)
	if not flow_check.ok:
		return SimulationResult.failure(StringName(flow_check.code), elapsed_msec, flow_check.details)

	var cursor := context.baseline_simulation_time_msec
	var remaining := elapsed_msec
	var transition_guard := 0
	while remaining > 0:
		transition_guard += 1
		if transition_guard > 2:
			return SimulationResult.failure(ERR_ZERO_BOUNDARY, elapsed_msec, "Exceeded bounded M04C settlement segmentation.")
		var working := transaction.calculation_snapshot()
		var working_reaping: GameState.ReapingState = working.reapings[active_id]
		var threshold: GameState.ThresholdState = working.thresholds[active_id]
		var segment_msec := remaining
		var will_settle := false
		if str(threshold.lifecycle_state) == "OVERDUE" and threshold.remaining_backlog > 0:
			var boundary := _msec_to_next_return(working_reaping, active_id, threshold.remaining_backlog)
			if not boundary.ok: return SimulationResult.failure(StringName(boundary.code), elapsed_msec, boundary.details)
			if boundary.elapsed_msec <= 0: return SimulationResult.failure(ERR_ZERO_BOUNDARY, elapsed_msec, "Settlement boundary cannot advance time.")
			if boundary.elapsed_msec <= remaining:
				segment_msec = boundary.elapsed_msec
				will_settle = true
		if cursor > FixedPoint.INT64_MAX - segment_msec:
			return SimulationResult.failure(ERR_OVERFLOW, elapsed_msec, "simulation segment end")
		var segment_end_msec := cursor + segment_msec
		var core_plan := _calculate_core_segment(working, active_id, segment_msec, cursor, segment_end_msec, transaction.next_segment_index())
		if not core_plan.ok: return SimulationResult.failure(StringName(core_plan.code), elapsed_msec, core_plan.details)
		var applied_core := transaction.apply_core_segment(core_plan)
		if not applied_core.ok: return SimulationResult.failure(StringName(applied_core.code), elapsed_msec, applied_core.details)
		var channel_snapshot := transaction.calculation_snapshot()
		var channels := _eligible_output_channels(channel_snapshot, active_id)
		if not channels.ok: return SimulationResult.failure(StringName(channels.code), elapsed_msec, channels.details)
		for channel in channels.channels:
			channel_snapshot = transaction.calculation_snapshot()
			var channel_plan := _calculate_channel_segment(channel_snapshot, active_id, channel, segment_msec, segment_end_msec, transaction.current_segment_index())
			if not channel_plan.ok: return SimulationResult.failure(StringName(channel_plan.code), elapsed_msec, channel_plan.details)
			var applied_channel := transaction.apply_channel_segment(channel_plan)
			if not applied_channel.ok: return SimulationResult.failure(StringName(applied_channel.code), elapsed_msec, applied_channel.details)
		cursor = segment_end_msec
		remaining -= segment_msec
		if will_settle:
			var settled := transaction.apply_settlement_transition()
			if not settled.ok: return SimulationResult.failure(StringName(settled.code), elapsed_msec, settled.details)
	var timeline := transaction.advance_timeline()
	if not timeline.ok: return SimulationResult.failure(StringName(timeline.code), elapsed_msec, timeline.details)
	return _finalize_and_commit(state, transaction, trace_output)

func _capture_run_context(state: GameState, elapsed_msec: int, active_ids: Array[StringName]) -> SimulationRunContext:
	if active_ids.is_empty():
		return SimulationRunContext.new(state.simulation_time_msec, elapsed_msec, false, &"", 0, &"", &"", [], &"", registry.content_revision)
	var threshold_id: StringName = active_ids[0]
	var reaping: GameState.ReapingState = state.reapings[threshold_id]
	var threshold: GameState.ThresholdState = state.thresholds[threshold_id]
	return SimulationRunContext.new(state.simulation_time_msec, elapsed_msec, true, threshold_id, reaping.assignment_revision, reaping.form_id, reaping.writ_id, reaping.retinue_ids, threshold.lifecycle_state, registry.content_revision)

func _finalize_and_commit(state: GameState, transaction: SimulationTransaction, trace_output: Dictionary = {}) -> SimulationResult:
	var finalized := transaction.finalize()
	if not finalized.ok:
		return SimulationResult.failure(StringName(finalized.code), transaction.requested_elapsed_msec(), finalized.details)
	var committed: Dictionary = transaction.commit_to(state)
	if not committed.ok:
		return SimulationResult.failure(StringName(committed.code), transaction.requested_elapsed_msec(), committed.details)
	if trace_output != null:
		trace_output["transaction"] = transaction.read_only_snapshot()
	return committed.result

func _calculate_core_segment(state: GameState, threshold_id: StringName, elapsed_msec: int, start_msec: int, end_msec: int, segment_index: int) -> Dictionary:
	var threshold: GameState.ThresholdState = state.thresholds[threshold_id]
	var reaping: GameState.ReapingState = state.reapings[threshold_id]
	var form: GameState.FormState = state.forms[reaping.form_id]
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
	var essence := _accumulate_flow(reaping, FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS, FLOW_CORE_ESSENCE_RATE_CARRY_UNITS, essence_rate.rate, essence_rate.period, elapsed_msec)
	if not essence.ok: return essence
	var mastery := FixedPoint.accumulate_for_elapsed_msec(mastery_rate.rate, mastery_rate.period, elapsed_msec, int(reaping.flow_carry_units.get(FLOW_CORE_MASTERY_RATE_CARRY_UNITS, 0)))
	if not mastery.ok: return _fail(ERR_OVERFLOW, "mastery")
	if form.mastery_subunits > FixedPoint.INT64_MAX - int(mastery.produced_subunits): return _fail(ERR_OVERFLOW, "mastery")
	if form_record.cycle_duration_msec <= 0: return _fail(ERR_CONTENT, "cycle_duration_msec")
	if reaping.cycle_phase_msec > FixedPoint.INT64_MAX - elapsed_msec: return _fail(ERR_OVERFLOW, "cycle_phase_msec")
	var phase_total := reaping.cycle_phase_msec + elapsed_msec
	var completed := phase_total / int(form_record.cycle_duration_msec)
	if reaping.completed_cycle_count > FixedPoint.INT64_MAX - completed: return _fail(ERR_OVERFLOW, "completed_cycle_count")
	var essence_entry: GameState.InventoryEntryState = state.inventory.entries.get(&"RES_ESSENCE", GameState.InventoryEntryState.new())
	if essence_entry.total > FixedPoint.INT64_MAX - int(essence.whole): return _fail(ERR_OVERFLOW, "RES_ESSENCE")
	if threshold.persistent_returns_total > FixedPoint.INT64_MAX - int(returns.whole): return _fail(ERR_OVERFLOW, "persistent_returns_total")
	var backlog_after := threshold.remaining_backlog
	if threshold.lifecycle_state == &"OVERDUE": backlog_after = max(0, backlog_after - int(returns.whole))
	return {"ok": true, "segment_index": segment_index, "threshold_id": threshold_id, "assignment_revision": reaping.assignment_revision, "form_id": reaping.form_id, "writ_id": reaping.writ_id, "ordered_retinue_ids": reaping.retinue_ids.duplicate(), "lifecycle_state": threshold.lifecycle_state, "start_simulation_msec": start_msec, "end_simulation_msec": end_msec, "elapsed_msec": elapsed_msec, "persistent_returns_before": threshold.persistent_returns_total, "persistent_returns_after": threshold.persistent_returns_total + int(returns.whole), "remaining_backlog_before": threshold.remaining_backlog, "remaining_backlog_after": backlog_after, "essence_before": essence_entry.total, "essence_after": essence_entry.total + int(essence.whole), "mastery_before": form.mastery_subunits, "mastery_after": form.mastery_subunits + int(mastery.produced_subunits), "cycle_phase_before": reaping.cycle_phase_msec, "cycle_phase_after": phase_total % int(form_record.cycle_duration_msec), "completed_cycles_before": reaping.completed_cycle_count, "completed_cycles_after": reaping.completed_cycle_count + completed, "flow_endpoints": {FLOW_CORE_RETURNS_PROGRESS_SUBUNITS: {"before": reaping.flow_carry_units.get(FLOW_CORE_RETURNS_PROGRESS_SUBUNITS, 0), "after": returns.progress_after}, FLOW_CORE_RETURNS_RATE_CARRY_UNITS: {"before": reaping.flow_carry_units.get(FLOW_CORE_RETURNS_RATE_CARRY_UNITS, 0), "after": returns.carry_after}, FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS: {"before": reaping.flow_carry_units.get(FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS, 0), "after": essence.progress_after}, FLOW_CORE_ESSENCE_RATE_CARRY_UNITS: {"before": reaping.flow_carry_units.get(FLOW_CORE_ESSENCE_RATE_CARRY_UNITS, 0), "after": essence.carry_after}, FLOW_CORE_MASTERY_RATE_CARRY_UNITS: {"before": reaping.flow_carry_units.get(FLOW_CORE_MASTERY_RATE_CARRY_UNITS, 0), "after": mastery.carry_units}}}

func _calculate_channel_segment(state: GameState, threshold_id: StringName, channel: Dictionary, elapsed_msec: int, segment_end_msec: int, segment_index: int) -> Dictionary:
	var reaping: GameState.ReapingState = state.reapings[threshold_id]
	var threshold: GameState.ThresholdState = state.thresholds[threshold_id]
	var channel_id := StringName(channel.id)
	var acq: GameState.ThresholdAcquisitionState = threshold.channel_acquisition[channel_id]
	var rate := rate_context.output_channel_rate_plan(threshold_id, reaping.form_id, channel_id, str(threshold.lifecycle_state), reaping.writ_id, reaping.retinue_ids)
	if not rate.ok: return _fail(StringName(rate.code), rate.get("details", "channel rate"))
	var acc := FixedPoint.accumulate_for_elapsed_msec(int(rate.rate_subunits_per_period), int(rate.period_msec), elapsed_msec, acq.rate_carry_units)
	if not acc.ok: return _fail(ERR_OVERFLOW, "channel accumulation %s" % channel.id)
	var added := FixedPoint.add_subunits(acq.progress_subunits, int(acc.produced_subunits))
	if not added.ok: return _fail(ERR_OVERFLOW, "channel progress %s" % channel.id)
	var extracted := FixedPoint.extract_whole(int(added.subunits))
	var whole := int(extracted.whole_units)
	if acq.total_banked_units > FixedPoint.INT64_MAX - whole: return _fail(ERR_OVERFLOW, "channel total_banked_units %s" % channel.id)
	var item_id := StringName(channel.output_item_id)
	var entry: GameState.InventoryEntryState = state.inventory.entries.get(item_id, GameState.InventoryEntryState.new())
	if entry.total > FixedPoint.INT64_MAX - whole: return _fail(ERR_OVERFLOW, "inventory %s" % item_id)
	return {"ok": true, "segment_index": segment_index, "channel_id": channel_id, "output_item_id": item_id, "lifecycle_state": threshold.lifecycle_state, "segment_end_simulation_msec": segment_end_msec, "progress_subunits_before": acq.progress_subunits, "progress_subunits_after": extracted.remaining_subunits, "rate_carry_units_before": acq.rate_carry_units, "rate_carry_units_after": acc.carry_units, "total_banked_units_before": acq.total_banked_units, "total_banked_units_after": acq.total_banked_units + whole, "banked_units_delta": whole, "inventory_total_before": entry.total, "inventory_total_after": entry.total + whole, "period_msec": int(rate.period_msec)}

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
	return {"ok": true, "whole": int(extracted.whole_units), "progress_before": progress, "progress_after": int(extracted.remaining_subunits), "carry_before": int(reaping.flow_carry_units.get(carry_key, 0)), "carry_after": int(acc.carry_units)}

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

func _active_reaping_ids(state: GameState) -> Array[StringName]:
	var ids: Array[StringName] = []
	for id in state.reapings.keys():
		if state.reapings[id].is_active: ids.append(id)
	ids.sort()
	return ids

func _has_any(left: Array, right: Array) -> bool:
	for value in right:
		if left.has(value): return true
	return false

func _fail(code: StringName, details: String) -> Dictionary:
	return {"ok": false, "code": code, "details": details}
